#!/usr/bin/perl -w
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 13_ParentLeft.t'

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
$aglo->add_force("ParentLeft");
my @forces = $aglo->forces;
is(@forces, 1, "Only one force");
isa_ok($forces[0][0], "Graph::Layout::Aesthetic::Force::ParentLeft");
is($forces[0][1], 1, "Unit weight");
is($forces[0][0]->name, "ParentLeft", "Right name");

$aglo->all_coordinates([-1, 0], [1, 0]);
is_deeply(scalar $aglo->gradient, [[-9, 0], [9, 0]]);

$aglo->all_coordinates([-1, 5], [1, 8]);
is_deeply(scalar $aglo->gradient, [[-9, 0], [9, 0]], 
          "y-coordinate does not matter");

$aglo->all_coordinates([-5, 0], [5, 0]);
is_deeply(scalar $aglo->gradient, [([0, 0]) x 2], "No force if ordered");

$aglo->all_coordinates([-2, 0], [2, 0]);
is_deeply(scalar $aglo->gradient, [[-1, 0], [1, 0]]);

$aglo->all_coordinates(([0, 0]) x 2);
is_deeply(scalar $aglo->gradient, [[-25, 0], [25, 0]],
          "No force explosion on point collapse");

$aglo->all_coordinates([0, 0], [5, 0]);
is_deeply(scalar $aglo->gradient, [([0, 0]) x 2],
          "No force explosion on displaced point collapse");


