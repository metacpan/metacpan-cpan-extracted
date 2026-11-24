#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;

plan tests => 4;

BEGIN {
    use_ok( 'Google::Cloud::Vectorsearch::V1beta' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Vectorsearch::V1beta::DataObjectSearchServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Vectorsearch::V1beta::DataObjectServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Vectorsearch::V1beta::VectorSearchServiceClient' ) || print "Bail out!\n";
}

diag( "Testing Google::Cloud::Vectorsearch::V1beta $Google::Cloud::Vectorsearch::V1beta::VERSION, Perl $], $^X" );
