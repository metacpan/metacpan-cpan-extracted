use warnings;
use strict;
use Test::More tests => 2;

use Geo::OSM::Render::Viewport::UnClipped;

my $vp = Geo::OSM::Render::Viewport::UnClipped->new();

my $x=42;
my $y=99;

my ($map_x, $map_y) = $vp->x_y_to_map_x_y($x, $y);

is($x, $map_x, 'x == map_x');
is($y, $map_y, 'y == map_y');
