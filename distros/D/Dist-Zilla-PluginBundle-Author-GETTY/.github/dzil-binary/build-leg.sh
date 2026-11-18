#!/usr/bin/env bash
# One build leg of the binary release workflow, phase by phase, so the workflow
# can restore and save its caches between the phases:
#   build-leg.sh init     unpack tarball/*.tar.gz into dist/   -> perl_key (not on Windows)
#   build-leg.sh keys     after the packing perl               -> lib_key
#   build-leg.sh prepare  the dist's prepare, with the local lib active
#   build-leg.sh deps     cpanm --installdeps . and PAR::Packer into the local lib
#   build-leg.sh pack     per binary: pp (Windows: again with the packing perl's
#                         DLLs it links, win-dlls.pl), lib-gate.pl, require-gate.pl
#                         -> out/, artifact
#   build-leg.sh verify   per binary: the dist's verify
# Run from the job's workspace. Environment: PLATFORM, VERSION (the version slot
# of the asset names), PREPARE_KEY, LEG_IMAGE (part of perl_key),
# MACOSX_DEPLOYMENT_TARGET (macOS), DZIL_BINARY_PERL_BIN (Windows: Strawberry's
# perl bin directory).
# ~/dzil-binary holds what the workflow caches: perl/ (the packing perl; Windows
# packs with Strawberry), local/ (the deps local lib), prepare/ (prepare's cache dir).
# A hook from x_binaries runs from the dist root as  sh -c '<cmd> "$@"' sh <arg>.
# verify's hook runs with the packing perl first on PATH, without PERL5LIB and
# the other local::lib variables, and with DZIL_BINARY_PERL5LIB set to the
# local lib (local/lib/perl5), the PERL5LIB under which the packing perl loads
# the dist's dependencies.
set -euo pipefail

die() { echo "::error::$*"; exit 1; }

phase=${1:-}
: "${PLATFORM:?PLATFORM is not set}"
case $PLATFORM in
  linux-x86_64|linux-arm64|macos-arm64|macos-x86_64|windows-x86_64) ;;
  *) die "unknown platform '$PLATFORM'" ;;
esac
os=${PLATFORM%%-*}
exe=''
[ "$os" != windows ] || exe=.exe

# Windows: Strawberry perl takes C:/... paths; bash's PATH takes /c/... entries.
native() { if [ "$os" = windows ]; then cygpath -m "$1"; else printf '%s\n' "$1"; fi; }
posix()  { if [ "$os" = windows ]; then cygpath -u "$1"; else printf '%s\n' "$1"; fi; }

HERE=$(native "$(cd "$(dirname "$0")" && pwd)")
TOP=$(native "$(pwd)")
DIST=$TOP/dist
OUT=$TOP/out
ROOT=$(native "$HOME/dzil-binary")
LOCAL=$ROOT/local
PREPARE_DIR=$ROOT/prepare

emit() {
  printf '%s=%s\n' "$1" "$2"
  if [ -n "${GITHUB_OUTPUT:-}" ]; then printf '%s=%s\n' "$1" "$2" >>"$GITHUB_OUTPUT"; fi
}

sha256() {
  if command -v sha256sum >/dev/null 2>&1; then sha256sum; else shasum -a 256; fi | awk '{ print $1 }'
}

# The packing perl's bin first on PATH; with "lib", the local lib active as
# local::lib sets it. Without, its variables are unset: the binary under test
# finds no module outside itself.
leg_env() {
  local perl_bin
  if [ "$os" = windows ]; then
    perl_bin=$(posix "${DZIL_BINARY_PERL_BIN:?DZIL_BINARY_PERL_BIN is not set}")
  else
    perl_bin=$ROOT/perl/bin
  fi
  [ -x "$perl_bin/perl$exe" ] || die "no packing perl in $perl_bin"
  if [ "${1:-}" = lib ]; then
    PATH="$perl_bin:$(posix "$LOCAL/bin"):$PATH"
    export PERL_LOCAL_LIB_ROOT=$LOCAL
    export PERL_MB_OPT="--install_base \"$LOCAL\""
    export PERL_MM_OPT="INSTALL_BASE=$LOCAL"
    export PERL5LIB=$LOCAL/lib/perl5
  else
    PATH="$perl_bin:$PATH"
    unset PERL_LOCAL_LIB_ROOT PERL_MB_OPT PERL_MM_OPT PERL5LIB
  fi
  export PATH
}

