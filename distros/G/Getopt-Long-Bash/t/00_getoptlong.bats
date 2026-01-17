#!/usr/bin/env bats

# Load the helper (which loads bats-support and bats-assert)
load test_helper.bash
# Source getoptlong.sh to make its functions available for testing
. ../script/getoptlong.sh

# Test: getoptlong init and version
@test "getoptlong: init and version" {
    run getoptlong version # Directly run the function
    assert_success # Provided by bats-assert
    assert_output -e "[0-9]+.[0-9]+"
}

# Test: Basic flag option (--verbose)
@test "getoptlong: flag - long option --verbose" {
    run $BASH -c '
        . ../script/getoptlong.sh
        # getoptlong.sh is sourced above by the test file itself
        declare -A OPTS=([verbose|v]=)
        getoptlong init OPTS
        getoptlong parse foo --verbose
        eval "$(getoptlong set)"
        echo "verbose_val:$verbose"
    '
    assert_success # bats-assert
    assert_output "verbose_val:1"
}

# Test: Basic flag option (--verbose)
@test "getoptlong: flag - long option --verbose (PERMUTE=)" {
    run $BASH -c '
        . ../script/getoptlong.sh
        # getoptlong.sh is sourced above by the test file itself
        declare -A OPTS=([verbose|v]=)
        getoptlong init OPTS PERMUTE=
        getoptlong parse foo --verbose
        eval "$(getoptlong set)"
        echo "verbose_val:$verbose"
    '
    assert_success # bats-assert
    assert_output "verbose_val:"
}

# Test: Basic flag option (-v)
@test "getoptlong: flag - short option -v" {
    run $BASH -c '
        . ../script/getoptlong.sh
        declare -A OPTS=([verbose|v]=)
        getoptlong init OPTS
        getoptlong parse -v
        eval "$(getoptlong set)"
        echo "verbose_val:$verbose"
    '
    assert_success
    assert_output "verbose_val:1"
}

@test "getoptlong: - in the option name --help-me" {
    run $BASH -c '
        . ../script/getoptlong.sh
        declare -A OPTS=([help-me|h]=)
        getoptlong init OPTS
        getoptlong parse foo --help-me
        eval "$(getoptlong set)"
        echo "help_me:$help_me"
    '
    assert_success
    assert_output "help_me:1"
}

# Test: Flag option, incrementing (-d -d)
@test "getoptlong: flag - incrementing -d -d -dd --debug" {
    run $BASH -c '
        . ../script/getoptlong.sh
        declare -A OPTS=([debug|d]=0)
        getoptlong init OPTS
        getoptlong parse -d -d -dd --debug
        eval "$(getoptlong set)"
        echo "debug_val:$debug"
    '
    assert_success
    assert_output "debug_val:5"
}

# Test: Flag option, negated (--no-feature)
@test "getoptlong: flag - negated --no-feature" {
    run $BASH -c '
        . ../script/getoptlong.sh
        declare -A OPTS=([feature|f]=1)
        getoptlong init OPTS
        getoptlong parse --no-feature
        eval "$(getoptlong set)"
        echo "feature_val:$feature"
    '
    assert_success
    assert_output "feature_val:"
}

# Test: Flag option, repeated long options
@test "getoptlong: flag - repeated long --level --level --level" {
    run $BASH -c '
        . ../script/getoptlong.sh
        declare -A OPTS=([level|l]=0)
        getoptlong init OPTS
        getoptlong parse --level --level --level
        eval "$(getoptlong set)"
        echo "level_val:$level"
    '
    assert_success
    assert_output "level_val:3"
}

# Test: Flag option, repeated short options
@test "getoptlong: flag - repeated short -l -l -l" {
    run $BASH -c '
        . ../script/getoptlong.sh
        declare -A OPTS=([level|l]=0)
        getoptlong init OPTS
        getoptlong parse -l -l -l
        eval "$(getoptlong set)"
        echo "level_val:$level"
    '
    assert_success
    assert_output "level_val:3"
}

