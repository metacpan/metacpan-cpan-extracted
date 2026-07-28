package Google::Spanner::V1::Spanner::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'CreateSessionRequest',
    as InstanceOf['Google::Spanner::V1::Spanner::CreateSessionRequest'];

coerce 'CreateSessionRequest',
    from HashRef, via { 'Google::Spanner::V1::Spanner::CreateSessionRequest'->new($_) };

declare 'RepeatedCreateSessionRequest',
    as ArrayRef[CreateSessionRequest()];

coerce 'RepeatedCreateSessionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::V1::Spanner::CreateSessionRequest'->new($_) } @$_ ] };

declare 'MapStringCreateSessionRequest',
    as HashRef[CreateSessionRequest()];

declare 'BatchCreateSessionsRequest',
    as InstanceOf['Google::Spanner::V1::Spanner::BatchCreateSessionsRequest'];

coerce 'BatchCreateSessionsRequest',
    from HashRef, via { 'Google::Spanner::V1::Spanner::BatchCreateSessionsRequest'->new($_) };

declare 'RepeatedBatchCreateSessionsRequest',
    as ArrayRef[BatchCreateSessionsRequest()];

coerce 'RepeatedBatchCreateSessionsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::V1::Spanner::BatchCreateSessionsRequest'->new($_) } @$_ ] };

declare 'MapStringBatchCreateSessionsRequest',
    as HashRef[BatchCreateSessionsRequest()];

declare 'BatchCreateSessionsResponse',
    as InstanceOf['Google::Spanner::V1::Spanner::BatchCreateSessionsResponse'];

coerce 'BatchCreateSessionsResponse',
    from HashRef, via { 'Google::Spanner::V1::Spanner::BatchCreateSessionsResponse'->new($_) };

declare 'RepeatedBatchCreateSessionsResponse',
    as ArrayRef[BatchCreateSessionsResponse()];

coerce 'RepeatedBatchCreateSessionsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::V1::Spanner::BatchCreateSessionsResponse'->new($_) } @$_ ] };

declare 'MapStringBatchCreateSessionsResponse',
    as HashRef[BatchCreateSessionsResponse()];

declare 'Session',
    as InstanceOf['Google::Spanner::V1::Spanner::Session'];

coerce 'Session',
    from HashRef, via { 'Google::Spanner::V1::Spanner::Session'->new($_) };

declare 'RepeatedSession',
    as ArrayRef[Session()];

coerce 'RepeatedSession',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::V1::Spanner::Session'->new($_) } @$_ ] };

declare 'MapStringSession',
    as HashRef[Session()];

declare 'LabelsEntry',
    as InstanceOf['Google::Spanner::V1::Spanner::Session::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Spanner::V1::Spanner::Session::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::V1::Spanner::Session::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'GetSessionRequest',
    as InstanceOf['Google::Spanner::V1::Spanner::GetSessionRequest'];

coerce 'GetSessionRequest',
    from HashRef, via { 'Google::Spanner::V1::Spanner::GetSessionRequest'->new($_) };

declare 'RepeatedGetSessionRequest',
    as ArrayRef[GetSessionRequest()];

coerce 'RepeatedGetSessionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::V1::Spanner::GetSessionRequest'->new($_) } @$_ ] };

declare 'MapStringGetSessionRequest',
    as HashRef[GetSessionRequest()];

declare 'ListSessionsRequest',
    as InstanceOf['Google::Spanner::V1::Spanner::ListSessionsRequest'];

coerce 'ListSessionsRequest',
    from HashRef, via { 'Google::Spanner::V1::Spanner::ListSessionsRequest'->new($_) };

declare 'RepeatedListSessionsRequest',
    as ArrayRef[ListSessionsRequest()];

coerce 'RepeatedListSessionsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::V1::Spanner::ListSessionsRequest'->new($_) } @$_ ] };

declare 'MapStringListSessionsRequest',
    as HashRef[ListSessionsRequest()];

declare 'ListSessionsResponse',
    as InstanceOf['Google::Spanner::V1::Spanner::ListSessionsResponse'];

coerce 'ListSessionsResponse',
    from HashRef, via { 'Google::Spanner::V1::Spanner::ListSessionsResponse'->new($_) };

declare 'RepeatedListSessionsResponse',
    as ArrayRef[ListSessionsResponse()];

coerce 'RepeatedListSessionsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::V1::Spanner::ListSessionsResponse'->new($_) } @$_ ] };

declare 'MapStringListSessionsResponse',
    as HashRef[ListSessionsResponse()];

