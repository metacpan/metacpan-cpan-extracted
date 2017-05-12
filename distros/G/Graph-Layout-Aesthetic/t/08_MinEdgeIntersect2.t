#!/usr/bin/perl -w
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 08_MinEdgeIntersect2.t.t'

use strict;
use warnings;
BEGIN { $^W = 1 };
use Test::More "no_plan";

BEGIN { use_ok('Graph::Layout::Aesthetic') };
BEGIN { use_ok('Graph::Layout::Aesthetic::Topology') };

my $topo = Graph::Layout::Aesthetic::Topology->new_vertices(4);
$topo->add_edge(0, 1);
$topo->add_edge(2, 3);
$topo->finish;

my $aglo = Graph::Layout::Aesthetic->new($topo, 3);
eval { $aglo->add_force("MinEdgeIntersect2") };
like($@, qr!^MinEdgeIntersect2 only works in 2 dimensions, not 3 at !,
     "Not allowed in three dimensions");
$aglo = Graph::Layout::Aesthetic->new($topo);
$aglo->add_force("MinEdgeIntersect2");
my @forces = $aglo->forces;
is(@forces, 1, "Only one force");
isa_ok($forces[0][0], "Graph::Layout::Aesthetic::Force::MinEdgeIntersect2");
is($forces[0][1], 1, "Unit weight");
is($forces[0][0]->name, "MinEdgeIntersect2", "Right name");

$aglo->all_coordinates([0, -1], [0, 1], [1, -1], [1, 1]);
is_deeply(scalar $aglo->gradient, [([0, 0])x4], "No force if no intersect");
$aglo->all_coordinates([-1, 0], [3, 0], [0, -1], [0, 3]);
is_deeply(scalar $aglo->gradient, [([1, -1]) x 2, ([-1, 1]) x 2]);
$aglo->all_coordinates([-2, 0], [6, 0], [0, -2], [0, 6]);
is_deeply(scalar $aglo->gradient, [([2, -2]) x 2, ([-2, 2]) x 2]);
