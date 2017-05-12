#!/usr/bin/env perl -w
use strict;
use Test::More tests => 1;

use Hash::Lazy;

# http://en.wikipedia.org/wiki/Negafibonacci
# 1, -1, -2, -3, -5, -8, -13, -21, -34, -55
my $nfib = Hash {
    my ($hash, $key) = @_;
    $hash->{$key} = $hash->{$key + 2} - $hash->{$key + 1};
};

$$nfib{-1} = 1;
$$nfib{-2} = -1;

is($$nfib{-10}, -55);
