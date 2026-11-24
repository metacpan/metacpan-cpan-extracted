#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;

plan tests => 3;

BEGIN {
    use_ok( 'Google::Cloud::Geminidataanalytics::V1alpha' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Geminidataanalytics::V1alpha::DataAgentServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Geminidataanalytics::V1alpha::DataChatServiceClient' ) || print "Bail out!\n";
}

diag( "Testing Google::Cloud::Geminidataanalytics::V1alpha $Google::Cloud::Geminidataanalytics::V1alpha::VERSION, Perl $], $^X" );
