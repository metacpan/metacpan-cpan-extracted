#!/usr/bin/perl

# Regression test for rt.cpan.org #30251.

# Test that a directory called '{1234}' is deleted correctly.

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 6;
use File::Spec::Functions ':ALL';
use File::Remove ();

# Create the test directory
my $dir  = '{1234}';
my $path = catdir( 't', '{1234}' );
unless ( -e $path ) {
	mkdir($path,0777);
}
ok( -e $path, "Test directory $path exists" );

# Delete the test directory
my @removed = File::Remove::remove( \1, $path );
is_deeply( \@removed, [ $path ], 'remove returns as expected' );
ok( ! -e $path, "remove deletes the $path directory" );

# Repeat the tests on a dir named {1234} in the root path
unless ( -e $dir ) {
	mkdir($dir,0777);
}
ok( -e $dir, "Test directory $dir exists" );
@removed = File::Remove::remove( \1, $dir );
is_deeply( \@removed, [ $dir ], 'remove returns as expected' );
ok( ! -e $path, "remove delete the $dir directory" );
