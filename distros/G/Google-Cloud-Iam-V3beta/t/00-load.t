#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;

plan tests => 4;

BEGIN {
    use_ok( 'Google::Cloud::Iam::V3beta' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Iam::V3beta::AccessPoliciesClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Iam::V3beta::PolicyBindingsClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Iam::V3beta::PrincipalAccessBoundaryPoliciesClient' ) || print "Bail out!\n";
}

diag( "Testing Google::Cloud::Iam::V3beta $Google::Cloud::Iam::V3beta::VERSION, Perl $], $^X" );
