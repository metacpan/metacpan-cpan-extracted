#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;

plan tests => 4;

BEGIN {
    use_ok( 'Google::Cloud::Iam::V3' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Iam::V3::AccessPoliciesClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Iam::V3::PolicyBindingsClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Iam::V3::PrincipalAccessBoundaryPoliciesClient' ) || print "Bail out!\n";
}

diag( "Testing Google::Cloud::Iam::V3 $Google::Cloud::Iam::V3::VERSION, Perl $], $^X" );
