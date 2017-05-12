package Geo::Coordinates::Converter::Datum::Wgs72;
use strict;
use warnings;
use parent 'Geo::Coordinates::Converter::Datum';

sub name { 'wgs72' }
sub radius { 6378135 }
sub rate { 0.006694318 }

1;
