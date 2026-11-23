#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;

plan tests => 4;

BEGIN {
    use_ok( 'Google::Cloud::Pubsub::V1' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Pubsub::V1::PublisherClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Pubsub::V1::SchemaServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Pubsub::V1::SubscriberClient' ) || print "Bail out!\n";
}

diag( "Testing Google::Cloud::Pubsub::V1 $Google::Cloud::Pubsub::V1::VERSION, Perl $], $^X" );
