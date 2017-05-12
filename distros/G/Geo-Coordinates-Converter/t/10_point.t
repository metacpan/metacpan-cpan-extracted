use strict;
use Test::Base;

use Geo::Coordinates::Converter::Point;

plan tests => 12 * blocks;

filters { point => 'yaml' };

sub point_test {
    my($geo, $point) = @_;
    is $geo->$_, $point->{$_} for (qw/ lat lng datum format /);
    is $geo->latitude,  $point->{lat};
    is $geo->longitude, $point->{lng};
}

run {
    my $block = shift;
    my $point = Geo::Coordinates::Converter::Point->new( $block->point );
    point_test $point, $block->point;
    point_test $point->clone, $block->point;
}


__END__

===
--- point
lat: 35.65580
lng: 139.65580
datum: wgs84
format: degree

===
--- point
lat: 35.39.24.00
lng: 139.40.15.05
datum: wgs84
format: dms
