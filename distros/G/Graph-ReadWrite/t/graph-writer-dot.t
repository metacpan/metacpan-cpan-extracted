use strict;
use Test::More 'no_plan';
use Graph;
use Graph::Writer::Dot;
use File::Temp qw(tempfile);

{ # clustering by 'group'
  my $graph = Graph->new();
  $graph->add_edge('function1' => 'function2');
  $graph->set_vertex_attribute('function1', 'group', 'cluster1.c');
  my ($OUTPUT_FH, $OUTPUT_NAME) = tempfile();
  my $writer = Graph::Writer::Dot->new(cluster => 'group');
  $writer->write_graph($graph, $OUTPUT_FH);
  open $OUTPUT_FH, '<', $OUTPUT_NAME;
  $/ = undef;
  my $OUTPUT = <$OUTPUT_FH>;
  close $OUTPUT_FH;
  unlink $OUTPUT_NAME;

  is(
    $OUTPUT,
    'digraph g
{

  /* list of nodes */
  "function1" [group="cluster1.c"];
  "function2";

  /* list of subgraphs */
  subgraph "cluster_cluster1.c" {
    label = "cluster1.c";
    node [label="function1"] "function1";
  }

  /* list of edges */
  "function1" -> "function2";
}
',
    "must output a single cluster");
}

{ # two clusters in order
  my $graph = Graph->new();
  $graph->add_edge('function1' => 'function2');
  $graph->set_vertex_attribute('function1', 'group', 'cluster1.c');
  $graph->add_edge('function1' => 'function3');
  $graph->set_vertex_attribute('function2', 'group', 'cluster2.c');
  $graph->set_vertex_attribute('function3', 'group', 'cluster2.c');
  my ($OUTPUT_FH, $OUTPUT_NAME) = tempfile();
  my $writer = Graph::Writer::Dot->new(cluster => 'group');
  $writer->write_graph($graph, $OUTPUT_FH);
  open $OUTPUT_FH, '<', $OUTPUT_NAME;
  $/ = undef;
  my $OUTPUT = <$OUTPUT_FH>;
  close $OUTPUT_FH;
  unlink $OUTPUT_NAME;
  is(
    $OUTPUT,
    'digraph g
{

  /* list of nodes */
  "function1" [group="cluster1.c"];
  "function2" [group="cluster2.c"];
  "function3" [group="cluster2.c"];

  /* list of subgraphs */
  subgraph "cluster_cluster1.c" {
    label = "cluster1.c";
    node [label="function1"] "function1";
  }
  subgraph "cluster_cluster2.c" {
    label = "cluster2.c";
    node [label="function2"] "function2";
    node [label="function3"] "function3";
  }

  /* list of edges */
  "function1" -> "function2";
  "function1" -> "function3";
}
',
    "must add two clusters in lexicographic order"
  );
}

{ # clustering by 'color'
  my $graph = Graph->new();
  $graph->add_edge('a' => 'b');
  $graph->add_edge('b' => 'c');
  $graph->add_edge('b' => 'd');
  $graph->set_vertex_attribute('a', 'color', 'blue');
  $graph->set_vertex_attribute('b', 'color', 'blue');
  $graph->set_vertex_attribute('c', 'color', 'red');
  $graph->set_vertex_attribute('d', 'color', 'red');
  my ($OUTPUT_FH, $OUTPUT_NAME) = tempfile();
  my $writer = Graph::Writer::Dot->new(cluster => 'color');
  $writer->write_graph($graph, $OUTPUT_FH);
  open $OUTPUT_FH, '<', $OUTPUT_NAME;
  $/ = undef;
  my $OUTPUT = <$OUTPUT_FH>;
  close $OUTPUT_FH;
  unlink $OUTPUT_NAME;

  is(
    $OUTPUT,
    'digraph g
{

  /* list of nodes */
  "a" [color="blue"];
  "b" [color="blue"];
  "c" [color="red"];
  "d" [color="red"];

  /* list of subgraphs */
  subgraph "cluster_blue" {
    label = "blue";
    node [label="a"] "a";
    node [label="b"] "b";
  }
  subgraph "cluster_red" {
    label = "red";
    node [label="c"] "c";
    node [label="d"] "d";
  }

  /* list of edges */
  "a" -> "b";
  "b" -> "c";
  "b" -> "d";
}
',
    "must cluster by color attribute");
}

{ # cluster only with a valid attribute
  my $graph = Graph->new();
  $graph->add_edge('a' => 'b');
  $graph->add_edge('a' => 'c');
  $graph->set_vertex_attribute('a', 'invalid_attr', 'value_attr');
  $graph->set_vertex_attribute('b', 'invalid_attr', 'value_attr');
  my ($OUTPUT_FH, $OUTPUT_NAME) = tempfile();
  my $writer = Graph::Writer::Dot->new(cluster => 'invalid_attr');
  $writer->write_graph($graph, $OUTPUT_FH);
  open $OUTPUT_FH, '<', $OUTPUT_NAME;
  $/ = undef;
  my $OUTPUT = <$OUTPUT_FH>;
  close $OUTPUT_FH;
  unlink $OUTPUT_NAME;

  is(
    $OUTPUT,
    'digraph g
{

  /* list of nodes */
  "a";
  "b";
  "c";

  /* list of edges */
  "a" -> "b";
  "a" -> "c";
}
',
    "do not cluster with invalid attribute");
}
