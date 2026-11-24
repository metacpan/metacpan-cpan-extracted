package Google::Spanner::Executor::V1::CloudExecutor::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'SpannerAsyncActionRequest',
    as InstanceOf['Google::Spanner::Executor::V1::CloudExecutor::SpannerAsyncActionRequest'];

coerce 'SpannerAsyncActionRequest',
    from HashRef, via { 'Google::Spanner::Executor::V1::CloudExecutor::SpannerAsyncActionRequest'->new($_) };

declare 'RepeatedSpannerAsyncActionRequest',
    as ArrayRef[SpannerAsyncActionRequest()];

coerce 'RepeatedSpannerAsyncActionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Executor::V1::CloudExecutor::SpannerAsyncActionRequest'->new($_) } @$_ ] };

declare 'MapStringSpannerAsyncActionRequest',
    as HashRef[SpannerAsyncActionRequest()];

declare 'SpannerAsyncActionResponse',
    as InstanceOf['Google::Spanner::Executor::V1::CloudExecutor::SpannerAsyncActionResponse'];

coerce 'SpannerAsyncActionResponse',
    from HashRef, via { 'Google::Spanner::Executor::V1::CloudExecutor::SpannerAsyncActionResponse'->new($_) };

declare 'RepeatedSpannerAsyncActionResponse',
    as ArrayRef[SpannerAsyncActionResponse()];

coerce 'RepeatedSpannerAsyncActionResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Executor::V1::CloudExecutor::SpannerAsyncActionResponse'->new($_) } @$_ ] };

declare 'MapStringSpannerAsyncActionResponse',
    as HashRef[SpannerAsyncActionResponse()];

declare 'SpannerAction',
    as InstanceOf['Google::Spanner::Executor::V1::CloudExecutor::SpannerAction'];

coerce 'SpannerAction',
    from HashRef, via { 'Google::Spanner::Executor::V1::CloudExecutor::SpannerAction'->new($_) };

declare 'RepeatedSpannerAction',
    as ArrayRef[SpannerAction()];

coerce 'RepeatedSpannerAction',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Executor::V1::CloudExecutor::SpannerAction'->new($_) } @$_ ] };

declare 'MapStringSpannerAction',
    as HashRef[SpannerAction()];

declare 'ReadAction',
    as InstanceOf['Google::Spanner::Executor::V1::CloudExecutor::ReadAction'];

coerce 'ReadAction',
    from HashRef, via { 'Google::Spanner::Executor::V1::CloudExecutor::ReadAction'->new($_) };

declare 'RepeatedReadAction',
    as ArrayRef[ReadAction()];

coerce 'RepeatedReadAction',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Executor::V1::CloudExecutor::ReadAction'->new($_) } @$_ ] };

declare 'MapStringReadAction',
    as HashRef[ReadAction()];

declare 'QueryAction',
    as InstanceOf['Google::Spanner::Executor::V1::CloudExecutor::QueryAction'];

coerce 'QueryAction',
    from HashRef, via { 'Google::Spanner::Executor::V1::CloudExecutor::QueryAction'->new($_) };

declare 'RepeatedQueryAction',
    as ArrayRef[QueryAction()];

coerce 'RepeatedQueryAction',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Executor::V1::CloudExecutor::QueryAction'->new($_) } @$_ ] };

declare 'MapStringQueryAction',
    as HashRef[QueryAction()];

declare 'Parameter',
    as InstanceOf['Google::Spanner::Executor::V1::CloudExecutor::QueryAction::Parameter'];

coerce 'Parameter',
    from HashRef, via { 'Google::Spanner::Executor::V1::CloudExecutor::QueryAction::Parameter'->new($_) };

declare 'RepeatedParameter',
    as ArrayRef[Parameter()];

coerce 'RepeatedParameter',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Executor::V1::CloudExecutor::QueryAction::Parameter'->new($_) } @$_ ] };

declare 'MapStringParameter',
    as HashRef[Parameter()];

declare 'SecureContextEntry',
    as InstanceOf['Google::Spanner::Executor::V1::CloudExecutor::QueryAction::SecureContextEntry'];

coerce 'SecureContextEntry',
    from HashRef, via { 'Google::Spanner::Executor::V1::CloudExecutor::QueryAction::SecureContextEntry'->new($_) };

declare 'RepeatedSecureContextEntry',
    as ArrayRef[SecureContextEntry()];

coerce 'RepeatedSecureContextEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Executor::V1::CloudExecutor::QueryAction::SecureContextEntry'->new($_) } @$_ ] };

declare 'MapStringSecureContextEntry',
    as HashRef[SecureContextEntry()];

declare 'DmlAction',
    as InstanceOf['Google::Spanner::Executor::V1::CloudExecutor::DmlAction'];

coerce 'DmlAction',
    from HashRef, via { 'Google::Spanner::Executor::V1::CloudExecutor::DmlAction'->new($_) };

declare 'RepeatedDmlAction',
    as ArrayRef[DmlAction()];

coerce 'RepeatedDmlAction',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Executor::V1::CloudExecutor::DmlAction'->new($_) } @$_ ] };

declare 'MapStringDmlAction',
    as HashRef[DmlAction()];

declare 'BatchDmlAction',
    as InstanceOf['Google::Spanner::Executor::V1::CloudExecutor::BatchDmlAction'];

coerce 'BatchDmlAction',
    from HashRef, via { 'Google::Spanner::Executor::V1::CloudExecutor::BatchDmlAction'->new($_) };

declare 'RepeatedBatchDmlAction',
    as ArrayRef[BatchDmlAction()];

coerce 'RepeatedBatchDmlAction',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Executor::V1::CloudExecutor::BatchDmlAction'->new($_) } @$_ ] };

declare 'MapStringBatchDmlAction',
    as HashRef[BatchDmlAction()];

declare 'Value',
    as InstanceOf['Google::Spanner::Executor::V1::CloudExecutor::Value'];

coerce 'Value',
    from HashRef, via { 'Google::Spanner::Executor::V1::CloudExecutor::Value'->new($_) };

declare 'RepeatedValue',
    as ArrayRef[Value()];

coerce 'RepeatedValue',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Executor::V1::CloudExecutor::Value'->new($_) } @$_ ] };

declare 'MapStringValue',
    as HashRef[Value()];

declare 'KeyRange',
    as InstanceOf['Google::Spanner::Executor::V1::CloudExecutor::KeyRange'];

coerce 'KeyRange',
    from HashRef, via { 'Google::Spanner::Executor::V1::CloudExecutor::KeyRange'->new($_) };

declare 'RepeatedKeyRange',
    as ArrayRef[KeyRange()];

coerce 'RepeatedKeyRange',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Executor::V1::CloudExecutor::KeyRange'->new($_) } @$_ ] };

declare 'MapStringKeyRange',
    as HashRef[KeyRange()];

declare 'Type',
    as (Int | Str);

declare 'KeySet',
    as InstanceOf['Google::Spanner::Executor::V1::CloudExecutor::KeySet'];

coerce 'KeySet',
    from HashRef, via { 'Google::Spanner::Executor::V1::CloudExecutor::KeySet'->new($_) };

declare 'RepeatedKeySet',
    as ArrayRef[KeySet()];

coerce 'RepeatedKeySet',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Executor::V1::CloudExecutor::KeySet'->new($_) } @$_ ] };

declare 'MapStringKeySet',
    as HashRef[KeySet()];

