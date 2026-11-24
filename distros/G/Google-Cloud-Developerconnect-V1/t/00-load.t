#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;

plan tests => 3;

BEGIN {
    use_ok( 'Google::Cloud::Developerconnect::V1' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Developerconnect::V1::DeveloperConnectClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Developerconnect::V1::InsightsConfigServiceClient' ) || print "Bail out!\n";
}

diag( "Testing Google::Cloud::Developerconnect::V1 $Google::Cloud::Developerconnect::V1::VERSION, Perl $], $^X" );
