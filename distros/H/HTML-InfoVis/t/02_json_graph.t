#!/usr/bin/perl

# Test generating a JSON structure loadable as a graph

use 5.006;
use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 2;
use HTML::InfoVis;

my $graph = HTML::InfoVis::Graph->new;
isa_ok( $graph, 'HTML::InfoVis::Graph' );
$graph->add_edge('foo' => 'bar');

my $json = $graph->as_json;
is( $json, <<'END_JSON', '->as_json ok' );
[
   {
      "adjacencies" : [],
      "id" : "bar",
      "name" : "bar"
   },
   {
      "adjacencies" : [
         "bar"
      ],
      "id" : "foo",
      "name" : "foo"
   }
]
END_JSON
