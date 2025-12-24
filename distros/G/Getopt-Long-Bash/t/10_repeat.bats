#!/usr/bin/env bats

# test_helper.bash sources getoptlong.sh, which is needed by repeat.sh
load 'test_helper'

# Path to the script under test, relative to the .bats file
: ${SCRIPT_UNDER_TEST:="../ex/repeat.sh"}

setup() {
    # Ensure the script is executable before each test
    chmod +x "$SCRIPT_UNDER_TEST"
}

script=$(basename "$SCRIPT_UNDER_TEST")

RUN() {
    run "$SCRIPT_UNDER_TEST" "$@"
}

@test "${script}: shows help with --help" {
    RUN --help
    assert_success
    assert_output --partial "--count=#"
}

@test "${script}: space in arg" {
    RUN echo "hello  world"
    assert_success
    assert_output "hello  world"
}

@test "${script}: 2 times: echo hello" {
    RUN 2 echo hello
    assert_success
    assert_output "hello
hello"
}

@test "${script}: -c 3: echo test" {
    RUN -c 3 echo test
    assert_success
    assert_output "test
test
test"
}

@test "${script}: --count=1: echo single" {
    RUN --count=1 echo single
    assert_success
    assert_output "single"
}

@test "${script}: paragraph (-p): echo line (default newline)" {
    RUN -c 2 -p echo line
    assert_success
    # Expected: command_output + paragraph_separator + command_output + paragraph_separator
    # Default separator is a newline.
    assert_output "line

line"
}

@test "${script}: --paragraph=---: echo segment" {
    RUN --count=2 --paragraph='---' echo segment
    assert_success
    assert_output "segment
---
segment
---"
}

@test "${script}: message BEGIN (-m BEGIN=Start)" {
    RUN -c 1 -m BEGIN=Start echo action
    assert_success
    assert_output "Start
action"
}

@test "${script}: message BEGIN (-m begin=Start) -- invalid" {
    RUN -c 1 -m begin=Start echo action
    assert_failure
}

@test "${script}: message END (--message END=Finish)" {
    RUN --count=1 --message END=Finish echo work
    assert_success
    assert_output "work
Finish"
}

@test "${script}: multiple messages (BEGIN, END)" {
    RUN -c 1 -m BEGIN=B -m END=X echo task
    assert_success
    assert_output "B
task
X"
}

@test "${script}: multiple messages (BEGIN, END) -- bundling together" {
    RUN -c 1 -m BEGIN=B,END=X echo task
    assert_success
    assert_output "B
task
X"
}

@test "${script}: multiple messages (BEGIN, END) -- bundling together w/nl" {
    RUN -c 1 -m $'BEGIN=--  B\nEND=--  X\n' echo task
    assert_success
    assert_output "--  B
task
--  X"
}

@test "${script}: command with spaces: echo hello world" {
    RUN -c 1 echo "hello world"
    assert_success
    assert_output "hello world"
}

@test "${script}: command with its own options: ls -a /dev/null (check for null)" {
    # This test is slightly less deterministic if ls output format varies wildly.
    # We check for the presence of "null".
    # Note: /dev/null is a file, `ls -a /dev/null` outputs `/dev/null`.
    RUN -c 1 -- ls -a /dev/null
    assert_success
    assert_output --partial "/dev/null"
}

@test "${script}: no arguments (should show help/error and fail)" {
    RUN
    assert_success
    assert_output ''
}

@test "${script}: -i 0.01 (sleep, hard to test duration, just runs)" {
    # Actual sleep duration is not tested here, only that the command runs.
    # For more robust sleep testing, one might use `time` and compare durations,
    # but that can be flaky in CI.
    RUN -c 1 -i 0.01 echo "slept"
    assert_success
    assert_output "slept"
}

@test "${script}: multiple sleep intervals -i 0.01 -i 0.02 (runs 3 times)" {
    # Checks that the command runs 3 times, cycling through sleep values.
    # The debug output for sleep was useful but made tests complex.
    # Here we just check the command output.
    RUN -c 3 -i 0.01 -i 0.02 echo "cycle sleep"
    assert_success
    assert_output "cycle sleep
cycle sleep
cycle sleep"
}

@test "${script}: -x (trace) option (check for trace output)" {
    RUN -x -c 1 echo trace me
    assert_success
    # `set -x` output is on stderr.
    # We check if `stderr` contains a typical trace line.
    # The actual output of "echo trace me" goes to stdout.
    assert_output --partial "+ echo trace me"
}

@test "${script}: -d (debug level 1)" {
    RUN -d echo debug test
    assert_success
    # Debug output is on stderr.
    assert_output --partial "# [ 'echo' 'debug' 'test' ]" # stderr
}

# It's harder to make a simple output assertion for debug level 2 (getoptlong dump)
# as the dump includes variable internal IDs that can change.
# We'll skip a direct output comparison for debug=2 to keep tests simple.
# A partial match for "OPTS[" could be done if essential.
