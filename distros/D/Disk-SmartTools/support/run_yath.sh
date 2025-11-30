#!/usr/bin/env bash

set -Eeuo pipefail
trap cleanup SIGINT SIGTERM ERR EXIT

cleanup() {
  trap - SIGINT SIGTERM ERR EXIT
  yath stop
}

yath_args=''
yath_start_args=''

while [[ "$#" -gt 0 ]]; do
  if [[ "$1" == '--verbose' ]]; then
    yath_args+=' --verbose'
  elif [[ "$1" == '--single' ]]; then
    yath_start_args+=' --no-job-count --no-slots-per-job'
  fi
  shift
done

yath start $yath_start_args

find lib t xt | entr yath run $yath_args

