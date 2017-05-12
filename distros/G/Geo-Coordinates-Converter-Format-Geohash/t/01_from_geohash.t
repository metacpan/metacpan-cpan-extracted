use strict;
use warnings;
use Test::Base;

use Geo::Coordinates::Converter;
use Geo::Coordinates::Converter::Point::Geohash;

Geo::Coordinates::Converter->add_default_formats('Geohash');

plan tests => 2 * blocks;

filters { geohash => 'chomp', lat => 'chomp', lng => 'chomp', format => 'chomp' };

run {
    my $block = shift;
    my $geo = Geo::Coordinates::Converter->new(
        point => Geo::Coordinates::Converter::Point::Geohash->new({
            geohash => $block->geohash,
        }),
    );

    $geo->format($block->format);
    is $geo->lat, $block->lat;
    is $geo->lng, $block->lng;
};

__END__

===
--- geohash: xn76gg
--- format: dms
--- lat: 35.39.31.948
--- lng: 139.44.26.162

===
--- geohash: xn76gg
--- format: degree
--- lat: 35.658875
--- lng: 139.740601
