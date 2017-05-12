use strict;
use Test::More;

use Geo::Hex::V3::XS;

subtest code => sub {
    my $geohex = Geo::Hex::V3::XS->new(code => 'OL3371');
    is $geohex->level, 4;
    like $geohex->size, qr/^9162\.098006/;
    is $geohex->code, 'OL3371';
    like $geohex->lat, qr/^-45\.377703/;
    like $geohex->lng, qr/^49\.382716/;
    is $geohex->x, -79;
    is $geohex->y, -279;
};

subtest latlng => sub {
    my $geohex = Geo::Hex::V3::XS->new(lat => 40.5814792855475, lng => 134.296601127877, level => 7);
    is $geohex->level, 7;
    like $geohex->size, qr/^339\.336963/;
    is $geohex->code, 'XU6312418';
    like $geohex->lat, qr/^40\.580142/;
    like $geohex->lng, qr/^134\.293552/;
    is $geohex->x, 11554;
    is $geohex->y, -3131;
};

done_testing;

