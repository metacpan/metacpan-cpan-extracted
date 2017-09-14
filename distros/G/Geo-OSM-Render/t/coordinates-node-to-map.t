use warnings;
use strict;
use Test::More tests => 2;

use Geo::OSM::Render::Projection::Ident;
use Geo::OSM::Render::Viewport::Clipped;
use Geo::OSM::Primitive::Node;
use Geo::OSM::Render::Renderer;

my $osm_proj_id    = Geo::OSM::Render::Projection::Ident  ->new();
my $osm_vp_cl      = Geo::OSM::Render::Viewport::Clipped  ->new(
   x_of_map_0       =>  -2,
   x_of_map_width   =>   6,
   y_of_map_0       =>   5,
   y_of_map_height  =>  -1,
   max_width_height => 800
);

my $renderer=Geo::OSM::Render::Renderer->new($osm_proj_id, $osm_vp_cl);

my $node = Geo::OSM::Primitive::Node->new(42, 4, 2);
my ($x_map, $y_map) = $renderer->node_to_map_coordinates($node);

is($x_map, 400, 'x_map is 400');
is($y_map, 100, 'y_map is 100');
