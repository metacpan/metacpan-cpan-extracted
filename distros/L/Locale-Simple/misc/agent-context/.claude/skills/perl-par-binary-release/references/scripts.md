# Script skeletons

Five files under `scripts/` and a keeper test under `t/` (end of this page). The bash
scripts start with `#!/usr/bin/env bash` and `set -euo pipefail`, and stay bash-3.2
compatible (macOS). Replace the `__NAME__` (binary
name, e.g. `locale-simple`), `__NAME_UC__` (env prefix, `LOCALE_SIMPLE`), `__Module__`
(the file holding `$VERSION` as a path below `lib/` without `.pm`, `Locale/Simple`),
`__Dist__` (top namespace as a package, `Locale::Simple`) and `__Dist-Name__` (the
distribution name, `Locale-Simple`) slots with the dist's own. Prose and YAML spell the
same slots `<name>`, `<NAME>`, `<Module>` and `<Dist-Name>`: `<name>` = `__NAME__`,
`<NAME>_BIN_OUT` = `__NAME_UC___BIN_OUT`, `<Module>` = `__Module__`. `__Optional__` is
the optional module left out of every build (`YAML`) and `__Optional_Path__` its directory
below `@INC` (`YAML`). A dist with no such module drops all of these together: the
`nofam` block and the `"${nofam[@]}"` line of the `pp` call in build-binary.sh, the
`next if $m eq '__Optional__'` line in loaded-modules.pl, and the `famfiles` check with
its `echo` in verify-binary.sh. Comment every `-M`, `-a` and `-X` line with the failure
it prevents.

## build-binary.sh

```bash
#!/usr/bin/env bash
# Pack bin/__NAME__ into one standalone executable with PAR::Packer.
# Run from the checkout root. Output: $__NAME_UC___BIN_OUT (default ./__NAME__).
set -euo pipefail

OUT="${__NAME_UC___BIN_OUT:-./__NAME__}"
[ -f bin/__NAME__ ] || { echo "ERROR: run from the checkout root" >&2; exit 1; }
command -v pp >/dev/null 2>&1 || { echo "ERROR: pp (PAR::Packer) is not installed" >&2; exit 1; }

# Every module needed at run time must be installed, or the loaded set below is short.
perl -Ilib -MJSON::PP -MTry::Tiny -e1 \
  || { echo "ERROR: runtime dependencies missing (cpanm --installdeps .)" >&2; exit 1; }

# Preconditions pp itself would not notice (example): an Alien must be a share build,
# or dist_dir points at host paths the target lacks.
#   [ "$(perl -MAlien::Foo -e 'print Alien::Foo->install_type')" = share ] || { ...; exit 1; }

# The loaded set: scripts/loaded-modules.pl runs the real command paths and prints every
# module that came from its own file. verify-binary.sh requires the same list in the archive.
loaded=(); while IFS= read -r m; do loaded+=("$m"); done < <(perl -Ilib scripts/loaded-modules.pl)
[ "${#loaded[@]}" -gt 25 ] || { echo "ERROR: loaded set suspiciously small (${#loaded[@]})" >&2; exit 1; }
mods=(); for m in "${loaded[@]}"; do mods+=(-M "$m"); done

# Optional modules: -M on an absent module aborts pp.
optional=()
for m in Cpanel::JSON::XS JSON::XS; do
  if perl -Ilib -M"$m" -e1 >/dev/null 2>&1; then optional+=(-M "$m"); fi
done

# PAR_VERBATIM=1: pp's POD-stripping filter corrupts files with POD between code.
# -I lib: the checkout's lib/ wins over any installed copy.
# -M '__Dist__::**': members of the namespace that load on some path only.
# -a: share tree where File::ShareDir looks in an installed dist; drop this line when
#     the dist has no share/ directory. Add one per dependency that reads a share tree:
#     -a "$(perl -MFile::ShareDir=dist_dir -e 'print dist_dir("Dep-Dist")');lib/auto/share/dist/Dep-Dist"
# -X: an optional module that links a lib the target may lack; the code falls back.
# -X family: `pp -X Name` drops exactly Name.pm (no wildcard) and the scanner still follows
#     `require Name` into the module's own dependencies, so a module installed on one runner
#     only (here __Optional__, say an output format) takes one -X per family member found in
#     @INC on this host. Every binary then has the same features on every platform.
nofam=(-X __Optional__)
while IFS= read -r m; do nofam+=(-X "$m"); done < <(perl -MFile::Find -e '
  my %m;
  for my $dir (grep { !ref } @INC) {
    next unless -d "$dir/__Optional_Path__";
    find({ no_chdir => 1, wanted => sub {
      return unless /\.pm\z/;
      (my $n = substr $_, length($dir) + 1) =~ s{/}{::}g;
      $n =~ s/\.pm\z//;
      $m{$n} = 1;
    } }, "$dir/__Optional_Path__");
  }
  print "$_\n" for sort keys %m;')

PAR_VERBATIM=1 pp -o "$OUT" \
  -I lib \
  "${mods[@]}" \
  ${optional[@]+"${optional[@]}"} \
  -M '__Dist__::**' \
  "${nofam[@]}" \
  -a "share;lib/auto/share/dist/__Dist-Name__" \
  bin/__NAME__

chmod +x "$OUT"
echo "Built $OUT ($(du -h "$OUT" | cut -f1), ${#loaded[@]} modules)"
```

