package Google::Spanner::Admin::Database::V1::SpannerDatabaseAdmin::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'RestoreSourceType',
    as (Int | Str);

declare 'RestoreInfo',
    as InstanceOf['Google::Spanner::Admin::Database::V1::SpannerDatabaseAdmin::RestoreInfo'];

coerce 'RestoreInfo',
    from HashRef, via { 'Google::Spanner::Admin::Database::V1::SpannerDatabaseAdmin::RestoreInfo'->new($_) };

declare 'RepeatedRestoreInfo',
    as ArrayRef[RestoreInfo()];

coerce 'RepeatedRestoreInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Admin::Database::V1::SpannerDatabaseAdmin::RestoreInfo'->new($_) } @$_ ] };

declare 'MapStringRestoreInfo',
    as HashRef[RestoreInfo()];

declare 'Database',
    as InstanceOf['Google::Spanner::Admin::Database::V1::SpannerDatabaseAdmin::Database'];

coerce 'Database',
    from HashRef, via { 'Google::Spanner::Admin::Database::V1::SpannerDatabaseAdmin::Database'->new($_) };

declare 'RepeatedDatabase',
    as ArrayRef[Database()];

coerce 'RepeatedDatabase',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Admin::Database::V1::SpannerDatabaseAdmin::Database'->new($_) } @$_ ] };

declare 'MapStringDatabase',
    as HashRef[Database()];

declare 'State',
    as (Int | Str);

declare 'ListDatabasesRequest',
    as InstanceOf['Google::Spanner::Admin::Database::V1::SpannerDatabaseAdmin::ListDatabasesRequest'];

coerce 'ListDatabasesRequest',
    from HashRef, via { 'Google::Spanner::Admin::Database::V1::SpannerDatabaseAdmin::ListDatabasesRequest'->new($_) };

declare 'RepeatedListDatabasesRequest',
    as ArrayRef[ListDatabasesRequest()];

coerce 'RepeatedListDatabasesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Admin::Database::V1::SpannerDatabaseAdmin::ListDatabasesRequest'->new($_) } @$_ ] };

declare 'MapStringListDatabasesRequest',
    as HashRef[ListDatabasesRequest()];

declare 'ListDatabasesResponse',
    as InstanceOf['Google::Spanner::Admin::Database::V1::SpannerDatabaseAdmin::ListDatabasesResponse'];

coerce 'ListDatabasesResponse',
    from HashRef, via { 'Google::Spanner::Admin::Database::V1::SpannerDatabaseAdmin::ListDatabasesResponse'->new($_) };

declare 'RepeatedListDatabasesResponse',
    as ArrayRef[ListDatabasesResponse()];

coerce 'RepeatedListDatabasesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Admin::Database::V1::SpannerDatabaseAdmin::ListDatabasesResponse'->new($_) } @$_ ] };

declare 'MapStringListDatabasesResponse',
    as HashRef[ListDatabasesResponse()];

declare 'CreateDatabaseRequest',
    as InstanceOf['Google::Spanner::Admin::Database::V1::SpannerDatabaseAdmin::CreateDatabaseRequest'];

coerce 'CreateDatabaseRequest',
    from HashRef, via { 'Google::Spanner::Admin::Database::V1::SpannerDatabaseAdmin::CreateDatabaseRequest'->new($_) };

declare 'RepeatedCreateDatabaseRequest',
    as ArrayRef[CreateDatabaseRequest()];

coerce 'RepeatedCreateDatabaseRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Admin::Database::V1::SpannerDatabaseAdmin::CreateDatabaseRequest'->new($_) } @$_ ] };

declare 'MapStringCreateDatabaseRequest',
    as HashRef[CreateDatabaseRequest()];

declare 'CreateDatabaseMetadata',
    as InstanceOf['Google::Spanner::Admin::Database::V1::SpannerDatabaseAdmin::CreateDatabaseMetadata'];

coerce 'CreateDatabaseMetadata',
    from HashRef, via { 'Google::Spanner::Admin::Database::V1::SpannerDatabaseAdmin::CreateDatabaseMetadata'->new($_) };

