package Google::Firestore::Admin::V1::FirestoreAdmin::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'ListDatabasesRequest',
    as InstanceOf['Google::Firestore::Admin::V1::FirestoreAdmin::ListDatabasesRequest'];

coerce 'ListDatabasesRequest',
    from HashRef, via { 'Google::Firestore::Admin::V1::FirestoreAdmin::ListDatabasesRequest'->new($_) };

declare 'RepeatedListDatabasesRequest',
    as ArrayRef[ListDatabasesRequest()];

coerce 'RepeatedListDatabasesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Firestore::Admin::V1::FirestoreAdmin::ListDatabasesRequest'->new($_) } @$_ ] };

declare 'MapStringListDatabasesRequest',
    as HashRef[ListDatabasesRequest()];

declare 'CreateDatabaseRequest',
    as InstanceOf['Google::Firestore::Admin::V1::FirestoreAdmin::CreateDatabaseRequest'];

coerce 'CreateDatabaseRequest',
    from HashRef, via { 'Google::Firestore::Admin::V1::FirestoreAdmin::CreateDatabaseRequest'->new($_) };

declare 'RepeatedCreateDatabaseRequest',
    as ArrayRef[CreateDatabaseRequest()];

coerce 'RepeatedCreateDatabaseRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Firestore::Admin::V1::FirestoreAdmin::CreateDatabaseRequest'->new($_) } @$_ ] };

declare 'MapStringCreateDatabaseRequest',
    as HashRef[CreateDatabaseRequest()];

declare 'CreateDatabaseMetadata',
    as InstanceOf['Google::Firestore::Admin::V1::FirestoreAdmin::CreateDatabaseMetadata'];

coerce 'CreateDatabaseMetadata',
    from HashRef, via { 'Google::Firestore::Admin::V1::FirestoreAdmin::CreateDatabaseMetadata'->new($_) };

declare 'RepeatedCreateDatabaseMetadata',
    as ArrayRef[CreateDatabaseMetadata()];

coerce 'RepeatedCreateDatabaseMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Firestore::Admin::V1::FirestoreAdmin::CreateDatabaseMetadata'->new($_) } @$_ ] };

declare 'MapStringCreateDatabaseMetadata',
    as HashRef[CreateDatabaseMetadata()];

declare 'ListDatabasesResponse',
    as InstanceOf['Google::Firestore::Admin::V1::FirestoreAdmin::ListDatabasesResponse'];

coerce 'ListDatabasesResponse',
    from HashRef, via { 'Google::Firestore::Admin::V1::FirestoreAdmin::ListDatabasesResponse'->new($_) };

declare 'RepeatedListDatabasesResponse',
    as ArrayRef[ListDatabasesResponse()];

coerce 'RepeatedListDatabasesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Firestore::Admin::V1::FirestoreAdmin::ListDatabasesResponse'->new($_) } @$_ ] };

declare 'MapStringListDatabasesResponse',
    as HashRef[ListDatabasesResponse()];

declare 'GetDatabaseRequest',
    as InstanceOf['Google::Firestore::Admin::V1::FirestoreAdmin::GetDatabaseRequest'];

coerce 'GetDatabaseRequest',
    from HashRef, via { 'Google::Firestore::Admin::V1::FirestoreAdmin::GetDatabaseRequest'->new($_) };

declare 'RepeatedGetDatabaseRequest',
    as ArrayRef[GetDatabaseRequest()];

coerce 'RepeatedGetDatabaseRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Firestore::Admin::V1::FirestoreAdmin::GetDatabaseRequest'->new($_) } @$_ ] };

declare 'MapStringGetDatabaseRequest',
    as HashRef[GetDatabaseRequest()];

declare 'UpdateDatabaseRequest',
    as InstanceOf['Google::Firestore::Admin::V1::FirestoreAdmin::UpdateDatabaseRequest'];

coerce 'UpdateDatabaseRequest',
    from HashRef, via { 'Google::Firestore::Admin::V1::FirestoreAdmin::UpdateDatabaseRequest'->new($_) };

