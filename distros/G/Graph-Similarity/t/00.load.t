#!perl -T

use Test::More tests => 4;

BEGIN {
    use_ok( 'Graph::Similarity' ) || print "Bail out!\n";
    use_ok( 'Graph::Similarity::SimRank' ) || print "Bail out!\n";
    use_ok( 'Graph::Similarity::SimilarityFlooding' ) || print "Bail out!\n";
    use_ok( 'Graph::Similarity::CoupledNodeEdgeScoring' ) || print "Bail out!\n";
}

diag( "Testing Graph::Similarity $Graph::Similarity::VERSION, Perl $], $^X" );