declare 'RepeatedCreateDatabaseMetadata',
    as ArrayRef[CreateDatabaseMetadata()];

coerce 'RepeatedCreateDatabaseMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Admin::Database::V1::SpannerDatabaseAdmin::CreateDatabaseMetadata'->new($_) } @$_ ] };

declare 'MapStringCreateDatabaseMetadata',
    as HashRef[CreateDatabaseMetadata()];

declare 'GetDatabaseRequest',
    as InstanceOf['Google::Spanner::Admin::Database::V1::SpannerDatabaseAdmin::GetDatabaseRequest'];

coerce 'GetDatabaseRequest',
    from HashRef, via { 'Google::Spanner::Admin::Database::V1::SpannerDatabaseAdmin::GetDatabaseRequest'->new($_) };

declare 'RepeatedGetDatabaseRequest',
    as ArrayRef[GetDatabaseRequest()];

coerce 'RepeatedGetDatabaseRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Admin::Database::V1::SpannerDatabaseAdmin::GetDatabaseRequest'->new($_) } @$_ ] };

declare 'MapStringGetDatabaseRequest',
    as HashRef[GetDatabaseRequest()];

declare 'UpdateDatabaseRequest',
    as InstanceOf['Google::Spanner::Admin::Database::V1::SpannerDatabaseAdmin::UpdateDatabaseRequest'];

coerce 'UpdateDatabaseRequest',
    from HashRef, via { 'Google::Spanner::Admin::Database::V1::SpannerDatabaseAdmin::UpdateDatabaseRequest'->new($_) };

declare 'RepeatedUpdateDatabaseRequest',
    as ArrayRef[UpdateDatabaseRequest()];

coerce 'RepeatedUpdateDatabaseRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Admin::Database::V1::SpannerDatabaseAdmin::UpdateDatabaseRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateDatabaseRequest',
    as HashRef[UpdateDatabaseRequest()];

declare 'UpdateDatabaseMetadata',
    as InstanceOf['Google::Spanner::Admin::Database::V1::SpannerDatabaseAdmin::UpdateDatabaseMetadata'];

coerce 'UpdateDatabaseMetadata',
    from HashRef, via { 'Google::Spanner::Admin::Database::V1::SpannerDatabaseAdmin::UpdateDatabaseMetadata'->new($_) };

declare 'RepeatedUpdateDatabaseMetadata',
    as ArrayRef[UpdateDatabaseMetadata()];

coerce 'RepeatedUpdateDatabaseMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Admin::Database::V1::SpannerDatabaseAdmin::UpdateDatabaseMetadata'->new($_) } @$_ ] };

declare 'MapStringUpdateDatabaseMetadata',
    as HashRef[UpdateDatabaseMetadata()];

declare 'UpdateDatabaseDdlRequest',
    as InstanceOf['Google::Spanner::Admin::Database::V1::SpannerDatabaseAdmin::UpdateDatabaseDdlRequest'];

coerce 'UpdateDatabaseDdlRequest',
    from HashRef, via { 'Google::Spanner::Admin::Database::V1::SpannerDatabaseAdmin::UpdateDatabaseDdlRequest'->new($_) };

declare 'RepeatedUpdateDatabaseDdlRequest',
    as ArrayRef[UpdateDatabaseDdlRequest()];

coerce 'RepeatedUpdateDatabaseDdlRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Admin::Database::V1::SpannerDatabaseAdmin::UpdateDatabaseDdlRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateDatabaseDdlRequest',
    as HashRef[UpdateDatabaseDdlRequest()];

declare 'DdlStatementActionInfo',
    as InstanceOf['Google::Spanner::Admin::Database::V1::SpannerDatabaseAdmin::DdlStatementActionInfo'];

coerce 'DdlStatementActionInfo',
    from HashRef, via { 'Google::Spanner::Admin::Database::V1::SpannerDatabaseAdmin::DdlStatementActionInfo'->new($_) };

