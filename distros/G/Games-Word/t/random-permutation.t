#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use Games::Word qw(random_permutation);

is(random_permutation(""), "", "testing permutation of empty string");

for my $word (qw/foo bar baz quux blah/) {
    for (1..10) {
        is_deeply(
            [sort split //, random_permutation($word)],
            [sort split //, $word],
            "random tests"
        );
    }
}

done_testing;
