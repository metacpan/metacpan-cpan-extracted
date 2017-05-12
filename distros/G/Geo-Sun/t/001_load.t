# -*- perl -*-
use Test::More tests => 17;

BEGIN { use_ok( 'Geo::Sun' ); }
BEGIN { use_ok( 'Geo::Sun::Bearing' ); }
BEGIN { use_ok( 'GPS::Point' ); }

my $gs = Geo::Sun->new;
isa_ok($gs,                        'Geo::Sun');
isa_ok($gs->ellipsoid,             "Geo::Ellipsoids");
isa_ok($gs->sun,                   "Astro::Coord::ECI::Sun");
isa_ok($gs->datetime,              "DateTime");
isa_ok($gs->point_dt,              "GPS::Point");
isa_ok($gs->point_recalculate,     "Geo::Sun");
isa_ok($gs->point,                 "GPS::Point");

my $station=GPS::Point->new(lat=>39, lon=>-77);
$gs = Geo::Sun::Bearing->new(station=>$station);
isa_ok($gs,                        'Geo::Sun::Bearing');
isa_ok($gs->ellipsoid,             "Geo::Ellipsoids");
isa_ok($gs->sun,                   "Astro::Coord::ECI::Sun");
isa_ok($gs->datetime,              "DateTime");
isa_ok($gs->point_dt,              "GPS::Point");
isa_ok($gs->point_recalculate,     "Geo::Sun::Bearing");
isa_ok($gs->point,                 "GPS::Point");
