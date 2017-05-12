#!/usr/bin/perl -w

use strict;
use Test::More tests => 2;

use Graph::Subgraph;

my $G = Graph->new(directed=>0, vertices => [1..5]);

is ($G->subgraph, "", "no args => empty subgraph");

is ($G->subgraph(1..3), $G->subgraph([1..3]), "list == 1 array arg");


