#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'MasonX::Resolver::Multiplex' );
}

diag( "Testing MasonX::Resolver::Multiplex $MasonX::Resolver::Multiplex::VERSION, Perl $], $^X" );
