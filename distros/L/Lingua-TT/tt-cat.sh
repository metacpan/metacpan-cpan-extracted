#!/bin/bash

if test -z "$*" -o "$1" = '-h' -o "$1" = "--help" ; then
  echo "Usage: $0 TTFILE(s)"
  echo " + concatenate .tt files, adding implicit EOS between files"
  echo " + pipe to tt-eosnorm.perl to avoid redundant EOS"
  exit 0;
fi

for f in "$@"; do
  echo "%% File: $f"
  cat "$f"
  ##-- add implicit EOS between files (use tt-eosnorm.perl to normalize)
  echo ""
done
