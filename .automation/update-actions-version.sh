#!/usr/bin/env bash

################################################################################
############# Update the actions.yml with version @admiralawkbar ###############
################################################################################

###########
# Globals #
###########
GITHUB_API='https://api.github.com'     # API url
GITHUB_TOKEN="${GITHUB_TOKEN}"          # Token for API CALLS
DEPLOY_KEY="${SUPER_LINTER_DEPLOY_KEY}" # Deploy key with write access
ORG='github'                            # Name of ther GitHub Organization
REPO='super-linter'                     # Name of the gitHub repository
VERSION=''                              # Version of release pulled from api
ACTION_FILE='action.yml'                # Action file to update

################################################################################
############################ FUNCTIONS BELOW ###################################
################################################################################
################################################################################
#### Function Header ###########################################################
Header() {
  echo "-------------------------------------------------------"
  echo "----------- GitHub Update Release Version -------------"
  echo "-------------------------------------------------------"
}
################################################################################
#### Function GetLatestRelease #################################################
GetLatestRelease() {
  echo "-------------------------------------------------------"
  echo "Getting the latest Release version from GitHub..."

  # Get the latest release on the Repository
  GET_VERSION_CMD=$(curl -s --fail -X GET \
    --url "$GITHUB_API/repos/$ORG/$REPO/releases/latest" \
    -H "Authorization: Bearer ${GITHUB_TOKEN}" |jq -r .tag_name 2>&1)

  # Load the error code
  ERROR_CODE=$?

  # Check the shell for errors
  if [ "${ERROR_CODE}" -ne 0 ] || [ ${#GET_VERSION_CMD} -lt 1]; then
    # Error
    echo "ERROR! Failed to get the version!"
    echo "ERROR:[${GET_VERSION_CMD}]"
    exit 1
  else
    # Success
    echo "Latest Version:[${GET_VERSION_CMD}]"
  fi

  # Set the version
  VERSION=${GET_VERSION_CMD}
}
################################################################################
#### Function UpdateActionFile #################################################
UpdateActionFile() {
  echo "-------------------------------------------------------"
  echo "Updating the file:[$ACTION_FILE] with version:[$VERSION]..."

  # Validate we can see the file
  if [ ! -f "${ACTION_FILE}" ]; then
    # ERROR
    echo "ERROR! Failed to find the file:[${ACTION_FILE}]"
    exit 1
  fi

  # Update the file
  UPDATE_CMD=$(sed -i "s|image:.*|image: 'docker://ghcr.io/github/super-linter:${VERSION}'|" "${ACTION_FILE}" 2>&1)

  # Load the error code
  ERROR_CODE=$?

  # Check the shell for errors
  if [ "${ERROR_CODE}" -ne 0 ]; then
    # Failed to update file
    echo "ERROR! Failed to update ${ACTION_FILE}!"
    exho "ERROR:[${UPDATE_CMD}]"
    exit 1
  else
    echo "Successfully updated file to:"
    cat "${ACTION_FILE}"
  fi
}
################################################################################
#### Function CommitAndPush ####################################################
CommitAndPush() {
  echo "-------------------------------------------------------"
  echo "Creating commit, and pushing to PR..."

  # Commit the code to GitHub
  COMMIT_CMD=$(git checkout -b "Automation-Release-${VERSION}"; \
    git add "${ACTION_FILE}" ; \
    git config --global user.name "SuperLinter Automation"; \
    git config --global user.email "super_linter_automation@github.com"; \
    git commit -m "Updating action.yml with release version" 2>&1)

  # Load the error code
  ERROR_CODE=$?

  # Check the shell for errors
  if [ "${ERROR_CODE}" -ne 0 ]; then
    # ERROR
    echo "ERROR! Failed to make commit!"
    echo "ERROR:[$COMMIT_CMD]"
    exit 1
  else
    echo "Successfully staged commmit"
  fi

  # Push the code to the branch and create PR
  PUSH_CMD=$(git push --set-upstream origin "Automation-Release-${VERSION}" \;
    gh pr create --title "Automation-Release-${VERSION}" --body "Automation Upgrade to action.yml" 2>&1)

  # Load the error code
  ERROR_CODE=$?

  # Check the shell for errors
  if [ "${ERROR_CODE}" -ne 0 ]; then
    # ERROR
    echo "ERROR! Failed to create PR!"
    echo "ERROR:[$PUSH_CMD]"
    exit 1
  else
    echo "Successfully Created PR"
  fi
}
################################################################################
#### Function Footer ###########################################################
Footer() {
  echo "-------------------------------------------------------"
  echo "The step has completed"
  echo "-------------------------------------------------------"
}
################################################################################
################################## MAIN ########################################
################################################################################

##########
# Header #
##########
Header

##########################
# Get the latest version #
##########################
GetLatestRelease

##########################
# Update the action file #
##########################
UpdateActionFile

########################
# Commit and push file #
########################
CommitAndPush

##########
# Footer #
##########
Footer
