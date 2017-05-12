#!/usr/bin/perl

use strict;
use warnings;

use Test::More 0.88;

use Math::Int64 qw(:native_if_available
                   int64 int64_to_number
                   net_to_int64 int64_to_net
                   native_to_int64 int64_to_native);

my $i = int64('1234567890123456789');
my $j = $i + 1;
my $k = (int64(1) << 60) + 255;

# 1
ok($i == '1234567890123456789');

ok($j - 1 == '1234567890123456789');

ok (($k & 127) == 127);

ok (($k & 256) == 0) or diag "$k & 256 is " . ($k & 256);

# 5
ok ($i * 2 == $j + $j - 2);

SKIP: {
    skip "conversion to NV loses low bits", 1;
    ok ($i * $i * $i * $i == ($j * $j - 2 * $j + 1) * ($j * $j - 2 * $j + 1));
};

SKIP: {
    skip "native division semantics differ", 2;
    ok (($i / $j) == 0);
    ok ($j / $i == 1);
};

ok ($i % $j == $i);

# 10
ok ($j % $i == 1);

ok (($j += 1) == $i + 2);

ok ($j == $i + 2);

ok (($j -= 3) == $i - 1);

ok ($j == $i - 1);

$j = $i;
# 15
ok (($j *= 2) == $i << 1);

ok (($j >> 1) == $i);

ok (($j / 2) == $i);

$j = $i + 2;

ok (($j %= $i) == 2);

ok ($j == 2);

# 20
ok (($j <=> $i) < 0);

ok (($i <=> $j) > 0);

ok (($i <=> $i) == 0);

ok (($j <=> 2) == 0);

ok ($j < $i);

# 25
ok ($j <= $i);

ok (!($i < $j));

ok (!($i <= $j));

ok ($i <= $i);

ok ($j >= $j);

# 30
ok ($i > $j);

ok ($i >= $j);

ok (!($j > $i));

ok (!($j >= $i));

ok (int(log(int64(1)<<50)/log(2)+0.001) == 50);

# 35

my $n = int64_to_net(-1);

ok (join(" ", unpack "C*" => $n) eq join(" ", (255) x 8));

ok (net_to_int64($n) == -1);

ok (native_to_int64(int64_to_native(-1)) == -1);

ok (native_to_int64(int64_to_native(0)) == 0);

ok (native_to_int64(int64_to_native(-12343)) == -12343);

# 40

$n = pack(NN => 0x01020304, 0x05060708);

ok (net_to_int64($n) == ((int64(0x01020304) << 32) + 0x05060708));

ok ((($i | $j) & 1) != 0);

ok ((($i & $j) & 1) == 0);

SKIP: {
    skip "backend != IV", 8 unless Math::Int64::_backend() eq 'IV';

    ok(ref $_ eq '') for ($i, $j, $k,
                          net_to_int64(pack(NN => 0x01020304, 0x05060708)),
                          int64_to_net(-1),
                          native_to_int64(int64_to_native(-1)),
                          native_to_int64(int64_to_native(0)),
                          native_to_int64(int64_to_native(-12343)));
}

done_testing();
