use strict;
use warnings;
use Geo::Coordinates::OSGB::Grid qw{parse_grid format_grid};
print scalar format_grid(parse_grid("@ARGV"), { maps => 1 }), "\n";
