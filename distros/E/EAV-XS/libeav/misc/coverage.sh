#!/bin/sh

#
# Usage:
#     coverage.sh
#
#     # or define custom IDNKIT_DIR, default is $HOME/local
#     IDNKIT_DIR=/path/to/idnkit coverage.sh
#
# Description:
#     Runs coverage build and creates reports for all IDN libraries.
#     You may find report files inside of ./coverage directory.
#

[ -s "${IDNKIT_DIR}" ] || export IDNKIT_DIR="$HOME/local"
[ -s "$LD_LIBRARY_PATH" ] \
    && export LD_LIBRARY_PATH="${IDNKIT_DIR}/lib:${LD_LIBRARY_PATH}" \
    || export LD_LIBRARY_PATH="${IDNKIT_DIR}/lib"

curdir=`dirname $0`
# assuming that this script is placed in "misc/" directory
srcdir=`realpath "${curdir}/../"`
cd "${srcdir}" || exit 1

for lib in idn2 idn idnkit;
do
    make FORCE_IDN=${lib} gcovr
    make FORCE_IDN=${lib} clean
done
