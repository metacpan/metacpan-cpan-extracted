#!/usr/bin/perl -w
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 11_NodeEdgeRepulsion.t'

use strict;
use warnings;
BEGIN { $^W = 1 };
use Test::More "no_plan";

BEGIN { use_ok('Graph::Layout::Aesthetic') };
BEGIN { use_ok('Graph::Layout::Aesthetic::Topology') };

my $topo = Graph::Layout::Aesthetic::Topology->new_vertices(3);
$topo->add_edge(0, 1);
$topo->finish;

my $aglo = Graph::Layout::Aesthetic->new($topo);
$aglo->add_force("NodeEdgeRepulsion");
my @forces = $aglo->forces;
is(@forces, 1, "Only one force");
isa_ok($forces[0][0], "Graph::Layout::Aesthetic::Force::NodeEdgeRepulsion");
is($forces[0][1], 1, "Unit weight");
is($forces[0][0]->name, "NodeEdgeRepulsion", "Right name");

$aglo->all_coordinates([0, 0], [0, 2], [1, 1]);
is_deeply(scalar $aglo->gradient, [[-1/2, 0], [-1/2, 0], [1, 0]]);

$aglo->all_coordinates([0, 0], [2, 0], [1, 1]);
is_deeply(scalar $aglo->gradient, [[0, -1/2], [0, -1/2], [0, 1]]);

$aglo->all_coordinates([0, 0], [0, 4], [2, 2]);
is_deeply(scalar $aglo->gradient, [[-1/4, 0], [-1/4, 0], [1/2, 0]]);

$aglo->all_coordinates([0, 0], [0, 1], [1/2, 1/2]);
is_deeply(scalar $aglo->gradient, [[-1, 0], [-1, 0], [2, 0]]);

$aglo->all_coordinates([0, 0], [0, 2], [1, 3]);
is_deeply(scalar $aglo->gradient, [([0, 0]) x 3]);

$aglo->all_coordinates(([0, 0]) x 3);
is_deeply(scalar $aglo->gradient, [([0, 0]) x 3],
          "No force explosion on point collapse");
