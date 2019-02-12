#!/bin/bash

opts=()
args=()
help=""

while test $# -gt 0; do
 case "$1" in
  -\?|-h|-help|--help)
    help="$1"
    ;;
  -*)
    opts[${#opts[@]}]="$1"
    ;;
  *)
    args[${#args[@]}]="$1"
    ;;
 esac
 shift
done

#echo "$0: opts=(${opts[@]})"
#echo "$0: args=(${args[@]})"
#echo "$0: help='$help'"

if test -n "$help" ; then
  exec wc --help
fi

exec cat "${args[@]}" | grep -v '^%%' | grep '.' | wc "${opts[@]}"
