package Google::Datastore::V1::Datastore::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'LookupRequest',
    as InstanceOf['Google::Datastore::V1::Datastore::LookupRequest'];

coerce 'LookupRequest',
    from HashRef, via { 'Google::Datastore::V1::Datastore::LookupRequest'->new($_) };

declare 'RepeatedLookupRequest',
    as ArrayRef[LookupRequest()];

coerce 'RepeatedLookupRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Datastore::V1::Datastore::LookupRequest'->new($_) } @$_ ] };

declare 'MapStringLookupRequest',
    as HashRef[LookupRequest()];

declare 'LookupResponse',
    as InstanceOf['Google::Datastore::V1::Datastore::LookupResponse'];

coerce 'LookupResponse',
    from HashRef, via { 'Google::Datastore::V1::Datastore::LookupResponse'->new($_) };

declare 'RepeatedLookupResponse',
    as ArrayRef[LookupResponse()];

coerce 'RepeatedLookupResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Datastore::V1::Datastore::LookupResponse'->new($_) } @$_ ] };

declare 'MapStringLookupResponse',
    as HashRef[LookupResponse()];

declare 'RunQueryRequest',
    as InstanceOf['Google::Datastore::V1::Datastore::RunQueryRequest'];

coerce 'RunQueryRequest',
    from HashRef, via { 'Google::Datastore::V1::Datastore::RunQueryRequest'->new($_) };

declare 'RepeatedRunQueryRequest',
    as ArrayRef[RunQueryRequest()];

coerce 'RepeatedRunQueryRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Datastore::V1::Datastore::RunQueryRequest'->new($_) } @$_ ] };

declare 'MapStringRunQueryRequest',
    as HashRef[RunQueryRequest()];

declare 'RunQueryResponse',
    as InstanceOf['Google::Datastore::V1::Datastore::RunQueryResponse'];

coerce 'RunQueryResponse',
    from HashRef, via { 'Google::Datastore::V1::Datastore::RunQueryResponse'->new($_) };

declare 'RepeatedRunQueryResponse',
    as ArrayRef[RunQueryResponse()];

coerce 'RepeatedRunQueryResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Datastore::V1::Datastore::RunQueryResponse'->new($_) } @$_ ] };

declare 'MapStringRunQueryResponse',
    as HashRef[RunQueryResponse()];

declare 'RunAggregationQueryRequest',
    as InstanceOf['Google::Datastore::V1::Datastore::RunAggregationQueryRequest'];

coerce 'RunAggregationQueryRequest',
    from HashRef, via { 'Google::Datastore::V1::Datastore::RunAggregationQueryRequest'->new($_) };

declare 'RepeatedRunAggregationQueryRequest',
    as ArrayRef[RunAggregationQueryRequest()];

coerce 'RepeatedRunAggregationQueryRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Datastore::V1::Datastore::RunAggregationQueryRequest'->new($_) } @$_ ] };

declare 'MapStringRunAggregationQueryRequest',
    as HashRef[RunAggregationQueryRequest()];

declare 'RunAggregationQueryResponse',
    as InstanceOf['Google::Datastore::V1::Datastore::RunAggregationQueryResponse'];

coerce 'RunAggregationQueryResponse',
    from HashRef, via { 'Google::Datastore::V1::Datastore::RunAggregationQueryResponse'->new($_) };

declare 'RepeatedRunAggregationQueryResponse',
    as ArrayRef[RunAggregationQueryResponse()];

coerce 'RepeatedRunAggregationQueryResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Datastore::V1::Datastore::RunAggregationQueryResponse'->new($_) } @$_ ] };

declare 'MapStringRunAggregationQueryResponse',
    as HashRef[RunAggregationQueryResponse()];

declare 'BeginTransactionRequest',
    as InstanceOf['Google::Datastore::V1::Datastore::BeginTransactionRequest'];

