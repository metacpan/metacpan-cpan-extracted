#!/usr/bin/perl -w

use strict;
use Test::More tests => 4;

use Graph::Subgraph;

my $G = Graph->new(directed => 0, vertices => [10..20])->complete;
is ($G->subgraph([1..9]), "", "empty subgraph is empty");

is ($G->subgraph([0..4], [5..9]), "", "empty subgraph is empty (2 args)");

is ($G->subgraph([1..100], [0]), join (",", sort $G->vertices), "dotted subgraph 1"); 
is ($G->subgraph([0], [1..100]), join (",", sort $G->vertices), "dotted subgraph 2"); 
