#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Integer::Tiny' );
}

diag( "Testing Integer::Tiny $Integer::Tiny::VERSION, Perl $], $^X" );
