#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;

plan tests => 15;

BEGIN {
    use_ok( 'Google::Cloud::Sql::V1beta4' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Sql::V1beta4::BlueGreenDeploymentsServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Sql::V1beta4::SqlBackupRunsServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Sql::V1beta4::SqlBackupsServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Sql::V1beta4::SqlConnectServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Sql::V1beta4::SqlDataServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Sql::V1beta4::SqlDatabasesServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Sql::V1beta4::SqlFlagsServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Sql::V1beta4::SqlIamPoliciesServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Sql::V1beta4::SqlInstancesServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Sql::V1beta4::SqlOperationsServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Sql::V1beta4::SqlSslCertsServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Sql::V1beta4::SqlTiersServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Sql::V1beta4::SqlUsersServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Sql::V1beta4::SqlWorkloadCapturesServiceClient' ) || print "Bail out!\n";
}

diag( "Testing Google::Cloud::Sql::V1beta4 $Google::Cloud::Sql::V1beta4::VERSION, Perl $], $^X" );
