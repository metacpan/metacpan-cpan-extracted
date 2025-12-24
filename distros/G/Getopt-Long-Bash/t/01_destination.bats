#!/usr/bin/env bats

load test_helper.bash

. ../script/getoptlong.sh

# Test: Basic flag option (--verbose)
@test "getoptlong: flag - long option --verbose" {
    run $BASH -c '
        . ../script/getoptlong.sh
        # getoptlong.sh is sourced above by the test file itself
        declare -A OPTS=([verbose|v+VERB]=)
        getoptlong init OPTS
        getoptlong parse foo --verbose
        eval "$(getoptlong set)"
        echo "verbose_val:$VERB"
    '
    assert_success # bats-assert
    assert_output "verbose_val:1"
}

# Test: Basic flag option (-v)
@test "getoptlong: flag - short option -v" {
    run $BASH -c '
        . ../script/getoptlong.sh
        declare -A OPTS=([verbose|v+VERB]=)
        getoptlong init OPTS
        getoptlong parse -v
        eval "$(getoptlong set)"
        echo "verbose_val:$VERB"
    '
    assert_success
    assert_output "verbose_val:1"
}

# Test: Flag option, incrementing (-d -d)
@test "getoptlong: flag - incrementing -d -d -dd --debug" {
    run $BASH -c '
        . ../script/getoptlong.sh
        declare -A OPTS=([debug|d+DEB]=0)
        getoptlong init OPTS
        getoptlong parse -d -d -dd --debug
        eval "$(getoptlong set)"
        echo "debug_val:$DEB"
    '
    assert_success
    assert_output "debug_val:5"
}

# Test: Flag option, negated (--no-feature)
@test "getoptlong: flag - negated --no-feature" {
    run $BASH -c '
        . ../script/getoptlong.sh
        declare -A OPTS=([feature|f+FEA]=1)
        getoptlong init OPTS
        getoptlong parse --no-feature
        eval "$(getoptlong set)"
        echo "feature_val:$FEA"
    '
    assert_success
    assert_output "feature_val:"
}

# Test: Option with required argument (--file data.txt)
@test "getoptlong: required arg - long --file data.txt" {
    run $BASH -c '
        . ../script/getoptlong.sh
        declare -A OPTS=([file|f:FILE]=)
        getoptlong init OPTS
        getoptlong parse --file data.txt
        eval "$(getoptlong set)"
        echo "file_val:$FILE"
    '
    assert_success
    assert_output "file_val:data.txt"
}

# Test: Option with optional argument (--optarg=value)
@test "getoptlong: optional arg - long --optarg=value" {
    run $BASH -c '
        . ../script/getoptlong.sh
        declare -A OPTS=([optarg|o?ARG]=)
        getoptlong init OPTS
        getoptlong parse --optarg=value
        eval "$(getoptlong set)"
        echo "optarg_val:$ARG"
    '
    assert_success
    assert_output "optarg_val:value"
}

# Test: Array option (--item val1 --item val2)
@test "getoptlong: array option - long --item val1 --item val2" {
    run $BASH -c '
        . ../script/getoptlong.sh
        declare -A OPTS=([item|i@ARRAY]=)
        getoptlong init OPTS
        getoptlong parse --item val1 --item val2
        eval "$(getoptlong set)"
        echo "item_vals:${ARRAY[*]}"
    '
    assert_success
    assert_output "item_vals:val1 val2"
}

# Test: Hash option (--data key1=val1 --data key2=val2)
@test "getoptlong: hash option - long --data k1=v1 --data k2=v2" {
    run $BASH -c '
        . ../script/getoptlong.sh
        declare -A OPTS=([data|D%HASH]=)
        getoptlong init OPTS
        getoptlong parse --data k1=v1 --data k2=v2
        eval "$(getoptlong set)"
        echo "data_k1:${HASH[k1]}"
        echo "data_k2:${HASH[k2]}"
    '
    assert_success
    assert_line --index 0 "data_k1:v1"
    assert_line --index 1 "data_k2:v2"
}

# Test: Variable name conflict - MARKS
@test "getoptlong: destination variable - MARKS" {
    run $BASH -c '
        . ../script/getoptlong.sh
        declare -A OPTS=([verbose|v+MARKS]=)
        getoptlong init OPTS
        getoptlong parse --verbose
        eval "$(getoptlong set)"
        echo "MARKS:$MARKS"
    '
    assert_success
    assert_output "MARKS:1"
}

# Test: Variable name conflict - CONFIG
@test "getoptlong: destination variable - CONFIG" {
    run $BASH -c '
        . ../script/getoptlong.sh
        declare -A OPTS=([level|l+CONFIG]=0)
        getoptlong init OPTS
        getoptlong parse -ll
        eval "$(getoptlong set)"
        echo "CONFIG:$CONFIG"
    '
    assert_success
    assert_output "CONFIG:2"
}

