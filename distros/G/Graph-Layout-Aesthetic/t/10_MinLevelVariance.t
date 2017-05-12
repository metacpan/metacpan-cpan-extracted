#!/usr/bin/perl -w
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 10_MinLevelVariance.t'

use strict;
use warnings;
BEGIN { $^W = 1 };
use Test::More "no_plan";

BEGIN { use_ok('Graph::Layout::Aesthetic') };
BEGIN { use_ok('Graph::Layout::Aesthetic::Topology') };

my $topo = Graph::Layout::Aesthetic::Topology->new_vertices(4);
$topo->add_edge(0, 2);
$topo->add_edge(0, 3);
$topo->add_edge(1, 2);
$topo->add_edge(1, 3);
$topo->finish;
is_deeply([$topo->levels], [0, 0, 1, 1]);

my $aglo = Graph::Layout::Aesthetic->new($topo);
$aglo->add_force("MinLevelVariance");
my @forces = $aglo->forces;
is(@forces, 1, "Only one force");
isa_ok($forces[0][0], "Graph::Layout::Aesthetic::Force::MinLevelVariance");
is($forces[0][1], 1, "Unit weight");
is($forces[0][0]->name, "MinLevelVariance", "Right name");

$aglo->all_coordinates([0, 0], [0, 1], [1, 0], [1, 1]);
is_deeply(scalar $aglo->gradient, [([0, 0]) x 4]);

$aglo->all_coordinates([0, 0], [0, 1], [1, 1], [1, 0]);
is_deeply(scalar $aglo->gradient, [([0, 0]) x 4]);

$aglo->all_coordinates([0, 0], [1, 0], [0, 1], [1, 1]);
is_deeply(scalar $aglo->gradient, [[1/8, 0], [-1/8, 0], [1/8, 0], [-1/8, 0]]);

$aglo->all_coordinates([0, 0], [2, 0], [0, 2], [2, 2]);
is_deeply(scalar $aglo->gradient, [[1, 0], [-1, 0], [1, 0], [-1, 0]]);

$aglo->all_coordinates(([0, 0]) x 4);
is_deeply(scalar $aglo->gradient, [([0, 0]) x 4],
          "No force explosion on point collapse");
