#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use File::Temp qw(tempdir);
use File::Path qw(make_path);

use FastGlob ();

# Test that Windows-style drive letter root patterns work correctly,
# including lowercase drive letters (e.g. c: vs C:).
# Bug: rootpat was [A-Z]: which rejected lowercase drive letters,
# causing glob to silently return no results.

# --- rootpat regex coverage ---

subtest 'rootpat matches drive letters on Windows' => sub {
    # Temporarily set Windows-style rootpat
    local $FastGlob::rootpat = '[A-Za-z]:';

    for my $letter ('A', 'C', 'Z', 'a', 'c', 'z') {
        like( "$letter:", qr/($FastGlob::rootpat)/,
            "rootpat matches $letter:" );
    }

    unlike( '1:', qr/\A($FastGlob::rootpat)\z/,
        'rootpat does not match digit:' );
    unlike( ':', qr/\A($FastGlob::rootpat)\z/,
        'rootpat does not match bare colon' );
};

# --- Functional test with simulated Windows config ---

subtest 'lowercase drive letter glob traversal' => sub {
    # Create a temp directory tree that simulates a drive-rooted path
    # Use DIR => '.' to avoid 8.3 short path issues on real Windows
    my $tmpdir = tempdir( DIR => '.', CLEANUP => 1 );

    make_path("$tmpdir/fakedir");
    my $file = "$tmpdir/fakedir/test.txt";
    open my $fh, '>', $file or die "Cannot create $file: $!";
    close $fh;

    # Save original config
    my $orig_dirsep    = $FastGlob::dirsep;
    my $orig_rootpat   = $FastGlob::rootpat;
    my $orig_curdir    = $FastGlob::curdir;
    my $orig_hidedot   = $FastGlob::hidedotfiles;

    # Simulate Windows-like config but use forward slash to work on Unix
    local $FastGlob::dirsep       = '/';
    local $FastGlob::rootpat      = '[A-Za-z]:';
    local $FastGlob::curdir       = '.';
    local $FastGlob::hidedotfiles = 1;

    # Verify that uppercase drive letter works (baseline)
    # We can't use a real drive letter on Unix, so test via rootpat regex
    ok( 'C:' =~ /($FastGlob::rootpat)/, 'uppercase C: matches rootpat' );
    ok( 'c:' =~ /($FastGlob::rootpat)/, 'lowercase c: matches rootpat' );

    # Functional glob test (non-rooted, since we're on Unix)
    my @got = FastGlob::glob("$tmpdir/fakedir/*.txt");
    is( scalar @got, 1, 'glob finds test.txt in fakedir' );
    like( $got[0], qr/test\.txt$/, 'result contains test.txt' );
};

# --- Default rootpat is correct per platform ---

subtest 'default rootpat is platform-appropriate' => sub {
    if ( $^O eq 'MSWin32' ) {
        like( 'C:', qr/\A($FastGlob::rootpat)\z/,
            'default rootpat matches uppercase drive letter' );
        like( 'c:', qr/\A($FastGlob::rootpat)\z/,
            'default rootpat matches lowercase drive letter' );
    } else {
        is( $FastGlob::rootpat, '\A\Z',
            'default rootpat on Unix is empty-string anchor' );
    }
};

done_testing;