# Reads x_binaries of the unpacked dist:  meta prepare | meta names | meta <field> <name>
meta() {
  perl - "$DIST/META.json" "$@" <<'PERL'
  use strict; use warnings; use JSON::PP ();
  my ($file, $what, $name) = @ARGV;
  open my $fh, "<:raw", $file or die "cannot read $file: $!\n";
  my $m = JSON::PP->new->decode(do { local $/; <$fh> });
  my $x = $m->{x_binaries};
  die "$file has no x_binaries\n" unless ref $x eq "HASH";
  my $bins = ref $x->{binaries} eq "HASH" ? $x->{binaries} : {};
  if ($what eq "prepare") { print $x->{prepare} // ""; exit 0 }
  if ($what eq "names") {
    die "$file: x_binaries has no binaries\n" unless %$bins;
    for (sort keys %$bins) {
      die "bad binary name: $_\n" unless /\A[A-Za-z0-9][A-Za-z0-9._-]*\z/;
      print "$_\n";
    }
    exit 0;
  }
  my $b = $bins->{$name};
  die "no binary $name in x_binaries\n" unless ref $b eq "HASH";
  my $v = $b->{$what};
  if (ref $v eq "ARRAY") { print "$_\n" for @$v } elsif (defined $v) { print $v }
PERL
}

# lines LIST: the non-empty lines of LIST into LINES (bash 3.2 has no mapfile). Split on \n
# only and strip one trailing \r per line (Strawberry perl prints CRLF; command substitution
# strips only the last line's CR), the rule pp-args.pl's pp_args_lines states.
lines() {
  local l
  LINES=()
  while IFS= read -r l; do
    l=${l%$'\r'}
    if [ -n "$l" ]; then LINES+=("$l"); fi
  done <<<"$1"
}

names() {
  local list
  list=$(meta names)
  lines "$list"
  [ ${#LINES[@]} -gt 0 ] || die "x_binaries has no binaries"
  NAMES=("${LINES[@]}")
}

hook() { (cd "$DIST" && sh -c "$1 \"\$@\"" sh "$2"); }

init() {
  set -- tarball/*.tar.gz
  if [ $# -ne 1 ] || [ ! -f "$1" ]; then die "want exactly one tarball/*.tar.gz, found: $*"; fi
  rm -rf dist out
  mkdir dist out
  tar xzf "$1" -C dist --strip-components=1
  [ -f dist/META.json ] || die "the dist tarball has no META.json"
  if [ "$os" != windows ]; then
    emit perl_key "dzil-binary-perl-$PLATFORM-$( { cat "$HERE/build-perl.sh"; printf '%s\n' "${LEG_IMAGE:-}" "${MACOSX_DEPLOYMENT_TARGET:-}"; } | sha256)"
  fi
}

keys() {
  local perl_version perl_sha sum
  leg_env lib
  perl -e 'exit !($] >= 5.040 && $] < 5.041)' || die "the packing perl is $(perl -e 'print $^V'), want 5.40"
  perl -V:version -V:archname
  perl_version=$(perl -MConfig -e 'print $Config{version}')
  # build-perl.sh's hash too: XS modules built for one packing perl build never
  # come back for another of the same version.
  perl_sha=$(sha256 <"$HERE/build-perl.sh")
  sum=$(perl -MJSON::PP -MDigest::SHA=sha256_hex -e '
    open my $fh, "<:raw", $ARGV[0] or die "cannot read $ARGV[0]: $!\n";
    my $m = JSON::PP->new->decode(do { local $/; <$fh> });
    print sha256_hex(JSON::PP->new->canonical->encode($m->{prereqs} || {}));
  ' "$DIST/META.json")
  emit lib_key "dzil-binary-lib-$PLATFORM-perl$perl_version-$perl_sha-$sum-${PREPARE_KEY:?PREPARE_KEY is not set}"
}

prepare() {
  local cmd
  leg_env lib
  cmd=$(meta prepare)
  [ -n "$cmd" ] || die "x_binaries has no prepare"
  mkdir -p "$PREPARE_DIR" "$LOCAL"
  hook "$cmd" "$PREPARE_DIR"
}

deps() {
  leg_env lib
  mkdir -p "$LOCAL"
  # "." - cpanm takes an argument for a directory only when it starts with . or /
  ( cd "$DIST" && perl -S cpanm --notest --installdeps . && perl -S cpanm --notest PAR::Packer ) || {
    tail -n 80 "$HOME/.cpanm/build.log" >&2 || true
    die "installing the dependencies into $LOCAL failed"
  }
}

# The packing perl's pp: the local lib's when deps installed PAR::Packer there,
# else one in the perl's own script dirs: site, then vendor, then core (Strawberry
# ships PAR::Packer as a vendor install, so cpanm finds it up to date and installs
# nothing locally, and its pp sits in perl\bin). Never a pp on PATH.
# Prints the pp, or fails printing the directories it looked in.
pp_script() {
  perl -MConfig -e '
    my %seen;
    my @dirs = grep { defined && length && !$seen{$_}++ }
      @ARGV, @Config{qw(installsitescript installsitebin installvendorscript
        installvendorbin installscript installbin)};
    for (@dirs) { if (-f "$_/pp") { print "$_/pp"; exit 0 } }
    print join ", ", @dirs;
    exit 1;
  ' "$LOCAL/bin"
}

# pp_run PP OUT ARG...: perl PP ARG... from the dist root, echoed first; fails
# when it wrote no OUT.
pp_run() {
  local pp=$1 out=$2
  shift 2
  echo "+ perl $pp $*"
  ( cd "$DIST" && PAR_VERBATIM=1 perl "$pp" "$@" )
  [ -f "$out" ] || die "pp wrote no $out"
}

# win_dlls BINARY: into LINES, the DLLs BINARY links that neither the system nor
# the binary provides, taken from the packing perl's own directories only -
# Strawberry's perl\bin, then c\bin (OpenSSL & co.), siblings under its root;
# never System32, Git's mingw64 or PATH.
win_dlls() {
  local perl_bin list
  perl_bin=$(native "${DZIL_BINARY_PERL_BIN:?DZIL_BINARY_PERL_BIN is not set}")
  list=$(perl "$HERE/win-dlls.pl" "$1" "$perl_bin" "$(dirname "$(dirname "$perl_bin")")/c/bin") ||
    die "cannot list the DLLs $1 links"
  lines "$list"
}

pack() {
  local name out a args list dist pp links
  leg_env lib
  pp=$(pp_script) || die "the packing perl has no pp in: $pp"
  names
  for name in "${NAMES[@]}"; do
    out=$OUT/$name-$VERSION-$PLATFORM$exe
    perl "$HERE/pp-args.pl" "$DIST/META.json" "$name" "$out" "$DIST" >"$TOP/pp-args.bin"
    args=()
    while IFS= read -r -d '' a; do args+=("$a"); done <"$TOP/pp-args.bin"
    rm -f "$TOP/pp-args.bin"
    pp_run "$pp" "$out" "${args[@]}"
    # Windows: XS of Strawberry's (Net::SSLeay, ...) links DLLs of Strawberry's
    # c\bin; pack them, or the binary needs Strawberry on the user's machine.
    if [ "$os" = windows ]; then
      win_dlls "$out"
      if [ ${#LINES[@]} -gt 0 ]; then
        echo "+ windows: linking ${#LINES[@]} DLL(s) from the packing perl: ${LINES[*]}"
        links=()
        for a in "${LINES[@]}"; do links+=(-l "$a"); done
        rm -f "$out"
        pp_run "$pp" "$out" "${links[@]}" "${args[@]}"
      fi
    fi
    perl "$HERE/lib-gate.pl" "$out" "$os"
    list=$(meta require "$name")
    lines "$list"
    if [ ${#LINES[@]} -gt 0 ]; then perl "$HERE/require-gate.pl" "$out" "${LINES[@]}"; fi
  done
  # one artifact per leg, <dist>-<version>-<platform>, holding the binaries as named above
  dist=$(perl -MJSON::PP -e '
    open my $fh, "<:raw", $ARGV[0] or die "cannot read $ARGV[0]: $!\n";
    print JSON::PP->new->decode(do { local $/; <$fh> })->{name} // "";
  ' "$DIST/META.json")
  [ -n "$dist" ] || die "META.json has no name"
  emit artifact "$dist-$VERSION-$PLATFORM"
}

# The binary under test sees no local lib; the hook gets it in
# DZIL_BINARY_PERL5LIB, the PERL5LIB that `leg_env lib` sets (Windows: the
# C:/... form Strawberry perl takes).
verify() {
  local name cmd
  leg_env
  export DZIL_BINARY_PERL5LIB=$LOCAL/lib/perl5
  names
  for name in "${NAMES[@]}"; do
    cmd=$(meta verify "$name")
    if [ -z "$cmd" ]; then echo "::notice::$name: x_binaries declares no verify"; continue; fi
    hook "$cmd" "$OUT/$name-$VERSION-$PLATFORM$exe"
  done
}

case $phase in
  init|keys|prepare|deps|pack|verify) "$phase" ;;
  *) die "usage: build-leg.sh init|keys|prepare|deps|pack|verify" ;;
esac
