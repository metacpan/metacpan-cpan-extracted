package Google::Firestore::V1beta1::Firestore::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'GetDocumentRequest',
    as InstanceOf['Google::Firestore::V1beta1::Firestore::GetDocumentRequest'];

coerce 'GetDocumentRequest',
    from HashRef, via { 'Google::Firestore::V1beta1::Firestore::GetDocumentRequest'->new($_) };

declare 'RepeatedGetDocumentRequest',
    as ArrayRef[GetDocumentRequest()];

coerce 'RepeatedGetDocumentRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Firestore::V1beta1::Firestore::GetDocumentRequest'->new($_) } @$_ ] };

declare 'MapStringGetDocumentRequest',
    as HashRef[GetDocumentRequest()];

declare 'ListDocumentsRequest',
    as InstanceOf['Google::Firestore::V1beta1::Firestore::ListDocumentsRequest'];

coerce 'ListDocumentsRequest',
    from HashRef, via { 'Google::Firestore::V1beta1::Firestore::ListDocumentsRequest'->new($_) };

declare 'RepeatedListDocumentsRequest',
    as ArrayRef[ListDocumentsRequest()];

coerce 'RepeatedListDocumentsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Firestore::V1beta1::Firestore::ListDocumentsRequest'->new($_) } @$_ ] };

declare 'MapStringListDocumentsRequest',
    as HashRef[ListDocumentsRequest()];

declare 'ListDocumentsResponse',
    as InstanceOf['Google::Firestore::V1beta1::Firestore::ListDocumentsResponse'];

coerce 'ListDocumentsResponse',
    from HashRef, via { 'Google::Firestore::V1beta1::Firestore::ListDocumentsResponse'->new($_) };

declare 'RepeatedListDocumentsResponse',
    as ArrayRef[ListDocumentsResponse()];

coerce 'RepeatedListDocumentsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Firestore::V1beta1::Firestore::ListDocumentsResponse'->new($_) } @$_ ] };

declare 'MapStringListDocumentsResponse',
    as HashRef[ListDocumentsResponse()];

declare 'CreateDocumentRequest',
    as InstanceOf['Google::Firestore::V1beta1::Firestore::CreateDocumentRequest'];

coerce 'CreateDocumentRequest',
    from HashRef, via { 'Google::Firestore::V1beta1::Firestore::CreateDocumentRequest'->new($_) };

declare 'RepeatedCreateDocumentRequest',
    as ArrayRef[CreateDocumentRequest()];

coerce 'RepeatedCreateDocumentRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Firestore::V1beta1::Firestore::CreateDocumentRequest'->new($_) } @$_ ] };

declare 'MapStringCreateDocumentRequest',
    as HashRef[CreateDocumentRequest()];

declare 'UpdateDocumentRequest',
    as InstanceOf['Google::Firestore::V1beta1::Firestore::UpdateDocumentRequest'];

coerce 'UpdateDocumentRequest',
    from HashRef, via { 'Google::Firestore::V1beta1::Firestore::UpdateDocumentRequest'->new($_) };

declare 'RepeatedUpdateDocumentRequest',
    as ArrayRef[UpdateDocumentRequest()];

coerce 'RepeatedUpdateDocumentRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Firestore::V1beta1::Firestore::UpdateDocumentRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateDocumentRequest',
    as HashRef[UpdateDocumentRequest()];

declare 'DeleteDocumentRequest',
    as InstanceOf['Google::Firestore::V1beta1::Firestore::DeleteDocumentRequest'];

coerce 'DeleteDocumentRequest',
    from HashRef, via { 'Google::Firestore::V1beta1::Firestore::DeleteDocumentRequest'->new($_) };

declare 'RepeatedDeleteDocumentRequest',
    as ArrayRef[DeleteDocumentRequest()];

coerce 'RepeatedDeleteDocumentRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Firestore::V1beta1::Firestore::DeleteDocumentRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteDocumentRequest',
    as HashRef[DeleteDocumentRequest()];

