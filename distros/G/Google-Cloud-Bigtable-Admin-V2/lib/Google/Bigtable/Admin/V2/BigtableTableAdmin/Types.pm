package Google::Bigtable::Admin::V2::BigtableTableAdmin::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'RestoreTableRequest',
    as InstanceOf['Google::Bigtable::Admin::V2::BigtableTableAdmin::RestoreTableRequest'];

coerce 'RestoreTableRequest',
    from HashRef, via { 'Google::Bigtable::Admin::V2::BigtableTableAdmin::RestoreTableRequest'->new($_) };

declare 'RepeatedRestoreTableRequest',
    as ArrayRef[RestoreTableRequest()];

coerce 'RepeatedRestoreTableRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::Admin::V2::BigtableTableAdmin::RestoreTableRequest'->new($_) } @$_ ] };

declare 'MapStringRestoreTableRequest',
    as HashRef[RestoreTableRequest()];

declare 'RestoreTableMetadata',
    as InstanceOf['Google::Bigtable::Admin::V2::BigtableTableAdmin::RestoreTableMetadata'];

coerce 'RestoreTableMetadata',
    from HashRef, via { 'Google::Bigtable::Admin::V2::BigtableTableAdmin::RestoreTableMetadata'->new($_) };

declare 'RepeatedRestoreTableMetadata',
    as ArrayRef[RestoreTableMetadata()];

coerce 'RepeatedRestoreTableMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::Admin::V2::BigtableTableAdmin::RestoreTableMetadata'->new($_) } @$_ ] };

declare 'MapStringRestoreTableMetadata',
    as HashRef[RestoreTableMetadata()];

declare 'OptimizeRestoredTableMetadata',
    as InstanceOf['Google::Bigtable::Admin::V2::BigtableTableAdmin::OptimizeRestoredTableMetadata'];

coerce 'OptimizeRestoredTableMetadata',
    from HashRef, via { 'Google::Bigtable::Admin::V2::BigtableTableAdmin::OptimizeRestoredTableMetadata'->new($_) };

declare 'RepeatedOptimizeRestoredTableMetadata',
    as ArrayRef[OptimizeRestoredTableMetadata()];

coerce 'RepeatedOptimizeRestoredTableMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::Admin::V2::BigtableTableAdmin::OptimizeRestoredTableMetadata'->new($_) } @$_ ] };

declare 'MapStringOptimizeRestoredTableMetadata',
    as HashRef[OptimizeRestoredTableMetadata()];

declare 'CreateTableRequest',
    as InstanceOf['Google::Bigtable::Admin::V2::BigtableTableAdmin::CreateTableRequest'];

coerce 'CreateTableRequest',
    from HashRef, via { 'Google::Bigtable::Admin::V2::BigtableTableAdmin::CreateTableRequest'->new($_) };

declare 'RepeatedCreateTableRequest',
    as ArrayRef[CreateTableRequest()];

coerce 'RepeatedCreateTableRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::Admin::V2::BigtableTableAdmin::CreateTableRequest'->new($_) } @$_ ] };

declare 'MapStringCreateTableRequest',
    as HashRef[CreateTableRequest()];

declare 'Split',
    as InstanceOf['Google::Bigtable::Admin::V2::BigtableTableAdmin::CreateTableRequest::Split'];

coerce 'Split',
    from HashRef, via { 'Google::Bigtable::Admin::V2::BigtableTableAdmin::CreateTableRequest::Split'->new($_) };

declare 'RepeatedSplit',
    as ArrayRef[Split()];

coerce 'RepeatedSplit',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::Admin::V2::BigtableTableAdmin::CreateTableRequest::Split'->new($_) } @$_ ] };

declare 'MapStringSplit',
    as HashRef[Split()];

declare 'CreateTableFromSnapshotRequest',
    as InstanceOf['Google::Bigtable::Admin::V2::BigtableTableAdmin::CreateTableFromSnapshotRequest'];

coerce 'CreateTableFromSnapshotRequest',
    from HashRef, via { 'Google::Bigtable::Admin::V2::BigtableTableAdmin::CreateTableFromSnapshotRequest'->new($_) };

declare 'RepeatedCreateTableFromSnapshotRequest',
    as ArrayRef[CreateTableFromSnapshotRequest()];

coerce 'RepeatedCreateTableFromSnapshotRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::Admin::V2::BigtableTableAdmin::CreateTableFromSnapshotRequest'->new($_) } @$_ ] };

declare 'MapStringCreateTableFromSnapshotRequest',
    as HashRef[CreateTableFromSnapshotRequest()];

declare 'DropRowRangeRequest',
    as InstanceOf['Google::Bigtable::Admin::V2::BigtableTableAdmin::DropRowRangeRequest'];

coerce 'DropRowRangeRequest',
    from HashRef, via { 'Google::Bigtable::Admin::V2::BigtableTableAdmin::DropRowRangeRequest'->new($_) };

declare 'RepeatedDropRowRangeRequest',
    as ArrayRef[DropRowRangeRequest()];

coerce 'RepeatedDropRowRangeRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::Admin::V2::BigtableTableAdmin::DropRowRangeRequest'->new($_) } @$_ ] };

