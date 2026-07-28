#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;

plan tests => 7;

BEGIN {
    use_ok( 'Google::Cloud::Bigquery::V2::DatasetServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Bigquery::V2::JobServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Bigquery::V2::ModelServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Bigquery::V2::ProjectServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Bigquery::V2::RoutineServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Bigquery::V2::RowAccessPolicyServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Bigquery::V2::TableServiceClient' ) || print "Bail out!\n";
}

diag( "Testing Google::Cloud::Bigquery::V2::DatasetServiceClient $Google::Cloud::Bigquery::V2::DatasetServiceClient::VERSION, Perl $], $^X" );
