#!/bin/bash

show_usage() {
  echo "Usage: tt-123-kgrams.awk [OPTIONS] K VERBOSE_123_FILE(s)..." 1>&2
  exit 1
}


test $# -lt 1 && show_usage;

case "$1" in
  [0-9]|[0-9][0-9])
    k="$1"
    shift
    ;;
  *)
    show_usage
    ;;
esac

let "nf=$k+1"
exec awk '\
 BEGIN {FS="\t"; OFS="\t";} \
 /^%%/ {next}  \
 {if (NF == '$nf') print $0}' \
 "$@"
