use strict;
use Test::Base;

use Geo::Coordinates::Converter;

plan tests => 3 * blocks;

filters { point => 'yaml', lat => 'chomp', lng => 'chomp', format => 'chomp' };

run {
    my $block = shift;
    my $geo = Geo::Coordinates::Converter->new(%{ $block->point });

    is $geo->$_, $block->$_ for (qw/ lat lng format /);
}

__END__

===
--- point
lat: 35.65580
lng: 139.65580
--- lat: 35.655800
--- lng: 139.655800
--- format: degree

===
--- point
lat: +35.65580
lng: +139.65580
--- lat: 35.655800
--- lng: 139.655800
--- format: degree

===
--- point
lat: 35.65580
lng: -139.65580
--- lat: 35.655800
--- lng: -139.655800
--- format: degree

===
--- point
lat: +35.65580
lng: -139.65580
--- lat: 35.655800
--- lng: -139.655800
--- format: degree

===
--- point
lat: -35.65580
lng: 139.65580
--- lat: -35.655800
--- lng: 139.655800
--- format: degree

===
--- point
lat: -35.65580
lng: +139.65580
--- lat: -35.655800
--- lng: 139.655800
--- format: degree

===
--- point
lat: -35.65580
lng: -139.65580
--- lat: -35.655800
--- lng: -139.655800
--- format: degree

===
--- point
lat: 35.39.24.000
lng: 139.40.15.050
--- lat: 35.39.24.000
--- lng: 139.40.15.050
--- format: dms

===
--- point
lat: +35.39.24.000
lng: +139.40.15.050
--- lat: 35.39.24.000
--- lng: 139.40.15.050
--- format: dms

===
--- point
lat: 35.39.24.000
lng: -139.40.15.050
--- lat: 35.39.24.000
--- lng: -139.40.15.050
--- format: dms

===
--- point
lat: +35.39.24.000
lng: -139.40.15.050
--- lat: 35.39.24.000
--- lng: -139.40.15.050
--- format: dms

===
--- point
lat: -35.39.24.000
lng: 139.40.15.050
--- lat: -35.39.24.000
--- lng: 139.40.15.050
--- format: dms

===
--- point
lat: -35.39.24.000
lng: +139.40.15.050
--- lat: -35.39.24.000
--- lng: 139.40.15.050
--- format: dms

===
--- point
lat: -35.39.24.000
lng: -139.40.15.050
--- lat: -35.39.24.000
--- lng: -139.40.15.050
--- format: dms

===
--- point
latitude: 35.65580
longitude: 139.65580
--- lat: 35.655800
--- lng: 139.655800
--- format: degree