coerce 'BeginTransactionRequest',
    from HashRef, via { 'Google::Datastore::V1::Datastore::BeginTransactionRequest'->new($_) };

declare 'RepeatedBeginTransactionRequest',
    as ArrayRef[BeginTransactionRequest()];

coerce 'RepeatedBeginTransactionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Datastore::V1::Datastore::BeginTransactionRequest'->new($_) } @$_ ] };

declare 'MapStringBeginTransactionRequest',
    as HashRef[BeginTransactionRequest()];

declare 'BeginTransactionResponse',
    as InstanceOf['Google::Datastore::V1::Datastore::BeginTransactionResponse'];

coerce 'BeginTransactionResponse',
    from HashRef, via { 'Google::Datastore::V1::Datastore::BeginTransactionResponse'->new($_) };

declare 'RepeatedBeginTransactionResponse',
    as ArrayRef[BeginTransactionResponse()];

coerce 'RepeatedBeginTransactionResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Datastore::V1::Datastore::BeginTransactionResponse'->new($_) } @$_ ] };

declare 'MapStringBeginTransactionResponse',
    as HashRef[BeginTransactionResponse()];

declare 'RollbackRequest',
    as InstanceOf['Google::Datastore::V1::Datastore::RollbackRequest'];

coerce 'RollbackRequest',
    from HashRef, via { 'Google::Datastore::V1::Datastore::RollbackRequest'->new($_) };

declare 'RepeatedRollbackRequest',
    as ArrayRef[RollbackRequest()];

coerce 'RepeatedRollbackRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Datastore::V1::Datastore::RollbackRequest'->new($_) } @$_ ] };

declare 'MapStringRollbackRequest',
    as HashRef[RollbackRequest()];

declare 'RollbackResponse',
    as InstanceOf['Google::Datastore::V1::Datastore::RollbackResponse'];

coerce 'RollbackResponse',
    from HashRef, via { 'Google::Datastore::V1::Datastore::RollbackResponse'->new($_) };

declare 'RepeatedRollbackResponse',
    as ArrayRef[RollbackResponse()];

coerce 'RepeatedRollbackResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Datastore::V1::Datastore::RollbackResponse'->new($_) } @$_ ] };

declare 'MapStringRollbackResponse',
    as HashRef[RollbackResponse()];

declare 'CommitRequest',
    as InstanceOf['Google::Datastore::V1::Datastore::CommitRequest'];

coerce 'CommitRequest',
    from HashRef, via { 'Google::Datastore::V1::Datastore::CommitRequest'->new($_) };

declare 'RepeatedCommitRequest',
    as ArrayRef[CommitRequest()];

coerce 'RepeatedCommitRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Datastore::V1::Datastore::CommitRequest'->new($_) } @$_ ] };

declare 'MapStringCommitRequest',
    as HashRef[CommitRequest()];

declare 'Mode',
    as (Int | Str);

declare 'CommitResponse',
    as InstanceOf['Google::Datastore::V1::Datastore::CommitResponse'];

coerce 'CommitResponse',
    from HashRef, via { 'Google::Datastore::V1::Datastore::CommitResponse'->new($_) };

declare 'RepeatedCommitResponse',
    as ArrayRef[CommitResponse()];

coerce 'RepeatedCommitResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Datastore::V1::Datastore::CommitResponse'->new($_) } @$_ ] };

declare 'MapStringCommitResponse',
    as HashRef[CommitResponse()];

declare 'AllocateIdsRequest',
    as InstanceOf['Google::Datastore::V1::Datastore::AllocateIdsRequest'];

coerce 'AllocateIdsRequest',
    from HashRef, via { 'Google::Datastore::V1::Datastore::AllocateIdsRequest'->new($_) };

declare 'RepeatedAllocateIdsRequest',
    as ArrayRef[AllocateIdsRequest()];

coerce 'RepeatedAllocateIdsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Datastore::V1::Datastore::AllocateIdsRequest'->new($_) } @$_ ] };

