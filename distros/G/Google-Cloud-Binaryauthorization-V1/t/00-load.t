#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;

plan tests => 4;

BEGIN {
    use_ok( 'Google::Cloud::Binaryauthorization::V1' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Binaryauthorization::V1::BinauthzManagementServiceV1Client' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Binaryauthorization::V1::SystemPolicyV1Client' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Binaryauthorization::V1::ValidationHelperV1Client' ) || print "Bail out!\n";
}

diag( "Testing Google::Cloud::Binaryauthorization::V1 $Google::Cloud::Binaryauthorization::V1::VERSION, Perl $], $^X" );