declare 'BatchGetDocumentsRequest',
    as InstanceOf['Google::Firestore::V1beta1::Firestore::BatchGetDocumentsRequest'];

coerce 'BatchGetDocumentsRequest',
    from HashRef, via { 'Google::Firestore::V1beta1::Firestore::BatchGetDocumentsRequest'->new($_) };

declare 'RepeatedBatchGetDocumentsRequest',
    as ArrayRef[BatchGetDocumentsRequest()];

coerce 'RepeatedBatchGetDocumentsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Firestore::V1beta1::Firestore::BatchGetDocumentsRequest'->new($_) } @$_ ] };

declare 'MapStringBatchGetDocumentsRequest',
    as HashRef[BatchGetDocumentsRequest()];

declare 'BatchGetDocumentsResponse',
    as InstanceOf['Google::Firestore::V1beta1::Firestore::BatchGetDocumentsResponse'];

coerce 'BatchGetDocumentsResponse',
    from HashRef, via { 'Google::Firestore::V1beta1::Firestore::BatchGetDocumentsResponse'->new($_) };

declare 'RepeatedBatchGetDocumentsResponse',
    as ArrayRef[BatchGetDocumentsResponse()];

coerce 'RepeatedBatchGetDocumentsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Firestore::V1beta1::Firestore::BatchGetDocumentsResponse'->new($_) } @$_ ] };

declare 'MapStringBatchGetDocumentsResponse',
    as HashRef[BatchGetDocumentsResponse()];

declare 'BeginTransactionRequest',
    as InstanceOf['Google::Firestore::V1beta1::Firestore::BeginTransactionRequest'];

coerce 'BeginTransactionRequest',
    from HashRef, via { 'Google::Firestore::V1beta1::Firestore::BeginTransactionRequest'->new($_) };

declare 'RepeatedBeginTransactionRequest',
    as ArrayRef[BeginTransactionRequest()];

coerce 'RepeatedBeginTransactionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Firestore::V1beta1::Firestore::BeginTransactionRequest'->new($_) } @$_ ] };

declare 'MapStringBeginTransactionRequest',
    as HashRef[BeginTransactionRequest()];

declare 'BeginTransactionResponse',
    as InstanceOf['Google::Firestore::V1beta1::Firestore::BeginTransactionResponse'];

coerce 'BeginTransactionResponse',
    from HashRef, via { 'Google::Firestore::V1beta1::Firestore::BeginTransactionResponse'->new($_) };

declare 'RepeatedBeginTransactionResponse',
    as ArrayRef[BeginTransactionResponse()];

coerce 'RepeatedBeginTransactionResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Firestore::V1beta1::Firestore::BeginTransactionResponse'->new($_) } @$_ ] };

declare 'MapStringBeginTransactionResponse',
    as HashRef[BeginTransactionResponse()];

declare 'CommitRequest',
    as InstanceOf['Google::Firestore::V1beta1::Firestore::CommitRequest'];

coerce 'CommitRequest',
    from HashRef, via { 'Google::Firestore::V1beta1::Firestore::CommitRequest'->new($_) };

declare 'RepeatedCommitRequest',
    as ArrayRef[CommitRequest()];

coerce 'RepeatedCommitRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Firestore::V1beta1::Firestore::CommitRequest'->new($_) } @$_ ] };

declare 'MapStringCommitRequest',
    as HashRef[CommitRequest()];

declare 'CommitResponse',
    as InstanceOf['Google::Firestore::V1beta1::Firestore::CommitResponse'];

coerce 'CommitResponse',
    from HashRef, via { 'Google::Firestore::V1beta1::Firestore::CommitResponse'->new($_) };

declare 'RepeatedCommitResponse',
    as ArrayRef[CommitResponse()];

coerce 'RepeatedCommitResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Firestore::V1beta1::Firestore::CommitResponse'->new($_) } @$_ ] };