declare 'MapStringDropRowRangeRequest',
    as HashRef[DropRowRangeRequest()];

declare 'ListTablesRequest',
    as InstanceOf['Google::Bigtable::Admin::V2::BigtableTableAdmin::ListTablesRequest'];

coerce 'ListTablesRequest',
    from HashRef, via { 'Google::Bigtable::Admin::V2::BigtableTableAdmin::ListTablesRequest'->new($_) };

declare 'RepeatedListTablesRequest',
    as ArrayRef[ListTablesRequest()];

coerce 'RepeatedListTablesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::Admin::V2::BigtableTableAdmin::ListTablesRequest'->new($_) } @$_ ] };

declare 'MapStringListTablesRequest',
    as HashRef[ListTablesRequest()];

declare 'ListTablesResponse',
    as InstanceOf['Google::Bigtable::Admin::V2::BigtableTableAdmin::ListTablesResponse'];

coerce 'ListTablesResponse',
    from HashRef, via { 'Google::Bigtable::Admin::V2::BigtableTableAdmin::ListTablesResponse'->new($_) };

declare 'RepeatedListTablesResponse',
    as ArrayRef[ListTablesResponse()];

coerce 'RepeatedListTablesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::Admin::V2::BigtableTableAdmin::ListTablesResponse'->new($_) } @$_ ] };

declare 'MapStringListTablesResponse',
    as HashRef[ListTablesResponse()];

declare 'GetTableRequest',
    as InstanceOf['Google::Bigtable::Admin::V2::BigtableTableAdmin::GetTableRequest'];

coerce 'GetTableRequest',
    from HashRef, via { 'Google::Bigtable::Admin::V2::BigtableTableAdmin::GetTableRequest'->new($_) };

declare 'RepeatedGetTableRequest',
    as ArrayRef[GetTableRequest()];

coerce 'RepeatedGetTableRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::Admin::V2::BigtableTableAdmin::GetTableRequest'->new($_) } @$_ ] };

declare 'MapStringGetTableRequest',
    as HashRef[GetTableRequest()];

declare 'UpdateTableRequest',
    as InstanceOf['Google::Bigtable::Admin::V2::BigtableTableAdmin::UpdateTableRequest'];

coerce 'UpdateTableRequest',
    from HashRef, via { 'Google::Bigtable::Admin::V2::BigtableTableAdmin::UpdateTableRequest'->new($_) };

declare 'RepeatedUpdateTableRequest',
    as ArrayRef[UpdateTableRequest()];

coerce 'RepeatedUpdateTableRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::Admin::V2::BigtableTableAdmin::UpdateTableRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateTableRequest',
    as HashRef[UpdateTableRequest()];

declare 'UpdateTableMetadata',
    as InstanceOf['Google::Bigtable::Admin::V2::BigtableTableAdmin::UpdateTableMetadata'];

coerce 'UpdateTableMetadata',
    from HashRef, via { 'Google::Bigtable::Admin::V2::BigtableTableAdmin::UpdateTableMetadata'->new($_) };

declare 'RepeatedUpdateTableMetadata',
    as ArrayRef[UpdateTableMetadata()];

coerce 'RepeatedUpdateTableMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::Admin::V2::BigtableTableAdmin::UpdateTableMetadata'->new($_) } @$_ ] };

declare 'MapStringUpdateTableMetadata',
    as HashRef[UpdateTableMetadata()];

declare 'DeleteTableRequest',
    as InstanceOf['Google::Bigtable::Admin::V2::BigtableTableAdmin::DeleteTableRequest'];

coerce 'DeleteTableRequest',
    from HashRef, via { 'Google::Bigtable::Admin::V2::BigtableTableAdmin::DeleteTableRequest'->new($_) };

declare 'RepeatedDeleteTableRequest',
    as ArrayRef[DeleteTableRequest()];

coerce 'RepeatedDeleteTableRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::Admin::V2::BigtableTableAdmin::DeleteTableRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteTableRequest',
    as HashRef[DeleteTableRequest()];

declare 'UndeleteTableRequest',
    as InstanceOf['Google::Bigtable::Admin::V2::BigtableTableAdmin::UndeleteTableRequest'];

coerce 'UndeleteTableRequest',
    from HashRef, via { 'Google::Bigtable::Admin::V2::BigtableTableAdmin::UndeleteTableRequest'->new($_) };

declare 'RepeatedUndeleteTableRequest',
    as ArrayRef[UndeleteTableRequest()];

coerce 'RepeatedUndeleteTableRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::Admin::V2::BigtableTableAdmin::UndeleteTableRequest'->new($_) } @$_ ] };

declare 'MapStringUndeleteTableRequest',
    as HashRef[UndeleteTableRequest()];

declare 'UndeleteTableMetadata',
    as InstanceOf['Google::Bigtable::Admin::V2::BigtableTableAdmin::UndeleteTableMetadata'];

coerce 'UndeleteTableMetadata',
    from HashRef, via { 'Google::Bigtable::Admin::V2::BigtableTableAdmin::UndeleteTableMetadata'->new($_) };

