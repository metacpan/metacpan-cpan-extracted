#!/usr/bin/perl -w

use strict;
use Test::More;

use Graph::Subgraph;

plan tests => 10;

my $G = Graph->new(); # directed graph
my $U = Graph::Undirected->new();

# check copying directedness
ok ($G->subgraph([])->is_directed, "empty directed");
ok (!$U->subgraph([])->is_directed, "empty undirected");

note "Directed graph simple checks:";
$G->add_edges(qw(x y y z q p));

is ($G->subgraph([ $G->vertices ]), $G, "Full subgraph");
unlike ($G->subgraph([ $G->vertices ], []), qr([-=]), "unconnected-src");
unlike ($G->subgraph([], [ $G->vertices ]), qr([-=]), "unconnected-dst");
is ($G->subgraph(['x', 'z'], [qw(x y z t p q)]), 'x-y,p,q,z', "Only one edge");


note "Undirected graph simple checks:";
$U->add_edges(qw(x y y z q p));

is ($U->subgraph([ $U->vertices ]), $U, "Full subgraph");
unlike ($U->subgraph([ $U->vertices ], []), qr([-=]), "unconnected-src");
unlike ($U->subgraph([], [ $U->vertices ]), qr([-=]), "unconnected-dst");
is ($U->subgraph(['x', 'z'], [qw(x y z t p q)]), 'x=y,y=z,p,q',
	"Now two edges");



