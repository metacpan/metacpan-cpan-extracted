#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'IO::Tail' );
}

diag( "Testing IO::Tail $IO::Tail::VERSION, Perl $], $^X" );
