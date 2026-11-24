#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;

plan tests => 2;

BEGIN {
    use_ok( 'Google::Cloud::Workflows::V1beta' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Workflows::V1beta::WorkflowsClient' ) || print "Bail out!\n";
}

diag( "Testing Google::Cloud::Workflows::V1beta $Google::Cloud::Workflows::V1beta::VERSION, Perl $], $^X" );
