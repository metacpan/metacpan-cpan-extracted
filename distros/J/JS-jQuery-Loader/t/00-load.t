#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'JS::jQuery::Loader' );
}

diag( "Testing JS::jQuery::Loader $JS::jQuery::Loader::VERSION, Perl $], $^X" );
