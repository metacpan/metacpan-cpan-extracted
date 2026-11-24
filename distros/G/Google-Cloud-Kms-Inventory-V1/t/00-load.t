#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;

plan tests => 4;

BEGIN {
    use_ok( 'Google::Cloud::Kms::Inventory::V1' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Kms::Inventory::V1::KeyDashboardServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Kms::Inventory::V1::KeyTrackingServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Kms::Inventory::V1::agentClient' ) || print "Bail out!\n";
}

diag( "Testing Google::Cloud::Kms::Inventory::V1 $Google::Cloud::Kms::Inventory::V1::VERSION, Perl $], $^X" );