declare 'RepeatedUpdateDatabaseRequest',
    as ArrayRef[UpdateDatabaseRequest()];

coerce 'RepeatedUpdateDatabaseRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Firestore::Admin::V1::FirestoreAdmin::UpdateDatabaseRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateDatabaseRequest',
    as HashRef[UpdateDatabaseRequest()];

declare 'UpdateDatabaseMetadata',
    as InstanceOf['Google::Firestore::Admin::V1::FirestoreAdmin::UpdateDatabaseMetadata'];

coerce 'UpdateDatabaseMetadata',
    from HashRef, via { 'Google::Firestore::Admin::V1::FirestoreAdmin::UpdateDatabaseMetadata'->new($_) };

declare 'RepeatedUpdateDatabaseMetadata',
    as ArrayRef[UpdateDatabaseMetadata()];

coerce 'RepeatedUpdateDatabaseMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Firestore::Admin::V1::FirestoreAdmin::UpdateDatabaseMetadata'->new($_) } @$_ ] };

declare 'MapStringUpdateDatabaseMetadata',
    as HashRef[UpdateDatabaseMetadata()];

declare 'DeleteDatabaseRequest',
    as InstanceOf['Google::Firestore::Admin::V1::FirestoreAdmin::DeleteDatabaseRequest'];

coerce 'DeleteDatabaseRequest',
    from HashRef, via { 'Google::Firestore::Admin::V1::FirestoreAdmin::DeleteDatabaseRequest'->new($_) };

declare 'RepeatedDeleteDatabaseRequest',
    as ArrayRef[DeleteDatabaseRequest()];

coerce 'RepeatedDeleteDatabaseRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Firestore::Admin::V1::FirestoreAdmin::DeleteDatabaseRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteDatabaseRequest',
    as HashRef[DeleteDatabaseRequest()];

declare 'DeleteDatabaseMetadata',
    as InstanceOf['Google::Firestore::Admin::V1::FirestoreAdmin::DeleteDatabaseMetadata'];

coerce 'DeleteDatabaseMetadata',
    from HashRef, via { 'Google::Firestore::Admin::V1::FirestoreAdmin::DeleteDatabaseMetadata'->new($_) };

declare 'RepeatedDeleteDatabaseMetadata',
    as ArrayRef[DeleteDatabaseMetadata()];

coerce 'RepeatedDeleteDatabaseMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Firestore::Admin::V1::FirestoreAdmin::DeleteDatabaseMetadata'->new($_) } @$_ ] };

declare 'MapStringDeleteDatabaseMetadata',
    as HashRef[DeleteDatabaseMetadata()];

declare 'CreateUserCredsRequest',
    as InstanceOf['Google::Firestore::Admin::V1::FirestoreAdmin::CreateUserCredsRequest'];

coerce 'CreateUserCredsRequest',
    from HashRef, via { 'Google::Firestore::Admin::V1::FirestoreAdmin::CreateUserCredsRequest'->new($_) };

declare 'RepeatedCreateUserCredsRequest',
    as ArrayRef[CreateUserCredsRequest()];

coerce 'RepeatedCreateUserCredsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Firestore::Admin::V1::FirestoreAdmin::CreateUserCredsRequest'->new($_) } @$_ ] };

declare 'MapStringCreateUserCredsRequest',
    as HashRef[CreateUserCredsRequest()];

declare 'GetUserCredsRequest',
    as InstanceOf['Google::Firestore::Admin::V1::FirestoreAdmin::GetUserCredsRequest'];

coerce 'GetUserCredsRequest',
    from HashRef, via { 'Google::Firestore::Admin::V1::FirestoreAdmin::GetUserCredsRequest'->new($_) };

declare 'RepeatedGetUserCredsRequest',
    as ArrayRef[GetUserCredsRequest()];

coerce 'RepeatedGetUserCredsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Firestore::Admin::V1::FirestoreAdmin::GetUserCredsRequest'->new($_) } @$_ ] };