declare 'RepeatedUndeleteTableMetadata',
    as ArrayRef[UndeleteTableMetadata()];

coerce 'RepeatedUndeleteTableMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::Admin::V2::BigtableTableAdmin::UndeleteTableMetadata'->new($_) } @$_ ] };

declare 'MapStringUndeleteTableMetadata',
    as HashRef[UndeleteTableMetadata()];

declare 'ModifyColumnFamiliesRequest',
    as InstanceOf['Google::Bigtable::Admin::V2::BigtableTableAdmin::ModifyColumnFamiliesRequest'];

coerce 'ModifyColumnFamiliesRequest',
    from HashRef, via { 'Google::Bigtable::Admin::V2::BigtableTableAdmin::ModifyColumnFamiliesRequest'->new($_) };

declare 'RepeatedModifyColumnFamiliesRequest',
    as ArrayRef[ModifyColumnFamiliesRequest()];

coerce 'RepeatedModifyColumnFamiliesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::Admin::V2::BigtableTableAdmin::ModifyColumnFamiliesRequest'->new($_) } @$_ ] };

declare 'MapStringModifyColumnFamiliesRequest',
    as HashRef[ModifyColumnFamiliesRequest()];

declare 'Modification',
    as InstanceOf['Google::Bigtable::Admin::V2::BigtableTableAdmin::ModifyColumnFamiliesRequest::Modification'];

coerce 'Modification',
    from HashRef, via { 'Google::Bigtable::Admin::V2::BigtableTableAdmin::ModifyColumnFamiliesRequest::Modification'->new($_) };

declare 'RepeatedModification',
    as ArrayRef[Modification()];

coerce 'RepeatedModification',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::Admin::V2::BigtableTableAdmin::ModifyColumnFamiliesRequest::Modification'->new($_) } @$_ ] };

declare 'MapStringModification',
    as HashRef[Modification()];

declare 'GenerateConsistencyTokenRequest',
    as InstanceOf['Google::Bigtable::Admin::V2::BigtableTableAdmin::GenerateConsistencyTokenRequest'];

coerce 'GenerateConsistencyTokenRequest',
    from HashRef, via { 'Google::Bigtable::Admin::V2::BigtableTableAdmin::GenerateConsistencyTokenRequest'->new($_) };

declare 'RepeatedGenerateConsistencyTokenRequest',
    as ArrayRef[GenerateConsistencyTokenRequest()];

coerce 'RepeatedGenerateConsistencyTokenRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::Admin::V2::BigtableTableAdmin::GenerateConsistencyTokenRequest'->new($_) } @$_ ] };

declare 'MapStringGenerateConsistencyTokenRequest',
    as HashRef[GenerateConsistencyTokenRequest()];

declare 'GenerateConsistencyTokenResponse',
    as InstanceOf['Google::Bigtable::Admin::V2::BigtableTableAdmin::GenerateConsistencyTokenResponse'];

coerce 'GenerateConsistencyTokenResponse',
    from HashRef, via { 'Google::Bigtable::Admin::V2::BigtableTableAdmin::GenerateConsistencyTokenResponse'->new($_) };

declare 'RepeatedGenerateConsistencyTokenResponse',
    as ArrayRef[GenerateConsistencyTokenResponse()];

coerce 'RepeatedGenerateConsistencyTokenResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::Admin::V2::BigtableTableAdmin::GenerateConsistencyTokenResponse'->new($_) } @$_ ] };

declare 'MapStringGenerateConsistencyTokenResponse',
    as HashRef[GenerateConsistencyTokenResponse()];

declare 'CheckConsistencyRequest',
    as InstanceOf['Google::Bigtable::Admin::V2::BigtableTableAdmin::CheckConsistencyRequest'];

coerce 'CheckConsistencyRequest',
    from HashRef, via { 'Google::Bigtable::Admin::V2::BigtableTableAdmin::CheckConsistencyRequest'->new($_) };

declare 'RepeatedCheckConsistencyRequest',
    as ArrayRef[CheckConsistencyRequest()];

coerce 'RepeatedCheckConsistencyRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::Admin::V2::BigtableTableAdmin::CheckConsistencyRequest'->new($_) } @$_ ] };

declare 'MapStringCheckConsistencyRequest',
    as HashRef[CheckConsistencyRequest()];

declare 'StandardReadRemoteWrites',
    as InstanceOf['Google::Bigtable::Admin::V2::BigtableTableAdmin::StandardReadRemoteWrites'];

coerce 'StandardReadRemoteWrites',
    from HashRef, via { 'Google::Bigtable::Admin::V2::BigtableTableAdmin::StandardReadRemoteWrites'->new($_) };

declare 'RepeatedStandardReadRemoteWrites',
    as ArrayRef[StandardReadRemoteWrites()];

coerce 'RepeatedStandardReadRemoteWrites',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::Admin::V2::BigtableTableAdmin::StandardReadRemoteWrites'->new($_) } @$_ ] };

declare 'MapStringStandardReadRemoteWrites',
    as HashRef[StandardReadRemoteWrites()];

