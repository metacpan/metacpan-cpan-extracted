#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;

plan tests => 4;

BEGIN {
    use_ok( 'Google::Cloud::Logging::V2' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Logging::V2::ConfigServiceV2Client' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Logging::V2::LoggingServiceV2Client' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Logging::V2::MetricsServiceV2Client' ) || print "Bail out!\n";
}

diag( "Testing Google::Cloud::Logging::V2 $Google::Cloud::Logging::V2::VERSION, Perl $], $^X" );
