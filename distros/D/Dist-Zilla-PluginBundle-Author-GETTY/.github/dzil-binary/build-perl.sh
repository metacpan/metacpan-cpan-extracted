#!/usr/bin/env bash
# The packing perl of one build leg: perl 5.40 built into PREFIX, cpanm in its bin.
#   build-perl.sh PREFIX
# A PREFIX that already holds this perl (restored from the cache) is only checked,
# and on macOS re-linked to its own libperl.dylib. Windows packs with Strawberry
# Perl instead and never runs this.
#
# Linux: no crypt(3) (-Ud_crypt -Ud_crypt_r -Ui_crypt) and a short libs list, so
# libperl needs neither libcrypt.so.1 nor libnsl/libgdbm/libdb, which a target
# may not have. -Duseshrplib: pp packs libperl as a shared library.
# macOS: MACOSX_DEPLOYMENT_TARGET comes from the workflow (set for the whole leg).
set -euo pipefail

PERL_VERSION=5.40.5
PERL_SHA256=09d926ae2d1b277c3bce62054c41da47c981380d719c41cf980b67945cc581ed
CPANM_VERSION=1.7049
CPANM_SHA256=b9ffb88e62a06aa91bd7d5a28ef6bdbb942608aea90e3969aa29b33640035214

PREFIX=${1:?usage: build-perl.sh PREFIX}
case $PREFIX in /*) ;; *) echo "ERROR: PREFIX must be absolute: $PREFIX" >&2; exit 1 ;; esac

# Nothing of a local::lib may divert the build or the cpanm install.
unset PERL5LIB PERL_MM_OPT PERL_MB_OPT PERL_LOCAL_LIB_ROOT

sha256_of() {
  if command -v sha256sum >/dev/null 2>&1; then sha256sum "$1"; else shasum -a 256 "$1"; fi | awk '{ print $1 }'
}

fetch() {
  local url=$1 out=$2 want=$3 got
  curl -sSfL -o "$out" "$url"
  got=$(sha256_of "$out")
  [ "$got" = "$want" ] || { echo "ERROR: $url: sha256 $got, want $want" >&2; exit 1; }
}

# The perl binaries name libperl.dylib by its build-time path; point them at the
# copy under PREFIX and re-sign them ad hoc.
darwin_fixup() {
  local lib f old
  lib=$(find "$PREFIX/lib" -path '*/CORE/libperl.dylib' | head -n 1)
  [ -n "$lib" ] || { echo "ERROR: no libperl.dylib under $PREFIX/lib" >&2; exit 1; }
  for f in "$PREFIX/bin/perl" "$PREFIX"/bin/perl5.*; do
    [ -f "$f" ] || continue
    old=$(otool -L "$f" | awk '/libperl\.dylib/ { print $1; exit }')
    if [ -z "$old" ] || [ "$old" = "$lib" ]; then continue; fi
    echo "relink $f: $old -> $lib"
    install_name_tool -change "$old" "$lib" "$f"
    codesign --force -s - "$f"
  done
}

check() {
  local v
  v=$("$PREFIX/bin/perl" -e 'print substr($^V, 1)')
  [ "$v" = "$PERL_VERSION" ] || { echo "ERROR: $PREFIX/bin/perl is $v, want $PERL_VERSION" >&2; exit 1; }
  [ -x "$PREFIX/bin/cpanm" ] || { echo "ERROR: no cpanm in $PREFIX/bin" >&2; exit 1; }
  "$PREFIX/bin/perl" -V:libs -V:d_crypt -V:useshrplib -V:ccflags
}

if [ -x "$PREFIX/bin/perl" ]; then
  echo "perl in $PREFIX (cache)"
  if [ "$(uname -s)" = Darwin ]; then darwin_fixup; fi
  check
  exit 0
fi

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

fetch "https://www.cpan.org/src/5.0/perl-$PERL_VERSION.tar.gz" "$work/perl.tar.gz" "$PERL_SHA256"
tar xzf "$work/perl.tar.gz" -C "$work" --no-same-owner

extra=()
case "$(uname -s)" in
  Linux)  extra=( -Ud_crypt -Ud_crypt_r -Ui_crypt '-Dlibs=-lpthread -ldl -lm -lutil -lc' ) ;;
  Darwin) echo "MACOSX_DEPLOYMENT_TARGET=${MACOSX_DEPLOYMENT_TARGET:-<unset>}" ;;
esac
jobs=$(nproc 2>/dev/null || sysctl -n hw.ncpu)

(
  cd "$work/perl-$PERL_VERSION"
  ./Configure -des -Dprefix="$PREFIX" -Duseshrplib -Dman1dir=none -Dman3dir=none \
    ${extra[@]+"${extra[@]}"} >"$work/configure.log" 2>&1 \
    || { tail -n 60 "$work/configure.log" >&2; exit 1; }
  make -j"$jobs" >"$work/make.log" 2>&1 || { tail -n 80 "$work/make.log" >&2; exit 1; }
  make install >"$work/install.log" 2>&1 || { tail -n 40 "$work/install.log" >&2; exit 1; }
)
if [ "$(uname -s)" = Darwin ]; then darwin_fixup; fi

# cpanm, installed by this perl into its own bin (no network at install time).
fetch "https://cpan.metacpan.org/authors/id/M/MI/MIYAGAWA/App-cpanminus-$CPANM_VERSION.tar.gz" \
  "$work/cpanm.tar.gz" "$CPANM_SHA256"
tar xzf "$work/cpanm.tar.gz" -C "$work" --no-same-owner
(
  cd "$work/App-cpanminus-$CPANM_VERSION"
  { "$PREFIX/bin/perl" Makefile.PL && make install; } >"$work/cpanm.log" 2>&1 \
    || { tail -n 40 "$work/cpanm.log" >&2; exit 1; }
)

check
