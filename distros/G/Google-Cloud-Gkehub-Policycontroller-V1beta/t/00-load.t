#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Google::Cloud::Gkehub::Policycontroller::V1beta' ) || print "Bail out!\n";
}

diag( "Testing Google::Cloud::Gkehub::Policycontroller::V1beta $Google::Cloud::Gkehub::Policycontroller::V1beta::VERSION, Perl $], $^X" );