declare 'MapStringAllocateIdsRequest',
    as HashRef[AllocateIdsRequest()];

declare 'AllocateIdsResponse',
    as InstanceOf['Google::Datastore::V1::Datastore::AllocateIdsResponse'];

coerce 'AllocateIdsResponse',
    from HashRef, via { 'Google::Datastore::V1::Datastore::AllocateIdsResponse'->new($_) };

declare 'RepeatedAllocateIdsResponse',
    as ArrayRef[AllocateIdsResponse()];

coerce 'RepeatedAllocateIdsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Datastore::V1::Datastore::AllocateIdsResponse'->new($_) } @$_ ] };

declare 'MapStringAllocateIdsResponse',
    as HashRef[AllocateIdsResponse()];

declare 'ReserveIdsRequest',
    as InstanceOf['Google::Datastore::V1::Datastore::ReserveIdsRequest'];

coerce 'ReserveIdsRequest',
    from HashRef, via { 'Google::Datastore::V1::Datastore::ReserveIdsRequest'->new($_) };

declare 'RepeatedReserveIdsRequest',
    as ArrayRef[ReserveIdsRequest()];

coerce 'RepeatedReserveIdsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Datastore::V1::Datastore::ReserveIdsRequest'->new($_) } @$_ ] };

declare 'MapStringReserveIdsRequest',
    as HashRef[ReserveIdsRequest()];

declare 'ReserveIdsResponse',
    as InstanceOf['Google::Datastore::V1::Datastore::ReserveIdsResponse'];

coerce 'ReserveIdsResponse',
    from HashRef, via { 'Google::Datastore::V1::Datastore::ReserveIdsResponse'->new($_) };

declare 'RepeatedReserveIdsResponse',
    as ArrayRef[ReserveIdsResponse()];

coerce 'RepeatedReserveIdsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Datastore::V1::Datastore::ReserveIdsResponse'->new($_) } @$_ ] };

declare 'MapStringReserveIdsResponse',
    as HashRef[ReserveIdsResponse()];

declare 'Mutation',
    as InstanceOf['Google::Datastore::V1::Datastore::Mutation'];

coerce 'Mutation',
    from HashRef, via { 'Google::Datastore::V1::Datastore::Mutation'->new($_) };

declare 'RepeatedMutation',
    as ArrayRef[Mutation()];

coerce 'RepeatedMutation',
    from ArrayRef[HashRef], via { [ map { 'Google::Datastore::V1::Datastore::Mutation'->new($_) } @$_ ] };

declare 'MapStringMutation',
    as HashRef[Mutation()];

declare 'ConflictResolutionStrategy',
    as (Int | Str);

declare 'PropertyTransform',
    as InstanceOf['Google::Datastore::V1::Datastore::PropertyTransform'];

coerce 'PropertyTransform',
    from HashRef, via { 'Google::Datastore::V1::Datastore::PropertyTransform'->new($_) };

declare 'RepeatedPropertyTransform',
    as ArrayRef[PropertyTransform()];

coerce 'RepeatedPropertyTransform',
    from ArrayRef[HashRef], via { [ map { 'Google::Datastore::V1::Datastore::PropertyTransform'->new($_) } @$_ ] };

declare 'MapStringPropertyTransform',
    as HashRef[PropertyTransform()];

declare 'ServerValue',
    as (Int | Str);

declare 'MutationResult',
    as InstanceOf['Google::Datastore::V1::Datastore::MutationResult'];

coerce 'MutationResult',
    from HashRef, via { 'Google::Datastore::V1::Datastore::MutationResult'->new($_) };

declare 'RepeatedMutationResult',
    as ArrayRef[MutationResult()];

coerce 'RepeatedMutationResult',
    from ArrayRef[HashRef], via { [ map { 'Google::Datastore::V1::Datastore::MutationResult'->new($_) } @$_ ] };

declare 'MapStringMutationResult',
    as HashRef[MutationResult()];

