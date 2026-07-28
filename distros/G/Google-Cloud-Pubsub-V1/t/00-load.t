#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;

plan tests => 3;

BEGIN {
    use_ok( 'Google::Cloud::Pubsub::V1::PublisherClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Pubsub::V1::SchemaServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Pubsub::V1::SubscriberClient' ) || print "Bail out!\n";
}

diag( "Testing Google::Cloud::Pubsub::V1::PublisherClient $Google::Cloud::Pubsub::V1::PublisherClient::VERSION, Perl $], $^X" );
