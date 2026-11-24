package Google::Cloud::Sql::V1beta4::CloudSql::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'ExternalSyncParallelLevel',
    as (Int | Str);

declare 'CreateBackupRequest',
    as InstanceOf['Google::Cloud::Sql::V1beta4::CloudSql::CreateBackupRequest'];

coerce 'CreateBackupRequest',
    from HashRef, via { 'Google::Cloud::Sql::V1beta4::CloudSql::CreateBackupRequest'->new($_) };

declare 'RepeatedCreateBackupRequest',
    as ArrayRef[CreateBackupRequest()];

coerce 'RepeatedCreateBackupRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1beta4::CloudSql::CreateBackupRequest'->new($_) } @$_ ] };

declare 'MapStringCreateBackupRequest',
    as HashRef[CreateBackupRequest()];

declare 'GetBackupRequest',
    as InstanceOf['Google::Cloud::Sql::V1beta4::CloudSql::GetBackupRequest'];

coerce 'GetBackupRequest',
    from HashRef, via { 'Google::Cloud::Sql::V1beta4::CloudSql::GetBackupRequest'->new($_) };

declare 'RepeatedGetBackupRequest',
    as ArrayRef[GetBackupRequest()];

coerce 'RepeatedGetBackupRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1beta4::CloudSql::GetBackupRequest'->new($_) } @$_ ] };

declare 'MapStringGetBackupRequest',
    as HashRef[GetBackupRequest()];

declare 'ListBackupsRequest',
    as InstanceOf['Google::Cloud::Sql::V1beta4::CloudSql::ListBackupsRequest'];

coerce 'ListBackupsRequest',
    from HashRef, via { 'Google::Cloud::Sql::V1beta4::CloudSql::ListBackupsRequest'->new($_) };

declare 'RepeatedListBackupsRequest',
    as ArrayRef[ListBackupsRequest()];

coerce 'RepeatedListBackupsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1beta4::CloudSql::ListBackupsRequest'->new($_) } @$_ ] };

declare 'MapStringListBackupsRequest',
    as HashRef[ListBackupsRequest()];

declare 'ListBackupsResponse',
    as InstanceOf['Google::Cloud::Sql::V1beta4::CloudSql::ListBackupsResponse'];

coerce 'ListBackupsResponse',
    from HashRef, via { 'Google::Cloud::Sql::V1beta4::CloudSql::ListBackupsResponse'->new($_) };

declare 'RepeatedListBackupsResponse',
    as ArrayRef[ListBackupsResponse()];

coerce 'RepeatedListBackupsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1beta4::CloudSql::ListBackupsResponse'->new($_) } @$_ ] };

declare 'MapStringListBackupsResponse',
    as HashRef[ListBackupsResponse()];

declare 'UpdateBackupRequest',
    as InstanceOf['Google::Cloud::Sql::V1beta4::CloudSql::UpdateBackupRequest'];

coerce 'UpdateBackupRequest',
    from HashRef, via { 'Google::Cloud::Sql::V1beta4::CloudSql::UpdateBackupRequest'->new($_) };

declare 'RepeatedUpdateBackupRequest',
    as ArrayRef[UpdateBackupRequest()];

coerce 'RepeatedUpdateBackupRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1beta4::CloudSql::UpdateBackupRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateBackupRequest',
    as HashRef[UpdateBackupRequest()];

declare 'DeleteBackupRequest',
    as InstanceOf['Google::Cloud::Sql::V1beta4::CloudSql::DeleteBackupRequest'];

coerce 'DeleteBackupRequest',
    from HashRef, via { 'Google::Cloud::Sql::V1beta4::CloudSql::DeleteBackupRequest'->new($_) };

declare 'RepeatedDeleteBackupRequest',
    as ArrayRef[DeleteBackupRequest()];

coerce 'RepeatedDeleteBackupRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1beta4::CloudSql::DeleteBackupRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteBackupRequest',
    as HashRef[DeleteBackupRequest()];

declare 'SqlBackupRunsDeleteRequest',
    as InstanceOf['Google::Cloud::Sql::V1beta4::CloudSql::SqlBackupRunsDeleteRequest'];

coerce 'SqlBackupRunsDeleteRequest',
    from HashRef, via { 'Google::Cloud::Sql::V1beta4::CloudSql::SqlBackupRunsDeleteRequest'->new($_) };

declare 'RepeatedSqlBackupRunsDeleteRequest',
    as ArrayRef[SqlBackupRunsDeleteRequest()];

coerce 'RepeatedSqlBackupRunsDeleteRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1beta4::CloudSql::SqlBackupRunsDeleteRequest'->new($_) } @$_ ] };

declare 'MapStringSqlBackupRunsDeleteRequest',
    as HashRef[SqlBackupRunsDeleteRequest()];

declare 'SqlBackupRunsGetRequest',
    as InstanceOf['Google::Cloud::Sql::V1beta4::CloudSql::SqlBackupRunsGetRequest'];

coerce 'SqlBackupRunsGetRequest',
    from HashRef, via { 'Google::Cloud::Sql::V1beta4::CloudSql::SqlBackupRunsGetRequest'->new($_) };

declare 'RepeatedSqlBackupRunsGetRequest',
    as ArrayRef[SqlBackupRunsGetRequest()];

coerce 'RepeatedSqlBackupRunsGetRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1beta4::CloudSql::SqlBackupRunsGetRequest'->new($_) } @$_ ] };

declare 'MapStringSqlBackupRunsGetRequest',
    as HashRef[SqlBackupRunsGetRequest()];

declare 'SqlBackupRunsInsertRequest',
    as InstanceOf['Google::Cloud::Sql::V1beta4::CloudSql::SqlBackupRunsInsertRequest'];

coerce 'SqlBackupRunsInsertRequest',
    from HashRef, via { 'Google::Cloud::Sql::V1beta4::CloudSql::SqlBackupRunsInsertRequest'->new($_) };

declare 'RepeatedSqlBackupRunsInsertRequest',
    as ArrayRef[SqlBackupRunsInsertRequest()];

coerce 'RepeatedSqlBackupRunsInsertRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1beta4::CloudSql::SqlBackupRunsInsertRequest'->new($_) } @$_ ] };

declare 'MapStringSqlBackupRunsInsertRequest',
    as HashRef[SqlBackupRunsInsertRequest()];

declare 'SqlBackupRunsListRequest',
    as InstanceOf['Google::Cloud::Sql::V1beta4::CloudSql::SqlBackupRunsListRequest'];

coerce 'SqlBackupRunsListRequest',
    from HashRef, via { 'Google::Cloud::Sql::V1beta4::CloudSql::SqlBackupRunsListRequest'->new($_) };

declare 'RepeatedSqlBackupRunsListRequest',
    as ArrayRef[SqlBackupRunsListRequest()];

coerce 'RepeatedSqlBackupRunsListRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1beta4::CloudSql::SqlBackupRunsListRequest'->new($_) } @$_ ] };

declare 'MapStringSqlBackupRunsListRequest',
    as HashRef[SqlBackupRunsListRequest()];

declare 'SqlDatabasesDeleteRequest',
    as InstanceOf['Google::Cloud::Sql::V1beta4::CloudSql::SqlDatabasesDeleteRequest'];

coerce 'SqlDatabasesDeleteRequest',
    from HashRef, via { 'Google::Cloud::Sql::V1beta4::CloudSql::SqlDatabasesDeleteRequest'->new($_) };

declare 'RepeatedSqlDatabasesDeleteRequest',
    as ArrayRef[SqlDatabasesDeleteRequest()];

coerce 'RepeatedSqlDatabasesDeleteRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1beta4::CloudSql::SqlDatabasesDeleteRequest'->new($_) } @$_ ] };

declare 'MapStringSqlDatabasesDeleteRequest',
    as HashRef[SqlDatabasesDeleteRequest()];

declare 'SqlDatabasesGetRequest',
    as InstanceOf['Google::Cloud::Sql::V1beta4::CloudSql::SqlDatabasesGetRequest'];

coerce 'SqlDatabasesGetRequest',
    from HashRef, via { 'Google::Cloud::Sql::V1beta4::CloudSql::SqlDatabasesGetRequest'->new($_) };

declare 'RepeatedSqlDatabasesGetRequest',
    as ArrayRef[SqlDatabasesGetRequest()];

coerce 'RepeatedSqlDatabasesGetRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1beta4::CloudSql::SqlDatabasesGetRequest'->new($_) } @$_ ] };

declare 'MapStringSqlDatabasesGetRequest',
    as HashRef[SqlDatabasesGetRequest()];

declare 'SqlDatabasesInsertRequest',
    as InstanceOf['Google::Cloud::Sql::V1beta4::CloudSql::SqlDatabasesInsertRequest'];

coerce 'SqlDatabasesInsertRequest',
    from HashRef, via { 'Google::Cloud::Sql::V1beta4::CloudSql::SqlDatabasesInsertRequest'->new($_) };

declare 'RepeatedSqlDatabasesInsertRequest',
    as ArrayRef[SqlDatabasesInsertRequest()];

coerce 'RepeatedSqlDatabasesInsertRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1beta4::CloudSql::SqlDatabasesInsertRequest'->new($_) } @$_ ] };

declare 'MapStringSqlDatabasesInsertRequest',
    as HashRef[SqlDatabasesInsertRequest()];

declare 'SqlDatabasesListRequest',
    as InstanceOf['Google::Cloud::Sql::V1beta4::CloudSql::SqlDatabasesListRequest'];

coerce 'SqlDatabasesListRequest',
    from HashRef, via { 'Google::Cloud::Sql::V1beta4::CloudSql::SqlDatabasesListRequest'->new($_) };

declare 'RepeatedSqlDatabasesListRequest',
    as ArrayRef[SqlDatabasesListRequest()];

coerce 'RepeatedSqlDatabasesListRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1beta4::CloudSql::SqlDatabasesListRequest'->new($_) } @$_ ] };

declare 'MapStringSqlDatabasesListRequest',
    as HashRef[SqlDatabasesListRequest()];

declare 'SqlDatabasesUpdateRequest',
    as InstanceOf['Google::Cloud::Sql::V1beta4::CloudSql::SqlDatabasesUpdateRequest'];

coerce 'SqlDatabasesUpdateRequest',
    from HashRef, via { 'Google::Cloud::Sql::V1beta4::CloudSql::SqlDatabasesUpdateRequest'->new($_) };

declare 'RepeatedSqlDatabasesUpdateRequest',
    as ArrayRef[SqlDatabasesUpdateRequest()];

coerce 'RepeatedSqlDatabasesUpdateRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1beta4::CloudSql::SqlDatabasesUpdateRequest'->new($_) } @$_ ] };

declare 'MapStringSqlDatabasesUpdateRequest',
    as HashRef[SqlDatabasesUpdateRequest()];

declare 'SqlFlagsListRequest',
    as InstanceOf['Google::Cloud::Sql::V1beta4::CloudSql::SqlFlagsListRequest'];

coerce 'SqlFlagsListRequest',
    from HashRef, via { 'Google::Cloud::Sql::V1beta4::CloudSql::SqlFlagsListRequest'->new($_) };

declare 'RepeatedSqlFlagsListRequest',
    as ArrayRef[SqlFlagsListRequest()];

coerce 'RepeatedSqlFlagsListRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1beta4::CloudSql::SqlFlagsListRequest'->new($_) } @$_ ] };

declare 'MapStringSqlFlagsListRequest',
    as HashRef[SqlFlagsListRequest()];

declare 'SqlInstancesAddServerCaRequest',
    as InstanceOf['Google::Cloud::Sql::V1beta4::CloudSql::SqlInstancesAddServerCaRequest'];

coerce 'SqlInstancesAddServerCaRequest',
    from HashRef, via { 'Google::Cloud::Sql::V1beta4::CloudSql::SqlInstancesAddServerCaRequest'->new($_) };

declare 'RepeatedSqlInstancesAddServerCaRequest',
    as ArrayRef[SqlInstancesAddServerCaRequest()];

coerce 'RepeatedSqlInstancesAddServerCaRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1beta4::CloudSql::SqlInstancesAddServerCaRequest'->new($_) } @$_ ] };

declare 'MapStringSqlInstancesAddServerCaRequest',
    as HashRef[SqlInstancesAddServerCaRequest()];

declare 'SqlInstancesAddServerCertificateRequest',
    as InstanceOf['Google::Cloud::Sql::V1beta4::CloudSql::SqlInstancesAddServerCertificateRequest'];

coerce 'SqlInstancesAddServerCertificateRequest',
    from HashRef, via { 'Google::Cloud::Sql::V1beta4::CloudSql::SqlInstancesAddServerCertificateRequest'->new($_) };

declare 'RepeatedSqlInstancesAddServerCertificateRequest',
    as ArrayRef[SqlInstancesAddServerCertificateRequest()];

coerce 'RepeatedSqlInstancesAddServerCertificateRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1beta4::CloudSql::SqlInstancesAddServerCertificateRequest'->new($_) } @$_ ] };

declare 'MapStringSqlInstancesAddServerCertificateRequest',
    as HashRef[SqlInstancesAddServerCertificateRequest()];

declare 'SqlInstancesAddEntraIdCertificateRequest',
    as InstanceOf['Google::Cloud::Sql::V1beta4::CloudSql::SqlInstancesAddEntraIdCertificateRequest'];

coerce 'SqlInstancesAddEntraIdCertificateRequest',
    from HashRef, via { 'Google::Cloud::Sql::V1beta4::CloudSql::SqlInstancesAddEntraIdCertificateRequest'->new($_) };

declare 'RepeatedSqlInstancesAddEntraIdCertificateRequest',
    as ArrayRef[SqlInstancesAddEntraIdCertificateRequest()];

coerce 'RepeatedSqlInstancesAddEntraIdCertificateRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1beta4::CloudSql::SqlInstancesAddEntraIdCertificateRequest'->new($_) } @$_ ] };

declare 'MapStringSqlInstancesAddEntraIdCertificateRequest',
    as HashRef[SqlInstancesAddEntraIdCertificateRequest()];

declare 'UpdateCustomerManagedCertificateRequest',
    as InstanceOf['Google::Cloud::Sql::V1beta4::CloudSql::UpdateCustomerManagedCertificateRequest'];

coerce 'UpdateCustomerManagedCertificateRequest',
    from HashRef, via { 'Google::Cloud::Sql::V1beta4::CloudSql::UpdateCustomerManagedCertificateRequest'->new($_) };

declare 'RepeatedUpdateCustomerManagedCertificateRequest',
    as ArrayRef[UpdateCustomerManagedCertificateRequest()];

coerce 'RepeatedUpdateCustomerManagedCertificateRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1beta4::CloudSql::UpdateCustomerManagedCertificateRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateCustomerManagedCertificateRequest',
    as HashRef[UpdateCustomerManagedCertificateRequest()];

declare 'DeleteCustomerManagedCertificateRequest',
    as InstanceOf['Google::Cloud::Sql::V1beta4::CloudSql::DeleteCustomerManagedCertificateRequest'];

coerce 'DeleteCustomerManagedCertificateRequest',
    from HashRef, via { 'Google::Cloud::Sql::V1beta4::CloudSql::DeleteCustomerManagedCertificateRequest'->new($_) };

declare 'RepeatedDeleteCustomerManagedCertificateRequest',
    as ArrayRef[DeleteCustomerManagedCertificateRequest()];

coerce 'RepeatedDeleteCustomerManagedCertificateRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1beta4::CloudSql::DeleteCustomerManagedCertificateRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteCustomerManagedCertificateRequest',
    as HashRef[DeleteCustomerManagedCertificateRequest()];

declare 'ListCustomerManagedCertificatesRequest',
    as InstanceOf['Google::Cloud::Sql::V1beta4::CloudSql::ListCustomerManagedCertificatesRequest'];

coerce 'ListCustomerManagedCertificatesRequest',
    from HashRef, via { 'Google::Cloud::Sql::V1beta4::CloudSql::ListCustomerManagedCertificatesRequest'->new($_) };

declare 'RepeatedListCustomerManagedCertificatesRequest',
    as ArrayRef[ListCustomerManagedCertificatesRequest()];

coerce 'RepeatedListCustomerManagedCertificatesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1beta4::CloudSql::ListCustomerManagedCertificatesRequest'->new($_) } @$_ ] };

declare 'MapStringListCustomerManagedCertificatesRequest',
    as HashRef[ListCustomerManagedCertificatesRequest()];

declare 'ListCustomerManagedCertificatesResponse',
    as InstanceOf['Google::Cloud::Sql::V1beta4::CloudSql::ListCustomerManagedCertificatesResponse'];

coerce 'ListCustomerManagedCertificatesResponse',
    from HashRef, via { 'Google::Cloud::Sql::V1beta4::CloudSql::ListCustomerManagedCertificatesResponse'->new($_) };

declare 'RepeatedListCustomerManagedCertificatesResponse',
    as ArrayRef[ListCustomerManagedCertificatesResponse()];

coerce 'RepeatedListCustomerManagedCertificatesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1beta4::CloudSql::ListCustomerManagedCertificatesResponse'->new($_) } @$_ ] };

declare 'MapStringListCustomerManagedCertificatesResponse',
    as HashRef[ListCustomerManagedCertificatesResponse()];

declare 'SqlInstancesCloneRequest',
    as InstanceOf['Google::Cloud::Sql::V1beta4::CloudSql::SqlInstancesCloneRequest'];

coerce 'SqlInstancesCloneRequest',
    from HashRef, via { 'Google::Cloud::Sql::V1beta4::CloudSql::SqlInstancesCloneRequest'->new($_) };

declare 'RepeatedSqlInstancesCloneRequest',
    as ArrayRef[SqlInstancesCloneRequest()];

coerce 'RepeatedSqlInstancesCloneRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1beta4::CloudSql::SqlInstancesCloneRequest'->new($_) } @$_ ] };

declare 'MapStringSqlInstancesCloneRequest',
    as HashRef[SqlInstancesCloneRequest()];