declare 'ValueList',
    as InstanceOf['Google::Spanner::Executor::V1::CloudExecutor::ValueList'];

coerce 'ValueList',
    from HashRef, via { 'Google::Spanner::Executor::V1::CloudExecutor::ValueList'->new($_) };

declare 'RepeatedValueList',
    as ArrayRef[ValueList()];

coerce 'RepeatedValueList',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Executor::V1::CloudExecutor::ValueList'->new($_) } @$_ ] };

declare 'MapStringValueList',
    as HashRef[ValueList()];

declare 'MutationAction',
    as InstanceOf['Google::Spanner::Executor::V1::CloudExecutor::MutationAction'];

coerce 'MutationAction',
    from HashRef, via { 'Google::Spanner::Executor::V1::CloudExecutor::MutationAction'->new($_) };

declare 'RepeatedMutationAction',
    as ArrayRef[MutationAction()];

coerce 'RepeatedMutationAction',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Executor::V1::CloudExecutor::MutationAction'->new($_) } @$_ ] };

declare 'MapStringMutationAction',
    as HashRef[MutationAction()];

declare 'InsertArgs',
    as InstanceOf['Google::Spanner::Executor::V1::CloudExecutor::MutationAction::InsertArgs'];

coerce 'InsertArgs',
    from HashRef, via { 'Google::Spanner::Executor::V1::CloudExecutor::MutationAction::InsertArgs'->new($_) };

declare 'RepeatedInsertArgs',
    as ArrayRef[InsertArgs()];

coerce 'RepeatedInsertArgs',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Executor::V1::CloudExecutor::MutationAction::InsertArgs'->new($_) } @$_ ] };

declare 'MapStringInsertArgs',
    as HashRef[InsertArgs()];

declare 'UpdateArgs',
    as InstanceOf['Google::Spanner::Executor::V1::CloudExecutor::MutationAction::UpdateArgs'];

coerce 'UpdateArgs',
    from HashRef, via { 'Google::Spanner::Executor::V1::CloudExecutor::MutationAction::UpdateArgs'->new($_) };

declare 'RepeatedUpdateArgs',
    as ArrayRef[UpdateArgs()];

coerce 'RepeatedUpdateArgs',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Executor::V1::CloudExecutor::MutationAction::UpdateArgs'->new($_) } @$_ ] };

declare 'MapStringUpdateArgs',
    as HashRef[UpdateArgs()];

declare 'Mod',
    as InstanceOf['Google::Spanner::Executor::V1::CloudExecutor::MutationAction::Mod'];

coerce 'Mod',
    from HashRef, via { 'Google::Spanner::Executor::V1::CloudExecutor::MutationAction::Mod'->new($_) };

declare 'RepeatedMod',
    as ArrayRef[Mod()];

coerce 'RepeatedMod',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Executor::V1::CloudExecutor::MutationAction::Mod'->new($_) } @$_ ] };

declare 'MapStringMod',
    as HashRef[Mod()];

declare 'WriteMutationsAction',
    as InstanceOf['Google::Spanner::Executor::V1::CloudExecutor::WriteMutationsAction'];

coerce 'WriteMutationsAction',
    from HashRef, via { 'Google::Spanner::Executor::V1::CloudExecutor::WriteMutationsAction'->new($_) };

declare 'RepeatedWriteMutationsAction',
    as ArrayRef[WriteMutationsAction()];

coerce 'RepeatedWriteMutationsAction',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Executor::V1::CloudExecutor::WriteMutationsAction'->new($_) } @$_ ] };

declare 'MapStringWriteMutationsAction',
    as HashRef[WriteMutationsAction()];

declare 'PartitionedUpdateAction',
    as InstanceOf['Google::Spanner::Executor::V1::CloudExecutor::PartitionedUpdateAction'];

coerce 'PartitionedUpdateAction',
    from HashRef, via { 'Google::Spanner::Executor::V1::CloudExecutor::PartitionedUpdateAction'->new($_) };

declare 'RepeatedPartitionedUpdateAction',
    as ArrayRef[PartitionedUpdateAction()];

coerce 'RepeatedPartitionedUpdateAction',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Executor::V1::CloudExecutor::PartitionedUpdateAction'->new($_) } @$_ ] };

declare 'MapStringPartitionedUpdateAction',
    as HashRef[PartitionedUpdateAction()];

declare 'ExecutePartitionedUpdateOptions',
    as InstanceOf['Google::Spanner::Executor::V1::CloudExecutor::PartitionedUpdateAction::ExecutePartitionedUpdateOptions'];

coerce 'ExecutePartitionedUpdateOptions',
    from HashRef, via { 'Google::Spanner::Executor::V1::CloudExecutor::PartitionedUpdateAction::ExecutePartitionedUpdateOptions'->new($_) };

declare 'RepeatedExecutePartitionedUpdateOptions',
    as ArrayRef[ExecutePartitionedUpdateOptions()];

coerce 'RepeatedExecutePartitionedUpdateOptions',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Executor::V1::CloudExecutor::PartitionedUpdateAction::ExecutePartitionedUpdateOptions'->new($_) } @$_ ] };

declare 'MapStringExecutePartitionedUpdateOptions',
    as HashRef[ExecutePartitionedUpdateOptions()];

declare 'StartTransactionAction',
    as InstanceOf['Google::Spanner::Executor::V1::CloudExecutor::StartTransactionAction'];

coerce 'StartTransactionAction',
    from HashRef, via { 'Google::Spanner::Executor::V1::CloudExecutor::StartTransactionAction'->new($_) };

declare 'RepeatedStartTransactionAction',
    as ArrayRef[StartTransactionAction()];

coerce 'RepeatedStartTransactionAction',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Executor::V1::CloudExecutor::StartTransactionAction'->new($_) } @$_ ] };

declare 'MapStringStartTransactionAction',
    as HashRef[StartTransactionAction()];

declare 'Concurrency',
    as InstanceOf['Google::Spanner::Executor::V1::CloudExecutor::Concurrency'];

coerce 'Concurrency',
    from HashRef, via { 'Google::Spanner::Executor::V1::CloudExecutor::Concurrency'->new($_) };

declare 'RepeatedConcurrency',
    as ArrayRef[Concurrency()];

coerce 'RepeatedConcurrency',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Executor::V1::CloudExecutor::Concurrency'->new($_) } @$_ ] };

declare 'MapStringConcurrency',
    as HashRef[Concurrency()];

declare 'TableMetadata',
    as InstanceOf['Google::Spanner::Executor::V1::CloudExecutor::TableMetadata'];

coerce 'TableMetadata',
    from HashRef, via { 'Google::Spanner::Executor::V1::CloudExecutor::TableMetadata'->new($_) };

declare 'RepeatedTableMetadata',
    as ArrayRef[TableMetadata()];

coerce 'RepeatedTableMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Executor::V1::CloudExecutor::TableMetadata'->new($_) } @$_ ] };

declare 'MapStringTableMetadata',
    as HashRef[TableMetadata()];

declare 'ColumnMetadata',
    as InstanceOf['Google::Spanner::Executor::V1::CloudExecutor::ColumnMetadata'];

coerce 'ColumnMetadata',
    from HashRef, via { 'Google::Spanner::Executor::V1::CloudExecutor::ColumnMetadata'->new($_) };

declare 'RepeatedColumnMetadata',
    as ArrayRef[ColumnMetadata()];