declare 'MapStringGetUserCredsRequest',
    as HashRef[GetUserCredsRequest()];

declare 'ListUserCredsRequest',
    as InstanceOf['Google::Firestore::Admin::V1::FirestoreAdmin::ListUserCredsRequest'];

coerce 'ListUserCredsRequest',
    from HashRef, via { 'Google::Firestore::Admin::V1::FirestoreAdmin::ListUserCredsRequest'->new($_) };

declare 'RepeatedListUserCredsRequest',
    as ArrayRef[ListUserCredsRequest()];

coerce 'RepeatedListUserCredsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Firestore::Admin::V1::FirestoreAdmin::ListUserCredsRequest'->new($_) } @$_ ] };

declare 'MapStringListUserCredsRequest',
    as HashRef[ListUserCredsRequest()];

declare 'ListUserCredsResponse',
    as InstanceOf['Google::Firestore::Admin::V1::FirestoreAdmin::ListUserCredsResponse'];

coerce 'ListUserCredsResponse',
    from HashRef, via { 'Google::Firestore::Admin::V1::FirestoreAdmin::ListUserCredsResponse'->new($_) };

declare 'RepeatedListUserCredsResponse',
    as ArrayRef[ListUserCredsResponse()];

coerce 'RepeatedListUserCredsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Firestore::Admin::V1::FirestoreAdmin::ListUserCredsResponse'->new($_) } @$_ ] };

declare 'MapStringListUserCredsResponse',
    as HashRef[ListUserCredsResponse()];

declare 'EnableUserCredsRequest',
    as InstanceOf['Google::Firestore::Admin::V1::FirestoreAdmin::EnableUserCredsRequest'];

coerce 'EnableUserCredsRequest',
    from HashRef, via { 'Google::Firestore::Admin::V1::FirestoreAdmin::EnableUserCredsRequest'->new($_) };

declare 'RepeatedEnableUserCredsRequest',
    as ArrayRef[EnableUserCredsRequest()];

coerce 'RepeatedEnableUserCredsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Firestore::Admin::V1::FirestoreAdmin::EnableUserCredsRequest'->new($_) } @$_ ] };

declare 'MapStringEnableUserCredsRequest',
    as HashRef[EnableUserCredsRequest()];

declare 'DisableUserCredsRequest',
    as InstanceOf['Google::Firestore::Admin::V1::FirestoreAdmin::DisableUserCredsRequest'];

coerce 'DisableUserCredsRequest',
    from HashRef, via { 'Google::Firestore::Admin::V1::FirestoreAdmin::DisableUserCredsRequest'->new($_) };

declare 'RepeatedDisableUserCredsRequest',
    as ArrayRef[DisableUserCredsRequest()];

coerce 'RepeatedDisableUserCredsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Firestore::Admin::V1::FirestoreAdmin::DisableUserCredsRequest'->new($_) } @$_ ] };

declare 'MapStringDisableUserCredsRequest',
    as HashRef[DisableUserCredsRequest()];

declare 'ResetUserPasswordRequest',
    as InstanceOf['Google::Firestore::Admin::V1::FirestoreAdmin::ResetUserPasswordRequest'];

coerce 'ResetUserPasswordRequest',
    from HashRef, via { 'Google::Firestore::Admin::V1::FirestoreAdmin::ResetUserPasswordRequest'->new($_) };

declare 'RepeatedResetUserPasswordRequest',
    as ArrayRef[ResetUserPasswordRequest()];

coerce 'RepeatedResetUserPasswordRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Firestore::Admin::V1::FirestoreAdmin::ResetUserPasswordRequest'->new($_) } @$_ ] };

declare 'MapStringResetUserPasswordRequest',
    as HashRef[ResetUserPasswordRequest()];

declare 'DeleteUserCredsRequest',
    as InstanceOf['Google::Firestore::Admin::V1::FirestoreAdmin::DeleteUserCredsRequest'];

