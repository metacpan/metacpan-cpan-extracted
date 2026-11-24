#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;

plan tests => 3;

BEGIN {
    use_ok( 'Google::Cloud::Alloydb::V1alpha' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Alloydb::V1alpha::AlloyDBAdminClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Alloydb::V1alpha::AlloyDBCSQLAdminClient' ) || print "Bail out!\n";
}

diag( "Testing Google::Cloud::Alloydb::V1alpha $Google::Cloud::Alloydb::V1alpha::VERSION, Perl $], $^X" );
