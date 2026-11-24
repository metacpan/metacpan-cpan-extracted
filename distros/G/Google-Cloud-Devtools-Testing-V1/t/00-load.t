#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;

plan tests => 5;

BEGIN {
    use_ok( 'Google::Cloud::Devtools::Testing::V1' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Devtools::Testing::V1::ApplicationDetailServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Devtools::Testing::V1::DirectAccessServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Devtools::Testing::V1::TestEnvironmentDiscoveryServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Devtools::Testing::V1::TestExecutionServiceClient' ) || print "Bail out!\n";
}

diag( "Testing Google::Cloud::Devtools::Testing::V1 $Google::Cloud::Devtools::Testing::V1::VERSION, Perl $], $^X" );
