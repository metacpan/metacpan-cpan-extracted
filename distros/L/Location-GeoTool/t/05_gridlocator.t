use strict;
use Test::More tests => 5;

use Location::GeoTool qw/GridLocator/;

my @Tests = (
    [ '000000.000', '1394437.000', 'PJ90UA' ],
    [ '-354345.000', '-1394437.000', 'CF04DG' ],
    [ '354345.000', '-1394437.000', 'CM05DR', ],
    [ '-354345.000', '1394437.000', 'PF94UG' ],
    [ '354345.000', '1394437.000', 'PM95UR' ]
);

for (@Tests) {
  my($lat, $long, $gl) = @$_;
  my $geo = Location::GeoTool->create_coord($lat, $long, "wgs84", "dmsn");
  is $geo->get_gridlocator, $gl;
}

__END__
