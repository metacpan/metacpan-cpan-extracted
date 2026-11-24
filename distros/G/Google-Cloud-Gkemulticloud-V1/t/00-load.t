#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;

plan tests => 4;

BEGIN {
    use_ok( 'Google::Cloud::Gkemulticloud::V1' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Gkemulticloud::V1::AttachedClustersClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Gkemulticloud::V1::AwsClustersClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Gkemulticloud::V1::AzureClustersClient' ) || print "Bail out!\n";
}

diag( "Testing Google::Cloud::Gkemulticloud::V1 $Google::Cloud::Gkemulticloud::V1::VERSION, Perl $], $^X" );
