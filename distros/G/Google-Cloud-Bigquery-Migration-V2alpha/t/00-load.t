#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;

plan tests => 3;

BEGIN {
    use_ok( 'Google::Cloud::Bigquery::Migration::V2alpha' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Bigquery::Migration::V2alpha::MigrationServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Bigquery::Migration::V2alpha::SqlTranslationServiceClient' ) || print "Bail out!\n";
}

diag( "Testing Google::Cloud::Bigquery::Migration::V2alpha $Google::Cloud::Bigquery::Migration::V2alpha::VERSION, Perl $], $^X" );