A shared namespace takes explicit names instead of the glob:

```bash
pm_to_mod() { sed -e 's#\.pm$##' -e 's#/#::#g'; }
mods=()
while IFS= read -r m; do mods+=(-M "$m"); done \
  < <(cd lib && find "$(echo '__Dist__' | sed 's#::#/#g')" -name '*.pm' | sort | pm_to_mod)
```

Installed dependency modules can come from the dist's `.packlist`
(`$INC/auto/<Dist>/.packlist`), filtered with `grep -v` for the siblings to leave out.

## loaded-modules.pl

Skip the optional module in the printed set (see the last loop, `next if $m eq '__Optional__'`),
so verify does not require a file the build leaves out. A module the CLI really needs stays
in the set and fails the build there.

Run as `perl -Ilib scripts/loaded-modules.pl` from the checkout root; the list goes to
STDOUT, problems to STDERR.

```perl
#!/usr/bin/env perl
# Print the modules the CLI loads, one per line (Foo::Bar), by running the real commands.
# build-binary.sh turns the list into pp -M options; verify-binary.sh requires every entry
# inside the packed archive. One source, so build and verify cannot drift.
use strict; use warnings;
use File::Find ();
use File::Temp ();
my %mods;
( my $path = '__Dist__' ) =~ s{::}{/}g;      # Locale::Simple -> Locale/Simple
# The dist's own namespace, from every @INC dir that holds it.
for my $dir ( grep { !ref } @INC ) {
  next unless -d "$dir/$path";
  File::Find::find( { no_chdir => 1, wanted => sub {
    return unless /\.pm\z/;
    ( my $m = substr $_, length($dir) + 1 ) =~ s{/}{::}g;
    $m =~ s/\.pm\z//;
    $mods{$m} = 1;
  } }, "$dir/$path" );
}
# Backends chosen at run time (the scanner cannot see them); list each one.
$mods{$_} = 1 for qw( Some::Backend Some::Backend::Pure );
for my $m ( sort keys %mods ) {
  eval "require $m; 1" or warn "loaded-modules: not loadable: $m (" . ( split /\n/, $@ )[0] . ")\n";
}
# Run every command path for real, so the lazy loads happen: help, version, each
# subcommand on small fixtures, the usage and file-not-found error paths.
require __Dist__::CLI;
my $dir = File::Temp::tempdir( CLEANUP => 1 );
{
  chdir $dir or die $!;
  open my $oldout, '>&', \*STDOUT or die;
  open STDOUT, '>', '/dev/null' or die;
  open my $olderr, '>&', \*STDERR or die;
  open STDERR, '>', '/dev/null' or die;
  __Dist__::CLI::run(@$_) for ( [], ['help'], ['--help'], ['--version'], ['nope'] );
  # __Dist__::CLI::run( 'subcommand', '--option', ... );   # one call per subcommand
  open STDOUT, '>&', $oldout or die;
  open STDERR, '>&', $olderr or die;
  chdir '/';
}
for my $file ( sort keys %INC ) {
  next unless $file =~ m{\A[\w/]+\.pm\z};
  next unless defined $INC{$file} && !ref $INC{$file} && $INC{$file} =~ m{/\Q$file\E\z};
  ( my $m = $file ) =~ s{/}{::}g;
  $m =~ s/\.pm\z//;
  next if $m eq '__Optional__';    # left out of every build (-X in build-binary.sh)
  print "$m\n";
}
```

