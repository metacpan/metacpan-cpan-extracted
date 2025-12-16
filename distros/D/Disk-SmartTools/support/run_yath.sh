#!/usr/bin/env bash

set -Eeuo pipefail
trap cleanup SIGINT SIGTERM ERR EXIT

cleanup() {
  trap - SIGINT SIGTERM ERR EXIT
  yath stop
}

yath_args=''
yath_start_args=''
yath_dirs='t '

while [[ "$#" -gt 0 ]]; do
  if [[ "$1" == '--verbose' ]]; then
    yath_args+=' --verbose'
  elif [[ "$1" == '--single' ]]; then
    yath_start_args+=' --no-job-count --no-slots-per-job '
  elif [[ "$1" == '--author' ]]; then
    yath_dirs+='xt '
  fi
  shift
done

yath start $yath_start_args

find lib t xt examples | entr yath $yath_dirs run $yath_args

