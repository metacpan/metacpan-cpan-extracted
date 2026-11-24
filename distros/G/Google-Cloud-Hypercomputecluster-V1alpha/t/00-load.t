#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;

plan tests => 3;

BEGIN {
    use_ok( 'Google::Cloud::Hypercomputecluster::V1alpha' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Hypercomputecluster::V1alpha::HypercomputeClusterClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Hypercomputecluster::V1alpha::MachineLearningRunsClient' ) || print "Bail out!\n";
}

diag( "Testing Google::Cloud::Hypercomputecluster::V1alpha $Google::Cloud::Hypercomputecluster::V1alpha::VERSION, Perl $], $^X" );
