#!/usr/bin/env bash
# Verify a packed locale-simple binary against `perl -Ilib bin/locale-simple`.
#   verify-binary.sh <binary>
# Run it where the binary was built (same perl, same installed modules): the packed
# module set is computed from this host's perl, and optional modules such as
# Class::XSAccessor load only where they are installed.
set -euo pipefail

[ -n "${1:-}" ] || { echo "usage: verify-binary.sh <binary>" >&2; exit 1; }
BIN=$(perl -MCwd=abs_path -e 'print abs_path(shift) // ""' "$1")
[ -n "$BIN" ] || { echo "FAIL: cannot resolve path: $1" >&2; exit 1; }
[ -x "$BIN" ] || { echo "FAIL: not an executable: $BIN" >&2; exit 1; }
root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
work=$(mktemp -d); cache=$(mktemp -d)
trap 'rm -rf "$work" "$cache"' EXIT
mkdir -p "$work/home" "$work/cwd"

fail() { echo "FAIL: $*" >&2; exit 1; }
tmo=${LOCALE_SIMPLE_VERIFY_TIMEOUT:-120}
# timeout(1) where it exists (GNU coreutils); a perl alarm wrapper where it does not (macOS).
if command -v timeout >/dev/null 2>&1; then TMO=(timeout "$tmo")
else TMO=(perl -e 'alarm shift; exec @ARGV' "$tmo"); fi

# The binary under a wiped environment and a fresh extraction cache.
bin() { env -i PATH=/usr/bin:/bin HOME="$work/home" PAR_GLOBAL_TEMP="$cache" "${TMO[@]}" "$BIN" "$@" </dev/null; }
# The reference: the same CLI from the checkout.
ref() { "${TMO[@]}" perl -I"$root/lib" "$root/bin/locale-simple" "$@" </dev/null; }

# same_as_perl CASE ARGS...: STDOUT and exit code of the binary match the checkout's perl run.
# The reference must have printed something (a case with empty output on both sides proves
# nothing); set EXPECT_EMPTY=1 for a case that prints nothing. STDERR is not compared;
# set STDERR_PATTERN to require that both runs report it on STDERR.
same_as_perl() {
  local name=$1; shift
  local rc_want=0 rc_got=0
  ref "$@" >"$work/want" 2>"$work/want.err" || rc_want=$?
  bin "$@" >"$work/got" 2>"$work/got.err" || rc_got=$?
  [ "$rc_want" = "$rc_got" ] || fail "$name: exit code differs (binary $rc_got, perl $rc_want)"
  if [ -z "${EXPECT_EMPTY:-}" ]; then
    [ -s "$work/want" ] || fail "$name: the perl reference printed nothing, the case proves nothing"
  fi
  cmp -s "$work/want" "$work/got" || fail "$name: STDOUT differs from perl -Ilib (binary: $(wc -c <"$work/got") bytes, perl: $(wc -c <"$work/want") bytes)"
  if [ -n "${STDERR_PATTERN:-}" ]; then
    grep -q -- "$STDERR_PATTERN" "$work/want.err" || fail "$name: perl run lacks '$STDERR_PATTERN' on STDERR"
    grep -q -- "$STDERR_PATTERN" "$work/got.err" || fail "$name: binary run lacks '$STDERR_PATTERN' on STDERR"
  fi
}

want_version=$(sed -n "s/^our \$VERSION = '\(.*\)';/\1/p" "$root/lib/Locale/Simple.pm")
[ -n "$want_version" ] || fail "cannot read \$VERSION from lib/Locale/Simple.pm"

# Fixtures are copied, so reference and binary see the same relative paths.
cp -r "$root/t/data" "$work/cwd/data"
cd "$work/cwd"

# Startup on a fresh cache (the extraction run), then a second start on the same cache.
out=$(bin --version) || fail "--version failed on a fresh cache"
[ "$out" = "locale-simple $want_version" ] || fail "--version prints '$out', want 'locale-simple $want_version'"
echo "startup (--version, fresh cache): OK"
out=$(bin --version) || fail "--version failed on the second start"
[ "$out" = "locale-simple $want_version" ] || fail "second start prints '$out'"
echo "second start (same cache): OK"

same_as_perl "--help" --help
same_as_perl "help" help
EXPECT_EMPTY=1 same_as_perl "no command (exit 2)"
EXPECT_EMPTY=1 same_as_perl "unknown command (exit 2)" nope
echo "help and usage: OK"

cd data/n-fixtures
same_as_perl "scrape n-fixtures" scrape
same_as_perl "scrape n-fixtures --output json" scrape --output json
cd ../..
echo "scrape: OK"