coerce 'DeleteUserCredsRequest',
    from HashRef, via { 'Google::Firestore::Admin::V1::FirestoreAdmin::DeleteUserCredsRequest'->new($_) };

declare 'RepeatedDeleteUserCredsRequest',
    as ArrayRef[DeleteUserCredsRequest()];

coerce 'RepeatedDeleteUserCredsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Firestore::Admin::V1::FirestoreAdmin::DeleteUserCredsRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteUserCredsRequest',
    as HashRef[DeleteUserCredsRequest()];

declare 'CreateBackupScheduleRequest',
    as InstanceOf['Google::Firestore::Admin::V1::FirestoreAdmin::CreateBackupScheduleRequest'];

coerce 'CreateBackupScheduleRequest',
    from HashRef, via { 'Google::Firestore::Admin::V1::FirestoreAdmin::CreateBackupScheduleRequest'->new($_) };

declare 'RepeatedCreateBackupScheduleRequest',
    as ArrayRef[CreateBackupScheduleRequest()];

coerce 'RepeatedCreateBackupScheduleRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Firestore::Admin::V1::FirestoreAdmin::CreateBackupScheduleRequest'->new($_) } @$_ ] };

declare 'MapStringCreateBackupScheduleRequest',
    as HashRef[CreateBackupScheduleRequest()];

declare 'GetBackupScheduleRequest',
    as InstanceOf['Google::Firestore::Admin::V1::FirestoreAdmin::GetBackupScheduleRequest'];

coerce 'GetBackupScheduleRequest',
    from HashRef, via { 'Google::Firestore::Admin::V1::FirestoreAdmin::GetBackupScheduleRequest'->new($_) };

declare 'RepeatedGetBackupScheduleRequest',
    as ArrayRef[GetBackupScheduleRequest()];

coerce 'RepeatedGetBackupScheduleRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Firestore::Admin::V1::FirestoreAdmin::GetBackupScheduleRequest'->new($_) } @$_ ] };

declare 'MapStringGetBackupScheduleRequest',
    as HashRef[GetBackupScheduleRequest()];

declare 'UpdateBackupScheduleRequest',
    as InstanceOf['Google::Firestore::Admin::V1::FirestoreAdmin::UpdateBackupScheduleRequest'];

coerce 'UpdateBackupScheduleRequest',
    from HashRef, via { 'Google::Firestore::Admin::V1::FirestoreAdmin::UpdateBackupScheduleRequest'->new($_) };

declare 'RepeatedUpdateBackupScheduleRequest',
    as ArrayRef[UpdateBackupScheduleRequest()];

coerce 'RepeatedUpdateBackupScheduleRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Firestore::Admin::V1::FirestoreAdmin::UpdateBackupScheduleRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateBackupScheduleRequest',
    as HashRef[UpdateBackupScheduleRequest()];

declare 'ListBackupSchedulesRequest',
    as InstanceOf['Google::Firestore::Admin::V1::FirestoreAdmin::ListBackupSchedulesRequest'];

coerce 'ListBackupSchedulesRequest',
    from HashRef, via { 'Google::Firestore::Admin::V1::FirestoreAdmin::ListBackupSchedulesRequest'->new($_) };

declare 'RepeatedListBackupSchedulesRequest',
    as ArrayRef[ListBackupSchedulesRequest()];

coerce 'RepeatedListBackupSchedulesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Firestore::Admin::V1::FirestoreAdmin::ListBackupSchedulesRequest'->new($_) } @$_ ] };

declare 'MapStringListBackupSchedulesRequest',
    as HashRef[ListBackupSchedulesRequest()];

declare 'ListBackupSchedulesResponse',
    as InstanceOf['Google::Firestore::Admin::V1::FirestoreAdmin::ListBackupSchedulesResponse'];

coerce 'ListBackupSchedulesResponse',
    from HashRef, via { 'Google::Firestore::Admin::V1::FirestoreAdmin::ListBackupSchedulesResponse'->new($_) };

