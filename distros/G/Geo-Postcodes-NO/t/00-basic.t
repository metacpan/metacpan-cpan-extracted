use strict;
use warnings;
use utf8;

use Test::More;
use Digest::SHA qw(sha256_hex);

use Geo::Postcodes::NO;

ok(Geo::Postcodes::NO::legal('0010'), 'four digits are legal');
ok(Geo::Postcodes::NO::valid('0010'), '0010 is in use');
ok(Geo::Postcodes::NO::valid('1178'), '1178 is in use');
ok(!Geo::Postcodes::NO::legal('10'), 'short postcode is not legal');
ok(!Geo::Postcodes::NO::legal('abcd'), 'letters are not legal');
ok(!Geo::Postcodes::NO::valid('0000'), '0000 is not in use');
ok(!Geo::Postcodes::NO::valid('9999'), '9999 is not in use');

is(Geo::Postcodes::NO::location_of('1178'), 'OSLO', 'postcode to location');
is(Geo::Postcodes::NO::borough_number_of('1178'), '0301', 'postcode to borough number');
is(Geo::Postcodes::NO::borough_of('1178'), 'OSLO', 'postcode to borough');
is(Geo::Postcodes::NO::county_of('1178'), 'OSLO', 'postcode to county');
is(Geo::Postcodes::NO::type_of('1178'), 'ST', 'Bring G maps to legacy ST');
is(Geo::Postcodes::NO::type_verbose_of('1178'), 'Gateadresse', 'Norwegian type description');

is(Geo::Postcodes::NO::borough_number_of('2542'), '3426', 'current municipality number');
is(Geo::Postcodes::NO::borough_of('2542'), 'TOLGA', 'current municipality name');
is(Geo::Postcodes::NO::county_of('2542'), 'INNLANDET', 'current county name');

is(Geo::Postcodes::NO::borough_of('1300'), 'BÆRUM', 'UTF-8 borough names are preserved');
is(Geo::Postcodes::NO::county_of('1300'), 'AKERSHUS', '2024 county structure is used');

is(Geo::Postcodes::NO::type_of('0010'), 'STBX', 'Bring B maps to legacy STBX');
is(Geo::Postcodes::NO::type_verbose_of('0010'), 'Både gateadresse og postboks', 'UTF-8 type description');
is(Geo::Postcodes::NO::type_of('0018'), 'SX', 'Bring S maps to legacy SX');
is(Geo::Postcodes::NO::bring_category_of('0018'), 'S', 'raw Bring category remains available');

like(Geo::Postcodes::NO::data_file(), qr/postnummerregister-ansi\.txt\z/, 'local data file path');
ok(-f Geo::Postcodes::NO::data_file(), 'local data file exists');
is(Geo::Postcodes::NO::data_valid_from(), '2026-10-01', 'bundled data validity date');

{
    open my $fh, '<:raw', Geo::Postcodes::NO::data_file() or die "cannot read data file: $!";
    local $/;
    my $data = <$fh>;
    close $fh;
    is(sha256_hex($data), '118ab7e9a3532dad00cf9a0f434bc11dfb0d1574c25ac3ce280bb8ce7ff60a42', 'bundled data file sha256');
}

my $postcode = Geo::Postcodes::NO->new('1178');
isa_ok($postcode, 'Geo::Postcodes::NO');
is($postcode->postcode, '1178', 'object postcode');
is($postcode->location, 'OSLO', 'object location');
is($postcode->borough_number, '0301', 'object borough number');
is($postcode->borough, 'OSLO', 'object borough');
is($postcode->county, 'OSLO', 'object county');
is($postcode->type, 'ST', 'object type');
is($postcode->type_verbose, 'Gateadresse', 'object Norwegian type');
is(Geo::Postcodes::NO::type2verbose_english($postcode->type), 'Street address', 'English type description remains available');

is(Geo::Postcodes::NO->new('9999'), undef, 'unknown postcode returns undef');

done_testing;
