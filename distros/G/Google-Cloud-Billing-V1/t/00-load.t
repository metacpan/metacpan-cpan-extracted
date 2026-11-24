#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;

plan tests => 3;

BEGIN {
    use_ok( 'Google::Cloud::Billing::V1' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Billing::V1::CloudBillingClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Billing::V1::CloudCatalogClient' ) || print "Bail out!\n";
}

diag( "Testing Google::Cloud::Billing::V1 $Google::Cloud::Billing::V1::VERSION, Perl $], $^X" );
