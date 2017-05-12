#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Getopt::Complete' );
}

diag( "Testing Getopt::Complete $Getopt::Complete::VERSION, Perl $], $^X" );
