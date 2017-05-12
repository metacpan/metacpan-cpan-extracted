#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'McBain::WithGearmanXS' ) || print "Bail out!\n";
}

diag( "Testing McBain::WithGearmanXS $McBain::WithGearmanXS::VERSION, Perl $], $^X" );
