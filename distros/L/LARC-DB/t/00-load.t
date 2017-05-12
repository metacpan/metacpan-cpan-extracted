#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'LARC::DB' );
}

diag( "Testing LARC::DB $LARC::DB::VERSION, Perl $], $^X" );
