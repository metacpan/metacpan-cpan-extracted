#!/usr/bin/env bash
# vim: filetype=bash :  -*- mode: sh; sh-shell: bash; -*-
###############################################################################
# GetOptLong: Getopt Library for Bash Script
# Copyright 2025-2026 Office TECOLI, LLC <https://github.com/tecolicom/getoptlong-bash>
# MIT License: See <https://opensource.org/licenses/MIT>
: ${GOL_VERSION:=2.1.0}
###############################################################################
# Check bash version (4.4+ for nameref and ${parameter@Q})
((BASH_VERSINFO[0] > 4 || (BASH_VERSINFO[0] == 4 && BASH_VERSINFO[1] >= 4))) ||
    { echo "Requires bash 4.4 or later (found ${BASH_VERSION})" >&2 ; exit 1 ; }
_gol_warn() { echo "$@" >&2 ; }
_gol_die()  { _gol_warn "$@" ; exit 1 ; }
# an error in the arguments: it exits only with EXIT_ON_ERROR, and
# the message is suppressed by SILENT without EXIT_ON_ERROR
_gol_fail() { [[ $_EXIT_ON_ERROR || ! $_SILENT ]] && _gol_warn "$@" ; [[ $_EXIT_ON_ERROR ]] && exit 1 ; return 1 ; }
_gol_opts() {
    local _key="$1"
    [[ $_key =~ ^[$_MARKS]$ ]] && _key+="$2" && shift
    (($# == 2)) && _opts["$_key"]="$2" && return 0
    [[ -v _opts[$_key] ]] && echo "${_opts[$_key]}" || return 1
}
_gol_alias() { _gol_opts "$_MK_ALIAS" "$@" ; }
_gol_saila() { _gol_opts "$_MK_SAILA" "$@" ; }
_gol_deny()  { _gol_opts "$_MK_DENY"  "$@" ; }
_gol_trig()  { _gol_opts "$_MK_TRIG"  "$@" ; }
_gol_hook()  { _gol_opts "$_MK_HOOK"  "$@" ; }
_gol_rule()  { _gol_opts "$_MK_RULE"  "$@" ; }
_gol_help()  { _gol_opts "$_MK_HELP"  "$@" ; }
_gol_ival()  { _gol_opts "$_MK_INIT"  "$@" ; }
_gol_dest()  {
    [[ $1 =~ ^[[:alpha:]] ]] || _gol_die "$1: variable name must start with alphabet"
    _gol_opts "$_MK_DEST"  "$@"
}
_gol_type()  { [[ ${_opts[$1]} =~ ^([^[:alnum:]]+) ]] && echo "${_MATCH[1]}" || _gol_die "$1: unexpected" ; }
_gol_debug() { [[ ${_opts[&DEBUG]:-} ]] && _gol_warn DEBUG: "${@}" || : ; }
_gol_plusone() { [[ $1 =~ ^[0-9]+$ ]] && echo $(( $1 + 1 )) || echo 1 ; }
_gol_vstr() { printf "%03d." ${1//./ } ; }
# Main redirection function - sets up environment and delegates to implementation
_gol_redirect() { local _name ;
    declare -n _opts=$GOL_OPTHASH
    declare -n _MATCH=BASH_REMATCH
    _gol_debug "${FUNCNAME[1]}(${@@Q})"
    local _MARKS='><()&=#^.~' _MK_ALIAS='>' _MK_SAILA='<' _MK_DENY='~' _MK_TRIG='(' _MK_HOOK=')' _MK_CONF='&' _MK_RULE='=' _MK_HELP='#' _MK_INIT='^' _MK_DEST='.' \
	  _IS_ANY='+:?@*%' _IS_MOD='!>' _IS_REQ=':@*%' _IS_FLAG='+' _IS_NEED=':' _IS_MAYB='?' _IS_LIST='@' _IS_HASH='%' _IS_VARG='*' _IS_HOOK='!' _IS_PASS='>' \
	  _CONFIG=(EXIT_ON_ERROR SILENT PERMUTE REQUIRE DEBUG PREFIX DELIM USAGE HELP)
    for _name in "${_CONFIG[@]}" ; do declare _$_name="${_opts[&$_name]=}" ; done
    "${FUNCNAME[1]}_" "$@"
}
gol_dump () { _gol_redirect "$@" ; }
gol_dump_() { local _key ;
    if [[ ${1-} =~ ^(-a|--all)$ ]] ; then
	for _key in "${!_opts[@]}" ; do
	    printf '[%s]=%s\n' "${_key}" "${_opts["$_key"]@Q}"
	done | sort
    fi
    gol_vdump_
}
gol_vdump () { _gol_redirect "$@" ; }
gol_vdump_() { local _declare ; declare -A _seen ;
    for _key in "${!_opts[@]}" ; do
	[[ $_key =~ ^[$_MK_DEST](.*) ]] && [[ -z ${_seen[${_opts[$_key]}]-} ]] || continue
	_declare=$(declare -p "${_opts[$_key]}" 2> /dev/null) && echo "$_declare"
	_seen[${_opts[$_key]}]=1
    done | sort
}
gol_init() { local _key ;
    (( $# == 0 )) && { echo '(( ${#FUNCNAME[@]} > 0 )) && local GOL_OPTHASH OPTIND=1 || OPTIND=1' ; return ; }
    declare -n _opts=$1
    declare -A GOL_CONFIG=([PERMUTE]=GOL_ARGV [EXIT_ON_ERROR]=1 [DELIM]=$' \t,' [HELP]='help|h!#show HELP')
    for _key in "${!GOL_CONFIG[@]}" ; do : ${_opts["&$_key"]="${GOL_CONFIG[$_key]}"} ; done
    GOL_OPTHASH=$1
    (( $# > 1 )) && gol_configure "${@:2}"
    _gol_redirect
}
################################################################################
gol_init_() { local _key _aliases _alias _help ;
    [[ $_REQUIRE && $(_gol_vstr $GOL_VERSION) < $(_gol_vstr $_REQUIRE) ]] && _gol_die "getoptlong version $GOL_VERSION < $_REQUIRE"
    for _key in "${!_opts[@]}" ; do
	[[ $_key =~ ^( *)[$_MARKS] ]] && {
	    [[ $_key != "${_key// /}" ]] && _opts[${_key// /}]="${_opts[$_key]}" && unset "_opts[$_key]"
	    continue
	}
	_gol_init_entry "$_key"
    done
    if [[ $_HELP =~ ^( *)([[:alpha:]]+) ]] && _help=${_MATCH[2]} && [[ ! -v _opts[$_help] ]] ; then
	_gol_init_entry "$_HELP"
	declare -F $_help > /dev/null || eval "$_help() { getoptlong help ; exit ; }"
    fi
    return 0
}
_gol_init_entry() { local _entry="$1" _pass= _name _vname _dtype ;
    [[ $_entry =~ ^([-_~ \|[:alnum:]]+)([$_IS_ANY]*[$_IS_MOD]*[_[:alnum:]]*)( *)(=([if]|\(.*\)))?( *)(# *(.*[^[:space:]]))? ]] \
	|| _gol_die "[$_entry] -- invalid"
    local _names=${_MATCH[1]} _vtype=${_MATCH[2]} _type=${_MATCH[5]} _comment=${_MATCH[8]}
    local _initial="${_opts[$_entry]-}"
    IFS=$' \t|' read -ra _aliases <<< ${_names}
    _name=${_aliases[0]}
    _gol_ival $_name "$_initial"
    unset _opts["$_entry"]
    [[ $_vtype =~ ([$_IS_ANY]*[$_IS_MOD]*)([_[:alnum:]]+)$ ]] && { _vtype=${_MATCH[1]} ; _vname=${_MATCH[2]} ; }
    [[ $_vtype =~ $_IS_PASS ]] && { _vtype=${_vtype//$_IS_PASS/} ; _pass="$_IS_PASS" ; }
    [[ $_vtype =~ $_IS_HOOK ]] && { _vtype=${_vtype//$_IS_HOOK/} ; _gol_hook $_name ${_vname:-${_name//-/_}} ; }
    _gol_dest $_name ${_vname="${_PREFIX}${_name//-/_}"}
    : ${_vtype:=$_IS_FLAG} ${_dtype:=${_pass:+$_IS_LIST}}
    case ${_dtype:-$_vtype} in
	"$_IS_MAYB")
	    # the initial value is the default, which --no- unsets;
	    # without it, the variable is left as it is
	    [[ $_initial ]] && _gol_value $_vname "$_initial" ;;
	"$_IS_LIST"|"$_IS_HASH"|"$_IS_VARG")
	    [[ $_vtype == [$_IS_LIST$_IS_VARG] && ! -v $_vname ]] && declare -ga $_vname
	    [[ $_vtype == $_IS_HASH && ! -v $_vname ]] && declare -gA $_vname
	    if [[ $_initial =~ ^\(.*\)$ ]] ; then
		eval "$_vname=$_initial"
	    else
		[[ $_vtype == [$_IS_LIST$_IS_VARG] ]] && _gol_add_array $_vname ${_initial:+"$_initial"}
		[[ $_vtype == $_IS_HASH ]] && [[ $_initial ]] && _gol_die "$_initial: invalid hash data"
	    fi
	    ;;
	"$_IS_NEED"|"$_IS_FLAG") _gol_value $_vname "$_initial" ;;
	*) _gol_die "$_vtype: unknown option type" ;;
    esac
    _opts[$_name]="${_vtype}${_pass}${_vname}"
    [[ $_type ]] && _gol_rule $_name "$_type"
    for _alias in "${_aliases[@]:1}" ; do
	[[ $_alias == ~* ]] && { _alias=${_alias#\~} ; _gol_deny $_alias $_name ; }
	_opts[$_alias]="${_opts[$_name]}"
	_gol_alias $_alias $_name
    done
    _aliases=("${_aliases[@]/#\~/}")
    _gol_saila $_name "${_aliases[*]:1}"
    [[ $_comment ]] && _gol_help "$_name" "$_comment"
    return 0
}
gol_configure () { _gol_redirect "$@" ; }
gol_configure_() { local _param _key _val ;
    for _param in "$@" ; do
	[[ $_param =~ ^[[:alnum:]] ]] || _gol_die "$_param -- invalid config parameter"
	_key="${_MK_CONF}${_param%%=*}"
	[[ $_param =~ =(.*) ]] && _val="${_MATCH[1]}" || _val=1
	[[ -v _opts[$_key] ]] || _gol_die "$_param -- invalid config parameter"
	_opts[$_key]="$_val"
    done
    return 0
}
gol_optstring_() { local _key _string ;
    for _key in "${!_opts[@]}" ; do
	[[ $_key =~ ^[[:alnum:]]$ ]] && _string+=$_key || continue
	[[ ${_opts[$_key]} =~ [${_IS_REQ}] ]] && _string+=:
    done
    echo "${_SILENT:+:}${_string:- }-:"
}
gol_getopts () { _gol_redirect "$@" ; }
gol_getopts_() { local _non= _optname _val _vtype _vname _name _callback _trigger _pass _vargs=() ;
    local _opt="$1"; shift;
    case $_opt in
	[:?]) _callback=$(_gol_hook "$_opt") && [[ $_callback ]] && _gol_call_hook "$_callback" "$OPTARG"
	      [[ $_EXIT_ON_ERROR ]] && exit 1 || return 1 ;;
	-) _gol_getopts_long "$@" || return $? ;;
	*) _gol_getopts_short "$@" || return $? ;;
    esac
    [[ -v _val || $_pass ]] || _val="$(_gol_plusone "$(_gol_value $_vname)")"
    _name=$(_gol_alias ${_optname:-$_opt}) || _name=${_optname:=$_opt}
    _trigger="$(_gol_trig $_name)" && _gol_call_hook "$_trigger" "$_name"
    if [[ $_pass ]] ; then _gol_getopts_passthru ; else _gol_getopts_store || return ; fi
    if _callback="$(_gol_hook $_name)" ; then
	# the * type gives the arguments, the others give the value
	[[ $_vtype == "$_IS_VARG" ]] || _vargs=("$_val")
	_gol_call_hook "$_callback" "$_name" "${_vargs[@]}"
    fi
    return 0
}
_gol_call_hook() {
    local _call ; read -ra _call <<< "$1"
    declare -F "${_call[0]}" > /dev/null \
	|| _gol_die "callback function ${_call[0]}() is not defined"
    # the callback handles its own errors: the return value is ignored
    "${_call[@]}" "${@:2}" || :
}
_gol_getopts_long() { local _param ;
    [[ $OPTARG =~ ^(no-)?([-_[:alnum:]]+)(=(.*))? ]] || { _gol_fail "$OPTARG: unrecognized option" ; return ; }
    _non="${_MATCH[1]}" _optname="${_MATCH[2]}" _param="${_MATCH[3]}"
    [[ $_param ]] && _val="${_MATCH[4]}"
    [[ $(_gol_opts $_optname) =~ ^([$_IS_ANY]+)([$_IS_MOD]?)([_[:alnum:]]+) ]] \
	|| { _gol_fail "no such option -- --$_optname" ; return ; }
    _vtype=${_MATCH[1]} _pass="${_MATCH[2]}" _vname=${_MATCH[3]}
    _gol_deny $_optname > /dev/null 2>&1 && { [[ $_non ]] && _non="" || _non="no-" ; }
    if [[ $_param ]] ; then
	[[ $_vtype =~ [${_IS_REQ}${_IS_MAYB}] ]] || { _gol_fail "does not take an argument -- $_optname" ; return ; }
	[[ $_vtype == "$_IS_VARG" ]] && _vargs=("$_val")
    else
	case $_vtype in
	    [$_IS_MAYB]) _val= ;;
	    [$_IS_VARG]) _val= ; [[ $_non ]] || _gol_getopts_varargs $_optname "$@" || return ;;
	    [$_IS_REQ])
		if [[ $_non ]] ; then _val= ; else
		    (( OPTIND > $# )) && { _gol_fail "option requires an argument -- $_optname" ; return ; }
		    _val="${@:$((OPTIND++)):1}"
		fi ;;
	    *) [[ $_non ]] && _val= ;;
	esac
    fi
    return 0
}
_gol_getopts_short() {
    [[ ${_opts[$_opt]-} =~ ^([$_IS_ANY])([$_IS_MOD]?)([_[:alnum:]]+) ]] \
	|| { _gol_fail "no such option -- -$_opt" ; return ; }
    _vtype=${_MATCH[1]} _pass="${_MATCH[2]}" _vname=${_MATCH[3]}
    [[ $_vtype =~ [${_IS_MAYB}${_IS_REQ}] ]] && _val="${OPTARG:-}"
    if [[ $_vtype == "$_IS_VARG" ]] ; then
	# a value joined to the option is the only one, as --opt=value;
	# a separate one is the first of the arguments up to --
	_val=
	if [[ ${@:$((OPTIND-1)):1} != "$OPTARG" ]] ; then _vargs=("$OPTARG")
	elif [[ $OPTARG == -- ]] ; then VARGIND=$OPTIND
	else _vargs=("$OPTARG") ; _gol_getopts_varargs $_opt "$@" || return ; fi
    fi
    _gol_deny $_opt > /dev/null 2>&1 && { _non="no-" ; _val="" ; }
    return 0
}
# take the arguments up to -- into _vargs, and the -- itself
_gol_getopts_varargs() { local _optname="$1" ; shift
    while (( OPTIND <= $# )) ; do
	# VARGIND tells parse that the -- does not end the options
	[[ ${!OPTIND} == -- ]] && { OPTIND=$((OPTIND + 1)) VARGIND=$OPTIND ; return 0 ; }
	_vargs+=("${!OPTIND}") ; OPTIND=$((OPTIND + 1))
    done
    _gol_fail "option requires terminating -- -- $_optname"
}
_gol_getopts_store() { local _vals _v ;
    local _check=$(_gol_rule $_name)
    case $_vtype in
	[$_IS_VARG])
	    [[ $_non ]] && { declare -n __target__=$_vname ; __target__=() ; return ; }
	    for _v in "${_vargs[@]}" ; do
		[[ ! $_check ]] || _gol_validate "$_check" "$_v" || return
	    done
	    _gol_add_array $_vname "${_vargs[@]}"
	    ;;
	[$_IS_LIST]|[$_IS_HASH])
	    [[ $_non ]] && { declare -n __target__=$_vname ; __target__=() ; return ; }
	    [[ $_val =~ $'\n' ]] && readarray -t _vals <<< ${_val%$'\n'} \
				 || IFS="${_DELIM}" read -ra _vals <<< ${_val}
	    for _v in "${_vals[@]}" ; do
		[[ ! $_check ]] || _gol_validate "$_check" "$_v" || return
		case $_vtype in
		[$_IS_LIST]) _gol_add_array $_vname "$_v" ;;
		[$_IS_HASH])
		    [[ $_v =~ = ]] && _gol_set_hash $_vname "${_v%%=*}" "${_v#*=}" \
				   || _gol_set_hash $_vname "$_v" 1 ;;
		esac
	    done
	    ;;
	[$_IS_MAYB])
	    # --no- takes the option back: the variable is unset, the
	    # third state besides a value and the empty string
	    [[ $_non ]] && { unset -v "$_vname" ; return ; }
	    ;;&
	*) [[ ! $_check ]] || _gol_validate "$_check" "$_val" || return
	   _gol_value $_vname "$_val" ;;
    esac
}
_gol_getopts_passthru() { local _options=() ;
    local _option=${_optname-$_opt}
    (( ${#_option} > 1 || ${#_non} )) && _options=(--$_non$_option) || _options=(-$_option)
    if [[ $_non ]] ; then :
    elif [[ $_vtype == "$_IS_VARG" ]] ; then _options+=("${_vargs[@]}" --)
    elif [[ $_vtype =~ [$_IS_REQ] ]] ; then _options+=("$_val")
    elif [[ $_vtype =~ [$_IS_MAYB] && ${_val-} ]] ; then
	(( ${#_option} > 1 )) && _options=("--$_option=$_val") || _options=("-$_option$_val")
    fi
    _gol_add_array $_vname "${_options[@]}"
}
_gol_value() {
    declare -n __target__="$1"
    (( $# > 1 )) && __target__="$2" || echo "$__target__"
}
_gol_add_array() { declare -n __target__="$1" ; __target__+=("${@:2}") ; }
_gol_set_hash()  { declare -n __target__="$1" ; __target__["$2"]="$3" ; }
_gol_validate() {
    case $1 in
	i)   [[ $2 =~ ^[-+]?[0-9]+$ ]]            || _gol_fail "$2: not an integer" ;;
	f)   [[ $2 =~ ^[-+]?[0-9]*(\.[0-9]+)?$ ]] || _gol_fail "$2: not a number" ;;
	\(*) [[ $2 =~ $1 ]] ; case $? in
		 1) _gol_fail "$2: invalid argument" ;;
		 2) _gol_die "$1: something wrong" ;;
	     esac ;;
	*)   _gol_die "$1: unknown validation pattern" ;;
    esac
}
gol_callback () { _gol_redirect "$@" ; }
gol_callback_() { local _setter=_gol_hook _name _func _arg ;
    case ${1-} in -b|--before) _setter=_gol_trig ; shift ;; esac
    (($# > 0)) || _gol_die "callback: option name is required"
    _name=$(_gol_alias "$1") || _name=$1
    [[ $_name == [:?] ]] || _gol_opts "$_MK_DEST" "$_name" > /dev/null \
	|| _gol_die "$1: no such option"
    _func=${2:-$_name}
    [[ $_func =~ ^[_[:alnum:]] ]] || _func=$_name
    [[ $_func =~ [[:space:]] ]] && _gol_die "$_func: invalid function name"
    for _arg in "${@:3}" ; do
	[[ $_arg =~ ^[^[:space:]]+$ ]] || _gol_die "${_arg@Q}: invalid callback argument"
    done
    $_setter "$_name" "${_func//-/_} ${*:3}"
}
gol_help () { _gol_redirect "$@" ; }
gol_help_() {
    (( $# < 2 )) && { _gol_show_help "$@" ; return 0 ; }
    while (($# > 1)) ; do _gol_help "$1" "$2" ; shift 2 ; done
}
_gol_show_help() { local _key _aliases _init= _default= _column _flag _msg ;
    echo "${1:-${_USAGE:-$(basename "$0") [ options ] args}}"
    _column=($(command -v column)) && _column+=(-s $'\t' -t) || _column=(cat)
    for _key in "${!_opts[@]}" ; do
	_aliases="$(_gol_saila "$_key")" || continue
	_msg="$(_gol_help $_key)" || {
	    _init="$(_gol_ival $_key)" && _default="${_init:+ (default:$_init)}"
	    [[ $_init =~ ^[0-9]+$ ]] && _flag=bump || _flag=enable
	    [[ ${_opts[$_key]} =~ ([^[:alnum:]]+)(.*) ]] || _gol_die "${_opts[$_key]}: invalid entry"
	    case "${_MATCH[1]}" in
		*[$_IS_PASS]) _msg="passthrough to ${_MATCH[2]^^}" ;;
		*[$_IS_VARG]) _msg="add arguments up to -- to ${_key^^}" ;;
		*[$_IS_FLAG]) _msg="$_flag ${_key^^}$_default" ;;
		*[$_IS_NEED]) _msg="set ${_key^^}$_default" ;;
		*[$_IS_LIST]) _msg="add item(s) to ${_key^^}" ;;
		*[$_IS_HASH]) _msg="set KEY=VALUE(s) in ${_key^^}" ;;
		*[$_IS_MAYB]) _msg="enable/set ${_key^^}$_default" ;;
	    esac
	}
	printf '    %s\t%1s\t%s\n' "$(_gol_optize $_key)" "$(_gol_optize $_aliases)" "$_msg"
    done | sort | "${_column[@]}"
}
_gol_optize() { local _name _opt _optlist _eq ;
    for _name in "$@"; do
	if _gol_deny $_name > /dev/null 2>&1 ; then
	    (( ${#_name} > 1 )) && _opt="~~$_name" || _opt="~$_name"
	else
	    (( ${#_name} > 1 )) && _opt=--$_name _eq='=' || _opt=-$_name _eq=
	    case "$(_gol_type $_name)" in
		[$_IS_NEED]) _opt+="$_eq#" ;;
		[$_IS_LIST]) _opt+="$_eq#[,#]" ;;
		[$_IS_VARG]) _opt+=" #... --" ;;
		[$_IS_HASH]) _opt+="$_eq#=#" ;;
		[$_IS_MAYB]) (( ${#_name} > 1 )) && _opt+="[=#]" ;;
	    esac
	fi
	_optlist+=("$_opt")
    done
    printf '%s\n' "${_optlist[*]}"
}
gol_parse () { _gol_redirect "$@" ; }
gol_parse_() { local gol_OPT SAVEARG=() SAVEIND= VARGIND= ;
    local optstring="$(gol_optstring_)" ; _gol_debug "OPTSTRING=$optstring" ;
    for (( OPTIND=1 ; OPTIND <= $# ; OPTIND++ )) ; do
	while getopts "$optstring" gol_OPT ; do
	    # an error: the arguments are left as they are
	    gol_getopts_ "$gol_OPT" "$@" || return 1
	done
	: ${SAVEIND:=$OPTIND}
	[[ ! $_PERMUTE || $OPTIND -gt $# ]] && break
	[[ ${@:$(($OPTIND-1)):1} == -- && $OPTIND != "$VARGIND" ]] && break
	_gol_debug "SAVE PARAM: ${!OPTIND}"
	SAVEARG+=("${!OPTIND}")
    done
    set -- "${SAVEARG[@]}" "${@:$OPTIND}"
    OPTIND=${SAVEIND:-$OPTIND}
    _gol_debug "ARGV=(${@@Q})"
    [[ $_PERMUTE ]] && { declare -n _gol_argv=$_PERMUTE ; _gol_argv=("$@") ; }
    return 0
}
gol_set () { _gol_redirect "$@" ; }
gol_set_() {
    [[ $_PERMUTE ]] && printf 'set -- "${%s[@]}"\n' "$_PERMUTE" \
		    || echo 'set -- "${@:$OPTIND}"'
}
# Main entry point - dispatch to appropriate subcommand
getoptlong () {
    case ${1-} in
	init|parse|set|configure|getopts|callback|dump|help) gol_$1 "${@:2}" ;;
	version) echo ${GOL_VERSION} ;;
	*) _gol_die "unknown subcommand -- ${1-}" ;;
    esac
}
# Auto-initialization if first argument is an associative array, only
# when sourced as a file: the code embedded in a script (BASH_SOURCE is
# the script itself) leaves the script's arguments alone
if [[ ${BASH_SOURCE[0]} != "$0" && $(declare -p "${1-}" 2> /dev/null) =~ ^declare\ -A ]] ; then
    gol_init "$1" && shift && gol_parse "$@" && eval "$(gol_set)"
fi
