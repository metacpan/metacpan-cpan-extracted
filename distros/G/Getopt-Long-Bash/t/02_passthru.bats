#!/usr/bin/env bats

# Load the helper (which loads bats-support and bats-assert)
load test_helper.bash
# Source getoptlong.sh to make its functions available for testing
. ../script/getoptlong.sh

# Test: Passthru - basic long option with value
@test "getoptlong: passthru - long option --passthru-opt val" {
    run $BASH -c '
        . ../script/getoptlong.sh
        declare -A OPTS=([passthru-opt|p:>my_passthru_array]=)
        declare -a my_passthru_array=()
        getoptlong init OPTS
        getoptlong parse --passthru-opt value1
        eval "$(getoptlong set)"
        echo "arr_len:${#my_passthru_array[@]}"
        echo "arr_0:${my_passthru_array[0]}"
        echo "arr_1:${my_passthru_array[1]}"
    '
    assert_success
    assert_line --index 0 "arr_len:2"
    assert_line --index 1 "arr_0:--passthru-opt"
    assert_line --index 2 "arr_1:value1"
}

# Test: Passthru - basic short option with value
@test "getoptlong: passthru - short option -p val" {
    run $BASH -c '
        . ../script/getoptlong.sh
        declare -A OPTS=([passthru-opt|p:>my_passthru_array]=)
        declare -a my_passthru_array=()
        getoptlong init OPTS
        getoptlong parse -p value2
        eval "$(getoptlong set)"
        echo "arr_len:${#my_passthru_array[@]}"
        echo "arr_0:${my_passthru_array[0]}"
        echo "arr_1:${my_passthru_array[1]}"
    '
    assert_success
    assert_line --index 0 "arr_len:2"
    assert_line --index 1 "arr_0:-p"
    assert_line --index 2 "arr_1:value2"
}

# Test: Passthru - flag option (no value)
@test "getoptlong: passthru - flag option --flag-opt" {
    run $BASH -c '
        . ../script/getoptlong.sh
        declare -A OPTS=([flag-opt+>my_flag_array]=)
        declare -a my_flag_array=()
        getoptlong init OPTS
        getoptlong parse --flag-opt
        eval "$(getoptlong set)"
        echo "arr_len:${#my_flag_array[@]}"
        echo "arr_0:${my_flag_array[0]}"
    '
    assert_success
    assert_line --index 0 "arr_len:1"
    assert_line --index 1 "arr_0:--flag-opt"
}

# Test: Passthru - combined with callback (!)
@test "getoptlong: passthru - combined with callback --cb-opt val" {
    run $BASH -c '
        . ../script/getoptlong.sh
        cb_func() { echo "Callback: $1 val=$2"; }
        declare -A OPTS=([cb-opt:!>my_cb_array]=)
        declare -a my_cb_array=()
        getoptlong init OPTS
        getoptlong callback cb-opt cb_func
        getoptlong parse --cb-opt cb_val
        eval "$(getoptlong set)"
        echo "arr_len:${#my_cb_array[@]}"
        echo "arr_0:${my_cb_array[0]}"
        echo "arr_1:${my_cb_array[1]}"
    '
    assert_success
    assert_output --partial "Callback: cb-opt val=cb_val"
    assert_line --index 1 "arr_len:2" # Callback output is first
    assert_line --index 2 "arr_0:--cb-opt"
    assert_line --index 3 "arr_1:cb_val"
}

# Test: Passthru - combined with required value (:)
@test "getoptlong: passthru - combined with required value --req-opt val" {
    run $BASH -c '
        . ../script/getoptlong.sh
        declare -A OPTS=([req-opt|r:>my_req_array]=) # Note the type is effectively ":>"
        declare -a my_req_array=()
        getoptlong init OPTS
        getoptlong parse --req-opt req_val
        eval "$(getoptlong set)"
        echo "arr_len:${#my_req_array[@]}"
        echo "arr_0:${my_req_array[0]}"
        echo "arr_1:${my_req_array[1]}"
    '
    assert_success
    assert_line --index 0 "arr_len:2"
    assert_line --index 1 "arr_0:--req-opt"
    assert_line --index 2 "arr_1:req_val"
}

# Test: Passthru - multiple options to the same array
@test "getoptlong: passthru - multiple options to same array" {
    run $BASH -c '
        . ../script/getoptlong.sh
        declare -A OPTS=(
            [opt1|a:>common_array]=
            [opt2|b:>common_array]=
        )
        declare -a common_array=()
        getoptlong init OPTS
        getoptlong parse --opt1 val1 -b val2 --opt1 val3
        eval "$(getoptlong set)"
        echo "arr_len:${#common_array[@]}"
        echo "arr_0:${common_array[0]}"
        echo "arr_1:${common_array[1]}"
        echo "arr_2:${common_array[2]}"
        echo "arr_3:${common_array[3]}"
        echo "arr_4:${common_array[4]}"
        echo "arr_5:${common_array[5]}"
    '
    assert_success
    assert_line --index 0 "arr_len:6"
    assert_line --index 1 "arr_0:--opt1"
    assert_line --index 2 "arr_1:val1"
    assert_line --index 3 "arr_2:-b"
    assert_line --index 4 "arr_3:val2"
    assert_line --index 5 "arr_4:--opt1"
    assert_line --index 6 "arr_5:val3"
}

