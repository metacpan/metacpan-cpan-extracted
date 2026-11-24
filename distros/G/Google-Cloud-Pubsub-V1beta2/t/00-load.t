#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;

plan tests => 3;

BEGIN {
    use_ok( 'Google::Cloud::Pubsub::V1beta2' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Pubsub::V1beta2::PublisherClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Pubsub::V1beta2::SubscriberClient' ) || print "Bail out!\n";
}

diag( "Testing Google::Cloud::Pubsub::V1beta2 $Google::Cloud::Pubsub::V1beta2::VERSION, Perl $], $^X" );
