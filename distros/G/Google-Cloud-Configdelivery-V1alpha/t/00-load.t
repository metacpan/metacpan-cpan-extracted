#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;

plan tests => 2;

BEGIN {
    use_ok( 'Google::Cloud::Configdelivery::V1alpha' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Configdelivery::V1alpha::ConfigDeliveryClient' ) || print "Bail out!\n";
}

diag( "Testing Google::Cloud::Configdelivery::V1alpha $Google::Cloud::Configdelivery::V1alpha::VERSION, Perl $], $^X" );
