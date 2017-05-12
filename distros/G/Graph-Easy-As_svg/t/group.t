#!/usr/bin/env perl

# Test group output

use Test::More;
use strict;

BEGIN
   {
   plan tests => 9;
   chdir 't' if -d 't';
   use lib '../lib';
   use_ok ("Graph::Easy") or die($@);
   };

use Graph::Easy::Edge::Cell qw/EDGE_END_E EDGE_END_N EDGE_END_S EDGE_END_W EDGE_HOR/;

#############################################################################
my $graph = Graph::Easy->new();

is (ref($graph), 'Graph::Easy');

is ($graph->error(), '', 'no error yet');

# this will load As_svg:
my $svg = $graph->as_svg();

#############################################################################
# add a group and three nodes, one invisible

my $group = $graph->add_group('Cities');

my $last;
for my $name (qw/Bonn Berlin Rostock/)
  {
  my $node = $graph->add_node($name);
  $node->set_attribute('shape','invisible') if $name eq 'Rostock';
  $group->add_node($node);
  $graph->add_edge($last,$node) if defined $last;
  $last = $node;
  }

$group->add_node( $graph->add_node('Wismut') );
$graph->add_edge('Berlin','Wismut');

$svg = $graph->as_svg();

like ($svg, qr/Bonn/, 'contains Bonn');
like ($svg, qr/Wismut/, 'contains Wismut');
like ($svg, qr/Berlin/, 'contains Berlin');
unlike ($svg, qr/Rostock<\/text/, "doesn't contains invisible Rostock");

like ($svg, qr/<line x1=".*stroke-dasharray="6,\s*2/, 'contains some border');
like ($svg, qr/<rect .*stroke="none"/, 'contains a rect with no stroke for edge backgrounds');

