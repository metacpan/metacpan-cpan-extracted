#!/usr/bin/perl

use strict;
use warnings;

use Test::More 0.88;

use Math::Int64 qw(int64 int64_to_number
                   net_to_int64 int64_to_net
                   le_to_int64 int64_to_le
                   string_to_int64 int64_to_string
                   native_to_int64 int64_to_native
                   int64_to_BER BER_to_int64 uint64_to_BER BER_length
                   int64_rand
                   int64_to_hex hex_to_int64
                 );

my $i = int64('1234567890123456789');
my $j = $i + 1;
my $k = (int64(1) << 60) + 255;

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
my $nu = (int64(0x01020304) << 32) + 0x05060708;

ok (net_to_int64($n) == $nu);

ok ((($i | $j) & 1) != 0);

ok ((($i & $j) & 1) == 0);

my $l = int64("1271310319617");

is ("$l", "1271310319617", "string to/from int64 conversion");

is(BER_to_int64(int64_to_BER($l)). "", "1271310319617");

is(int64_to_BER($nu), uint64_to_BER($nu << 1));

for ( int64('1271310319617'),
      int64('8420970171052099265'),
      int64(0xdeadbeef),
      map int64_rand, 1..50 )
{
    my $n = $_;
     my $hex = int64_to_hex($n);
    ok($n == int64("$n"));
    ok($n == string_to_int64(int64_to_string($n)), "int64->string->int64 n: $n hex: $hex");
    ok(int64_to_hex($n) eq int64_to_hex(string_to_int64(int64_to_string($n))));
    ok($n == hex_to_int64(int64_to_hex($n)));
    is("$n", string_to_int64(int64_to_string($n)));
    is("$n", string_to_int64(int64_to_string($n, 25), 25));
    is("$n", string_to_int64(int64_to_string($n, 36), 36));
    is("$n", string_to_int64(int64_to_string($n, 2), 2));
    is("$n", native_to_int64(int64_to_native($n)));
    is("$n", net_to_int64(int64_to_net($n)));
    my $ber = int64_to_BER($n);
    my $ber_length = length($ber);
    is("$n", BER_to_int64(int64_to_BER($n)));
    is("$n", BER_to_int64($ber));
    is($ber_length, BER_length($ber));
    is($ber_length, BER_length($ber . pack ("C*", map rand(256), 0..rand(10))));
}

# pow (**) precision sometimes is not good enough!
sub ipow {
    my ($base, $exp) = @_;
    my $r = 1;
    $r *= $base for (1..$exp);
    $r;
}

my $two  = int64(2);
my $four = int64(4);
is ($two  ** -1, 0, "signed pow 2**-1");
is ($four ** -1, 0, "signed pow 4**-1");

my $max = (((int64(2)**62)-1)*2)+1;
for my $j (0..62) {
    my $one = int64(1);

    is($two  ** $j, $one <<     $j, "signed pow 2**$j");
    is($four ** $j, $one << 2 * $j, "signed pow 4**$j") if $j < 32;

    is($one << $j, $two ** $j, "$one << $j");

    $one <<= $j;
    is($one, $two ** $j, "$one <<= $j");

    next unless $j;

    is($max >> $j, $max / ipow(2, $j), "max int64 >> $j");

    my $copy = int64($max);
    $copy >>= $j;
    is($copy, $max / ipow(2, $j), "max int64 >>= $j");
}

is ($max >> 63, 0, "max int64 >> 63");

# test for rt.cpan.org #100861:
is(sprintf("%s", int64("-2251842763358208")), "-2251842763358208", "bug #100861");

{
    my $one = int64(1);
    cmp_ok($one << 64, '==', 0, '1 << 64 == 0');
    cmp_ok($one << 65, '==', 0, '1 << 65 == 0');
}

{
    my $one = int64(1);
    $one <<= 64;
    cmp_ok($one, '==', 0, '1 <<= 64 == 0');
}

{
    my $one = int64(1);
    $one <<= 65;
    cmp_ok($one, '==', 0, '1 <<= 65 == 0');
}

{
    my $one = int64(1);
    cmp_ok($one >> 64, '==', 0, '1 >> 64 == 0');
    cmp_ok($one >> 65, '==', 0, '1 >> 65 == 0');
}

{
    my $one = int64(1);
    $one >>= 64;
    cmp_ok($one, '==', 0, '1 >>= 64 == 0');
}

{
    my $one = int64(1);
    $one >>= 65;
    cmp_ok($one, '==', 0, '1 >>= 65 == 0');
}

{
    my $neg_one = int64(-1);
    cmp_ok($neg_one >> 64, '==', -1, '-1 >> 64 == -1');
    cmp_ok($neg_one >> 65, '==', -1, '-1 >> 65 == -1');
}

{
    my $neg_one = int64(-1);
    $neg_one >>= 64;
    cmp_ok($neg_one, '==', -1, '-1 >>= 64 == -1');
}

{
    my $neg_one = int64(-1);
    $neg_one >>= 65;
    cmp_ok($neg_one, '==', -1, '-1 >>= 65 == -1');
}

my $nle = int64_to_le(-1);
ok (join(" ", unpack "C*" => $nle) eq join(" ", (255) x 8));

my $nle2 = int64_to_le(2);
ok (join(" ", unpack "C*" => $nle2) eq join(" ", (2, 0, 0, 0, 0, 0, 0, 0)));

ok (int64_to_net(le_to_int64("\x01\x02\x03\x04\x05\x06\x07\x08")) eq "\x08\x07\x06\x05\x04\x03\x02\x01");


done_testing();
