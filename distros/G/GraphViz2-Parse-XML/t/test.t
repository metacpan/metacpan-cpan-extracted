use strict;
use warnings;
use Test::More;

use GraphViz2;
use GraphViz2::Parse::XML;
use File::Spec;

my $g_xml = GraphViz2::Parse::XML->new;
$g_xml->create(file_name => File::Spec->catfile('t', 'sample.xml') );

my $g = $g_xml->graph;
my $node_rect = { attributes => { shape => 'rectangle' } };
my $node_empty = { attributes => {} };
is_deeply_dump($g->node_hash, {
  3163 => $node_rect,
  Australia => $node_rect,
  Murrumbeena => $node_rect,
  Ron => $node_rect,
  Savage => $node_rect,
  Victoria => $node_rect,
  address => $node_empty,
  city => $node_empty,
  country => $node_empty,
  given_name => $node_empty,
  locality => $node_empty,
  name => $node_empty,
  person => $node_empty,
  postcode => $node_empty,
  state => $node_empty,
  surname => $node_empty,
}, 'nodes');
my $empty_edge = [ { attributes => {}, from_port => '', to_port => '' } ];
is_deeply_dump($g->edge_hash, {
  address => { city => $empty_edge, country => $empty_edge, state => $empty_edge },
  city => { locality => $empty_edge, postcode => $empty_edge },
  country => { Australia => $empty_edge },
  given_name => { Ron => $empty_edge },
  locality => { Murrumbeena => $empty_edge },
  name => { given_name => $empty_edge, surname => $empty_edge },
  person => { address => $empty_edge, name => $empty_edge },
  postcode => { 3163 => $empty_edge },
  state => { Victoria => $empty_edge },
  surname => { Savage => $empty_edge },
}, 'edges');

sub is_deeply_dump {
  my ($got, $expected, $label) = @_;
  is_deeply $got, $expected, $label or diag explain $got;
}

done_testing;
