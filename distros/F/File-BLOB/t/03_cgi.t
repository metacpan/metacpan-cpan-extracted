#!/usr/bin/perl

# Basic functionality testing for File::BLOB

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use constant T => 11;
use Test::More tests => T;
use File::BLOB ();

# Optionally load CGI
eval { require CGI; };
SKIP: {
	unless ( $CGI::VERSION and $CGI::VERSION >= 2.47 ) {
		skip("CGI is not installed", T);
	}





	#####################################################################
	# Test creation from a CGI object

	# Create an empty CGI object
	my $empty = CGI->new( { } );
	isa_ok( $empty, 'CGI' );
	is_deeply( [ $empty->param ], [ ], 'Confirmation there are no params' );

	# Check the from_cgi method in list and scalar contexts
	my $scalar_null = File::BLOB->from_cgi( $empty, 'foo' );
	is( $scalar_null, undef, '->from_cgi on empty param in scalar context returns undef' );
	my @list_null = File::BLOB->from_cgi( $empty, 'foo' );
	is_deeply( \@list_null, [ ], '->from_cgi on empty param in list context returns null list' );

	eval { File::BLOB->from_cgi() };
	like( $@, qr/First argument to from_cgi was not a CGI object/,
	'->from_cgi throws a correct error on null params' );
	eval { File::BLOB->from_cgi(undef) };
	like( $@, qr/First argument to from_cgi was not a CGI object/,
	'->from_cgi throws a correct error on undef param' );
	eval { File::BLOB->from_cgi('foo') };
	like( $@, qr/First argument to from_cgi was not a CGI object/,
	'->from_cgi throws a correct error on string param' );
	eval { File::BLOB->from_cgi('CGI') };
	like( $@, qr/First argument to from_cgi was not a CGI object/,
	'->from_cgi throws a correct error on string matching object class' );
	eval { File::BLOB->from_cgi($empty) };
	like( $@, qr/Second argument to from_cgi was not a CGI param/,
	'->from_cgi throws a correct error on string matching object class' );
	eval { File::BLOB->from_cgi($empty, undef) };
	like( $@, qr/Second argument to from_cgi was not a CGI param/,
	'->from_cgi throws a correct error on undef object param' );
	eval { File::BLOB->from_cgi($empty, \'foo') };
	like( $@, qr/Second argument to from_cgi was not a CGI param/,
	'->from_cgi throws a correct error on SCALAR ref second param' );





	#############################################################
	# Check with actual upload CGIs
	
	### HOW???
}
