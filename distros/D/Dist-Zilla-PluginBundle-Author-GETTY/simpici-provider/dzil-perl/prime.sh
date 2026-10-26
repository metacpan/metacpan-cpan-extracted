#!/usr/bin/env bash
# Prime a perl:<ver> image for `dzil test` of [@Author::GETTY] distributions:
# Dist::Zilla, the bundle from CPAN (with every plugin it requires), and the
# develop-phase deps the bundle registers (Test::Pod via [PodSyntaxTests]).
#
# The develop deps exist only once a dist.ini is evaluated, so we fabricate a
# throwaway distribution and run the same two commands the SimpiCI helper and
# the dzil-test action run: `dzil authordeps --missing` and
# `dzil listdeps --author --missing`. listdeps gathers files through
# Git::GatherDir, so the dist must be a git repository with its files tracked
# (no commit needed); LicenseFile wants a LICENSE, which `dzil genlicense`
# writes. No remote, so the bundle falls back to [Repository].
set -euo pipefail

# On failure, show the build log before the layer (and the log) is thrown away.
cpanm_n() {
  cpanm -n "$@" || { cat "$HOME/.cpanm/build.log" >&2 || true; exit 1; }
}

cpanm_n Dist::Zilla Dist::Zilla::PluginBundle::Author::GETTY

dist="$(mktemp -d)"
cd "$dist"
mkdir -p lib/Dzil/Perl
cat > dist.ini <<'EOF'
name             = Dzil-Perl
author           = Nobody <nobody@example.invalid>
license          = Perl_5
copyright_holder = Nobody
copyright_year   = 2026

[@Author::GETTY]
EOF
cat > lib/Dzil/Perl.pm <<'EOF'
package Dzil::Perl;
# ABSTRACT: throwaway distribution priming the dzil-perl image
our $VERSION = '0.001';
1;
EOF
cat > Changes <<'EOF'
{{$NEXT}}

  - Throwaway.
EOF
dzil genlicense
git init -q .
git add -A

dzil authordeps --missing | cpanm_n
dzil listdeps --author --missing | cpanm_n

cd /
rm -rf "$dist" "$HOME/.cpanm"

# Fail the build now rather than in a consumer's CI.
perl -MDist::Zilla -MDist::Zilla::PluginBundle::Author::GETTY -MTest::Pod -e1
git --version
dzil --version
