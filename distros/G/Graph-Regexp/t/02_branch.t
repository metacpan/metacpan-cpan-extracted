#!/usr/bin/perl -w

# test branching as in /a|b/, /(a|b)/ etc

use Test::More;
use strict;

BEGIN
   {
   plan tests => 10;
   chdir 't' if -d 't';
   use lib '../lib';
   use_ok ("Graph::Regexp") or die($@);
   };

#############################################################################
# inputs:

my $parens = <<EOF
   1: OPEN1(3)
   3:   BRANCH(6)
   4:     EXACT <a>(9)
   6:   BRANCH(9)
   7:     EXACT <b>(9)
   9: CLOSE1(11)
  11: END(0)
EOF
;

my $noparens = <<EOF
   1: BRANCH(4)
   2:   EXACT <a>(7)
   4: BRANCH(7)
   5:   EXACT <b>(7)
   7: END(0)
EOF
;

#############################################################################
#############################################################################
# tests:

my $graph = Graph::Regexp->graph( \$parens );

is (ref($graph), 'Graph::Easy');

is ($graph->error(), '', 'no error yet');

is (scalar $graph->nodes(), 5, '5 nodes');
is (scalar $graph->edges(), 5, '5 edges');

#############################################################################
# Now with no parens

my $graph_no = Graph::Regexp->graph( \$noparens );

is (ref($graph_no), 'Graph::Easy');

is ($graph_no->error(), '', 'no error yet');

is (scalar $graph_no->nodes(), 5, '5 nodes');
is (scalar $graph_no->edges(), 5, '5 edges');

#############################################################################
# second graph should be equivalent to the first

is ($graph->as_ascii(), $graph_no->as_ascii(), 'graphs are equal');