declare 'SqlInstancesDeleteRequest',
    as InstanceOf['Google::Cloud::Sql::V1beta4::CloudSql::SqlInstancesDeleteRequest'];

coerce 'SqlInstancesDeleteRequest',
    from HashRef, via { 'Google::Cloud::Sql::V1beta4::CloudSql::SqlInstancesDeleteRequest'->new($_) };

declare 'RepeatedSqlInstancesDeleteRequest',
    as ArrayRef[SqlInstancesDeleteRequest()];

coerce 'RepeatedSqlInstancesDeleteRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1beta4::CloudSql::SqlInstancesDeleteRequest'->new($_) } @$_ ] };

declare 'MapStringSqlInstancesDeleteRequest',
    as HashRef[SqlInstancesDeleteRequest()];

declare 'SqlInstancesDemoteMasterRequest',
    as InstanceOf['Google::Cloud::Sql::V1beta4::CloudSql::SqlInstancesDemoteMasterRequest'];

coerce 'SqlInstancesDemoteMasterRequest',
    from HashRef, via { 'Google::Cloud::Sql::V1beta4::CloudSql::SqlInstancesDemoteMasterRequest'->new($_) };

declare 'RepeatedSqlInstancesDemoteMasterRequest',
    as ArrayRef[SqlInstancesDemoteMasterRequest()];

coerce 'RepeatedSqlInstancesDemoteMasterRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1beta4::CloudSql::SqlInstancesDemoteMasterRequest'->new($_) } @$_ ] };

declare 'MapStringSqlInstancesDemoteMasterRequest',
    as HashRef[SqlInstancesDemoteMasterRequest()];

declare 'SqlInstancesDemoteRequest',
    as InstanceOf['Google::Cloud::Sql::V1beta4::CloudSql::SqlInstancesDemoteRequest'];

coerce 'SqlInstancesDemoteRequest',
    from HashRef, via { 'Google::Cloud::Sql::V1beta4::CloudSql::SqlInstancesDemoteRequest'->new($_) };

declare 'RepeatedSqlInstancesDemoteRequest',
    as ArrayRef[SqlInstancesDemoteRequest()];

coerce 'RepeatedSqlInstancesDemoteRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1beta4::CloudSql::SqlInstancesDemoteRequest'->new($_) } @$_ ] };

declare 'MapStringSqlInstancesDemoteRequest',
    as HashRef[SqlInstancesDemoteRequest()];

declare 'SqlInstancesExportRequest',
    as InstanceOf['Google::Cloud::Sql::V1beta4::CloudSql::SqlInstancesExportRequest'];

coerce 'SqlInstancesExportRequest',
    from HashRef, via { 'Google::Cloud::Sql::V1beta4::CloudSql::SqlInstancesExportRequest'->new($_) };

declare 'RepeatedSqlInstancesExportRequest',
    as ArrayRef[SqlInstancesExportRequest()];

coerce 'RepeatedSqlInstancesExportRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1beta4::CloudSql::SqlInstancesExportRequest'->new($_) } @$_ ] };

declare 'MapStringSqlInstancesExportRequest',
    as HashRef[SqlInstancesExportRequest()];

declare 'SqlInstancesFailoverRequest',
    as InstanceOf['Google::Cloud::Sql::V1beta4::CloudSql::SqlInstancesFailoverRequest'];

coerce 'SqlInstancesFailoverRequest',
    from HashRef, via { 'Google::Cloud::Sql::V1beta4::CloudSql::SqlInstancesFailoverRequest'->new($_) };

declare 'RepeatedSqlInstancesFailoverRequest',
    as ArrayRef[SqlInstancesFailoverRequest()];

coerce 'RepeatedSqlInstancesFailoverRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1beta4::CloudSql::SqlInstancesFailoverRequest'->new($_) } @$_ ] };

declare 'MapStringSqlInstancesFailoverRequest',
    as HashRef[SqlInstancesFailoverRequest()];

declare 'SqlInstancesGetRequest',
    as InstanceOf['Google::Cloud::Sql::V1beta4::CloudSql::SqlInstancesGetRequest'];

coerce 'SqlInstancesGetRequest',
    from HashRef, via { 'Google::Cloud::Sql::V1beta4::CloudSql::SqlInstancesGetRequest'->new($_) };

declare 'RepeatedSqlInstancesGetRequest',
    as ArrayRef[SqlInstancesGetRequest()];

coerce 'RepeatedSqlInstancesGetRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1beta4::CloudSql::SqlInstancesGetRequest'->new($_) } @$_ ] };

declare 'MapStringSqlInstancesGetRequest',
    as HashRef[SqlInstancesGetRequest()];

declare 'SqlInstancesImportRequest',
    as InstanceOf['Google::Cloud::Sql::V1beta4::CloudSql::SqlInstancesImportRequest'];

coerce 'SqlInstancesImportRequest',
    from HashRef, via { 'Google::Cloud::Sql::V1beta4::CloudSql::SqlInstancesImportRequest'->new($_) };

declare 'RepeatedSqlInstancesImportRequest',
    as ArrayRef[SqlInstancesImportRequest()];

coerce 'RepeatedSqlInstancesImportRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1beta4::CloudSql::SqlInstancesImportRequest'->new($_) } @$_ ] };

declare 'MapStringSqlInstancesImportRequest',
    as HashRef[SqlInstancesImportRequest()];

declare 'SqlInstancesInsertRequest',
    as InstanceOf['Google::Cloud::Sql::V1beta4::CloudSql::SqlInstancesInsertRequest'];

coerce 'SqlInstancesInsertRequest',
    from HashRef, via { 'Google::Cloud::Sql::V1beta4::CloudSql::SqlInstancesInsertRequest'->new($_) };

declare 'RepeatedSqlInstancesInsertRequest',
    as ArrayRef[SqlInstancesInsertRequest()];

coerce 'RepeatedSqlInstancesInsertRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1beta4::CloudSql::SqlInstancesInsertRequest'->new($_) } @$_ ] };

declare 'MapStringSqlInstancesInsertRequest',
    as HashRef[SqlInstancesInsertRequest()];

declare 'SqlInstancesListRequest',
    as InstanceOf['Google::Cloud::Sql::V1beta4::CloudSql::SqlInstancesListRequest'];

coerce 'SqlInstancesListRequest',
    from HashRef, via { 'Google::Cloud::Sql::V1beta4::CloudSql::SqlInstancesListRequest'->new($_) };

declare 'RepeatedSqlInstancesListRequest',
    as ArrayRef[SqlInstancesListRequest()];

coerce 'RepeatedSqlInstancesListRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1beta4::CloudSql::SqlInstancesListRequest'->new($_) } @$_ ] };

declare 'MapStringSqlInstancesListRequest',
    as HashRef[SqlInstancesListRequest()];

declare 'SqlInstancesListServerCasRequest',
    as InstanceOf['Google::Cloud::Sql::V1beta4::CloudSql::SqlInstancesListServerCasRequest'];

coerce 'SqlInstancesListServerCasRequest',
    from HashRef, via { 'Google::Cloud::Sql::V1beta4::CloudSql::SqlInstancesListServerCasRequest'->new($_) };

declare 'RepeatedSqlInstancesListServerCasRequest',
    as ArrayRef[SqlInstancesListServerCasRequest()];

coerce 'RepeatedSqlInstancesListServerCasRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1beta4::CloudSql::SqlInstancesListServerCasRequest'->new($_) } @$_ ] };

declare 'MapStringSqlInstancesListServerCasRequest',
    as HashRef[SqlInstancesListServerCasRequest()];

declare 'SqlInstancesListServerCertificatesRequest',
    as InstanceOf['Google::Cloud::Sql::V1beta4::CloudSql::SqlInstancesListServerCertificatesRequest'];

coerce 'SqlInstancesListServerCertificatesRequest',
    from HashRef, via { 'Google::Cloud::Sql::V1beta4::CloudSql::SqlInstancesListServerCertificatesRequest'->new($_) };

declare 'RepeatedSqlInstancesListServerCertificatesRequest',
    as ArrayRef[SqlInstancesListServerCertificatesRequest()];

coerce 'RepeatedSqlInstancesListServerCertificatesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1beta4::CloudSql::SqlInstancesListServerCertificatesRequest'->new($_) } @$_ ] };

declare 'MapStringSqlInstancesListServerCertificatesRequest',
    as HashRef[SqlInstancesListServerCertificatesRequest()];

declare 'SqlInstancesListEntraIdCertificatesRequest',
    as InstanceOf['Google::Cloud::Sql::V1beta4::CloudSql::SqlInstancesListEntraIdCertificatesRequest'];

coerce 'SqlInstancesListEntraIdCertificatesRequest',
    from HashRef, via { 'Google::Cloud::Sql::V1beta4::CloudSql::SqlInstancesListEntraIdCertificatesRequest'->new($_) };

declare 'RepeatedSqlInstancesListEntraIdCertificatesRequest',
    as ArrayRef[SqlInstancesListEntraIdCertificatesRequest()];