# Test: Flag option, mixed long and short
@test "getoptlong: flag - mixed --level -l --level" {
    run $BASH -c '
        . ../script/getoptlong.sh
        declare -A OPTS=([level|l]=0)
        getoptlong init OPTS
        getoptlong parse --level -l --level
        eval "$(getoptlong set)"
        echo "level_val:$level"
    '
    assert_success
    assert_output "level_val:3"
}

# Test: Option with required argument (--file data.txt)
@test "getoptlong: required arg - long --file data.txt" {
    run $BASH -c '
        . ../script/getoptlong.sh
        declare -A OPTS=([file|f:]=)
        getoptlong init OPTS
        getoptlong parse --file data.txt
        eval "$(getoptlong set)"
        echo "file_val:$file"
    '
    assert_success
    assert_output "file_val:data.txt"
}

# Test: Option with required argument (-f data.txt)
@test "getoptlong: required arg - short -f data.txt" {
    run $BASH -c '
        . ../script/getoptlong.sh
        declare -A OPTS=([file|f:]=)
        getoptlong init OPTS
        getoptlong parse -f data.txt
        eval "$(getoptlong set)"
        echo "file_val:$file"
    '
    assert_success
    assert_output "file_val:data.txt"
}

# Test: Option with required argument (-fdata.txt, attached)
@test "getoptlong: required arg - short -fdata.txt (attached)" {
    run $BASH -c '
        . ../script/getoptlong.sh
        declare -A OPTS=([file|f:]=)
        getoptlong init OPTS
        getoptlong parse -fdata.txt
        eval "$(getoptlong set)"
        echo "file_val:$file"
    '
    assert_success
    assert_output "file_val:data.txt"
}

# Test: Option with required argument (not given, should retain default from OPTS array)
@test "getoptlong: required arg - not given (retain default)" {
    run $BASH -c '
        . ../script/getoptlong.sh
        declare -A OPTS=([file|f:]=default)
        getoptlong init OPTS
        getoptlong parse # No args
        eval "$(getoptlong set)"
        echo "file_val:$file"
    '
    assert_success
    assert_output "file_val:default"
}

# Test: Option with optional argument (--optarg=value)
@test "getoptlong: optional arg - long --optarg=value" {
    run $BASH -c '
        . ../script/getoptlong.sh
        declare -A OPTS=([optarg|o?]=)
        getoptlong init OPTS
        getoptlong parse --optarg=value
        eval "$(getoptlong set)"
        echo "optarg_val:$optarg"
    '
    assert_success
    assert_output "optarg_val:value"
}

# Test: Option with optional argument (--optarg, no value provided)
@test "getoptlong: optional arg - long --optarg (no value)" {
    run $BASH -c '
        . ../script/getoptlong.sh
        declare -A OPTS=([optarg|o?]=)
        getoptlong init OPTS
        getoptlong parse --optarg
        eval "$(getoptlong set)"
        echo "optarg_val:$optarg"
    '
    assert_success
    assert_output "optarg_val:"
}

# Test: Array option (--item val1 --item val2)
@test "getoptlong: array option - long --item val1 --item val2" {
    run $BASH -c '
        . ../script/getoptlong.sh
        declare -A OPTS=([item|i@]=)
        getoptlong init OPTS
        getoptlong parse --item val1 --item val2
        eval "$(getoptlong set)"
        echo "item_vals:${item[*]}"
    '
    assert_success
    assert_output "item_vals:val1 val2"
}

# Test: Array option (-i val1 -i val2)
@test "getoptlong: array option - short -i val1 -i val2" {
    run $BASH -c '
        . ../script/getoptlong.sh
        declare -A OPTS=([item|i@]=)
        getoptlong init OPTS
        getoptlong parse -i val1 -i val2
        eval "$(getoptlong set)"
        echo "item_vals:${item[*]}"
    '
    assert_success
    assert_output "item_vals:val1 val2"
}

