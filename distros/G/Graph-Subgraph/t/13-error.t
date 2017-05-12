#!/usr/bin/perl -w

use strict;
use Test::More tests => 4;
use Test::Exception;

use Graph::Subgraph;

my $G = Graph->new;


dies_ok {
	$G->subgraph([], [], []);
} "too many args";
note $@;

dies_ok {
	$G->subgraph([], {});
} "wrong args - []{}";

dies_ok {
	$G->subgraph({}, []);
} "wrong args - {}[]";

dies_ok {
	$G->subgraph([], "hello");
} "wrong args - scalar";
