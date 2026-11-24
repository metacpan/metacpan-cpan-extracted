#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;

plan tests => 4;

BEGIN {
    use_ok( 'Google::Cloud::Vectorsearch::V1' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Vectorsearch::V1::DataObjectSearchServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Vectorsearch::V1::DataObjectServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Vectorsearch::V1::VectorSearchServiceClient' ) || print "Bail out!\n";
}

diag( "Testing Google::Cloud::Vectorsearch::V1 $Google::Cloud::Vectorsearch::V1::VERSION, Perl $], $^X" );
