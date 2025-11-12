#!/usr/bin/env bash

set -Eeuo pipefail
trap cleanup SIGINT SIGTERM ERR EXIT

cleanup() {
  trap - SIGINT SIGTERM ERR EXIT
  yath stop
}

yath start

if [[ $# -eq 1 ]] && [[ "$1" == '--verbose' ]]; then
  find lib t xt | entr yath run --verbose
else
  find lib t xt | entr yath run
fi

