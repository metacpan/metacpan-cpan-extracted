#!/bin/bash

set -euo pipefail
IFS=$'\n\t'

cd `mktemp -d`
git clone --depth 2 https://github.com/plicease/Dist-Zilla-Plugin-Author-Plicease.git .
dzil authordeps --missing | cpanm -n
dzil listdeps   --missing | cpanm -n
dzil install --install-command="cpanm -n ."

