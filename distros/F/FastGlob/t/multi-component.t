#!/usr/bin/env perl

# Test that multi-component glob patterns (e.g. lib/*/*.pm) correctly
# skip non-directory entries and match only through actual directories.

use strict;
use warnings;

use Test::More;
use File::Temp qw(tempdir);
use File::Path qw(mkpath);
use FastGlob ();

# On Windows, FastGlob uses \ as separator but CORE::glob uses / —
# normalize both sides to forward slashes for comparison.
sub _norm { my @p = @_; s{\\}{/}g for @p; sort @p }

my $dir = tempdir( DIR => '.', CLEANUP => 1 );

# Create a directory structure:
#   $dir/
#     aaa/          (directory)
#       foo.txt
#       bar.txt
#     bbb/          (directory)
#       baz.txt
#     plain.txt     (regular file — should NOT be opened as a dir)
#     other.dat     (regular file)

mkpath("$dir/aaa");
mkpath("$dir/bbb");

for my $f ("$dir/aaa/foo.txt", "$dir/aaa/bar.txt", "$dir/bbb/baz.txt",
           "$dir/plain.txt",   "$dir/other.dat") {
    open my $fh, '>', $f or die "Cannot create $f: $!";
    close $fh;
}

# Pattern: $dir/*/*.txt — should match through subdirectories only
{
    my @got    = _norm( FastGlob::glob("$dir/*/*.txt") );
    my @expect = _norm( glob("$dir/*/*.txt") );
    is_deeply( \@got, \@expect,
        'multi-component pattern matches files inside subdirectories' );
    # Specifically: aaa/foo.txt, aaa/bar.txt, bbb/baz.txt
    is( scalar @got, 3, 'found exactly 3 .txt files in subdirs' );
}

# Pattern: $dir/aaa/* — single-level, should match files in aaa
{
    my @got    = _norm( FastGlob::glob("$dir/aaa/*") );
    my @expect = _norm( glob("$dir/aaa/*") );
    is_deeply( \@got, \@expect, 'single subdir pattern works' );
    is( scalar @got, 2, 'found 2 files in aaa/' );
}

# Pattern: $dir/*/* — should find all files inside subdirs, not plain files
{
    my @got    = _norm( FastGlob::glob("$dir/*/*") );
    my @expect = _norm( glob("$dir/*/*") );
    is_deeply( \@got, \@expect, 'wildcard/wildcard matches only through directories' );
    # Should find foo.txt, bar.txt, baz.txt — NOT plain.txt or other.dat
    is( scalar @got, 3, 'found 3 files via */*' );
}

# Pattern: $dir/* — should find both dirs and files at top level
{
    my @got    = _norm( FastGlob::glob("$dir/*") );
    my @expect = _norm( glob("$dir/*") );
    is_deeply( \@got, \@expect, 'single-level wildcard matches everything' );
    # aaa, bbb, other.dat, plain.txt
    is( scalar @got, 4, 'found 4 entries at top level' );
}

done_testing;
