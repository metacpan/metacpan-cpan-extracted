use warnings;
use strict;
use Test::More tests => 2;

use Geo::OSM::Render::Projection::CH_LV03;

# La chaux des breleux
my $lat = 47 + 13/60 + 15/3600;
my $lon =  7 +  1/60 + 41/3600;

my $proj = Geo::OSM::Render::Projection::CH_LV03->new;

my ($x, $y) = $proj->lat_lon_to_x_y($lat, $lon);

is(568901.92, int(0.5 + 100*$x)/100, 'lon = x');
is(230071.03, int(0.5 + 100*$y)/100, 'lat = y');
