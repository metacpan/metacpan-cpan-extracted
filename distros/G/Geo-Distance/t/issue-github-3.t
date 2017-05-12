#!/usr/bin/env perl
use strict;
use warnings;

# https://github.com/bluefeet/Geo-Distance/issues/3
# Square root of negative value

use Test::More;
use Test::Fatal;

BEGIN { use_ok('Geo::Distance') }

my $geo = Geo::Distance->new();

is(
    exception { $geo->distance("mile", 175, 12, -5, -12) },
    undef,
);

done_testing;
