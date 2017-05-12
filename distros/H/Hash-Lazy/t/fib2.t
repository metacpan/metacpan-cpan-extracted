#!/usr/bin/env perl -w
use strict;
use Test::More tests => 1;

use Hash::Lazy;

my $fib = Hash {
    my ($hash, $key) = @_;
    return $hash->{$key - 1} + $hash->{$key - 2};
};

$$fib{0} = 0;
$$fib{1} = 1;

is($$fib{10}, 55);