declare 'DeleteSessionRequest',
    as InstanceOf['Google::Spanner::V1::Spanner::DeleteSessionRequest'];

coerce 'DeleteSessionRequest',
    from HashRef, via { 'Google::Spanner::V1::Spanner::DeleteSessionRequest'->new($_) };

declare 'RepeatedDeleteSessionRequest',
    as ArrayRef[DeleteSessionRequest()];

coerce 'RepeatedDeleteSessionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::V1::Spanner::DeleteSessionRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteSessionRequest',
    as HashRef[DeleteSessionRequest()];

declare 'RequestOptions',
    as InstanceOf['Google::Spanner::V1::Spanner::RequestOptions'];

coerce 'RequestOptions',
    from HashRef, via { 'Google::Spanner::V1::Spanner::RequestOptions'->new($_) };

declare 'RepeatedRequestOptions',
    as ArrayRef[RequestOptions()];

coerce 'RepeatedRequestOptions',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::V1::Spanner::RequestOptions'->new($_) } @$_ ] };

declare 'MapStringRequestOptions',
    as HashRef[RequestOptions()];

declare 'Priority',
    as (Int | Str);

declare 'ClientContext',
    as InstanceOf['Google::Spanner::V1::Spanner::RequestOptions::ClientContext'];

coerce 'ClientContext',
    from HashRef, via { 'Google::Spanner::V1::Spanner::RequestOptions::ClientContext'->new($_) };

declare 'RepeatedClientContext',
    as ArrayRef[ClientContext()];

coerce 'RepeatedClientContext',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::V1::Spanner::RequestOptions::ClientContext'->new($_) } @$_ ] };

declare 'MapStringClientContext',
    as HashRef[ClientContext()];

declare 'SecureContextEntry',
    as InstanceOf['Google::Spanner::V1::Spanner::RequestOptions::ClientContext::SecureContextEntry'];

coerce 'SecureContextEntry',
    from HashRef, via { 'Google::Spanner::V1::Spanner::RequestOptions::ClientContext::SecureContextEntry'->new($_) };

declare 'RepeatedSecureContextEntry',
    as ArrayRef[SecureContextEntry()];

coerce 'RepeatedSecureContextEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::V1::Spanner::RequestOptions::ClientContext::SecureContextEntry'->new($_) } @$_ ] };

declare 'MapStringSecureContextEntry',
    as HashRef[SecureContextEntry()];

declare 'DirectedReadOptions',
    as InstanceOf['Google::Spanner::V1::Spanner::DirectedReadOptions'];

coerce 'DirectedReadOptions',
    from HashRef, via { 'Google::Spanner::V1::Spanner::DirectedReadOptions'->new($_) };

declare 'RepeatedDirectedReadOptions',
    as ArrayRef[DirectedReadOptions()];

coerce 'RepeatedDirectedReadOptions',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::V1::Spanner::DirectedReadOptions'->new($_) } @$_ ] };

declare 'MapStringDirectedReadOptions',
    as HashRef[DirectedReadOptions()];

declare 'ReplicaSelection',
    as InstanceOf['Google::Spanner::V1::Spanner::DirectedReadOptions::ReplicaSelection'];

coerce 'ReplicaSelection',
    from HashRef, via { 'Google::Spanner::V1::Spanner::DirectedReadOptions::ReplicaSelection'->new($_) };

declare 'RepeatedReplicaSelection',
    as ArrayRef[ReplicaSelection()];

coerce 'RepeatedReplicaSelection',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::V1::Spanner::DirectedReadOptions::ReplicaSelection'->new($_) } @$_ ] };

declare 'MapStringReplicaSelection',
    as HashRef[ReplicaSelection()];

declare 'Type',
    as (Int | Str);

declare 'IncludeReplicas',
    as InstanceOf['Google::Spanner::V1::Spanner::DirectedReadOptions::IncludeReplicas'];

coerce 'IncludeReplicas',
    from HashRef, via { 'Google::Spanner::V1::Spanner::DirectedReadOptions::IncludeReplicas'->new($_) };

declare 'RepeatedIncludeReplicas',
    as ArrayRef[IncludeReplicas()];

coerce 'RepeatedIncludeReplicas',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::V1::Spanner::DirectedReadOptions::IncludeReplicas'->new($_) } @$_ ] };

declare 'MapStringIncludeReplicas',
    as HashRef[IncludeReplicas()];

declare 'ExcludeReplicas',
    as InstanceOf['Google::Spanner::V1::Spanner::DirectedReadOptions::ExcludeReplicas'];

coerce 'ExcludeReplicas',
    from HashRef, via { 'Google::Spanner::V1::Spanner::DirectedReadOptions::ExcludeReplicas'->new($_) };

