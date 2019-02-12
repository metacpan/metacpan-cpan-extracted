#!/bin/bash

if test -z "$*"; then
 echo "Usage: $0 TTFILE(s)"
 echo " + remove comments from .tt files"
 exit 0
fi

exec cat "$@" | egrep -v '^[[:space:]]*%%'
