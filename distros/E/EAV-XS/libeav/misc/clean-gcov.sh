#!/bin/sh

curdir=`dirname $0`
# assuming that this script is placed in "misc/" directory
srcdir=`realpath "${curdir}/../"`

find ${srcdir} -type f -name '*.gcov' -or -name '*.gcda' -or -name '*.gcno' \
	| xargs -n1 -I{} rm '{}'