coerce 'RepeatedColumnMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Executor::V1::CloudExecutor::ColumnMetadata'->new($_) } @$_ ] };

declare 'MapStringColumnMetadata',
    as HashRef[ColumnMetadata()];

declare 'TransactionExecutionOptions',
    as InstanceOf['Google::Spanner::Executor::V1::CloudExecutor::TransactionExecutionOptions'];

coerce 'TransactionExecutionOptions',
    from HashRef, via { 'Google::Spanner::Executor::V1::CloudExecutor::TransactionExecutionOptions'->new($_) };

declare 'RepeatedTransactionExecutionOptions',
    as ArrayRef[TransactionExecutionOptions()];

coerce 'RepeatedTransactionExecutionOptions',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Executor::V1::CloudExecutor::TransactionExecutionOptions'->new($_) } @$_ ] };

declare 'MapStringTransactionExecutionOptions',
    as HashRef[TransactionExecutionOptions()];

declare 'FinishTransactionAction',
    as InstanceOf['Google::Spanner::Executor::V1::CloudExecutor::FinishTransactionAction'];

coerce 'FinishTransactionAction',
    from HashRef, via { 'Google::Spanner::Executor::V1::CloudExecutor::FinishTransactionAction'->new($_) };

declare 'RepeatedFinishTransactionAction',
    as ArrayRef[FinishTransactionAction()];

coerce 'RepeatedFinishTransactionAction',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Executor::V1::CloudExecutor::FinishTransactionAction'->new($_) } @$_ ] };

declare 'MapStringFinishTransactionAction',
    as HashRef[FinishTransactionAction()];

declare 'Mode',
    as (Int | Str);

declare 'AdminAction',
    as InstanceOf['Google::Spanner::Executor::V1::CloudExecutor::AdminAction'];

coerce 'AdminAction',
    from HashRef, via { 'Google::Spanner::Executor::V1::CloudExecutor::AdminAction'->new($_) };

declare 'RepeatedAdminAction',
    as ArrayRef[AdminAction()];

coerce 'RepeatedAdminAction',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Executor::V1::CloudExecutor::AdminAction'->new($_) } @$_ ] };

declare 'MapStringAdminAction',
    as HashRef[AdminAction()];

declare 'CreateUserInstanceConfigAction',
    as InstanceOf['Google::Spanner::Executor::V1::CloudExecutor::CreateUserInstanceConfigAction'];

coerce 'CreateUserInstanceConfigAction',
    from HashRef, via { 'Google::Spanner::Executor::V1::CloudExecutor::CreateUserInstanceConfigAction'->new($_) };

declare 'RepeatedCreateUserInstanceConfigAction',
    as ArrayRef[CreateUserInstanceConfigAction()];

coerce 'RepeatedCreateUserInstanceConfigAction',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Executor::V1::CloudExecutor::CreateUserInstanceConfigAction'->new($_) } @$_ ] };

declare 'MapStringCreateUserInstanceConfigAction',
    as HashRef[CreateUserInstanceConfigAction()];

declare 'UpdateUserInstanceConfigAction',
    as InstanceOf['Google::Spanner::Executor::V1::CloudExecutor::UpdateUserInstanceConfigAction'];

coerce 'UpdateUserInstanceConfigAction',
    from HashRef, via { 'Google::Spanner::Executor::V1::CloudExecutor::UpdateUserInstanceConfigAction'->new($_) };

declare 'RepeatedUpdateUserInstanceConfigAction',
    as ArrayRef[UpdateUserInstanceConfigAction()];

coerce 'RepeatedUpdateUserInstanceConfigAction',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Executor::V1::CloudExecutor::UpdateUserInstanceConfigAction'->new($_) } @$_ ] };

declare 'MapStringUpdateUserInstanceConfigAction',
    as HashRef[UpdateUserInstanceConfigAction()];

