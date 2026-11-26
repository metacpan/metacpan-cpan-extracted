#!/usr/bin/env bats

# The * type: the arguments up to -- are taken as they are

load test_helper.bash

# varargs_with [ init-params ] -- args...
# OPTS has a * option, column-opts|X, and a flag, lateral|L.
varargs_with() {
    run env LC_ALL=C $BASH -c '
        . ../script/getoptlong.sh
        declare -A OPTS=([column-opts|X*]= [lateral|L]=)
        declare -a ARGV=()
        params=() ; while [[ $1 != -- ]] ; do params+=("$1") ; shift ; done ; shift
        getoptlong init OPTS PERMUTE=ARGV "${params[@]}"
        getoptlong parse "$@"
        echo "parse:$? cols:$(printf "[%s]" "${column_opts[@]}") lateral:$lateral argv:$(printf "[%s]" "${ARGV[@]}")"
    ' _ "$@"
}

@test "varargs: long option" {
    varargs_with -- --column-opts -w 170 -s ' ' -- a.txt
    assert_success
    assert_output "parse:0 cols:[-w][170][-s][ ] lateral: argv:[a.txt]"
}

@test "varargs: short option" {
    varargs_with -- -X -w 170 -- a.txt
    assert_success
    assert_output "parse:0 cols:[-w][170] lateral: argv:[a.txt]"
}

@test "varargs: short option joined with a value takes the value only" {
    varargs_with -- -X-w 170 -- a.txt
    assert_success
    assert_output "parse:0 cols:[-w] lateral: argv:[170][a.txt]"
}

@test "varargs: short option joined with a value in a cluster" {
    varargs_with -- -LX170 a.txt
    assert_success
    assert_output "parse:0 cols:[170] lateral:1 argv:[a.txt]"
}

@test "varargs: short option joined with a value, with an argument equal to it" {
    varargs_with -- -X170 170 a.txt
    assert_success
    assert_output "parse:0 cols:[170] lateral: argv:[170][a.txt]"
}

@test "varargs: short option at the end of a cluster" {
    varargs_with -- -LX -w -- a.txt
    assert_success
    assert_output "parse:0 cols:[-w] lateral:1 argv:[a.txt]"
}

@test "varargs: no arguments" {
    varargs_with -- --column-opts -- -X -- a.txt
    assert_success
    assert_output "parse:0 cols:[] lateral: argv:[a.txt]"
}

@test "varargs: the arguments are not split by DELIM" {
    varargs_with -- -X 'a,b c' -- a.txt
    assert_success
    assert_output "parse:0 cols:[a,b c] lateral: argv:[a.txt]"
}

@test "varargs: repeated options add to the array" {
    varargs_with -- -X -w 170 -- --column-opts -s ' ' -- a.txt
    assert_success
    assert_output "parse:0 cols:[-w][170][-s][ ] lateral: argv:[a.txt]"
}

@test "varargs: options after the arguments are parsed" {
    varargs_with -- -X -L -- -L a.txt
    assert_success
    assert_output "parse:0 cols:[-L] lateral:1 argv:[a.txt]"
}

@test "varargs: with PERMUTE, the arguments around are kept in order" {
    varargs_with -- a.txt -X -w -- b.txt
    assert_success
    assert_output "parse:0 cols:[-w] lateral: argv:[a.txt][b.txt]"
}

@test "varargs: another -- ends the options" {
    varargs_with -- -X -w -- -- -L
    assert_success
    assert_output "parse:0 cols:[-w] lateral: argv:[-L]"
}

@test "varargs: --opt=value takes the value only" {
    varargs_with -- --column-opts=-w 170 -- a.txt
    assert_success
    assert_output "parse:0 cols:[-w] lateral: argv:[170][a.txt]"
}

@test "varargs: --no- empties the array" {
    varargs_with -- -X -w -- --no-column-opts a.txt
    assert_success
    assert_output "parse:0 cols:[] lateral: argv:[a.txt]"
}

@test "varargs: without --, the script exits" {
    varargs_with -- --column-opts -w 170
    assert_failure
    assert_output "option requires terminating -- -- column-opts"
}

@test "varargs: without -- in short option, the script exits" {
    varargs_with -- -X -w 170
    assert_failure
    assert_output "option requires terminating -- -- X"
}

