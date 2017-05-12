#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;

use Fun;

{
    my $x = 10;

    fun bar ($y) {
        $x * $y
    }
}

is(bar(3), 30);

done_testing;
