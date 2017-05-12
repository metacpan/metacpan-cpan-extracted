use strict;
use warnings;
use utf8;
use Test::More tests => 1;
use Geo::Coordinates::Converter 0.10;
use Test::Requires 'Geo::Coordinates::Converter::Format::Geohash';
use HTTP::MobileAgent;
use HTTP::MobileAgent::Plugin::Locator qw/:locator/;

local $ENV{HTTP_USER_AGENT} = 'DoCoMo/2.0 SH904i(c100;TB;W24H16)';

Geo::Coordinates::Converter->add_default_formats('Geohash');

my $ma = HTTP::MobileAgent->new();
is $ma->get_location(
    { lat => '35.21.03.342', lon => '138.34.45.725', geo => 'wgs84' },
)->converter('wgs84', 'geohash')->geohash, 'xn6917qqj6dm2xc8fbny1';

