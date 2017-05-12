# -*- perl -*-

# t/001_load.t - check module loading and create testing directory

use strict;
use Test::More tests => 6;

BEGIN { use_ok( 'Graph::Undirected::Components' ); }
BEGIN { use_ok( 'Graph::Undirected::Components::External' ); }
BEGIN { use_ok( 'Log::Log4perl' ); }
BEGIN { use_ok( 'Log::Log4perl::Level' ); }
ok (testInternalLineGraphs(40), 'Testing internal graphs.');
ok (testOneExternalGraph(40), 'Testing external graphs.');


sub testInternalLineGraphs
{
  my $tests = $_[0];
  for (my $i = 0; $i < $tests; $i++)
  {
    return 0 unless testOneLineGraph ();
  }
  return 1;
}


sub testExternalLineGraphs
{
  my $tests = $_[0];
  for (my $i = 0; $i < $tests; $i++)
  {
    return 0 unless testOneExternalGraph ();
  }
  return 1;
}


sub testOneLineGraph
{
  # generate the line graph edges.
  my $totalVertices = 100 + int rand 500;
  my @edges;
  my $vertex = int rand 1000000;
  my %vertices = ($vertex, 1);
  for (my $i = 0; $i < $totalVertices; $i++)
  {
    push @edges, [$vertex, int rand 1000000];
    $vertex = $edges[-1]->[1];
    $vertices{$vertex} = 1;
  }
  for (my $i = 0; $i < $totalVertices; $i++)
  {
    my $j = int rand $totalVertices;
    my $tmp = $edges[$j];
    $edges[$j] = $edges[$i];
    $edges[$i] = $tmp;
  }
  my $componenter = Graph::Undirected::Components->new ();
  for (my $i = 0; $i < $totalVertices; $i++)
  {
    $componenter->add_edge (@{$edges[$i]});
  }
  my @components = $componenter->connected_components();
  return 0 unless @components == 1;
  foreach my $vertex (@{$components[0]})
  {
    delete $vertices{$vertex};
  }
  return 0 unless 0 == scalar keys %vertices;
  return 1;
}


sub testOneExternalGraph
{
  Log::Log4perl->easy_init ($ERROR);
  
  # generate the line graph edges.
  use File::Temp qw(tempfile);
  my ($fh, $outputFile) = tempfile (UNLINK => 1);
  close $fh;
  my $totalVertices = 100 + int rand 500;
  my @edges;
  my $vertex = int rand 1000000;
  my %vertices = ($vertex, 1);
  for (my $i = 0; $i < $totalVertices; $i++)
  {
    push @edges, [$vertex, int rand 1000000];
    $vertex = $edges[-1]->[1];
    $vertices{$vertex} = 1;
  }
  for (my $i = 0; $i < $totalVertices; $i++)
  {
    my $j = int rand $totalVertices;
    my $tmp = $edges[$j];
    $edges[$j] = $edges[$i];
    $edges[$i] = $tmp;
  }
  my $componenter = Graph::Undirected::Components::External->new (purgeSizeBytes => 42, outputFile => $outputFile);
  for (my $i = 0; $i < $totalVertices; $i++)
  {
    $componenter->add_edge (@{$edges[$i]});
  }
  $componenter->finish();
  return 0 unless open ($fh, '<', $outputFile);
  my @lines = <$fh>;
  close $fh;
  my %componentHash;
  foreach my $vertexCompId (@lines)
  {
    chop $vertexCompId;
    my ($vertex, $compId) = split (/,/, $vertexCompId);
    $componentHash{$compId} = [] unless defined $componentHash{$compId};
    push @{$componentHash{$compId}}, $vertex;
  }
  my @components = values %componentHash;
  return 0 unless @components == 1;
  foreach my $vertex (@{$components[0]})
  {
    delete $vertices{$vertex};
  }
  return 0 unless 0 == scalar keys %vertices;
  return 1;
}
