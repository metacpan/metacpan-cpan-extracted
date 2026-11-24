#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;

plan tests => 7;

BEGIN {
    use_ok( 'Google::Cloud::Pubsublite::V1' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Pubsublite::V1::AdminServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Pubsublite::V1::CursorServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Pubsublite::V1::PartitionAssignmentServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Pubsublite::V1::PublisherServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Pubsublite::V1::SubscriberServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Pubsublite::V1::TopicStatsServiceClient' ) || print "Bail out!\n";
}

diag( "Testing Google::Cloud::Pubsublite::V1 $Google::Cloud::Pubsublite::V1::VERSION, Perl $], $^X" );
