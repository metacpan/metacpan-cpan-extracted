#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;

plan tests => 3;

BEGIN {
    use_ok( 'Google::Cloud::Alloydb::V1' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Alloydb::V1::AlloyDBAdminClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Alloydb::V1::AlloyDBCSQLAdminClient' ) || print "Bail out!\n";
}

diag( "Testing Google::Cloud::Alloydb::V1 $Google::Cloud::Alloydb::V1::VERSION, Perl $], $^X" );
