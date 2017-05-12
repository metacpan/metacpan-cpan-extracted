use strict;
use warnings;
use Test::More tests => 14;
use Geo::Coordinates::Converter;

# 200 area ok
sub {
    my $geo = Geo::Coordinates::Converter->new(formats => [qw/ iArea /], format => 'iarea', areacode => '05905');
    isa_ok $geo, 'Geo::Coordinates::Converter';

    my $point = $geo->convert('degree' => 'wgs84');
    isa_ok $point, 'Geo::Coordinates::Converter::Point';
    is $point->lat, '35.647771';
    is $point->lng, '139.719441';
    is $point->datum, 'wgs84';
    is $point->format, 'degree';
    is $point->areacode, '05905';

    is $geo->lat, '35.647771';
    is $geo->lng, '139.719441';
    is $geo->datum, 'wgs84';
    is $geo->format, 'degree';
    is $geo->areacode, '05905';
}->();

# 404 area not found
sub {
    my $geo2 = Geo::Coordinates::Converter->new(formats => [qw/ iArea /], areacode => '99999');
    is $geo2->lat, '0.000000';
    is $geo2->lng, '0.000000';
}->();

