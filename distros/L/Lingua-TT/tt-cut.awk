#!/bin/bash

if test $# -lt 1 ; then
  echo "Usage: $0 AWK_EXPR [AWK_ARGS_AND_TT_FILE(s)]" 1>&2
  exit 1
fi

awkexpr="$1";
shift;
exec awk -F $'\t' '\
 BEGIN { FS="\t"; OFS="\t"; } \
 /^$/  { print; next; } \
 /^%%/ { print; next; } \
 { print '"$awkexpr"' } \
 ' \
 "$@"
