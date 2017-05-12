package Geo::Coordinates::Converter::Datum::Tokyo;
use strict;
use warnings;
use parent 'Geo::Coordinates::Converter::Datum';

sub name { 'tokyo' }
sub radius { 6377397.155 }
sub rate {
    my $r = 1 / 299.152813;
    2 * $r - $r * $r;
}
sub translation { +{ x => 148, y => -507, z => -681 } }

1;

__END__

not Tokyo97
