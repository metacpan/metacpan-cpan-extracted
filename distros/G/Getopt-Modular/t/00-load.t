#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Getopt::Modular' );
}

diag( "Testing Getopt::Modular $Getopt::Modular::VERSION, Perl $], $^X" );
