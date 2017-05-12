package Test::Graph::Writer::DSM;
use parent qw(t::Graph::Writer::DSM::Test);
use Test::Most 'no_plan';
use Test::File;
use Graph;

BEGIN {
  use_ok 'Graph::Writer::DSM';
};

sub test_constructor : Tests {
  my $writer = Graph::Writer::DSM->new;
  isa_ok($writer, 'Graph::Writer::DSM');
}

sub write_output_file : Tests {
  my $graph = Graph->new;
  $graph->add_vertex('A');
  $graph->add_vertex('B');
  $graph->add_vertex('C');
  $graph->add_edge('A', 'B');
  $graph->add_edge('A', 'C');
  my $writer = Graph::Writer::DSM->new;
  $writer->write_graph($graph, "output.png");
  file_exists_ok "output.png";
}

sub output_file_isnt_empty : Tests {
  my $self = shift;
  return diag('gnuplot not found')
    unless $self->can_run('gnuplot');
  my $graph = Graph->new;
  $graph->add_vertex('A');
  $graph->add_vertex('B');
  $graph->add_vertex('C');
  $graph->add_edge('A', 'B');
  $graph->add_edge('A', 'C');
  my $writer = Graph::Writer::DSM->new;
  $writer->write_graph($graph, "output.png");
  file_not_empty_ok "output.png";
}
