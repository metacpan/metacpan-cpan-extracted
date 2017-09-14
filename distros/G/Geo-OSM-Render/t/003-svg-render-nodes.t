use strict;
use warnings;
use Test::More tests => 6;
use Test::File;

use Geo::OSM::Primitive::Node;
use Geo::OSM::Primitive::Way;
use Geo::OSM::Render::Projection::Ident;
use Geo::OSM::Render::Viewport::Clipped;

my $node_1 = Geo::OSM::Primitive::Node->new( 42, 4, 2);
my $node_2 = Geo::OSM::Primitive::Node->new( 99, 0, 0);
my $node_3 = Geo::OSM::Primitive::Node->new(100, 3, 1);
my $node_4 = Geo::OSM::Primitive::Node->new(101, 1, 2);

my $way_1  = Geo::OSM::Primitive::Way->new(1);
$way_1->_set_cache_nodes($node_1, $node_3, $node_4, $node_2);

my $proj = Geo::OSM::Render::Projection::Ident->new();
my $vp   = Geo::OSM::Render::Viewport::Clipped->new (
  x_of_map_0       =>  -2,  # westernmost
  x_of_map_width   =>   6,  # easternmost
  y_of_map_0       =>   5,  # northernmost
  y_of_map_height  =>  -1,  # southernmost 
  max_width_height => 800
);

use Geo::OSM::Render::Renderer::SVG;

my $svg_filename = 't/003-svg-render-nodes.svg';
my $osm_renderer_svg = Geo::OSM::Render::Renderer::SVG->new(
  $svg_filename,
  $proj,
  $vp
);

$osm_renderer_svg->render_node(
   $node_1,
   radius => 20,
   styles => {
        'fill'          => '#f63',
        'stroke'        => '#f31',
        'stroke-width'  =>     5 ,
   }
);

$osm_renderer_svg->render_node(
   $node_2,
   radius => 10,
   styles => {
        'fill'          => '#36f',
        'stroke'        => '#135',
        'stroke-width'  =>     8 ,
   }
);

$osm_renderer_svg->render_way(
  $way_1,
  styles => {
    'stroke'       => 'rgb( 30,  60, 255)',
    'stroke-width' => '2px',
    'fill'         => 'none',
  }
);

$osm_renderer_svg->line(
  $node_1->lat, $node_1->lon,
  $node_4->lat, $node_4->lon,
  styles => {
    'stroke-dasharray' => '5, 5',
    'stroke'           => 'rgb(100, 200, 100)',
    'stroke-width'     =>  5,
  }
);


$osm_renderer_svg->end;

file_contains_utf8_like($svg_filename, [
    qr/<svg .*height="600"/,
    qr/<svg .*width="800"/ ,
    qr/<circle cx="400" cy="100" r="20" style="fill: #f63; stroke: #f31; stroke-width: 5" \/>/,
    qr/<circle cx="200" cy="500" r="10" style="fill: #36f; stroke: #135; stroke-width: 8" \/>/,
    qr/<polyline points="400,100 300,200 400,400 200,500" style="fill: none; stroke: rgb\( 30,  60, 255\); stroke-width: 2px" \/>/,
	  qr/<line style="stroke: rgb\(100, 200, 100\); stroke-dasharray: 5, 5; stroke-width: 5" x1="400" x2="400" y1="100" y2="400" \/>/,
]);