declare 'LabelsEntry',
    as InstanceOf['Google::Spanner::Executor::V1::CloudExecutor::UpdateUserInstanceConfigAction::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Spanner::Executor::V1::CloudExecutor::UpdateUserInstanceConfigAction::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Executor::V1::CloudExecutor::UpdateUserInstanceConfigAction::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'GetCloudInstanceConfigAction',
    as InstanceOf['Google::Spanner::Executor::V1::CloudExecutor::GetCloudInstanceConfigAction'];

coerce 'GetCloudInstanceConfigAction',
    from HashRef, via { 'Google::Spanner::Executor::V1::CloudExecutor::GetCloudInstanceConfigAction'->new($_) };

declare 'RepeatedGetCloudInstanceConfigAction',
    as ArrayRef[GetCloudInstanceConfigAction()];

coerce 'RepeatedGetCloudInstanceConfigAction',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Executor::V1::CloudExecutor::GetCloudInstanceConfigAction'->new($_) } @$_ ] };

declare 'MapStringGetCloudInstanceConfigAction',
    as HashRef[GetCloudInstanceConfigAction()];

declare 'DeleteUserInstanceConfigAction',
    as InstanceOf['Google::Spanner::Executor::V1::CloudExecutor::DeleteUserInstanceConfigAction'];

coerce 'DeleteUserInstanceConfigAction',
    from HashRef, via { 'Google::Spanner::Executor::V1::CloudExecutor::DeleteUserInstanceConfigAction'->new($_) };

declare 'RepeatedDeleteUserInstanceConfigAction',
    as ArrayRef[DeleteUserInstanceConfigAction()];

coerce 'RepeatedDeleteUserInstanceConfigAction',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Executor::V1::CloudExecutor::DeleteUserInstanceConfigAction'->new($_) } @$_ ] };

declare 'MapStringDeleteUserInstanceConfigAction',
    as HashRef[DeleteUserInstanceConfigAction()];

declare 'ListCloudInstanceConfigsAction',
    as InstanceOf['Google::Spanner::Executor::V1::CloudExecutor::ListCloudInstanceConfigsAction'];

coerce 'ListCloudInstanceConfigsAction',
    from HashRef, via { 'Google::Spanner::Executor::V1::CloudExecutor::ListCloudInstanceConfigsAction'->new($_) };

declare 'RepeatedListCloudInstanceConfigsAction',
    as ArrayRef[ListCloudInstanceConfigsAction()];

coerce 'RepeatedListCloudInstanceConfigsAction',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Executor::V1::CloudExecutor::ListCloudInstanceConfigsAction'->new($_) } @$_ ] };

declare 'MapStringListCloudInstanceConfigsAction',
    as HashRef[ListCloudInstanceConfigsAction()];

declare 'CreateCloudInstanceAction',
    as InstanceOf['Google::Spanner::Executor::V1::CloudExecutor::CreateCloudInstanceAction'];

coerce 'CreateCloudInstanceAction',
    from HashRef, via { 'Google::Spanner::Executor::V1::CloudExecutor::CreateCloudInstanceAction'->new($_) };

declare 'RepeatedCreateCloudInstanceAction',
    as ArrayRef[CreateCloudInstanceAction()];

coerce 'RepeatedCreateCloudInstanceAction',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Executor::V1::CloudExecutor::CreateCloudInstanceAction'->new($_) } @$_ ] };

declare 'MapStringCreateCloudInstanceAction',
    as HashRef[CreateCloudInstanceAction()];

declare 'LabelsEntry',
    as InstanceOf['Google::Spanner::Executor::V1::CloudExecutor::CreateCloudInstanceAction::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Spanner::Executor::V1::CloudExecutor::CreateCloudInstanceAction::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Executor::V1::CloudExecutor::CreateCloudInstanceAction::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'UpdateCloudInstanceAction',
    as InstanceOf['Google::Spanner::Executor::V1::CloudExecutor::UpdateCloudInstanceAction'];

coerce 'UpdateCloudInstanceAction',
    from HashRef, via { 'Google::Spanner::Executor::V1::CloudExecutor::UpdateCloudInstanceAction'->new($_) };

declare 'RepeatedUpdateCloudInstanceAction',
    as ArrayRef[UpdateCloudInstanceAction()];

coerce 'RepeatedUpdateCloudInstanceAction',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Executor::V1::CloudExecutor::UpdateCloudInstanceAction'->new($_) } @$_ ] };

declare 'MapStringUpdateCloudInstanceAction',
    as HashRef[UpdateCloudInstanceAction()];

declare 'LabelsEntry',
    as InstanceOf['Google::Spanner::Executor::V1::CloudExecutor::UpdateCloudInstanceAction::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Spanner::Executor::V1::CloudExecutor::UpdateCloudInstanceAction::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Executor::V1::CloudExecutor::UpdateCloudInstanceAction::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'DeleteCloudInstanceAction',
    as InstanceOf['Google::Spanner::Executor::V1::CloudExecutor::DeleteCloudInstanceAction'];

coerce 'DeleteCloudInstanceAction',
    from HashRef, via { 'Google::Spanner::Executor::V1::CloudExecutor::DeleteCloudInstanceAction'->new($_) };

declare 'RepeatedDeleteCloudInstanceAction',
    as ArrayRef[DeleteCloudInstanceAction()];

coerce 'RepeatedDeleteCloudInstanceAction',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Executor::V1::CloudExecutor::DeleteCloudInstanceAction'->new($_) } @$_ ] };

declare 'MapStringDeleteCloudInstanceAction',
    as HashRef[DeleteCloudInstanceAction()];

declare 'CreateCloudDatabaseAction',
    as InstanceOf['Google::Spanner::Executor::V1::CloudExecutor::CreateCloudDatabaseAction'];

coerce 'CreateCloudDatabaseAction',
    from HashRef, via { 'Google::Spanner::Executor::V1::CloudExecutor::CreateCloudDatabaseAction'->new($_) };

declare 'RepeatedCreateCloudDatabaseAction',
    as ArrayRef[CreateCloudDatabaseAction()];

coerce 'RepeatedCreateCloudDatabaseAction',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Executor::V1::CloudExecutor::CreateCloudDatabaseAction'->new($_) } @$_ ] };

declare 'MapStringCreateCloudDatabaseAction',
    as HashRef[CreateCloudDatabaseAction()];

declare 'UpdateCloudDatabaseDdlAction',
    as InstanceOf['Google::Spanner::Executor::V1::CloudExecutor::UpdateCloudDatabaseDdlAction'];

coerce 'UpdateCloudDatabaseDdlAction',
    from HashRef, via { 'Google::Spanner::Executor::V1::CloudExecutor::UpdateCloudDatabaseDdlAction'->new($_) };

declare 'RepeatedUpdateCloudDatabaseDdlAction',
    as ArrayRef[UpdateCloudDatabaseDdlAction()];

coerce 'RepeatedUpdateCloudDatabaseDdlAction',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Executor::V1::CloudExecutor::UpdateCloudDatabaseDdlAction'->new($_) } @$_ ] };

declare 'MapStringUpdateCloudDatabaseDdlAction',
    as HashRef[UpdateCloudDatabaseDdlAction()];

declare 'UpdateCloudDatabaseAction',
    as InstanceOf['Google::Spanner::Executor::V1::CloudExecutor::UpdateCloudDatabaseAction'];

coerce 'UpdateCloudDatabaseAction',
    from HashRef, via { 'Google::Spanner::Executor::V1::CloudExecutor::UpdateCloudDatabaseAction'->new($_) };

declare 'RepeatedUpdateCloudDatabaseAction',
    as ArrayRef[UpdateCloudDatabaseAction()];

coerce 'RepeatedUpdateCloudDatabaseAction',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Executor::V1::CloudExecutor::UpdateCloudDatabaseAction'->new($_) } @$_ ] };

declare 'MapStringUpdateCloudDatabaseAction',
    as HashRef[UpdateCloudDatabaseAction()];

declare 'DropCloudDatabaseAction',
    as InstanceOf['Google::Spanner::Executor::V1::CloudExecutor::DropCloudDatabaseAction'];

coerce 'DropCloudDatabaseAction',
    from HashRef, via { 'Google::Spanner::Executor::V1::CloudExecutor::DropCloudDatabaseAction'->new($_) };

declare 'RepeatedDropCloudDatabaseAction',
    as ArrayRef[DropCloudDatabaseAction()];

coerce 'RepeatedDropCloudDatabaseAction',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Executor::V1::CloudExecutor::DropCloudDatabaseAction'->new($_) } @$_ ] };

declare 'MapStringDropCloudDatabaseAction',
    as HashRef[DropCloudDatabaseAction()];

declare 'ChangeQuorumCloudDatabaseAction',
    as InstanceOf['Google::Spanner::Executor::V1::CloudExecutor::ChangeQuorumCloudDatabaseAction'];

coerce 'ChangeQuorumCloudDatabaseAction',
    from HashRef, via { 'Google::Spanner::Executor::V1::CloudExecutor::ChangeQuorumCloudDatabaseAction'->new($_) };

declare 'RepeatedChangeQuorumCloudDatabaseAction',
    as ArrayRef[ChangeQuorumCloudDatabaseAction()];

coerce 'RepeatedChangeQuorumCloudDatabaseAction',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Executor::V1::CloudExecutor::ChangeQuorumCloudDatabaseAction'->new($_) } @$_ ] };

declare 'MapStringChangeQuorumCloudDatabaseAction',
    as HashRef[ChangeQuorumCloudDatabaseAction()];

declare 'AdaptMessageAction',
    as InstanceOf['Google::Spanner::Executor::V1::CloudExecutor::AdaptMessageAction'];

coerce 'AdaptMessageAction',
    from HashRef, via { 'Google::Spanner::Executor::V1::CloudExecutor::AdaptMessageAction'->new($_) };

declare 'RepeatedAdaptMessageAction',
    as ArrayRef[AdaptMessageAction()];

coerce 'RepeatedAdaptMessageAction',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Executor::V1::CloudExecutor::AdaptMessageAction'->new($_) } @$_ ] };

declare 'MapStringAdaptMessageAction',
    as HashRef[AdaptMessageAction()];

declare 'AttachmentsEntry',
    as InstanceOf['Google::Spanner::Executor::V1::CloudExecutor::AdaptMessageAction::AttachmentsEntry'];

coerce 'AttachmentsEntry',
    from HashRef, via { 'Google::Spanner::Executor::V1::CloudExecutor::AdaptMessageAction::AttachmentsEntry'->new($_) };

declare 'RepeatedAttachmentsEntry',
    as ArrayRef[AttachmentsEntry()];

coerce 'RepeatedAttachmentsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Executor::V1::CloudExecutor::AdaptMessageAction::AttachmentsEntry'->new($_) } @$_ ] };

declare 'MapStringAttachmentsEntry',
    as HashRef[AttachmentsEntry()];

