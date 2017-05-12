use strict;
use warnings;

use Geo::GoogleMaps::OffsetCenter qw/ offset_center_by_pixel /;

use Data::Printer;
use Test::Simple tests => 1;

my $result = offset_center_by_pixel(
    52.5100134,
    13.3796214,
    802,
    480,
    522,
    240,
    14
);

ok( $result->{latitude} == 52.510013 && $result->{longitude} == 13.369236 );

1;
