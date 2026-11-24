#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;

plan tests => 4;

BEGIN {
    use_ok( 'Google::Cloud::Networkmanagement::V1' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Networkmanagement::V1::OrganizationVpcFlowLogsServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Networkmanagement::V1::ReachabilityServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Networkmanagement::V1::VpcFlowLogsServiceClient' ) || print "Bail out!\n";
}

diag( "Testing Google::Cloud::Networkmanagement::V1 $Google::Cloud::Networkmanagement::V1::VERSION, Perl $], $^X" );
