#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;

plan tests => 16;

BEGIN {
    use_ok( 'Google::Cloud::Sql::V1::SqlAvailableDatabaseVersionsServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Sql::V1::SqlBackupRunsServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Sql::V1::SqlBackupsServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Sql::V1::SqlConnectServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Sql::V1::SqlDatabasesServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Sql::V1::SqlEventsServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Sql::V1::SqlFeatureEligibilityServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Sql::V1::SqlFlagsServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Sql::V1::SqlIamPoliciesServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Sql::V1::SqlInstanceNamesServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Sql::V1::SqlInstancesServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Sql::V1::SqlOperationsServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Sql::V1::SqlRegionsServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Sql::V1::SqlSslCertsServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Sql::V1::SqlTiersServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Sql::V1::SqlUsersServiceClient' ) || print "Bail out!\n";
}

diag( "Testing Google::Cloud::Sql::V1::SqlAvailableDatabaseVersionsServiceClient $Google::Cloud::Sql::V1::SqlAvailableDatabaseVersionsServiceClient::VERSION, Perl $], $^X" );
