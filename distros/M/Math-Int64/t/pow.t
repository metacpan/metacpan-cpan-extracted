#!/usr/bin/perl

use strict;
use warnings;

use Math::Int64 qw(int64 uint64 string_to_int64 string_to_uint64);

use Test::More 0.88;

my $zero = int64(0);
my $one = int64(1);
my $two = int64(2);
my $mone = int64(-1);
my $mtwo = int64(-2);

ok($zero ** 0 == 1);
ok($zero ** 1 == 0);
ok($zero ** 10 == 0);
eval { my $r = $zero ** -1 };
ok($@ =~ /illegal.*division/i);

ok($one ** 0 == 1);
ok($one ** 10 == 1);
ok($one ** -19 == 1);

ok($mone ** 0 == 1);
ok($mone ** 10 == 1);
ok($mone ** 11 == -1);
ok($mone ** -1 == -1);
ok($mone ** -30 == 1);
ok($mone ** -31 == -1);

ok($two ** 0 == 1);
ok($two ** 1 == 2);
ok($two ** 2 == 4);
ok($two ** 31 == string_to_int64("0x8000_0000"));
ok($two ** 32 == string_to_int64("0x1_0000_0000"));
ok($two ** 62 == string_to_int64("0x4000_0000_0000_0000"));
ok($two ** -1 == 0);

ok($mtwo ** 0 == 1);
ok($mtwo ** 1 == -2);
ok($mtwo ** 2 == 4);
ok($mtwo ** 3 == -8);
ok($mtwo ** 4 == 16);
ok($mtwo ** 31 == -string_to_int64("0x8000_0000"));
ok($mtwo ** 32 == string_to_int64("0x1_0000_0000"));
ok($mtwo ** 62 == string_to_int64("0x4000_0000_0000_0000"));
ok($mtwo ** -1 == 0);

ok(int64(12) ** 2 == 144);
ok(int64(-12) ** 2 == 144);
ok(int64(12) ** 3 == 1728);
ok(int64(-12) ** 3 == -1728);
ok(int64(256) ** 5 == 2 ** (8 * 5));
ok(int64(-256) ** 5 == -(2 ** (8 * 5)));
ok(int64(256) ** -5 == 0);

$zero = uint64(0);
$one = uint64(1);
$two = uint64(2);

ok($zero ** 0 == 1);
ok($zero ** 1 == 0);
ok($zero ** 10 == 0);

ok($one ** 0 == 1);
ok($one ** 10 == 1);

ok($two ** 0 == 1);
ok($two ** 1 == 2);
ok($two ** 2 == 4);
ok($two ** 31 == string_to_uint64("0x8000_0000"));
ok($two ** 32 == string_to_uint64("0x1_0000_0000"));
ok($two ** 62 == string_to_uint64("0x4000_0000_0000_0000"));
ok($two ** 63 == string_to_uint64("0x8000_0000_0000_0000"));

ok(int64(12) ** 2 == 144);
ok(int64(12) ** 3 == 1728);
ok(int64(256) ** 5 == 2 ** (8 * 5));

done_testing();
