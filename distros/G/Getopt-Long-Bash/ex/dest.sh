#!/usr/bin/env bash

set -eu

declare -A OPTS=(
    [ count     | c :COUNT=i # repeat count              ]=1
    [ sleep     | i @SLEEP=f # interval time             ]=
    [ paragraph | p ?PARA    # print newline after cycle ]=
    [ trace     | x !TRACE   # trace execution           ]=
    [ debug     | d +DEBUG   # debug level               ]=0
    [ message   | m %MSG=(^(BEGIN|END)=) # print message at BEGIN|END ]=
)
TRACE() { [[ $2 ]] && set -x || set +x ; }

. "$(dirname $0)"/getoptlong.sh OPTS "$@"

column=$(command -v column) || column=cat
(( DEBUG >= 3 )) && dumpopt=(--all) filter=$column
(( DEBUG >= 2 )) && getoptlong dump ${dumpopt[@]} | ${filter:-cat} >&2

[[ ${1:-} =~ ^[0-9]+$ ]] && COUNT=$1 && shift

message() { [[ -v MSG[$1] ]] && echo "${MSG[$1]}" || : ; }

message BEGIN
for (( i = 0; $# > 0 && i < COUNT ; i++ )) ; do
    (( DEBUG > 0 )) && echo "# [ ${@@Q} ]" >&2
    "$@"
    [[ -v PARA ]] && echo "$PARA"
    if (( ${#SLEEP[@]} > 0 )) ; then
	time="${SLEEP[$(( i % ${#SLEEP[@]} ))]}"
	(( DEBUG > 0 )) && echo "# sleep $time" >&2
	sleep $time
    fi
done
message END
