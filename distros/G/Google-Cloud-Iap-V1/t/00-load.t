#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;

plan tests => 3;

BEGIN {
    use_ok( 'Google::Cloud::Iap::V1' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Iap::V1::IdentityAwareProxyAdminServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Iap::V1::IdentityAwareProxyOAuthServiceClient' ) || print "Bail out!\n";
}

diag( "Testing Google::Cloud::Iap::V1 $Google::Cloud::Iap::V1::VERSION, Perl $], $^X" );
