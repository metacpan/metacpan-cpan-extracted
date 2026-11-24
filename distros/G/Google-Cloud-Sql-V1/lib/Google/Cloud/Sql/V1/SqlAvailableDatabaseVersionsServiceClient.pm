package Google::Cloud::Sql::V1::SqlAvailableDatabaseVersionsServiceClient;

use strict;
use warnings;

use Protobuf;
use Google::Api::Common;
use Google::Cloud::Sql::V1::CloudSqlResources;
use Google::Cloud::Sql::V1::CloudSqlTiers;
use Google::Cloud::Sql::V1::CloudSqlInstanceNames;
use Google::Cloud::Sql::V1::CloudSqlEvents;
use Google::Cloud::Sql::V1::CloudSqlRegions;
use Google::Cloud::Sql::V1::CloudSqlAvailableDatabaseVersions;
use Google::Cloud::Sql::V1::CloudSqlFeatureEligibility;
use Google::Cloud::Sql::V1::CloudSqlIamPolicies;
use Google::Cloud::Sql::V1::CloudSqlInstances;
use Google::Cloud::Sql::V1::CloudSqlWorkloadCaptures;
use Google::Cloud::Sql::V1::CloudSqlDatabases;
use Google::Cloud::Sql::V1::CloudSqlBlueGreenDeployments;
use Google::Cloud::Sql::V1::CloudSqlConnect;
use Google::Cloud::Sql::V1::CloudSqlSslCerts;
use Google::Cloud::Sql::V1::CloudSqlBackupRuns;
use Google::Cloud::Sql::V1::CloudSqlUsers;
use Google::Cloud::Sql::V1::CloudSqlFlags;
use Google::Cloud::Sql::V1::CloudSqlOperations;
use Google::Cloud::Sql::V1::CloudSqlBackups;

our $VERSION = '0.06';
1; # End of Google::Cloud::Sql::V1::SqlAvailableDatabaseVersionsServiceClient

__END__

=head1 NAME

Google::Cloud::Sql::V1::SqlAvailableDatabaseVersionsServiceClient - Auto-generated Protocol Buffers schema container

=head1 DESCRIPTION

This is an auto-generated Protocol Buffers schema container module for Google Cloud Services.

=head1 SYNOPSIS

    use Google::Cloud::Sql::V1::BlueGreenDeploymentsServiceClient;

    my $client = Google::Cloud::Sql::V1::BlueGreenDeploymentsServiceClient->new();

=head1 CLIENTS

This distribution provides the following service client classes:

=over 4

=item * L<Google::Cloud::Sql::V1::BlueGreenDeploymentsServiceClient>

=item * L<Google::Cloud::Sql::V1::SqlAvailableDatabaseVersionsServiceClient>

=item * L<Google::Cloud::Sql::V1::SqlBackupRunsServiceClient>

=item * L<Google::Cloud::Sql::V1::SqlBackupsServiceClient>

=item * L<Google::Cloud::Sql::V1::SqlConnectServiceClient>

=item * L<Google::Cloud::Sql::V1::SqlDatabasesServiceClient>

=item * L<Google::Cloud::Sql::V1::SqlEventsServiceClient>

=item * L<Google::Cloud::Sql::V1::SqlFeatureEligibilityServiceClient>

=item * L<Google::Cloud::Sql::V1::SqlFlagsServiceClient>

=item * L<Google::Cloud::Sql::V1::SqlIamPoliciesServiceClient>

=item * L<Google::Cloud::Sql::V1::SqlInstanceNamesServiceClient>

=item * L<Google::Cloud::Sql::V1::SqlInstancesServiceClient>

=item * L<Google::Cloud::Sql::V1::SqlOperationsServiceClient>

=item * L<Google::Cloud::Sql::V1::SqlRegionsServiceClient>

=item * L<Google::Cloud::Sql::V1::SqlSslCertsServiceClient>

=item * L<Google::Cloud::Sql::V1::SqlTiersServiceClient>

=item * L<Google::Cloud::Sql::V1::SqlUsersServiceClient>

=item * L<Google::Cloud::Sql::V1::SqlWorkloadCapturesServiceClient>

=back

=head1 SEE ALSO

L<Google::Cloud::Sql::V1::BlueGreenDeploymentsServiceClient>, L<Google::Cloud::Sql::V1::SqlAvailableDatabaseVersionsServiceClient>, L<Google::Cloud::Sql::V1::SqlBackupRunsServiceClient>, L<Google::Cloud::Sql::V1::SqlBackupsServiceClient>, L<Google::Cloud::Sql::V1::SqlConnectServiceClient>, L<Google::Cloud::Sql::V1::SqlDatabasesServiceClient>, L<Google::Cloud::Sql::V1::SqlEventsServiceClient>, L<Google::Cloud::Sql::V1::SqlFeatureEligibilityServiceClient>, L<Google::Cloud::Sql::V1::SqlFlagsServiceClient>, L<Google::Cloud::Sql::V1::SqlIamPoliciesServiceClient>, L<Google::Cloud::Sql::V1::SqlInstanceNamesServiceClient>, L<Google::Cloud::Sql::V1::SqlInstancesServiceClient>, L<Google::Cloud::Sql::V1::SqlOperationsServiceClient>, L<Google::Cloud::Sql::V1::SqlRegionsServiceClient>, L<Google::Cloud::Sql::V1::SqlSslCertsServiceClient>, L<Google::Cloud::Sql::V1::SqlTiersServiceClient>, L<Google::Cloud::Sql::V1::SqlUsersServiceClient>, L<Google::Cloud::Sql::V1::SqlWorkloadCapturesServiceClient>

=head1 SOURCE

Generated from the following Protocol Buffers schemas:

=over 4

=item * C<googleapis/google/cloud/sql/v1/cloud_sql_available_database_versions.proto>

=item * C<googleapis/google/cloud/sql/v1/cloud_sql_backup_runs.proto>

=item * C<googleapis/google/cloud/sql/v1/cloud_sql_backups.proto>

=item * C<googleapis/google/cloud/sql/v1/cloud_sql_blue_green_deployments.proto>

=item * C<googleapis/google/cloud/sql/v1/cloud_sql_connect.proto>

=item * C<googleapis/google/cloud/sql/v1/cloud_sql_databases.proto>

=item * C<googleapis/google/cloud/sql/v1/cloud_sql_events.proto>

=item * C<googleapis/google/cloud/sql/v1/cloud_sql_feature_eligibility.proto>

=item * C<googleapis/google/cloud/sql/v1/cloud_sql_flags.proto>

=item * C<googleapis/google/cloud/sql/v1/cloud_sql_iam_policies.proto>

=item * C<googleapis/google/cloud/sql/v1/cloud_sql_instance_names.proto>

=item * C<googleapis/google/cloud/sql/v1/cloud_sql_instances.proto>

=item * C<googleapis/google/cloud/sql/v1/cloud_sql_operations.proto>

=item * C<googleapis/google/cloud/sql/v1/cloud_sql_regions.proto>

=item * C<googleapis/google/cloud/sql/v1/cloud_sql_resources.proto>

=item * C<googleapis/google/cloud/sql/v1/cloud_sql_ssl_certs.proto>

=item * C<googleapis/google/cloud/sql/v1/cloud_sql_tiers.proto>

=item * C<googleapis/google/cloud/sql/v1/cloud_sql_users.proto>

=item * C<googleapis/google/cloud/sql/v1/cloud_sql_workload_captures.proto>



=back

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
