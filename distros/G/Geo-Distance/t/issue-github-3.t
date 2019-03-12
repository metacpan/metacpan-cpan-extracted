#!/usr/bin/env perl
use 5.008001;
use strict;
use warnings;
use Test2::V0;

use Geo::Distance;

my $geo = Geo::Distance->new();

is(
    dies { $geo->distance('mile', 175, 12, -5, -12) },
    undef,
    'did not die',
);

done_testing;