declare 'MapStringCommitResponse',
    as HashRef[CommitResponse()];

declare 'RollbackRequest',
    as InstanceOf['Google::Firestore::V1beta1::Firestore::RollbackRequest'];

coerce 'RollbackRequest',
    from HashRef, via { 'Google::Firestore::V1beta1::Firestore::RollbackRequest'->new($_) };

declare 'RepeatedRollbackRequest',
    as ArrayRef[RollbackRequest()];

coerce 'RepeatedRollbackRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Firestore::V1beta1::Firestore::RollbackRequest'->new($_) } @$_ ] };

declare 'MapStringRollbackRequest',
    as HashRef[RollbackRequest()];

declare 'RunQueryRequest',
    as InstanceOf['Google::Firestore::V1beta1::Firestore::RunQueryRequest'];

coerce 'RunQueryRequest',
    from HashRef, via { 'Google::Firestore::V1beta1::Firestore::RunQueryRequest'->new($_) };

declare 'RepeatedRunQueryRequest',
    as ArrayRef[RunQueryRequest()];

coerce 'RepeatedRunQueryRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Firestore::V1beta1::Firestore::RunQueryRequest'->new($_) } @$_ ] };

declare 'MapStringRunQueryRequest',
    as HashRef[RunQueryRequest()];

declare 'RunQueryResponse',
    as InstanceOf['Google::Firestore::V1beta1::Firestore::RunQueryResponse'];

coerce 'RunQueryResponse',
    from HashRef, via { 'Google::Firestore::V1beta1::Firestore::RunQueryResponse'->new($_) };

declare 'RepeatedRunQueryResponse',
    as ArrayRef[RunQueryResponse()];

coerce 'RepeatedRunQueryResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Firestore::V1beta1::Firestore::RunQueryResponse'->new($_) } @$_ ] };

declare 'MapStringRunQueryResponse',
    as HashRef[RunQueryResponse()];

declare 'PartitionQueryRequest',
    as InstanceOf['Google::Firestore::V1beta1::Firestore::PartitionQueryRequest'];

coerce 'PartitionQueryRequest',
    from HashRef, via { 'Google::Firestore::V1beta1::Firestore::PartitionQueryRequest'->new($_) };

declare 'RepeatedPartitionQueryRequest',
    as ArrayRef[PartitionQueryRequest()];

coerce 'RepeatedPartitionQueryRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Firestore::V1beta1::Firestore::PartitionQueryRequest'->new($_) } @$_ ] };

declare 'MapStringPartitionQueryRequest',
    as HashRef[PartitionQueryRequest()];

declare 'PartitionQueryResponse',
    as InstanceOf['Google::Firestore::V1beta1::Firestore::PartitionQueryResponse'];

coerce 'PartitionQueryResponse',
    from HashRef, via { 'Google::Firestore::V1beta1::Firestore::PartitionQueryResponse'->new($_) };

declare 'RepeatedPartitionQueryResponse',
    as ArrayRef[PartitionQueryResponse()];

coerce 'RepeatedPartitionQueryResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Firestore::V1beta1::Firestore::PartitionQueryResponse'->new($_) } @$_ ] };

declare 'MapStringPartitionQueryResponse',
    as HashRef[PartitionQueryResponse()];

declare 'WriteRequest',
    as InstanceOf['Google::Firestore::V1beta1::Firestore::WriteRequest'];

coerce 'WriteRequest',
    from HashRef, via { 'Google::Firestore::V1beta1::Firestore::WriteRequest'->new($_) };

declare 'RepeatedWriteRequest',
    as ArrayRef[WriteRequest()];

coerce 'RepeatedWriteRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Firestore::V1beta1::Firestore::WriteRequest'->new($_) } @$_ ] };

declare 'MapStringWriteRequest',
    as HashRef[WriteRequest()];

