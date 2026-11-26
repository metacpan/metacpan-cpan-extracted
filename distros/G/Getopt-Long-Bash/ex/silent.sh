#!/usr/bin/env bash

set -eu

. "$(dirname "$0")"/getoptlong.sh -

help_main() {
    cat <<-END
	repeat [ options ] command
	    -h , --help  show help
	    -d , --debug debug level
	END
    exit 0
}
declare -A OPTS=(
    [ debug   | d   ]=0
    [ help    | h   ]=
    [ message | m % ]=
)
# Without EXIT_ON_ERROR, parse returns 1 on an error, and leaves the
# arguments as they are; SILENT drops the error messages, and the
# script gives its own.  PERMUTE= stops at the subcommand, so that its
# options are left to the subcommand.
getoptlong init OPTS EXIT_ON_ERROR= SILENT=1 PERMUTE= DEBUG=${DEBUGME:-}
getoptlong callback help help_main
getoptlong parse "$@" || { echo "invalid option: see --help" >&2 ; exit 2 ; }
eval "$(getoptlong set)"

echo "ARGV=[$@]" >&2

declare -p message

[[ ${subcmd:=${1:-}} ]] && shift || { echo "subcommand is required"; exit 1; }

echo "$subcmd [ $@ ]"

case $subcmd in
    flag) declare -A SUB_OPTS=([ flag | F   ]=) ;;
    data) declare -A SUB_OPTS=([ data | D : ]=) ;;
    list) declare -A SUB_OPTS=([ list | L @ ]=) ;;
    hash) declare -A SUB_OPTS=([ hash | H % ]=) ;;
    *)    echo "$subcmd: unknown subcommand" >&2 ; exit 1 ;;
esac

getoptlong init SUB_OPTS DEBUG=${DEBUGME:-}
getoptlong parse "$@" && eval "$(getoptlong set)"

[[ $debug -gt 0 ]] && getoptlong dump

case $subcmd in
    flag) declare -p flag ;;
    data) declare -p data ;;
    list) declare -p list ;;
    hash) declare -p hash ;;
esac

(( $# > 0 )) && echo "$@" || :
