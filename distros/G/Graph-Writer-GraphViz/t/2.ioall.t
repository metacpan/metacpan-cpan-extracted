#!/usr/bin/env perl -w

use strict;
use blib;
use Test::Simple tests => 2;
use IO::All;
use Graph;
use Graph::Writer::GraphViz;

my @v = qw/Alice Bob Crude Dr/;
my $g = Graph->new;
$g->add_vertices(@v);

my $wr = Graph::Writer::GraphViz->new(-format => 'dot');
my $io = io('t/graph.ioall.dot')->mode('w+')->assert;
$wr->write_graph($g, $io );

my ($g1,$g2);
$io->seek(0,0);
$g2 = $io->slurp;

{
    local $/ = undef;
    $g1 = <DATA>;
}

ok(-f 't/graph.ioall.dot');
# Ignore font-sizes, it's system-dependant
$g1 =~ s/\d+/0/g;
$g2 =~ s/\d+/0/g;
ok($g1 eq $g2);
$io->unlink;

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
