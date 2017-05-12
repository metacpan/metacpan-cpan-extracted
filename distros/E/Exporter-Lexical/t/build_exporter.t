#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use lib 't/lib';

sub bar { 'bar' }

is(bar(), "bar");
{
    use Bar;
    is(bar(), "BAR");
    is($Bar::imported, 1);
}
is(bar(), "bar");

done_testing;
