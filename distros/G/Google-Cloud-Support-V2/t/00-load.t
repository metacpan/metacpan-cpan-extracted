#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;

plan tests => 5;

BEGIN {
    use_ok( 'Google::Cloud::Support::V2' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Support::V2::CaseAttachmentServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Support::V2::CaseServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Support::V2::CommentServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Support::V2::SupportEventSubscriptionServiceClient' ) || print "Bail out!\n";
}

diag( "Testing Google::Cloud::Support::V2 $Google::Cloud::Support::V2::VERSION, Perl $], $^X" );
