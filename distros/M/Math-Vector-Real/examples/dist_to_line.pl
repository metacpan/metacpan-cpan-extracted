#!/usr/bin/perl

use strict;
use warnings;

# see http://perlmonks.org/?node_id=814899

# Given a line defined by two points $l0 and $l1 calculate the
# distance to another point $p:

use Math::Vector::Real;

my $l0 = V(2, 3, 4);
my $l1 = V(1, 0, 1);

my $p = V(2, 2, 2);

# calculate the vector $n perpendicular to the line that goes to $p:

my $u = $l1 - $l0; # line direction

my $n = $p - $l0;
$n -= ($u * $n)/($u * $u) * $u;

# the distance is the length of the vector:

printf "The distance between the point %s and the line [%s - %s] is %g\n",
    $p, $l0, $l1, abs($n)
