#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;

plan tests => 2;

BEGIN {
    use_ok( 'Google::Cloud::Firestore::Admin::V1beta2' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Firestore::Admin::V1beta2::FirestoreAdminClient' ) || print "Bail out!\n";
}

diag( "Testing Google::Cloud::Firestore::Admin::V1beta2 $Google::Cloud::Firestore::Admin::V1beta2::VERSION, Perl $], $^X" );
