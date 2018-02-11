#!/bin/sh

maint=$(dirname "$0")
home=$(dirname "$maint")

fatpack-maint-build.pl \
    -source "$home/scripts/perlbrewise-spec" \
    -target "$home/perlbrewise-spec" \
    -verbose