declare 'LabelsEntry',
    as InstanceOf['Google::Firestore::V1beta1::Firestore::WriteRequest::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Firestore::V1beta1::Firestore::WriteRequest::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Firestore::V1beta1::Firestore::WriteRequest::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'WriteResponse',
    as InstanceOf['Google::Firestore::V1beta1::Firestore::WriteResponse'];

coerce 'WriteResponse',
    from HashRef, via { 'Google::Firestore::V1beta1::Firestore::WriteResponse'->new($_) };

declare 'RepeatedWriteResponse',
    as ArrayRef[WriteResponse()];

coerce 'RepeatedWriteResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Firestore::V1beta1::Firestore::WriteResponse'->new($_) } @$_ ] };

declare 'MapStringWriteResponse',
    as HashRef[WriteResponse()];

declare 'ListenRequest',
    as InstanceOf['Google::Firestore::V1beta1::Firestore::ListenRequest'];

coerce 'ListenRequest',
    from HashRef, via { 'Google::Firestore::V1beta1::Firestore::ListenRequest'->new($_) };

declare 'RepeatedListenRequest',
    as ArrayRef[ListenRequest()];

coerce 'RepeatedListenRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Firestore::V1beta1::Firestore::ListenRequest'->new($_) } @$_ ] };

declare 'MapStringListenRequest',
    as HashRef[ListenRequest()];

declare 'LabelsEntry',
    as InstanceOf['Google::Firestore::V1beta1::Firestore::ListenRequest::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Firestore::V1beta1::Firestore::ListenRequest::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Firestore::V1beta1::Firestore::ListenRequest::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'ListenResponse',
    as InstanceOf['Google::Firestore::V1beta1::Firestore::ListenResponse'];

coerce 'ListenResponse',
    from HashRef, via { 'Google::Firestore::V1beta1::Firestore::ListenResponse'->new($_) };

declare 'RepeatedListenResponse',
    as ArrayRef[ListenResponse()];

coerce 'RepeatedListenResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Firestore::V1beta1::Firestore::ListenResponse'->new($_) } @$_ ] };

declare 'MapStringListenResponse',
    as HashRef[ListenResponse()];

declare 'Target',
    as InstanceOf['Google::Firestore::V1beta1::Firestore::Target'];

coerce 'Target',
    from HashRef, via { 'Google::Firestore::V1beta1::Firestore::Target'->new($_) };

declare 'RepeatedTarget',
    as ArrayRef[Target()];

coerce 'RepeatedTarget',
    from ArrayRef[HashRef], via { [ map { 'Google::Firestore::V1beta1::Firestore::Target'->new($_) } @$_ ] };

declare 'MapStringTarget',
    as HashRef[Target()];

declare 'DocumentsTarget',
    as InstanceOf['Google::Firestore::V1beta1::Firestore::Target::DocumentsTarget'];

coerce 'DocumentsTarget',
    from HashRef, via { 'Google::Firestore::V1beta1::Firestore::Target::DocumentsTarget'->new($_) };

declare 'RepeatedDocumentsTarget',
    as ArrayRef[DocumentsTarget()];

coerce 'RepeatedDocumentsTarget',
    from ArrayRef[HashRef], via { [ map { 'Google::Firestore::V1beta1::Firestore::Target::DocumentsTarget'->new($_) } @$_ ] };

declare 'MapStringDocumentsTarget',
    as HashRef[DocumentsTarget()];

declare 'QueryTarget',
    as InstanceOf['Google::Firestore::V1beta1::Firestore::Target::QueryTarget'];

coerce 'QueryTarget',
    from HashRef, via { 'Google::Firestore::V1beta1::Firestore::Target::QueryTarget'->new($_) };

declare 'RepeatedQueryTarget',
    as ArrayRef[QueryTarget()];

coerce 'RepeatedQueryTarget',
    from ArrayRef[HashRef], via { [ map { 'Google::Firestore::V1beta1::Firestore::Target::QueryTarget'->new($_) } @$_ ] };

