# Toby Thurston -- 19 Feb 2016 

# test boundary conditions

use Geo::Coordinates::OSGB qw/ll_to_grid grid_to_ll set_default_shape/;
use Geo::Coordinates::OSGB::Grid qw/parse_grid format_grid format_grid_GPS/;

use Test::More tests => 16;

# The point of this test is to check running off the edge of the OSTN02 rectangle

my @edge = (49.76705, -7.5569);
my $result = sprintf "%.7g %.5g", @edge;

#printf "@edge %s %s\n", grid_to_ll(79020,20);
is( sprintf( "%.7g %.5g", grid_to_ll(21,26)), $result , "Edge one $result");
is( ll_to_grid(@edge), "21 26", "Edge one");


is( ll_to_grid(grid_to_ll(449960,567710)), "449960.000 567710.000", "off South Shields");
is( ll_to_grid(grid_to_ll(77360,895710)),  "77360.001 895709.999", "near Uist");
is( ll_to_grid(grid_to_ll(109865,764128)), "109865.000 764128.000", "near Coll");
is( ll_to_grid(grid_to_ll(109165,763888)), "109165.000 763888.000", "near Coll");
is( ll_to_grid(grid_to_ll(458020,1217306)), "458020.000 1217306.000", "near Yell");
is( ll_to_grid(grid_to_ll(449611,1215083)), "449611.000 1215083.000", "near Yell");
is( ll_to_grid(grid_to_ll(456720,1210574)), "456720.000 1210574.000", "near Yell");
is( ll_to_grid(grid_to_ll(452979,1203121)), "452979.000 1203121.000", "near Yell");
is( ll_to_grid(grid_to_ll(447086,1203452)), "447086.000 1203452.000", "near Yell");
is( ll_to_grid(grid_to_ll(382514,682908)), "382514.000 682908.000", "off Scarborough");
is( ll_to_grid(grid_to_ll(377516,684564)), "377516.000 684564.000", "off Scarborough");
is( ll_to_grid(grid_to_ll(363754,724465)), "363754.000 724465.000", "off Scarborough");
is( ll_to_grid(grid_to_ll(parse_grid('SW 540 170'))), "154000.000 17000.000", "in SW");
is( ll_to_grid(grid_to_ll(parse_grid('SW 910 150'))), "191000.000 15000.000", "in SW");

