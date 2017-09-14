use warnings;
use strict;
use Test::More tests => 6;

use Geo::OSM::Render::Renderer;
use Geo::OSM::Render::Projection;
use Geo::OSM::Render::Projection::CH_LV03;
use Geo::OSM::Render::Projection::Ident;
use Geo::OSM::Render::Renderer::SVG;
use Geo::OSM::Render::Viewport;
use Geo::OSM::Render::Viewport::Clipped;
use Geo::OSM::Render::Viewport::UnClipped;

my $osm_proj_ch    = Geo::OSM::Render::Projection::CH_LV03->new();
my $osm_proj_id    = Geo::OSM::Render::Projection::Ident  ->new();
my $osm_render     = Geo::OSM::Render::Renderer           ->new();
my $osm_vp_uncl    = Geo::OSM::Render::Viewport::UnClipped->new();
my $osm_vp_cl      = Geo::OSM::Render::Viewport::Clipped  ->new(
   x_of_map_0       => 0,
   x_of_map_width   => 1,
   y_of_map_0       => 0,
   y_of_map_height  => 1,
   max_width_height => 1
);

my $osm_render_svg = Geo::OSM::Render::Renderer::SVG->new(
 't/001-load.svg',
  $osm_vp_cl,
  $osm_proj_id
);

isa_ok($osm_render    , 'Geo::OSM::Render::Renderer'           );
isa_ok($osm_proj_ch   , 'Geo::OSM::Render::Projection::CH_LV03');
isa_ok($osm_proj_id   , 'Geo::OSM::Render::Projection::Ident'  );
isa_ok($osm_render_svg, 'Geo::OSM::Render::Renderer::SVG'      );
isa_ok($osm_vp_uncl   , 'Geo::OSM::Render::Viewport::UnClipped');
isa_ok($osm_vp_cl     , 'Geo::OSM::Render::Viewport::Clipped'  );
