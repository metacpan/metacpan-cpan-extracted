use warnings;
use strict;

use Test::More tests => 7;

use Geo::OSM::Render::Viewport::Clipped;

my $osm_vp_cl      = Geo::OSM::Render::Viewport::Clipped  ->new(
  x_of_map_0       =>   -2,
  x_of_map_width   =>    8,
  y_of_map_0       =>    5,
  y_of_map_height  =>   -1,
  max_width_height => 1000
);

is ($osm_vp_cl->map_width (), 1000, 'map width  is 1000');
is ($osm_vp_cl->map_height(),  600, 'map height is  600');

is_deeply([ $osm_vp_cl->x_y_to_map_x_y(-2,  5) ], [   0,   0], '-2,  5 ->    0,   0');
is_deeply([ $osm_vp_cl->x_y_to_map_x_y( 8,  5) ], [1000,   0], ' 8,  5 -> 1000,   0');
is_deeply([ $osm_vp_cl->x_y_to_map_x_y(-2, -1) ], [   0, 600], '-2, -1 ->    0, 600');
is_deeply([ $osm_vp_cl->x_y_to_map_x_y( 8, -1) ], [1000, 600], '-2, -1 -> 1000, 600');

is_deeply([ $osm_vp_cl->x_y_to_map_x_y( 1,  3) ], [ 300, 200], ' 1, -1 ->  300, 200');