declare 'MapStringQueryTarget',
    as HashRef[QueryTarget()];

declare 'TargetChange',
    as InstanceOf['Google::Firestore::V1beta1::Firestore::TargetChange'];

coerce 'TargetChange',
    from HashRef, via { 'Google::Firestore::V1beta1::Firestore::TargetChange'->new($_) };

declare 'RepeatedTargetChange',
    as ArrayRef[TargetChange()];

coerce 'RepeatedTargetChange',
    from ArrayRef[HashRef], via { [ map { 'Google::Firestore::V1beta1::Firestore::TargetChange'->new($_) } @$_ ] };

declare 'MapStringTargetChange',
    as HashRef[TargetChange()];

declare 'TargetChangeType',
    as (Int | Str);

declare 'ListCollectionIdsRequest',
    as InstanceOf['Google::Firestore::V1beta1::Firestore::ListCollectionIdsRequest'];

coerce 'ListCollectionIdsRequest',
    from HashRef, via { 'Google::Firestore::V1beta1::Firestore::ListCollectionIdsRequest'->new($_) };

declare 'RepeatedListCollectionIdsRequest',
    as ArrayRef[ListCollectionIdsRequest()];

coerce 'RepeatedListCollectionIdsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Firestore::V1beta1::Firestore::ListCollectionIdsRequest'->new($_) } @$_ ] };

declare 'MapStringListCollectionIdsRequest',
    as HashRef[ListCollectionIdsRequest()];

declare 'ListCollectionIdsResponse',
    as InstanceOf['Google::Firestore::V1beta1::Firestore::ListCollectionIdsResponse'];

coerce 'ListCollectionIdsResponse',
    from HashRef, via { 'Google::Firestore::V1beta1::Firestore::ListCollectionIdsResponse'->new($_) };

declare 'RepeatedListCollectionIdsResponse',
    as ArrayRef[ListCollectionIdsResponse()];

coerce 'RepeatedListCollectionIdsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Firestore::V1beta1::Firestore::ListCollectionIdsResponse'->new($_) } @$_ ] };

declare 'MapStringListCollectionIdsResponse',
    as HashRef[ListCollectionIdsResponse()];

declare 'BatchWriteRequest',
    as InstanceOf['Google::Firestore::V1beta1::Firestore::BatchWriteRequest'];

coerce 'BatchWriteRequest',
    from HashRef, via { 'Google::Firestore::V1beta1::Firestore::BatchWriteRequest'->new($_) };

declare 'RepeatedBatchWriteRequest',
    as ArrayRef[BatchWriteRequest()];

coerce 'RepeatedBatchWriteRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Firestore::V1beta1::Firestore::BatchWriteRequest'->new($_) } @$_ ] };

declare 'MapStringBatchWriteRequest',
    as HashRef[BatchWriteRequest()];

declare 'LabelsEntry',
    as InstanceOf['Google::Firestore::V1beta1::Firestore::BatchWriteRequest::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Firestore::V1beta1::Firestore::BatchWriteRequest::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Firestore::V1beta1::Firestore::BatchWriteRequest::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'BatchWriteResponse',
    as InstanceOf['Google::Firestore::V1beta1::Firestore::BatchWriteResponse'];

coerce 'BatchWriteResponse',
    from HashRef, via { 'Google::Firestore::V1beta1::Firestore::BatchWriteResponse'->new($_) };

declare 'RepeatedBatchWriteResponse',
    as ArrayRef[BatchWriteResponse()];

coerce 'RepeatedBatchWriteResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Firestore::V1beta1::Firestore::BatchWriteResponse'->new($_) } @$_ ] };

declare 'MapStringBatchWriteResponse',
    as HashRef[BatchWriteResponse()];

1;

__END__

=head1 NAME

Google::Firestore::V1beta1::Firestore::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
