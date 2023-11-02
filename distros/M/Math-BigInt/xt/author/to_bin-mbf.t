# -*- mode: perl; -*-

use strict;
use warnings;

use Test::More;
use Math::BigFloat;

my $cases =
  [
   [ "inf", "inf" ],
   [ "-inf", "-inf" ],
   [ "NaN", "NaN" ],
   [ "1/2", "NaN" ],
   [ "-1/2", "NaN" ],
  ];

for (my $in = -300 ; $in <= 300 ; $in++) {
    my $out = sprintf "%b", abs($in);
    $out = "-" . $out if $in < 0;
    push @$cases, [ $in, $out ];
}

for (my $ndig = 4 ; $ndig <= 50 ; $ndig++) {
    for my $rep (1 .. 5) {
        my $in = 1 + int rand 9;
        $in .= int rand 10 for 2 .. $ndig;
        my $out = `dc <<< "2 o $in p"`;
        $out =~ tr/0-9A-F//dc;
        $out = lc $out;
        push @$cases,
          [ $in, $out ],
          [ "-$in", "-$out" ];
    }
}

for my $case (@$cases) {
    my ($in, $want) = @$case;
    note qq|\n\$x = Math::BigFloat -> to_bin("$want");\n\n|;
    my $got = Math::BigFloat -> to_bin($in);
    is(ref($got), '', 'output is a scalar');
    is($got, $want, "output is '$want'");
};

for my $case (@$cases) {
    my ($in, $want) = @$case;
    note qq|\n\$x = Math::BigFloat -> new("$in") -> to_bin();\n\n|;
    my $got = Math::BigFloat -> new("$in") -> to_bin();
    is(ref($got), '', 'output is a scalar');
    is($got, $want, "output is '$want'");
};

done_testing();
