#!perl -T

use Test::More tests => 2;

BEGIN {
	use_ok( 'FTN::Database' );
	use_ok( 'FTN::Database::Nodelist' );
}

diag( "Testing FTN::Database $FTN::Database::VERSION, Perl $], $^X" );