declare 'RepeatedDdlStatementActionInfo',
    as ArrayRef[DdlStatementActionInfo()];

coerce 'RepeatedDdlStatementActionInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Admin::Database::V1::SpannerDatabaseAdmin::DdlStatementActionInfo'->new($_) } @$_ ] };

declare 'MapStringDdlStatementActionInfo',
    as HashRef[DdlStatementActionInfo()];

declare 'UpdateDatabaseDdlMetadata',
    as InstanceOf['Google::Spanner::Admin::Database::V1::SpannerDatabaseAdmin::UpdateDatabaseDdlMetadata'];

coerce 'UpdateDatabaseDdlMetadata',
    from HashRef, via { 'Google::Spanner::Admin::Database::V1::SpannerDatabaseAdmin::UpdateDatabaseDdlMetadata'->new($_) };

declare 'RepeatedUpdateDatabaseDdlMetadata',
    as ArrayRef[UpdateDatabaseDdlMetadata()];

coerce 'RepeatedUpdateDatabaseDdlMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Admin::Database::V1::SpannerDatabaseAdmin::UpdateDatabaseDdlMetadata'->new($_) } @$_ ] };

declare 'MapStringUpdateDatabaseDdlMetadata',
    as HashRef[UpdateDatabaseDdlMetadata()];

declare 'DropDatabaseRequest',
    as InstanceOf['Google::Spanner::Admin::Database::V1::SpannerDatabaseAdmin::DropDatabaseRequest'];

coerce 'DropDatabaseRequest',
    from HashRef, via { 'Google::Spanner::Admin::Database::V1::SpannerDatabaseAdmin::DropDatabaseRequest'->new($_) };

declare 'RepeatedDropDatabaseRequest',
    as ArrayRef[DropDatabaseRequest()];

coerce 'RepeatedDropDatabaseRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Admin::Database::V1::SpannerDatabaseAdmin::DropDatabaseRequest'->new($_) } @$_ ] };

declare 'MapStringDropDatabaseRequest',
    as HashRef[DropDatabaseRequest()];

declare 'GetDatabaseDdlRequest',
    as InstanceOf['Google::Spanner::Admin::Database::V1::SpannerDatabaseAdmin::GetDatabaseDdlRequest'];

coerce 'GetDatabaseDdlRequest',
    from HashRef, via { 'Google::Spanner::Admin::Database::V1::SpannerDatabaseAdmin::GetDatabaseDdlRequest'->new($_) };

declare 'RepeatedGetDatabaseDdlRequest',
    as ArrayRef[GetDatabaseDdlRequest()];

coerce 'RepeatedGetDatabaseDdlRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Admin::Database::V1::SpannerDatabaseAdmin::GetDatabaseDdlRequest'->new($_) } @$_ ] };

declare 'MapStringGetDatabaseDdlRequest',
    as HashRef[GetDatabaseDdlRequest()];

declare 'GetDatabaseDdlResponse',
    as InstanceOf['Google::Spanner::Admin::Database::V1::SpannerDatabaseAdmin::GetDatabaseDdlResponse'];

coerce 'GetDatabaseDdlResponse',
    from HashRef, via { 'Google::Spanner::Admin::Database::V1::SpannerDatabaseAdmin::GetDatabaseDdlResponse'->new($_) };

declare 'RepeatedGetDatabaseDdlResponse',
    as ArrayRef[GetDatabaseDdlResponse()];

coerce 'RepeatedGetDatabaseDdlResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Admin::Database::V1::SpannerDatabaseAdmin::GetDatabaseDdlResponse'->new($_) } @$_ ] };

declare 'MapStringGetDatabaseDdlResponse',
    as HashRef[GetDatabaseDdlResponse()];

declare 'ListDatabaseOperationsRequest',
    as InstanceOf['Google::Spanner::Admin::Database::V1::SpannerDatabaseAdmin::ListDatabaseOperationsRequest'];

