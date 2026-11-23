#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;

plan tests => 6;

BEGIN {
    use_ok( 'Google::Cloud::Kms::V1' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Kms::V1::AutokeyClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Kms::V1::AutokeyAdminClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Kms::V1::EkmServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Kms::V1::HsmManagementClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Kms::V1::KeyManagementServiceClient' ) || print "Bail out!\n";
}

diag( "Testing Google::Cloud::Kms::V1 $Google::Cloud::Kms::V1::VERSION, Perl $], $^X" );