# Test: Passthru - default array name (based on option name)
@test "getoptlong: passthru - default array name" {
    run $BASH -c '
        . ../script/getoptlong.sh
        declare -A OPTS=([default-array-opt+>]=) # Target array will be default_array_opt
        # Ensure default_array_opt is declared, or it might fail in strict mode or cause issues
        declare -a default_array_opt=()
        getoptlong init OPTS
        getoptlong parse --default-array-opt
        eval "$(getoptlong set)"
        echo "arr_len:${#default_array_opt[@]}"
        echo "arr_0:${default_array_opt[0]}"
    '
    assert_success
    assert_line --index 0 "arr_len:1"
    assert_line --index 1 "arr_0:--default-array-opt"
}

# Test: Passthru - help message
@test "getoptlong: passthru - help message" {
    run $BASH -c '
        . ../script/getoptlong.sh
        declare -A OPTS=(
            [my-pass|p:>pass_arr]=
            [another-pass:>another_arr]=
        )
        getoptlong init OPTS
        getoptlong help "My Script Usage"
    '
    assert_success
    assert_output --partial "passthrough to PASS_ARR"
    assert_output --partial "passthrough to ANOTHER_ARR"
}

# Test: Passthru - optional argument without value
@test "getoptlong: passthru - optional argument without value --opt" {
    run $BASH -c '
        . ../script/getoptlong.sh
        declare -A OPTS=([optional-opt|o?>opt_array]=)
        declare -a opt_array=()
        getoptlong init OPTS
        getoptlong parse --optional-opt
        eval "$(getoptlong set)"
        echo "arr_len:${#opt_array[@]}"
        echo "arr_0:${opt_array[0]}"
    '
    assert_success
    assert_line --index 0 "arr_len:1"
    assert_line --index 1 "arr_0:--optional-opt"
}

# Test: Passthru - short option attached value
@test "getoptlong: passthru - short option attached value -ovalue" {
    run $BASH -c '
        . ../script/getoptlong.sh
        declare -A OPTS=([option|o:>opt_array]=)
        declare -a opt_array=()
        getoptlong init OPTS
        getoptlong parse -oattached_value
        eval "$(getoptlong set)"
        echo "arr_len:${#opt_array[@]}"
        echo "arr_0:${opt_array[0]}"
        echo "arr_1:${opt_array[1]}"
    '
    assert_success
    assert_line --index 0 "arr_len:2"
    assert_line --index 1 "arr_0:-o"
    assert_line --index 2 "arr_1:attached_value"
}

# Test: Passthru - combined with regular options
@test "getoptlong: passthru - mixed with regular options" {
    run $BASH -c '
        . ../script/getoptlong.sh
        declare -A OPTS=(
            [regular-opt|r:]=
            [passthru-opt|p:>pass_array]=
            [flag-opt|f]=
        )
        declare -a pass_array=()
        getoptlong init OPTS
        getoptlong parse --regular-opt reg_val --passthru-opt pass_val --flag-opt
        eval "$(getoptlong set)"
        echo "regular:$regular_opt"
        echo "flag:$flag_opt"
        echo "pass_len:${#pass_array[@]}"
        echo "pass_0:${pass_array[0]}"
        echo "pass_1:${pass_array[1]}"
    '
    assert_success
    assert_line --index 0 "regular:reg_val"
    assert_line --index 1 "flag:1"
    assert_line --index 2 "pass_len:2"
    assert_line --index 3 "pass_0:--passthru-opt"
    assert_line --index 4 "pass_1:pass_val"
}


# Test: Passthru - with double dash separator
@test "getoptlong: passthru - with double dash separator" {
    run $BASH -c '
        . ../script/getoptlong.sh
        declare -A OPTS=([pass-opt|p:>pass_array]=)
        declare -a pass_array=()
        getoptlong init OPTS
        getoptlong parse --pass-opt value1 -- --pass-opt value2
        eval "$(getoptlong set)"
        echo "arr_len:${#pass_array[@]}"
        echo "arr_0:${pass_array[0]}"
        echo "arr_1:${pass_array[1]}"
        echo "remaining args: $*"
    '
    assert_success
    assert_line --index 0 "arr_len:2"
    assert_line --index 1 "arr_0:--pass-opt"
    assert_line --index 2 "arr_1:value1"
    assert_line --index 3 "remaining args: --pass-opt value2"
}

# Test: Passthru - simple flag option
@test "getoptlong: passthru - simple flag option --feature" {
    run $BASH -c '
        . ../script/getoptlong.sh
        declare -A OPTS=([feature+>feature_array]=)
        declare -a feature_array=()
        getoptlong init OPTS
        getoptlong parse --feature
        eval "$(getoptlong set)"
        echo "arr_len:${#feature_array[@]}"
        echo "arr_0:${feature_array[0]}"
    '
    assert_success
    assert_line --index 0 "arr_len:1"
    assert_line --index 1 "arr_0:--feature"
}