# Parse errors are reported on STDERR; Perl exits 0 and so must the binary.
cd data
STDERR_PATTERN='Expected ","' same_as_perl "scrape with parse errors" scrape --pl 1pl --only 1pl
rc=0; bin scrape --pl 1pl --only 1pl >/dev/null 2>&1 || rc=$?
[ "$rc" = 0 ] || fail "scrape with parse errors: binary exits $rc, want 0"
echo "scrape parse errors: OK"

same_as_perl "po2json --domain test" po2json --domain test locale/de_DE/LC_MESSAGES/test.po
same_as_perl "po2json edge.po (UTF-8)" po2json po2json/edge.po
same_as_perl "po2json --pretty" po2json --pretty po2json/edge.po
same_as_perl "po2json noplural.po" po2json po2json/noplural.po
# UTF-8: the JSON decodes to the strings of edge.po, not to double-encoded mojibake.
bin po2json po2json/edge.po | perl -MJSON::PP -e '
  local $/; my $j = JSON::PP->new->utf8->decode(<STDIN>);
  my $want = "Gr\x{f6}\x{df}e \x{2192}"; my $found = 0;
  my $walk; $walk = sub { my $v = shift;
    if (ref $v eq "HASH") { $walk->($_) for values %$v } elsif (ref $v eq "ARRAY") { $walk->($_) for @$v }
    elsif (defined $v && $v eq $want) { $found++ } };
  $walk->($j); exit($found ? 0 : 1)' \
  || fail "po2json edge.po: the JSON does not decode to the string 'Größe →'"
echo "po2json: OK"

# Error path: a missing file exits non-zero, the same code as Perl.
rc_want=0; rc_got=0
ref po2json nope.po >/dev/null 2>&1 || rc_want=$?
bin po2json nope.po >/dev/null 2>&1 || rc_got=$?
[ "$rc_want" -ne 0 ] || fail "po2json nope.po: perl exits 0, the reference is broken"
[ "$rc_want" = "$rc_got" ] || fail "po2json nope.po: exit code differs (binary $rc_got, perl $rc_want)"
echo "error path (po2json nope.po, exit $rc_got): OK"

echo "output equals perl -Ilib: OK"

# Packed module set. A pp binary keeps the build perl's compiled-in @INC, so a module the
# build missed would still load on this host. The full loaded set (scripts/loaded-modules.pl,
# the same list build-binary.sh packs: the dist, its dependencies and what those load in turn,
# core and XS modules included) must therefore be inside the archive itself.
# PAR puts every module, XS-backed ones such as List/Util.pm and Cwd.pm included, under the
# archive's lib/ (their .so files go to shlib/); arch/ is accepted as well should that change.
command -v unzip >/dev/null 2>&1 || fail "unzip is not installed (needed to inspect the PAR archive)"
rc=0; unzip -qq -o "$BIN" -d "$work/archive" >/dev/null 2>&1 || rc=$?   # 1 = bytes before the zip
[ "$rc" -le 1 ] && [ -d "$work/archive/lib" ] || fail "cannot unpack the PAR archive (unzip exit $rc)"
perl -I"$root/lib" "$root/scripts/loaded-modules.pl" >"$work/loaded" 2>"$work/loaded.err" \
  || fail "scripts/loaded-modules.pl failed: $(cat "$work/loaded.err")"
nloaded=$(wc -l <"$work/loaded" | tr -d ' ')
[ "$nloaded" -gt 25 ] || fail "loaded set suspiciously small ($nloaded modules)"
# EXTRA_PACKED_CHECK="Not::Packed" adds names to the list (used to prove the check can fail).
for m in $(cat "$work/loaded") ${EXTRA_PACKED_CHECK:-}; do
  f="$(echo "$m" | sed 's#::#/#g').pm"
  [ -f "$work/archive/lib/$f" ] || [ -f "$work/archive/arch/$f" ] || missing="${missing:-} $f"
done
[ -z "${missing:-}" ] || fail "modules missing inside the PAR archive:$missing (run verify where the binary was built)"
echo "packed module set: OK ($nloaded modules)"
# Every binary writes the same output formats: YAML and all YAML::* modules are left out of the
# build (-X in build-binary.sh), so a runner that happens to have them installed does not pack them.
yamlfiles="$(cd "$work/archive" && { find lib arch \( -name YAML.pm -o -path '*/YAML/*' \) 2>/dev/null || true; } | head -5)"
[ -z "$yamlfiles" ] || fail "YAML packed ($(echo $yamlfiles)); build-binary.sh must leave out YAML and YAML::*"
echo "no YAML packed: OK"
echo "verify: OK"
