#!/usr/bin/env perl
use strict;
use warnings;

use Test::More tests => 84;

use Graph::Fast;

my $g = Graph::Fast->new();

$g->add_edge("A" => "O", 1);
$g->add_edge("B" => "O", 1);
$g->add_edge("C" => "O", 1);

$g->add_edge("O" => "S", 1);
$g->add_edge("O" => "T", 1);
$g->add_edge("O" => "U", 1);

is($g->count_edges()   , 6, "Six edges");
is($g->count_vertices(), 7, "Seven vertices");

# deletion of central node should delete all edges
$g->del_vertex("O");

is($g->count_edges()   , 0, "No edges");
is($g->count_vertices(), 6, "Six vertices");

is(scalar keys %{$g->{vertices}->{A}->{edges_out}}, 0, "Vertex A has no outgoing edges");
is(scalar keys %{$g->{vertices}->{B}->{edges_out}}, 0, "Vertex B has no outgoing edges");
is(scalar keys %{$g->{vertices}->{C}->{edges_out}}, 0, "Vertex C has no outgoing edges");

is(scalar keys %{$g->{vertices}->{S}->{edges_in}}, 0, "Vertex S has no incoming edges");
is(scalar keys %{$g->{vertices}->{T}->{edges_in}}, 0, "Vertex T has no incoming edges");
is(scalar keys %{$g->{vertices}->{U}->{edges_in}}, 0, "Vertex U has no incoming edges");

# reconnect nodes
$g->add_edge("A" => "O", 1);
$g->add_edge("B" => "O", 1);
$g->add_edge("C" => "O", 1);

$g->add_edge("O" => "S", 1);
$g->add_edge("O" => "T", 1);
$g->add_edge("O" => "U", 1);

# counts should now be correct again
is($g->count_edges()   , 6, "Six edges");
is($g->count_vertices(), 7, "Seven vertices");

# check in/out edge counts
is(scalar keys %{$g->{vertices}->{O}->{edges_in }}, 3, "Vertex O has 3 incoming edges");
is(scalar keys %{$g->{vertices}->{O}->{edges_out}}, 3, "Vertex O has 3 outgoing edges");

is(scalar keys %{$g->{vertices}->{A}->{edges_in }}, 0, "Vertex A has no  incoming edges");
is(scalar keys %{$g->{vertices}->{A}->{edges_out}}, 1, "Vertex A has one outgoing edge");
is(scalar keys %{$g->{vertices}->{B}->{edges_in }}, 0, "Vertex B has no  incoming edges");
is(scalar keys %{$g->{vertices}->{B}->{edges_out}}, 1, "Vertex B has one outgoing edge");
is(scalar keys %{$g->{vertices}->{C}->{edges_in }}, 0, "Vertex C has no  incoming edges");
is(scalar keys %{$g->{vertices}->{C}->{edges_out}}, 1, "Vertex C has one outgoing edge");

is(scalar keys %{$g->{vertices}->{S}->{edges_in }}, 1, "Vertex S has one incoming edge");
is(scalar keys %{$g->{vertices}->{S}->{edges_out}}, 0, "Vertex S has no  outgoing edges");
is(scalar keys %{$g->{vertices}->{T}->{edges_in }}, 1, "Vertex T has one incoming edge");
is(scalar keys %{$g->{vertices}->{T}->{edges_out}}, 0, "Vertex T has no  outgoing edges");
is(scalar keys %{$g->{vertices}->{U}->{edges_in }}, 1, "Vertex U has one incoming edge");
is(scalar keys %{$g->{vertices}->{U}->{edges_out}}, 0, "Vertex U has no  outgoing edges");

# delete a node again
$g->del_vertex("B");

is($g->count_edges()   , 5, "Five edges");
is($g->count_vertices(), 6, "Six vertices");

# check counts
is(scalar keys %{$g->{vertices}->{O}->{edges_in }}, 2, "Vertex O has 2 incoming edges");
is(scalar keys %{$g->{vertices}->{O}->{edges_out}}, 3, "Vertex O has 3 outgoing edges");

is(scalar keys %{$g->{vertices}->{A}->{edges_in }}, 0, "Vertex A has no  incoming edges");
is(scalar keys %{$g->{vertices}->{A}->{edges_out}}, 1, "Vertex A has one outgoing edge");
is(scalar keys %{$g->{vertices}->{C}->{edges_in }}, 0, "Vertex C has no  incoming edges");
is(scalar keys %{$g->{vertices}->{C}->{edges_out}}, 1, "Vertex C has one outgoing edge");

is(scalar keys %{$g->{vertices}->{S}->{edges_in }}, 1, "Vertex S has one incoming edge");
is(scalar keys %{$g->{vertices}->{S}->{edges_out}}, 0, "Vertex S has no  outgoing edges");
is(scalar keys %{$g->{vertices}->{T}->{edges_in }}, 1, "Vertex T has one incoming edge");
is(scalar keys %{$g->{vertices}->{T}->{edges_out}}, 0, "Vertex T has no  outgoing edges");
is(scalar keys %{$g->{vertices}->{U}->{edges_in }}, 1, "Vertex U has one incoming edge");
is(scalar keys %{$g->{vertices}->{U}->{edges_out}}, 0, "Vertex U has no  outgoing edges");

# delete another node
$g->del_vertex("S");

