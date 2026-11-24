#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Google::Cloud::Recommender::Logging::V1' ) || print "Bail out!\n";
}

diag( "Testing Google::Cloud::Recommender::Logging::V1 $Google::Cloud::Recommender::Logging::V1::VERSION, Perl $], $^X" );
