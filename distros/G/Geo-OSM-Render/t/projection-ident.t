use warnings;
use strict;
use Test::More tests => 2;

use Geo::OSM::Render::Projection::Ident;

my $lat = 42;
my $lon = 17;

my $proj = Geo::OSM::Render::Projection::Ident->new;

my ($x, $y) = $proj->lat_lon_to_x_y($lat, $lon);

is($lat, $y, 'lat = y');
is($lon, $x, 'lon = x');
