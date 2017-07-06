#!/bin/bash

# Copyright (C) 2014 by CPqD

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

# http://www.dwheeler.com/essays/fixing-unix-linux-filenames.html
set -eu
IFS=$(printf '\n\t')

usage() {
    echo >&2 "usage: $(basename $0) [-v] [--] USER..."
    [[ -n $1 ]] && exit $1
}

VERBOSE=
LIMIT=10
while getopts v opt; do
    case $opt in
	v) VERBOSE=1 ;;
	\?) usage 2
    esac
done
shift $((OPTIND - 1))

TMPDIR=$(mktemp -d /tmp/tmp.XXXXXXXXXX) || exit 1
trap 'rm -rf $TMPDIR' EXIT

[[ -n "$V" ]] && set -x

ssh -p 29418 $USER@localhost gerrit create-project test
