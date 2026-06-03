#!/usr/bin/env bash

set -Eeuo pipefail
trap cleanup SIGINT SIGTERM ERR EXIT
source ${BASH_FUNCTION_DIR}/iterm_fns.sh
source ${BASH_FUNCTION_DIR}/colorscheme_fns.sh

cleanup() {
  trap - SIGINT SIGTERM ERR EXIT
  if is_iTerm; then
    iterm_profile_set $colors
  fi
  yath stop
}


if is_iTerm; then
  colors=$(iterm_get_profile_name)
  if is_Dark; then
    iterm_profile_set MERM-Selenized-HC-Dark
  else
    iterm_profile_set MERM-Selenized-HC-Light
  fi
fi



yath_args=''
yath_start_args=''
yath_dirs='t '

while [[ "$#" -gt 0 ]]; do
  if [[ "$1" == '--verbose' ]]; then
    yath_args+=' --verbose'
  elif [[ "$1" == '--single' ]]; then
    yath_start_args+=' --no-job-count --no-slots-per-job '
  elif [[ "$1" == '--author' ]]; then
    export AUTHOR_TESTING=1
    yath_dirs+='xt '
  fi
  shift
done

yath start $yath_start_args

find lib t xt examples | entr yath $yath_dirs run $yath_args

