#!/usr/bin/env bash

export TESTDIR='/hpcrunner-tests'

flunk() {
  echo "Command failed with exit code $status"
  echo "Output is $output"
  return 1
}

assert_success() {
  if [[ "$status" -ne 0 ]]; then
    flunk
  fi
  echo "Output is $output"
}

#sometimes we expect things to fail
assert_failure() {
  if [[ "$status" -ne 0 ]]; then
    return 0
  fi
  return 1
}

assert_exit_status() {
    assert_equal "$status" "$1"
}