coerce 'RepeatedSqlInstancesListEntraIdCertificatesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1beta4::CloudSql::SqlInstancesListEntraIdCertificatesRequest'->new($_) } @$_ ] };

declare 'MapStringSqlInstancesListEntraIdCertificatesRequest',
    as HashRef[SqlInstancesListEntraIdCertificatesRequest()];

declare 'SqlInstancesPatchRequest',
    as InstanceOf['Google::Cloud::Sql::V1beta4::CloudSql::SqlInstancesPatchRequest'];

coerce 'SqlInstancesPatchRequest',
    from HashRef, via { 'Google::Cloud::Sql::V1beta4::CloudSql::SqlInstancesPatchRequest'->new($_) };

declare 'RepeatedSqlInstancesPatchRequest',
    as ArrayRef[SqlInstancesPatchRequest()];

coerce 'RepeatedSqlInstancesPatchRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1beta4::CloudSql::SqlInstancesPatchRequest'->new($_) } @$_ ] };

declare 'MapStringSqlInstancesPatchRequest',
    as HashRef[SqlInstancesPatchRequest()];

declare 'SqlInstancesPromoteReplicaRequest',
    as InstanceOf['Google::Cloud::Sql::V1beta4::CloudSql::SqlInstancesPromoteReplicaRequest'];

coerce 'SqlInstancesPromoteReplicaRequest',
    from HashRef, via { 'Google::Cloud::Sql::V1beta4::CloudSql::SqlInstancesPromoteReplicaRequest'->new($_) };

declare 'RepeatedSqlInstancesPromoteReplicaRequest',
    as ArrayRef[SqlInstancesPromoteReplicaRequest()];

coerce 'RepeatedSqlInstancesPromoteReplicaRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1beta4::CloudSql::SqlInstancesPromoteReplicaRequest'->new($_) } @$_ ] };

declare 'MapStringSqlInstancesPromoteReplicaRequest',
    as HashRef[SqlInstancesPromoteReplicaRequest()];

declare 'SqlInstancesSwitchoverRequest',
    as InstanceOf['Google::Cloud::Sql::V1beta4::CloudSql::SqlInstancesSwitchoverRequest'];

coerce 'SqlInstancesSwitchoverRequest',
    from HashRef, via { 'Google::Cloud::Sql::V1beta4::CloudSql::SqlInstancesSwitchoverRequest'->new($_) };

declare 'RepeatedSqlInstancesSwitchoverRequest',
    as ArrayRef[SqlInstancesSwitchoverRequest()];

coerce 'RepeatedSqlInstancesSwitchoverRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1beta4::CloudSql::SqlInstancesSwitchoverRequest'->new($_) } @$_ ] };

declare 'MapStringSqlInstancesSwitchoverRequest',
    as HashRef[SqlInstancesSwitchoverRequest()];

declare 'SqlInstancesResetSslConfigRequest',
    as InstanceOf['Google::Cloud::Sql::V1beta4::CloudSql::SqlInstancesResetSslConfigRequest'];

coerce 'SqlInstancesResetSslConfigRequest',
    from HashRef, via { 'Google::Cloud::Sql::V1beta4::CloudSql::SqlInstancesResetSslConfigRequest'->new($_) };

declare 'RepeatedSqlInstancesResetSslConfigRequest',
    as ArrayRef[SqlInstancesResetSslConfigRequest()];

coerce 'RepeatedSqlInstancesResetSslConfigRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1beta4::CloudSql::SqlInstancesResetSslConfigRequest'->new($_) } @$_ ] };

declare 'MapStringSqlInstancesResetSslConfigRequest',
    as HashRef[SqlInstancesResetSslConfigRequest()];

declare 'ResetSslMode',
    as (Int | Str);

declare 'SqlInstancesRestartRequest',
    as InstanceOf['Google::Cloud::Sql::V1beta4::CloudSql::SqlInstancesRestartRequest'];

coerce 'SqlInstancesRestartRequest',
    from HashRef, via { 'Google::Cloud::Sql::V1beta4::CloudSql::SqlInstancesRestartRequest'->new($_) };

declare 'RepeatedSqlInstancesRestartRequest',
    as ArrayRef[SqlInstancesRestartRequest()];

coerce 'RepeatedSqlInstancesRestartRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1beta4::CloudSql::SqlInstancesRestartRequest'->new($_) } @$_ ] };

declare 'MapStringSqlInstancesRestartRequest',
    as HashRef[SqlInstancesRestartRequest()];

declare 'SqlInstancesStartRequest',
    as InstanceOf['Google::Cloud::Sql::V1beta4::CloudSql::SqlInstancesStartRequest'];

coerce 'SqlInstancesStartRequest',
    from HashRef, via { 'Google::Cloud::Sql::V1beta4::CloudSql::SqlInstancesStartRequest'->new($_) };

declare 'RepeatedSqlInstancesStartRequest',
    as ArrayRef[SqlInstancesStartRequest()];

coerce 'RepeatedSqlInstancesStartRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1beta4::CloudSql::SqlInstancesStartRequest'->new($_) } @$_ ] };

declare 'MapStringSqlInstancesStartRequest',
    as HashRef[SqlInstancesStartRequest()];

declare 'SqlInstancesStopRequest',
    as InstanceOf['Google::Cloud::Sql::V1beta4::CloudSql::SqlInstancesStopRequest'];

coerce 'SqlInstancesStopRequest',
    from HashRef, via { 'Google::Cloud::Sql::V1beta4::CloudSql::SqlInstancesStopRequest'->new($_) };

declare 'RepeatedSqlInstancesStopRequest',
    as ArrayRef[SqlInstancesStopRequest()];

coerce 'RepeatedSqlInstancesStopRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1beta4::CloudSql::SqlInstancesStopRequest'->new($_) } @$_ ] };

declare 'MapStringSqlInstancesStopRequest',
    as HashRef[SqlInstancesStopRequest()];

declare 'SqlInstancesRestoreBackupRequest',
    as InstanceOf['Google::Cloud::Sql::V1beta4::CloudSql::SqlInstancesRestoreBackupRequest'];

coerce 'SqlInstancesRestoreBackupRequest',
    from HashRef, via { 'Google::Cloud::Sql::V1beta4::CloudSql::SqlInstancesRestoreBackupRequest'->new($_) };

declare 'RepeatedSqlInstancesRestoreBackupRequest',
    as ArrayRef[SqlInstancesRestoreBackupRequest()];

coerce 'RepeatedSqlInstancesRestoreBackupRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1beta4::CloudSql::SqlInstancesRestoreBackupRequest'->new($_) } @$_ ] };

declare 'MapStringSqlInstancesRestoreBackupRequest',
    as HashRef[SqlInstancesRestoreBackupRequest()];

declare 'SqlInstancesRotateServerCaRequest',
    as InstanceOf['Google::Cloud::Sql::V1beta4::CloudSql::SqlInstancesRotateServerCaRequest'];

coerce 'SqlInstancesRotateServerCaRequest',
    from HashRef, via { 'Google::Cloud::Sql::V1beta4::CloudSql::SqlInstancesRotateServerCaRequest'->new($_) };

declare 'RepeatedSqlInstancesRotateServerCaRequest',
    as ArrayRef[SqlInstancesRotateServerCaRequest()];

coerce 'RepeatedSqlInstancesRotateServerCaRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1beta4::CloudSql::SqlInstancesRotateServerCaRequest'->new($_) } @$_ ] };

declare 'MapStringSqlInstancesRotateServerCaRequest',
    as HashRef[SqlInstancesRotateServerCaRequest()];

declare 'SqlInstancesRotateServerCertificateRequest',
    as InstanceOf['Google::Cloud::Sql::V1beta4::CloudSql::SqlInstancesRotateServerCertificateRequest'];

coerce 'SqlInstancesRotateServerCertificateRequest',
    from HashRef, via { 'Google::Cloud::Sql::V1beta4::CloudSql::SqlInstancesRotateServerCertificateRequest'->new($_) };

declare 'RepeatedSqlInstancesRotateServerCertificateRequest',
    as ArrayRef[SqlInstancesRotateServerCertificateRequest()];

coerce 'RepeatedSqlInstancesRotateServerCertificateRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1beta4::CloudSql::SqlInstancesRotateServerCertificateRequest'->new($_) } @$_ ] };

declare 'MapStringSqlInstancesRotateServerCertificateRequest',
    as HashRef[SqlInstancesRotateServerCertificateRequest()];

declare 'SqlInstancesRotateEntraIdCertificateRequest',
    as InstanceOf['Google::Cloud::Sql::V1beta4::CloudSql::SqlInstancesRotateEntraIdCertificateRequest'];

coerce 'SqlInstancesRotateEntraIdCertificateRequest',
    from HashRef, via { 'Google::Cloud::Sql::V1beta4::CloudSql::SqlInstancesRotateEntraIdCertificateRequest'->new($_) };

declare 'RepeatedSqlInstancesRotateEntraIdCertificateRequest',
    as ArrayRef[SqlInstancesRotateEntraIdCertificateRequest()];

coerce 'RepeatedSqlInstancesRotateEntraIdCertificateRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1beta4::CloudSql::SqlInstancesRotateEntraIdCertificateRequest'->new($_) } @$_ ] };

