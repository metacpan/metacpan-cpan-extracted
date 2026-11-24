#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;

plan tests => 2;

BEGIN {
    use_ok( 'Google::Cloud::Datastore::V1beta3' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Datastore::V1beta3::DatastoreClient' ) || print "Bail out!\n";
}

diag( "Testing Google::Cloud::Datastore::V1beta3 $Google::Cloud::Datastore::V1beta3::VERSION, Perl $], $^X" );
