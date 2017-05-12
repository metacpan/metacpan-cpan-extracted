
use Test::More tests => 40;
use Graph::SomeUtils ':all';
use Graph::Directed;
use Graph::Undirected;

for my $class (qw/Graph::Directed Graph::Undirected/) {
  for (1 .. 20) {
    my $g0 = $class->random_graph(
      vertices => int(rand(70)),
      edges_fill => rand(),
    );
    
    my $g1 = $g0->copy_graph;
    
    my @vertices = map {
      
      $g0->vertices ? $g0->random_vertex : ()
      
    } 0 .. int(rand(scalar $g0->vertices));

    $g0->delete_vertices(@vertices);
    graph_delete_vertices_fast($g1, @vertices);

    ok($g0 eq $g1);
  }
}
