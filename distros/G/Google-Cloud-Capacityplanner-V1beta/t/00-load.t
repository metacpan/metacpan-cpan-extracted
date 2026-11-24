#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;

plan tests => 2;

BEGIN {
    use_ok( 'Google::Cloud::Capacityplanner::V1beta' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Capacityplanner::V1beta::UsageServiceClient' ) || print "Bail out!\n";
}

diag( "Testing Google::Cloud::Capacityplanner::V1beta $Google::Cloud::Capacityplanner::V1beta::VERSION, Perl $], $^X" );
