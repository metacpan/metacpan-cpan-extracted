#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Hatena::API::Auth' );
}

diag( "Testing Hatena::API::Auth $Hatena::API::Auth::VERSION, Perl $], $^X" );
