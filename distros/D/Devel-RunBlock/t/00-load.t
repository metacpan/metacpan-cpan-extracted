#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Devel::RunBlock' );
}

diag( "Testing Devel::RunBlock $Devel::RunBlock::VERSION, Perl $], $^X" );