A CLI whose entry point calls `exit` needs the run wrapped (`eval`, or a `local *CORE::GLOBAL::exit`).

## verify-binary.sh

```bash
#!/usr/bin/env bash
# Verify a packed binary against `perl -Ilib bin/__NAME__`. Run it where the binary was built.
set -euo pipefail

[ -n "${1:-}" ] || { echo "usage: verify-binary.sh <binary>" >&2; exit 1; }
BIN=$(perl -MCwd=abs_path -e 'print abs_path(shift) // ""' "$1")
[ -x "$BIN" ] || { echo "FAIL: not an executable: $BIN" >&2; exit 1; }
root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
work=$(mktemp -d); cache=$(mktemp -d)
trap 'rm -rf "$work" "$cache"' EXIT
mkdir -p "$work/home" "$work/cwd"

fail() { echo "FAIL: $*" >&2; exit 1; }
tmo=${__NAME_UC___VERIFY_TIMEOUT:-120}
# timeout(1) where it exists (GNU coreutils); a perl alarm wrapper where it does not (macOS).
if command -v timeout >/dev/null 2>&1; then TMO=(timeout "$tmo")
else TMO=(perl -e 'alarm shift; exec @ARGV' "$tmo"); fi

# The binary under a wiped environment and a fresh extraction cache.
bin() { env -i PATH=/usr/bin:/bin HOME="$work/home" PAR_GLOBAL_TEMP="$cache" "${TMO[@]}" "$BIN" "$@" </dev/null; }
# The reference: the same CLI from the checkout.
ref() { "${TMO[@]}" perl -I"$root/lib" "$root/bin/__NAME__" "$@" </dev/null; }

# same_as_perl CASE ARGS...: STDOUT and exit code match the checkout's perl run. The
# reference must have printed something (EXPECT_EMPTY=1 for a case that prints nothing).
same_as_perl() {
  local name=$1; shift
  local rc_want=0 rc_got=0
  ref "$@" >"$work/want" 2>/dev/null || rc_want=$?
  bin "$@" >"$work/got" 2>/dev/null || rc_got=$?
  [ "$rc_want" = "$rc_got" ] || fail "$name: exit code differs (binary $rc_got, perl $rc_want)"
  if [ -z "${EXPECT_EMPTY:-}" ]; then
    [ -s "$work/want" ] || fail "$name: the perl reference printed nothing, the case proves nothing"
  fi
  cmp -s "$work/want" "$work/got" || fail "$name: STDOUT differs from perl -Ilib"
}

want_version=$(sed -n "s/^our \$VERSION = '\(.*\)';/\1/p" "$root/lib/__Module__.pm")
[ -n "$want_version" ] || fail "cannot read \$VERSION from lib/__Module__.pm"

cp -r "$root/t/data" "$work/cwd/data"      # fixtures are copied: same relative paths for both
cd "$work/cwd"

out=$(bin --version) || fail "--version failed on a fresh cache"
[ "$out" = "__NAME__ $want_version" ] || fail "--version prints '$out'"
echo "startup (--version, fresh cache): OK"
out=$(bin --version) || fail "--version failed on the second start"
[ "$out" = "__NAME__ $want_version" ] || fail "second start prints '$out'"
echo "second start (same cache): OK"

same_as_perl "--help" --help
EXPECT_EMPTY=1 same_as_perl "unknown command" nope
# same_as_perl "subcommand" subcommand --option data/input     # success path per subcommand
# same_as_perl "missing file" subcommand nope                  # error paths too
echo "output equals perl -Ilib: OK"

# Shipped files, byte for byte (what the binary serves or installs against share/).
# for f in $(cd "$root/share" && find . -type f); do cmp -s "$root/share/$f" <(bin ...) || fail "share/$f"; done

# Packed module set: the same list build-binary.sh packs must sit inside the archive. A pp
# binary keeps the build perl's compiled-in @INC, so a missing module would still load here.
command -v unzip >/dev/null 2>&1 || fail "unzip is not installed"
rc=0; unzip -qq -o "$BIN" -d "$work/archive" >/dev/null 2>&1 || rc=$?   # 1 = bytes before the zip
[ "$rc" -le 1 ] && [ -d "$work/archive/lib" ] || fail "cannot unpack the PAR archive (unzip exit $rc)"
perl -I"$root/lib" "$root/scripts/loaded-modules.pl" >"$work/loaded" 2>"$work/loaded.err" \
  || fail "scripts/loaded-modules.pl failed: $(cat "$work/loaded.err")"
nloaded=$(wc -l <"$work/loaded" | tr -d ' ')
[ "$nloaded" -gt 25 ] || fail "loaded set suspiciously small ($nloaded modules)"
# EXTRA_PACKED_CHECK="Not::Packed" adds names to the list (proves the check can fail).
missing=
for m in $(cat "$work/loaded") ${EXTRA_PACKED_CHECK:-}; do
  f="$(echo "$m" | sed 's#::#/#g').pm"
  [ -f "$work/archive/lib/$f" ] || [ -f "$work/archive/arch/$f" ] || missing="$missing $f"
done
[ -z "$missing" ] || fail "modules missing inside the PAR archive:$missing"
echo "packed module set: OK ($nloaded modules)"
# Left-out family: no file of it inside the archive, so every platform has the same features.
famfiles="$(cd "$work/archive" && { find lib arch \( -path '*/__Optional_Path__.pm' -o -path '*/__Optional_Path__/*' \) 2>/dev/null || true; } | head -5)"
[ -z "$famfiles" ] || fail "__Optional__ packed ($(echo $famfiles)); build-binary.sh must leave out the family"
echo "no __Optional__ packed: OK"
echo "verify: OK"
```

