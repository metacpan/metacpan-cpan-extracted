#!/usr/bin/perl
use strict;
use warnings;

use File::Temp;
use File::Spec::Functions;
use File::Copy;
use Text::Diff;

use Test::More;

BEGIN {
    unless ( eval 'use Test::Script::Run; 1' ) {
        plan skip_all => "please install Test::Script::Run to run these tests"
    }
}

plan tests => 3;

use constant APP => catfile qw( bin reformat-pre.pl );
use constant EXT => '.orig';

my @base_datafiles = qw( DataFlow.pm.html DBD-SQLite-Cookbook.pod.html );
my @datafiles  = map catfile( 't', 'data', $_            ), @base_datafiles;
my @patchfiles = map catfile( 't', 'data', $_ . '.patch' ), @base_datafiles;

my $tmpdir = File::Temp->newdir;
my @tmp_datafiles = map catfile($tmpdir, $_), @base_datafiles;

copy($_, $tmpdir) or die "Copy failed: $!"
    foreach @datafiles;

run_ok(
    APP, [ '--backup', EXT, @tmp_datafiles ],
    'Run with ' . scalar(@tmp_datafiles) . ' files and backup'
);

my @patchtexts = map {
    open my $fh, '<', $_
        or die "Can't open file $_: ", $!;
    do { local $/; <$fh> }
} @patchfiles;

my @diffs;
# This will test the backup existence as well.
foreach ( @tmp_datafiles ) {
    diff( $_ . EXT, $_, { OUTPUT => \my @output } );
    push @diffs, join '', @output[1..$#output]
}

is( $diffs[$_], $patchtexts[$_], 'Check pod ' . ($_+1) )
    for 0..$#datafiles;
