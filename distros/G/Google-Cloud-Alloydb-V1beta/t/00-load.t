#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;

plan tests => 3;

BEGIN {
    use_ok( 'Google::Cloud::Alloydb::V1beta' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Alloydb::V1beta::AlloyDBAdminClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Alloydb::V1beta::AlloyDBCSQLAdminClient' ) || print "Bail out!\n";
}

diag( "Testing Google::Cloud::Alloydb::V1beta $Google::Cloud::Alloydb::V1beta::VERSION, Perl $], $^X" );
