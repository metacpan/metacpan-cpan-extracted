#! /usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 96;

ok require Datify, 'Required Datify';

my @integers = qw(
              1
             21
            321

          4_321
         54_321
        654_321

      7_654_321
     87_654_321
    987_654_321
);
foreach my $number (@integers) {
    my $as_string   = $number;
    my $underscores = $number =~ tr/_//d;

    my $num = Datify->numify( 0+ $number );
    cmp_ok $num,  'eq', $as_string, 'Looks like expected integer';
    is $num =~ tr/_//, $underscores, "Underscores in integer $number";

    my $_num = Datify->numify( -$number );
    cmp_ok $_num, 'eq', "-$as_string", 'Looks like expected negative integer';
    is $_num =~ tr/_//, $underscores, "Underscores in negative integer -$number";
}

my @real = qw(
    0.1
    0.13
    0.13_5
    0.13_57
    0.13_579
    0.13_579_2
    0.13_579_24
    0.13_579_246

            789.01_234_567
        456_789.01_234
    123_456_789.01
);
foreach my $number (@real) {
    my $as_string   = $number;
    my $underscores = $number =~ tr/_//d;

    my $num = Datify->numify( 0+ $number );
    cmp_ok $num,  'eq', "$as_string", 'Looks like expected number';
    is $num =~ tr/_//, $underscores, "Underscores in number $number";

    my $_num = Datify->numify( -$number );
    cmp_ok $_num, 'eq', "-$as_string", 'Looks like expected negative number';
    is $_num =~ tr/_//, $underscores, "Underscores in negative number -$number";
}

my @infinity = (
    qw( Inf inf infinity ),
);
foreach my $number (@infinity) {
    my $as_string   = $number;

    my $num = Datify->numify( 0+ $number );
    cmp_ok $num,  'eq', "'inf'", 'Looks like expected infinity';

    my $_num = Datify->numify( -$number );
    cmp_ok $_num, 'eq', "'-inf'", 'Looks like expected negative infinity';
}

my @nan = (
    qw( NaN nan NAN )
);
foreach my $number (@nan) {
    my $as_string   = $number;

    my $num = Datify->numify( 0+ $number );
    is $num, "'nan'", 'Looks like expected NaN';

    my $_num = Datify->numify( -$number );
    is $_num, "'nan'", 'Looks like expected negative NaN';
}

my @weirds = (
    qw( apple banana )
);
foreach my $number (@weirds) {
    my $num = Datify->numify( $number );
    is $num, "'nan'", 'Looks like expected non-numeric value';
}

my $num = Datify->numify( undef );
is $num, 'undef', 'Looks like expected undef value';