coerce 'ListDatabaseOperationsRequest',
    from HashRef, via { 'Google::Spanner::Admin::Database::V1::SpannerDatabaseAdmin::ListDatabaseOperationsRequest'->new($_) };

declare 'RepeatedListDatabaseOperationsRequest',
    as ArrayRef[ListDatabaseOperationsRequest()];

coerce 'RepeatedListDatabaseOperationsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Admin::Database::V1::SpannerDatabaseAdmin::ListDatabaseOperationsRequest'->new($_) } @$_ ] };

declare 'MapStringListDatabaseOperationsRequest',
    as HashRef[ListDatabaseOperationsRequest()];

declare 'ListDatabaseOperationsResponse',
    as InstanceOf['Google::Spanner::Admin::Database::V1::SpannerDatabaseAdmin::ListDatabaseOperationsResponse'];

coerce 'ListDatabaseOperationsResponse',
    from HashRef, via { 'Google::Spanner::Admin::Database::V1::SpannerDatabaseAdmin::ListDatabaseOperationsResponse'->new($_) };

declare 'RepeatedListDatabaseOperationsResponse',
    as ArrayRef[ListDatabaseOperationsResponse()];

coerce 'RepeatedListDatabaseOperationsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Admin::Database::V1::SpannerDatabaseAdmin::ListDatabaseOperationsResponse'->new($_) } @$_ ] };

declare 'MapStringListDatabaseOperationsResponse',
    as HashRef[ListDatabaseOperationsResponse()];

declare 'RestoreDatabaseRequest',
    as InstanceOf['Google::Spanner::Admin::Database::V1::SpannerDatabaseAdmin::RestoreDatabaseRequest'];

coerce 'RestoreDatabaseRequest',
    from HashRef, via { 'Google::Spanner::Admin::Database::V1::SpannerDatabaseAdmin::RestoreDatabaseRequest'->new($_) };

declare 'RepeatedRestoreDatabaseRequest',
    as ArrayRef[RestoreDatabaseRequest()];

coerce 'RepeatedRestoreDatabaseRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Admin::Database::V1::SpannerDatabaseAdmin::RestoreDatabaseRequest'->new($_) } @$_ ] };

declare 'MapStringRestoreDatabaseRequest',
    as HashRef[RestoreDatabaseRequest()];

declare 'RestoreDatabaseEncryptionConfig',
    as InstanceOf['Google::Spanner::Admin::Database::V1::SpannerDatabaseAdmin::RestoreDatabaseEncryptionConfig'];

coerce 'RestoreDatabaseEncryptionConfig',
    from HashRef, via { 'Google::Spanner::Admin::Database::V1::SpannerDatabaseAdmin::RestoreDatabaseEncryptionConfig'->new($_) };

declare 'RepeatedRestoreDatabaseEncryptionConfig',
    as ArrayRef[RestoreDatabaseEncryptionConfig()];

coerce 'RepeatedRestoreDatabaseEncryptionConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Admin::Database::V1::SpannerDatabaseAdmin::RestoreDatabaseEncryptionConfig'->new($_) } @$_ ] };

declare 'MapStringRestoreDatabaseEncryptionConfig',
    as HashRef[RestoreDatabaseEncryptionConfig()];

declare 'EncryptionType',
    as (Int | Str);

declare 'RestoreDatabaseMetadata',
    as InstanceOf['Google::Spanner::Admin::Database::V1::SpannerDatabaseAdmin::RestoreDatabaseMetadata'];

coerce 'RestoreDatabaseMetadata',
    from HashRef, via { 'Google::Spanner::Admin::Database::V1::SpannerDatabaseAdmin::RestoreDatabaseMetadata'->new($_) };

declare 'RepeatedRestoreDatabaseMetadata',
    as ArrayRef[RestoreDatabaseMetadata()];

coerce 'RepeatedRestoreDatabaseMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Admin::Database::V1::SpannerDatabaseAdmin::RestoreDatabaseMetadata'->new($_) } @$_ ] };

declare 'MapStringRestoreDatabaseMetadata',
    as HashRef[RestoreDatabaseMetadata()];

