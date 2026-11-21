#!/bin/sh
# Provenance facts of the binary release workflow, written as part files that
# provenance.pl merges into provenance.json:
#   facts.sh machine PREFIX    PREFIXos, PREFIXarchitecture, PREFIXabi, PREFIXkernel,
#                              PREFIXkernel_release of this machine on STDOUT; never fails
#   facts.sh plan OUT          the plan job's part. Environment: TAG (empty: probe),
#                              VERSION_SLOT, SOURCE_COMMIT (probe), GH_TOKEN (release),
#                              WORKFLOW_REPOSITORY, WORKFLOW_PATH, WORKFLOW_REF, WORKFLOW_SHA,
#                              CALLER_WORKFLOW_REF, CALLER_WORKFLOW_SHA, BUNDLE_REF,
#                              BUNDLE_SOURCE, BUNDLE_COMMIT and GitHub's GITHUB_*
#   facts.sh smoke OUT BIN     a smoke job's part, BIN the binary it smoked. Environment:
#                              PLATFORM, BIN_NAME, ASSET, SMOKE, IMAGE, RUNNER_LABEL,
#                              BUNDLE_COMMIT and the runner's ImageOS, ImageVersion, RUNNER_*
# A part has one KEY=VALUE line per fact; an empty value is null. A release's
# source commit is the one its tag ends at (through tag objects, via gh api).
# On Linux the smoke's target facts come from a fresh container of the smoked
# image (by its id), running `facts.sh machine target_` from a read-only mount.
# POSIX sh: it runs on the runners (Git Bash on Windows) and inside the smoke images.
set -eu

die() { echo "::error::$*"; exit 1; }

HERE=$(cd "$(dirname "$0")" && pwd)
NL='
'
CR=$(printf '\r')
MACHINE='os architecture abi kernel kernel_release'

# need NAME: fails unless the environment variable NAME is non-empty
need() {
  eval "v=\${$1:-}"
  [ -n "$v" ] || die "facts.sh: $1 is not set"
}

start() { OUT=$1; mkdir -p "$(dirname "$OUT")"; : >"$OUT"; }

# kv KEY VALUE: one line of the part; a value with a line break is refused
kv() {
  case $2 in *"$NL"*|*"$CR"*) die "facts.sh: the value of $1 has a line break" ;; esac
  printf '%s=%s\n' "$1" "$2" >>"$OUT"
}

osr() { sed -n "s/^$1=//p" /etc/os-release 2>/dev/null | head -n 1 | tr -d "\"'\r" || true; }

clean() { printf '%s' "$1" | tr -d '\r\n' || true; }

machine() {
  p=$1
  os='' abi=''
  arch=$(uname -m 2>/dev/null) || arch=''
  kernel=$(uname -s 2>/dev/null) || kernel=''
  release=$(uname -r 2>/dev/null) || release=''
  case $kernel in
    Linux*)
      id=$(osr ID) ver=$(osr VERSION_ID)
      [ -z "$id" ] || os="$id${ver:+ $ver}"
      if command -v getconf >/dev/null 2>&1; then abi=$(getconf GNU_LIBC_VERSION 2>/dev/null) || abi=''; fi
      ;;
    Darwin*)
      if command -v sw_vers >/dev/null 2>&1; then
        product=$(sw_vers -productName 2>/dev/null) || product=''
        pver=$(sw_vers -productVersion 2>/dev/null) || pver=''
        [ -z "$product" ] || os="$product${pver:+ $pver}"
      fi
      [ -z "$release" ] || abi=darwin-$release
      ;;
    MINGW*|MSYS*|CYGWIN*)
      # the Windows version from cmd's "ver" ("Microsoft Windows [Version 10.0.20348.1234]"),
      # not the MSYS runtime version uname -r reports
      winver=$(cmd.exe //c ver 2>/dev/null | tr -d '\r' | sed -n 's/.*\[[^0-9]*\([0-9][0-9.]*\)\].*/\1/p' | head -n 1) || winver=''
      if [ -n "$winver" ]; then
        os="windows $winver"
        build=$(printf '%s' "$winver" | cut -d. -f3) || build=''
        [ -z "$build" ] || abi=nt-$build
      fi
      ;;
  esac
  printf '%s=%s\n' "${p}os" "$(clean "$os")" "${p}architecture" "$(clean "$arch")" "${p}abi" "$(clean "$abi")" \
    "${p}kernel" "$(clean "$kernel")" "${p}kernel_release" "$(clean "$release")"
}

