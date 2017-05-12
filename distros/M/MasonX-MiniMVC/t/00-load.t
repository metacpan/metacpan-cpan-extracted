#!perl -T

use Test::More tests => 2;

BEGIN {
	use_ok( 'MasonX::MiniMVC' );
	use_ok( 'MasonX::MiniMVC::Dispatcher' );
}

diag( "Testing MasonX::MiniMVC $MasonX::MiniMVC::VERSION, Perl $], $^X" );
