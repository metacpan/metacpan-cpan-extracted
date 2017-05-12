#!/usr/bin/perl

# Test that File::Remove (with or without globbing) supports the use of
# spaces in the path to delete.

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More qw(no_plan);
use File::Spec::Functions ':ALL';
use File::Copy   ();
use File::Remove ();





#####################################################################
# Set up for the test

my $t  = catdir( curdir(), 't' );
my $s  = catdir(  $t, 'spaced path' );
my $f1 = catfile( $s, 'foo1.txt'    );
my $f2 = catfile( $s, 'foo2.txt'    );
my $f3 = catfile( $s, 'bar.txt'     );

sub create_directory {
	mkdir($s,0777) or die "Failed to create $s";
	ok( -d $s, "Created $s ok" );
	ok( -r $s, "Created $s -r" );
	ok( -w $s, "Created $s -w" );
	open( FILE, ">$f1" ) or die "Failed to create $f1";
	print FILE "Test\n";
	close FILE;
	open( FILE, ">$f2" ) or die "Failed to create $f2";
	print FILE "Test\n";
	close FILE;
	open( FILE, ">$f3" ) or die "Failed to create $f3";
	print FILE "Test\n";
	close FILE;
}

sub clear_directory {
	if ( -e $f1 ) {
		unlink( $f1 )      or die "unlink: $f1 failed";
		! -e $f1           or die "unlink didn't work";
	}
	if ( -e $f2 ) {
		unlink( $f2 )      or die "unlink: $f2 failed";
		! -e $f2           or die "unlink didn't work";
	}
	if ( -e $f3 ) {
		unlink( $f3 )      or die "unlink: $f3 failed";
		! -e $f3           or die "unlink didn't work";
	}
	if ( -e $s ) {
		rmdir( $s )       or die "rmdir: $s failed";
		! -e $s           or die "rmdir didn't work";
	}
}

# Make sure there is no directory from a previous run
clear_directory();

# Create the directory
create_directory();

# Schedule cleanup
END {
	clear_directory();
}





#####################################################################
# Main Testing

# Expand a glob that should match the foo files
my @match = File::Remove::expand('t/spaced path/foo*');
is( scalar(@match), 2, 'Found two results' );
ok( $match[0] =~ /foo1.txt/, 'Found foo1' );
ok( $match[1] =~ /foo2.txt/, 'Found foo2' );
