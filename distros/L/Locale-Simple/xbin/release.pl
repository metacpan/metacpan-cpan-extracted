#!/usr/bin/env perl
use strict;
use warnings;

# Usage:
#   xbin/release.pl python-prep   <perl-version>   (run_before_release)
#   xbin/release.pl python-upload                  (run_after_release)
#
# python-prep checks the PyPI credentials first (nothing is published yet, so a
# missing credential stops the release before CPAN): ~/.pypirc with a [pypi]
# password/token, or TWINE_PASSWORD together with TWINE_USERNAME (or a pypi-
# token). No secret is ever printed.
#
# python-upload runs after the CPAN upload, when the release can no longer be
# taken back. A failed twine upload therefore prints the command that retries it
# by hand to STDERR and exits 0, so the tag, the push and the GitHub release
# (and the npm, crates.io, Packagist, Go and binary publishes behind them) go on.
#
# Split so the Python version bump happens in run_before_release — that way
# Git::Commit (AfterRelease) includes the bumped locale_simple.py in the
# release commit instead of leaving it dirty in the working tree forever.
#
# JS is intentionally NOT handled here — it is published by
# .github/workflows/publish-js.yml on tag push using npm Trusted Publishing
# (OIDC), so a flaky `npm publish` can never poison a dzil release.

use Cwd ();
use File::Spec;
use FindBin qw($Bin);

my ( $action, $perl_version ) = @ARGV;
die "usage: $0 python-prep <perl-version> | python-upload\n"
    unless $action and ( $action eq 'python-prep' or $action eq 'python-upload' );

my $root = Cwd::abs_path( "$Bin/.." );

# True when ~/.pypirc has a [pypi] section whose key $want is set.
sub pypirc_value {
    my ($want) = @_;
    my $home = $ENV{HOME};
    return unless defined $home and length $home;
    open my $fh, '<', "$home/.pypirc" or return;
    my $in_pypi = 0;
    my $found;
    while ( my $line = <$fh> ) {
        if ( $line =~ /^\s*\[([^\]]*)\]/ ) { $in_pypi = $1 eq 'pypi'; next }
        next unless $in_pypi;
        $found = 1 if $line =~ /^\s*\Q$want\E\s*[=:]\s*\S/;
    }
    close $fh;
    return $found;
}

sub check_pypi_credentials {
    my $env_pass = defined $ENV{TWINE_PASSWORD} && length $ENV{TWINE_PASSWORD};
    my $env_user = defined $ENV{TWINE_USERNAME} && length $ENV{TWINE_USERNAME};
    return 1 if pypirc_value('password');
    return 1 if $env_pass and ( $env_user or $ENV{TWINE_PASSWORD} =~ /^pypi-/ or pypirc_value('username') );
    my $home = defined $ENV{HOME} ? $ENV{HOME} : '(HOME unset)';
    die "python-prep: no PyPI credentials, the upload after the CPAN release would fail.\n"
      . "  missing: a [pypi] section with a password or token in $home/.pypirc,\n"
      . "  or TWINE_USERNAME and TWINE_PASSWORD in the environment\n"
      . "  (TWINE_PASSWORD alone works with a __token__ user from ~/.pypirc or a pypi- token).\n";
}

sub run {
    my @cmd = @_;
    print "+ @cmd\n";
    system( @cmd ) == 0 or die "command failed (exit @{[ $? >> 8 ]}): @cmd\n";
}

chdir "$root/python" or die "chdir python: $!";

if ( $action eq 'python-prep' ) {
    die "python-prep needs a version argument\n" unless $perl_version;
    check_pypi_credentials();

    my $file = 'locale_simple.py';
    open my $in,  '<', $file or die "read $file: $!";
    my @lines = <$in>;
    close $in;
    for ( @lines ) {
        s/__version__ = .*/__version__ = "$perl_version"/;
    }
    open my $out, '>', $file or die "write $file: $!";
    print $out @lines;
    close $out;

    run( 'rm', '-rf', 'dist' );
    run( 'python', '-m', 'build' );
    run( 'twine', 'check', glob 'dist/*' );
}
elsif ( $action eq 'python-upload' ) {
    my @dist;
    if ( opendir my $dh, 'dist' ) {
        @dist = sort grep { !/^\./ } readdir $dh;
        closedir $dh;
    }
    my @files = map { "python/dist/$_" } @dist;
    my $retry = @files
      ? "cd $root && twine upload @files"
      : "cd $root/python && python -m build && twine upload dist/*";
    my $ok = @files && system( 'twine', 'upload', map { "dist/$_" } @dist ) == 0;
    unless ($ok) {
        print STDERR <<"END";

==============================================================================
PyPI upload FAILED. CPAN is released, so the release goes on (tag, push,
GitHub release, npm, crates.io, Packagist, Go, binaries).
Upload the Python package by hand:

  $retry

==============================================================================
END
    }
    exit 0;
}
