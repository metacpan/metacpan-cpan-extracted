#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Google::Cloud::Build::V1::CloudBuildClient' ) || print "Bail out!\n";
}

diag( "Testing Google::Cloud::Build::V1::CloudBuildClient $Google::Cloud::Build::V1::CloudBuildClient::VERSION, Perl $], $^X" );
