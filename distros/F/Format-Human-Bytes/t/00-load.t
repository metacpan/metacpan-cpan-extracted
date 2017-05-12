#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Format::Human::Bytes' );
}

diag( "Testing Format::Human::Bytes $Format::Human::Bytes::VERSION, Perl $], $^X" );
