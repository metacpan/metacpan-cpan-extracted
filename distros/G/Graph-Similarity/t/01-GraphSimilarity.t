#!perl -T

use Test::More tests => 7;
use Test::Exception;
use Graph::Similarity;

use Graph;
use Data::Dumper;

# Simple Graph
my $g1 = Graph->new; 
my $g2 = Graph->new; 
my $g3 = Graph->new(multiedged => 1);
my $g4 = Graph->new(multiedged => 1);

my $s = new Graph::Similarity(graph => [$g1]);
my $method1 = $s->use('SimRank');
isa_ok $method1, 'Graph::Similarity::SimRank';

# SimilarityFlooding and CoupleNodeEdgeScoring should not be a single graph
dies_ok (sub {$s->use('CoupledNodeEdgeScoring')}, "CouledNodeEdgeScoring is died properly when it's single graph" );
dies_ok (sub {$s->use('SimilarityFlooding')}, "SimilarityFlooding is died properly when it's single graphs" );

$s = new Graph::Similarity(graph => [$g1, $g2]);
# SimRank should be single graph
dies_ok (sub {$s->use('SimRank')}, "SimRank is died properly when it's multiple graphs" );
my $method2 = $s->use('CoupledNodeEdgeScoring');
isa_ok $method2, 'Graph::Similarity::CoupledNodeEdgeScoring';

dies_ok (sub {$s->use('SimilarityFlooding')}, "SimilarityFlooding should use multiedged graph for edge label");
$s = new Graph::Similarity(graph => [$g3, $g4]);
my $method3 = $s->use('SimilarityFlooding');
isa_ok $method3, 'Graph::Similarity::SimilarityFlooding';