declare 'DataBoostReadLocalWrites',
    as InstanceOf['Google::Bigtable::Admin::V2::BigtableTableAdmin::DataBoostReadLocalWrites'];

coerce 'DataBoostReadLocalWrites',
    from HashRef, via { 'Google::Bigtable::Admin::V2::BigtableTableAdmin::DataBoostReadLocalWrites'->new($_) };

declare 'RepeatedDataBoostReadLocalWrites',
    as ArrayRef[DataBoostReadLocalWrites()];

coerce 'RepeatedDataBoostReadLocalWrites',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::Admin::V2::BigtableTableAdmin::DataBoostReadLocalWrites'->new($_) } @$_ ] };

declare 'MapStringDataBoostReadLocalWrites',
    as HashRef[DataBoostReadLocalWrites()];

declare 'CheckConsistencyResponse',
    as InstanceOf['Google::Bigtable::Admin::V2::BigtableTableAdmin::CheckConsistencyResponse'];

coerce 'CheckConsistencyResponse',
    from HashRef, via { 'Google::Bigtable::Admin::V2::BigtableTableAdmin::CheckConsistencyResponse'->new($_) };

declare 'RepeatedCheckConsistencyResponse',
    as ArrayRef[CheckConsistencyResponse()];

coerce 'RepeatedCheckConsistencyResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::Admin::V2::BigtableTableAdmin::CheckConsistencyResponse'->new($_) } @$_ ] };

declare 'MapStringCheckConsistencyResponse',
    as HashRef[CheckConsistencyResponse()];

declare 'SnapshotTableRequest',
    as InstanceOf['Google::Bigtable::Admin::V2::BigtableTableAdmin::SnapshotTableRequest'];

coerce 'SnapshotTableRequest',
    from HashRef, via { 'Google::Bigtable::Admin::V2::BigtableTableAdmin::SnapshotTableRequest'->new($_) };

declare 'RepeatedSnapshotTableRequest',
    as ArrayRef[SnapshotTableRequest()];

coerce 'RepeatedSnapshotTableRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::Admin::V2::BigtableTableAdmin::SnapshotTableRequest'->new($_) } @$_ ] };

declare 'MapStringSnapshotTableRequest',
    as HashRef[SnapshotTableRequest()];

declare 'GetSnapshotRequest',
    as InstanceOf['Google::Bigtable::Admin::V2::BigtableTableAdmin::GetSnapshotRequest'];

coerce 'GetSnapshotRequest',
    from HashRef, via { 'Google::Bigtable::Admin::V2::BigtableTableAdmin::GetSnapshotRequest'->new($_) };

declare 'RepeatedGetSnapshotRequest',
    as ArrayRef[GetSnapshotRequest()];

coerce 'RepeatedGetSnapshotRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::Admin::V2::BigtableTableAdmin::GetSnapshotRequest'->new($_) } @$_ ] };

declare 'MapStringGetSnapshotRequest',
    as HashRef[GetSnapshotRequest()];

declare 'ListSnapshotsRequest',
    as InstanceOf['Google::Bigtable::Admin::V2::BigtableTableAdmin::ListSnapshotsRequest'];

coerce 'ListSnapshotsRequest',
    from HashRef, via { 'Google::Bigtable::Admin::V2::BigtableTableAdmin::ListSnapshotsRequest'->new($_) };

declare 'RepeatedListSnapshotsRequest',
    as ArrayRef[ListSnapshotsRequest()];

coerce 'RepeatedListSnapshotsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::Admin::V2::BigtableTableAdmin::ListSnapshotsRequest'->new($_) } @$_ ] };

declare 'MapStringListSnapshotsRequest',
    as HashRef[ListSnapshotsRequest()];

declare 'ListSnapshotsResponse',
    as InstanceOf['Google::Bigtable::Admin::V2::BigtableTableAdmin::ListSnapshotsResponse'];

coerce 'ListSnapshotsResponse',
    from HashRef, via { 'Google::Bigtable::Admin::V2::BigtableTableAdmin::ListSnapshotsResponse'->new($_) };

declare 'RepeatedListSnapshotsResponse',
    as ArrayRef[ListSnapshotsResponse()];

coerce 'RepeatedListSnapshotsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::Admin::V2::BigtableTableAdmin::ListSnapshotsResponse'->new($_) } @$_ ] };

declare 'MapStringListSnapshotsResponse',
    as HashRef[ListSnapshotsResponse()];

declare 'DeleteSnapshotRequest',
    as InstanceOf['Google::Bigtable::Admin::V2::BigtableTableAdmin::DeleteSnapshotRequest'];

coerce 'DeleteSnapshotRequest',
    from HashRef, via { 'Google::Bigtable::Admin::V2::BigtableTableAdmin::DeleteSnapshotRequest'->new($_) };

declare 'RepeatedDeleteSnapshotRequest',
    as ArrayRef[DeleteSnapshotRequest()];

coerce 'RepeatedDeleteSnapshotRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::Admin::V2::BigtableTableAdmin::DeleteSnapshotRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteSnapshotRequest',
    as HashRef[DeleteSnapshotRequest()];

