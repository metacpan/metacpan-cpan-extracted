#!/usr/bin/env bats

# test_helper.bash

# Load bats-support.bash. It provides `load_bats_support` and other utilities.
# The path is relative to the location of this test_helper.bash file,
# assuming .bats files are in the same directory as test_helper.bash or a subdirectory.
# If .bats files are in 't/', and test_helper.bash is also in 't/',
# and submodules are t/bats-support, then this path is correct.
load 'bats-support/load.bash'

# Load bats-assert.bash. It provides `assert_output`, `assert_line`,
# `assert_success`, `assert_failure`, etc.
load 'bats-assert/load.bash'

BASH="bash -u"

# Any other global setup for tests can go here.
# For example, if you had a common cleanup function or global variables.
# export MY_GLOBAL_VAR="some_value"

# Note: If getoptlong.sh needs to be sourced for specific test files (like 00_getoptlong.bats),
# it's now recommended to do that directly in those files, e.g.:
# . ../script/getoptlong.sh
# This keeps test_helper.bash focused on loading common libraries.
