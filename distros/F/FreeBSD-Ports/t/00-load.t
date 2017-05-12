#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'FreeBSD::Ports' );
}

diag( "Testing FreeBSD::Ports $FreeBSD::Ports::VERSION, Perl $], $^X" );
