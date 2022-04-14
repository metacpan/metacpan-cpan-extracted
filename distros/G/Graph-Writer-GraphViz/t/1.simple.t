#!/usr/bin/env perl -w

use strict;
use Test::Simple tests => 2;
use IO::All;
use Graph;
use Graph::Writer::GraphViz;

sub normalized {
    my $s = shift;
    $s =~ s/\d+/0/g;
    $s =~ s/\s+/ /g;
    return $s;
}

my @v = qw/Alice Bob Crude Dr/;
my $g = Graph->new;
$g->add_vertices(@v);

my $wr = Graph::Writer::GraphViz->new(-format => 'dot');
$wr->write_graph($g,'t/graph.simple.dot');

ok(-f 't/graph.simple.dot');

$/ = undef;
my $g1 = <DATA>;
my $g2 = io('t/graph.simple.dot')->slurp;

$g1 = normalized($g1);
$g2 = normalized($g2);

ok($g1 eq $g2);
unlink('t/graph.simple.dot');

__DATA__
digraph test {
	graph [bb="0,0,285.9,36",
		ratio=fill
	];
	node [color=black,
		label="\N"
	];
	edge [color=black];
	Alice	[height=0.5,
		label=Alice,
		pos="29.897,18",
		width=0.83048];
	Bob	[height=0.5,
		label=Bob,
		pos="104.9,18",
		width=0.75];
	Crude	[height=0.5,
		label=Crude,
		pos="181.9,18",
		width=0.9027];
	Dr	[height=0.5,
		label=Dr,
		pos="258.9,18",
		width=0.75];
}