declare 'RepeatedListBackupSchedulesResponse',
    as ArrayRef[ListBackupSchedulesResponse()];

coerce 'RepeatedListBackupSchedulesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Firestore::Admin::V1::FirestoreAdmin::ListBackupSchedulesResponse'->new($_) } @$_ ] };

declare 'MapStringListBackupSchedulesResponse',
    as HashRef[ListBackupSchedulesResponse()];

declare 'DeleteBackupScheduleRequest',
    as InstanceOf['Google::Firestore::Admin::V1::FirestoreAdmin::DeleteBackupScheduleRequest'];

coerce 'DeleteBackupScheduleRequest',
    from HashRef, via { 'Google::Firestore::Admin::V1::FirestoreAdmin::DeleteBackupScheduleRequest'->new($_) };

declare 'RepeatedDeleteBackupScheduleRequest',
    as ArrayRef[DeleteBackupScheduleRequest()];

coerce 'RepeatedDeleteBackupScheduleRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Firestore::Admin::V1::FirestoreAdmin::DeleteBackupScheduleRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteBackupScheduleRequest',
    as HashRef[DeleteBackupScheduleRequest()];

declare 'CreateIndexRequest',
    as InstanceOf['Google::Firestore::Admin::V1::FirestoreAdmin::CreateIndexRequest'];

coerce 'CreateIndexRequest',
    from HashRef, via { 'Google::Firestore::Admin::V1::FirestoreAdmin::CreateIndexRequest'->new($_) };

declare 'RepeatedCreateIndexRequest',
    as ArrayRef[CreateIndexRequest()];

coerce 'RepeatedCreateIndexRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Firestore::Admin::V1::FirestoreAdmin::CreateIndexRequest'->new($_) } @$_ ] };

declare 'MapStringCreateIndexRequest',
    as HashRef[CreateIndexRequest()];

declare 'ListIndexesRequest',
    as InstanceOf['Google::Firestore::Admin::V1::FirestoreAdmin::ListIndexesRequest'];

coerce 'ListIndexesRequest',
    from HashRef, via { 'Google::Firestore::Admin::V1::FirestoreAdmin::ListIndexesRequest'->new($_) };

declare 'RepeatedListIndexesRequest',
    as ArrayRef[ListIndexesRequest()];

coerce 'RepeatedListIndexesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Firestore::Admin::V1::FirestoreAdmin::ListIndexesRequest'->new($_) } @$_ ] };

declare 'MapStringListIndexesRequest',
    as HashRef[ListIndexesRequest()];

declare 'ListIndexesResponse',
    as InstanceOf['Google::Firestore::Admin::V1::FirestoreAdmin::ListIndexesResponse'];

coerce 'ListIndexesResponse',
    from HashRef, via { 'Google::Firestore::Admin::V1::FirestoreAdmin::ListIndexesResponse'->new($_) };

declare 'RepeatedListIndexesResponse',
    as ArrayRef[ListIndexesResponse()];

coerce 'RepeatedListIndexesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Firestore::Admin::V1::FirestoreAdmin::ListIndexesResponse'->new($_) } @$_ ] };

declare 'MapStringListIndexesResponse',
    as HashRef[ListIndexesResponse()];

declare 'GetIndexRequest',
    as InstanceOf['Google::Firestore::Admin::V1::FirestoreAdmin::GetIndexRequest'];

coerce 'GetIndexRequest',
    from HashRef, via { 'Google::Firestore::Admin::V1::FirestoreAdmin::GetIndexRequest'->new($_) };

declare 'RepeatedGetIndexRequest',
    as ArrayRef[GetIndexRequest()];

coerce 'RepeatedGetIndexRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Firestore::Admin::V1::FirestoreAdmin::GetIndexRequest'->new($_) } @$_ ] };

declare 'MapStringGetIndexRequest',
    as HashRef[GetIndexRequest()];

declare 'DeleteIndexRequest',
    as InstanceOf['Google::Firestore::Admin::V1::FirestoreAdmin::DeleteIndexRequest'];

