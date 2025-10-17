#!/bin/bash

source gbash.sh || exit 1

DEFINE_string githubrepo "google-ads-perl" "The GitHub project name. Set this value to a private project name if testing the release."
DEFINE_string githuborg "googleads" "GitHub organization or user under which the repo resides."
DEFINE_bool githubupload "true" "Upload the GitHub release and the tag."
DEFINE_bool cpanupload "true" "Build the distribution tar file and upload to CPAN."

gbash::init_google "$@"

GOOGLE3=$(pwd)
if [[ "$(basename "$(pwd)")" != "google3" ]]; then
  GOOGLE3=$(pwd | grep -o ".*/google3/" | grep -o ".*google3")
fi

function main() {
  echo ">>> Building manifest..."
  perl Build manifest

  echo ">>> Building distribution and testing..."
  perl Build distclean
  perl Build.PL
  perl Build disttest || gbash::die "Distribution tests failed."

  echo ">>> Building distribution..."
  perl Build dist

  cpan_dist_file=Google-Ads-GoogleAds-Client-29.0.1.tar.gz

  echo "Build CPAN distribution complete!"
  echo "File ${cpan_dist_file} has been created for CPAN."

  echo ">>> Uploading ${cpan_dist_file} to CPAN..."
  sudo cpan CPAN::Uploader
  echo "Enter your CPAN PAUSE username:"
  read cpan_username
  cpan-upload -u "${cpan_username}" "${cpan_dist_file}"
  # cpan-upload will prompt for the username's CPAN PAUSE password.
}

main
