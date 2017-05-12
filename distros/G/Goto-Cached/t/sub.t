#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 4;
use Goto::Cached;

sub test1 {
    goto &test2;
}

sub test2 {
    return [ caller(0) ];
}

sub test3 {
    goto shift;
}

sub test4 {
    return [ caller(0) ];
}

my ($caller1, $caller2) = (test1(), test2());
my ($caller3, $caller4) = (test3(\&test4), test4());

is_deeply($caller1, $caller2);
is_deeply($caller3, $caller4);
is_deeply(test1(), test2());
is_deeply(test3(\&test4), test4());