declare 'RepeatedExcludeReplicas',
    as ArrayRef[ExcludeReplicas()];

coerce 'RepeatedExcludeReplicas',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::V1::Spanner::DirectedReadOptions::ExcludeReplicas'->new($_) } @$_ ] };

declare 'MapStringExcludeReplicas',
    as HashRef[ExcludeReplicas()];

declare 'ExecuteSqlRequest',
    as InstanceOf['Google::Spanner::V1::Spanner::ExecuteSqlRequest'];

coerce 'ExecuteSqlRequest',
    from HashRef, via { 'Google::Spanner::V1::Spanner::ExecuteSqlRequest'->new($_) };

declare 'RepeatedExecuteSqlRequest',
    as ArrayRef[ExecuteSqlRequest()];

coerce 'RepeatedExecuteSqlRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::V1::Spanner::ExecuteSqlRequest'->new($_) } @$_ ] };

declare 'MapStringExecuteSqlRequest',
    as HashRef[ExecuteSqlRequest()];

declare 'QueryMode',
    as (Int | Str);

declare 'QueryOptions',
    as InstanceOf['Google::Spanner::V1::Spanner::ExecuteSqlRequest::QueryOptions'];

coerce 'QueryOptions',
    from HashRef, via { 'Google::Spanner::V1::Spanner::ExecuteSqlRequest::QueryOptions'->new($_) };

declare 'RepeatedQueryOptions',
    as ArrayRef[QueryOptions()];

coerce 'RepeatedQueryOptions',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::V1::Spanner::ExecuteSqlRequest::QueryOptions'->new($_) } @$_ ] };

declare 'MapStringQueryOptions',
    as HashRef[QueryOptions()];

declare 'ParamTypesEntry',
    as InstanceOf['Google::Spanner::V1::Spanner::ExecuteSqlRequest::ParamTypesEntry'];

coerce 'ParamTypesEntry',
    from HashRef, via { 'Google::Spanner::V1::Spanner::ExecuteSqlRequest::ParamTypesEntry'->new($_) };

declare 'RepeatedParamTypesEntry',
    as ArrayRef[ParamTypesEntry()];

coerce 'RepeatedParamTypesEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::V1::Spanner::ExecuteSqlRequest::ParamTypesEntry'->new($_) } @$_ ] };

declare 'MapStringParamTypesEntry',
    as HashRef[ParamTypesEntry()];

declare 'ExecuteBatchDmlRequest',
    as InstanceOf['Google::Spanner::V1::Spanner::ExecuteBatchDmlRequest'];

coerce 'ExecuteBatchDmlRequest',
    from HashRef, via { 'Google::Spanner::V1::Spanner::ExecuteBatchDmlRequest'->new($_) };

declare 'RepeatedExecuteBatchDmlRequest',
    as ArrayRef[ExecuteBatchDmlRequest()];

coerce 'RepeatedExecuteBatchDmlRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::V1::Spanner::ExecuteBatchDmlRequest'->new($_) } @$_ ] };

declare 'MapStringExecuteBatchDmlRequest',
    as HashRef[ExecuteBatchDmlRequest()];

declare 'Statement',
    as InstanceOf['Google::Spanner::V1::Spanner::ExecuteBatchDmlRequest::Statement'];

coerce 'Statement',
    from HashRef, via { 'Google::Spanner::V1::Spanner::ExecuteBatchDmlRequest::Statement'->new($_) };

declare 'RepeatedStatement',
    as ArrayRef[Statement()];

coerce 'RepeatedStatement',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::V1::Spanner::ExecuteBatchDmlRequest::Statement'->new($_) } @$_ ] };

declare 'MapStringStatement',
    as HashRef[Statement()];

declare 'ParamTypesEntry',
    as InstanceOf['Google::Spanner::V1::Spanner::ExecuteBatchDmlRequest::Statement::ParamTypesEntry'];

coerce 'ParamTypesEntry',
    from HashRef, via { 'Google::Spanner::V1::Spanner::ExecuteBatchDmlRequest::Statement::ParamTypesEntry'->new($_) };

declare 'RepeatedParamTypesEntry',
    as ArrayRef[ParamTypesEntry()];

coerce 'RepeatedParamTypesEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::V1::Spanner::ExecuteBatchDmlRequest::Statement::ParamTypesEntry'->new($_) } @$_ ] };

declare 'MapStringParamTypesEntry',
    as HashRef[ParamTypesEntry()];

