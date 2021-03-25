#!/bin/bash
#set -euo pipefail
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
cd "$DIR/../.."
if [[ -e "../_build_fastx_reader_exp" ]]; then
  mv ../_build_fastx_reader_exp experimental
fi
cd -
echo "[XT::RELEASE::AFTER] WD=$PWD; DIR=$DIR"
if [[ -e "META.old" ]]; then
  echo "[fixing_ci] Copying META from $DIR to $PWD"
  mv META.old META.yml
fi
