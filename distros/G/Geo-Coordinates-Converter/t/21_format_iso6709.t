use strict;
use warnings;
use Test::Base;

use Geo::Coordinates::Converter;
use Geo::Coordinates::Converter::Point::ISO6709;

plan tests => 4 * blocks;

filters { data => 'chomp', lat => 'chomp', lng => 'chomp', height => 'chomp', to => 'chomp' };

run {
    my $block = shift;
    if ($block->to) {
        my $geo = Geo::Coordinates::Converter->new(
            point => Geo::Coordinates::Converter::Point::ISO6709->new({
                iso6709 => $block->iso6709,
            }),
        );
        $geo->format($block->to);

        is $geo->lat, $block->lat;
        is $geo->lng, $block->lng;
        is $geo->height, $block->height;
        is $geo->datum, 'wgs84';
    } else {
        my $geo = Geo::Coordinates::Converter->new(
            lat => $block->lat, lng => $block->lng, height => $block->height,
        );

        $geo->format('iso6709');
        isa_ok($geo->point, 'Geo::Coordinates::Converter::Point::ISO6709');
        is $geo->point->iso6709, $block->iso6709;
        is $geo->lat, undef;
        is $geo->lng, undef;
    }
};

__END__

===
--- iso6709: +352139+1384339/
--- to: dms
--- lat: 35.21.39.000
--- lng: 138.43.39.000
--- height: 0

===
--- iso6709: +352139+1384339CRSWGS_84/
--- to: dms
--- lat: 35.21.39.000
--- lng: 138.43.39.000
--- height: 0

===
--- iso6709: +352139+1384339-10CRSWGS_84/
--- to: dms
--- lat: 35.21.39.000
--- lng: 138.43.39.000
--- height: -10

===
--- iso6709: -4012.22-07500.25/
--- to: dms
--- lat: -40.12.13.200
--- lng: -75.00.15.000
--- height: 0

===
--- iso6709: -4012.22-07500.25+10CRSWGS_84/
--- to: dms
--- lat: -40.12.13.200
--- lng: -75.00.15.000
--- height: 10

===
--- iso6709: -4012.22-07500.25-10CRSWGS_84/
--- to: dms
--- lat: -40.12.13.200
--- lng: -75.00.15.000
--- height: -10

===
--- iso6709: +35.36083+138.72750/
--- to: dms
--- lat: 35.21.38.988
--- lng: 138.43.39.000
--- height: 0

===
--- iso6709: +35.36083+138.72750+3776/
--- to: dms
--- lat: 35.21.38.988
--- lng: 138.43.39.000
--- height: 3776

===
--- iso6709: +35.36083+138.72750-3776/
--- to: dms
--- lat: 35.21.38.988
--- lng: 138.43.39.000
--- height: -3776

===
--- iso6709: -35.36083+138.72750-3776CRSWGS_84/
--- to: dms
--- lat: -35.21.38.988
--- lng: 138.43.39.000
--- height: -3776

===
--- iso6709: +352139+1384339/
--- to: degree
--- lat: 35.360833
--- lng: 138.727500
--- height: 0

===
--- iso6709: +35.2139+138.4339/
--- to: degree
--- lat: 35.213900
--- lng: 138.433900
--- height: 0

===
--- iso6709: +05.2139+008.4339/
--- to: degree
--- lat: 5.213900
--- lng: 8.433900
--- height: 0



===
--- iso6709: +352138.9999999998672+1384338.9999999999714/
--- lat: 35.21.39.000
--- lng: 138.43.39.000
--- height: 0

===
--- iso6709: +352138.9999999998672+1384338.9999999999714-10/
--- lat: 35.21.39.000
--- lng: 138.43.39.000
--- height: -10

===
--- iso6709: -401213.2000000001159-75015.0000000001398/
--- lat: -40.12.13.200
--- lng: -75.00.15.000
--- height: 0

===
--- iso6709: -401213.2000000001159-75015.0000000001398+10/
--- lat: -40.12.13.200
--- lng: -75.00.15.000
--- height: 10

===
--- iso6709: +35.360833+138.7275/
--- lat: 35.360833
--- lng: 138.727500
--- height: 0

===
--- iso6709: +35.2139-138.4339-123/
--- lat: 35.213900
--- lng: -138.433900
--- height: -123

===
--- iso6709: +05.2139+008.4339/
--- lat: 5.213900
--- lng: 8.433900
--- height: 0
