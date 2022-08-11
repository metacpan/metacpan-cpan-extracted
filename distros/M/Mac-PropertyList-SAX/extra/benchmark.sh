#!/usr/bin/env bash
# Compare real-time parsing speeds between multiple Perl modules providing the
# `Mac::PropertyList::parse_plist_file` interface.

# Fail earl and loudly.
set -o errexit -o nounset -o pipefail

plists=( "$@" )

modules=(
    Mac::PropertyList
    Mac::PropertyList::SAX
)

real_seconds () { command time -p "$@" 2>&1 >/dev/null | grep ^real | (read _ x; echo $x); }

echo -e "plist\tbytes\tmodule\tseconds"
for p in "${plists[@]}"
do
    bytes=$(stat -f %z "$p")
    for mod in "${modules[@]}"
    do
        echo -ne "$p\t$bytes\t$mod\t"
        real_seconds perl -Mlib=lib -M$mod=parse_plist_file -e 'parse_plist_file(@ARGV)' "$p"
    done
done
