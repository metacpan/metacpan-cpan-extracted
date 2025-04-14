# -*- mode: perl; -*-

use strict;
use warnings;

use Test::More tests => 22;

use Math::BigRat;
use Math::BigFloat;

my $b =  2;             # base
my $p = 64;             # precision in bits
my $w = 15;             # width of exponent

$b = Math::BigRat -> new($b);
$p = Math::BigRat -> new($p);

my $emax = 2 ** ($w - 1) - 1;
my $emin = 1 - $emax;

my $format = 'fp80';

my $binv = Math::BigRat -> new("0.5");

my $data =
  [

   {
    dsc => "positive zero",
    bin => "0"
         . ("0" x $w)
         . ("0" x $p),
    asc => "+0",
    obj => Math::BigRat -> new("0"),
   },

   {
    dsc => "smallest positive subnormal number",
    bin => "0"
         . ("0" x $w)
         . ("0" x ($p - 1)) . "1",
    asc => "$b ** ($emin) * $b ** (" . (1 - $p) . ") "
         . "= $b ** (" . ($emin + 1 - $p) . ")",
    obj => $binv ** ($p - 1 - $emin),
   },

   {
    dsc => "second smallest positive subnormal number",
    bin => "0"
         . ("0" x $w)
         . ("0" x ($p - 2)) . "10",
    asc => "$b ** ($emin) * $b ** (" . (2 - $p) . ") "
         . "= $b ** (" . ($emin + 2 - $p) . ")",
    obj => $binv ** ($p - 2 - $emin),
   },

   {
    dsc => "second largest subnormal number",
    bin => "0"
         . ("0" x $w)
         . "0" . ("1" x ($p - 2)) . "0",
    asc => "$b ** ($emin) * (1 - $b ** (" . (2 - $p) . "))",
    obj => $binv ** (-$emin) * (1 - $binv ** ($p - 2)),
   },

   {
    dsc => "largest subnormal number",
    bin => "0"
         . ("0" x $w)
         . "0" . ("1" x ($p - 1)),
    asc => "$b ** ($emin) * (1 - $b ** (" . (1 - $p) . "))",
    obj => $binv ** (-$emin) * (1 - $binv ** ($p - 1)),
   },

   {
    dsc => "smallest positive normal number",
    bin => "0"
         . ("0" x ($w - 1)) . "1"
         . "1" . ("0" x ($p - 1)),
    asc => "$b ** ($emin)",
    obj => $binv ** (-$emin),
   },

   {
    dsc => "second smallest positive normal number",
    bin => "0"
         . ("0" x ($w - 1)) . "1"
         . "1" . ("0" x ($p - 2)) . "1",
    asc => "$b ** ($emin) * (1 + $b ** (" . (1 - $p) . "))",
    obj => $binv ** (-$emin) * (1 + $binv ** ($p - 1)),
   },

   {
    dsc => "second largest number less than one",
    bin => "0"
         . "0" . ("1" x ($w - 2)) . "0"
         . "1" x ($p - 1) . "0",
    asc => "1 - $b ** (1 - $p)",
    obj => 1 - $binv ** ($p - 1),
   },

   {
    dsc => "largest number less than one",
    bin => "0"
         . "0" . ("1" x ($w - 2)) . "0"
         . "1" x $p,
    asc => "1 - $b ** (-$p)",
    obj => 1 - $binv ** $p,
   },

   {
    dsc => "one",
    bin => "0"
         . "0" . ("1" x ($w - 1))
         . "1" . "0" x ($p - 1),
    asc => "1",
    obj => Math::BigFloat -> new("1"),
   },

   {
    dsc => "smallest number larger than one",
    bin => "0"
         . "0" . ("1" x ($w - 1))
         . ("1" . "0" x ($p - 2)) . "1",
    asc => "1 + $b ** (" . (1 - $p) . ")",
    obj => 1 + $binv ** ($p - 1),
   },

   {
    dsc => "second smallest number larger than one",
    bin => "0"
         . "0" . ("1" x ($w - 1))
         . "1" . ("0" x ($p - 3)) . "10",
    asc => "1 + $b ** (" . (2 - $p) . ")",
    obj => 1 + $binv ** ($p - 2),
   },

   {
    dsc => "second largest normal number",
    bin => "0"
         . ("1" x ($w - 1)) . "0"
         . "1" x ($p - 1) . "0",
    asc => "$b ** $emax * ($b - $b ** (" . (2 - $p) . "))",
    obj => $b ** $emax * ($b - $binv ** ($p - 2)),
   },

   {
    dsc => "largest normal number",
    bin => "0"
         . ("1" x ($w - 1)) . "0"
         . "1" x $p,
    asc => "$b ** $emax * ($b - $b ** (" . (1 - $p) . "))",
    obj => $b ** $emax * ($b - $binv ** ($p - 1)),
   },

   {
    dsc => "minus one",
    bin => "1"
         . "0" . ("1" x ($w - 1))
         . "1" . "0" x ($p - 1),
    asc => "-1",
    obj => Math::BigRat -> new("-1"),
   },

   {
    dsc => "two",
    bin => "0"
         . "1" . ("0" x ($w - 1))
         . "1" . ("0" x ($p - 1)),
    asc => "2",
    obj => Math::BigRat -> new("2"),
   },

   {
    dsc => "minus two",
    bin => "1"
         . "1" . ("0" x ($w - 1))
         . "1" . ("0" x ($p - 1)),
    asc => "-2",
    obj => Math::BigRat -> new("-2"),
   },

   {
    dsc => "positive infinity",
    bin => "0"
         . ("1" x $w)
         . ("0" x $p),
    asc => "+inf",
    obj => Math::BigRat -> new("inf"),
   },

   {
    dsc => "negative infinity",
    bin =>  "1"
         . ("1" x $w)
         . ("0" x $p),
    asc => "-inf",
    obj => Math::BigRat -> new("-inf"),
   },

   {
    dsc => "NaN",
    bin => "1"
         . ("1" x $w)
         . ("1" x $p),
    asc => "NaN",
    obj => Math::BigRat -> new("NaN"),
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

    my $test = qq|Math::BigRat -> new("$x") -> to_fp80()|;

    my $got_bytes = $x -> to_fp80(40);
    my $got_hex = unpack "H*", $got_bytes;
    $got_hex =~ s/(..)/\\x$1/g;

    my $expected_hex = $hex;
    $expected_hex =~ s/(..)/\\x$1/g;

    is($got_hex, $expected_hex);
}

{
    # largest number smaller than one
    my $lo = Math::BigRat -> from_fp80("3ffeffffffffffffffff");

    # one
    my $hi = Math::BigRat -> from_fp80("3fff8000000000000000");

    # compute an average weighted towards the smaller of the two
    my $x1 = 0.75 * $lo + 0.25 * $hi;

    note "";
    note "lo : ", $lo -> bdstr();
    note "hi : ", $hi -> bdstr();
    note "x1 : ", $x1 -> bdstr();
    note "";

    my $got1 = unpack "H*", $x1 -> to_fp80(40);
    is($got1, "3ffeffffffffffffffff",
       "0.999999999999999999959342418531793583... -> 0x3ffeffffffffffffffff");

    # compute an average weighted towards the larger of the two
    my $x3 = 0.25 * $lo + 0.75 * $hi;

    note "";
    note "lo : ", $lo -> bdstr();
    note "hi : ", $hi -> bdstr();
    note "x3 : ", $x3 -> bdstr();
    note "";

    my $got3 = unpack "H*", $x3 -> to_fp80();
    is($got3, "3fff8000000000000000",
       "0.999999999999999999986447472843931194... -> 0x3fff8000000000000000");
}
