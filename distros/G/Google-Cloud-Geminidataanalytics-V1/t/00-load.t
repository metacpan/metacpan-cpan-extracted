#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;

plan tests => 3;

BEGIN {
    use_ok( 'Google::Cloud::Geminidataanalytics::V1' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Geminidataanalytics::V1::DataAgentServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Geminidataanalytics::V1::DataChatServiceClient' ) || print "Bail out!\n";
}

diag( "Testing Google::Cloud::Geminidataanalytics::V1 $Google::Cloud::Geminidataanalytics::V1::VERSION, Perl $], $^X" );
