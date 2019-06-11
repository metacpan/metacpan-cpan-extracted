#!/bin/bash
set -euo pipefail
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
echo "DIR=$DIR"
cd "$DIR/../../"
rm -rfv FASTX-*
mv experimental ../_build_fastx_reader_exp
cd -
