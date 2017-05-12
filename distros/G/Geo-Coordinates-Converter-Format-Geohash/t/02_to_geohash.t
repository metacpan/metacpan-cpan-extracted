use strict;
use warnings;
use Test::Base;

use Geo::Coordinates::Converter;
use Geo::Coordinates::Converter::Point::Geohash;

Geo::Coordinates::Converter->add_default_formats('Geohash');

plan tests => 4 * blocks;

filters { geohash => 'chomp', lat => 'chomp', lng => 'chomp', format => 'chomp' };

run {
    my $block = shift;
    my $geo = Geo::Coordinates::Converter->new(
        lat => $block->lat, lng => $block->lng,
    );

    $geo->format('geohash');
    isa_ok($geo->point, 'Geo::Coordinates::Converter::Point::Geohash');
    my $geohash = $block->geohash;
    like( $geo->point->geohash, qr/^$geohash/ );
    is $geo->lat, undef;
    is $geo->lng, undef;
};

__END__

===
--- geohash: xn76gg7zzzzzx70v19vp
--- lat: 35.39.31.948
--- lng: 139.44.26.162

===
--- geohash: xn76ggs00006
--- lat: 35.658875
--- lng: 139.740601