declare 'ListCloudDatabasesAction',
    as InstanceOf['Google::Spanner::Executor::V1::CloudExecutor::ListCloudDatabasesAction'];

coerce 'ListCloudDatabasesAction',
    from HashRef, via { 'Google::Spanner::Executor::V1::CloudExecutor::ListCloudDatabasesAction'->new($_) };

declare 'RepeatedListCloudDatabasesAction',
    as ArrayRef[ListCloudDatabasesAction()];

coerce 'RepeatedListCloudDatabasesAction',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Executor::V1::CloudExecutor::ListCloudDatabasesAction'->new($_) } @$_ ] };

declare 'MapStringListCloudDatabasesAction',
    as HashRef[ListCloudDatabasesAction()];

declare 'ListCloudInstancesAction',
    as InstanceOf['Google::Spanner::Executor::V1::CloudExecutor::ListCloudInstancesAction'];

coerce 'ListCloudInstancesAction',
    from HashRef, via { 'Google::Spanner::Executor::V1::CloudExecutor::ListCloudInstancesAction'->new($_) };

declare 'RepeatedListCloudInstancesAction',
    as ArrayRef[ListCloudInstancesAction()];

coerce 'RepeatedListCloudInstancesAction',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Executor::V1::CloudExecutor::ListCloudInstancesAction'->new($_) } @$_ ] };

declare 'MapStringListCloudInstancesAction',
    as HashRef[ListCloudInstancesAction()];

declare 'GetCloudInstanceAction',
    as InstanceOf['Google::Spanner::Executor::V1::CloudExecutor::GetCloudInstanceAction'];

coerce 'GetCloudInstanceAction',
    from HashRef, via { 'Google::Spanner::Executor::V1::CloudExecutor::GetCloudInstanceAction'->new($_) };

declare 'RepeatedGetCloudInstanceAction',
    as ArrayRef[GetCloudInstanceAction()];

coerce 'RepeatedGetCloudInstanceAction',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Executor::V1::CloudExecutor::GetCloudInstanceAction'->new($_) } @$_ ] };

declare 'MapStringGetCloudInstanceAction',
    as HashRef[GetCloudInstanceAction()];

declare 'ListCloudDatabaseOperationsAction',
    as InstanceOf['Google::Spanner::Executor::V1::CloudExecutor::ListCloudDatabaseOperationsAction'];

coerce 'ListCloudDatabaseOperationsAction',
    from HashRef, via { 'Google::Spanner::Executor::V1::CloudExecutor::ListCloudDatabaseOperationsAction'->new($_) };

declare 'RepeatedListCloudDatabaseOperationsAction',
    as ArrayRef[ListCloudDatabaseOperationsAction()];

coerce 'RepeatedListCloudDatabaseOperationsAction',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Executor::V1::CloudExecutor::ListCloudDatabaseOperationsAction'->new($_) } @$_ ] };

declare 'MapStringListCloudDatabaseOperationsAction',
    as HashRef[ListCloudDatabaseOperationsAction()];

declare 'RestoreCloudDatabaseAction',
    as InstanceOf['Google::Spanner::Executor::V1::CloudExecutor::RestoreCloudDatabaseAction'];

coerce 'RestoreCloudDatabaseAction',
    from HashRef, via { 'Google::Spanner::Executor::V1::CloudExecutor::RestoreCloudDatabaseAction'->new($_) };

declare 'RepeatedRestoreCloudDatabaseAction',
    as ArrayRef[RestoreCloudDatabaseAction()];

coerce 'RepeatedRestoreCloudDatabaseAction',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Executor::V1::CloudExecutor::RestoreCloudDatabaseAction'->new($_) } @$_ ] };

declare 'MapStringRestoreCloudDatabaseAction',
    as HashRef[RestoreCloudDatabaseAction()];

declare 'GetCloudDatabaseAction',
    as InstanceOf['Google::Spanner::Executor::V1::CloudExecutor::GetCloudDatabaseAction'];

coerce 'GetCloudDatabaseAction',
    from HashRef, via { 'Google::Spanner::Executor::V1::CloudExecutor::GetCloudDatabaseAction'->new($_) };

declare 'RepeatedGetCloudDatabaseAction',
    as ArrayRef[GetCloudDatabaseAction()];

coerce 'RepeatedGetCloudDatabaseAction',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Executor::V1::CloudExecutor::GetCloudDatabaseAction'->new($_) } @$_ ] };

declare 'MapStringGetCloudDatabaseAction',
    as HashRef[GetCloudDatabaseAction()];

declare 'CreateCloudBackupAction',
    as InstanceOf['Google::Spanner::Executor::V1::CloudExecutor::CreateCloudBackupAction'];

coerce 'CreateCloudBackupAction',
    from HashRef, via { 'Google::Spanner::Executor::V1::CloudExecutor::CreateCloudBackupAction'->new($_) };

declare 'RepeatedCreateCloudBackupAction',
    as ArrayRef[CreateCloudBackupAction()];

coerce 'RepeatedCreateCloudBackupAction',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Executor::V1::CloudExecutor::CreateCloudBackupAction'->new($_) } @$_ ] };

declare 'MapStringCreateCloudBackupAction',
    as HashRef[CreateCloudBackupAction()];

declare 'CopyCloudBackupAction',
    as InstanceOf['Google::Spanner::Executor::V1::CloudExecutor::CopyCloudBackupAction'];

coerce 'CopyCloudBackupAction',
    from HashRef, via { 'Google::Spanner::Executor::V1::CloudExecutor::CopyCloudBackupAction'->new($_) };

declare 'RepeatedCopyCloudBackupAction',
    as ArrayRef[CopyCloudBackupAction()];

coerce 'RepeatedCopyCloudBackupAction',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Executor::V1::CloudExecutor::CopyCloudBackupAction'->new($_) } @$_ ] };

declare 'MapStringCopyCloudBackupAction',
    as HashRef[CopyCloudBackupAction()];

declare 'GetCloudBackupAction',
    as InstanceOf['Google::Spanner::Executor::V1::CloudExecutor::GetCloudBackupAction'];

coerce 'GetCloudBackupAction',
    from HashRef, via { 'Google::Spanner::Executor::V1::CloudExecutor::GetCloudBackupAction'->new($_) };

declare 'RepeatedGetCloudBackupAction',
    as ArrayRef[GetCloudBackupAction()];

coerce 'RepeatedGetCloudBackupAction',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Executor::V1::CloudExecutor::GetCloudBackupAction'->new($_) } @$_ ] };

declare 'MapStringGetCloudBackupAction',
    as HashRef[GetCloudBackupAction()];

declare 'UpdateCloudBackupAction',
    as InstanceOf['Google::Spanner::Executor::V1::CloudExecutor::UpdateCloudBackupAction'];

coerce 'UpdateCloudBackupAction',
    from HashRef, via { 'Google::Spanner::Executor::V1::CloudExecutor::UpdateCloudBackupAction'->new($_) };

declare 'RepeatedUpdateCloudBackupAction',
    as ArrayRef[UpdateCloudBackupAction()];

coerce 'RepeatedUpdateCloudBackupAction',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Executor::V1::CloudExecutor::UpdateCloudBackupAction'->new($_) } @$_ ] };

declare 'MapStringUpdateCloudBackupAction',
    as HashRef[UpdateCloudBackupAction()];

declare 'DeleteCloudBackupAction',
    as InstanceOf['Google::Spanner::Executor::V1::CloudExecutor::DeleteCloudBackupAction'];