# Test: Array option (--item=val1,val2,val3 comma separated)
# This test was identified as problematic due to EOF error, ensure quotes are correct.
@test "getoptlong: array option - long --item=v1,v2,v3 (comma separated)" {
    run $BASH -c '
        . ../script/getoptlong.sh
        declare -A OPTS=([item|i@]=)
        getoptlong init OPTS
        getoptlong parse --item=v1,v2,v3
        eval "$(getoptlong set)"
        echo "item_vals:${item[*]}"
    ' # Ensure this closing quote for $BASH -c is present and correct
    assert_success
    assert_output "item_vals:v1 v2 v3"
}

@test "getoptlong: array option - long --item=v1,v2,v3 (DELIM=\$' \t')" {
    run $BASH <<'    END'
        . ../script/getoptlong.sh
        declare -A OPTS=([item|i@]=)
        getoptlong init OPTS DELIM=$' \t'
        getoptlong parse --item=v1,v2,v3
        eval "$(getoptlong set)"
        echo "item_vals:${item[*]}"
    END
    assert_success
    assert_output "item_vals:v1,v2,v3"
}

@test "getoptlong: array option - long --item=v  1\nv  2\nv  3\n (newline separated)" {
    run $BASH <<'    END'
        . ../script/getoptlong.sh
        declare -A OPTS=([item|i@]=)
        getoptlong init OPTS
        getoptlong parse --item=$'v  1\nv  2\nv  3\n'
        eval "$(getoptlong set)"
        echo item_vals: "${item[@]}"
    END
    assert_success
    assert_output "item_vals: v  1 v  2 v  3"
}

# Test: Array option reset with --no-item
@test "getoptlong: array option - --no-item resets array" {
    run $BASH -c '
        . ../script/getoptlong.sh
        declare -A OPTS=([item|i@]="(a b c)")
        getoptlong init OPTS
        getoptlong parse --no-item
        eval "$(getoptlong set)"
        echo "item_count:${#item[@]}"
    '
    assert_success
    assert_output "item_count:0"
}

# Test: Array option reset then add with --no-item --item=x
@test "getoptlong: array option - --no-item --item=x resets then adds" {
    run $BASH -c '
        . ../script/getoptlong.sh
        declare -A OPTS=([item|i@]="(a b c)")
        getoptlong init OPTS
        getoptlong parse --no-item --item=x
        eval "$(getoptlong set)"
        echo "item_vals:${item[*]}"
    '
    assert_success
    assert_output "item_vals:x"
}

# Test: Hash option (--data key1=val1 --data key2=val2)
@test "getoptlong: hash option - long --data k1=v1 --data k2=v2" {
    run $BASH -c '
        . ../script/getoptlong.sh
        declare -A OPTS=([data|D%]=)
        getoptlong init OPTS
        getoptlong parse --data k1=v1 --data k2=v2
        eval "$(getoptlong set)"
        echo "data_k1:${data[k1]}"
        echo "data_k2:${data[k2]}"
    '
    assert_success
    assert_line --index 0 "data_k1:v1"
    assert_line --index 1 "data_k2:v2"
}

# Test: Hash option (-D k1=v1 -D k2=v2)
@test "getoptlong: hash option - short -D k1=v1 -D k2=v2" {
    run $BASH -c '
        . ../script/getoptlong.sh
        declare -A OPTS=([data|D%]=)
        getoptlong init OPTS
        getoptlong parse -D k1=v1 -D k2=v2
        eval "$(getoptlong set)"
        echo "data_k1:${data[k1]}"
        echo "data_k2:${data[k2]}"
    '
    assert_success
    assert_line --index 0 "data_k1:v1"
    assert_line --index 1 "data_k2:v2"
}

@test "getoptlong: hash option - short -D k1=v1,k2=v2" {
    run $BASH -c '
        . ../script/getoptlong.sh
        declare -A OPTS=([data|D%]=)
        getoptlong init OPTS
        getoptlong parse -D k1=v1,k2=v2
        eval "$(getoptlong set)"
        echo "data_k1:${data[k1]}"
        echo "data_k2:${data[k2]}"
    '
    assert_success
    assert_line --index 0 "data_k1:v1"
    assert_line --index 1 "data_k2:v2"
}

