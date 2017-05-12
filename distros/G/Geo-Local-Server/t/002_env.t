# -*- perl -*-

use strict;
use warnings;
use Test::More tests => 9;

BEGIN {$ENV{"COORDINATES_WGS84_LON_LAT_HAE"}="  \t   lon  \t  lat   hae  \r\n"};

BEGIN { use_ok( 'Geo::Local::Server' ); }

my $glc = Geo::Local::Server->new;
isa_ok ($glc, 'Geo::Local::Server');

is($glc->lat, "lat", "lat");
is($glc->lon, "lon", "lon");
is($glc->hae, "hae", "hae");

{
my @a=$glc->latlon;
is($a[0], "lat", "latlon");
is($a[1], "lon", "latlon");
}

{
my @a=$glc->latlong;
is($a[0], "lat", "latlong");
is($a[1], "lon", "latlong");
}