@test "varargs: without --, parse returns 1 with EXIT_ON_ERROR disabled" {
    varargs_with EXIT_ON_ERROR= -- -L -X -w 170
    assert_success
    assert_line --index 0 "option requires terminating -- -- X"
    assert_line --index 1 "parse:1 cols:[] lateral:1 argv:[]"
}

@test "varargs: short option at the end requires an argument" {
    varargs_with -- -X
    assert_failure
    assert_output --partial "option requires an argument -- X"
}

@test "varargs: initial value" {
    run $BASH -c '
        . ../script/getoptlong.sh
        declare -A OPTS=([column-opts|X*]="(-w 80)")
        getoptlong init OPTS
        getoptlong parse -X -s " " -- a.txt
        eval "$(getoptlong set)"
        echo "cols:$(printf "[%s]" "${column_opts[@]}") args:$*"
    '
    assert_success
    assert_output "cols:[-w][80][-s][ ] args:a.txt"
}

@test "varargs: validation of each argument" {
    run $BASH -c '
        . ../script/getoptlong.sh
        declare -A OPTS=([size|s*=i]=)
        getoptlong init OPTS
        getoptlong parse -s 1 x -- a.txt
        echo "not reached"
    '
    assert_failure
    assert_output "x: not an integer"
}

@test "varargs: callback gets the arguments" {
    run $BASH -c '
        . ../script/getoptlong.sh
        column_opts() { echo "callback:$(printf "[%s]" "$@")" ; }
        declare -A OPTS=([column-opts|X*!]=)
        getoptlong init OPTS
        getoptlong parse -X -s " " 170 -- a.txt
        eval "$(getoptlong set)"
        echo "cols:$(printf "[%s]" "${column_opts[@]}") args:$*"
    '
    assert_success
    assert_line --index 0 "callback:[column-opts][-s][ ][170]"
    assert_line --index 1 "cols:[-s][ ][170] args:a.txt"
}

@test "varargs: pass-through" {
    run $BASH -c '
        . ../script/getoptlong.sh
        declare -A OPTS=([column-opts|X*>cols]=)
        getoptlong init OPTS
        getoptlong parse --column-opts -w 170 -- -X -s " " -- a.txt
        eval "$(getoptlong set)"
        echo "cols:$(printf "[%s]" "${cols[@]}") args:$*"
    '
    assert_success
    assert_output "cols:[--column-opts][-w][170][--][-X][-s][ ][--] args:a.txt"
}

@test "varargs: help" {
    run $BASH -c '
        . ../script/getoptlong.sh
        declare -A OPTS=([column-opts|X*]= [pane|C:]=)
        getoptlong init OPTS
        getoptlong help
    '
    assert_success
    assert_output --regexp "--column-opts #\.\.\. -- +-X #\.\.\. -- +add arguments up to -- to COLUMN-OPTS"
}

@test "varargs: with PERMUTE, options after the arguments and a file are parsed" {
    varargs_with -- -X -w -- a.txt -L b.txt
    assert_success
    assert_output "parse:0 cols:[-w] lateral:1 argv:[a.txt][b.txt]"
}

@test "varargs: with PERMUTE, another -- after a file ends the options" {
    varargs_with -- -X -w -- a.txt -- -L
    assert_success
    assert_output "parse:0 cols:[-w] lateral: argv:[a.txt][-L]"
}

@test "varargs: without PERMUTE, parse stops at a file after the arguments" {
    varargs_with PERMUTE= -- -X -w -- a.txt -L
    assert_success
    assert_output "parse:0 cols:[-w] lateral: argv:[]"
}

@test "varargs: with PERMUTE, options after no arguments and a file are parsed" {
    varargs_with -- -X -- a.txt -L b.txt
    assert_success
    assert_output "parse:0 cols:[] lateral:1 argv:[a.txt][b.txt]"
}

@test "varargs: -X-- takes -- as the value" {
    varargs_with -- -X-- a.txt -L b.txt
    assert_success
    assert_output "parse:0 cols:[--] lateral:1 argv:[a.txt][b.txt]"
}

@test "varargs: callback gets no arguments for no arguments and --no-" {
    run $BASH -c '
        . ../script/getoptlong.sh
        column_opts() { echo "callback:$#:$1" ; }
        declare -A OPTS=([column-opts|X*!]=)
        getoptlong init OPTS
        getoptlong parse -X -- --no-column-opts a.txt
    '
    assert_success
    assert_line --index 0 "callback:1:column-opts"
    assert_line --index 1 "callback:1:column-opts"
}
