#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Inline::Wrapper' );
}

diag( "Testing Inline::Wrapper $Inline::Wrapper::VERSION, Perl $], $^X" );