declare 'PropertyMask',
    as InstanceOf['Google::Datastore::V1::Datastore::PropertyMask'];

coerce 'PropertyMask',
    from HashRef, via { 'Google::Datastore::V1::Datastore::PropertyMask'->new($_) };

declare 'RepeatedPropertyMask',
    as ArrayRef[PropertyMask()];

coerce 'RepeatedPropertyMask',
    from ArrayRef[HashRef], via { [ map { 'Google::Datastore::V1::Datastore::PropertyMask'->new($_) } @$_ ] };

declare 'MapStringPropertyMask',
    as HashRef[PropertyMask()];

declare 'ReadOptions',
    as InstanceOf['Google::Datastore::V1::Datastore::ReadOptions'];

coerce 'ReadOptions',
    from HashRef, via { 'Google::Datastore::V1::Datastore::ReadOptions'->new($_) };

declare 'RepeatedReadOptions',
    as ArrayRef[ReadOptions()];

coerce 'RepeatedReadOptions',
    from ArrayRef[HashRef], via { [ map { 'Google::Datastore::V1::Datastore::ReadOptions'->new($_) } @$_ ] };

declare 'MapStringReadOptions',
    as HashRef[ReadOptions()];

declare 'ReadConsistency',
    as (Int | Str);

declare 'TransactionOptions',
    as InstanceOf['Google::Datastore::V1::Datastore::TransactionOptions'];

coerce 'TransactionOptions',
    from HashRef, via { 'Google::Datastore::V1::Datastore::TransactionOptions'->new($_) };

declare 'RepeatedTransactionOptions',
    as ArrayRef[TransactionOptions()];

coerce 'RepeatedTransactionOptions',
    from ArrayRef[HashRef], via { [ map { 'Google::Datastore::V1::Datastore::TransactionOptions'->new($_) } @$_ ] };

declare 'MapStringTransactionOptions',
    as HashRef[TransactionOptions()];

declare 'ReadWrite',
    as InstanceOf['Google::Datastore::V1::Datastore::TransactionOptions::ReadWrite'];

coerce 'ReadWrite',
    from HashRef, via { 'Google::Datastore::V1::Datastore::TransactionOptions::ReadWrite'->new($_) };

declare 'RepeatedReadWrite',
    as ArrayRef[ReadWrite()];

coerce 'RepeatedReadWrite',
    from ArrayRef[HashRef], via { [ map { 'Google::Datastore::V1::Datastore::TransactionOptions::ReadWrite'->new($_) } @$_ ] };

declare 'MapStringReadWrite',
    as HashRef[ReadWrite()];

declare 'ReadOnly',
    as InstanceOf['Google::Datastore::V1::Datastore::TransactionOptions::ReadOnly'];

coerce 'ReadOnly',
    from HashRef, via { 'Google::Datastore::V1::Datastore::TransactionOptions::ReadOnly'->new($_) };

declare 'RepeatedReadOnly',
    as ArrayRef[ReadOnly()];

coerce 'RepeatedReadOnly',
    from ArrayRef[HashRef], via { [ map { 'Google::Datastore::V1::Datastore::TransactionOptions::ReadOnly'->new($_) } @$_ ] };

declare 'MapStringReadOnly',
    as HashRef[ReadOnly()];

declare 'RequestOptions',
    as InstanceOf['Google::Datastore::V1::Datastore::RequestOptions'];

coerce 'RequestOptions',
    from HashRef, via { 'Google::Datastore::V1::Datastore::RequestOptions'->new($_) };

declare 'RepeatedRequestOptions',
    as ArrayRef[RequestOptions()];

coerce 'RepeatedRequestOptions',
    from ArrayRef[HashRef], via { [ map { 'Google::Datastore::V1::Datastore::RequestOptions'->new($_) } @$_ ] };

declare 'MapStringRequestOptions',
    as HashRef[RequestOptions()];

1;

__END__

=head1 NAME

Google::Datastore::V1::Datastore::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
