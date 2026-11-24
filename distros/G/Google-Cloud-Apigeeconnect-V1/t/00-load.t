#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;

plan tests => 3;

BEGIN {
    use_ok( 'Google::Cloud::Apigeeconnect::V1' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Apigeeconnect::V1::ConnectionServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Apigeeconnect::V1::TetherClient' ) || print "Bail out!\n";
}

diag( "Testing Google::Cloud::Apigeeconnect::V1 $Google::Cloud::Apigeeconnect::V1::VERSION, Perl $], $^X" );
