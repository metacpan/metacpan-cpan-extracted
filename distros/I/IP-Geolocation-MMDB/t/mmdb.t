#!perl

# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later

use 5.016;
use warnings;
use utf8;

use Test::More;

use File::Spec::Functions qw(catfile);
use IP::Geolocation::MMDB;
use Math::BigInt 1.999806;

my $version = IP::Geolocation::MMDB::libmaxminddb_version;

my $expected_version = eval {
    require Alien::libmaxminddb;
    Alien::libmaxminddb->version;
};

# Check if the module was linked against the wrong library version.
if (defined $expected_version && $version ne $expected_version) {
    plan skip_all => "Error: wrong libmaxminddb version, got $version, "
        . "expected $expected_version";
}

diag 'libmaxminddb version is ' . $version;

ok !eval { IP::Geolocation::MMDB->new },
    'constructor without "file" parameter dies';

ok !eval { IP::Geolocation::MMDB->new(file => 'nonexistent') },
    'constructor with non-existing file dies';

my $file = catfile(qw(t data Test-City.mmdb));

# Ensure that the module is subclassable by using an empty subclass.
@MaxMind::DB::Reader::ISA = qw(IP::Geolocation::MMDB);

my $reader = new_ok 'MaxMind::DB::Reader' => [file => $file];

can_ok $reader,
    qw(get getcc record_for_address iterate_search_tree metadata file);

is $reader->file, $file, 'file matches';

ok !eval { $reader->get('-1') }, 'invalid ip address throws exception';

ok !$reader->record_for_address('127.0.0.1'), 'no data for localhost';

my $uint64  = Math::BigInt->new('4702394921427289928');
my $uint128 = Math::BigInt->new('86743875649080753100636639643044826960');

my $r = $reader->get('176.9.54.163');
isa_ok $r, 'HASH';
is $reader->getcc('176.9.54.163'), 'DE', 'IPv4 address is in Germany';

my ($s, $prefix_length) = $reader->get('176.9.54.163');
is_deeply $r, $s, 'data matches';
cmp_ok $prefix_length, '==', 16, 'IPv4 prefix length is 16';

SKIP:
{
    skip 'IPv6 tests on Windows', 3 if $^O eq 'MSWin32';

    isa_ok $reader->record_for_address('2a01:4f8:150:74ab::2'), 'HASH';
    is $reader->getcc('2a01:4f8:150:74ab::2'), 'DE',
        'IPv6 address is in Germany';

    my (undef, $prefix_length) = $reader->get('2a01:4f8:150:74ab::2');
    cmp_ok $prefix_length, '==', 32, 'IPv6 prefix length is 32';
}

is_deeply $r->{x_array}, [-1, 0, 1], 'array matches';
is_deeply $r->{x_map}, {red => 160, green => 32, blue => 240}, 'map matches';
ok $r->{x_boolean}, 'boolean is true';
is $r->{x_bytes}, pack('W*', ord 'A' .. ord 'Z'), 'bytes match';
cmp_ok $r->{x_double}, '>', 0.0, 'double is greater than zero';
cmp_ok $r->{x_float},  '<', 0.0, 'float is less than zero';
is $r->{x_int32},       -12500413,      'int32 matches';
is $r->{x_uint16},      16706,          'uint16 matches';
is $r->{x_uint32},      1094861636,     'uint32 matches';
is $r->{x_uint64},      $uint64,        'uint64 matches';
is $r->{x_uint128},     $uint128,       'uint128 matches';
is $r->{x_utf8_string}, 'Фалькенштайн', 'utf8_string matches';

my $m = $reader->metadata;
can_ok $m, qw(
    binary_format_major_version binary_format_minor_version build_epoch
    database_type languages description ip_version node_count record_size
);
cmp_ok $m->binary_format_major_version, '>=', 0, 'major version is set';
cmp_ok $m->binary_format_minor_version, '>=', 0, 'minor version is set';
cmp_ok $m->build_epoch,                 '>=', 0, 'build_epoch is set';
isnt $m->database_type, q{}, 'database type is not empty';
isa_ok $m->languages,   'ARRAY';
isa_ok $m->description, 'HASH';
cmp_ok $m->ip_version,  '>=', 0, 'ip_version is set';
cmp_ok $m->node_count,  '>=', 0, 'node_count is set';
cmp_ok $m->record_size, '>=', 0, 'record_size is set';

my %data_for;

sub data_callback {
    my ($numeric_ip, $prefix_length, $data) = @_;

    my $address = $numeric_ip->as_hex . '/' . $prefix_length;
    $data_for{$address} = $data;

    return;
}

my %children_for;

sub node_callback {
    my ($node_number, $left_node_number, $right_node_number) = @_;

    $children_for{$node_number} = [$left_node_number, $right_node_number];

    return;
}

$reader->iterate_search_tree(\&data_callback, \&node_callback);

cmp_ok scalar keys %data_for,     '>', 0, 'data_callback was called';
cmp_ok scalar keys %children_for, '>', 0, 'node_callback was called';
ok exists $children_for{0}, 'node 0 exists';
isnt $children_for{0}->[0], $children_for{0}->[1], 'children differ';

my $ipv4_data = $data_for{'0xffffb0090000/112'};
my $ipv6_data = $data_for{'0x2a0104f8000000000000000000000000/32'};
ok defined $ipv4_data,           'IPv4 data exists';
ok defined $ipv6_data,           'IPv6 data exists';
ok exists $ipv4_data->{city},    'city key exists';
ok exists $ipv6_data->{country}, 'country key exists';

done_testing;
