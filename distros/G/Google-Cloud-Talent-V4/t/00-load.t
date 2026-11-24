#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;

plan tests => 6;

BEGIN {
    use_ok( 'Google::Cloud::Talent::V4' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Talent::V4::CompanyServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Talent::V4::CompletionClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Talent::V4::EventServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Talent::V4::JobServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Talent::V4::TenantServiceClient' ) || print "Bail out!\n";
}

diag( "Testing Google::Cloud::Talent::V4 $Google::Cloud::Talent::V4::VERSION, Perl $], $^X" );
