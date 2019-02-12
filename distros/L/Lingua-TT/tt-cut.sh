#!/bin/sh

if test $# -lt 1; then
  echo "Usage: $0 AWK_EXPR [TT_FILE(s)]" 1>&2
  exit 1
fi

tokexpr="$1"
shift

exec awk -F "	"
  'BEGIN { OFS="\t" };'
 
BEGIN	{ OFS="\t" }
/^$/    { print $0; next }
/^%%/   { print $0; next }
{ print "-",$0 }
