#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Google::Cloud::Iam::V1::IamPolicyClient' ) || print "Bail out!\n";
}

diag( "Testing Google::Cloud::Iam::V1::IamPolicyClient $Google::Cloud::Iam::V1::IamPolicyClient::VERSION, Perl $], $^X" );
