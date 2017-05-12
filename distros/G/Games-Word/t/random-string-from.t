#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Test::Deep;
use Test::Fatal;

use Games::Word qw(random_string_from);

is(random_string_from("", 0), "",
   "0 length random_string_from an empty string");
like(
    exception { random_string_from("", 5) },
    qr/invalid letter list/,
    "random_string_from an empty string"
);
is(random_string_from("abcde", 0), "",
   "0 length random_string_from");
my @letters = qw/a b c d e/;
for my $i (1..10) {
    my $str = random_string_from join('', @letters), $i;
    is(length $str, $i, "random_string_from returns the correct length");
    my $bag = subbagof();
    $bag->add(@letters) for 1..$i;
    cmp_deeply([split(//, $str)], $bag, "random test of random_string_from");
}

done_testing;
