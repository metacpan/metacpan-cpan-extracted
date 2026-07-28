#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Google::Cloud::Datafusion::V1::DatafusionClient' ) || print "Bail out!\n";
}

diag( "Testing Google::Cloud::Datafusion::V1::DatafusionClient $Google::Cloud::Datafusion::V1::DatafusionClient::VERSION, Perl $], $^X" );
