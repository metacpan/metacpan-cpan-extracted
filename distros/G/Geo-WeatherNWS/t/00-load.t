#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok('Geo::WeatherNWS') || print "Bail out!\n";
}

diag("Testing Geo::WeatherNWS $Geo::WeatherNWS::VERSION, Perl $], $^X");
