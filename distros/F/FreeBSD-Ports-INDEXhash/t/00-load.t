#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'FreeBSD::Ports::INDEXhash' );
}

diag( "Testing FreeBSD::Ports::INDEXhash $FreeBSD::Ports::INDEXhash::VERSION, Perl $], $^X" );
