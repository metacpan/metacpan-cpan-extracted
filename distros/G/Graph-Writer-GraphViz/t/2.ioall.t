#!/usr/bin/env perl -w

use strict;
use Test::Simple tests => 1;
use IO::All;
use Graph;
use Graph::Writer::GraphViz;

my @v = qw/Alice Bob Crude Dr/;
my $g = Graph->new;
$g->add_vertices(@v);

my $wr = Graph::Writer::GraphViz->new(-format => 'dot');
my $io = io('t/graph.ioall.dot')->mode('w+')->assert;
$wr->write_graph($g, $io );

ok(-f 't/graph.ioall.dot');

$io->unlink;