declare 'MapStringSqlInstancesRotateEntraIdCertificateRequest',
    as HashRef[SqlInstancesRotateEntraIdCertificateRequest()];

declare 'SqlInstancesStartReplicaRequest',
    as InstanceOf['Google::Cloud::Sql::V1beta4::CloudSql::SqlInstancesStartReplicaRequest'];

coerce 'SqlInstancesStartReplicaRequest',
    from HashRef, via { 'Google::Cloud::Sql::V1beta4::CloudSql::SqlInstancesStartReplicaRequest'->new($_) };

declare 'RepeatedSqlInstancesStartReplicaRequest',
    as ArrayRef[SqlInstancesStartReplicaRequest()];

coerce 'RepeatedSqlInstancesStartReplicaRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1beta4::CloudSql::SqlInstancesStartReplicaRequest'->new($_) } @$_ ] };

declare 'MapStringSqlInstancesStartReplicaRequest',
    as HashRef[SqlInstancesStartReplicaRequest()];

declare 'SqlInstancesStopReplicaRequest',
    as InstanceOf['Google::Cloud::Sql::V1beta4::CloudSql::SqlInstancesStopReplicaRequest'];

coerce 'SqlInstancesStopReplicaRequest',
    from HashRef, via { 'Google::Cloud::Sql::V1beta4::CloudSql::SqlInstancesStopReplicaRequest'->new($_) };

declare 'RepeatedSqlInstancesStopReplicaRequest',
    as ArrayRef[SqlInstancesStopReplicaRequest()];

coerce 'RepeatedSqlInstancesStopReplicaRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1beta4::CloudSql::SqlInstancesStopReplicaRequest'->new($_) } @$_ ] };

declare 'MapStringSqlInstancesStopReplicaRequest',
    as HashRef[SqlInstancesStopReplicaRequest()];

declare 'SqlInstancesTruncateLogRequest',
    as InstanceOf['Google::Cloud::Sql::V1beta4::CloudSql::SqlInstancesTruncateLogRequest'];

coerce 'SqlInstancesTruncateLogRequest',
    from HashRef, via { 'Google::Cloud::Sql::V1beta4::CloudSql::SqlInstancesTruncateLogRequest'->new($_) };

declare 'RepeatedSqlInstancesTruncateLogRequest',
    as ArrayRef[SqlInstancesTruncateLogRequest()];

coerce 'RepeatedSqlInstancesTruncateLogRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1beta4::CloudSql::SqlInstancesTruncateLogRequest'->new($_) } @$_ ] };

declare 'MapStringSqlInstancesTruncateLogRequest',
    as HashRef[SqlInstancesTruncateLogRequest()];

declare 'SqlInstancesUpdateRequest',
    as InstanceOf['Google::Cloud::Sql::V1beta4::CloudSql::SqlInstancesUpdateRequest'];

coerce 'SqlInstancesUpdateRequest',
    from HashRef, via { 'Google::Cloud::Sql::V1beta4::CloudSql::SqlInstancesUpdateRequest'->new($_) };

declare 'RepeatedSqlInstancesUpdateRequest',
    as ArrayRef[SqlInstancesUpdateRequest()];

coerce 'RepeatedSqlInstancesUpdateRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1beta4::CloudSql::SqlInstancesUpdateRequest'->new($_) } @$_ ] };

declare 'MapStringSqlInstancesUpdateRequest',
    as HashRef[SqlInstancesUpdateRequest()];

declare 'SqlInstancesReencryptRequest',
    as InstanceOf['Google::Cloud::Sql::V1beta4::CloudSql::SqlInstancesReencryptRequest'];

coerce 'SqlInstancesReencryptRequest',
    from HashRef, via { 'Google::Cloud::Sql::V1beta4::CloudSql::SqlInstancesReencryptRequest'->new($_) };

declare 'RepeatedSqlInstancesReencryptRequest',
    as ArrayRef[SqlInstancesReencryptRequest()];

coerce 'RepeatedSqlInstancesReencryptRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1beta4::CloudSql::SqlInstancesReencryptRequest'->new($_) } @$_ ] };

declare 'MapStringSqlInstancesReencryptRequest',
    as HashRef[SqlInstancesReencryptRequest()];

declare 'InstancesReencryptRequest',
    as InstanceOf['Google::Cloud::Sql::V1beta4::CloudSql::InstancesReencryptRequest'];

coerce 'InstancesReencryptRequest',
    from HashRef, via { 'Google::Cloud::Sql::V1beta4::CloudSql::InstancesReencryptRequest'->new($_) };

declare 'RepeatedInstancesReencryptRequest',
    as ArrayRef[InstancesReencryptRequest()];

coerce 'RepeatedInstancesReencryptRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1beta4::CloudSql::InstancesReencryptRequest'->new($_) } @$_ ] };

declare 'MapStringInstancesReencryptRequest',
    as HashRef[InstancesReencryptRequest()];

declare 'BackupReencryptionConfig',
    as InstanceOf['Google::Cloud::Sql::V1beta4::CloudSql::BackupReencryptionConfig'];

coerce 'BackupReencryptionConfig',
    from HashRef, via { 'Google::Cloud::Sql::V1beta4::CloudSql::BackupReencryptionConfig'->new($_) };

declare 'RepeatedBackupReencryptionConfig',
    as ArrayRef[BackupReencryptionConfig()];

coerce 'RepeatedBackupReencryptionConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1beta4::CloudSql::BackupReencryptionConfig'->new($_) } @$_ ] };

declare 'MapStringBackupReencryptionConfig',
    as HashRef[BackupReencryptionConfig()];

declare 'BackupType',
    as (Int | Str);

declare 'SqlInstancesRescheduleMaintenanceRequest',
    as InstanceOf['Google::Cloud::Sql::V1beta4::CloudSql::SqlInstancesRescheduleMaintenanceRequest'];

coerce 'SqlInstancesRescheduleMaintenanceRequest',
    from HashRef, via { 'Google::Cloud::Sql::V1beta4::CloudSql::SqlInstancesRescheduleMaintenanceRequest'->new($_) };

declare 'RepeatedSqlInstancesRescheduleMaintenanceRequest',
    as ArrayRef[SqlInstancesRescheduleMaintenanceRequest()];

coerce 'RepeatedSqlInstancesRescheduleMaintenanceRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1beta4::CloudSql::SqlInstancesRescheduleMaintenanceRequest'->new($_) } @$_ ] };

declare 'MapStringSqlInstancesRescheduleMaintenanceRequest',
    as HashRef[SqlInstancesRescheduleMaintenanceRequest()];

declare 'SqlInstancesPerformDiskShrinkRequest',
    as InstanceOf['Google::Cloud::Sql::V1beta4::CloudSql::SqlInstancesPerformDiskShrinkRequest'];

coerce 'SqlInstancesPerformDiskShrinkRequest',
    from HashRef, via { 'Google::Cloud::Sql::V1beta4::CloudSql::SqlInstancesPerformDiskShrinkRequest'->new($_) };

declare 'RepeatedSqlInstancesPerformDiskShrinkRequest',
    as ArrayRef[SqlInstancesPerformDiskShrinkRequest()];

coerce 'RepeatedSqlInstancesPerformDiskShrinkRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1beta4::CloudSql::SqlInstancesPerformDiskShrinkRequest'->new($_) } @$_ ] };

declare 'MapStringSqlInstancesPerformDiskShrinkRequest',
    as HashRef[SqlInstancesPerformDiskShrinkRequest()];

declare 'ExternalSyncSelectedObject',
    as InstanceOf['Google::Cloud::Sql::V1beta4::CloudSql::ExternalSyncSelectedObject'];

coerce 'ExternalSyncSelectedObject',
    from HashRef, via { 'Google::Cloud::Sql::V1beta4::CloudSql::ExternalSyncSelectedObject'->new($_) };

declare 'RepeatedExternalSyncSelectedObject',
    as ArrayRef[ExternalSyncSelectedObject()];

coerce 'RepeatedExternalSyncSelectedObject',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1beta4::CloudSql::ExternalSyncSelectedObject'->new($_) } @$_ ] };

declare 'MapStringExternalSyncSelectedObject',
    as HashRef[ExternalSyncSelectedObject()];

declare 'SqlInstancesVerifyExternalSyncSettingsRequest',
    as InstanceOf['Google::Cloud::Sql::V1beta4::CloudSql::SqlInstancesVerifyExternalSyncSettingsRequest'];

coerce 'SqlInstancesVerifyExternalSyncSettingsRequest',
    from HashRef, via { 'Google::Cloud::Sql::V1beta4::CloudSql::SqlInstancesVerifyExternalSyncSettingsRequest'->new($_) };

declare 'RepeatedSqlInstancesVerifyExternalSyncSettingsRequest',
    as ArrayRef[SqlInstancesVerifyExternalSyncSettingsRequest()];

coerce 'RepeatedSqlInstancesVerifyExternalSyncSettingsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1beta4::CloudSql::SqlInstancesVerifyExternalSyncSettingsRequest'->new($_) } @$_ ] };

