#!/usr/bin/env bats

# Errors in parsing, with EXIT_ON_ERROR enabled and disabled

load test_helper.bash

# parse_with EXIT_ON_ERROR SILENT args...
# The messages of getopts are taken in the C locale.
parse_with() {
    run env LC_ALL=C $BASH -c '
        . ../script/getoptlong.sh
        declare -A OPTS=([lateral|L]= [pane|C:=i]=)
        declare -a ARGV=(untouched)
        getoptlong init OPTS PERMUTE=ARGV EXIT_ON_ERROR="$1" SILENT="$2"
        shift 2
        getoptlong parse "$@"
        echo "parse:$? lateral:$lateral pane:$pane argv:${ARGV[*]}"
    ' _ "$@"
}

##
## EXIT_ON_ERROR enabled: the script exits
##

@test "exit_on_error: enabled - unknown short option" {
    parse_with 1 '' -w
    assert_failure
    assert_output --partial "illegal option -- w"
    refute_output --partial "parse:"
}

@test "exit_on_error: enabled - unknown long option" {
    parse_with 1 '' --width
    assert_failure
    assert_output "no such option -- --width"
}

@test "exit_on_error: enabled - short option without its argument" {
    parse_with 1 '' -C
    assert_failure
    assert_output --partial "option requires an argument -- C"
    refute_output --partial "parse:"
}

@test "exit_on_error: enabled - long option without its argument" {
    parse_with 1 '' --pane
    assert_failure
    assert_output "option requires an argument -- pane"
}

@test "exit_on_error: enabled - validation error" {
    parse_with 1 '' -C x
    assert_failure
    assert_output "x: not an integer"
}

@test "exit_on_error: enabled, silent - unknown short option" {
    parse_with 1 1 -w
    assert_failure
    assert_output ""
}

@test "exit_on_error: enabled, silent - unknown long option" {
    parse_with 1 1 --width
    assert_failure
    assert_output "no such option -- --width"
}

@test "exit_on_error: enabled, silent - short option without its argument" {
    parse_with 1 1 -C
    assert_failure
    assert_output ""
}

@test "exit_on_error: enabled, silent - long option without its argument" {
    parse_with 1 1 --pane
    assert_failure
    assert_output "option requires an argument -- pane"
}

@test "exit_on_error: enabled, silent - validation error" {
    parse_with 1 1 -C x
    assert_failure
    assert_output "x: not an integer"
}

##
## EXIT_ON_ERROR disabled: parse stops at the first error and returns
## 1, and leaves the arguments as they are
##

@test "exit_on_error: disabled - unknown short option" {
    parse_with '' '' -w
    assert_success
    assert_line --index 0 --partial "illegal option -- w"
    assert_line --index 1 "parse:1 lateral: pane: argv:untouched"
}

@test "exit_on_error: disabled - unknown long option" {
    parse_with '' '' --width
    assert_success
    assert_line --index 0 "no such option -- --width"
    assert_line --index 1 "parse:1 lateral: pane: argv:untouched"
}

@test "exit_on_error: disabled - short option without its argument" {
    parse_with '' '' -C
    assert_success
    assert_line --index 0 --partial "option requires an argument -- C"
    assert_line --index 1 "parse:1 lateral: pane: argv:untouched"
}

@test "exit_on_error: disabled - long option without its argument" {
    parse_with '' '' --pane
    assert_success
    assert_line --index 0 "option requires an argument -- pane"
    assert_line --index 1 "parse:1 lateral: pane: argv:untouched"
}

@test "exit_on_error: disabled - validation error" {
    parse_with '' '' -C x
    assert_success
    assert_line --index 0 "x: not an integer"
    assert_line --index 1 "parse:1 lateral: pane: argv:untouched"
}

@test "exit_on_error: disabled, silent - unknown short option" {
    parse_with '' 1 -w
    assert_success
    assert_output "parse:1 lateral: pane: argv:untouched"
}

@test "exit_on_error: disabled, silent - unknown long option" {
    parse_with '' 1 --width
    assert_success
    assert_output "parse:1 lateral: pane: argv:untouched"
}

@test "exit_on_error: disabled, silent - short option without its argument" {
    parse_with '' 1 -C
    assert_success
    assert_output "parse:1 lateral: pane: argv:untouched"
}

@test "exit_on_error: disabled, silent - long option without its argument" {
    parse_with '' 1 --pane
    assert_success
    assert_output "parse:1 lateral: pane: argv:untouched"
}

@test "exit_on_error: disabled, silent - validation error" {
    parse_with '' 1 -C x
    assert_success
    assert_output "parse:1 lateral: pane: argv:untouched"
}

@test "exit_on_error: disabled - stops at the first error" {
    parse_with '' 1 -L -w -C2
    assert_success
    assert_output "parse:1 lateral:1 pane: argv:untouched"
}

@test "exit_on_error: disabled - unknown option joined with a value" {
    parse_with '' 1 a.txt -w170 -C2
    assert_success
    assert_output "parse:1 lateral: pane: argv:untouched"
}

@test "exit_on_error: disabled - unknown option after a known one" {
    parse_with '' 1 -Lw -C2 a.txt
    assert_success
    assert_output "parse:1 lateral:1 pane: argv:untouched"
}

@test "exit_on_error: disabled - no error" {
    parse_with '' 1 -L a.txt -C2
    assert_success
    assert_output "parse:0 lateral:1 pane:2 argv:a.txt"
}

@test "exit_on_error: disabled - the status of the one-liner form" {
    run $BASH -c '
        declare -A OPTS=([&EXIT_ON_ERROR]= [&SILENT]=1 [lateral|L]=)
        . ../script/getoptlong.sh OPTS -L -w a.txt || echo "status:$?"
        echo "lateral:$lateral args:$*"
    ' _
    assert_success
    assert_line --index 0 "status:1"
    assert_line --index 1 "lateral:1 args:"
}

@test "exit_on_error: disabled - long option given an argument it does not take" {
    parse_with '' '' --lateral=1
    assert_success
    assert_line --index 0 "does not take an argument -- lateral"
    assert_line --index 1 "parse:1 lateral: pane: argv:untouched"
}

# regex validation
regex_with() {
    run $BASH -c '
        . ../script/getoptlong.sh
        declare -A OPTS=([size|s:=($2)]=)
        getoptlong init OPTS EXIT_ON_ERROR="$1"
        shift 2
        getoptlong parse "$@"
        echo "parse:$? size:$size"
    ' _ "$@"
}

@test "exit_on_error: enabled - regex validation error" {
    regex_with 1 '^[0-9]+$' --size abc
    assert_failure
    assert_output "abc: invalid argument"
}

@test "exit_on_error: disabled - regex validation error" {
    regex_with '' '^[0-9]+$' --size abc
    assert_success
    assert_line --index 0 "abc: invalid argument"
    assert_line --index 1 "parse:1 size:"
}

@test "exit_on_error: disabled - regex validation passes" {
    regex_with '' '^[0-9]+$' --size 12
    assert_success
    assert_output "parse:0 size:12"
}

@test "exit_on_error: disabled - an invalid regex still exits" {
    regex_with '' '^[0-9+$' --size 12
    assert_failure
    assert_output --partial "(^[0-9+$): something wrong"
    refute_output --partial "parse:"
}
