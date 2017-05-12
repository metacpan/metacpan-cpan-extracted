#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use Fun;

fun mul ($x, $y) {
    return $x * $y;
}

is(mul(3, 4), 12);

fun sum (@nums) {
    my $sum;
    for my $num (@nums) {
        $sum += $num;
    }
    return $sum;
}

is(sum(1, 2, 3, 4), 10);

{
    package Foo;
    use Fun;
    fun foo { }
}

ok(exists $Foo::{foo});

done_testing;