declare 'MapStringSqlInstancesVerifyExternalSyncSettingsRequest',
    as HashRef[SqlInstancesVerifyExternalSyncSettingsRequest()];

declare 'ExternalSyncMode',
    as (Int | Str);

declare 'MigrationType',
    as (Int | Str);

declare 'SqlInstancesStartExternalSyncRequest',
    as InstanceOf['Google::Cloud::Sql::V1beta4::CloudSql::SqlInstancesStartExternalSyncRequest'];

coerce 'SqlInstancesStartExternalSyncRequest',
    from HashRef, via { 'Google::Cloud::Sql::V1beta4::CloudSql::SqlInstancesStartExternalSyncRequest'->new($_) };

declare 'RepeatedSqlInstancesStartExternalSyncRequest',
    as ArrayRef[SqlInstancesStartExternalSyncRequest()];

coerce 'RepeatedSqlInstancesStartExternalSyncRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1beta4::CloudSql::SqlInstancesStartExternalSyncRequest'->new($_) } @$_ ] };

declare 'MapStringSqlInstancesStartExternalSyncRequest',
    as HashRef[SqlInstancesStartExternalSyncRequest()];

declare 'SqlInstancesResetReplicaSizeRequest',
    as InstanceOf['Google::Cloud::Sql::V1beta4::CloudSql::SqlInstancesResetReplicaSizeRequest'];

coerce 'SqlInstancesResetReplicaSizeRequest',
    from HashRef, via { 'Google::Cloud::Sql::V1beta4::CloudSql::SqlInstancesResetReplicaSizeRequest'->new($_) };

declare 'RepeatedSqlInstancesResetReplicaSizeRequest',
    as ArrayRef[SqlInstancesResetReplicaSizeRequest()];

coerce 'RepeatedSqlInstancesResetReplicaSizeRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1beta4::CloudSql::SqlInstancesResetReplicaSizeRequest'->new($_) } @$_ ] };

declare 'MapStringSqlInstancesResetReplicaSizeRequest',
    as HashRef[SqlInstancesResetReplicaSizeRequest()];

declare 'SqlOperationsGetRequest',
    as InstanceOf['Google::Cloud::Sql::V1beta4::CloudSql::SqlOperationsGetRequest'];

coerce 'SqlOperationsGetRequest',
    from HashRef, via { 'Google::Cloud::Sql::V1beta4::CloudSql::SqlOperationsGetRequest'->new($_) };

declare 'RepeatedSqlOperationsGetRequest',
    as ArrayRef[SqlOperationsGetRequest()];

coerce 'RepeatedSqlOperationsGetRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1beta4::CloudSql::SqlOperationsGetRequest'->new($_) } @$_ ] };

declare 'MapStringSqlOperationsGetRequest',
    as HashRef[SqlOperationsGetRequest()];

declare 'SqlOperationsListRequest',
    as InstanceOf['Google::Cloud::Sql::V1beta4::CloudSql::SqlOperationsListRequest'];

coerce 'SqlOperationsListRequest',
    from HashRef, via { 'Google::Cloud::Sql::V1beta4::CloudSql::SqlOperationsListRequest'->new($_) };

declare 'RepeatedSqlOperationsListRequest',
    as ArrayRef[SqlOperationsListRequest()];

coerce 'RepeatedSqlOperationsListRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1beta4::CloudSql::SqlOperationsListRequest'->new($_) } @$_ ] };

declare 'MapStringSqlOperationsListRequest',
    as HashRef[SqlOperationsListRequest()];

declare 'SqlOperationsCancelRequest',
    as InstanceOf['Google::Cloud::Sql::V1beta4::CloudSql::SqlOperationsCancelRequest'];

coerce 'SqlOperationsCancelRequest',
    from HashRef, via { 'Google::Cloud::Sql::V1beta4::CloudSql::SqlOperationsCancelRequest'->new($_) };

declare 'RepeatedSqlOperationsCancelRequest',
    as ArrayRef[SqlOperationsCancelRequest()];

coerce 'RepeatedSqlOperationsCancelRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1beta4::CloudSql::SqlOperationsCancelRequest'->new($_) } @$_ ] };

declare 'MapStringSqlOperationsCancelRequest',
    as HashRef[SqlOperationsCancelRequest()];

declare 'SqlInstancesCreateEphemeralCertRequest',
    as InstanceOf['Google::Cloud::Sql::V1beta4::CloudSql::SqlInstancesCreateEphemeralCertRequest'];

coerce 'SqlInstancesCreateEphemeralCertRequest',
    from HashRef, via { 'Google::Cloud::Sql::V1beta4::CloudSql::SqlInstancesCreateEphemeralCertRequest'->new($_) };

declare 'RepeatedSqlInstancesCreateEphemeralCertRequest',
    as ArrayRef[SqlInstancesCreateEphemeralCertRequest()];

coerce 'RepeatedSqlInstancesCreateEphemeralCertRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1beta4::CloudSql::SqlInstancesCreateEphemeralCertRequest'->new($_) } @$_ ] };

declare 'MapStringSqlInstancesCreateEphemeralCertRequest',
    as HashRef[SqlInstancesCreateEphemeralCertRequest()];

declare 'SqlSslCertsDeleteRequest',
    as InstanceOf['Google::Cloud::Sql::V1beta4::CloudSql::SqlSslCertsDeleteRequest'];

coerce 'SqlSslCertsDeleteRequest',
    from HashRef, via { 'Google::Cloud::Sql::V1beta4::CloudSql::SqlSslCertsDeleteRequest'->new($_) };

declare 'RepeatedSqlSslCertsDeleteRequest',
    as ArrayRef[SqlSslCertsDeleteRequest()];

coerce 'RepeatedSqlSslCertsDeleteRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1beta4::CloudSql::SqlSslCertsDeleteRequest'->new($_) } @$_ ] };

declare 'MapStringSqlSslCertsDeleteRequest',
    as HashRef[SqlSslCertsDeleteRequest()];

declare 'SqlSslCertsGetRequest',
    as InstanceOf['Google::Cloud::Sql::V1beta4::CloudSql::SqlSslCertsGetRequest'];

coerce 'SqlSslCertsGetRequest',
    from HashRef, via { 'Google::Cloud::Sql::V1beta4::CloudSql::SqlSslCertsGetRequest'->new($_) };

declare 'RepeatedSqlSslCertsGetRequest',
    as ArrayRef[SqlSslCertsGetRequest()];

coerce 'RepeatedSqlSslCertsGetRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1beta4::CloudSql::SqlSslCertsGetRequest'->new($_) } @$_ ] };

declare 'MapStringSqlSslCertsGetRequest',
    as HashRef[SqlSslCertsGetRequest()];

declare 'SqlSslCertsInsertRequest',
    as InstanceOf['Google::Cloud::Sql::V1beta4::CloudSql::SqlSslCertsInsertRequest'];

coerce 'SqlSslCertsInsertRequest',
    from HashRef, via { 'Google::Cloud::Sql::V1beta4::CloudSql::SqlSslCertsInsertRequest'->new($_) };

declare 'RepeatedSqlSslCertsInsertRequest',
    as ArrayRef[SqlSslCertsInsertRequest()];

coerce 'RepeatedSqlSslCertsInsertRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1beta4::CloudSql::SqlSslCertsInsertRequest'->new($_) } @$_ ] };

declare 'MapStringSqlSslCertsInsertRequest',
    as HashRef[SqlSslCertsInsertRequest()];

declare 'SqlSslCertsListRequest',
    as InstanceOf['Google::Cloud::Sql::V1beta4::CloudSql::SqlSslCertsListRequest'];

coerce 'SqlSslCertsListRequest',
    from HashRef, via { 'Google::Cloud::Sql::V1beta4::CloudSql::SqlSslCertsListRequest'->new($_) };

declare 'RepeatedSqlSslCertsListRequest',
    as ArrayRef[SqlSslCertsListRequest()];

coerce 'RepeatedSqlSslCertsListRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1beta4::CloudSql::SqlSslCertsListRequest'->new($_) } @$_ ] };

declare 'MapStringSqlSslCertsListRequest',
    as HashRef[SqlSslCertsListRequest()];

declare 'SqlInstancesGetDiskShrinkConfigRequest',
    as InstanceOf['Google::Cloud::Sql::V1beta4::CloudSql::SqlInstancesGetDiskShrinkConfigRequest'];

coerce 'SqlInstancesGetDiskShrinkConfigRequest',
    from HashRef, via { 'Google::Cloud::Sql::V1beta4::CloudSql::SqlInstancesGetDiskShrinkConfigRequest'->new($_) };

declare 'RepeatedSqlInstancesGetDiskShrinkConfigRequest',
    as ArrayRef[SqlInstancesGetDiskShrinkConfigRequest()];

coerce 'RepeatedSqlInstancesGetDiskShrinkConfigRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1beta4::CloudSql::SqlInstancesGetDiskShrinkConfigRequest'->new($_) } @$_ ] };

declare 'MapStringSqlInstancesGetDiskShrinkConfigRequest',
    as HashRef[SqlInstancesGetDiskShrinkConfigRequest()];

