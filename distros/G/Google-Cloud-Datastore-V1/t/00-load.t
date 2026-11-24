#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;

plan tests => 2;

BEGIN {
    use_ok( 'Google::Cloud::Datastore::V1' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Datastore::V1::DatastoreClient' ) || print "Bail out!\n";
}

diag( "Testing Google::Cloud::Datastore::V1 $Google::Cloud::Datastore::V1::VERSION, Perl $], $^X" );
