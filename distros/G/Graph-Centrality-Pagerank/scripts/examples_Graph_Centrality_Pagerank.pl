#!/usr/bin/env perl

# contains all the examples in the POD documentation for the module.

use strict;
use warnings;
use Carp;

# A rather dull example with one node and no edges:
{
  use Graph;
  use Graph::Centrality::Pagerank;
  use Data::Dump qw(dump);
  my $ranker = Graph::Centrality::Pagerank->new();
  my $listOfNodes = [1];
  dump $ranker->getPagerankOfNodes (listOfNodes => $listOfNodes);
  # dumps:
  # {
  #   1 => 1
  # }
}

# A simple example with two disjoint edges:
{
  use Graph;
  use Graph::Centrality::Pagerank;
  use Data::Dump qw(dump);
  my $ranker = Graph::Centrality::Pagerank->new();
  my $listOfEdges = [[1,2],[3,4]];
  dump $ranker->getPagerankOfNodes (listOfEdges => $listOfEdges);
  # dumps:
  # {
  #   1 => "0.175438596989046",
  #   2 => "0.324561403010954",
  #   3 => "0.175438596989046",
  #   4 => "0.324561403010954",
  # }
}

# In this case the edges are placed in a L<Graph>:
{
  use Graph;
  use Graph::Centrality::Pagerank;
  use Data::Dump qw(dump);
  my $listOfEdges = [[1,2],[3,4]];
  my $graph = Graph->new (edges => $listOfEdges);
  my $ranker = Graph::Centrality::Pagerank->new();
  dump $ranker->getPagerankOfNodes (graph => $graph);
  # dumps:
  # {
  #   1 => "0.175438596989046",
  #   2 => "0.324561403010954",
  #   3 => "0.175438596989046",
  #   4 => "0.324561403010954",
  # }
}

# Below is the first example in the paper
# I<How Google Finds Your Needle in the Web's Haystack> by David Austin.
{
  use Graph;
  use Graph::Centrality::Pagerank;
  use Data::Dump qw(dump);
  my $ranker = Graph::Centrality::Pagerank->new();
  my $listOfEdges = [[1,2],[1,3],[2,4],[3,2],[3,5],[4,2],[4,5],[4,6],[5,6],
    [5,7],[5,8],[6,8],[7,5],[7,1],[7,8],[8,6],[8,7]];
  dump $ranker->getPagerankOfNodes (listOfEdges => $listOfEdges,
    dampeningFactor => 1);
  # dumps:
  # {
  #   1 => "0.0599999994835539",
  #   2 => "0.0675000002254998",
  #   3 => "0.0300000002967361",
  #   4 => "0.0674999997408677",
  #   5 => "0.0974999994123176",
  #   6 => "0.202500001447512",
  #   7 => "0.180000001348251",
  #   8 => "0.294999998045262",
  # }
}

# Below is the second example in the paper. Notice C<linkSinkNodes> has been
# set to zero.
{
  use Graph;
  use Graph::Centrality::Pagerank;
  use Data::Dump qw(dump);
  my $ranker = Graph::Centrality::Pagerank->new();
  my $listOfEdges = [[1,2]];
  dump $ranker->getPagerankOfNodes (listOfEdges => $listOfEdges,
    dampeningFactor => 1, linkSinkNodes => 0);
  # dumps:
  # { 1 => 0, 2 => 0 }
}

# Below is the third example in the paper. Notice
# linkSinkNodes has been set to one, the default value.
{
  use Graph;
  use Graph::Centrality::Pagerank;
  use Data::Dump qw(dump);
  my $ranker = Graph::Centrality::Pagerank->new();
  my $listOfEdges = [[1,2]];
  dump $ranker->getPagerankOfNodes (listOfEdges => $listOfEdges,
    dampeningFactor => 1, linkSinkNodes => 1);
  # dumps:
  # { 1 => "0.33333333209157", 2 => "0.66666666790843" }
}

