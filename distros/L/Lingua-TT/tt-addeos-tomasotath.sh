#!/bin/sh

if test -z "$*"; then
  echo "Usage: $0 TTFILE(s)"
  echo " + add EOS-marking blank lines after ever '$.' tag [HACK]"
  exit 0;
fi

exec sed -e '/^[^'$'\t'']*'$'\t''\$\./a'$'\n' "$@"