declare 'ExecuteBatchDmlResponse',
    as InstanceOf['Google::Spanner::V1::Spanner::ExecuteBatchDmlResponse'];

coerce 'ExecuteBatchDmlResponse',
    from HashRef, via { 'Google::Spanner::V1::Spanner::ExecuteBatchDmlResponse'->new($_) };

declare 'RepeatedExecuteBatchDmlResponse',
    as ArrayRef[ExecuteBatchDmlResponse()];

coerce 'RepeatedExecuteBatchDmlResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::V1::Spanner::ExecuteBatchDmlResponse'->new($_) } @$_ ] };

declare 'MapStringExecuteBatchDmlResponse',
    as HashRef[ExecuteBatchDmlResponse()];

declare 'PartitionOptions',
    as InstanceOf['Google::Spanner::V1::Spanner::PartitionOptions'];

coerce 'PartitionOptions',
    from HashRef, via { 'Google::Spanner::V1::Spanner::PartitionOptions'->new($_) };

declare 'RepeatedPartitionOptions',
    as ArrayRef[PartitionOptions()];

coerce 'RepeatedPartitionOptions',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::V1::Spanner::PartitionOptions'->new($_) } @$_ ] };

declare 'MapStringPartitionOptions',
    as HashRef[PartitionOptions()];

declare 'PartitionQueryRequest',
    as InstanceOf['Google::Spanner::V1::Spanner::PartitionQueryRequest'];

coerce 'PartitionQueryRequest',
    from HashRef, via { 'Google::Spanner::V1::Spanner::PartitionQueryRequest'->new($_) };

declare 'RepeatedPartitionQueryRequest',
    as ArrayRef[PartitionQueryRequest()];

coerce 'RepeatedPartitionQueryRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::V1::Spanner::PartitionQueryRequest'->new($_) } @$_ ] };

declare 'MapStringPartitionQueryRequest',
    as HashRef[PartitionQueryRequest()];

declare 'ParamTypesEntry',
    as InstanceOf['Google::Spanner::V1::Spanner::PartitionQueryRequest::ParamTypesEntry'];

coerce 'ParamTypesEntry',
    from HashRef, via { 'Google::Spanner::V1::Spanner::PartitionQueryRequest::ParamTypesEntry'->new($_) };

declare 'RepeatedParamTypesEntry',
    as ArrayRef[ParamTypesEntry()];

coerce 'RepeatedParamTypesEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::V1::Spanner::PartitionQueryRequest::ParamTypesEntry'->new($_) } @$_ ] };

declare 'MapStringParamTypesEntry',
    as HashRef[ParamTypesEntry()];

declare 'PartitionReadRequest',
    as InstanceOf['Google::Spanner::V1::Spanner::PartitionReadRequest'];

coerce 'PartitionReadRequest',
    from HashRef, via { 'Google::Spanner::V1::Spanner::PartitionReadRequest'->new($_) };

declare 'RepeatedPartitionReadRequest',
    as ArrayRef[PartitionReadRequest()];

coerce 'RepeatedPartitionReadRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::V1::Spanner::PartitionReadRequest'->new($_) } @$_ ] };

declare 'MapStringPartitionReadRequest',
    as HashRef[PartitionReadRequest()];

declare 'Partition',
    as InstanceOf['Google::Spanner::V1::Spanner::Partition'];

coerce 'Partition',
    from HashRef, via { 'Google::Spanner::V1::Spanner::Partition'->new($_) };

declare 'RepeatedPartition',
    as ArrayRef[Partition()];

coerce 'RepeatedPartition',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::V1::Spanner::Partition'->new($_) } @$_ ] };

declare 'MapStringPartition',
    as HashRef[Partition()];

declare 'PartitionResponse',
    as InstanceOf['Google::Spanner::V1::Spanner::PartitionResponse'];

coerce 'PartitionResponse',
    from HashRef, via { 'Google::Spanner::V1::Spanner::PartitionResponse'->new($_) };

declare 'RepeatedPartitionResponse',
    as ArrayRef[PartitionResponse()];

coerce 'RepeatedPartitionResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::V1::Spanner::PartitionResponse'->new($_) } @$_ ] };

declare 'MapStringPartitionResponse',
    as HashRef[PartitionResponse()];

declare 'ReadRequest',
    as InstanceOf['Google::Spanner::V1::Spanner::ReadRequest'];

coerce 'ReadRequest',
    from HashRef, via { 'Google::Spanner::V1::Spanner::ReadRequest'->new($_) };

declare 'RepeatedReadRequest',
    as ArrayRef[ReadRequest()];

coerce 'RepeatedReadRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::V1::Spanner::ReadRequest'->new($_) } @$_ ] };

