#!/usr/bin/env perl
# Verify that recurseglob uses push (O(1) amortized) instead of unshift (O(n)).
# Since glob() returns sort(@res), insertion order does not affect correctness.
# This test validates correctness on a large directory to exercise the change.

use strict;
use warnings;

use Test::More;
use File::Temp qw(tempdir);
use File::Spec;

use FastGlob ();

my $dir = tempdir(DIR => '.', CLEANUP => 1);

# Create 500 files to exercise the directory scanning loop
my $count = 500;
for my $i (1 .. $count) {
    my $name = sprintf("file_%04d.dat", $i);
    open my $fh, '>', File::Spec->catfile($dir, $name) or die "Cannot create $name: $!";
    close $fh;
}

# Also create a few subdirectories with files for recursive glob
my $subdir = File::Spec->catdir($dir, 'sub');
mkdir $subdir or die "Cannot mkdir $subdir: $!";
for my $i (1 .. 50) {
    my $name = sprintf("nested_%03d.dat", $i);
    open my $fh, '>', File::Spec->catfile($subdir, $name) or die "Cannot create $name: $!";
    close $fh;
}

# Save and chdir
my $orig_dir = do { require Cwd; Cwd::getcwd() };
chdir $dir or die "Cannot chdir to $dir: $!";

# Flat glob — all .dat files in current dir
my @flat = FastGlob::glob('*.dat');
is(scalar @flat, $count, "flat glob finds all $count files");

# Verify sorted output (glob() contract)
my @sorted = sort @flat;
is_deeply(\@flat, \@sorted, 'results are sorted');

# Recursive glob — files in subdirectory
my @nested = FastGlob::glob('sub/*.dat');
is(scalar @nested, 50, 'recursive glob finds all 50 nested files');

# Verify sorted
my @nsorted = sort @nested;
is_deeply(\@nested, \@nsorted, 'nested results are sorted');

# Wildcard with partial match
my @partial = FastGlob::glob('file_00??.dat');
is(scalar @partial, 99, '? wildcard matches expected count (file_0001..file_0099)');

chdir $orig_dir;

done_testing;
