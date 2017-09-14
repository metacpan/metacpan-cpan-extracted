use strict;
use warnings;
use Test::More tests => 6;
use Test::File;

use Geo::OSM::Render::Renderer::SVG;

use Geo::Coordinates::Converter::LV03 qw(lat_lng_2_y_x);
use Geo::OSM::Render::Projection::CH_LV03;
use Geo::OSM::Render::Viewport::Clipped;

my $svg_filename = 't/002-svg-new-max_width_height.svg';
my $osm_proj_ch    = Geo::OSM::Render::Projection::CH_LV03->new();

unlink $svg_filename if -f $svg_filename;
ok(! -f $svg_filename, "$svg_filename does not exist");

# 
#                          # ------------  According to https://en.wikipedia.org/wiki/List_of_extreme_points_of_Switzerland:
#                          #
my $lat_min =  45.817995 ; # Southernmost  45.818031 /  9.016483 - 722640 /  75275
my $lon_min =   5.9559113; # Westernmost   46.132242 /  5.956303 - 485441 / 110057
my $lat_max =  47.8084648; # Northernmost  47.808264 /  8.567897 - 684592 / 295912
my $lon_max =  10.4922941; # Eeastermost   46.612778 / 10.491944 - 833841 / 166942
#                          # -----------------------------------------------------------------------------------------------

my ($x_min, $y_min) = lat_lng_2_y_x($lat_min, $lon_min);
my ($x_max, $y_max) = lat_lng_2_y_x($lat_max, $lon_max);


# printf ("
#    x: %7.3f - %7.3f
#    y: %7.3f - %7.3f
# ", $x_min / 1000, $x_max / 1000, $y_min / 1000, $y_max / 1000);

my $osm_vp_cl      = Geo::OSM::Render::Viewport::Clipped  ->new(
   x_of_map_0       => $x_min, # 484.750
   x_of_map_width   => $x_max, # 828.693
   y_of_map_0       => $y_max, # 299.778
   y_of_map_height  => $y_min, #  75.129
   max_width_height => 750
);

my $osm_renderer_svg = Geo::OSM::Render::Renderer::SVG->new(
  $svg_filename,
  $osm_vp_cl,
  $osm_proj_ch
);


is(       $osm_vp_cl->map_width ()           , 750, 'calculated width' );
is( int ( $osm_vp_cl->map_height() / 10) * 10, 480, 'calculated height');

$osm_renderer_svg->end();

ok(-f $svg_filename, "$svg_filename was produced");

file_contains_utf8_like($svg_filename, [
    qr/<svg .*height="489.86/,
    qr/<svg .*width="750"/
]);