@test "getoptlong: hash option - short -D F'k1=v  1,k2=v  2\n' (newline separated)" {
    run $BASH << 'END'
        . ../script/getoptlong.sh
        declare -A OPTS=([data|D%]=)
        getoptlong init OPTS
        getoptlong parse -D $'k1=v  1\nk2=v  2\n'
        eval "$(getoptlong set)"
        echo "data_k1:${data[k1]}"
        echo "data_k2:${data[k2]}"
END
    assert_success
    assert_line --index 0 "data_k1:v  1"
    assert_line --index 1 "data_k2:v  2"
}

# Test: Hash option reset with --no-data
@test "getoptlong: hash option - --no-data resets hash" {
    run $BASH -c '
        . ../script/getoptlong.sh
        declare -A OPTS=([data|D%]=)
        declare -A data=([k1]=v1 [k2]=v2)
        getoptlong init OPTS
        getoptlong parse --no-data
        eval "$(getoptlong set)"
        echo "data_count:${#data[@]}"
    '
    assert_success
    assert_output "data_count:0"
}

# Test: Hash option reset then add with --no-data --data=x=y
@test "getoptlong: hash option - --no-data --data=x=y resets then adds" {
    run $BASH -c '
        . ../script/getoptlong.sh
        declare -A OPTS=([data|D%]=)
        declare -A data=([k1]=v1 [k2]=v2)
        getoptlong init OPTS
        getoptlong parse --no-data --data=x=y
        eval "$(getoptlong set)"
        echo "data_count:${#data[@]}"
        echo "data_x:${data[x]}"
    '
    assert_success
    assert_line --index 0 "data_count:1"
    assert_line --index 1 "data_x:y"
}

# Test: Integer validation (=i) - valid
@test "getoptlong: validation - integer (=i) - valid" {
    run $BASH -c '
        . ../script/getoptlong.sh
        declare -A OPTS=([count|c:=i]=0)
        getoptlong init OPTS
        getoptlong parse --count 123
        eval "$(getoptlong set)"
        echo "count_val:$count"
    '
    assert_success
    assert_output "count_val:123"
}

# Test: Integer validation (=i) - invalid (check stderr)
@test "getoptlong: validation - integer (=i) - invalid (stderr)" {
    run $BASH -c '
        . ../script/getoptlong.sh
        declare -A OPTS=([count|c:=i]=0)
        getoptlong init OPTS EXIT_ON_ERROR=1
        getoptlong parse --count abc
        echo "SHOULD_NOT_SEE_THIS" # Should exit before this
    '
    assert_failure # bats-assert
    # bats-assert can check stderr directly using `assert_output --stderr ...`
    # For simplicity here, we rely on failure and previous knowledge of error message.
    # A more robust test would be:
    # assert_output --stderr --partial "abc: not an integer"
    # However, need to ensure stdout is empty or also asserted.
    # Let's stick to simple failure for now, assuming error message goes to stderr.
    # To check stderr with bats-assert:
    # run $BASH -c '...'
    # assert_failure
    # assert_output --stderr --partial "abc: not an integer"
    # For now, just:
    [ "$status" -ne 0 ] # Redundant if assert_failure is used, but explicit
    # And we assume the error message was printed to stderr by getoptlong.sh
    # We can't directly assert stderr content with assert_output if it also checks stdout
    # unless we capture them separately or use --partial for combined output.
    # The `run` command in bats stores stdout in `$output` and stderr in `$stderr`.
    assert_output "abc: not an integer"
}

# Test: Float validation (=f) - valid
@test "getoptlong: validation - float (=f) - valid" {
    run $BASH -c '
        . ../script/getoptlong.sh
        declare -A OPTS=([value|v:=f]=0)
        getoptlong init OPTS
        getoptlong parse --value 3.14
        eval "$(getoptlong set)"
        echo "value_val:$value"
    '
    assert_success
    assert_output "value_val:3.14"
}