coerce 'DeleteIndexRequest',
    from HashRef, via { 'Google::Firestore::Admin::V1::FirestoreAdmin::DeleteIndexRequest'->new($_) };

declare 'RepeatedDeleteIndexRequest',
    as ArrayRef[DeleteIndexRequest()];

coerce 'RepeatedDeleteIndexRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Firestore::Admin::V1::FirestoreAdmin::DeleteIndexRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteIndexRequest',
    as HashRef[DeleteIndexRequest()];

declare 'UpdateFieldRequest',
    as InstanceOf['Google::Firestore::Admin::V1::FirestoreAdmin::UpdateFieldRequest'];

coerce 'UpdateFieldRequest',
    from HashRef, via { 'Google::Firestore::Admin::V1::FirestoreAdmin::UpdateFieldRequest'->new($_) };

declare 'RepeatedUpdateFieldRequest',
    as ArrayRef[UpdateFieldRequest()];

coerce 'RepeatedUpdateFieldRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Firestore::Admin::V1::FirestoreAdmin::UpdateFieldRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateFieldRequest',
    as HashRef[UpdateFieldRequest()];

declare 'GetFieldRequest',
    as InstanceOf['Google::Firestore::Admin::V1::FirestoreAdmin::GetFieldRequest'];

coerce 'GetFieldRequest',
    from HashRef, via { 'Google::Firestore::Admin::V1::FirestoreAdmin::GetFieldRequest'->new($_) };

declare 'RepeatedGetFieldRequest',
    as ArrayRef[GetFieldRequest()];

coerce 'RepeatedGetFieldRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Firestore::Admin::V1::FirestoreAdmin::GetFieldRequest'->new($_) } @$_ ] };

declare 'MapStringGetFieldRequest',
    as HashRef[GetFieldRequest()];

declare 'ListFieldsRequest',
    as InstanceOf['Google::Firestore::Admin::V1::FirestoreAdmin::ListFieldsRequest'];

coerce 'ListFieldsRequest',
    from HashRef, via { 'Google::Firestore::Admin::V1::FirestoreAdmin::ListFieldsRequest'->new($_) };

declare 'RepeatedListFieldsRequest',
    as ArrayRef[ListFieldsRequest()];

coerce 'RepeatedListFieldsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Firestore::Admin::V1::FirestoreAdmin::ListFieldsRequest'->new($_) } @$_ ] };

declare 'MapStringListFieldsRequest',
    as HashRef[ListFieldsRequest()];

declare 'ListFieldsResponse',
    as InstanceOf['Google::Firestore::Admin::V1::FirestoreAdmin::ListFieldsResponse'];

coerce 'ListFieldsResponse',
    from HashRef, via { 'Google::Firestore::Admin::V1::FirestoreAdmin::ListFieldsResponse'->new($_) };

declare 'RepeatedListFieldsResponse',
    as ArrayRef[ListFieldsResponse()];

coerce 'RepeatedListFieldsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Firestore::Admin::V1::FirestoreAdmin::ListFieldsResponse'->new($_) } @$_ ] };

declare 'MapStringListFieldsResponse',
    as HashRef[ListFieldsResponse()];

declare 'ExportDocumentsRequest',
    as InstanceOf['Google::Firestore::Admin::V1::FirestoreAdmin::ExportDocumentsRequest'];

coerce 'ExportDocumentsRequest',
    from HashRef, via { 'Google::Firestore::Admin::V1::FirestoreAdmin::ExportDocumentsRequest'->new($_) };

declare 'RepeatedExportDocumentsRequest',
    as ArrayRef[ExportDocumentsRequest()];

coerce 'RepeatedExportDocumentsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Firestore::Admin::V1::FirestoreAdmin::ExportDocumentsRequest'->new($_) } @$_ ] };

declare 'MapStringExportDocumentsRequest',
    as HashRef[ExportDocumentsRequest()];

declare 'ImportDocumentsRequest',
    as InstanceOf['Google::Firestore::Admin::V1::FirestoreAdmin::ImportDocumentsRequest'];

