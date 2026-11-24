#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;

plan tests => 2;

BEGIN {
    use_ok( 'Google::Cloud::Oslogin::V1beta' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Oslogin::V1beta::OsLoginServiceClient' ) || print "Bail out!\n";
}

diag( "Testing Google::Cloud::Oslogin::V1beta $Google::Cloud::Oslogin::V1beta::VERSION, Perl $], $^X" );
