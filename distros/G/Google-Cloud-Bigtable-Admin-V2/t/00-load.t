#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;

plan tests => 3;

BEGIN {
    use_ok( 'Google::Cloud::Bigtable::Admin::V2' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Bigtable::Admin::V2::BigtableInstanceAdminClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Bigtable::Admin::V2::BigtableTableAdminClient' ) || print "Bail out!\n";
}

diag( "Testing Google::Cloud::Bigtable::Admin::V2 $Google::Cloud::Bigtable::Admin::V2::VERSION, Perl $], $^X" );
