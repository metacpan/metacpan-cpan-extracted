#!perl -T

use strict;
use warnings;
use Test::More tests => 1;
use Geo::WeatherNWS;

my $report_http = Geo::WeatherNWS::new();

SKIP: {
    skip "network dependent test", 1 unless $ENV{TEST_NETWORK};

    $report_http->getreporthttp('kstl');
    is($report_http->{code}, 'KSTL', 'icao code from http report');
}

