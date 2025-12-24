#!/usr/bin/env bash

. $(dirname $0)/getoptlong.sh

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
getoptlong init OPTS PERMUTE=
getoptlong callback help help_main
getoptlong parse "$@" && eval "$(getoptlong set)"

declare -p message

[[ ${subcmd:=$1} ]] && shift || { echo "subcommand is required"; exit 1; }

case $subcmd in
    flag) declare -A SUB_OPTS=([ flag | F   ]=) ;;
    data) declare -A SUB_OPTS=([ data | D : ]=) ;;
    list) declare -A SUB_OPTS=([ list | L @ ]=) ;;
    hash) declare -A SUB_OPTS=([ hash | H % ]=) ;;
    *)    echo "$subcmd: unknown subcommand" >&2 ; exit 1 ;;
esac

getoptlong init SUB_OPTS
getoptlong parse "$@" && eval "$(getoptlong set)"

[[ $debug -gt 0 ]] && getoptlong dump

case $subcmd in
    flag) declare -p flag ;;
    data) declare -p data ;;
    list) declare -p list ;;
    hash) declare -p hash ;;
esac

(( $# > 0 )) && echo "$@"
