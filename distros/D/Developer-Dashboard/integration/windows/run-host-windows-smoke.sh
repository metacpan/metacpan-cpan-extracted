#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
LOCAL_PERL5="$ROOT_DIR/.perl5"
LOCAL_DZIL="$LOCAL_PERL5/bin/dzil"

load_windows_env() {
  # Purpose: import reusable Windows smoke settings from an env file.
  # Input: optional WINDOWS_QEMU_ENV_FILE or default project/home env-file paths.
  # Output: exports the env-file variables into the current shell when a file exists.
  local candidate="${WINDOWS_QEMU_ENV_FILE:-}"

  if [[ -z "$candidate" && -f "$ROOT_DIR/.developer-dashboard/windows-qemu.env" ]]; then
    candidate="$ROOT_DIR/.developer-dashboard/windows-qemu.env"
  fi

  if [[ -z "$candidate" && -n "${HOME:-}" && -f "$HOME/.developer-dashboard/windows-qemu.env" ]]; then
    candidate="$HOME/.developer-dashboard/windows-qemu.env"
  fi

  if [[ -n "$candidate" ]]; then
    if [[ ! -f "$candidate" ]]; then
      echo "WINDOWS_QEMU_ENV_FILE does not exist: $candidate" >&2
      exit 1
    fi
    export WINDOWS_QEMU_ENV_FILE="$candidate"
    set -a
    # shellcheck disable=SC1090
    source "$candidate"
    set +a
  fi
}

ensure_tarball() {
  # Purpose: resolve or build the latest Developer Dashboard release tarball.
  # Input: optional TARBALL env var or the repo root plus a local Dist::Zilla toolchain.
  # Output: exports TARBALL as an absolute path to a readable tarball file.
  if [[ -n "${TARBALL:-}" ]]; then
    if [[ ! -f "$TARBALL" ]]; then
      echo "Provided TARBALL does not exist: $TARBALL" >&2
      exit 1
    fi
    TARBALL="$(cd "$(dirname "$TARBALL")" && pwd)/$(basename "$TARBALL")"
    export TARBALL
    return
  fi

  if [[ ! -x "$LOCAL_DZIL" ]]; then
    cpanm --local-lib-contained "$LOCAL_PERL5" --notest Dist::Zilla
  fi

  export PERL5LIB="$LOCAL_PERL5/lib/perl5${PERL5LIB:+:$PERL5LIB}"
  export PATH="$LOCAL_PERL5/bin:$PATH"

  cd "$ROOT_DIR"
  rm -rf Developer-Dashboard-* Developer-Dashboard-*.tar.gz
  "$LOCAL_DZIL" build

  TARBALL="$(ls -1t "$ROOT_DIR"/Developer-Dashboard-*.tar.gz | head -n1)"
  export TARBALL
}

load_windows_env
ensure_tarball

"$ROOT_DIR/integration/windows/run-qemu-windows-smoke.sh"

: <<'__END__'

=pod

=head1 NAME

run-host-windows-smoke.sh - build a fresh tarball and rerun the Windows smoke flow

=head1 SYNOPSIS

  integration/windows/run-host-windows-smoke.sh

  WINDOWS_QEMU_ENV_FILE=.developer-dashboard/windows-qemu.env \
  integration/windows/run-host-windows-smoke.sh

=head1 DESCRIPTION

This host-side helper loads C<windows-qemu.env> settings from either
C<WINDOWS_QEMU_ENV_FILE>, F<./.developer-dashboard/windows-qemu.env>, or
F<~/.developer-dashboard/windows-qemu.env>, builds a fresh
C<Developer-Dashboard-*.tar.gz> with C<dzil build> when C<TARBALL> is not
already provided, and then delegates to
F<integration/windows/run-qemu-windows-smoke.sh>.

=cut
__END__
