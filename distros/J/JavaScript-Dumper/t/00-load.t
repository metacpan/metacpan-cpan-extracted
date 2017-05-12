#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'JavaScript::Dumper' );
}

diag( "Testing JavaScript::Dumper $JavaScript::Dumper::VERSION, Perl $], $^X" );
