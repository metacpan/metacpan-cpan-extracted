#!perl -T

use Test::More tests => 5;
use Test::Output;
use Graph;
use Data::Dumper;

BEGIN {
    use_ok( 'Graph::Similarity::SimilarityFlooding' ) || print "Bail out!\n";
}

my $g1 = Graph->new(multiedged => 1);
$g1->add_vertices("I","coffee","apple","swim");
$g1->add_edge_by_id("I", "coffee", "drink");
$g1->add_edge_by_id("I", "swim", "can't");
$g1->add_edge_by_id("I", "apple", "eat");

my $g2 = Graph->new(multiedged => 1);
$g2->add_vertices("she","cake","apple juice","swim");
$g2->add_edge_by_id("she", "apple juice", "drink");
$g2->add_edge_by_id("she", "swim", "can");
$g2->add_edge_by_id("she", "cake", "eat");

my $method = new Graph::Similarity::SimilarityFlooding(graph => [$g1, $g2]);

# Check the default number of iteration 
is($method->num_of_iteration, 100, "Default iteration is 100 times");

# Test setNumOfIteration()
$method->setNumOfIteration(200);
is($method->num_of_iteration, 200, "setNumOfIteration works fine");

my $result = $method->calculate;

# Check the result
my $sim = $method->getSimilarity('coffee', 'apple juice');
cmp_ok($sim, '>=', 0.5, "The similarity of confee and apple juice is $sim which is more than 0.5");

# Test showALLSimilarities
stdout_like {$method->showAllSimilarities()} qr/$sim/, "showAllSimilarities() has $sim";
