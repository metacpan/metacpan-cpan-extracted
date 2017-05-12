#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Graph::ChuLiuEdmonds' );
}

diag( "Testing Graph::ChuLiuEdmonds $Graph::ChuLiuEdmonds::VERSION, Perl $], $^X" );
