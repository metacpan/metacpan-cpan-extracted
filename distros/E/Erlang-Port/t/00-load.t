#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Erlang::Port' );
}

diag( "Testing Erlang::Port $Erlang::Port::VERSION, Perl $], $^X" );