Where the CLI talks HTTP, serve a fake upstream from core-only Perl (`IO::Socket::INET` on
`127.0.0.1`, port 0, one forked process per connection) and point the binary at it; where
it touches a repository or database, work in a `mktemp -d` copy.

## check-binary-libs.sh

```bash
#!/usr/bin/env bash
# Check that the packed binary needs no shared library beyond the documented set.
#   check-binary-libs.sh <binary>   check
#   check-binary-libs.sh --list     print the documented runtime libs (one line)
set -euo pipefail

# libcrypt: the pp loader executable links libperl, which links libcrypt.so.1. The loader runs
# before PAR extracts anything, so a bundled copy (pp -l) cannot help: the target must have it.
# The README names the same set.
case "$(uname -s)" in
  Darwin)
    RUNTIME_LIBS=()
    BASE_LIBS=(libSystem.B 'libc\+\+.1' 'libc\+\+abi' libobjc.A libiconv.2 libresolv.9
               libz.1 libcharset.1 libncurses.5.4 libm libpthread libdl)
    NEEDS_TOOL=otool
    SO_PATTERN=(-name '*.so' -o -name '*.bundle' -o -name '*.dylib' -o -name '*.so.*') ;;
  *)
    RUNTIME_LIBS=(libcrypt)
    BASE_LIBS=(libc libm libpthread libdl librt libgcc_s 'ld-linux-.*' linux-vdso libperl)
    NEEDS_TOOL=ldd
    # The glibc floor: the highest GLIBC_x.y any packed object requires. The build image
    # sets it (bullseye: 2.31); the README names the same ceiling.
    GLIBC_MAX=2.31
    SO_PATTERN=(-name '*.so' -o -name '*.so.*') ;;
esac

if [ "${1:-}" = "--list" ]; then echo "${RUNTIME_LIBS[*]:-}"; exit 0; fi

command -v "$NEEDS_TOOL" >/dev/null 2>&1 || { echo "FAIL: $NEEDS_TOOL is not installed" >&2; exit 1; }
command -v unzip >/dev/null 2>&1 || { echo "FAIL: unzip is not installed" >&2; exit 1; }
BIN=$(perl -MCwd=abs_path -e 'print abs_path(shift) // ""' "${1:?usage: check-binary-libs.sh <binary> | --list}")
[ -f "$BIN" ] || { echo "FAIL: no such file: $BIN" >&2; exit 1; }
allowed=$(IFS='|'; echo "${RUNTIME_LIBS[*]:-}|${BASE_LIBS[*]}")
work=$(mktemp -d); trap 'rm -rf "$work"' EXIT

rc=0
unzip -qq -o "$BIN" -d "$work/par" || rc=$?       # exit 1 = warning (bytes before the zip)
[ "$rc" -le 1 ] || { echo "FAIL: cannot unpack the PAR archive (unzip exit $rc)" >&2; exit 1; }

objects=("$BIN")
while IFS= read -r f; do objects+=("$f"); done \
  < <(find "$work/par" -type f \( "${SO_PATTERN[@]}" \) -print | sort)
# The loader executable plus at least one XS shared object must be there.
[ "${#objects[@]}" -ge 2 ] || { echo "FAIL: no shared objects inside $BIN" >&2; exit 1; }

: > "$work/needs"
# needed_libs OBJECT: prints one library name per line (version suffixes stripped).
needed_libs() {
  if [ "$NEEDS_TOOL" = ldd ]; then
    ldd "$1" >"$work/tool.out" 2>"$work/tool.err" \
      || { grep -q 'not a dynamic executable' "$work/tool.err" "$work/tool.out" && return 0; \
           echo "FAIL: ldd failed on ${1#"$work/par/"}: $(cat "$work/tool.err")" >&2; exit 1; }
    awk '$1 ~ /\.so/ { lib = $1; sub(/.*\//, "", lib); sub(/\.so.*/, "", lib); print lib }' "$work/tool.out"
  else
    otool -L "$1" >"$work/tool.out" 2>"$work/tool.err" \
      || { echo "FAIL: otool failed on ${1#"$work/par/"}: $(cat "$work/tool.err")" >&2; exit 1; }
    # Line 1 is the file name; a dylib lists its own install name first, which is not a need.
    is_dylib=; [[ "$1" == *.dylib ]] && is_dylib=1
    awk -v dylib="$is_dylib" \
      'NR > 1 && /^[ \t]/ { if (dylib && !skipped) { skipped = 1; next }
         lib = $1; sub(/.*\//, "", lib); sub(/\.dylib$/, "", lib); print lib }' "$work/tool.out"
  fi
}
for obj in "${objects[@]}"; do
  needed_libs "$obj" | sort -u | awk -v obj="${obj#"$work/par/"}" '{ print $0 "\t" obj }' >> "$work/needs"
done

[ -s "$work/needs" ] || { echo "FAIL: found no shared libs; a Perl binary always needs libc" >&2; exit 1; }

echo "Shared libs the binary needs on the target (${#objects[@]} objects checked):"
cut -f1 "$work/needs" | sort -u | sed 's/^/  /'

undocumented=$(cut -f1 "$work/needs" | sort -u | grep -vxE "$allowed" || true)
if [ -n "$undocumented" ]; then
  for lib in $undocumented; do
    printf '::error::undocumented runtime lib %s, needed by: %s\n' "$lib" \
      "$(awk -F'\t' -v l="$lib" '$1 == l {print $2}' "$work/needs" | sort -u | paste -sd' ')" >&2
  done
  echo "FAIL: libs outside the documented runtime set (${RUNTIME_LIBS[*]:-none})" >&2
  exit 1
fi
echo "runtime-libs check: only the documented libs are needed"

# glibc floor (Linux): every object's undefined GLIBC_x.y symbol versions, highest one wins.
if [ "$NEEDS_TOOL" = ldd ]; then
  command -v objdump >/dev/null 2>&1 || { echo "FAIL: objdump is not installed (binutils)" >&2; exit 1; }
  : > "$work/glibc"
  for obj in "${objects[@]}"; do
    objdump -T "$obj" 2>/dev/null | awk '/\*UND\*/' | grep -o 'GLIBC_[0-9][0-9.]*' \
      | sed 's/^GLIBC_//' | sort -u | sed "s|\$|\t${obj#"$work/par/"}|" >> "$work/glibc" || true
  done
  floor=$(cut -f1 "$work/glibc" | sort -uV | tail -n 1)
  [ -n "$floor" ] || { echo "FAIL: no GLIBC_ symbol versions found; a Perl binary always has them" >&2; exit 1; }
  echo "glibc floor: $floor (documented ceiling: $GLIBC_MAX)"
  if [ "$(printf '%s\n%s\n' "$floor" "$GLIBC_MAX" | sort -V | tail -n 1)" != "$GLIBC_MAX" ]; then
    printf '::error::glibc %s is above the documented %s, needed by: %s\n' "$floor" "$GLIBC_MAX" \
      "$(awk -F'\t' -v f="$floor" '$1 == f {print $2}' "$work/glibc" | sort -u | paste -sd' ')" >&2
    echo "FAIL: the binary needs glibc $floor, above the documented $GLIBC_MAX" >&2
    exit 1
  fi
  echo "glibc check: floor $floor is within $GLIBC_MAX"
fi
```

