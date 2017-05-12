#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'FreeBSD::Pkgs' );
}

diag( "Testing FreeBSD::Pkgs $FreeBSD::Pkgs::VERSION, Perl $], $^X" );
