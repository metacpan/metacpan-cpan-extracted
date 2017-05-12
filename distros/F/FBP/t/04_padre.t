#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 5;
use Test::NoWarnings;
use File::Spec::Functions ':ALL';
use FBP ();

# Find the test file
my $FILE = catfile( 't', 'data', 'padre.fbp' );
ok( -f $FILE, "Found test file '$FILE'" );

# Create the empty object
my $object = FBP->new;
isa_ok( $object, 'FBP' );

# Parse the file
my $ok = eval {
	$object->parse_file( $FILE );
};
is( $@, '', "Parsed '$FILE' without error" );
ok( $ok, '->parse_file returned true' );
