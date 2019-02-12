#!/bin/bash

#. `dirname $0`/cmdutils.sh#
if test $# -lt 1 -o "$1" = "-h" -o "$1" = "--help" ; then
    echo "Usage: $0 TAG_PREFIX_LENGTH TTFILE(s)"
    exit 0
fi

taglen="$1"
shift
exec tt-cut.perl -f '1,{substr($_->[1],0,'$taglen')},2:-1' "$@"
