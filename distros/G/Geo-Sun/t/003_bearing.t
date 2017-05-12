# -*- perl -*-
use Test::More tests => 15;
use Test::Number::Delta relative => 1e-4;

BEGIN { use_ok( 'Geo::Sun::Bearing' ); }
BEGIN { use_ok( 'DateTime' ); }
BEGIN { use_ok( 'GPS::Point' ); }

my $gs = Geo::Sun::Bearing->new;
isa_ok($gs, 'Geo::Sun::Bearing');

my $spring=DateTime->new( year   => 2008,
                          month  => 3,
                          day    => 20,
                          hour   => 5,
                          minute => 48,
                          time_zone => "UTC",
                         );
isa_ok($spring, "DateTime");
my $station=GPS::Point->new(lat=>0, lon=>0);
isa_ok($station, "GPS::Point");
my $point=$gs->set_datetime($spring)->point;
isa_ok($point, "GPS::Point");
delta_within($point->lat, 0, 0.005, "Spring Equinox");
delta_within($gs->set_station($station)->bearing, 90, 0.005, 'Spring Equinox bearing');
delta_within($gs->bearing, 90, 0.005, 'Spring Equinox bearing');
isa_ok($gs->station, "GPS::Point");

SKIP: {
  eval ' use Geo::Point ';
  skip "Geo::Point is not installed", 4 if $@;
  my $station=Geo::Point->new(latitude=>0, longitude=>0);
  isa_ok($station, "Geo::Point");
  isa_ok($gs->set_station($station), "Geo::Sun");
  isa_ok($gs->station, "Geo::Point");
  delta_within($gs->bearing, 90, 0.005, 'Spring Equinox bearing');
}