declare 'SqlInstancesGetLatestRecoveryTimeRequest',
    as InstanceOf['Google::Cloud::Sql::V1beta4::CloudSql::SqlInstancesGetLatestRecoveryTimeRequest'];

coerce 'SqlInstancesGetLatestRecoveryTimeRequest',
    from HashRef, via { 'Google::Cloud::Sql::V1beta4::CloudSql::SqlInstancesGetLatestRecoveryTimeRequest'->new($_) };

declare 'RepeatedSqlInstancesGetLatestRecoveryTimeRequest',
    as ArrayRef[SqlInstancesGetLatestRecoveryTimeRequest()];

coerce 'RepeatedSqlInstancesGetLatestRecoveryTimeRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1beta4::CloudSql::SqlInstancesGetLatestRecoveryTimeRequest'->new($_) } @$_ ] };

declare 'MapStringSqlInstancesGetLatestRecoveryTimeRequest',
    as HashRef[SqlInstancesGetLatestRecoveryTimeRequest()];

declare 'SqlInstancesGetLatestRecoveryTimeResponse',
    as InstanceOf['Google::Cloud::Sql::V1beta4::CloudSql::SqlInstancesGetLatestRecoveryTimeResponse'];

coerce 'SqlInstancesGetLatestRecoveryTimeResponse',
    from HashRef, via { 'Google::Cloud::Sql::V1beta4::CloudSql::SqlInstancesGetLatestRecoveryTimeResponse'->new($_) };

declare 'RepeatedSqlInstancesGetLatestRecoveryTimeResponse',
    as ArrayRef[SqlInstancesGetLatestRecoveryTimeResponse()];

coerce 'RepeatedSqlInstancesGetLatestRecoveryTimeResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1beta4::CloudSql::SqlInstancesGetLatestRecoveryTimeResponse'->new($_) } @$_ ] };

declare 'MapStringSqlInstancesGetLatestRecoveryTimeResponse',
    as HashRef[SqlInstancesGetLatestRecoveryTimeResponse()];

declare 'SqlInstancesExecuteSqlReadOnlyRequest',
    as InstanceOf['Google::Cloud::Sql::V1beta4::CloudSql::SqlInstancesExecuteSqlReadOnlyRequest'];

coerce 'SqlInstancesExecuteSqlReadOnlyRequest',
    from HashRef, via { 'Google::Cloud::Sql::V1beta4::CloudSql::SqlInstancesExecuteSqlReadOnlyRequest'->new($_) };

declare 'RepeatedSqlInstancesExecuteSqlReadOnlyRequest',
    as ArrayRef[SqlInstancesExecuteSqlReadOnlyRequest()];

coerce 'RepeatedSqlInstancesExecuteSqlReadOnlyRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1beta4::CloudSql::SqlInstancesExecuteSqlReadOnlyRequest'->new($_) } @$_ ] };

declare 'MapStringSqlInstancesExecuteSqlReadOnlyRequest',
    as HashRef[SqlInstancesExecuteSqlReadOnlyRequest()];

declare 'SqlInstancesExecuteSqlRequest',
    as InstanceOf['Google::Cloud::Sql::V1beta4::CloudSql::SqlInstancesExecuteSqlRequest'];

coerce 'SqlInstancesExecuteSqlRequest',
    from HashRef, via { 'Google::Cloud::Sql::V1beta4::CloudSql::SqlInstancesExecuteSqlRequest'->new($_) };

declare 'RepeatedSqlInstancesExecuteSqlRequest',
    as ArrayRef[SqlInstancesExecuteSqlRequest()];

coerce 'RepeatedSqlInstancesExecuteSqlRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1beta4::CloudSql::SqlInstancesExecuteSqlRequest'->new($_) } @$_ ] };

declare 'MapStringSqlInstancesExecuteSqlRequest',
    as HashRef[SqlInstancesExecuteSqlRequest()];

declare 'SqlInstancesReleaseSsrsLeaseRequest',
    as InstanceOf['Google::Cloud::Sql::V1beta4::CloudSql::SqlInstancesReleaseSsrsLeaseRequest'];

coerce 'SqlInstancesReleaseSsrsLeaseRequest',
    from HashRef, via { 'Google::Cloud::Sql::V1beta4::CloudSql::SqlInstancesReleaseSsrsLeaseRequest'->new($_) };

declare 'RepeatedSqlInstancesReleaseSsrsLeaseRequest',
    as ArrayRef[SqlInstancesReleaseSsrsLeaseRequest()];

coerce 'RepeatedSqlInstancesReleaseSsrsLeaseRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1beta4::CloudSql::SqlInstancesReleaseSsrsLeaseRequest'->new($_) } @$_ ] };

declare 'MapStringSqlInstancesReleaseSsrsLeaseRequest',
    as HashRef[SqlInstancesReleaseSsrsLeaseRequest()];

declare 'SqlInstancesReleaseSsrsLeaseResponse',
    as InstanceOf['Google::Cloud::Sql::V1beta4::CloudSql::SqlInstancesReleaseSsrsLeaseResponse'];

coerce 'SqlInstancesReleaseSsrsLeaseResponse',
    from HashRef, via { 'Google::Cloud::Sql::V1beta4::CloudSql::SqlInstancesReleaseSsrsLeaseResponse'->new($_) };

declare 'RepeatedSqlInstancesReleaseSsrsLeaseResponse',
    as ArrayRef[SqlInstancesReleaseSsrsLeaseResponse()];

coerce 'RepeatedSqlInstancesReleaseSsrsLeaseResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1beta4::CloudSql::SqlInstancesReleaseSsrsLeaseResponse'->new($_) } @$_ ] };

declare 'MapStringSqlInstancesReleaseSsrsLeaseResponse',
    as HashRef[SqlInstancesReleaseSsrsLeaseResponse()];

declare 'ExecuteSqlReadOnlyPayload',
    as InstanceOf['Google::Cloud::Sql::V1beta4::CloudSql::ExecuteSqlReadOnlyPayload'];

coerce 'ExecuteSqlReadOnlyPayload',
    from HashRef, via { 'Google::Cloud::Sql::V1beta4::CloudSql::ExecuteSqlReadOnlyPayload'->new($_) };

declare 'RepeatedExecuteSqlReadOnlyPayload',
    as ArrayRef[ExecuteSqlReadOnlyPayload()];

coerce 'RepeatedExecuteSqlReadOnlyPayload',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1beta4::CloudSql::ExecuteSqlReadOnlyPayload'->new($_) } @$_ ] };

declare 'MapStringExecuteSqlReadOnlyPayload',
    as HashRef[ExecuteSqlReadOnlyPayload()];

declare 'ExecuteSqlPayload',
    as InstanceOf['Google::Cloud::Sql::V1beta4::CloudSql::ExecuteSqlPayload'];

coerce 'ExecuteSqlPayload',
    from HashRef, via { 'Google::Cloud::Sql::V1beta4::CloudSql::ExecuteSqlPayload'->new($_) };

declare 'RepeatedExecuteSqlPayload',
    as ArrayRef[ExecuteSqlPayload()];

coerce 'RepeatedExecuteSqlPayload',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1beta4::CloudSql::ExecuteSqlPayload'->new($_) } @$_ ] };

declare 'MapStringExecuteSqlPayload',
    as HashRef[ExecuteSqlPayload()];

declare 'PartialResultMode',
    as (Int | Str);

declare 'SqlInstancesExecuteSqlReadOnlyResponse',
    as InstanceOf['Google::Cloud::Sql::V1beta4::CloudSql::SqlInstancesExecuteSqlReadOnlyResponse'];

coerce 'SqlInstancesExecuteSqlReadOnlyResponse',
    from HashRef, via { 'Google::Cloud::Sql::V1beta4::CloudSql::SqlInstancesExecuteSqlReadOnlyResponse'->new($_) };

declare 'RepeatedSqlInstancesExecuteSqlReadOnlyResponse',
    as ArrayRef[SqlInstancesExecuteSqlReadOnlyResponse()];

coerce 'RepeatedSqlInstancesExecuteSqlReadOnlyResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1beta4::CloudSql::SqlInstancesExecuteSqlReadOnlyResponse'->new($_) } @$_ ] };

declare 'MapStringSqlInstancesExecuteSqlReadOnlyResponse',
    as HashRef[SqlInstancesExecuteSqlReadOnlyResponse()];

declare 'SqlInstancesExecuteSqlResponse',
    as InstanceOf['Google::Cloud::Sql::V1beta4::CloudSql::SqlInstancesExecuteSqlResponse'];

coerce 'SqlInstancesExecuteSqlResponse',
    from HashRef, via { 'Google::Cloud::Sql::V1beta4::CloudSql::SqlInstancesExecuteSqlResponse'->new($_) };

declare 'RepeatedSqlInstancesExecuteSqlResponse',
    as ArrayRef[SqlInstancesExecuteSqlResponse()];

coerce 'RepeatedSqlInstancesExecuteSqlResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1beta4::CloudSql::SqlInstancesExecuteSqlResponse'->new($_) } @$_ ] };

