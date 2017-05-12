use strict;
use warnings;
use utf8;
use Test::More tests => 1;
use Geo::Coordinates::Converter 0.10;
use Geo::Coordinates::Converter::iArea;
use HTTP::MobileAgent;
use HTTP::MobileAgent::Plugin::Locator qw/:locator/;

local $ENV{HTTP_USER_AGENT} = 'DoCoMo/2.0 SH904i(c100;TB;W24H16)';

my $ma = HTTP::MobileAgent->new();
is $ma->get_location(
    { lat => '35.21.03.342', lon => '138.34.45.725', geo => 'wgs84' },
)->converter('iarea')->areacode, '09500';