# Test: Regex validation (=(regex)) - valid
@test "getoptlong: validation - regex (=(regex)) - valid" {
    run $BASH -c '
        . ../script/getoptlong.sh
        declare -A OPTS=([mode|m:=(^(fast|slow)$)]=)
        getoptlong init OPTS
        getoptlong parse --mode fast
        eval "$(getoptlong set)"
        echo "mode_val:$mode"
    '
    assert_success
    assert_output "mode_val:fast"
}

# Test: Callback execution
@test "getoptlong: callback - basic execution" {
    run $BASH -c '
        . ../script/getoptlong.sh
        my_callback() { echo "Callback invoked with value: $*"; }
        declare -A OPTS=([action|a:]=)
        getoptlong init OPTS
        getoptlong callback action "my_callback --with-option" # Register callback
        getoptlong parse --action perform_action # Parse options
        eval "$(getoptlong set)" # Set variables
        # Callback output should be part of stdout if it echos.
    '
    assert_success
    assert_output --partial "Callback invoked with value: action --with-option perform_action"
}

@test "getoptlong: callback --before" {
    run $BASH -c '
        . ../script/getoptlong.sh
        my_callback() { echo "Callback invoked with value: $*"; }
        declare -A OPTS=([action|a:]=)
        getoptlong init OPTS
        getoptlong callback --before action "my_callback --with-option" # Register callback
        getoptlong parse --action perform_action # Parse options
        eval "$(getoptlong set)" # Set variables
        # Callback output should be part of stdout if it echos.
    '
    assert_success
    assert_output --partial "Callback invoked with value: action --with-option"
}

@test "getoptlong: callback type option" {
    run $BASH -c '
        . ../script/getoptlong.sh
        action() { echo "Callback invoked with value: $*"; }
        declare -A OPTS=([action|a!]=)
        getoptlong init OPTS
        getoptlong parse --action
        eval "$(getoptlong set)"
    '
    assert_success
    assert_output --partial "Callback invoked with value: action 1"
}

@test "getoptlong: callback type option with arg" {
    run $BASH -c '
        . ../script/getoptlong.sh
        action() { echo "Callback invoked with value: $*"; }
        declare -A OPTS=([action|a:!]=)
        getoptlong init OPTS
        getoptlong parse --action=hiho
        eval "$(getoptlong set)"
    '
    assert_success
    assert_output --partial "Callback invoked with value: action hiho"
}

@test "getoptlong: callback type option with hyphen" {
    run $BASH -c '
        . ../script/getoptlong.sh
        list_themes() { echo "Callback invoked: $*"; }
        declare -A OPTS=([list-themes!]=)
        getoptlong init OPTS
        getoptlong parse --list-themes
        eval "$(getoptlong set)"
    '
    assert_success
    assert_output --partial "Callback invoked: list-themes 1"
}

# Test: PREFIX option
@test "getoptlong: configuration - PREFIX=test_" {
    run $BASH -c '
        . ../script/getoptlong.sh
        declare -A OPTS=([long|l]=)
        getoptlong init OPTS PREFIX=test_
        getoptlong parse --long
        eval "$(getoptlong set)"
        echo "test_long_val:$test_long"
    '
    assert_success
    assert_output "test_long_val:1"
}

# Test: PERMUTE option for non-option arguments
@test "getoptlong: configuration - PERMUTE" {
    run $BASH -c '
        . ../script/getoptlong.sh
        declare -A OPTS=([verbose|v]=)
        declare -a GOL_MYARGS=()
        getoptlong init OPTS PERMUTE=GOL_MYARGS
        getoptlong parse arg1 --verbose arg2 -- arg3
        eval "$(getoptlong set)"
        echo "verbose_is:$verbose"
        echo "permuted_args:${GOL_MYARGS[*]}"
    '
    assert_success
    assert_line --index 0 "verbose_is:1"
    assert_line --index 1 "permuted_args:arg1 arg2 arg3"
}

