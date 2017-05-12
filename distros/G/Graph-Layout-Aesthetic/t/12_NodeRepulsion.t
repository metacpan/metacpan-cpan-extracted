#!/usr/bin/perl -w
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 12_NodeRepulsion.t'

use strict;
use warnings;
BEGIN { $^W = 1 };
use Test::More "no_plan";

BEGIN { use_ok('Graph::Layout::Aesthetic') };
BEGIN { use_ok('Graph::Layout::Aesthetic::Topology') };

my $topo = Graph::Layout::Aesthetic::Topology->new_vertices(2);
# $topo->add_edge(0, 1);
$topo->finish;

my $aglo = Graph::Layout::Aesthetic->new($topo);
$aglo->add_force("NodeRepulsion");
my @forces = $aglo->forces;
is(@forces, 1, "Only one force");
isa_ok($forces[0][0], "Graph::Layout::Aesthetic::Force::NodeRepulsion");
is($forces[0][1], 1, "Unit weight");
is($forces[0][0]->name, "NodeRepulsion", "Right name");

$aglo->all_coordinates([0, -1], [0, 1]);
is_deeply(scalar $aglo->gradient, [[0, -1/2], [0, 1/2]]);

$aglo->all_coordinates([0, -2], [0, 2]);
is_deeply(scalar $aglo->gradient, [[0, -1/4], [0, 1/4]]);

$aglo->all_coordinates([0, -1/2], [0, 1/2]);
is_deeply(scalar $aglo->gradient, [[0, -1], [0, 1]]);

$aglo->all_coordinates([-1/2, 0], [1/2, 0]);
is_deeply(scalar $aglo->gradient, [[-1, 0], [1, 0]]);

$aglo->all_coordinates(([0, 0]) x 2);
is_deeply(scalar $aglo->gradient, [([0, 0]) x 2],
          "No force explosion on point collapse");
