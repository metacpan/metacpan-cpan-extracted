#!/usr/bin/perl -w

# test quoting of special characters

use Test::More;
use strict;

BEGIN
   {
   plan tests => 16;
   chdir 't' if -d 't';
   use lib '../lib';
   use_ok ("Graph::Regexp") or die($@);
   };

#############################################################################
# inputs:

my $dollar = <<EOF
   1: EXACT <\$>(3)
   3: END(0)
EOF
;
my $specials = <<EOS
   1: EXACT <\$\@>(3)
   3: END(0)
EOS
;
my $right = <<EOR
   1: EXACT <>>(3)
   3: END(0)
EOR
;

#############################################################################
# tests

my $graph = Graph::Regexp->graph( \$dollar );

is (ref($graph), 'Graph::Easy');

is ($graph->error(), '', 'no error yet');

is (scalar $graph->nodes(), 4, '4 node (start -> $ -> success)');
is (scalar $graph->edges(), 3, '3 edges (start -> $ -> success)');

is ($graph->node('1')->label(), '"\$"', '"\\$"');

$graph = Graph::Regexp->graph( \$specials );

is (ref($graph), 'Graph::Easy');

is ($graph->error(), '', 'no error yet');

is (scalar $graph->nodes(), 4, '4 node (start -> $@ -> success)');
is (scalar $graph->edges(), 3, '3 edges (start -> $@ -> success)');

is ($graph->node('1')->label(), '"\$\@"', '"\\$\\@"');

$graph = Graph::Regexp->graph( \$right );

is (ref($graph), 'Graph::Easy');

is ($graph->error(), '', 'no error yet');

is (scalar $graph->nodes(), 4, '4 node (start -> ">" -> success)');
is (scalar $graph->edges(), 3, '3 edges (start -> ">" -> success)');

is ($graph->node('1')->label(), '">"', '">"');

