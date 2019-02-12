#!/bin/bash

if test -z "$*" -o "$1" = '-h' -o "$1" = "--help" ; then
  echo "Usage: $0 TTFILE(s)"
  echo " + remove blank lines (EOS markers) from .tt files"
  exit 0;
fi

exec grep . "$@"
