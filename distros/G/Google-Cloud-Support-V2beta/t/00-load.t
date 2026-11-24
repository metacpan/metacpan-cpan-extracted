#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;

plan tests => 6;

BEGIN {
    use_ok( 'Google::Cloud::Support::V2beta' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Support::V2beta::CaseAttachmentServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Support::V2beta::CaseServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Support::V2beta::CommentServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Support::V2beta::FeedServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Support::V2beta::SupportEventSubscriptionServiceClient' ) || print "Bail out!\n";
}

diag( "Testing Google::Cloud::Support::V2beta $Google::Cloud::Support::V2beta::VERSION, Perl $], $^X" );
