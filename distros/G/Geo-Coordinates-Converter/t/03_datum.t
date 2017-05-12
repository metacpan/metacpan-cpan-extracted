use strict;
use Test::Base;

use Geo::Coordinates::Converter;

plan tests => 2 * blocks;

filters { point => 'yaml', lat => 'chomp', lng => 'chomp', datum => 'chomp' };

run {
    my $block = shift;
    my $geo = Geo::Coordinates::Converter->new(%{ $block->point });

    $geo->datum($block->datum);
    is $geo->$_, $block->$_ for (qw/ lat lng /);
}

__END__

===
--- point
lat: 35.20.51.664
lng: 138.34.56.905
datum: tokyo
--- lat: 35.21.03.342
--- lng: 138.34.45.725
--- datum: wgs84

===
--- point
lat: 35.20.39.984328
lng: 138.35.08.086122
datum: tokyo
--- lat: 35.20.51.664
--- lng: 138.34.56.905
--- datum: wgs84

===
--- point
lat: 35.20.51.664
lng: 138.34.56.905
datum: wgs84
--- lat: 35.20.39.985
--- lng: 138.35.08.086
--- datum: tokyo

===
--- point
lat: 35.39.36.145
lng: 139.39.58.871
datum: wgs84
--- lat: 35.39.24.490
--- lng: 139.40.10.429
--- datum: tokyo

===
--- point
lat: 35.656667
lng: 139.670848
datum: wgs84
--- lat: 35.653429
--- lng: 139.674059
--- datum: tokyo
