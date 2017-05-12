#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Devel::Dt' );
}

diag( "Testing Devel::Dt $Devel::Dt::VERSION, Perl $], $^X" );
