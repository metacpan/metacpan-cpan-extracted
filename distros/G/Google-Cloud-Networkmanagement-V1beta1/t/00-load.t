#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;

plan tests => 4;

BEGIN {
    use_ok( 'Google::Cloud::Networkmanagement::V1beta1' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Networkmanagement::V1beta1::OrganizationVpcFlowLogsServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Networkmanagement::V1beta1::ReachabilityServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Networkmanagement::V1beta1::VpcFlowLogsServiceClient' ) || print "Bail out!\n";
}

diag( "Testing Google::Cloud::Networkmanagement::V1beta1 $Google::Cloud::Networkmanagement::V1beta1::VERSION, Perl $], $^X" );
