#!/bin/bash

if test -z "$*" -o "$1" = '-h' -o "$1" = "--help" ; then
  echo "Usage: $0 WHICH TTE_FILE"
  echo " + get a single sentence from a .tte (encoded .tt) file"
  echo " + sentence indices start counting at 1 (one)"
  echo " + pipe to tt-decode.perl to decode"
  echo " + if your sentences are commented, you might be better off with:"
  echo "   \$ grep '^%% Sentence s1234' -m 1 TTE_FILE"
  exit 0;
fi

which="$1"
shift
head -n "$which" "$1" | tail -n 1
