use strict;
use Test::More;

use Geo::Hex::V3::XS;

isa_ok(Geo::Hex::V3::XS->new(code => "XE1234"), 'Geo::Hex::V3::XS');
isa_ok(Geo::Hex::V3::XS->new(lat => 40.5814792855475, lng => 134.296601127877, level => 7), 'Geo::Hex::V3::XS');
isa_ok(Geo::Hex::V3::XS->new(x => 11554, y => -3131, level => 7), 'Geo::Hex::V3::XS');

is(Geo::Hex::V3::XS->new(x => 11254, y => -4025, level => 7)->code, 'XM4885168');

done_testing;

