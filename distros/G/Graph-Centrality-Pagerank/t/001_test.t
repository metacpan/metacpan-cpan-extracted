# -*- perl -*-

use strict;
use warnings;
#use Data::Dump qw(dump);

use Test::More tests => 5;

BEGIN { use_ok( 'Graph::Centrality::Pagerank' ); }

my $object = Graph::Centrality::Pagerank->new ();
isa_ok ($object, 'Graph::Centrality::Pagerank');
ok (testLoopGraphs(10), 'Testing pagerank of loop graphs.');
ok (staticGraph1Test(), 'Testing static graph.');
ok (testNoEdgesGraphs(10), 'Testing edgeless graphs.');

# returns the average relative error between to vectors stored in a hash.
sub getRelativeError
{
  my ($Orig, $Approx) = @_;

  my %allKeys = (%$Orig, %$Approx);
  my $relError = 0;
  my $totalKeys = 0;
  foreach my $key (keys %allKeys)
  {
    ++$totalKeys;
    my $orig = 0;
    $orig = $Orig->{$key} if (exists ($Orig->{$key}));
    my $approx = 0;
    $approx = $Approx->{$key} if (exists ($Approx->{$key}));
    my $error = abs $approx;
    $error = abs (($orig - $approx) / $orig) if ($orig != 0);
    $relError += $error;
  }
  $relError /= $totalKeys if $totalKeys;
  return $relError;
}

# returns array reference of loop graph getEdgesOfLoopGraph ($TotalNodes)
sub getEdgesOfLoopGraph
{
  my $TotalNodes = shift;
  my @edges;
  for (my $i = 0; $i < $TotalNodes-1; $i++)
  {
    push @edges, [$i, $i+1];
  }
  push @edges, [$TotalNodes-1,0];
  return \@edges;
}

# test the pagerank computed on loops graphs, directed
# and undirected. all pagerank values should be 1/totalNodes.
# returns 1 if tests pass, 0 if any test fails.
sub testLoopGraphs
{
  my $TotalTests = shift;
  $TotalTests = 1 unless defined $TotalTests;

  my $epsilon = sqrt _getMachineEpsilon ();
  {
    my $totalNodes = 100;
    for (my $test = 0; $test < $TotalTests; $test++)
    {
      my $listOfEdges = getEdgesOfLoopGraph ($totalNodes);
      my $ranker = Graph::Centrality::Pagerank->new();
      my $ranks = $ranker->getPagerankOfNodes (listOfEdges => $listOfEdges);
      my %trueRanks = %$ranks;
      foreach my $key (keys %trueRanks) { $trueRanks{$key} = 1/$totalNodes; }
      my $error = getRelativeError (\%trueRanks, $ranks);
      return 0 if ($error > 10 * $epsilon);
      $totalNodes += 100;
    }
  }
  {
    my $totalNodes = 100;
    for (my $test = 0; $test < $TotalTests; $test++)
    {
      my $listOfEdges = getEdgesOfLoopGraph ($totalNodes);
      my $ranker = Graph::Centrality::Pagerank->new();
      my $ranks = $ranker->getPagerankOfNodes (directed => 0, listOfEdges => $listOfEdges);
      my %trueRanks = %$ranks;
      foreach my $key (keys %trueRanks) { $trueRanks{$key} = 1/$totalNodes; }
      my $error = getRelativeError (\%trueRanks, $ranks);
      return 0 if ($error > 10 * $epsilon);
      $totalNodes += 100;
    }
  }
  return 1;
}

# returns the machine epsilon of the system.
sub _getMachineEpsilon
{
  my $one = 1;
  my $epsilon = 2;
  my $halfOfepsilon = 1;
  my $powerOf2 = 0;
  my $sum;
  do
  {
    $epsilon = $halfOfepsilon;
    $halfOfepsilon = $epsilon / 2;
    $sum = 1 + $halfOfepsilon;
    ++$powerOf2;
  }
  until (($sum == $one) || ($powerOf2 > 2048)) ;
  return $epsilon, ;
}

# a test on a static graph.
sub staticGraph1Test
{
  my $ranker = Graph::Centrality::Pagerank->new();
  my $listOfEdges = [[1,2],[1,3],[2,4],[3,2],[3,5],[4,2],[4,5],[4,6],[5,6],
    [5,7],[5,8],[6,8],[7,5],[7,1],[7,8],[8,6],[8,7]];
  my $ranks = $ranker->getPagerankOfNodes (listOfEdges => $listOfEdges,
    dampeningFactor => 1);
  my %trueRanks = (1,0.06,2,0.0675,3,0.03,4,0.0675,5,0.0975,6,0.2025,7,0.18,8,0.295);
  my $error = getRelativeError (\%trueRanks, $ranks);
  my $epsilon = sqrt _getMachineEpsilon ();
  return 0 if ($error > 10 * $epsilon);
  return 1;
}

# test the ranks computed for graphs without edges.
sub testNoEdgesGraphs
{
  my $TotalTests = shift;
  $TotalTests = 1 unless defined $TotalTests;

  my $ranker = Graph::Centrality::Pagerank->new();
  my $epsilon = sqrt _getMachineEpsilon ();
  {
    for (my $test = 1; $test <= $TotalTests; $test++)
    {
      my $totalNodes = 1 + int abs rand 1000;
      $totalNodes = 1 if ($test < 2);
      my @listOfNodes = (1..$totalNodes);
      my $ranks = $ranker->getPagerankOfNodes (listOfNodes => \@listOfNodes);
      my %trueRanks = %$ranks;
      foreach my $key (keys %trueRanks) { $trueRanks{$key} = 1/$totalNodes; }
      my $error = getRelativeError (\%trueRanks, $ranks);
      return 0 if ($error > 10 * $epsilon);
    }
  }
  return 1;
}
