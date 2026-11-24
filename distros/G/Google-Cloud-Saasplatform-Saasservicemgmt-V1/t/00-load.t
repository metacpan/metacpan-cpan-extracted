#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;

plan tests => 3;

BEGIN {
    use_ok( 'Google::Cloud::Saasplatform::Saasservicemgmt::V1' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Saasplatform::Saasservicemgmt::V1::SaasDeploymentsClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Saasplatform::Saasservicemgmt::V1::SaasRolloutsClient' ) || print "Bail out!\n";
}

diag( "Testing Google::Cloud::Saasplatform::Saasservicemgmt::V1 $Google::Cloud::Saasplatform::Saasservicemgmt::V1::VERSION, Perl $], $^X" );