declare 'OptimizeRestoredDatabaseMetadata',
    as InstanceOf['Google::Spanner::Admin::Database::V1::SpannerDatabaseAdmin::OptimizeRestoredDatabaseMetadata'];

coerce 'OptimizeRestoredDatabaseMetadata',
    from HashRef, via { 'Google::Spanner::Admin::Database::V1::SpannerDatabaseAdmin::OptimizeRestoredDatabaseMetadata'->new($_) };

declare 'RepeatedOptimizeRestoredDatabaseMetadata',
    as ArrayRef[OptimizeRestoredDatabaseMetadata()];

coerce 'RepeatedOptimizeRestoredDatabaseMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Admin::Database::V1::SpannerDatabaseAdmin::OptimizeRestoredDatabaseMetadata'->new($_) } @$_ ] };

declare 'MapStringOptimizeRestoredDatabaseMetadata',
    as HashRef[OptimizeRestoredDatabaseMetadata()];

declare 'DatabaseRole',
    as InstanceOf['Google::Spanner::Admin::Database::V1::SpannerDatabaseAdmin::DatabaseRole'];

coerce 'DatabaseRole',
    from HashRef, via { 'Google::Spanner::Admin::Database::V1::SpannerDatabaseAdmin::DatabaseRole'->new($_) };

declare 'RepeatedDatabaseRole',
    as ArrayRef[DatabaseRole()];

coerce 'RepeatedDatabaseRole',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Admin::Database::V1::SpannerDatabaseAdmin::DatabaseRole'->new($_) } @$_ ] };

declare 'MapStringDatabaseRole',
    as HashRef[DatabaseRole()];

declare 'ListDatabaseRolesRequest',
    as InstanceOf['Google::Spanner::Admin::Database::V1::SpannerDatabaseAdmin::ListDatabaseRolesRequest'];

coerce 'ListDatabaseRolesRequest',
    from HashRef, via { 'Google::Spanner::Admin::Database::V1::SpannerDatabaseAdmin::ListDatabaseRolesRequest'->new($_) };

declare 'RepeatedListDatabaseRolesRequest',
    as ArrayRef[ListDatabaseRolesRequest()];

coerce 'RepeatedListDatabaseRolesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Admin::Database::V1::SpannerDatabaseAdmin::ListDatabaseRolesRequest'->new($_) } @$_ ] };

declare 'MapStringListDatabaseRolesRequest',
    as HashRef[ListDatabaseRolesRequest()];

declare 'ListDatabaseRolesResponse',
    as InstanceOf['Google::Spanner::Admin::Database::V1::SpannerDatabaseAdmin::ListDatabaseRolesResponse'];

coerce 'ListDatabaseRolesResponse',
    from HashRef, via { 'Google::Spanner::Admin::Database::V1::SpannerDatabaseAdmin::ListDatabaseRolesResponse'->new($_) };

declare 'RepeatedListDatabaseRolesResponse',
    as ArrayRef[ListDatabaseRolesResponse()];

coerce 'RepeatedListDatabaseRolesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Admin::Database::V1::SpannerDatabaseAdmin::ListDatabaseRolesResponse'->new($_) } @$_ ] };

declare 'MapStringListDatabaseRolesResponse',
    as HashRef[ListDatabaseRolesResponse()];

declare 'AddSplitPointsRequest',
    as InstanceOf['Google::Spanner::Admin::Database::V1::SpannerDatabaseAdmin::AddSplitPointsRequest'];

coerce 'AddSplitPointsRequest',
    from HashRef, via { 'Google::Spanner::Admin::Database::V1::SpannerDatabaseAdmin::AddSplitPointsRequest'->new($_) };

declare 'RepeatedAddSplitPointsRequest',
    as ArrayRef[AddSplitPointsRequest()];

coerce 'RepeatedAddSplitPointsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Admin::Database::V1::SpannerDatabaseAdmin::AddSplitPointsRequest'->new($_) } @$_ ] };

declare 'MapStringAddSplitPointsRequest',
    as HashRef[AddSplitPointsRequest()];

