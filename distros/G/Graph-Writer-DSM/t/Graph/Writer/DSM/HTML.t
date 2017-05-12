package Test::Graph::Writer::DSM::HTML;
use parent qw(t::Graph::Writer::DSM::Test);
use Test::Most 'no_plan';
use Test::File;
use Graph;

BEGIN {
  use_ok 'Graph::Writer::DSM::HTML';
};

sub test_constructor : Tests {
  my $writer = Graph::Writer::DSM::HTML->new;
  isa_ok($writer, 'Graph::Writer::DSM::HTML');
}

sub write_output_file : Tests {
  my $graph = Graph->new;
  $graph->add_vertex('A');
  $graph->add_vertex('B');
  $graph->add_edge('A', 'B');
  my $writer = Graph::Writer::DSM::HTML->new;
  $writer->write_graph($graph, "output.html");
  file_exists_ok "output.html";
}

sub output_file_isnt_empty : Tests {
  my $graph = Graph->new;
  $graph->add_vertex('A');
  $graph->add_vertex('B');
  $graph->add_edge('A', 'B');
  my $writer = Graph::Writer::DSM::HTML->new;
  $writer->write_graph($graph, "output.html");
  file_not_empty_ok "output.html";
}

sub set_the_title_of_page : Tests {
  my $graph = Graph->new;
  $graph->add_vertex('A');
  $graph->add_vertex('B');
  $graph->add_edge('A', 'B');
  my $writer = Graph::Writer::DSM::HTML->new(title => 'Testing G::W::DSM::HTML');
  $writer->write_graph($graph, "output.html");
  file_contains_like "output.html", qr|<title>Testing G::W::DSM::HTML</title>|;
}

sub default_title_of_page : Tests {
  my $graph = Graph->new;
  $graph->add_vertex('A');
  $graph->add_vertex('B');
  $graph->add_edge('A', 'B');
  my $writer = Graph::Writer::DSM::HTML->new;
  $writer->write_graph($graph, "output.html");
  file_contains_like "output.html", qr|<title>Design Structure Matrix</title>|;
}