coerce 'DeleteCloudBackupAction',
    from HashRef, via { 'Google::Spanner::Executor::V1::CloudExecutor::DeleteCloudBackupAction'->new($_) };

declare 'RepeatedDeleteCloudBackupAction',
    as ArrayRef[DeleteCloudBackupAction()];

coerce 'RepeatedDeleteCloudBackupAction',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Executor::V1::CloudExecutor::DeleteCloudBackupAction'->new($_) } @$_ ] };

declare 'MapStringDeleteCloudBackupAction',
    as HashRef[DeleteCloudBackupAction()];

declare 'ListCloudBackupsAction',
    as InstanceOf['Google::Spanner::Executor::V1::CloudExecutor::ListCloudBackupsAction'];

coerce 'ListCloudBackupsAction',
    from HashRef, via { 'Google::Spanner::Executor::V1::CloudExecutor::ListCloudBackupsAction'->new($_) };

declare 'RepeatedListCloudBackupsAction',
    as ArrayRef[ListCloudBackupsAction()];

coerce 'RepeatedListCloudBackupsAction',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Executor::V1::CloudExecutor::ListCloudBackupsAction'->new($_) } @$_ ] };

declare 'MapStringListCloudBackupsAction',
    as HashRef[ListCloudBackupsAction()];

declare 'ListCloudBackupOperationsAction',
    as InstanceOf['Google::Spanner::Executor::V1::CloudExecutor::ListCloudBackupOperationsAction'];

coerce 'ListCloudBackupOperationsAction',
    from HashRef, via { 'Google::Spanner::Executor::V1::CloudExecutor::ListCloudBackupOperationsAction'->new($_) };

declare 'RepeatedListCloudBackupOperationsAction',
    as ArrayRef[ListCloudBackupOperationsAction()];

coerce 'RepeatedListCloudBackupOperationsAction',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Executor::V1::CloudExecutor::ListCloudBackupOperationsAction'->new($_) } @$_ ] };

declare 'MapStringListCloudBackupOperationsAction',
    as HashRef[ListCloudBackupOperationsAction()];

declare 'GetOperationAction',
    as InstanceOf['Google::Spanner::Executor::V1::CloudExecutor::GetOperationAction'];

coerce 'GetOperationAction',
    from HashRef, via { 'Google::Spanner::Executor::V1::CloudExecutor::GetOperationAction'->new($_) };

declare 'RepeatedGetOperationAction',
    as ArrayRef[GetOperationAction()];

coerce 'RepeatedGetOperationAction',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Executor::V1::CloudExecutor::GetOperationAction'->new($_) } @$_ ] };

declare 'MapStringGetOperationAction',
    as HashRef[GetOperationAction()];

declare 'QueryCancellationAction',
    as InstanceOf['Google::Spanner::Executor::V1::CloudExecutor::QueryCancellationAction'];

coerce 'QueryCancellationAction',
    from HashRef, via { 'Google::Spanner::Executor::V1::CloudExecutor::QueryCancellationAction'->new($_) };

declare 'RepeatedQueryCancellationAction',
    as ArrayRef[QueryCancellationAction()];

coerce 'RepeatedQueryCancellationAction',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Executor::V1::CloudExecutor::QueryCancellationAction'->new($_) } @$_ ] };

declare 'MapStringQueryCancellationAction',
    as HashRef[QueryCancellationAction()];

declare 'CancelOperationAction',
    as InstanceOf['Google::Spanner::Executor::V1::CloudExecutor::CancelOperationAction'];

coerce 'CancelOperationAction',
    from HashRef, via { 'Google::Spanner::Executor::V1::CloudExecutor::CancelOperationAction'->new($_) };

declare 'RepeatedCancelOperationAction',
    as ArrayRef[CancelOperationAction()];

coerce 'RepeatedCancelOperationAction',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Executor::V1::CloudExecutor::CancelOperationAction'->new($_) } @$_ ] };

declare 'MapStringCancelOperationAction',
    as HashRef[CancelOperationAction()];

declare 'AddSplitPointsAction',
    as InstanceOf['Google::Spanner::Executor::V1::CloudExecutor::AddSplitPointsAction'];

coerce 'AddSplitPointsAction',
    from HashRef, via { 'Google::Spanner::Executor::V1::CloudExecutor::AddSplitPointsAction'->new($_) };

declare 'RepeatedAddSplitPointsAction',
    as ArrayRef[AddSplitPointsAction()];

coerce 'RepeatedAddSplitPointsAction',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Executor::V1::CloudExecutor::AddSplitPointsAction'->new($_) } @$_ ] };

declare 'MapStringAddSplitPointsAction',
    as HashRef[AddSplitPointsAction()];

declare 'StartBatchTransactionAction',
    as InstanceOf['Google::Spanner::Executor::V1::CloudExecutor::StartBatchTransactionAction'];

coerce 'StartBatchTransactionAction',
    from HashRef, via { 'Google::Spanner::Executor::V1::CloudExecutor::StartBatchTransactionAction'->new($_) };

declare 'RepeatedStartBatchTransactionAction',
    as ArrayRef[StartBatchTransactionAction()];

coerce 'RepeatedStartBatchTransactionAction',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Executor::V1::CloudExecutor::StartBatchTransactionAction'->new($_) } @$_ ] };

declare 'MapStringStartBatchTransactionAction',
    as HashRef[StartBatchTransactionAction()];

declare 'CloseBatchTransactionAction',
    as InstanceOf['Google::Spanner::Executor::V1::CloudExecutor::CloseBatchTransactionAction'];

coerce 'CloseBatchTransactionAction',
    from HashRef, via { 'Google::Spanner::Executor::V1::CloudExecutor::CloseBatchTransactionAction'->new($_) };

declare 'RepeatedCloseBatchTransactionAction',
    as ArrayRef[CloseBatchTransactionAction()];

coerce 'RepeatedCloseBatchTransactionAction',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Executor::V1::CloudExecutor::CloseBatchTransactionAction'->new($_) } @$_ ] };

declare 'MapStringCloseBatchTransactionAction',
    as HashRef[CloseBatchTransactionAction()];

declare 'GenerateDbPartitionsForReadAction',
    as InstanceOf['Google::Spanner::Executor::V1::CloudExecutor::GenerateDbPartitionsForReadAction'];

coerce 'GenerateDbPartitionsForReadAction',
    from HashRef, via { 'Google::Spanner::Executor::V1::CloudExecutor::GenerateDbPartitionsForReadAction'->new($_) };

declare 'RepeatedGenerateDbPartitionsForReadAction',
    as ArrayRef[GenerateDbPartitionsForReadAction()];

coerce 'RepeatedGenerateDbPartitionsForReadAction',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Executor::V1::CloudExecutor::GenerateDbPartitionsForReadAction'->new($_) } @$_ ] };

declare 'MapStringGenerateDbPartitionsForReadAction',
    as HashRef[GenerateDbPartitionsForReadAction()];

declare 'GenerateDbPartitionsForQueryAction',
    as InstanceOf['Google::Spanner::Executor::V1::CloudExecutor::GenerateDbPartitionsForQueryAction'];

coerce 'GenerateDbPartitionsForQueryAction',
    from HashRef, via { 'Google::Spanner::Executor::V1::CloudExecutor::GenerateDbPartitionsForQueryAction'->new($_) };