declare 'AddSplitPointsResponse',
    as InstanceOf['Google::Spanner::Admin::Database::V1::SpannerDatabaseAdmin::AddSplitPointsResponse'];

coerce 'AddSplitPointsResponse',
    from HashRef, via { 'Google::Spanner::Admin::Database::V1::SpannerDatabaseAdmin::AddSplitPointsResponse'->new($_) };

declare 'RepeatedAddSplitPointsResponse',
    as ArrayRef[AddSplitPointsResponse()];

coerce 'RepeatedAddSplitPointsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Admin::Database::V1::SpannerDatabaseAdmin::AddSplitPointsResponse'->new($_) } @$_ ] };

declare 'MapStringAddSplitPointsResponse',
    as HashRef[AddSplitPointsResponse()];

declare 'SplitPoints',
    as InstanceOf['Google::Spanner::Admin::Database::V1::SpannerDatabaseAdmin::SplitPoints'];

coerce 'SplitPoints',
    from HashRef, via { 'Google::Spanner::Admin::Database::V1::SpannerDatabaseAdmin::SplitPoints'->new($_) };

declare 'RepeatedSplitPoints',
    as ArrayRef[SplitPoints()];

coerce 'RepeatedSplitPoints',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Admin::Database::V1::SpannerDatabaseAdmin::SplitPoints'->new($_) } @$_ ] };

declare 'MapStringSplitPoints',
    as HashRef[SplitPoints()];

declare 'Key',
    as InstanceOf['Google::Spanner::Admin::Database::V1::SpannerDatabaseAdmin::SplitPoints::Key'];

coerce 'Key',
    from HashRef, via { 'Google::Spanner::Admin::Database::V1::SpannerDatabaseAdmin::SplitPoints::Key'->new($_) };

declare 'RepeatedKey',
    as ArrayRef[Key()];

coerce 'RepeatedKey',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Admin::Database::V1::SpannerDatabaseAdmin::SplitPoints::Key'->new($_) } @$_ ] };

declare 'MapStringKey',
    as HashRef[Key()];

declare 'InternalUpdateGraphOperationRequest',
    as InstanceOf['Google::Spanner::Admin::Database::V1::SpannerDatabaseAdmin::InternalUpdateGraphOperationRequest'];

coerce 'InternalUpdateGraphOperationRequest',
    from HashRef, via { 'Google::Spanner::Admin::Database::V1::SpannerDatabaseAdmin::InternalUpdateGraphOperationRequest'->new($_) };

declare 'RepeatedInternalUpdateGraphOperationRequest',
    as ArrayRef[InternalUpdateGraphOperationRequest()];

coerce 'RepeatedInternalUpdateGraphOperationRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Admin::Database::V1::SpannerDatabaseAdmin::InternalUpdateGraphOperationRequest'->new($_) } @$_ ] };

declare 'MapStringInternalUpdateGraphOperationRequest',
    as HashRef[InternalUpdateGraphOperationRequest()];

declare 'InternalUpdateGraphOperationResponse',
    as InstanceOf['Google::Spanner::Admin::Database::V1::SpannerDatabaseAdmin::InternalUpdateGraphOperationResponse'];

coerce 'InternalUpdateGraphOperationResponse',
    from HashRef, via { 'Google::Spanner::Admin::Database::V1::SpannerDatabaseAdmin::InternalUpdateGraphOperationResponse'->new($_) };

declare 'RepeatedInternalUpdateGraphOperationResponse',
    as ArrayRef[InternalUpdateGraphOperationResponse()];

coerce 'RepeatedInternalUpdateGraphOperationResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Admin::Database::V1::SpannerDatabaseAdmin::InternalUpdateGraphOperationResponse'->new($_) } @$_ ] };

declare 'MapStringInternalUpdateGraphOperationResponse',
    as HashRef[InternalUpdateGraphOperationResponse()];

1;

__END__

=head1 NAME

Google::Spanner::Admin::Database::V1::SpannerDatabaseAdmin::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