@test "getoptlong: configuration - PERMUTE=" {
    run $BASH -c '
        . ../script/getoptlong.sh
        declare -A OPTS=([debug|d]= [verbose|v]=)
        getoptlong init OPTS PERMUTE=
        set -- --debug arg1 --verbose arg2 arg3
        getoptlong parse "$@"
        eval "$(getoptlong set)"
        echo "debug_is:$debug"
        echo "verbose_is:$verbose"
        echo "permuted_args:$@"
    '
    assert_success
    assert_line --index 0 "debug_is:1"
    assert_line --index 1 "verbose_is:"
    assert_line --index 2 "permuted_args:arg1 --verbose arg2 arg3"
}

@test "getoptlong: stop by --" {
    run $BASH -c '
        . ../script/getoptlong.sh
        declare -A OPTS=([debug|d]= [verbose|v]=)
        getoptlong init OPTS
        set -- --debug arg1 -- --verbose arg2 arg3
        getoptlong parse "$@"
        eval "$(getoptlong set)"
        echo "debug_is:$debug"
        echo "verbose_is:$verbose"
        echo "permuted_args:$@"
    '
    assert_success
    assert_line --index 0 "debug_is:1"
    assert_line --index 1 "verbose_is:"
    assert_line --index 2 "permuted_args:arg1 --verbose arg2 arg3"
}

# Test: Combined short options (-xvf value)
@test "getoptlong: combined short options -xvf value" {
  run $BASH -c '
        . ../script/getoptlong.sh
        declare -A OPTS=([xflag|x]= [vflag|v]= [file|f:]=)
        getoptlong init OPTS
        getoptlong parse -xvf somefile
        eval "$(getoptlong set)"
        echo "x:$xflag v:$vflag f:$file"
  '
  assert_success
  assert_output "x:1 v:1 f:somefile"
}

# Test: Unknown long option (should produce error on stderr)
@test "getoptlong: error - unknown long option" {
  run $BASH -c '
        . ../script/getoptlong.sh
        declare -A OPTS=([known]=)
        getoptlong init OPTS EXIT_ON_ERROR=1
        getoptlong parse --unknown-option
        echo "Should not be reached"
  '
  assert_failure # From bats-assert
  # Stderr is in $stderr, stdout in $output
  assert_output "no such option -- --unknown-option"
}

# Test: Option requires argument, but not given (stderr)
@test "getoptlong: error - required arg missing" {
  run $BASH -c '
        . ../script/getoptlong.sh
        declare -A OPTS=([myfile|f:]=)
        getoptlong init OPTS EXIT_ON_ERROR=1
        getoptlong parse --myfile
        echo "Should not be reached"
  '
  assert_failure # From bats-assert
  assert_output "option requires an argument -- myfile"
}

# Test: --no-X prefix for required argument option sets empty string
@test "getoptlong: required arg - negated --no-pager sets empty string" {
  run $BASH -c '
        . ../script/getoptlong.sh
        declare -A OPTS=([pager|p:]=default_pager)
        getoptlong init OPTS
        getoptlong parse --no-pager
        eval "$(getoptlong set)"
        echo "pager_val:[$pager]"
  '
  assert_success
  assert_output "pager_val:[]"
}

# Test: --no-X with short option alias for required argument option
@test "getoptlong: required arg - negated --no-file sets empty string" {
  run $BASH -c '
        . ../script/getoptlong.sh
        declare -A OPTS=([file|f:]=original.txt)
        getoptlong init OPTS
        getoptlong parse --no-file
        eval "$(getoptlong set)"
        echo "file_val:[$file]"
  '
  assert_success
  assert_output "file_val:[]"
}

# Test: --no-X does not consume next argument
@test "getoptlong: required arg - negated --no-pager does not consume next arg" {
  run $BASH -c '
        . ../script/getoptlong.sh
        declare -A OPTS=([pager|p:]=default)
        getoptlong init OPTS PERMUTE=
        set -- --no-pager arg1 arg2
        getoptlong parse "$@"
        eval "$(getoptlong set)"
        echo "pager:[$pager]"
        echo "args:$*"
  '
  assert_success
  assert_line --index 0 "pager:[]"
  assert_line --index 1 "args:arg1 arg2"
}

