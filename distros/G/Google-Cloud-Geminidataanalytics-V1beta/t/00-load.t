#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;

plan tests => 3;

BEGIN {
    use_ok( 'Google::Cloud::Geminidataanalytics::V1beta' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Geminidataanalytics::V1beta::DataAgentServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Geminidataanalytics::V1beta::DataChatServiceClient' ) || print "Bail out!\n";
}

diag( "Testing Google::Cloud::Geminidataanalytics::V1beta $Google::Cloud::Geminidataanalytics::V1beta::VERSION, Perl $], $^X" );
