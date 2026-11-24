#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;

plan tests => 2;

BEGIN {
    use_ok( 'Google::Cloud::Iam::V2beta' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Iam::V2beta::PoliciesClient' ) || print "Bail out!\n";
}

diag( "Testing Google::Cloud::Iam::V2beta $Google::Cloud::Iam::V2beta::VERSION, Perl $], $^X" );
