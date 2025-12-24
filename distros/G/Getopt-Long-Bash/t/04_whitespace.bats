#!/usr/bin/env bats

load test_helper.bash

. ../script/getoptlong.sh

# Test: config key with surrounding spaces for alignment
@test "getoptlong: config key with surrounding spaces - [ &DEBUG ]" {
    run $BASH -c '
        . ../script/getoptlong.sh
        declare -A OPTS=(
            [verbose|v+VERB]=
            [ &DEBUG ]=1
        )
        getoptlong init OPTS
        getoptlong dump -a | grep -q "^\[&DEBUG\]=.1."
    '
    assert_success
}

# Test: config key without space (existing behavior)
@test "getoptlong: config key without space - [&DEBUG]" {
    run $BASH -c '
        . ../script/getoptlong.sh
        declare -A OPTS=(
            [verbose|v+VERB]=
            [&DEBUG]=1
        )
        getoptlong init OPTS
        getoptlong dump -a | grep -q "^\[&DEBUG\]=.1."
    '
    assert_success
}

# Test: whitespace normalization actually works
@test "getoptlong: whitespace key is normalized to non-whitespace key" {
    run $BASH -c '
        . ../script/getoptlong.sh
        declare -A OPTS=(
            [verbose|v+VERB]=
            [ &PERMUTE ]=
        )
        getoptlong init OPTS
        getoptlong dump -a | grep -q "^\[&PERMUTE\]="
    '
    assert_success
}
