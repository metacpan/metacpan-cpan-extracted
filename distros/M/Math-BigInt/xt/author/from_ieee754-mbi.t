# -*- mode: perl; -*-

use strict;
use warnings;

use Test::More tests => 230;

use Math::BigInt;
use Math::BigFloat;

my @k = (16, 32, 64, 128);

for my $k (@k) {

    # Parameters specific to this format:

    my $b = 2;
    my $p = $k == 16 ? 11
          : $k == 32 ? 24
          : $k == 64 ? 53
          : $k - sprintf("%.0f", 4 * log($k)/log(2)) + 13;

    $b = Math::BigFloat -> new($b);
    $k = Math::BigFloat -> new($k);
    $p = Math::BigFloat -> new($p);
    my $w = $k - $p;

    my $emax = 2 ** ($w - 1) - 1;
    my $emin = 1 - $emax;

    my $format = sprintf 'binary%u', $k;

    my $binv = Math::BigFloat -> new("0.5");

    my $data =
      [

       {
        dsc => "smallest positive subnormal number",
        bin => "0"
             . ("0" x $w)
             . ("0" x ($p - 2)) . "1",
        asc => "$b ** ($emin) * $b ** (" . (1 - $p) . ") "
             . "= $b ** (" . ($emin + 1 - $p) . ")",
        obj => $binv ** ($p - 1 - $emin),
       },

       {
        dsc => "largest subnormal number",
        bin => "0"
             . ("0" x $w)
             . ("1" x ($p - 1)),
        asc => "$b ** ($emin) * (1 - $b ** (" . (1 - $p) . "))",
        obj => $binv ** (-$emin) * (1 - $binv ** ($p - 1)),
       },

       {
        dsc => "smallest positive normal number",
        bin => "0"
             . ("0" x ($w - 1)) . "1"
             . ("0" x ($p - 1)),
        asc => "$b ** ($emin)",
        obj => $binv ** (-$emin),
       },

       {
        dsc => "largest normal number",
        bin => "0"
             . ("1" x ($w - 1)) . "0"
             . "1" x ($p - 1),
        asc => "$b ** $emax * ($b - $b ** (" . (1 - $p) . "))",
        obj => $b ** $emax * ($b - $binv ** ($p - 1)),
       },

       {
        dsc => "largest number less than one",
        bin => "0"
             . "0" . ("1" x ($w - 2)) . "0"
             . "1" x ($p - 1),
        asc => "1 - $b ** (-$p)",
        obj => 1 - $binv ** $p,
       },

       {
        dsc => "smallest number larger than one",
        bin => "0"
             . "0" . ("1" x ($w - 1))
             . ("0" x ($p - 2)) . "1",
        asc => "1 + $b ** (" . (1 - $p) . ")",
        obj => 1 + $binv ** ($p - 1),
       },

       {
        dsc => "second smallest number larger than one",
        bin => "0"
             . "0" . ("1" x ($w - 1))
             . ("0" x ($p - 3)) . "10",
        asc => "1 + $b ** (" . (2 - $p) . ")",
        obj => 1 + $binv ** ($p - 2),
       },

       {
        dsc => "one",
        bin => "0"
             . "0" . ("1" x ($w - 1))
             . "0" x ($p - 1),
        asc => "1",
        obj => Math::BigFloat -> new("1"),
       },

       {
        dsc => "minus one",
        bin => "1"
             . "0" . ("1" x ($w - 1))
             . "0" x ($p - 1),
        asc => "-1",
        obj => Math::BigFloat -> new("-1"),
       },

       {
        dsc => "two",
        bin => "0"
             . "1" . ("0" x ($w - 1))
             . ("0" x ($p - 1)),
        asc => "2",
        obj => Math::BigFloat -> new("2"),
       },

       {
        dsc => "minus two",
        bin => "1"
             . "1" . ("0" x ($w - 1))
             . ("0" x ($p - 1)),
        asc => "-2",
        obj => Math::BigFloat -> new("-2"),
       },

       {
        dsc => "positive zero",
        bin => "0"
             . ("0" x $w)
             . ("0" x ($p - 1)),
        asc => "+0",
        obj => Math::BigFloat -> new("0"),
       },

       {
        dsc => "negative zero",
        bin => "1"
             . ("0" x $w)
             . ("0" x ($p - 1)),
        asc => "-0",
        obj => Math::BigFloat -> new("0"),
       },

       {
        dsc => "positive infinity",
        bin => "0"
             . ("1" x $w)
             . ("0" x ($p - 1)),
        asc => "+inf",
        obj => Math::BigFloat -> new("inf"),
       },

       {
        dsc => "negative infinity",
        bin =>  "1"
             . ("1" x $w)
             . ("0" x ($p - 1)),
        asc => "-inf",
        obj => Math::BigFloat -> new("-inf"),
       },

       {
        dsc => "NaN (sNaN on most processors, such as x86 and ARM)",
        bin => "0"
             . ("1" x $w)
             . ("0" x ($p - 2)) . "1",
        asc => "sNaN",
        obj => Math::BigFloat -> new("NaN"),
       },

       {
        dsc => "NaN (qNaN on most processors, such as x86 and ARM)",
        bin => "0"
             . ("1" x $w)
             . "1" . ("0" x ($p - 3)) . "1",
        asc => "qNaN",
        obj => Math::BigFloat -> new("NaN"),
       },

       {
        dsc => "NaN (an alternative encoding)",
        bin => "0"
             . ("1" x $w)
             . ("1" x ($p - 1)),
        asc => "NaN",
        obj => Math::BigFloat -> new("NaN"),
       },

       {
        dsc => "NaN (encoding used by Perl on Cygwin)",
        bin => "1"
             . ("1" x $w)
             . ("1" . ("0" x ($p - 2))),
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
             "     binary : ", $bin, "\n",
             "hexadecimal : ", $hex, "\n",
             "      bytes : ", $str, "\n",
             "\n");

        my $expected = $entry -> {obj};
        $expected = "NaN" unless ($expected -> is_inf() ||
                                  $expected -> is_int());
        my ($got, $test);

        $got = Math::BigInt -> from_ieee754($bin, $format);

        $test = qq|Math::BigInt->from_ieee754("$bin", "$format")|;
        is($got, $expected, $test);

        $got = Math::BigInt -> from_ieee754($hex, $format);
        $test = qq|Math::BigInt->from_ieee754("$hex", "$format")|;
        is($got, $expected, $test);

        $got = Math::BigInt -> from_ieee754($bytes, $format);
        $test = qq|Math::BigInt->from_ieee754("$str", "$format")|;
        is($got, $expected, $test);
    }
}

note("\nTest as class method vs. instance method.\n\n");

# As class method.

my $x = Math::BigInt -> from_ieee754("4000000000000000", "binary64");
is($x, 2, "class method");

# As instance method, the invocand should be modified.

$x -> from_ieee754("4008000000000000", "binary64");
is($x, 3, "instance method modifies invocand");
