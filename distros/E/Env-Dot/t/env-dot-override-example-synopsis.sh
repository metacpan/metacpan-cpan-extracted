#!/bin/sh

set -o errexit
set -o nounset

lib_dir="$PWD/lib"

# Move to a temp dir
# mktemp is not a POSIX function, but GNU, I think...
dir="$(mktemp -d)"
cd "${dir}" || exit
unset VAR
echo "VAR='Good value'" > .env
perl -I"${lib_dir}" -e 'use Env::Dot; print "VAR:$ENV{VAR}\n";'
# VAR:Good value
VAR='Better value'; export VAR
perl -I"${lib_dir}" -e 'use Env::Dot; print "VAR:$ENV{VAR}\n";'
# VAR:Better value

exit 0
