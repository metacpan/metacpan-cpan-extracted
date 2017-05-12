#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Memoize::Memcached' );
}

diag( "Testing Memoize::Memcached $Memoize::Memcached::VERSION, Perl $], $^X" );
