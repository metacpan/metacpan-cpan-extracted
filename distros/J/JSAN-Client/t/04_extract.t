#!/usr/bin/perl

# Basic test for JSAN::Index

use strict;
BEGIN {
    $|  = 1;
    $^W = 1;
}

use Test::More tests => 5;
use File::Spec::Functions ':ALL';
use File::Remove 'remove';
use LWP::Online  'online';

BEGIN { remove( \1, 'temp' ) if -e 'temp'; }
END   { remove( \1, 'temp' ) if -e 'temp'; }

use JSAN::Index;

JSAN::Index->init({
    mirror_local => 'temp',
    prune => 1
});

# Create and/or clear the test directory
my $testdir = catdir( curdir(), '05_extract' );
remove \1, $testdir if -e $testdir;
ok( ! -e $testdir, "Test directory '$testdir' does not exist" );
ok( mkdir($testdir), "Create test directory '$testdir'" );
END {
    remove \1, $testdir if -e $testdir;
}





#####################################################################
# Extract a known release into the test directory

SKIP: {
    skip("Skipping online tests", 3) unless online();

    # Find a known library
    my $swap = JSAN::Index::Library->retrieve( name => 'Display.Swap' );
    isa_ok( $swap, 'JSAN::Index::Library' );

    # Attempt to extract it to the testdir
    ok( $swap->extract_libs( to => $testdir ),
        '->extract_libs returns ok for Display.Swap' );
    my $testfile = catfile( $testdir, 'Display', 'Swap.js' );
    ok( -f $testfile, "->extract_libs created expected file '$testfile'" );
}
