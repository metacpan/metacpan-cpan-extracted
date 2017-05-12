#!/usr/bin/env perl
use strict;
use warnings;

use Test::More tests => 11;

use Graph::Fast;

my $g = Graph::Fast->new();

is($g->count_edges()   , 0, "no edges");
is($g->count_vertices(), 0, "no vertices");

# should create missing vertices
$g->add_edge("A", "B", 5);
is($g->count_edges(),    1, "one edge in graph");
is($g->count_vertices(), 2, "two vertices in graph");

# shouldn't delete the vertices but just the edge
$g->del_edge("A", "B");
is($g->count_edges(),    0, "no edges in graph");
is($g->count_vertices(), 2, "still two vertices in graph");

# recreate the edge and a second one in the opposite direction
# - it shouldn't be deleted.
$g->add_edge("A", "B", 2);
$g->add_edge("B", "A", 3);
$g->del_edge("A", "B");
is($g->count_edges(),    1, "one edge in graph");
is($g->count_vertices(), 2, "two vertices in graph");
# for lack of a better interface, we peek into fastgraph's guts.
is($g->{edges}->[0]->{from}  , "B", "remaining edge's source vertex is B");
is($g->{edges}->[0]->{to}    , "A", "remaining edge's destination vertex is A");
is($g->{edges}->[0]->{weight},  3 , "remaining edge's weight is 3");
