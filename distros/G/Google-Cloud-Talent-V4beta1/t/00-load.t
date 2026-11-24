#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;

plan tests => 6;

BEGIN {
    use_ok( 'Google::Cloud::Talent::V4beta1' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Talent::V4beta1::CompanyServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Talent::V4beta1::CompletionClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Talent::V4beta1::EventServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Talent::V4beta1::JobServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Talent::V4beta1::TenantServiceClient' ) || print "Bail out!\n";
}

diag( "Testing Google::Cloud::Talent::V4beta1 $Google::Cloud::Talent::V4beta1::VERSION, Perl $], $^X" );
