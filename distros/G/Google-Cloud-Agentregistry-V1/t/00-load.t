#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;

plan tests => 2;

BEGIN {
    use_ok( 'Google::Cloud::Agentregistry::V1' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Agentregistry::V1::AgentRegistryClient' ) || print "Bail out!\n";
}

diag( "Testing Google::Cloud::Agentregistry::V1 $Google::Cloud::Agentregistry::V1::VERSION, Perl $], $^X" );