coerce 'ImportDocumentsRequest',
    from HashRef, via { 'Google::Firestore::Admin::V1::FirestoreAdmin::ImportDocumentsRequest'->new($_) };

declare 'RepeatedImportDocumentsRequest',
    as ArrayRef[ImportDocumentsRequest()];

coerce 'RepeatedImportDocumentsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Firestore::Admin::V1::FirestoreAdmin::ImportDocumentsRequest'->new($_) } @$_ ] };

declare 'MapStringImportDocumentsRequest',
    as HashRef[ImportDocumentsRequest()];

declare 'BulkDeleteDocumentsRequest',
    as InstanceOf['Google::Firestore::Admin::V1::FirestoreAdmin::BulkDeleteDocumentsRequest'];

coerce 'BulkDeleteDocumentsRequest',
    from HashRef, via { 'Google::Firestore::Admin::V1::FirestoreAdmin::BulkDeleteDocumentsRequest'->new($_) };

declare 'RepeatedBulkDeleteDocumentsRequest',
    as ArrayRef[BulkDeleteDocumentsRequest()];

coerce 'RepeatedBulkDeleteDocumentsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Firestore::Admin::V1::FirestoreAdmin::BulkDeleteDocumentsRequest'->new($_) } @$_ ] };

declare 'MapStringBulkDeleteDocumentsRequest',
    as HashRef[BulkDeleteDocumentsRequest()];

declare 'BulkDeleteDocumentsResponse',
    as InstanceOf['Google::Firestore::Admin::V1::FirestoreAdmin::BulkDeleteDocumentsResponse'];

coerce 'BulkDeleteDocumentsResponse',
    from HashRef, via { 'Google::Firestore::Admin::V1::FirestoreAdmin::BulkDeleteDocumentsResponse'->new($_) };

declare 'RepeatedBulkDeleteDocumentsResponse',
    as ArrayRef[BulkDeleteDocumentsResponse()];

coerce 'RepeatedBulkDeleteDocumentsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Firestore::Admin::V1::FirestoreAdmin::BulkDeleteDocumentsResponse'->new($_) } @$_ ] };

declare 'MapStringBulkDeleteDocumentsResponse',
    as HashRef[BulkDeleteDocumentsResponse()];

declare 'GetBackupRequest',
    as InstanceOf['Google::Firestore::Admin::V1::FirestoreAdmin::GetBackupRequest'];

coerce 'GetBackupRequest',
    from HashRef, via { 'Google::Firestore::Admin::V1::FirestoreAdmin::GetBackupRequest'->new($_) };

declare 'RepeatedGetBackupRequest',
    as ArrayRef[GetBackupRequest()];

coerce 'RepeatedGetBackupRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Firestore::Admin::V1::FirestoreAdmin::GetBackupRequest'->new($_) } @$_ ] };

declare 'MapStringGetBackupRequest',
    as HashRef[GetBackupRequest()];

declare 'ListBackupsRequest',
    as InstanceOf['Google::Firestore::Admin::V1::FirestoreAdmin::ListBackupsRequest'];

coerce 'ListBackupsRequest',
    from HashRef, via { 'Google::Firestore::Admin::V1::FirestoreAdmin::ListBackupsRequest'->new($_) };

declare 'RepeatedListBackupsRequest',
    as ArrayRef[ListBackupsRequest()];

coerce 'RepeatedListBackupsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Firestore::Admin::V1::FirestoreAdmin::ListBackupsRequest'->new($_) } @$_ ] };

declare 'MapStringListBackupsRequest',
    as HashRef[ListBackupsRequest()];

declare 'ListBackupsResponse',
    as InstanceOf['Google::Firestore::Admin::V1::FirestoreAdmin::ListBackupsResponse'];

coerce 'ListBackupsResponse',
    from HashRef, via { 'Google::Firestore::Admin::V1::FirestoreAdmin::ListBackupsResponse'->new($_) };

