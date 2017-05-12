package Geo::Coordinates::Converter::Datum::Wgs84;
use strict;
use warnings;
use parent 'Geo::Coordinates::Converter::Datum';

sub name { 'wgs84' }
sub radius { 6378137 }
sub rate {
    my $r = 1 / 298.257223563;
    2 * $r - $r * $r;
}

1;
