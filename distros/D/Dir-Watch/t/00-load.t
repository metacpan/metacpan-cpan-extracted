#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Dir::Watch' );
}

diag( "Testing Dir::Watch $Dir::Watch::VERSION, Perl $], $^X" );
