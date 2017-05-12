# -*- perl -*-

use strict;
use warnings;
use Test::More tests => 29;

BEGIN { use_ok( 'GPS::Point' ); }

my $lat=39;
my $lon=-77;
my $alt=72;
my $point;

$point = GPS::Point->newMulti({lat=>$lat,lon=>$lon,alt=>$alt});
isa_ok ($point, 'GPS::Point');
is($point->lat, $lat, '$point->lat');
is($point->lon, $lon, '$point->lon');
is($point->alt, $alt, '$point->lon');

$point = GPS::Point->newMulti(bless {lat=>$lat,lon=>$lon,alt=>$alt}, "My::Point");
isa_ok ($point, 'GPS::Point');
is($point->lat, $lat, '$point->lat');
is($point->lon, $lon, '$point->lon');
is($point->alt, $alt, '$point->lon');

$point = GPS::Point->newMulti(bless {latitude=>$lat, longitude=>$lon, elev=>$alt}, "My::Point");
isa_ok ($point, 'GPS::Point');
is($point->lat, $lat, '$point->lat');
is($point->lon, $lon, '$point->lon');
is($point->alt, $alt, '$point->lon');

$point = GPS::Point->newMulti(bless {lat=>$lat, long=>$lon, altitude=>$alt}, "My::Point");
isa_ok ($point, 'GPS::Point');
is($point->lat, $lat, '$point->lat');
is($point->lon, $lon, '$point->lon');
is($point->alt, $alt, '$point->lon');

$point = GPS::Point->newMulti({latitude=>$lat, long=>$lon, elevation=>$alt});
isa_ok ($point, 'GPS::Point');
is($point->lat, $lat, '$point->lat');
is($point->lon, $lon, '$point->lon');
is($point->alt, $alt, '$point->lon');

$point = GPS::Point->newMulti([$lat, $lon, $alt]);
isa_ok ($point, 'GPS::Point');
is($point->lat, $lat, '$point->lat');
is($point->lon, $lon, '$point->lon');
is($point->alt, $alt, '$point->lon');

$point = GPS::Point->newMulti(bless [$lat, $lon, $alt], "My::Point::Array");
isa_ok ($point, 'GPS::Point');
is($point->lat, $lat, '$point->lat');
is($point->lon, $lon, '$point->lon');
is($point->alt, $alt, '$point->lon');