declare 'MapStringReadRequest',
    as HashRef[ReadRequest()];

declare 'OrderBy',
    as (Int | Str);

declare 'LockHint',
    as (Int | Str);

declare 'BeginTransactionRequest',
    as InstanceOf['Google::Spanner::V1::Spanner::BeginTransactionRequest'];

coerce 'BeginTransactionRequest',
    from HashRef, via { 'Google::Spanner::V1::Spanner::BeginTransactionRequest'->new($_) };

declare 'RepeatedBeginTransactionRequest',
    as ArrayRef[BeginTransactionRequest()];

coerce 'RepeatedBeginTransactionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::V1::Spanner::BeginTransactionRequest'->new($_) } @$_ ] };

declare 'MapStringBeginTransactionRequest',
    as HashRef[BeginTransactionRequest()];

declare 'CommitRequest',
    as InstanceOf['Google::Spanner::V1::Spanner::CommitRequest'];

coerce 'CommitRequest',
    from HashRef, via { 'Google::Spanner::V1::Spanner::CommitRequest'->new($_) };

declare 'RepeatedCommitRequest',
    as ArrayRef[CommitRequest()];

coerce 'RepeatedCommitRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::V1::Spanner::CommitRequest'->new($_) } @$_ ] };

declare 'MapStringCommitRequest',
    as HashRef[CommitRequest()];

declare 'RollbackRequest',
    as InstanceOf['Google::Spanner::V1::Spanner::RollbackRequest'];

coerce 'RollbackRequest',
    from HashRef, via { 'Google::Spanner::V1::Spanner::RollbackRequest'->new($_) };

declare 'RepeatedRollbackRequest',
    as ArrayRef[RollbackRequest()];

coerce 'RepeatedRollbackRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::V1::Spanner::RollbackRequest'->new($_) } @$_ ] };

declare 'MapStringRollbackRequest',
    as HashRef[RollbackRequest()];

declare 'BatchWriteRequest',
    as InstanceOf['Google::Spanner::V1::Spanner::BatchWriteRequest'];

coerce 'BatchWriteRequest',
    from HashRef, via { 'Google::Spanner::V1::Spanner::BatchWriteRequest'->new($_) };

declare 'RepeatedBatchWriteRequest',
    as ArrayRef[BatchWriteRequest()];

coerce 'RepeatedBatchWriteRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::V1::Spanner::BatchWriteRequest'->new($_) } @$_ ] };

declare 'MapStringBatchWriteRequest',
    as HashRef[BatchWriteRequest()];

declare 'MutationGroup',
    as InstanceOf['Google::Spanner::V1::Spanner::BatchWriteRequest::MutationGroup'];

coerce 'MutationGroup',
    from HashRef, via { 'Google::Spanner::V1::Spanner::BatchWriteRequest::MutationGroup'->new($_) };

declare 'RepeatedMutationGroup',
    as ArrayRef[MutationGroup()];

coerce 'RepeatedMutationGroup',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::V1::Spanner::BatchWriteRequest::MutationGroup'->new($_) } @$_ ] };

declare 'MapStringMutationGroup',
    as HashRef[MutationGroup()];

declare 'BatchWriteResponse',
    as InstanceOf['Google::Spanner::V1::Spanner::BatchWriteResponse'];

coerce 'BatchWriteResponse',
    from HashRef, via { 'Google::Spanner::V1::Spanner::BatchWriteResponse'->new($_) };

declare 'RepeatedBatchWriteResponse',
    as ArrayRef[BatchWriteResponse()];

coerce 'RepeatedBatchWriteResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::V1::Spanner::BatchWriteResponse'->new($_) } @$_ ] };

declare 'MapStringBatchWriteResponse',
    as HashRef[BatchWriteResponse()];

declare 'FetchCacheUpdateRequest',
    as InstanceOf['Google::Spanner::V1::Spanner::FetchCacheUpdateRequest'];

coerce 'FetchCacheUpdateRequest',
    from HashRef, via { 'Google::Spanner::V1::Spanner::FetchCacheUpdateRequest'->new($_) };

declare 'RepeatedFetchCacheUpdateRequest',
    as ArrayRef[FetchCacheUpdateRequest()];

coerce 'RepeatedFetchCacheUpdateRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::V1::Spanner::FetchCacheUpdateRequest'->new($_) } @$_ ] };

declare 'MapStringFetchCacheUpdateRequest',
    as HashRef[FetchCacheUpdateRequest()];

1;

__END__

=head1 NAME

Google::Spanner::V1::Spanner::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
