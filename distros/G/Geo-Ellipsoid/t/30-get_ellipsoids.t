#!perl

use strict;
use warnings;

use Test::More tests => 4;

use Geo::Ellipsoid;

can_ok('Geo::Ellipsoid', 'get_ellipsoids');

# Get all ellipsoid names and count how many we got.

my @ellipsoids = Geo::Ellipsoid -> get_ellipsoids();
my $n = @ellipsoids;

# Run some very basic tests.

cmp_ok($n, '>', 0,
   'got a non-empty list of ellipsoid names');

is(scalar(grep { defined() } @ellipsoids), $n,
   'all ellipsoid names are defined');

is(scalar(grep { defined() && length() } @ellipsoids), $n,
   'all ellipsoid names are non-empty strings');
