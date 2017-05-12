#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'KiokuDB::Backend::MongoDB' );
}

diag( "Testing KiokuDB::Backend::MongoDB $KiokuDB::Backend::MongoDB::VERSION, Perl $], $^X" );
