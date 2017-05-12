#!perl -T

use Test::More tests => 6;

BEGIN {
    use_ok( 'FWS::V2' ) || print "Bail out!\n";
    use_ok( 'FWS::V2::Check' ) || print "Bail out!\n";
    use_ok( 'FWS::V2::Database' ) || print "Bail out!\n";
    use_ok( 'FWS::V2::Safety' ) || print "Bail out!\n";
    use_ok( 'FWS::V2::Format' ) || print "Bail out!\n";
    use_ok( 'FWS::V2::File' ) || print "Bail out!\n";
}

diag( "Testing FWS::V2 $FWS::V2::VERSION, Perl $], $^X" );
