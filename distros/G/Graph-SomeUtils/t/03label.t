
use Test::More tests => 2;
use Graph::SomeUtils ':all';
use Graph::Directed;
use Graph::Undirected;
use strict;
use warnings;

while (1) {
  my $g = Graph->random_graph(
    vertices => int(rand(70)),
    edges_fill => rand(),
  );
  next unless $g->vertices;
  my $v = $g->random_vertex;
  graph_set_vertex_label($g, $v, 'example');
  is(graph_get_vertex_label($g, $v), 'example');
  is($g->get_vertex_attribute($v, 'label'), 'example');
  last;
}
