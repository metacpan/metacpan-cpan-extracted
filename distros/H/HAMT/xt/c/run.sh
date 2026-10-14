#!/bin/sh
# Build the core harness with ASan and UBSan and run it. TAP on stdout.
#
#   sh xt/c/run.sh [build-dir]
#
# Run from the dist root. CC and HAMT_HARNESS_CFLAGS may be set in the
# environment; the build directory defaults to a fresh temporary one.
set -e

CC=${CC:-cc}
OUT=${1:-}
if [ -z "$OUT" ]; then
    OUT=$(mktemp -d "${TMPDIR:-/tmp}/hamt-harness.XXXXXX")
    trap 'rm -rf "$OUT"' EXIT
fi
[ -d include/hamt ] || { echo "Bail out! run from the dist root"; exit 2; }

"$CC" -std=c99 -Wall -Wextra -g -O1 -fno-omit-frame-pointer \
    -fsanitize=address,undefined -fno-sanitize-recover=undefined \
    $HAMT_HARNESS_CFLAGS -Iinclude \
    -o "$OUT/harness" xt/c/harness.c

"$OUT/harness"
