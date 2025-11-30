#!/usr/bin/env bash

set -Eeuo pipefail

# namename prints the basename without extension
namename() {
  local name=${1##*/}
  local name0="${name%.*}"
  printf "%s\n" "${name0:-$name}"
}

# Update API Docs
echo -n "Updating Module docs..."

rm -rf docs/*
for i in lib/Disk/SmartTools.pm examples/*pl
do
  j=$(namename "${i}")
  pod2markdown "${i}" > "docs/${j}.md"
done
echo "done"

echo -n "Updating Manifest..."
rm MANIFEST
make manifest
echo "done"

# Update Changelog
echo -n "Updating Changelog..."
rm CHANGELOG.md
git cliff > CHANGELOG.md
echo "done"

echo -n "Updating Signatures..."
rm SIGNATURE
make signature
echo "done"

