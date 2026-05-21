#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
LOCAL_PERL5="$ROOT_DIR/.perl5"
LOCAL_DZIL="$LOCAL_PERL5/bin/dzil"

if [[ -n "${TARBALL:-}" ]]; then
  if [[ ! -f "$TARBALL" ]]; then
    echo "Provided TARBALL does not exist: $TARBALL" >&2
    exit 1
  fi
  export DASHBOARD_TARBALL="$TARBALL"
else
  if [[ ! -x "$LOCAL_DZIL" ]]; then
    cpanm --local-lib-contained "$LOCAL_PERL5" --notest Dist::Zilla
  fi

  export PERL5LIB="$LOCAL_PERL5/lib/perl5${PERL5LIB:+:$PERL5LIB}"
  export PATH="$LOCAL_PERL5/bin:$PATH"

  cd "$ROOT_DIR"
  rm -rf Developer-Dashboard-* Developer-Dashboard-*.tar.gz
  "$LOCAL_DZIL" build

  TARBALL="$(ls -1t Developer-Dashboard-*.tar.gz | head -n1)"
  export DASHBOARD_TARBALL="$ROOT_DIR/$TARBALL"
fi

prove -lv t/44-smart-router-two-stage.t

docker compose -f integration/blank-env/docker-compose.yml build blank-env
docker compose -f integration/blank-env/docker-compose.yml run --rm blank-env

: <<'__END__'

=pod

=head1 NAME

run-host-integration.sh - build the tarball on the host and run blank-container integration

=head1 SYNOPSIS

  integration/blank-env/run-host-integration.sh

=head1 DESCRIPTION

This script either uses a supplied host tarball via C<TARBALL=/path/to/tar.gz>
or installs Dist::Zilla into a local F<.perl5> toolchain when needed, builds
the C<Developer-Dashboard> tarball on the host, exports the resulting artifact
path as C<DASHBOARD_TARBALL>, runs the post-build
C<t/44-smart-router-two-stage.t> guard against that tarball, rebuilds the
blank-environment image from F<integration/blank-env/Dockerfile>, and then runs
the installed-runtime blank-environment integration flow against that freshly
built image.

=cut
__END__
