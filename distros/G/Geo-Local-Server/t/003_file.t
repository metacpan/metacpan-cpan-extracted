# -*- perl -*-

use strict;
use warnings;
use Test::More tests => 9;
use Path::Class qw{file dir};

local $ENV{"COORDINATES_WGS84_LON_LAT_HAE"}=""; #must be not true for this to test correctly

my $file=file(file($0)->dir, qw{.. etc local.coordinates});

BEGIN { use_ok( 'Geo::Local::Server' ); }

my $gls = Geo::Local::Server->new(configfile=>$file);
isa_ok ($gls, 'Geo::Local::Server');

is($gls->lat, "38.780276", "lat");
is($gls->lon, "-77.386706", "lon");
is($gls->hae, "63", "hae");

{
my @a=$gls->latlon;
is($a[0], "38.780276", "latlon");
is($a[1], "-77.386706", "latlon");
}

{
my @a=$gls->latlong;
is($a[0], "38.780276", "latlong");
is($a[1], "-77.386706", "latlong");
}
