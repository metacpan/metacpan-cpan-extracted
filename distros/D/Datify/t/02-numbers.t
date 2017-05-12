#! /usr/bin/env perl

use Test::More tests => 21;

ok require Datify, 'Required Datify';

my @integers = (
              1,
             21,
            321,

          4_321,
         54_321,
        654_321,

      7_654_321,
     87_654_321,
    987_654_321,
);
foreach my $number (@integers) {
    my $underscores = int((length($number) - 1)/ 3);

    my $num = Datify->numify($number);
    is $num =~ tr/_//, $underscores, "Underscores in number $number";
}

my @real = (
    0.1,
    0.13,
    0.13_5,
    0.13_57,
    0.13_579,
    0.13_579_2,
    0.13_579_24,
    0.13_579_246,
);
foreach my $number (@real) {
    my $underscores = int((length($number) - 2)/ 3);

    my $num = Datify->numify($number);
    is $num =~ tr/_//, $underscores, "Underscores in number $number";
}

my @both = (
            789.01_234_567,
        456_789.01_234,
    123_456_789.01,
);
foreach my $number (@both) {
    my $underscores = 2;

    my $num = Datify->numify($number);
    is $num =~ tr/_//, $underscores, "Underscores in number $number";
}

