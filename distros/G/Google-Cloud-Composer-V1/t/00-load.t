#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;

plan tests => 2;

BEGIN {
    use_ok( 'Google::Cloud::Composer::V1::EnvironmentsClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Composer::V1::ImageVersionsClient' ) || print "Bail out!\n";
}

diag( "Testing Google::Cloud::Composer::V1::EnvironmentsClient $Google::Cloud::Composer::V1::EnvironmentsClient::VERSION, Perl $], $^X" );
