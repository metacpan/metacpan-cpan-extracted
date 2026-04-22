#!/usr/bin/env perl
use strict;
use warnings;

# Usage:
#   xbin/release.pl python-prep   <perl-version>   (run_before_release)
#   xbin/release.pl python-upload                  (run_after_release)
#
# Split so the Python version bump happens in run_before_release — that way
# Git::Commit (AfterRelease) includes the bumped locale_simple.py in the
# release commit instead of leaving it dirty in the working tree forever.
#
# JS is intentionally NOT handled here — it is published by
# .github/workflows/publish-js.yml on tag push using npm Trusted Publishing
# (OIDC), so a flaky `npm publish` can never poison a dzil release.

use File::Spec;
use FindBin qw($Bin);

my ( $action, $perl_version ) = @ARGV;
die "usage: $0 python-prep <perl-version> | python-upload\n"
    unless $action and ( $action eq 'python-prep' or $action eq 'python-upload' );

my $root = File::Spec->rel2abs( "$Bin/.." );

sub run {
    my @cmd = @_;
    print "+ @cmd\n";
    system( @cmd ) == 0 or die "command failed (exit @{[ $? >> 8 ]}): @cmd\n";
}

chdir "$root/python" or die "chdir python: $!";

if ( $action eq 'python-prep' ) {
    die "python-prep needs a version argument\n" unless $perl_version;

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
    opendir my $dh, 'dist' or die "opendir dist: $! (did python-prep run?)";
    my @dist = grep { !/^\./ } readdir $dh;
    closedir $dh;
    die "no files in python/dist/\n" unless @dist;
    run( 'twine', 'upload', map { "dist/$_" } @dist );
}
