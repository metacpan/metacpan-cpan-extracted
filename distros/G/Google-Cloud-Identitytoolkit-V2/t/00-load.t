#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;

plan tests => 3;

BEGIN {
    use_ok( 'Google::Cloud::Identitytoolkit::V2' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Identitytoolkit::V2::AccountManagementServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Identitytoolkit::V2::AuthenticationServiceClient' ) || print "Bail out!\n";
}

diag( "Testing Google::Cloud::Identitytoolkit::V2 $Google::Cloud::Identitytoolkit::V2::VERSION, Perl $], $^X" );
