#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;

plan tests => 3;

BEGIN {
    use_ok( 'Google::Cloud::Policysimulator::V1' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Policysimulator::V1::OrgPolicyViolationsPreviewServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Policysimulator::V1::SimulatorClient' ) || print "Bail out!\n";
}

diag( "Testing Google::Cloud::Policysimulator::V1 $Google::Cloud::Policysimulator::V1::VERSION, Perl $], $^X" );
