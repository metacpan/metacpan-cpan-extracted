#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;

plan tests => 3;

BEGIN {
    use_ok( 'Google::Cloud::Channel::V1' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Channel::V1::CloudChannelReportsServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Channel::V1::CloudChannelServiceClient' ) || print "Bail out!\n";
}

diag( "Testing Google::Cloud::Channel::V1 $Google::Cloud::Channel::V1::VERSION, Perl $], $^X" );
