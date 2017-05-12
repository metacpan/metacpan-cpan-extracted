#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'McBain::WithPSGI' ) || print "Bail out!\n";
}

diag( "Testing McBain::WithPSGI $McBain::WithPSGI::VERSION, Perl $], $^X" );