is($g->count_edges()   , 4, "Four edges");
is($g->count_vertices(), 5, "Five vertices");

# check counts
is(scalar keys %{$g->{vertices}->{O}->{edges_in }}, 2, "Vertex O has 2 incoming edges");
is(scalar keys %{$g->{vertices}->{O}->{edges_out}}, 2, "Vertex O has 2 outgoing edges");

is(scalar keys %{$g->{vertices}->{A}->{edges_in }}, 0, "Vertex A has no  incoming edges");
is(scalar keys %{$g->{vertices}->{A}->{edges_out}}, 1, "Vertex A has one outgoing edge");
is(scalar keys %{$g->{vertices}->{C}->{edges_in }}, 0, "Vertex C has no  incoming edges");
is(scalar keys %{$g->{vertices}->{C}->{edges_out}}, 1, "Vertex C has one outgoing edge");

is(scalar keys %{$g->{vertices}->{T}->{edges_in }}, 1, "Vertex T has one incoming edge");
is(scalar keys %{$g->{vertices}->{T}->{edges_out}}, 0, "Vertex T has no  outgoing edges");
is(scalar keys %{$g->{vertices}->{U}->{edges_in }}, 1, "Vertex U has one incoming edge");
is(scalar keys %{$g->{vertices}->{U}->{edges_out}}, 0, "Vertex U has no  outgoing edges");

# reconnect
$g->add_edge("B" => "O", 1);
$g->add_edge("O" => "S", 1);

# connect some more
$g->add_edge("C" => "T", 1);

# check
is($g->count_edges()   , 7, "Seven edges");
is($g->count_vertices(), 7, "Seven vertices");

# check in/out edge counts
is(scalar keys %{$g->{vertices}->{O}->{edges_in }}, 3, "Vertex O has 3 incoming edges");
is(scalar keys %{$g->{vertices}->{O}->{edges_out}}, 3, "Vertex O has 3 outgoing edges");

is(scalar keys %{$g->{vertices}->{A}->{edges_in }}, 0, "Vertex A has no  incoming edges");
is(scalar keys %{$g->{vertices}->{A}->{edges_out}}, 1, "Vertex A has one outgoing edge");
is(scalar keys %{$g->{vertices}->{B}->{edges_in }}, 0, "Vertex B has no  incoming edges");
is(scalar keys %{$g->{vertices}->{B}->{edges_out}}, 1, "Vertex B has one outgoing edge");
is(scalar keys %{$g->{vertices}->{C}->{edges_in }}, 0, "Vertex C has no  incoming edges");
is(scalar keys %{$g->{vertices}->{C}->{edges_out}}, 2, "Vertex C has two outgoing edges");

is(scalar keys %{$g->{vertices}->{S}->{edges_in }}, 1, "Vertex S has one incoming edge");
is(scalar keys %{$g->{vertices}->{S}->{edges_out}}, 0, "Vertex S has no  outgoing edges");
is(scalar keys %{$g->{vertices}->{T}->{edges_in }}, 2, "Vertex T has two incoming edges");
is(scalar keys %{$g->{vertices}->{T}->{edges_out}}, 0, "Vertex T has no  outgoing edges");
is(scalar keys %{$g->{vertices}->{U}->{edges_in }}, 1, "Vertex U has one incoming edge");
is(scalar keys %{$g->{vertices}->{U}->{edges_out}}, 0, "Vertex U has no  outgoing edges");

# and more
$g->add_edge("T" => "A", 1);

# check
is($g->count_edges()   , 8, "Eight edges");
is($g->count_vertices(), 7, "Seven vertices");

# check in/out edge counts
is(scalar keys %{$g->{vertices}->{O}->{edges_in }}, 3, "Vertex O has 3 incoming edges");
is(scalar keys %{$g->{vertices}->{O}->{edges_out}}, 3, "Vertex O has 3 outgoing edges");

is(scalar keys %{$g->{vertices}->{A}->{edges_in }}, 1, "Vertex A has one incoming edge");
is(scalar keys %{$g->{vertices}->{A}->{edges_out}}, 1, "Vertex A has one outgoing edge");
is(scalar keys %{$g->{vertices}->{B}->{edges_in }}, 0, "Vertex B has no  incoming edges");
is(scalar keys %{$g->{vertices}->{B}->{edges_out}}, 1, "Vertex B has one outgoing edge");
is(scalar keys %{$g->{vertices}->{C}->{edges_in }}, 0, "Vertex C has no  incoming edges");
is(scalar keys %{$g->{vertices}->{C}->{edges_out}}, 2, "Vertex C has two outgoing edges");

is(scalar keys %{$g->{vertices}->{S}->{edges_in }}, 1, "Vertex S has one incoming edge");
is(scalar keys %{$g->{vertices}->{S}->{edges_out}}, 0, "Vertex S has no  outgoing edges");
is(scalar keys %{$g->{vertices}->{T}->{edges_in }}, 2, "Vertex T has two incoming edges");
is(scalar keys %{$g->{vertices}->{T}->{edges_out}}, 1, "Vertex T has one outgoing edge");
is(scalar keys %{$g->{vertices}->{U}->{edges_in }}, 1, "Vertex U has one incoming edge");
is(scalar keys %{$g->{vertices}->{U}->{edges_out}}, 0, "Vertex U has no  outgoing edges");