# Test: Passthru - bundled short options
@test "getoptlong: passthru - bundled short options -abc" {
    run $BASH -c '
        . ../script/getoptlong.sh
        declare -A OPTS=(
            [opt-a|a+>opt_a_array]=
            [opt-b|b+>opt_b_array]=
            [opt-c|c:>opt_c_array]=
        )
        declare -a opt_a_array=() opt_b_array=() opt_c_array=()
        getoptlong init OPTS
        getoptlong parse -abc value_for_c
        eval "$(getoptlong set)"
        echo "a_len:${#opt_a_array[@]}"
        echo "b_len:${#opt_b_array[@]}"
        echo "c_len:${#opt_c_array[@]}"
        echo "a_0:${opt_a_array[0]}"
        echo "b_0:${opt_b_array[0]}"
        echo "c_0:${opt_c_array[0]}"
        echo "c_1:${opt_c_array[1]}"
    '
    assert_success
    assert_line --index 0 "a_len:1"
    assert_line --index 1 "b_len:1"
    assert_line --index 2 "c_len:2"
    assert_line --index 3 "a_0:-a"
    assert_line --index 4 "b_0:-b"
    assert_line --index 5 "c_0:-c"
    assert_line --index 6 "c_1:value_for_c"
}

# Test: Passthru - performance with many options
@test "getoptlong: passthru - many options performance test" {
    run $BASH -c '
        . ../script/getoptlong.sh
        declare -A OPTS=([multi-opt|m:>multi_array]=)
        declare -a multi_array=()
        getoptlong init OPTS
        
        # Add 10 options to test array handling
        args=""
        for i in {1..10}; do
            args="$args --multi-opt value$i"
        done
        
        getoptlong parse $args
        eval "$(getoptlong set)"
        echo "arr_len:${#multi_array[@]}"
        echo "first:${multi_array[0]}"
        echo "second:${multi_array[1]}"
        echo "last_opt:${multi_array[18]}"
        echo "last_val:${multi_array[19]}"
    '
    assert_success
    assert_line --index 0 "arr_len:20"  # 10 options * 2 (option + value)
    assert_line --index 1 "first:--multi-opt"
    assert_line --index 2 "second:value1"
    assert_line --index 3 "last_opt:--multi-opt"
    assert_line --index 4 "last_val:value10"
}

# Test: Passthru - with validation rules (should not validate passthru values)
@test "getoptlong: passthru - with validation rules (bypassed)" {
    run $BASH -c '
        . ../script/getoptlong.sh
        declare -A OPTS=([number-opt:>num_array=i]=)  # Integer validation
        declare -a num_array=()
        getoptlong init OPTS
        getoptlong parse --number-opt "not_a_number"
        eval "$(getoptlong set)"
        echo "arr_len:${#num_array[@]}"
        echo "arr_0:${num_array[0]}"
        echo "arr_1:${num_array[1]}"
    '
    assert_success  # Should succeed because passthru bypasses validation
    assert_line --index 0 "arr_len:2"
    assert_line --index 1 "arr_0:--number-opt"
    assert_line --index 2 "arr_1:not_a_number"
}

# Test: Passthru - negated flag option --no-debug
@test "getoptlong: passthru - negated flag option --no-debug" {
    run $BASH -c '
        . ../script/getoptlong.sh
        declare -A OPTS=([debug+>debug_array]=)
        declare -a debug_array=()
        getoptlong init OPTS
        getoptlong parse --no-debug
        eval "$(getoptlong set)"
        echo "arr_len:${#debug_array[@]}"
        echo "arr_0:${debug_array[0]}"
    '
    assert_success
    assert_line --index 0 "arr_len:1"
    assert_line --index 1 "arr_0:--no-debug"
}

# Test: Passthru - negated option with required arg --no-pager
@test "getoptlong: passthru - negated option with required arg --no-pager" {
    run $BASH -c '
        . ../script/getoptlong.sh
        declare -A OPTS=([pager:>pager_array]=)
        declare -a pager_array=()
        getoptlong init OPTS
        getoptlong parse --no-pager
        eval "$(getoptlong set)"
        echo "arr_len:${#pager_array[@]}"
        echo "arr_0:${pager_array[0]}"
    '
    assert_success
    assert_line --index 0 "arr_len:1"
    assert_line --index 1 "arr_0:--no-pager"
}

# Test: Passthru - mixed negated and normal options
@test "getoptlong: passthru - mixed negated and normal options" {
    run $BASH -c '
        . ../script/getoptlong.sh
        declare -A OPTS=([feature+>pass_array]=)
        declare -a pass_array=()
        getoptlong init OPTS
        getoptlong parse --feature --no-feature --feature
        eval "$(getoptlong set)"
        echo "arr_len:${#pass_array[@]}"
        echo "arr_0:${pass_array[0]}"
        echo "arr_1:${pass_array[1]}"
        echo "arr_2:${pass_array[2]}"
    '
    assert_success
    assert_line --index 0 "arr_len:3"
    assert_line --index 1 "arr_0:--feature"
    assert_line --index 2 "arr_1:--no-feature"
    assert_line --index 3 "arr_2:--feature"
}
