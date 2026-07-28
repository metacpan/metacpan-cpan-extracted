#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Google::Cloud::Spanner::V1::SpannerClient' ) || print "Bail out!\n";
}

diag( "Testing Google::Cloud::Spanner::V1::SpannerClient $Google::Cloud::Spanner::V1::SpannerClient::VERSION, Perl $], $^X" );