# gh_object ENDPOINT: TYPE and SHA of the git object ENDPOINT points at
gh_object() {
  r=$(gh api "repos/$GITHUB_REPOSITORY/$1" --jq '.object.type + " " + .object.sha') ||
    die "facts.sh: gh api repos/$GITHUB_REPOSITORY/$1 failed"
  TYPE=${r%% *} SHA=${r#* }
}

plan() {
  need VERSION_SLOT; need GITHUB_REPOSITORY; need GITHUB_RUN_ID; need GITHUB_RUN_ATTEMPT
  need WORKFLOW_SHA; need BUNDLE_SOURCE; need BUNDLE_COMMIT
  tag=${TAG:-} tag_object=''
  if [ -n "$tag" ]; then
    mode=release
    gh_object "git/ref/tags/$tag"
    hops=0
    while [ "$TYPE" = tag ]; do
      [ -n "$tag_object" ] || tag_object=$SHA
      hops=$((hops + 1))
      [ "$hops" -le 5 ] || die "facts.sh: tag $tag: more than 5 tag objects before a commit"
      gh_object "git/tags/$SHA"
    done
    [ "$TYPE" = commit ] || die "facts.sh: tag $tag ends at a '$TYPE', not a commit"
    source_commit=$SHA
  else
    mode=probe
    need SOURCE_COMMIT
    source_commit=$SOURCE_COMMIT
  fi
  start "$1"
  kv kind plan
  kv mode "$mode"
  kv tag "$tag"
  kv version_slot "$VERSION_SLOT"
  kv source_commit "$source_commit"
  kv source_tag_object "$tag_object"
  kv server_url "${GITHUB_SERVER_URL:-}"
  kv repository "$GITHUB_REPOSITORY"
  kv run_id "$GITHUB_RUN_ID"
  kv run_attempt "$GITHUB_RUN_ATTEMPT"
  kv event "${GITHUB_EVENT_NAME:-}"
  kv ref "${GITHUB_REF:-}"
  kv sha "${GITHUB_SHA:-}"
  kv caller_workflow_ref "${CALLER_WORKFLOW_REF:-}"
  kv caller_workflow_sha "${CALLER_WORKFLOW_SHA:-}"
  kv workflow_repository "${WORKFLOW_REPOSITORY:-}"
  kv workflow_path "${WORKFLOW_PATH:-}"
  kv workflow_ref "${WORKFLOW_REF:-}"
  kv workflow_commit "$WORKFLOW_SHA"
  kv bundle_ref_input "${BUNDLE_REF:-}"
  kv bundle_source "$BUNDLE_SOURCE"
  kv bundle_commit "$BUNDLE_COMMIT"
}

# sha256_of FILE -> SUM
sha256_of() {
  if command -v sha256sum >/dev/null 2>&1; then h=$(sha256sum <"$1") || h=''
  elif command -v openssl >/dev/null 2>&1; then h=$(openssl dgst -sha256 -r <"$1") || h=''
  elif command -v shasum >/dev/null 2>&1; then h=$(shasum -a 256 <"$1") || h=''
  else die "facts.sh: no sha256 tool (sha256sum, openssl, shasum)"
  fi
  h=${h%% *}
  case $h in ''|*[!0-9a-f]*) die "facts.sh: cannot hash $1" ;; esac
  [ ${#h} -eq 64 ] || die "facts.sh: cannot hash $1"
  SUM=$h
}

smoke() {
  bin=$2
  need PLATFORM; need BIN_NAME; need ASSET; need RUNNER_LABEL; need BUNDLE_COMMIT; need GITHUB_RUN_ATTEMPT
  [ -f "$bin" ] || die "facts.sh: no binary $bin"
  sha256_of "$bin"
  smoked=false image='' image_id='' image_platform='' digests='' target=''
  if [ -n "${SMOKE:-}" ]; then
    smoked=true
    case $PLATFORM in
      linux-*)
        need IMAGE
        image=$IMAGE
        image_id=$(docker image inspect --format '{{.Id}}' "$image") || die "facts.sh: docker image inspect $image failed"
        [ -n "$image_id" ] || die "facts.sh: docker image inspect $image gave no id"
        image_platform=$(docker image inspect --format '{{.Os}}/{{.Architecture}}' "$image") ||
          die "facts.sh: docker image inspect $image failed"
        variant=$(docker image inspect --format '{{.Variant}}' "$image") || die "facts.sh: docker image inspect $image failed"
        image_platform=$image_platform${variant:+/$variant}
        digests=$(docker image inspect --format '{{range .RepoDigests}}{{println .}}{{end}}' "$image") ||
          die "facts.sh: docker image inspect $image failed"
        target=$(docker run --rm -v "$HERE:/facts:ro" "$image_id" sh /facts/facts.sh machine target_) ||
          die "facts.sh: the facts run in $image ($image_id) failed"
        ;;
      *) target=$(machine target_) ;;
    esac
  fi
  start "$1"
  kv kind smoke
  kv platform "$PLATFORM"
  kv binary "$BIN_NAME"
  kv asset "$ASSET"
  kv sha256 "$SUM"
  kv smoked "$smoked"
  kv runner "$RUNNER_LABEL"
  kv runner_image_os "${ImageOS:-}"
  kv runner_image_version "${ImageVersion:-}"
  kv runner_os "${RUNNER_OS:-}"
  kv runner_arch "${RUNNER_ARCH:-}"
  kv run_attempt "$GITHUB_RUN_ATTEMPT"
  kv bundle_commit "$BUNDLE_COMMIT"
  machine host_ >>"$OUT"
  kv image "$image"
  kv image_id "$image_id"
  kv image_platform "$image_platform"
  while IFS= read -r d; do
    [ -z "$d" ] || kv image_repo_digest "$d"
  done <<EOF
$digests
EOF
  if [ "$smoked" = false ]; then
    for k in $MACHINE; do kv "target_$k" ''; done
  else
    while IFS= read -r l; do
      case $l in
        target_os=*|target_architecture=*|target_abi=*|target_kernel=*|target_kernel_release=*) printf '%s\n' "$l" >>"$OUT" ;;
        '') ;;
        *) die "facts.sh: the target facts run printed '$l'" ;;
      esac
    done <<EOF
$target
EOF
  fi
}

cmd=${1:-}
case $cmd in
  machine) [ $# -eq 2 ] || die "usage: facts.sh machine PREFIX"; machine "$2" ;;
  plan)    [ $# -eq 2 ] || die "usage: facts.sh plan OUT"; plan "$2" ;;
  smoke)   [ $# -eq 3 ] || die "usage: facts.sh smoke OUT BIN"; smoke "$2" "$3" ;;
  *) die "usage: facts.sh machine PREFIX | plan OUT | smoke OUT BIN" ;;
esac
