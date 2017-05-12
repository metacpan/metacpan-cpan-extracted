#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Encode::Unicode::Japanese' );
}

diag( "Testing Encode::Unicode::Japanese $Encode::Unicode::Japanese::VERSION, Perl $], $^X" );
