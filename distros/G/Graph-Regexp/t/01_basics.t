#!/usr/bin/perl -w

use Test::More;
use strict;

BEGIN
   {
   plan tests => 12;
   chdir 't' if -d 't';
   use lib '../lib';
   use_ok ("Graph::Regexp") or die($@);
   };

#############################################################################

can_ok ('Graph::Regexp',
  qw/
    new
    graph
    decompose
    reset
    option
    as_ascii
    as_graph
    graph_label
  /);

#############################################################################
# graph() interface

my $slashslash = <<EOF
   1: NOTHING(2)
   2: END(0)
EOF
;

my $graph = Graph::Regexp->graph( \$slashslash );

is (ref($graph), 'Graph::Easy');

is ($graph->error(), '', 'no error yet');

is (scalar $graph->nodes(), 3, '3 node (start -> nothing -> success)');
is (scalar $graph->edges(), 2, '2 edges (start -> nothing -> success)');

#############################################################################
# OO interface

my $grapher = Graph::Regexp->new();

is (ref($grapher), 'Graph::Regexp');

$graph = $grapher->graph( \$slashslash );

is (ref($graph), 'Graph::Easy', 'graph()');
is ($graph->error(), '', 'no error yet');
is (scalar $graph->nodes(), 3, '3 node (start -> nothing -> success)');
is (scalar $graph->edges(), 2, '2 edges (start -> nothing -> success)');

my $flow = $grapher->decompose( \$slashslash );

is (ref($flow), 'Graph::Regexp', 'decompose()');