declare 'SnapshotTableMetadata',
    as InstanceOf['Google::Bigtable::Admin::V2::BigtableTableAdmin::SnapshotTableMetadata'];

coerce 'SnapshotTableMetadata',
    from HashRef, via { 'Google::Bigtable::Admin::V2::BigtableTableAdmin::SnapshotTableMetadata'->new($_) };

declare 'RepeatedSnapshotTableMetadata',
    as ArrayRef[SnapshotTableMetadata()];

coerce 'RepeatedSnapshotTableMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::Admin::V2::BigtableTableAdmin::SnapshotTableMetadata'->new($_) } @$_ ] };

declare 'MapStringSnapshotTableMetadata',
    as HashRef[SnapshotTableMetadata()];

declare 'CreateTableFromSnapshotMetadata',
    as InstanceOf['Google::Bigtable::Admin::V2::BigtableTableAdmin::CreateTableFromSnapshotMetadata'];

coerce 'CreateTableFromSnapshotMetadata',
    from HashRef, via { 'Google::Bigtable::Admin::V2::BigtableTableAdmin::CreateTableFromSnapshotMetadata'->new($_) };

declare 'RepeatedCreateTableFromSnapshotMetadata',
    as ArrayRef[CreateTableFromSnapshotMetadata()];

coerce 'RepeatedCreateTableFromSnapshotMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::Admin::V2::BigtableTableAdmin::CreateTableFromSnapshotMetadata'->new($_) } @$_ ] };

declare 'MapStringCreateTableFromSnapshotMetadata',
    as HashRef[CreateTableFromSnapshotMetadata()];

declare 'CreateBackupRequest',
    as InstanceOf['Google::Bigtable::Admin::V2::BigtableTableAdmin::CreateBackupRequest'];

coerce 'CreateBackupRequest',
    from HashRef, via { 'Google::Bigtable::Admin::V2::BigtableTableAdmin::CreateBackupRequest'->new($_) };

declare 'RepeatedCreateBackupRequest',
    as ArrayRef[CreateBackupRequest()];

coerce 'RepeatedCreateBackupRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::Admin::V2::BigtableTableAdmin::CreateBackupRequest'->new($_) } @$_ ] };

declare 'MapStringCreateBackupRequest',
    as HashRef[CreateBackupRequest()];

declare 'CreateBackupMetadata',
    as InstanceOf['Google::Bigtable::Admin::V2::BigtableTableAdmin::CreateBackupMetadata'];

coerce 'CreateBackupMetadata',
    from HashRef, via { 'Google::Bigtable::Admin::V2::BigtableTableAdmin::CreateBackupMetadata'->new($_) };

declare 'RepeatedCreateBackupMetadata',
    as ArrayRef[CreateBackupMetadata()];

coerce 'RepeatedCreateBackupMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::Admin::V2::BigtableTableAdmin::CreateBackupMetadata'->new($_) } @$_ ] };

declare 'MapStringCreateBackupMetadata',
    as HashRef[CreateBackupMetadata()];

declare 'UpdateBackupRequest',
    as InstanceOf['Google::Bigtable::Admin::V2::BigtableTableAdmin::UpdateBackupRequest'];

coerce 'UpdateBackupRequest',
    from HashRef, via { 'Google::Bigtable::Admin::V2::BigtableTableAdmin::UpdateBackupRequest'->new($_) };

declare 'RepeatedUpdateBackupRequest',
    as ArrayRef[UpdateBackupRequest()];

coerce 'RepeatedUpdateBackupRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::Admin::V2::BigtableTableAdmin::UpdateBackupRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateBackupRequest',
    as HashRef[UpdateBackupRequest()];

declare 'GetBackupRequest',
    as InstanceOf['Google::Bigtable::Admin::V2::BigtableTableAdmin::GetBackupRequest'];

coerce 'GetBackupRequest',
    from HashRef, via { 'Google::Bigtable::Admin::V2::BigtableTableAdmin::GetBackupRequest'->new($_) };

declare 'RepeatedGetBackupRequest',
    as ArrayRef[GetBackupRequest()];

coerce 'RepeatedGetBackupRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::Admin::V2::BigtableTableAdmin::GetBackupRequest'->new($_) } @$_ ] };

declare 'MapStringGetBackupRequest',
    as HashRef[GetBackupRequest()];

declare 'DeleteBackupRequest',
    as InstanceOf['Google::Bigtable::Admin::V2::BigtableTableAdmin::DeleteBackupRequest'];

coerce 'DeleteBackupRequest',
    from HashRef, via { 'Google::Bigtable::Admin::V2::BigtableTableAdmin::DeleteBackupRequest'->new($_) };

declare 'RepeatedDeleteBackupRequest',
    as ArrayRef[DeleteBackupRequest()];

coerce 'RepeatedDeleteBackupRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::Admin::V2::BigtableTableAdmin::DeleteBackupRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteBackupRequest',
    as HashRef[DeleteBackupRequest()];

declare 'ListBackupsRequest',
    as InstanceOf['Google::Bigtable::Admin::V2::BigtableTableAdmin::ListBackupsRequest'];

