#!perl -T

use Test::More tests => 7;
use Test::Output;
use Graph;
use Data::Dumper;

BEGIN {
    use_ok( 'Graph::Similarity::SimRank' ) || print "Bail out!\n";
}

# Simple Graph
my $g1 = Graph->new;
$g1->add_vertices("a","b","c","d","e");
$g1->add_edges(['a', 'b'], ['b', 'c'], ['a', 'd'], ['d', 'e'], ['c','a'], ['e', 'd']);

my $method = new Graph::Similarity::SimRank(graph => $g1);

# Check the default value
is($method->constant, 0.6, "Default constant value is 0.6");

# Test setConst()
$method->setConst(0.8);
is($method->constant, 0.8, "Constant can be changed by setConst()");

# Check the default number of iteration 
is($method->num_of_iteration, 100, "Default iteration is 100 times");

# Test setNumOfIteration()
$method->setNumOfIteration(200);
is($method->num_of_iteration, 200, "setNumOfIteration works fine");

$method->calculate;

#print Dumper $sim;
my $sim = $method->getSimilarity('d', 'b');
cmp_ok($sim, '>=', 0, "Similarity $sim is bigger than equal to 0");

# Test showALLSimilarities
stdout_like {$method->showAllSimilarities()} qr/$sim/, "showAllSimilarities() has $sim";

