#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;

plan tests => 2;

BEGIN {
    use_ok( 'Google::Cloud::Apigateway::V1' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Apigateway::V1::ApiGatewayServiceClient' ) || print "Bail out!\n";
}

diag( "Testing Google::Cloud::Apigateway::V1 $Google::Cloud::Apigateway::V1::VERSION, Perl $], $^X" );
