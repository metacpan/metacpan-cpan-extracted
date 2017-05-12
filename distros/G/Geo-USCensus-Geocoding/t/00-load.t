#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Geo::USCensus::Geocoding' ) || print "Bail out!\n";
}

diag( "Testing Geo::USCensus::Geocoding $Geo::USCensus::Geocoding, Perl $], $^X" );