declare 'RepeatedGenerateDbPartitionsForQueryAction',
    as ArrayRef[GenerateDbPartitionsForQueryAction()];

coerce 'RepeatedGenerateDbPartitionsForQueryAction',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Executor::V1::CloudExecutor::GenerateDbPartitionsForQueryAction'->new($_) } @$_ ] };

declare 'MapStringGenerateDbPartitionsForQueryAction',
    as HashRef[GenerateDbPartitionsForQueryAction()];

declare 'BatchPartition',
    as InstanceOf['Google::Spanner::Executor::V1::CloudExecutor::BatchPartition'];

coerce 'BatchPartition',
    from HashRef, via { 'Google::Spanner::Executor::V1::CloudExecutor::BatchPartition'->new($_) };

declare 'RepeatedBatchPartition',
    as ArrayRef[BatchPartition()];

coerce 'RepeatedBatchPartition',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Executor::V1::CloudExecutor::BatchPartition'->new($_) } @$_ ] };

declare 'MapStringBatchPartition',
    as HashRef[BatchPartition()];

declare 'ExecutePartitionAction',
    as InstanceOf['Google::Spanner::Executor::V1::CloudExecutor::ExecutePartitionAction'];

coerce 'ExecutePartitionAction',
    from HashRef, via { 'Google::Spanner::Executor::V1::CloudExecutor::ExecutePartitionAction'->new($_) };

declare 'RepeatedExecutePartitionAction',
    as ArrayRef[ExecutePartitionAction()];

coerce 'RepeatedExecutePartitionAction',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Executor::V1::CloudExecutor::ExecutePartitionAction'->new($_) } @$_ ] };

declare 'MapStringExecutePartitionAction',
    as HashRef[ExecutePartitionAction()];

declare 'SecureContextEntry',
    as InstanceOf['Google::Spanner::Executor::V1::CloudExecutor::ExecutePartitionAction::SecureContextEntry'];

coerce 'SecureContextEntry',
    from HashRef, via { 'Google::Spanner::Executor::V1::CloudExecutor::ExecutePartitionAction::SecureContextEntry'->new($_) };

declare 'RepeatedSecureContextEntry',
    as ArrayRef[SecureContextEntry()];

coerce 'RepeatedSecureContextEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Executor::V1::CloudExecutor::ExecutePartitionAction::SecureContextEntry'->new($_) } @$_ ] };

declare 'MapStringSecureContextEntry',
    as HashRef[SecureContextEntry()];

declare 'ExecuteChangeStreamQuery',
    as InstanceOf['Google::Spanner::Executor::V1::CloudExecutor::ExecuteChangeStreamQuery'];

coerce 'ExecuteChangeStreamQuery',
    from HashRef, via { 'Google::Spanner::Executor::V1::CloudExecutor::ExecuteChangeStreamQuery'->new($_) };

declare 'RepeatedExecuteChangeStreamQuery',
    as ArrayRef[ExecuteChangeStreamQuery()];

coerce 'RepeatedExecuteChangeStreamQuery',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Executor::V1::CloudExecutor::ExecuteChangeStreamQuery'->new($_) } @$_ ] };

declare 'MapStringExecuteChangeStreamQuery',
    as HashRef[ExecuteChangeStreamQuery()];

declare 'SpannerActionOutcome',
    as InstanceOf['Google::Spanner::Executor::V1::CloudExecutor::SpannerActionOutcome'];

coerce 'SpannerActionOutcome',
    from HashRef, via { 'Google::Spanner::Executor::V1::CloudExecutor::SpannerActionOutcome'->new($_) };

declare 'RepeatedSpannerActionOutcome',
    as ArrayRef[SpannerActionOutcome()];

coerce 'RepeatedSpannerActionOutcome',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Executor::V1::CloudExecutor::SpannerActionOutcome'->new($_) } @$_ ] };

declare 'MapStringSpannerActionOutcome',
    as HashRef[SpannerActionOutcome()];

declare 'AdminResult',
    as InstanceOf['Google::Spanner::Executor::V1::CloudExecutor::AdminResult'];

coerce 'AdminResult',
    from HashRef, via { 'Google::Spanner::Executor::V1::CloudExecutor::AdminResult'->new($_) };

declare 'RepeatedAdminResult',
    as ArrayRef[AdminResult()];

coerce 'RepeatedAdminResult',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Executor::V1::CloudExecutor::AdminResult'->new($_) } @$_ ] };

declare 'MapStringAdminResult',
    as HashRef[AdminResult()];

declare 'CloudBackupResponse',
    as InstanceOf['Google::Spanner::Executor::V1::CloudExecutor::CloudBackupResponse'];

coerce 'CloudBackupResponse',
    from HashRef, via { 'Google::Spanner::Executor::V1::CloudExecutor::CloudBackupResponse'->new($_) };

declare 'RepeatedCloudBackupResponse',
    as ArrayRef[CloudBackupResponse()];

coerce 'RepeatedCloudBackupResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Executor::V1::CloudExecutor::CloudBackupResponse'->new($_) } @$_ ] };

declare 'MapStringCloudBackupResponse',
    as HashRef[CloudBackupResponse()];

declare 'OperationResponse',
    as InstanceOf['Google::Spanner::Executor::V1::CloudExecutor::OperationResponse'];

coerce 'OperationResponse',
    from HashRef, via { 'Google::Spanner::Executor::V1::CloudExecutor::OperationResponse'->new($_) };

declare 'RepeatedOperationResponse',
    as ArrayRef[OperationResponse()];

coerce 'RepeatedOperationResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Executor::V1::CloudExecutor::OperationResponse'->new($_) } @$_ ] };

declare 'MapStringOperationResponse',
    as HashRef[OperationResponse()];

declare 'CloudInstanceResponse',
    as InstanceOf['Google::Spanner::Executor::V1::CloudExecutor::CloudInstanceResponse'];

coerce 'CloudInstanceResponse',
    from HashRef, via { 'Google::Spanner::Executor::V1::CloudExecutor::CloudInstanceResponse'->new($_) };

declare 'RepeatedCloudInstanceResponse',
    as ArrayRef[CloudInstanceResponse()];

coerce 'RepeatedCloudInstanceResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Executor::V1::CloudExecutor::CloudInstanceResponse'->new($_) } @$_ ] };

declare 'MapStringCloudInstanceResponse',
    as HashRef[CloudInstanceResponse()];

declare 'CloudInstanceConfigResponse',
    as InstanceOf['Google::Spanner::Executor::V1::CloudExecutor::CloudInstanceConfigResponse'];

coerce 'CloudInstanceConfigResponse',
    from HashRef, via { 'Google::Spanner::Executor::V1::CloudExecutor::CloudInstanceConfigResponse'->new($_) };

declare 'RepeatedCloudInstanceConfigResponse',
    as ArrayRef[CloudInstanceConfigResponse()];

coerce 'RepeatedCloudInstanceConfigResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Executor::V1::CloudExecutor::CloudInstanceConfigResponse'->new($_) } @$_ ] };

declare 'MapStringCloudInstanceConfigResponse',
    as HashRef[CloudInstanceConfigResponse()];

declare 'CloudDatabaseResponse',
    as InstanceOf['Google::Spanner::Executor::V1::CloudExecutor::CloudDatabaseResponse'];

coerce 'CloudDatabaseResponse',
    from HashRef, via { 'Google::Spanner::Executor::V1::CloudExecutor::CloudDatabaseResponse'->new($_) };