## smoke-binary.sh

Run from the checkout root (for the fixtures), on a machine without the build's Perl.

```bash
#!/usr/bin/env bash
# Smoke-test a packed binary on a clean machine: no Perl modules from the build, no toolchain.
#   smoke-binary.sh <binary> [<tarball>]
# With a tarball (the .tar.gz users download) it is unpacked and checked as well: one
# directory named like the tarball, holding __NAME__ (executable as extracted, identical to
# the bare binary), LICENSE and README. The checks then run against the extracted binary.
set -euo pipefail

fail() { echo "FAIL: $*" >&2; exit 1; }
[ -n "${1:-}" ] || { echo "usage: smoke-binary.sh <binary> [<tarball>]" >&2; exit 1; }
BIN=$(cd "$(dirname "$1")" && pwd)/$(basename "$1")
chmod +x "$BIN"      # artifacts lose the mode
TARBALL=
if [ -n "${2:-}" ]; then TARBALL=$(cd "$(dirname "$2")" && pwd)/$(basename "$2"); fi

want=$(sed -n "s/^our \$VERSION = '\(.*\)';/\1/p" lib/__Module__.pm)
[ -n "$want" ] || fail "cannot read \$VERSION from lib/__Module__.pm"
work=$(mktemp -d); trap 'rm -rf "$work"' EXIT
mkdir -p "$work/home"

if [ -n "$TARBALL" ]; then
  [ -f "$TARBALL" ] || fail "no such tarball: $TARBALL"
  name=$(basename "$TARBALL" .tar.gz)
  mkdir "$work/tar"
  tar -xzf "$TARBALL" -C "$work/tar" || fail "cannot unpack $TARBALL"
  [ "$(ls -A "$work/tar")" = "$name" ] || fail "tarball must hold exactly the directory $name/"
  for f in __NAME__ LICENSE README; do
    [ -f "$work/tar/$name/$f" ] || fail "tarball lacks $name/$f"
  done
  [ -x "$work/tar/$name/__NAME__" ] || fail "$name/__NAME__ is not executable as extracted"
  cmp -s "$work/tar/$name/__NAME__" "$BIN" || fail "$name/__NAME__ differs from the bare binary"
  BIN="$work/tar/$name/__NAME__"
  echo "smoke tarball: OK ($name)"
fi

# The binary under a wiped environment, as a user without Perl would start it.
bin() { env -i PATH=/usr/bin:/bin HOME="$work/home" "$BIN" "$@" </dev/null; }

out=$(bin --version) || fail "--version failed"
[ "$out" = "__NAME__ $want" ] || fail "--version prints '$out', want '__NAME__ $want'"
echo "smoke --version: OK ($out)"

# Every subcommand on a fixture, compared byte for byte with a checked-in expectation.
# Repeat this block per subcommand; the t/ test below keeps each expectation true.
# `other` reads the current directory, so it runs inside the fixture directory; a
# subcommand that takes a file argument runs as `bin other t/data/input`.
( cd t/data/fixtures && bin other ) >"$work/other.out" 2>/dev/null || fail "other failed"
cmp -s "$work/other.out" t/data/other.expected \
  || fail "other: output differs from t/data/other.expected"
echo "smoke other: OK (byte-identical)"

rc=0; bin other nope >/dev/null 2>&1 || rc=$?
[ "$rc" -ne 0 ] || fail "other nope exits 0, want non-zero"
echo "smoke error path: OK (exit $rc)"
echo "smoke: OK"
```

### The keeper test

A `t/` test runs the same subcommand through the Perl code and compares with the same
expectation file, so the file equals what the Perl code writes and smoke never rots.

```perl
use strict; use warnings;
use Test::More;
use Test::InDistDir;
use Capture::Tiny 'capture';
use File::pushd;
use Path::Tiny;
use __Dist__::CLI;

# scripts/smoke-binary.sh runs this subcommand with the packed binary and compares the output
# byte for byte with t/data/other.expected; this test keeps that file true.
my $expected = path('t/data/other.expected')->absolute->slurp_raw;
my ( $out, $rc );
{
    my $g = pushd('t/data/fixtures');
    ( $out, undef, $rc ) = capture { __Dist__::CLI::run('other') };
}
is $rc, 0, 'exits 0';
ok length $expected > 500, 'the expectation is not empty';
is $out, $expected, 'expectation equals the output'
  or diag 'regenerate: (cd t/data/fixtures && perl -I../../../lib ../../../bin/__NAME__ other 2>/dev/null > ../other.expected)';
done_testing;
```