coerce 'ListBackupsRequest',
    from HashRef, via { 'Google::Bigtable::Admin::V2::BigtableTableAdmin::ListBackupsRequest'->new($_) };

declare 'RepeatedListBackupsRequest',
    as ArrayRef[ListBackupsRequest()];

coerce 'RepeatedListBackupsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::Admin::V2::BigtableTableAdmin::ListBackupsRequest'->new($_) } @$_ ] };

declare 'MapStringListBackupsRequest',
    as HashRef[ListBackupsRequest()];

declare 'ListBackupsResponse',
    as InstanceOf['Google::Bigtable::Admin::V2::BigtableTableAdmin::ListBackupsResponse'];

coerce 'ListBackupsResponse',
    from HashRef, via { 'Google::Bigtable::Admin::V2::BigtableTableAdmin::ListBackupsResponse'->new($_) };

declare 'RepeatedListBackupsResponse',
    as ArrayRef[ListBackupsResponse()];

coerce 'RepeatedListBackupsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::Admin::V2::BigtableTableAdmin::ListBackupsResponse'->new($_) } @$_ ] };

declare 'MapStringListBackupsResponse',
    as HashRef[ListBackupsResponse()];

declare 'CopyBackupRequest',
    as InstanceOf['Google::Bigtable::Admin::V2::BigtableTableAdmin::CopyBackupRequest'];

coerce 'CopyBackupRequest',
    from HashRef, via { 'Google::Bigtable::Admin::V2::BigtableTableAdmin::CopyBackupRequest'->new($_) };

declare 'RepeatedCopyBackupRequest',
    as ArrayRef[CopyBackupRequest()];

coerce 'RepeatedCopyBackupRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::Admin::V2::BigtableTableAdmin::CopyBackupRequest'->new($_) } @$_ ] };

declare 'MapStringCopyBackupRequest',
    as HashRef[CopyBackupRequest()];

declare 'CopyBackupMetadata',
    as InstanceOf['Google::Bigtable::Admin::V2::BigtableTableAdmin::CopyBackupMetadata'];

coerce 'CopyBackupMetadata',
    from HashRef, via { 'Google::Bigtable::Admin::V2::BigtableTableAdmin::CopyBackupMetadata'->new($_) };

declare 'RepeatedCopyBackupMetadata',
    as ArrayRef[CopyBackupMetadata()];

coerce 'RepeatedCopyBackupMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::Admin::V2::BigtableTableAdmin::CopyBackupMetadata'->new($_) } @$_ ] };

declare 'MapStringCopyBackupMetadata',
    as HashRef[CopyBackupMetadata()];

declare 'CreateAuthorizedViewRequest',
    as InstanceOf['Google::Bigtable::Admin::V2::BigtableTableAdmin::CreateAuthorizedViewRequest'];

coerce 'CreateAuthorizedViewRequest',
    from HashRef, via { 'Google::Bigtable::Admin::V2::BigtableTableAdmin::CreateAuthorizedViewRequest'->new($_) };

declare 'RepeatedCreateAuthorizedViewRequest',
    as ArrayRef[CreateAuthorizedViewRequest()];

coerce 'RepeatedCreateAuthorizedViewRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::Admin::V2::BigtableTableAdmin::CreateAuthorizedViewRequest'->new($_) } @$_ ] };

declare 'MapStringCreateAuthorizedViewRequest',
    as HashRef[CreateAuthorizedViewRequest()];

declare 'CreateAuthorizedViewMetadata',
    as InstanceOf['Google::Bigtable::Admin::V2::BigtableTableAdmin::CreateAuthorizedViewMetadata'];

coerce 'CreateAuthorizedViewMetadata',
    from HashRef, via { 'Google::Bigtable::Admin::V2::BigtableTableAdmin::CreateAuthorizedViewMetadata'->new($_) };

declare 'RepeatedCreateAuthorizedViewMetadata',
    as ArrayRef[CreateAuthorizedViewMetadata()];

coerce 'RepeatedCreateAuthorizedViewMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::Admin::V2::BigtableTableAdmin::CreateAuthorizedViewMetadata'->new($_) } @$_ ] };

declare 'MapStringCreateAuthorizedViewMetadata',
    as HashRef[CreateAuthorizedViewMetadata()];

declare 'ListAuthorizedViewsRequest',
    as InstanceOf['Google::Bigtable::Admin::V2::BigtableTableAdmin::ListAuthorizedViewsRequest'];

coerce 'ListAuthorizedViewsRequest',
    from HashRef, via { 'Google::Bigtable::Admin::V2::BigtableTableAdmin::ListAuthorizedViewsRequest'->new($_) };

declare 'RepeatedListAuthorizedViewsRequest',
    as ArrayRef[ListAuthorizedViewsRequest()];

coerce 'RepeatedListAuthorizedViewsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::Admin::V2::BigtableTableAdmin::ListAuthorizedViewsRequest'->new($_) } @$_ ] };

declare 'MapStringListAuthorizedViewsRequest',
    as HashRef[ListAuthorizedViewsRequest()];

declare 'ListAuthorizedViewsResponse',
    as InstanceOf['Google::Bigtable::Admin::V2::BigtableTableAdmin::ListAuthorizedViewsResponse'];

