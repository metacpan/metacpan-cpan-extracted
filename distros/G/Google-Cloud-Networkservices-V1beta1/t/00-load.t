#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;

plan tests => 3;

BEGIN {
    use_ok( 'Google::Cloud::Networkservices::V1beta1' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Networkservices::V1beta1::DepServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Networkservices::V1beta1::NetworkServicesClient' ) || print "Bail out!\n";
}

diag( "Testing Google::Cloud::Networkservices::V1beta1 $Google::Cloud::Networkservices::V1beta1::VERSION, Perl $], $^X" );
