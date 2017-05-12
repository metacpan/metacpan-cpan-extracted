#!/usr/bin/env perl -w

use strict;
use blib;
use Test::Simple tests => 1;
use IO::All;
use Graph;
use Graph::Writer::GraphViz;

my @v = qw/Alice Bob Crude Dr/;
my $g = Graph->new;
$g->add_vertices(@v);

my $wr = Graph::Writer::GraphViz->new(-format => 'dot');
$wr->write_graph($g,'t/graph.simple.dot');

$/ = undef;
my $g1 = <DATA>;
my $g2 = io('t/graph.simple.dot')->slurp;
# Ignore font-sizes, it's system-dependant
$g1 =~ s/\d+/0/g;
$g2 =~ s/\d+/0/g;
ok($g1 eq $g2);
unlink('t/graph.simple.dot');

__DATA__
digraph test {
	graph [ratio=fill];
	node [label="\N", color=black];
	edge [color=black];
	graph [bb="0,0,290,52"];
	Bob [label=Bob, pos="27,26", width="0.75", height="0.50"];
	Dr [label=Dr, pos="99,26", width="0.75", height="0.50"];
	Alice [label=Alice, pos="174,26", width="0.83", height="0.50"];
	Crude [label=Crude, pos="256,26", width="0.94", height="0.50"];
}
