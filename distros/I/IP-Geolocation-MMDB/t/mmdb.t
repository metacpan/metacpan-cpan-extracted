#!perl

# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later

use 5.016;
use warnings;
use utf8;

use Test::More tests => 23;

use File::Spec::Functions qw(catfile);
use IP::Geolocation::MMDB;

ok !eval { IP::Geolocation::MMDB->new },
  'constructor without "file" parameter dies';

ok !eval { IP::Geolocation::MMDB->new(file => 'nonexistent') },
  'constructor with non-existing file dies';

my $file = catfile(qw(t data Test-GeoLite2-City.mmdb));

my $mmdb = new_ok 'IP::Geolocation::MMDB' => [file => $file];

can_ok $mmdb, qw(getcc record_for_address version);

isnt $mmdb->version, q{}, 'library version is not empty';

ok !eval { $mmdb->record_for_address('-1') },
  'invalid ip address throws exception';

ok !$mmdb->record_for_address('127.0.0.1'), 'no data for localhost';

my $r = $mmdb->record_for_address('176.9.54.163');
isa_ok $r, 'HASH';
is_deeply $r->{x_array}, [-1, 0, 1], 'array matches';
is_deeply $r->{x_map}, {red => 160, green => 32, blue => 240}, 'map matches';
ok $r->{x_boolean}, 'boolean is true';
is $r->{x_bytes}, pack('W*', ord 'A' .. ord 'Z'), 'bytes match';
cmp_ok $r->{x_double}, '>', 0.0, 'double is greater than zero';
cmp_ok $r->{x_float},  '<', 0.0, 'float is less than zero';
is $r->{x_int32},       -2147483648,          'int32 matches';
is $r->{x_uint16},      65535,                'uint16 matches';
is $r->{x_uint32},      4294967295,           'uint32 matches';
is $r->{x_uint64},      18446744073709551615, 'uint64 matches';
is $r->{x_utf8_string}, 'Фалькенштайн',       'utf8_string matches';
ok defined $r->{x_uint128}, 'uint128 is defined';

is $mmdb->getcc('176.9.54.163'), 'DE', 'IPv4 address is in Germany';

SKIP:
{
  skip 'IPv6 tests on Windows', 2 if $^O eq 'MSWin32';

  isa_ok $mmdb->record_for_address('2a01:4f8:150:74ab::2'), 'HASH';
  is $mmdb->getcc('2a01:4f8:150:74ab::2'), 'DE', 'IPv6 address is in Germany';
}
