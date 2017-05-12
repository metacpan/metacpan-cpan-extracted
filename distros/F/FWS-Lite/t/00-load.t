#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'FWS::Lite' ) || print "Bail out!\n";
}

diag( "Testing FWS::Lite $FWS::Lite::VERSION, Perl $], $^X" );