declare 'RepeatedListBackupsResponse',
    as ArrayRef[ListBackupsResponse()];

coerce 'RepeatedListBackupsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Firestore::Admin::V1::FirestoreAdmin::ListBackupsResponse'->new($_) } @$_ ] };

declare 'MapStringListBackupsResponse',
    as HashRef[ListBackupsResponse()];

declare 'DeleteBackupRequest',
    as InstanceOf['Google::Firestore::Admin::V1::FirestoreAdmin::DeleteBackupRequest'];

coerce 'DeleteBackupRequest',
    from HashRef, via { 'Google::Firestore::Admin::V1::FirestoreAdmin::DeleteBackupRequest'->new($_) };

declare 'RepeatedDeleteBackupRequest',
    as ArrayRef[DeleteBackupRequest()];

coerce 'RepeatedDeleteBackupRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Firestore::Admin::V1::FirestoreAdmin::DeleteBackupRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteBackupRequest',
    as HashRef[DeleteBackupRequest()];

declare 'RestoreDatabaseRequest',
    as InstanceOf['Google::Firestore::Admin::V1::FirestoreAdmin::RestoreDatabaseRequest'];

coerce 'RestoreDatabaseRequest',
    from HashRef, via { 'Google::Firestore::Admin::V1::FirestoreAdmin::RestoreDatabaseRequest'->new($_) };

declare 'RepeatedRestoreDatabaseRequest',
    as ArrayRef[RestoreDatabaseRequest()];

coerce 'RepeatedRestoreDatabaseRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Firestore::Admin::V1::FirestoreAdmin::RestoreDatabaseRequest'->new($_) } @$_ ] };

declare 'MapStringRestoreDatabaseRequest',
    as HashRef[RestoreDatabaseRequest()];

declare 'TagsEntry',
    as InstanceOf['Google::Firestore::Admin::V1::FirestoreAdmin::RestoreDatabaseRequest::TagsEntry'];

coerce 'TagsEntry',
    from HashRef, via { 'Google::Firestore::Admin::V1::FirestoreAdmin::RestoreDatabaseRequest::TagsEntry'->new($_) };

declare 'RepeatedTagsEntry',
    as ArrayRef[TagsEntry()];

coerce 'RepeatedTagsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Firestore::Admin::V1::FirestoreAdmin::RestoreDatabaseRequest::TagsEntry'->new($_) } @$_ ] };

declare 'MapStringTagsEntry',
    as HashRef[TagsEntry()];

declare 'CloneDatabaseRequest',
    as InstanceOf['Google::Firestore::Admin::V1::FirestoreAdmin::CloneDatabaseRequest'];

coerce 'CloneDatabaseRequest',
    from HashRef, via { 'Google::Firestore::Admin::V1::FirestoreAdmin::CloneDatabaseRequest'->new($_) };

declare 'RepeatedCloneDatabaseRequest',
    as ArrayRef[CloneDatabaseRequest()];

coerce 'RepeatedCloneDatabaseRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Firestore::Admin::V1::FirestoreAdmin::CloneDatabaseRequest'->new($_) } @$_ ] };

declare 'MapStringCloneDatabaseRequest',
    as HashRef[CloneDatabaseRequest()];

declare 'TagsEntry',
    as InstanceOf['Google::Firestore::Admin::V1::FirestoreAdmin::CloneDatabaseRequest::TagsEntry'];

coerce 'TagsEntry',
    from HashRef, via { 'Google::Firestore::Admin::V1::FirestoreAdmin::CloneDatabaseRequest::TagsEntry'->new($_) };

declare 'RepeatedTagsEntry',
    as ArrayRef[TagsEntry()];

coerce 'RepeatedTagsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Firestore::Admin::V1::FirestoreAdmin::CloneDatabaseRequest::TagsEntry'->new($_) } @$_ ] };

declare 'MapStringTagsEntry',
    as HashRef[TagsEntry()];

1;

__END__

=head1 NAME

Google::Firestore::Admin::V1::FirestoreAdmin::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
