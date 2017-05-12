#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'FreeBSD::Src' );
}

diag( "Testing FreeBSD::Src $FreeBSD::Src::VERSION, Perl $], $^X" );
