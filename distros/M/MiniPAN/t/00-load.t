#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'MiniPAN' );
}

diag( "Testing MiniPAN $MiniPAN::VERSION, Perl $], $^X" );
