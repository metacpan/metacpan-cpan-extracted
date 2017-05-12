use strict;
use Test::Base;

use Geo::Coordinates::Converter;

plan tests => 2 * blocks;

filters { point => 'yaml', lat => 'chomp', lng => 'chomp', format => 'chomp' };

run {
    my $block = shift;
    my $geo = Geo::Coordinates::Converter->new(%{ $block->point });

    $geo->format($block->format);
    is $geo->$_, $block->$_ for (qw/ lat lng /);
}

__END__

===
--- point
lat: 35.39.24.00
lng: 139.40.15.054
--- lat: 35.39.24.000
--- lng: 139.40.15.054

===
--- point
lat: 35.39.24.00
lng: 139.40.15.054
--- lat: 35.656667
--- lng: 139.670848
--- format: degree

===
--- point
lat: 35.34.24.218
lng: 139.37.09.379
--- lat: 35.573394
--- lng: 139.619272
--- format: degree

===
--- point
lat: -35.34.24.218
lng: -139.37.09.379
--- lat: -35.573394
--- lng: -139.619272
--- format: degree


===
--- point
lat: 35.573394
lng: 139.619272
--- lat: 35.34.24.218
--- lng: 139.37.09.379
--- format: dms

===
--- point
lat: -35.573394
lng: -139.619272
--- lat: -35.34.24.218
--- lng: -139.37.09.379
--- format: dms

===
--- point
lat: N35.573394
lng: W139.619272
--- lat: 35.34.24.218
--- lng: -139.37.09.379
--- format: dms

===
--- point
lat: n35.573394
lng: w139.619272
--- lat: 35.34.24.218
--- lng: -139.37.09.379
--- format: dms

===
--- point
lat: S35.573394
lng: E139.619272
--- lat: -35.34.24.218
--- lng: 139.37.09.379
--- format: dms

===
--- point
lat: s35.573394
lng: e139.619272
--- lat: -35.34.24.218
--- lng: 139.37.09.379
--- format: dms

===
--- point
lat: N35.34.24.218
lng: E139.37.09.379
--- lat: 35.573394
--- lng: 139.619272
--- format: degree

===
--- point
lat: N35.34.24.218
lng: W139.37.09.379
--- lat: 35.573394
--- lng: -139.619272
--- format: degree

===
--- point
lat: S35.34.24.218
lng: E139.37.09.379
--- lat: -35.573394
--- lng: 139.619272
--- format: degree

===
--- point
lat: n35.34.24.218
lng: w139.37.09.379
--- lat: 35.573394
--- lng: -139.619272
--- format: degree

===
--- point
lat: s35.34.24.218
lng: e139.37.09.379
--- lat: -35.573394
--- lng: 139.619272
--- format: degree

===
--- point
lat: s35.4.4.218
lng: e139.7.9.379
--- lat: -35.04.04.218
--- lng: 139.07.09.379

===
--- point
lat: -35.573394
lng: 139.619272
--- lat: -128064218
--- lng: 502629380
--- format: milliseconds

===
--- point
lat: -128064218
lng: 502629380
--- lat: -35.573394
--- lng: 139.619272
--- format: degree
