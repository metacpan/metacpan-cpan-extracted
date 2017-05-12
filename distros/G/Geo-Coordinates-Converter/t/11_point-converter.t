use strict;
use warnings;
use Test::More;

use Geo::Coordinates::Converter::Point;

my $point = Geo::Coordinates::Converter::Point->new({
    lat   => '35.20.51.664',
    lng   => '138.34.56.905',
    datum => 'tokyo',
});

my $wgs84 = $point->converter('wgs84');
isa_ok($wgs84, 'Geo::Coordinates::Converter::Point');
is($wgs84->lat, '35.21.03.342');
is($wgs84->lng, '138.34.45.725');
is($wgs84->datum, 'wgs84');

done_testing;