# Below is the forth example in the paper
# How Google Finds Your Needle in the Web's Haystack by David Austin. The
# result is different from the paper since the starting vector for
# Graph::Centrality::Pagerank is
# { 1 => "0.2", 2 => "0.2", 3 => "0.2", 4 => "0.2", 5 => "0.2" }
# but the starting vector in the paper is
#  { 1 => 1, 2 => 0, 3 => 0, 4 => 0, 5 => 0 }.
{
  use Graph;
  use Graph::Centrality::Pagerank;
  use Data::Dump qw(dump);
  my $ranker = Graph::Centrality::Pagerank->new();
  my $listOfEdges = [[1,2],[2,3],[3,4],[4,5],[5,1]];
  dump $ranker->getPagerankOfNodes (listOfEdges => $listOfEdges,
    dampeningFactor => 1, linkSinkNodes => 0);
  # dumps:
  # { 1 => "0.2", 2 => "0.2", 3 => "0.2", 4 => "0.2", 5 => "0.2" }
}

# Below is the fifth example in the paper
# How Google Finds Your Needle in the Web's Haystack by David Austin.
{
  use Graph;
  use Graph::Centrality::Pagerank;
  use Data::Dump qw(dump);
  my $ranker = Graph::Centrality::Pagerank->new();
  my $listOfEdges = [[1,3],[1,2],[2,4],[3,2],[3,5],[4,2],[4,5],[4,6],[5,6],
    [5,7],[5,8],[6,8],[7,5],[7,8],[8,6],[8,7]];
  dump $ranker->getPagerankOfNodes (listOfEdges => $listOfEdges,
    dampeningFactor => 1, linkSinkNodes => 0);
  # dumps:
  # {
  #   1 => 0,
  #   2 => "2.39601089109228e-54",
  #   3 => 0,
  #   4 => "5.47659632249665e-54",
  #   5 => "0.119999999997811",
  #   6 => "0.240000000003975",
  #   7 => "0.240000000003975",
  #   8 => "0.399999999994238",
  # }
}

# An example of the effect of including edge weights:
{
  use Graph;
  use Graph::Centrality::Pagerank;
  use Data::Dump qw(dump);
  my $ranker = Graph::Centrality::Pagerank->new();
  my $listOfEdges = [[2,1],[2,3]];
  dump $ranker->getPagerankOfNodes (listOfEdges => $listOfEdges);
  $listOfEdges = [[2,1,2],[2,3,1]];
  dump $ranker->getPagerankOfNodes (listOfEdges => $listOfEdges,
    useEdgeWeights => 1);

  # dumps:
  # {
  #   1 => "0.370129870353883",
  #   2 => "0.259740259292235",
  #   3 => "0.370129870353883",
  # }
  # {
  #   1 => "0.406926407374432",
  #   2 => "0.259740259292235",
  #   3 => "0.333333333333333",
  # }
}

# An example of the effect of including node weights:
{
  use Graph;
  use Graph::Centrality::Pagerank;
  use Data::Dump qw(dump);
  my $ranker = Graph::Centrality::Pagerank->new();
  my $listOfEdges = [[1,2],[2,3]];
  dump $ranker->getPagerankOfNodes (listOfEdges => $listOfEdges);
  dump $ranker->getPagerankOfNodes (listOfEdges => $listOfEdges,
    nodeWeights => {2 => .9, 3 => .1 });

  # dumps:
  # {
  #   1 => "0.184416783248514",
  #   2 => "0.341171047056969",
  #   3 => "0.474412169694517",
  # }
  # {
  #   1 => "0.135592438389592",
  #   2 => "0.385846009631034",
  #   3 => "0.478561551979374",
  # }
}

# A example of the modules speed, or lack of.
{
  use Graph;
  use Graph::Centrality::Pagerank;
  use Data::Dump qw(dump);
  my $ranker = Graph::Centrality::Pagerank->new();
  my @listOfEdges;
  for (my $i = 0; $i < 1000000; $i++) {push @listOfEdges, [int rand 10000, int rand 10000]};
  my $startTime = time;
  my $pageranks = $ranker->getPagerankOfNodes (listOfEdges => \@listOfEdges);
  print time()-$startTime . "\n";
  # dumps:
  # a non-negative integer after a long time.
}


