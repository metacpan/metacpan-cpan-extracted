#!perl

use Test::More tests => 1;

BEGIN {
	use_ok( 'Getopt::Declare' );
}

diag( "Testing Getopt::Declare $Getopt::Declare::VERSION, Perl $], $^X" );
