#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'FreeBSD::Pkgs::FindUpdates' );
}

diag( "Testing FreeBSD::Pkgs::FindUpdates $FreeBSD::Pkgs::FindUpdates::VERSION, Perl $], $^X" );
