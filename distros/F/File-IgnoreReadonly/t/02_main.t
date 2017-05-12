#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 12;
use File::IgnoreReadonly  ();
use File::Spec::Functions ':ALL';
use File::Remove          'clear';





#####################################################################
# Create the readonly test file

my $file = catfile( 't', 'readonly.txt' );
clear( $file );
ok( ! -f $file, 'Test file does not exist' );
open( FILE, ">$file" ) or die "open: $!";
print FILE "This is a test file";
close( FILE );
if ( File::IgnoreReadonly::WIN32 ) {
	require Win32::File::Object;
	Win32::File::Object->new( $file, 1 )->readonly(1);
} else {
	require File::chmod;
	File::chmod::chmod('a-w', $file);
}
ok(   -f $file, 'Test file exists'          );
ok(   -r $file, 'Test file is readable'     );
SKIP: {
	unless ( File::IgnoreReadonly::WIN32 or ($< and $>) ) {
		skip( "Skipping test known to fail for root", 1 );
	}
	ok( ! -w $file, 'Test file is not writable' );
}





#####################################################################
# Main Tests

SCOPE: {
	# Create the guard object
	my $guard = File::IgnoreReadonly->new( $file );
	isa_ok( $guard, 'File::IgnoreReadonly' );

	# File should now be writable
	ok( -f $file, 'Test file exists'          );
	ok( -r $file, 'Test file is readable'     );
	ok( -w $file, 'Test file is not writable' );

	# Change the file
	open( FILE, ">$file" ) or die "open: $!";
	print FILE 'File has been changed';
	close( FILE );
}

# Destroy should have been fired.
ok(   -f $file, 'Test file exists'          );
ok(   -r $file, 'Test file is readable'     );
SKIP: {
	unless ( File::IgnoreReadonly::WIN32 or ($< and $>) ) {
		skip( "Skipping test known to fail for root", 1 );
	}
	ok( ! -w $file, 'Test file is not writable' );
}

# File contents should be different
open( FILE, $file ) or die "open: $!";
my $line = <FILE>;
close( FILE );
is( $line, 'File has been changed', 'File changed ok' );