coerce 'ListAuthorizedViewsResponse',
    from HashRef, via { 'Google::Bigtable::Admin::V2::BigtableTableAdmin::ListAuthorizedViewsResponse'->new($_) };

declare 'RepeatedListAuthorizedViewsResponse',
    as ArrayRef[ListAuthorizedViewsResponse()];

coerce 'RepeatedListAuthorizedViewsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::Admin::V2::BigtableTableAdmin::ListAuthorizedViewsResponse'->new($_) } @$_ ] };

declare 'MapStringListAuthorizedViewsResponse',
    as HashRef[ListAuthorizedViewsResponse()];

declare 'GetAuthorizedViewRequest',
    as InstanceOf['Google::Bigtable::Admin::V2::BigtableTableAdmin::GetAuthorizedViewRequest'];

coerce 'GetAuthorizedViewRequest',
    from HashRef, via { 'Google::Bigtable::Admin::V2::BigtableTableAdmin::GetAuthorizedViewRequest'->new($_) };

declare 'RepeatedGetAuthorizedViewRequest',
    as ArrayRef[GetAuthorizedViewRequest()];

coerce 'RepeatedGetAuthorizedViewRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::Admin::V2::BigtableTableAdmin::GetAuthorizedViewRequest'->new($_) } @$_ ] };

declare 'MapStringGetAuthorizedViewRequest',
    as HashRef[GetAuthorizedViewRequest()];

declare 'UpdateAuthorizedViewRequest',
    as InstanceOf['Google::Bigtable::Admin::V2::BigtableTableAdmin::UpdateAuthorizedViewRequest'];

coerce 'UpdateAuthorizedViewRequest',
    from HashRef, via { 'Google::Bigtable::Admin::V2::BigtableTableAdmin::UpdateAuthorizedViewRequest'->new($_) };

declare 'RepeatedUpdateAuthorizedViewRequest',
    as ArrayRef[UpdateAuthorizedViewRequest()];

coerce 'RepeatedUpdateAuthorizedViewRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::Admin::V2::BigtableTableAdmin::UpdateAuthorizedViewRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateAuthorizedViewRequest',
    as HashRef[UpdateAuthorizedViewRequest()];

declare 'UpdateAuthorizedViewMetadata',
    as InstanceOf['Google::Bigtable::Admin::V2::BigtableTableAdmin::UpdateAuthorizedViewMetadata'];

coerce 'UpdateAuthorizedViewMetadata',
    from HashRef, via { 'Google::Bigtable::Admin::V2::BigtableTableAdmin::UpdateAuthorizedViewMetadata'->new($_) };

declare 'RepeatedUpdateAuthorizedViewMetadata',
    as ArrayRef[UpdateAuthorizedViewMetadata()];

coerce 'RepeatedUpdateAuthorizedViewMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::Admin::V2::BigtableTableAdmin::UpdateAuthorizedViewMetadata'->new($_) } @$_ ] };

declare 'MapStringUpdateAuthorizedViewMetadata',
    as HashRef[UpdateAuthorizedViewMetadata()];

declare 'DeleteAuthorizedViewRequest',
    as InstanceOf['Google::Bigtable::Admin::V2::BigtableTableAdmin::DeleteAuthorizedViewRequest'];

coerce 'DeleteAuthorizedViewRequest',
    from HashRef, via { 'Google::Bigtable::Admin::V2::BigtableTableAdmin::DeleteAuthorizedViewRequest'->new($_) };

declare 'RepeatedDeleteAuthorizedViewRequest',
    as ArrayRef[DeleteAuthorizedViewRequest()];

coerce 'RepeatedDeleteAuthorizedViewRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::Admin::V2::BigtableTableAdmin::DeleteAuthorizedViewRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteAuthorizedViewRequest',
    as HashRef[DeleteAuthorizedViewRequest()];

declare 'CreateSchemaBundleRequest',
    as InstanceOf['Google::Bigtable::Admin::V2::BigtableTableAdmin::CreateSchemaBundleRequest'];

coerce 'CreateSchemaBundleRequest',
    from HashRef, via { 'Google::Bigtable::Admin::V2::BigtableTableAdmin::CreateSchemaBundleRequest'->new($_) };

declare 'RepeatedCreateSchemaBundleRequest',
    as ArrayRef[CreateSchemaBundleRequest()];

coerce 'RepeatedCreateSchemaBundleRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::Admin::V2::BigtableTableAdmin::CreateSchemaBundleRequest'->new($_) } @$_ ] };

declare 'MapStringCreateSchemaBundleRequest',
    as HashRef[CreateSchemaBundleRequest()];

declare 'CreateSchemaBundleMetadata',
    as InstanceOf['Google::Bigtable::Admin::V2::BigtableTableAdmin::CreateSchemaBundleMetadata'];

coerce 'CreateSchemaBundleMetadata',
    from HashRef, via { 'Google::Bigtable::Admin::V2::BigtableTableAdmin::CreateSchemaBundleMetadata'->new($_) };

declare 'RepeatedCreateSchemaBundleMetadata',
    as ArrayRef[CreateSchemaBundleMetadata()];

coerce 'RepeatedCreateSchemaBundleMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::Admin::V2::BigtableTableAdmin::CreateSchemaBundleMetadata'->new($_) } @$_ ] };

declare 'MapStringCreateSchemaBundleMetadata',
    as HashRef[CreateSchemaBundleMetadata()];

declare 'UpdateSchemaBundleRequest',
    as InstanceOf['Google::Bigtable::Admin::V2::BigtableTableAdmin::UpdateSchemaBundleRequest'];

coerce 'UpdateSchemaBundleRequest',
    from HashRef, via { 'Google::Bigtable::Admin::V2::BigtableTableAdmin::UpdateSchemaBundleRequest'->new($_) };

declare 'RepeatedUpdateSchemaBundleRequest',
    as ArrayRef[UpdateSchemaBundleRequest()];

coerce 'RepeatedUpdateSchemaBundleRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::Admin::V2::BigtableTableAdmin::UpdateSchemaBundleRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateSchemaBundleRequest',
    as HashRef[UpdateSchemaBundleRequest()];

declare 'UpdateSchemaBundleMetadata',
    as InstanceOf['Google::Bigtable::Admin::V2::BigtableTableAdmin::UpdateSchemaBundleMetadata'];

coerce 'UpdateSchemaBundleMetadata',
    from HashRef, via { 'Google::Bigtable::Admin::V2::BigtableTableAdmin::UpdateSchemaBundleMetadata'->new($_) };

declare 'RepeatedUpdateSchemaBundleMetadata',
    as ArrayRef[UpdateSchemaBundleMetadata()];

coerce 'RepeatedUpdateSchemaBundleMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::Admin::V2::BigtableTableAdmin::UpdateSchemaBundleMetadata'->new($_) } @$_ ] };

declare 'MapStringUpdateSchemaBundleMetadata',
    as HashRef[UpdateSchemaBundleMetadata()];

declare 'GetSchemaBundleRequest',
    as InstanceOf['Google::Bigtable::Admin::V2::BigtableTableAdmin::GetSchemaBundleRequest'];

coerce 'GetSchemaBundleRequest',
    from HashRef, via { 'Google::Bigtable::Admin::V2::BigtableTableAdmin::GetSchemaBundleRequest'->new($_) };

declare 'RepeatedGetSchemaBundleRequest',
    as ArrayRef[GetSchemaBundleRequest()];

coerce 'RepeatedGetSchemaBundleRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::Admin::V2::BigtableTableAdmin::GetSchemaBundleRequest'->new($_) } @$_ ] };

declare 'MapStringGetSchemaBundleRequest',
    as HashRef[GetSchemaBundleRequest()];

declare 'ListSchemaBundlesRequest',
    as InstanceOf['Google::Bigtable::Admin::V2::BigtableTableAdmin::ListSchemaBundlesRequest'];

coerce 'ListSchemaBundlesRequest',
    from HashRef, via { 'Google::Bigtable::Admin::V2::BigtableTableAdmin::ListSchemaBundlesRequest'->new($_) };

declare 'RepeatedListSchemaBundlesRequest',
    as ArrayRef[ListSchemaBundlesRequest()];

coerce 'RepeatedListSchemaBundlesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::Admin::V2::BigtableTableAdmin::ListSchemaBundlesRequest'->new($_) } @$_ ] };

declare 'MapStringListSchemaBundlesRequest',
    as HashRef[ListSchemaBundlesRequest()];

declare 'ListSchemaBundlesResponse',
    as InstanceOf['Google::Bigtable::Admin::V2::BigtableTableAdmin::ListSchemaBundlesResponse'];

coerce 'ListSchemaBundlesResponse',
    from HashRef, via { 'Google::Bigtable::Admin::V2::BigtableTableAdmin::ListSchemaBundlesResponse'->new($_) };

declare 'RepeatedListSchemaBundlesResponse',
    as ArrayRef[ListSchemaBundlesResponse()];

coerce 'RepeatedListSchemaBundlesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::Admin::V2::BigtableTableAdmin::ListSchemaBundlesResponse'->new($_) } @$_ ] };

declare 'MapStringListSchemaBundlesResponse',
    as HashRef[ListSchemaBundlesResponse()];

declare 'DeleteSchemaBundleRequest',
    as InstanceOf['Google::Bigtable::Admin::V2::BigtableTableAdmin::DeleteSchemaBundleRequest'];

coerce 'DeleteSchemaBundleRequest',
    from HashRef, via { 'Google::Bigtable::Admin::V2::BigtableTableAdmin::DeleteSchemaBundleRequest'->new($_) };

declare 'RepeatedDeleteSchemaBundleRequest',
    as ArrayRef[DeleteSchemaBundleRequest()];

coerce 'RepeatedDeleteSchemaBundleRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::Admin::V2::BigtableTableAdmin::DeleteSchemaBundleRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteSchemaBundleRequest',
    as HashRef[DeleteSchemaBundleRequest()];

1;

__END__

=head1 NAME

Google::Bigtable::Admin::V2::BigtableTableAdmin::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
