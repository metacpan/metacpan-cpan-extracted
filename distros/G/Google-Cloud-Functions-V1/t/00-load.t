#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;

plan tests => 2;

BEGIN {
    use_ok( 'Google::Cloud::Functions::V1' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Functions::V1::CloudFunctionsServiceClient' ) || print "Bail out!\n";
}

diag( "Testing Google::Cloud::Functions::V1 $Google::Cloud::Functions::V1::VERSION, Perl $], $^X" );
