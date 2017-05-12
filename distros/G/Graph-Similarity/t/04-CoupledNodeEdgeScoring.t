#!perl -T

use Test::More tests => 5;
use Test::Output;
use Graph;
use Data::Dumper;

BEGIN {
    use_ok( 'Graph::Similarity::CoupledNodeEdgeScoring' ) || print "Bail out!\n";
}

# Graph1 : a -> b -> c
my $g1 = Graph->new; 
$g1->add_vertices("A","B","C");
$g1->add_edges(['A', 'B'], ['B','C']);

## Test 3 : Simple Graph 
# Graph2
# a -> b -> c
# a -> d -> e
my $g2 = Graph->new; 
$g2->add_vertices("a","b","c","d","e");
$g2->add_edges(['a', 'b'], ['b', 'c'], ['a', 'd'], ['d', 'e']);

my $method = new Graph::Similarity::CoupledNodeEdgeScoring(graph => [$g1, $g2]);

# Check the default number of iteration 
is($method->num_of_iteration, 100, "Default iteration is 100 times");

# Test setNumOfIteration()
$method->setNumOfIteration(200);
is($method->num_of_iteration, 200, "setNumOfIteration works fine");

$method->calculate;

#print Dumper $sim;
my $sim = $method->getSimilarity('B', 'e');
cmp_ok($sim, '>=', 0, "Similarity $sim is bigger than equal to 0");

# Test showALLSimilarities
stdout_like {$method->showAllSimilarities()} qr/$sim/, "showAllSimilarities() has $sim";

#print $sim, "\n"; 


