#!/usr/bin/env bash
# Smoke-test a packed locale-simple binary on a clean machine: no Perl modules from the
# build, no build toolchain. Run it from the checkout root (for the fixtures).
#   smoke-binary.sh <binary> [<tarball>]
# With a tarball (the .tar.gz users download), it is unpacked and checked as well: one
# directory named like the tarball, holding locale-simple (executable as extracted, identical
# to the bare binary), LICENSE and README. The checks below then run against the extracted binary.
set -euo pipefail

fail() { echo "FAIL: $*" >&2; exit 1; }
[ -n "${1:-}" ] || { echo "usage: smoke-binary.sh <binary> [<tarball>]" >&2; exit 1; }
BIN=$(cd "$(dirname "$1")" && pwd)/$(basename "$1")
chmod +x "$BIN"      # artifacts lose the mode
TARBALL=
if [ -n "${2:-}" ]; then TARBALL=$(cd "$(dirname "$2")" && pwd)/$(basename "$2"); fi

want=$(sed -n "s/^our \$VERSION = '\(.*\)';/\1/p" lib/Locale/Simple.pm)
[ -n "$want" ] || fail "cannot read \$VERSION from lib/Locale/Simple.pm"
work=$(mktemp -d); trap 'rm -rf "$work"' EXIT
mkdir -p "$work/home"

if [ -n "$TARBALL" ]; then
  [ -f "$TARBALL" ] || fail "no such tarball: $TARBALL"
  name=$(basename "$TARBALL" .tar.gz)
  mkdir "$work/tar"
  tar -xzf "$TARBALL" -C "$work/tar" || fail "cannot unpack $TARBALL"
  [ "$(ls -A "$work/tar")" = "$name" ] || fail "tarball must hold exactly the directory $name/, found: $(ls -A "$work/tar" | tr '\n' ' ')"
  for f in locale-simple LICENSE README; do
    [ -f "$work/tar/$name/$f" ] || fail "tarball lacks $name/$f"
  done
  [ -x "$work/tar/$name/locale-simple" ] || fail "$name/locale-simple is not executable as extracted from the tarball"
  cmp -s "$work/tar/$name/locale-simple" "$BIN" || fail "$name/locale-simple differs from the bare binary $(basename "$BIN")"
  BIN="$work/tar/$name/locale-simple"
  echo "smoke tarball: OK ($name)"
fi

# The binary under a wiped environment, as a user without Perl would start it.
bin() { env -i PATH=/usr/bin:/bin HOME="$work/home" "$BIN" "$@" </dev/null; }

out=$(bin --version) || fail "--version failed"
[ "$out" = "locale-simple $want" ] || fail "--version prints '$out', want 'locale-simple $want'"
echo "smoke --version: OK ($out)"

bin po2json --domain test t/data/locale/de_DE/LC_MESSAGES/test.po >"$work/got" \
  || fail "po2json --domain test failed"
cmp -s "$work/got" t/data/po2json/test.domain.json \
  || fail "po2json --domain test: output differs from t/data/po2json/test.domain.json"
echo "smoke po2json --domain test: OK (byte-identical)"

# scrape: the fixture directory read by t/73-scrape-smoke.t against the checked-in template.
( cd t/data/n-fixtures && bin scrape ) >"$work/scrape.pot" 2>/dev/null \
  || fail "scrape in t/data/n-fixtures failed"
cmp -s "$work/scrape.pot" t/data/scrape-smoke.pot \
  || fail "scrape in t/data/n-fixtures: output differs from t/data/scrape-smoke.pot"
echo "smoke scrape: OK (byte-identical)"

rc=0; bin po2json nope.po >/dev/null 2>&1 || rc=$?
[ "$rc" -ne 0 ] || fail "po2json nope.po exits 0, want non-zero"
echo "smoke po2json nope.po: OK (exit $rc)"
echo "smoke: OK"
