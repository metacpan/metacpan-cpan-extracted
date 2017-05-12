package Geo::Coordinates::Converter::Datum::Grs80;
use strict;
use warnings;
use parent 'Geo::Coordinates::Converter::Datum';

sub name { 'grs80' }
sub radius { 6378137 }
sub rate {
    my $r = 1 / 298.257222101;
    2 * $r - $r * $r;
}

1;