# Test: Variable name conflict - MATCH
@test "getoptlong: destination variable - MATCH" {
    run $BASH -c '
        . ../script/getoptlong.sh
        declare -A OPTS=([count|c:MATCH=i]=)
        getoptlong init OPTS
        getoptlong parse --count 42
        eval "$(getoptlong set)"
        echo "MATCH:$MATCH"
    '
    assert_success
    assert_output "MATCH:42"
}

# Test: Config variable as destination - DEBUG
@test "getoptlong: destination variable - DEBUG" {
    run $BASH -c '
        . ../script/getoptlong.sh
        declare -A OPTS=([level|l+DEBUG]=0)
        getoptlong init OPTS
        getoptlong parse -ll
        eval "$(getoptlong set)"
        echo "DEBUG:$DEBUG"
    '
    assert_success
    assert_output "DEBUG:2"
}

# Test: Config variable as destination - HELP
@test "getoptlong: destination variable - HELP" {
    run $BASH -c '
        . ../script/getoptlong.sh
        declare -A OPTS=([message|m:HELP]=)
        getoptlong init OPTS
        getoptlong parse --message "usage info"
        eval "$(getoptlong set)"
        echo "HELP:$HELP"
    '
    assert_success
    assert_output "HELP:usage info"
}

# Test: Config variable as destination - PREFIX
@test "getoptlong: destination variable - PREFIX" {
    run $BASH -c '
        . ../script/getoptlong.sh
        declare -A OPTS=([namespace|n:PREFIX]=)
        getoptlong init OPTS
        getoptlong parse --namespace "app_"
        eval "$(getoptlong set)"
        echo "PREFIX:$PREFIX"
    '
    assert_success
    assert_output "PREFIX:app_"
}

# Test: Config variable as destination - DELIM
@test "getoptlong: destination variable - DELIM" {
    run $BASH -c '
        . ../script/getoptlong.sh
        declare -A OPTS=([separator|s:DELIM]= [values|v@]=)
        getoptlong init OPTS
        getoptlong parse --separator ":" --values "a:b:c"
        eval "$(getoptlong set)"
        echo "DELIM:$DELIM"
        echo "values:${values[*]}"
    '
    assert_success
    assert_line --index 0 "DELIM::"
    assert_line --index 1 "values:a:b:c"
}

# Test: Config variable as destination - PERMUTE
@test "getoptlong: destination variable - PERMUTE" {
    run $BASH -c '
        . ../script/getoptlong.sh
        declare -A OPTS=([mode|m:PERMUTE]=)
        getoptlong init OPTS
        getoptlong parse --mode "strict"
        eval "$(getoptlong set)"
        echo "PERMUTE:$PERMUTE"
    '
    assert_success
    assert_output "PERMUTE:strict"
}

# Test: Config variable as destination - REQUIRE
@test "getoptlong: destination variable - REQUIRE" {
    run $BASH -c '
        . ../script/getoptlong.sh
        declare -A OPTS=([version|v:REQUIRE]=)
        getoptlong init OPTS
        getoptlong parse --version "0.05"
        eval "$(getoptlong set)"
        echo "REQUIRE:$REQUIRE"
    '
    assert_success
    assert_output "REQUIRE:0.05"
}

# Test: Config variable as destination - SILENT
@test "getoptlong: destination variable - SILENT" {
    run $BASH -c '
        . ../script/getoptlong.sh
        declare -A OPTS=([quiet|q+SILENT]=)
        getoptlong init OPTS
        getoptlong parse --quiet
        eval "$(getoptlong set)"
        echo "SILENT:$SILENT"
    '
    assert_success
    assert_output "SILENT:1"
}

# Test: Config variable as destination - EXIT_ON_ERROR
@test "getoptlong: destination variable - EXIT_ON_ERROR" {
    run $BASH -c '
        . ../script/getoptlong.sh
        declare -A OPTS=([strict|s+EXIT_ON_ERROR]=)
        getoptlong init OPTS
        getoptlong parse --strict
        eval "$(getoptlong set)"
        echo "EXIT_ON_ERROR:$EXIT_ON_ERROR"
    '
    assert_success
    assert_output "EXIT_ON_ERROR:1"
}

# Test: Config variable as destination - USAGE
@test "getoptlong: destination variable - USAGE" {
    run $BASH -c '
        . ../script/getoptlong.sh
        declare -A OPTS=([help-text|h:USAGE]=)
        getoptlong init OPTS
        getoptlong parse --help-text "custom usage"
        eval "$(getoptlong set)"
        echo "USAGE:$USAGE"
    '
    assert_success
    assert_output "USAGE:custom usage"
}
