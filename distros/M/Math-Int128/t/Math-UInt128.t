#!/usr/bin/perl

use strict;
use warnings;

use Test::More 0.88;

use Math::Int128 qw(uint128 uint128_to_number
                    net_to_uint128 uint128_to_net
                    native_to_uint128 uint128_to_native);

my $i = uint128('1234567890123456789');
my $j = $i + 1;
my $k = (uint128(1) << 60) + 255;

# 1
ok($i == '1234567890123456789');

ok($j - 1 == '1234567890123456789');

ok (($k & 127) == 127);

ok (($k & 256) == 0);

# 5
ok ($i * 2 == $j + $j - 2);

ok ($i * $i * $i * $i == ($j * $j - 2 * $j + 1) * ($j * $j - 2 * $j + 1));

ok (($i / $j) == 0);

ok ($j / $i == 1);

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

ok (int(log(uint128(1)<<50)/log(2)+0.001) == 50);

# 35

my $l = uint128("127131031961723452345");

is ("$l", "127131031961723452345", "string to/from int128 conversion");

ok (native_to_uint128(uint128_to_native(1)) == 1);

ok (native_to_uint128(uint128_to_native(0)) == 0);

ok (native_to_uint128(uint128_to_native(12343)) == 12343);

ok (native_to_uint128(uint128_to_native($l)) == $l);

# 40

ok (native_to_uint128(uint128_to_native($j)) == $j);

ok (native_to_uint128(uint128_to_native($i)) == $i);

ok (net_to_uint128(uint128_to_net(1)) == 1);

ok (net_to_uint128(uint128_to_net(0)) == 0);

ok (net_to_uint128(uint128_to_net(12343)) == 12343);

# 45

ok (net_to_uint128(uint128_to_net($l)) == $l);

ok (net_to_uint128(uint128_to_net($j)) == $j);

ok (net_to_uint128(uint128_to_net($i)) == $i);

{
    use integer;
    my $int = uint128(255);
    ok($int == 255);
    $int <<= 32;
    $int |= 4294967295;
    ok($int == '1099511627775');
}

my $two  = uint128(2);
my $four = uint128(4);
is ($two  ** -1, 0, "signed pow 2**-1");
is ($four ** -1, 0, "signed pow 4**-1");

sub slow_pow_uint128 {
    my ($a, $b) = @_;
    my $acu = uint128(1);
    $acu *= $a for 1..$b;
    $acu;
}

sub slow_pow_nv {
    my ($base, $exp) = @_;
    my $r = 1;
    $r *= $base for 1..$exp;
    $r
}

my $max = (((uint128(2) ** 127) - 1) * 2) + 1;
for my $j (0..127) {
    my $one = uint128(1);

    is($two  ** $j, $one <<     $j, "signed pow 2**$j");
    is($four ** $j, $one << 2 * $j, "signed pow 4**$j") if $j < 64;

    is($one << $j, $two ** $j, "$one << $j");

    $one <<= $j;
    is($one, $two ** $j, "$one <<= $j");

    next unless $j;

    my $pow2j = slow_pow_nv(2, $j);

    is($max >> $j, $max / $pow2j, "max uint128 >> $j");

    my $copy = uint128($max);
    $copy >>= $j;
    is($copy, $max / $pow2j, "max uint128 >>= $j");
}

for my $i (5..9) {
    for my $j (0..40) { # 9**40 < 2**127
        is(uint128($i) ** $j, slow_pow_uint128($i, $j), "signed pow $i ** $j");
    }
}

done_testing();
