use strict;
use Test::Base;

use Geo::Coordinates::Converter;

plan tests => 2 * blocks;

filters { point => 'yaml', convert => 'yaml', lat => 'chomp', lng => 'chomp', format => 'chomp' };

run {
    my $block = shift;
    my $geo = Geo::Coordinates::Converter->new(%{ $block->point });

    my $point = $geo->convert(@{ $block->convert });
    is $point->$_, $block->$_ for (qw/ lat lng /);
}

__END__

===
--- point
lat: 35.20.51.664
lng: 138.34.56.905
datum: tokyo
--- convert
- wgs84
--- lat: 35.21.03.342
--- lng: 138.34.45.725

===
--- point
lat: +35.65580
lng: +139.65580
--- convert
- tokyo
- dms
--- lat: 35.39.09.225
--- lng: 139.39.32.434

===
--- point
lat: -35.20.51.664
lng: 138.34.56.905
--- convert
- dms
--- lat: -35.20.51.664
--- lng: 138.34.56.905

===
--- point
lat: 35.65580
lng: -139.65580
--- convert
- wgs84
- dms
--- lat: 35.39.20.880
--- lng: -139.39.20.880

===
--- point
lat: 35.20.51.664
lng: 138.34.56.905
--- convert
- degree
--- lat: 35.347684
--- lng: 138.582474

===
--- point
lat: -35.20.51.664
lng: 138.34.56.905
--- convert
- degree
--- lat: -35.347684
--- lng: 138.582474

===
--- point
lat: 35.20.51.664
lng: -138.34.56.905
--- convert
- degree
--- lat: 35.347684
--- lng: -138.582474

===
--- point
lat: -35.20.51.664
lng: -138.34.56.905
--- convert
- degree
--- lat: -35.347684
--- lng: -138.582474

===
--- point
lat: 35.20.51.664
lng: -138.34.56.905
--- convert
- dms
--- lat: 35.20.51.664
--- lng: -138.34.56.905
