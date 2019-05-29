#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'GRNOC::Config' );
}
diag( "Testing GRNOC::Config $GRNOC::Config::VERSION, Perl $], $^X" );