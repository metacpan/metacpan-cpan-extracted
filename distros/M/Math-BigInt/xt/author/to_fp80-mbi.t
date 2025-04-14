# -*- mode: perl; -*-

use strict;
use warnings;

use Test::More tests => 11;

use Math::BigInt;
use Math::BigFloat;

my $b =  2;             # base
my $p = 64;             # precision in bits
my $w = 15;             # width of exponent

$b = Math::BigInt -> new($b);
$p = Math::BigInt -> new($p);

my $emax = 2 ** ($w - 1) - 1;
my $emin = 1 - $emax;

my $format = 'fp80';

#my $binv = Math::BigFloat -> new("0.5");

my $data =
  [

   {
    dsc => "positive zero",
    bin => "0"
         . ("0" x $w)
         . ("0" x $p),
    asc => "+0",
    obj => Math::BigInt -> new("0"),
   },

   {
    dsc => "one",
    bin => "0"
         . "0" . ("1" x ($w - 1))
         . "1" . "0" x ($p - 1),
    asc => "1",
    obj => Math::BigInt -> new("1"),
   },

   {
    dsc => "largest normal number",
    bin => "0"
         . ("1" x ($w - 1)) . "0"
         . "1" x $p,
    asc => "$b ** $emax * ($b - $b ** (" . (1 - $p) . "))",
    #obj => $b ** $emax * ($b - $binv ** ($p - 1)),
    obj => $b ** ($emax + 1) - $b ** ($emax + 1 - $p),
   },

   {
    dsc => "minus one",
    bin => "1"
         . "0" . ("1" x ($w - 1))
         . "1" . "0" x ($p - 1),
    asc => "-1",
    obj => Math::BigInt -> new("-1"),
   },

   {
    dsc => "two",
    bin => "0"
         . "1" . ("0" x ($w - 1))
         . "1" . ("0" x ($p - 1)),
    asc => "2",
    obj => Math::BigInt -> new("2"),
   },

   {
    dsc => "minus two",
    bin => "1"
         . "1" . ("0" x ($w - 1))
         . "1" . ("0" x ($p - 1)),
    asc => "-2",
    obj => Math::BigInt -> new("-2"),
   },

   {
    dsc => "positive infinity",
    bin => "0"
         . ("1" x $w)
         . ("0" x $p),
    asc => "+inf",
    obj => Math::BigInt -> new("inf"),
   },

   {
    dsc => "negative infinity",
    bin =>  "1"
         . ("1" x $w)
         . ("0" x $p),
    asc => "-inf",
    obj => Math::BigInt -> new("-inf"),
   },

   {
    dsc => "NaN",
    bin => "1"
         . ("1" x $w)
         . ("1" x $p),
    asc => "NaN",
    obj => Math::BigInt -> new("NaN"),
   },

  ];

for my $entry (@$data) {
    my $bin   = $entry -> {bin};
    my $bytes = pack "B*", $bin;
    my $hex   = unpack "H*", $bytes;
    my $str   = join "", map "\\x$_", unpack "(a2)*", $hex;

    note("\n",
         "     format : ", $format, "\n",
         "description : ", $entry -> {dsc}, "\n",
         "      value : ", $entry -> {asc}, "\n",
         "     binary : ", join(" ", unpack "(a8)*", $bin), "\n",
         "hexadecimal : ", join(" ", unpack "(a2)*", $hex), "\n",
         "      bytes : ", $str, "\n",
         "\n");

    my $x = $entry -> {obj};

    my $test = qq|Math::BigInt -> new("$x") -> to_fp80()|;

    my $got_bytes = $x -> to_fp80();
    my $got_hex = unpack "H*", $got_bytes;
    $got_hex =~ s/(..)/\\x$1/g;

    my $expected_hex = $hex;
    $expected_hex =~ s/(..)/\\x$1/g;

    is($got_hex, $expected_hex);
}

note("\nRounding close to the largest normal number.\n\n");

{
    # largest normal number: 2 ** 16383 * (2 - 2 ** (-63))
    my $lo = Math::BigFloat -> from_fp80("7ffeffffffffffffffff");

    # 2 ** 16383 * 2 = 2 ** 16384
    my $hi = Math::BigFloat -> new("2") -> bpow("16384");

    # compute an average weighted towards the smaller of the two
    my $x1 = 0.75 * $lo + 0.25 * $hi;

    note "";
    note "lo ≈ ", $lo -> bnstr(40);
    note "hi ≈ ", $hi -> bnstr(40);
    note "x1 ≈ ", $x1 -> bnstr(40);
    note "";

    # this must round down to the largest normal number
    my $got1 = unpack "H*", $x1 -> to_fp80();
    is($got1, "7ffeffffffffffffffff");

    # compute an average weighted towards the larger of the two
    my $x3 = 0.25 * $lo + 0.75 * $hi;

    note "";
    note "lo ≈ ", $lo -> bnstr(40);
    note "hi ≈ ", $hi -> bnstr(40);
    note "x3 ≈ ", $x3 -> bnstr(40);
    note "";

    # this must round up to infinity
    my $got3 = unpack "H*", $x3 -> to_fp80();
    is($got3, "7fff0000000000000000");
}
