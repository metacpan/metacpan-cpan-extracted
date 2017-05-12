#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Fsdb' );
}

diag( "Testing Fsdb $Fsdb::VERSION, Perl $], $^X" );