declare 'RepeatedCloudDatabaseResponse',
    as ArrayRef[CloudDatabaseResponse()];

coerce 'RepeatedCloudDatabaseResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Executor::V1::CloudExecutor::CloudDatabaseResponse'->new($_) } @$_ ] };

declare 'MapStringCloudDatabaseResponse',
    as HashRef[CloudDatabaseResponse()];

declare 'ReadResult',
    as InstanceOf['Google::Spanner::Executor::V1::CloudExecutor::ReadResult'];

coerce 'ReadResult',
    from HashRef, via { 'Google::Spanner::Executor::V1::CloudExecutor::ReadResult'->new($_) };

declare 'RepeatedReadResult',
    as ArrayRef[ReadResult()];

coerce 'RepeatedReadResult',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Executor::V1::CloudExecutor::ReadResult'->new($_) } @$_ ] };

declare 'MapStringReadResult',
    as HashRef[ReadResult()];

declare 'QueryResult',
    as InstanceOf['Google::Spanner::Executor::V1::CloudExecutor::QueryResult'];

coerce 'QueryResult',
    from HashRef, via { 'Google::Spanner::Executor::V1::CloudExecutor::QueryResult'->new($_) };

declare 'RepeatedQueryResult',
    as ArrayRef[QueryResult()];

coerce 'RepeatedQueryResult',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Executor::V1::CloudExecutor::QueryResult'->new($_) } @$_ ] };

declare 'MapStringQueryResult',
    as HashRef[QueryResult()];

declare 'ChangeStreamRecord',
    as InstanceOf['Google::Spanner::Executor::V1::CloudExecutor::ChangeStreamRecord'];

coerce 'ChangeStreamRecord',
    from HashRef, via { 'Google::Spanner::Executor::V1::CloudExecutor::ChangeStreamRecord'->new($_) };

declare 'RepeatedChangeStreamRecord',
    as ArrayRef[ChangeStreamRecord()];

coerce 'RepeatedChangeStreamRecord',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Executor::V1::CloudExecutor::ChangeStreamRecord'->new($_) } @$_ ] };

declare 'MapStringChangeStreamRecord',
    as HashRef[ChangeStreamRecord()];

declare 'DataChangeRecord',
    as InstanceOf['Google::Spanner::Executor::V1::CloudExecutor::DataChangeRecord'];

coerce 'DataChangeRecord',
    from HashRef, via { 'Google::Spanner::Executor::V1::CloudExecutor::DataChangeRecord'->new($_) };

declare 'RepeatedDataChangeRecord',
    as ArrayRef[DataChangeRecord()];

coerce 'RepeatedDataChangeRecord',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Executor::V1::CloudExecutor::DataChangeRecord'->new($_) } @$_ ] };

declare 'MapStringDataChangeRecord',
    as HashRef[DataChangeRecord()];

declare 'ColumnType',
    as InstanceOf['Google::Spanner::Executor::V1::CloudExecutor::DataChangeRecord::ColumnType'];

coerce 'ColumnType',
    from HashRef, via { 'Google::Spanner::Executor::V1::CloudExecutor::DataChangeRecord::ColumnType'->new($_) };

declare 'RepeatedColumnType',
    as ArrayRef[ColumnType()];

coerce 'RepeatedColumnType',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Executor::V1::CloudExecutor::DataChangeRecord::ColumnType'->new($_) } @$_ ] };

declare 'MapStringColumnType',
    as HashRef[ColumnType()];

declare 'Mod',
    as InstanceOf['Google::Spanner::Executor::V1::CloudExecutor::DataChangeRecord::Mod'];

coerce 'Mod',
    from HashRef, via { 'Google::Spanner::Executor::V1::CloudExecutor::DataChangeRecord::Mod'->new($_) };

declare 'RepeatedMod',
    as ArrayRef[Mod()];

coerce 'RepeatedMod',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Executor::V1::CloudExecutor::DataChangeRecord::Mod'->new($_) } @$_ ] };

declare 'MapStringMod',
    as HashRef[Mod()];

declare 'ChildPartitionsRecord',
    as InstanceOf['Google::Spanner::Executor::V1::CloudExecutor::ChildPartitionsRecord'];

coerce 'ChildPartitionsRecord',
    from HashRef, via { 'Google::Spanner::Executor::V1::CloudExecutor::ChildPartitionsRecord'->new($_) };

declare 'RepeatedChildPartitionsRecord',
    as ArrayRef[ChildPartitionsRecord()];

coerce 'RepeatedChildPartitionsRecord',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Executor::V1::CloudExecutor::ChildPartitionsRecord'->new($_) } @$_ ] };

declare 'MapStringChildPartitionsRecord',
    as HashRef[ChildPartitionsRecord()];

declare 'ChildPartition',
    as InstanceOf['Google::Spanner::Executor::V1::CloudExecutor::ChildPartitionsRecord::ChildPartition'];

coerce 'ChildPartition',
    from HashRef, via { 'Google::Spanner::Executor::V1::CloudExecutor::ChildPartitionsRecord::ChildPartition'->new($_) };

declare 'RepeatedChildPartition',
    as ArrayRef[ChildPartition()];

coerce 'RepeatedChildPartition',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Executor::V1::CloudExecutor::ChildPartitionsRecord::ChildPartition'->new($_) } @$_ ] };

declare 'MapStringChildPartition',
    as HashRef[ChildPartition()];

declare 'HeartbeatRecord',
    as InstanceOf['Google::Spanner::Executor::V1::CloudExecutor::HeartbeatRecord'];

coerce 'HeartbeatRecord',
    from HashRef, via { 'Google::Spanner::Executor::V1::CloudExecutor::HeartbeatRecord'->new($_) };

declare 'RepeatedHeartbeatRecord',
    as ArrayRef[HeartbeatRecord()];

coerce 'RepeatedHeartbeatRecord',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Executor::V1::CloudExecutor::HeartbeatRecord'->new($_) } @$_ ] };

declare 'MapStringHeartbeatRecord',
    as HashRef[HeartbeatRecord()];

declare 'SpannerOptions',
    as InstanceOf['Google::Spanner::Executor::V1::CloudExecutor::SpannerOptions'];

coerce 'SpannerOptions',
    from HashRef, via { 'Google::Spanner::Executor::V1::CloudExecutor::SpannerOptions'->new($_) };

declare 'RepeatedSpannerOptions',
    as ArrayRef[SpannerOptions()];

coerce 'RepeatedSpannerOptions',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Executor::V1::CloudExecutor::SpannerOptions'->new($_) } @$_ ] };

declare 'MapStringSpannerOptions',
    as HashRef[SpannerOptions()];

declare 'SessionPoolOptions',
    as InstanceOf['Google::Spanner::Executor::V1::CloudExecutor::SessionPoolOptions'];

coerce 'SessionPoolOptions',
    from HashRef, via { 'Google::Spanner::Executor::V1::CloudExecutor::SessionPoolOptions'->new($_) };

declare 'RepeatedSessionPoolOptions',
    as ArrayRef[SessionPoolOptions()];

coerce 'RepeatedSessionPoolOptions',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Executor::V1::CloudExecutor::SessionPoolOptions'->new($_) } @$_ ] };

declare 'MapStringSessionPoolOptions',
    as HashRef[SessionPoolOptions()];

1;

__END__

=head1 NAME

Google::Spanner::Executor::V1::CloudExecutor::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
