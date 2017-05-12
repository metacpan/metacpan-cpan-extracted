#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Dir::Which' );
}

diag( "Testing Dir::Which $Dir::Which::VERSION, Perl $], $^X" );
