#!/usr/bin/env perl
use 5.024000;
use strict;
use warnings;
use Graph::Feather;

my $g = Graph::Feather->new;

$g->add_edge("Foo", "Bar");
$g->add_edge("Baz", "Foo");

say for $g->vertices;

