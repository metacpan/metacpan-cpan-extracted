#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;

plan tests => 2;

BEGIN {
    use_ok( 'Google::Cloud::Lifesciences::V2beta' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Lifesciences::V2beta::WorkflowsServiceV2BetaClient' ) || print "Bail out!\n";
}

diag( "Testing Google::Cloud::Lifesciences::V2beta $Google::Cloud::Lifesciences::V2beta::VERSION, Perl $], $^X" );
