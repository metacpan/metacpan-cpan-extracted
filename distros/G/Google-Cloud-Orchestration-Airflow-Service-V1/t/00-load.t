#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;

plan tests => 3;

BEGIN {
    use_ok( 'Google::Cloud::Orchestration::Airflow::Service::V1' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Orchestration::Airflow::Service::V1::EnvironmentsClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Orchestration::Airflow::Service::V1::ImageVersionsClient' ) || print "Bail out!\n";
}

diag( "Testing Google::Cloud::Orchestration::Airflow::Service::V1 $Google::Cloud::Orchestration::Airflow::Service::V1::VERSION, Perl $], $^X" );