declare 'MapStringSqlInstancesExecuteSqlResponse',
    as HashRef[SqlInstancesExecuteSqlResponse()];

declare 'Message',
    as InstanceOf['Google::Cloud::Sql::V1beta4::CloudSql::SqlInstancesExecuteSqlResponse::Message'];

coerce 'Message',
    from HashRef, via { 'Google::Cloud::Sql::V1beta4::CloudSql::SqlInstancesExecuteSqlResponse::Message'->new($_) };

declare 'RepeatedMessage',
    as ArrayRef[Message()];

coerce 'RepeatedMessage',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1beta4::CloudSql::SqlInstancesExecuteSqlResponse::Message'->new($_) } @$_ ] };

declare 'MapStringMessage',
    as HashRef[Message()];

declare 'QueryResult',
    as InstanceOf['Google::Cloud::Sql::V1beta4::CloudSql::QueryResult'];

coerce 'QueryResult',
    from HashRef, via { 'Google::Cloud::Sql::V1beta4::CloudSql::QueryResult'->new($_) };

declare 'RepeatedQueryResult',
    as ArrayRef[QueryResult()];

coerce 'RepeatedQueryResult',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1beta4::CloudSql::QueryResult'->new($_) } @$_ ] };

declare 'MapStringQueryResult',
    as HashRef[QueryResult()];

declare 'Column',
    as InstanceOf['Google::Cloud::Sql::V1beta4::CloudSql::Column'];

coerce 'Column',
    from HashRef, via { 'Google::Cloud::Sql::V1beta4::CloudSql::Column'->new($_) };

declare 'RepeatedColumn',
    as ArrayRef[Column()];

coerce 'RepeatedColumn',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1beta4::CloudSql::Column'->new($_) } @$_ ] };

declare 'MapStringColumn',
    as HashRef[Column()];

declare 'Row',
    as InstanceOf['Google::Cloud::Sql::V1beta4::CloudSql::Row'];

coerce 'Row',
    from HashRef, via { 'Google::Cloud::Sql::V1beta4::CloudSql::Row'->new($_) };

declare 'RepeatedRow',
    as ArrayRef[Row()];

coerce 'RepeatedRow',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1beta4::CloudSql::Row'->new($_) } @$_ ] };

declare 'MapStringRow',
    as HashRef[Row()];

declare 'Value',
    as InstanceOf['Google::Cloud::Sql::V1beta4::CloudSql::Value'];

coerce 'Value',
    from HashRef, via { 'Google::Cloud::Sql::V1beta4::CloudSql::Value'->new($_) };

declare 'RepeatedValue',
    as ArrayRef[Value()];

coerce 'RepeatedValue',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1beta4::CloudSql::Value'->new($_) } @$_ ] };

declare 'MapStringValue',
    as HashRef[Value()];

declare 'Metadata',
    as InstanceOf['Google::Cloud::Sql::V1beta4::CloudSql::Metadata'];

coerce 'Metadata',
    from HashRef, via { 'Google::Cloud::Sql::V1beta4::CloudSql::Metadata'->new($_) };

declare 'RepeatedMetadata',
    as ArrayRef[Metadata()];

coerce 'RepeatedMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1beta4::CloudSql::Metadata'->new($_) } @$_ ] };

declare 'MapStringMetadata',
    as HashRef[Metadata()];

declare 'SqlInstancesAcquireSsrsLeaseRequest',
    as InstanceOf['Google::Cloud::Sql::V1beta4::CloudSql::SqlInstancesAcquireSsrsLeaseRequest'];

coerce 'SqlInstancesAcquireSsrsLeaseRequest',
    from HashRef, via { 'Google::Cloud::Sql::V1beta4::CloudSql::SqlInstancesAcquireSsrsLeaseRequest'->new($_) };

declare 'RepeatedSqlInstancesAcquireSsrsLeaseRequest',
    as ArrayRef[SqlInstancesAcquireSsrsLeaseRequest()];

coerce 'RepeatedSqlInstancesAcquireSsrsLeaseRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1beta4::CloudSql::SqlInstancesAcquireSsrsLeaseRequest'->new($_) } @$_ ] };

declare 'MapStringSqlInstancesAcquireSsrsLeaseRequest',
    as HashRef[SqlInstancesAcquireSsrsLeaseRequest()];

declare 'SqlInstancesPreCheckMajorVersionUpgradeRequest',
    as InstanceOf['Google::Cloud::Sql::V1beta4::CloudSql::SqlInstancesPreCheckMajorVersionUpgradeRequest'];

coerce 'SqlInstancesPreCheckMajorVersionUpgradeRequest',
    from HashRef, via { 'Google::Cloud::Sql::V1beta4::CloudSql::SqlInstancesPreCheckMajorVersionUpgradeRequest'->new($_) };

declare 'RepeatedSqlInstancesPreCheckMajorVersionUpgradeRequest',
    as ArrayRef[SqlInstancesPreCheckMajorVersionUpgradeRequest()];

coerce 'RepeatedSqlInstancesPreCheckMajorVersionUpgradeRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1beta4::CloudSql::SqlInstancesPreCheckMajorVersionUpgradeRequest'->new($_) } @$_ ] };

declare 'MapStringSqlInstancesPreCheckMajorVersionUpgradeRequest',
    as HashRef[SqlInstancesPreCheckMajorVersionUpgradeRequest()];

declare 'SqlInstancesAcquireSsrsLeaseResponse',
    as InstanceOf['Google::Cloud::Sql::V1beta4::CloudSql::SqlInstancesAcquireSsrsLeaseResponse'];

coerce 'SqlInstancesAcquireSsrsLeaseResponse',
    from HashRef, via { 'Google::Cloud::Sql::V1beta4::CloudSql::SqlInstancesAcquireSsrsLeaseResponse'->new($_) };

declare 'RepeatedSqlInstancesAcquireSsrsLeaseResponse',
    as ArrayRef[SqlInstancesAcquireSsrsLeaseResponse()];

coerce 'RepeatedSqlInstancesAcquireSsrsLeaseResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1beta4::CloudSql::SqlInstancesAcquireSsrsLeaseResponse'->new($_) } @$_ ] };

declare 'MapStringSqlInstancesAcquireSsrsLeaseResponse',
    as HashRef[SqlInstancesAcquireSsrsLeaseResponse()];

declare 'SqlInstancesPointInTimeRestoreRequest',
    as InstanceOf['Google::Cloud::Sql::V1beta4::CloudSql::SqlInstancesPointInTimeRestoreRequest'];

coerce 'SqlInstancesPointInTimeRestoreRequest',
    from HashRef, via { 'Google::Cloud::Sql::V1beta4::CloudSql::SqlInstancesPointInTimeRestoreRequest'->new($_) };

declare 'RepeatedSqlInstancesPointInTimeRestoreRequest',
    as ArrayRef[SqlInstancesPointInTimeRestoreRequest()];

coerce 'RepeatedSqlInstancesPointInTimeRestoreRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1beta4::CloudSql::SqlInstancesPointInTimeRestoreRequest'->new($_) } @$_ ] };

declare 'MapStringSqlInstancesPointInTimeRestoreRequest',
    as HashRef[SqlInstancesPointInTimeRestoreRequest()];

declare 'SqlInstancesReconcileNetworkingRequest',
    as InstanceOf['Google::Cloud::Sql::V1beta4::CloudSql::SqlInstancesReconcileNetworkingRequest'];

coerce 'SqlInstancesReconcileNetworkingRequest',
    from HashRef, via { 'Google::Cloud::Sql::V1beta4::CloudSql::SqlInstancesReconcileNetworkingRequest'->new($_) };

declare 'RepeatedSqlInstancesReconcileNetworkingRequest',
    as ArrayRef[SqlInstancesReconcileNetworkingRequest()];

coerce 'RepeatedSqlInstancesReconcileNetworkingRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1beta4::CloudSql::SqlInstancesReconcileNetworkingRequest'->new($_) } @$_ ] };

declare 'MapStringSqlInstancesReconcileNetworkingRequest',
    as HashRef[SqlInstancesReconcileNetworkingRequest()];

declare 'PscDnsReconcileNetworkingRequest',
    as InstanceOf['Google::Cloud::Sql::V1beta4::CloudSql::PscDnsReconcileNetworkingRequest'];

coerce 'PscDnsReconcileNetworkingRequest',
    from HashRef, via { 'Google::Cloud::Sql::V1beta4::CloudSql::PscDnsReconcileNetworkingRequest'->new($_) };

declare 'RepeatedPscDnsReconcileNetworkingRequest',
    as ArrayRef[PscDnsReconcileNetworkingRequest()];

coerce 'RepeatedPscDnsReconcileNetworkingRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1beta4::CloudSql::PscDnsReconcileNetworkingRequest'->new($_) } @$_ ] };

declare 'MapStringPscDnsReconcileNetworkingRequest',
    as HashRef[PscDnsReconcileNetworkingRequest()];

1;

__END__

=head1 NAME

Google::Cloud::Sql::V1beta4::CloudSql::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
