#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;

plan tests => 6;

BEGIN {
    use_ok( 'Google::Cloud::Cloudsecuritycompliance::V1' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Cloudsecuritycompliance::V1::AuditClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Cloudsecuritycompliance::V1::CmEnrollmentServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Cloudsecuritycompliance::V1::ConfigClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Cloudsecuritycompliance::V1::DeploymentClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Cloudsecuritycompliance::V1::MonitoringClient' ) || print "Bail out!\n";
}

diag( "Testing Google::Cloud::Cloudsecuritycompliance::V1 $Google::Cloud::Cloudsecuritycompliance::V1::VERSION, Perl $], $^X" );
