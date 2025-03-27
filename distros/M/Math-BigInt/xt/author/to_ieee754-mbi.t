# -*- mode: perl; -*-

use strict;
use warnings;

use Test::More tests => 32;

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

    my $format = 'binary' . $k;

    note("\nComputing test data for k = $k ...\n\n");

    my $binv = Math::BigFloat -> new("0.5");

    my $data =
      [

       {
        dsc => "one",
        bin => "0"
             . "0" . ("1" x ($w - 1))
             . "0" x ($p - 1),
        asc => "1",
        obj => Math::BigInt -> new("1"),
       },

       {
        dsc => "minus one",
        bin => "1"
             . "0" . ("1" x ($w - 1))
             . "0" x ($p - 1),
        asc => "-1",
        obj => Math::BigInt -> new("-1"),
       },

       {
        dsc => "two",
        bin => "0"
             . "1" . ("0" x ($w - 1))
             . ("0" x ($p - 1)),
        asc => "2",
        obj => Math::BigInt -> new("2"),
       },

       {
        dsc => "minus two",
        bin => "1"
             . "1" . ("0" x ($w - 1))
             . ("0" x ($p - 1)),
        asc => "-2",
        obj => Math::BigInt -> new("-2"),
       },

       {
        dsc => "positive zero",
        bin => "0"
             . ("0" x $w)
             . ("0" x ($p - 1)),
        asc => "+0",
        obj => Math::BigInt -> new("0"),
       },

       {
        dsc => "positive infinity",
        bin => "0"
             . ("1" x $w)
             . ("0" x ($p - 1)),
        asc => "+inf",
        obj => Math::BigInt -> new("inf"),
       },

       {
        dsc => "negative infinity",
        bin =>  "1"
             . ("1" x $w)
             . ("0" x ($p - 1)),
        asc => "-inf",
        obj => Math::BigInt -> new("-inf"),
       },

       {
        dsc => "NaN (encoding used by Perl on Cygwin)",
        bin => "1"
             . ("1" x $w)
             . ("1" . ("0" x ($p - 2))),
        asc => "NaN",
        obj => Math::BigInt -> new("NaN"),
       },

      ];

    for my $entry (@$data) {
        my $bin   = $entry -> {bin};
        my $bytes = pack "B*", $bin;
        my $hex   = unpack "H*", $bytes;

        note("\n", $entry -> {dsc}, " (k = $k): ", $entry -> {asc}, "\n\n");

        my $x = $entry -> {obj};

        my $test = qq|Math::BigInt -> new("$x") -> to_ieee754("$format")|;

        my $got_bytes = $x -> to_ieee754($format);
        my $got_hex = unpack "H*", $got_bytes;
        $got_hex =~ s/(..)/\\x$1/g;

        my $expected_hex = $hex;
        $expected_hex =~ s/(..)/\\x$1/g;

        is($got_hex, $expected_hex);
    }
}
