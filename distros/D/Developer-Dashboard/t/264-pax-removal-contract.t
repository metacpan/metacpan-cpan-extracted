#!/usr/bin/env perl

use strict;
use warnings;

use File::Spec;
use Test::More;

my $repo_root = File::Spec->rel2abs('.');

ok( !-e File::Spec->catfile( $repo_root, 'lib', 'Developer', 'Dashboard', 'PaxCache.pm' ),
    'PAX self-compile cache module is removed from the runtime' );
ok( !-e File::Spec->catfile( $repo_root, 'lib', 'Developer', 'Dashboard', 'Pax.pm' ),
    'PAX top-level package documentation/module is removed' );
ok( !-d File::Spec->catdir( $repo_root, 'lib', 'Developer', 'Dashboard', 'Pax' ),
    'vendored PAX compiler subsystem is removed' );
ok( !-e File::Spec->catfile( $repo_root, 'share', 'private-cli', 'pax' ),
    'PAX is no longer staged as an internal CLI command' );
ok( !-e File::Spec->catfile( $repo_root, '.github', 'workflows', 'pax-release.yml' ),
    'PAX standalone-release workflow is removed' );

for my $relative (qw(bin/d2 bin/dashboard lib/Developer/Dashboard/InternalCLI.pm)) {
    my $path   = File::Spec->catfile( $repo_root, split m{/}, $relative );
    my $source = _read_file($path);
    unlike( $source, qr/Developer::Dashboard::PaxCache|PAX_CACHE_ELIGIBLE_COMMANDS|_maybe_exec_self_compiled/,
        "$relative no longer contains PAX cache or self-compile integration" );
}

my $release_workflow = _read_file( File::Spec->catfile( $repo_root, '.github', 'workflows', 'release-github.yml' ) );
unlike( $release_workflow, qr/pax-release|attach-pax-binaries/i,
    'GitHub release workflow no longer schedules PAX builds or attaches PAX binaries' );

my $makefile = _read_file( File::Spec->catfile( $repo_root, 'Makefile.PL' ) );
unlike( $makefile, qr/\bpax\b/i, 'MakeMaker does not stage a removed PAX helper' );

my $dist_ini = _read_file( File::Spec->catfile( $repo_root, 'dist.ini' ) );
like( $dist_ini, qr/^exclude_match\s*=\s*\^pax-output\//m,
    'distribution excludes stale PAX build artifacts from the source archive' );

my $readme = _read_file( File::Spec->catfile( $repo_root, 'README.md' ) );
unlike( $readme, qr/dashboard pax build|Developer::Dashboard::PaxCache/i,
    'README no longer documents the removed PAX command or runtime cache' );

done_testing;

# _read_file($path)
# Reads one repository source or documentation file as text for contract checks.
# Input: filesystem path string.
# Output: complete file contents, or an empty string when the optional path is absent.
sub _read_file {
    my ($path) = @_;
    return '' if !defined $path || !-f $path;
    open my $fh, '<', $path or die "Unable to read '$path': $!";
    local $/;
    my $contents = <$fh>;
    close $fh or die "Unable to close '$path': $!";
    return defined $contents ? $contents : '';
}

__END__

=head1 NAME

t/264-pax-removal-contract.t - guards the removal of PAX from Developer Dashboard

=head1 PURPOSE

This test defines Problem 23's compatibility boundary. The Developer Dashboard
must contain no vendored PAX compiler, PAX CLI helper, self-compile cache, or
PAX-specific release workflow, and stale generated binaries must not enter the
source archive. Normal Perl commands remain the supported CLI runtime.

=head1 WHY IT EXISTS

PAX embeds a second compiler and runtime into the Developer Dashboard. A
real Docker build of C<dashboard> processed 117 application files and packaged
2,596 payloads in 41 seconds, before subsequent standalone execution concerns.
Removing the compiler is intended to reduce iteration cost and eliminate the
fragile compiled-entrypoint path instead of merely hiding its command.

=head1 WHEN TO USE

Run this test when changing the CLI entrypoints, helper registry, release
workflow, or documentation that could reintroduce the PAX integration.

=head1 HOW TO USE

    prove -lv t/264-pax-removal-contract.t

The full repository test suite also runs this contract. Docker verification
must additionally prove that C<d2 version> and C<dashboard version> still work
and that no PAX-specific helper is installed.

=head1 WHAT USES IT

The repository release gate uses this test to preserve the no-PAX runtime
contract for the public C<d2> and C<dashboard> commands.

=head1 EXAMPLES

    prove -lv t/264-pax-removal-contract.t
    d2 docker compose --project-name problem23 -f .developer-dashboard/config/docker/d2/compose.yml exec dev prove -lv t/264-pax-removal-contract.t

=cut
