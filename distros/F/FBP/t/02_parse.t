#!/usr/bin/perl

# Initial test to check that the parser can handle all of the sample
# data files without crashing.

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 16;
use Test::NoWarnings;
use File::Spec::Functions ':ALL';
use FBP ();

my @FILES = qw{
	trivial.fbp
	simple.fbp
	padre.fbp
};

foreach my $file ( @FILES ) {
	my $object = FBP->new;
	isa_ok( $object, 'FBP' );

	my $path = File::Spec->catfile( 't', 'data', $file );
	ok( -f $path, "$path: Found test file" );

	my $ok = eval {
		$object->parse_file( $path );
	};
	is( $@, '', "$path: Parsed file without error" );
	ok( $ok, "$path: ->parse_file returned true" );

	my $children = $object->children;
	ok( scalar(@$children), "$path: Created objects for the file" );
}
