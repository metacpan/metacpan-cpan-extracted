#!/bin/bash
set -euxo pipefail

# basedir must include the modules listed below
BASEDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )"/../.. && pwd )"

# tempdir for merging the modules together
TEMPDIR="`mktemp -d`"
trap 'cd /; rm -rf "$TEMPDIR"' EXIT

# merge the modules into one directory
for THEMOD in Tie-Handle-Base File-Replace File-Replace-Fancy File-Replace-Inplace
do
	cd "$BASEDIR"/$THEMOD
	rsync --archive --recursive --relative lib "$TEMPDIR"
	mkdir -p "$TEMPDIR"/t/$THEMOD
	rsync --archive --recursive --relative t/./ "$TEMPDIR"/t/$THEMOD
done

# run coverage on all of the modules' tests
cd "$TEMPDIR"
for THETEST in t/*/*.t
do
	perl -Ilib -I"$BASEDIR"/Tie-Handle-Base/lib -I"$BASEDIR"File-Replace/lib -MDevel::Cover=-silent "$THETEST"
done

# generate combined report
cover -coverage default,-pod -select_re '^lib/'
