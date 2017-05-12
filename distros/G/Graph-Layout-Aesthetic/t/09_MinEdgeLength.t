#!/usr/bin/perl -w
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 09_MinEdgeLength.t'

use strict;
use warnings;
BEGIN { $^W = 1 };
use Test::More "no_plan";

BEGIN { use_ok('Graph::Layout::Aesthetic') };
BEGIN { use_ok('Graph::Layout::Aesthetic::Topology') };

my $topo = Graph::Layout::Aesthetic::Topology->new_vertices(2);
$topo->add_edge(0, 1);
$topo->finish;

my $aglo = Graph::Layout::Aesthetic->new($topo);
$aglo->add_force("MinEdgeLength");
my @forces = $aglo->forces;
is(@forces, 1, "Only one force");
isa_ok($forces[0][0], "Graph::Layout::Aesthetic::Force::MinEdgeLength");
is($forces[0][1], 1, "Unit weight");
is($forces[0][0]->name, "MinEdgeLength", "Right name");

$aglo->all_coordinates([0, -1], [0, 1]);
is_deeply(scalar $aglo->gradient, [[0, 4], [0, -4]]);

# This implicitely tests if all_coordinates updates the sequence number
$aglo->all_coordinates([1, -1], [1, 1]);
is_deeply(scalar $aglo->gradient, [[0, 4], [0, -4]]);

# This implicitely tests if coordinates updates the sequence number
$aglo->coordinates(0, 0, -2);
$aglo->coordinates(1, 0,  2);
is_deeply(scalar $aglo->gradient, [[0, 16], [0, -16]]);

$aglo->all_coordinates([-1/2, 0], [1/2, 0]);
is_deeply(scalar $aglo->gradient, [[1, 0], [-1, 0]]);

$aglo->all_coordinates(([0, 0]) x 2);
is_deeply(scalar $aglo->gradient, [([0, 0]) x 2],
          "No force explosion on point collapse");
