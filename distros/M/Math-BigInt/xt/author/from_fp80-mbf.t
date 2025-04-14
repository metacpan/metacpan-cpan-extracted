# -*- mode: perl; -*-

use strict;
use warnings;

use Test::More tests => 68;

use Math::BigFloat;

my $b =  2;             # base
my $k = 80;             # total width in bits
my $p = 64;             # precision in bits
my $w = 15;             # width of exponent

$b = Math::BigFloat -> new($b);
$p = Math::BigFloat -> new($p);

my $emax = 2 ** ($w - 1) - 1;
my $emin = 1 - $emax;

my $format = 'fp80';

my $binv = Math::BigFloat -> new("0.5");

my $data =
  [

   {
    dsc => "positive zero",
    bin => "0"
         . ("0" x $w)
         . ("0" x $p),
    asc => "+0",
    obj => Math::BigFloat -> new("0"),
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
    obj => Math::BigFloat -> new("-1"),
   },

   {
    dsc => "two",
    bin => "0"
         . "1" . ("0" x ($w - 1))
         . "1" . ("0" x ($p - 1)),
    asc => "2",
    obj => Math::BigFloat -> new("2"),
   },

   {
    dsc => "minus two",
    bin => "1"
         . "1" . ("0" x ($w - 1))
         . "1" . ("0" x ($p - 1)),
    asc => "-2",
    obj => Math::BigFloat -> new("-2"),
   },

   {
    dsc => "positive infinity",
    bin => "0"
         . ("1" x $w)
         . ("0" x $p),
    asc => "+inf",
    obj => Math::BigFloat -> new("inf"),
   },

   {
    dsc => "negative infinity",
    bin =>  "1"
         . ("1" x $w)
         . ("0" x $p),
    asc => "-inf",
    obj => Math::BigFloat -> new("-inf"),
   },

   {
    dsc => "NaN",
    bin => "0"
         . ("1" x $w)
         . ("0" x ($p - 1)) . "1",
    asc => "NaN",
    obj => Math::BigFloat -> new("NaN"),
   },

   {
    dsc => "NaN (alternative encoding)",
    bin => "0"
         . ("1" x $w)
         . "1" . ("0" x ($p - 2)) . "1",
    asc => "NaN",
    obj => Math::BigFloat -> new("NaN"),
   },

   {
    dsc => "NaN (another alternative encoding)",
    bin => "0"
         . ("1" x $w)
         . ("1" x $p),
    asc => "NaN",
    obj => Math::BigFloat -> new("NaN"),
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

    my $expected = $entry -> {obj};
    my ($got, $test);

    $got = Math::BigFloat -> from_fp80($bin);
    $test = qq|Math::BigFloat->from_fp80("$bin")|;
    is($got -> bnstr(), $expected -> bnstr(), $test);

    $got = Math::BigFloat -> from_fp80($hex);
    $test = qq|Math::BigFloat->from_fp80("$hex")|;
    is($got -> bnstr(), $expected -> bnstr(), $test);

    $got = Math::BigFloat -> from_fp80($bytes);
    $test = qq|Math::BigFloat->from_fp80("$str")|;
    is($got -> bnstr(), $expected -> bnstr(), $test);
}

note("\nTest as class method vs. instance method.\n\n");

# As class method.

{
    my $bin = "0"
            . "100000000000000"
            . "1000000000000000000000000000000000000000000000000000000000000000";
    note "bin : ", join(" ", unpack "(a8)*", $bin);

    my $hex = unpack "H*", pack "B*", $bin;
    note "hex : ", join(" ", unpack "(a2)*", $hex);

    my $x = Math::BigFloat -> from_fp80($hex);
    is($x, 2, "class method");
}

# As instance method, the invocand should be modified.

{
    my $bin = "0"
            . "100000000000000"
            . "1100000000000000000000000000000000000000000000000000000000000000";
    note "bin : ", join(" ", unpack "(a8)*", $bin);

    my $hex = unpack "H*", pack "B*", $bin;
    note "hex : ", join(" ", unpack "(a2)*", $hex);

    my $x = Math::BigFloat -> bnan();
    $x -> from_fp80($hex);
    is($x, 3, "instance method modifies invocand");
}
