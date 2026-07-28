package Google::Cloud::Bigquery::Storage::V1::Storage::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'CreateReadSessionRequest',
    as InstanceOf['Google::Cloud::Bigquery::Storage::V1::Storage::CreateReadSessionRequest'];

coerce 'CreateReadSessionRequest',
    from HashRef, via { 'Google::Cloud::Bigquery::Storage::V1::Storage::CreateReadSessionRequest'->new($_) };

declare 'RepeatedCreateReadSessionRequest',
    as ArrayRef[CreateReadSessionRequest()];

coerce 'RepeatedCreateReadSessionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Storage::V1::Storage::CreateReadSessionRequest'->new($_) } @$_ ] };

declare 'MapStringCreateReadSessionRequest',
    as HashRef[CreateReadSessionRequest()];

declare 'ReadRowsRequest',
    as InstanceOf['Google::Cloud::Bigquery::Storage::V1::Storage::ReadRowsRequest'];

coerce 'ReadRowsRequest',
    from HashRef, via { 'Google::Cloud::Bigquery::Storage::V1::Storage::ReadRowsRequest'->new($_) };

declare 'RepeatedReadRowsRequest',
    as ArrayRef[ReadRowsRequest()];

coerce 'RepeatedReadRowsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Storage::V1::Storage::ReadRowsRequest'->new($_) } @$_ ] };

declare 'MapStringReadRowsRequest',
    as HashRef[ReadRowsRequest()];

declare 'ThrottleState',
    as InstanceOf['Google::Cloud::Bigquery::Storage::V1::Storage::ThrottleState'];

coerce 'ThrottleState',
    from HashRef, via { 'Google::Cloud::Bigquery::Storage::V1::Storage::ThrottleState'->new($_) };

declare 'RepeatedThrottleState',
    as ArrayRef[ThrottleState()];

coerce 'RepeatedThrottleState',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Storage::V1::Storage::ThrottleState'->new($_) } @$_ ] };

declare 'MapStringThrottleState',
    as HashRef[ThrottleState()];

declare 'StreamStats',
    as InstanceOf['Google::Cloud::Bigquery::Storage::V1::Storage::StreamStats'];

coerce 'StreamStats',
    from HashRef, via { 'Google::Cloud::Bigquery::Storage::V1::Storage::StreamStats'->new($_) };

declare 'RepeatedStreamStats',
    as ArrayRef[StreamStats()];

coerce 'RepeatedStreamStats',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Storage::V1::Storage::StreamStats'->new($_) } @$_ ] };

declare 'MapStringStreamStats',
    as HashRef[StreamStats()];

declare 'Progress',
    as InstanceOf['Google::Cloud::Bigquery::Storage::V1::Storage::StreamStats::Progress'];

coerce 'Progress',
    from HashRef, via { 'Google::Cloud::Bigquery::Storage::V1::Storage::StreamStats::Progress'->new($_) };

declare 'RepeatedProgress',
    as ArrayRef[Progress()];

coerce 'RepeatedProgress',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Storage::V1::Storage::StreamStats::Progress'->new($_) } @$_ ] };

declare 'MapStringProgress',
    as HashRef[Progress()];

declare 'ReadRowsResponse',
    as InstanceOf['Google::Cloud::Bigquery::Storage::V1::Storage::ReadRowsResponse'];

coerce 'ReadRowsResponse',
    from HashRef, via { 'Google::Cloud::Bigquery::Storage::V1::Storage::ReadRowsResponse'->new($_) };

declare 'RepeatedReadRowsResponse',
    as ArrayRef[ReadRowsResponse()];

coerce 'RepeatedReadRowsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Storage::V1::Storage::ReadRowsResponse'->new($_) } @$_ ] };

declare 'MapStringReadRowsResponse',
    as HashRef[ReadRowsResponse()];

declare 'SplitReadStreamRequest',
    as InstanceOf['Google::Cloud::Bigquery::Storage::V1::Storage::SplitReadStreamRequest'];

coerce 'SplitReadStreamRequest',
    from HashRef, via { 'Google::Cloud::Bigquery::Storage::V1::Storage::SplitReadStreamRequest'->new($_) };

declare 'RepeatedSplitReadStreamRequest',
    as ArrayRef[SplitReadStreamRequest()];

coerce 'RepeatedSplitReadStreamRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Storage::V1::Storage::SplitReadStreamRequest'->new($_) } @$_ ] };

declare 'MapStringSplitReadStreamRequest',
    as HashRef[SplitReadStreamRequest()];

declare 'SplitReadStreamResponse',
    as InstanceOf['Google::Cloud::Bigquery::Storage::V1::Storage::SplitReadStreamResponse'];

coerce 'SplitReadStreamResponse',
    from HashRef, via { 'Google::Cloud::Bigquery::Storage::V1::Storage::SplitReadStreamResponse'->new($_) };

declare 'RepeatedSplitReadStreamResponse',
    as ArrayRef[SplitReadStreamResponse()];

coerce 'RepeatedSplitReadStreamResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Storage::V1::Storage::SplitReadStreamResponse'->new($_) } @$_ ] };

declare 'MapStringSplitReadStreamResponse',
    as HashRef[SplitReadStreamResponse()];

declare 'CreateWriteStreamRequest',
    as InstanceOf['Google::Cloud::Bigquery::Storage::V1::Storage::CreateWriteStreamRequest'];

coerce 'CreateWriteStreamRequest',
    from HashRef, via { 'Google::Cloud::Bigquery::Storage::V1::Storage::CreateWriteStreamRequest'->new($_) };

declare 'RepeatedCreateWriteStreamRequest',
    as ArrayRef[CreateWriteStreamRequest()];

coerce 'RepeatedCreateWriteStreamRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Storage::V1::Storage::CreateWriteStreamRequest'->new($_) } @$_ ] };

declare 'MapStringCreateWriteStreamRequest',
    as HashRef[CreateWriteStreamRequest()];

declare 'AppendRowsRequest',
    as InstanceOf['Google::Cloud::Bigquery::Storage::V1::Storage::AppendRowsRequest'];

coerce 'AppendRowsRequest',
    from HashRef, via { 'Google::Cloud::Bigquery::Storage::V1::Storage::AppendRowsRequest'->new($_) };

declare 'RepeatedAppendRowsRequest',
    as ArrayRef[AppendRowsRequest()];

coerce 'RepeatedAppendRowsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Storage::V1::Storage::AppendRowsRequest'->new($_) } @$_ ] };

declare 'MapStringAppendRowsRequest',
    as HashRef[AppendRowsRequest()];

declare 'MissingValueInterpretation',
    as (Int | Str);

declare 'ArrowData',
    as InstanceOf['Google::Cloud::Bigquery::Storage::V1::Storage::AppendRowsRequest::ArrowData'];

coerce 'ArrowData',
    from HashRef, via { 'Google::Cloud::Bigquery::Storage::V1::Storage::AppendRowsRequest::ArrowData'->new($_) };

declare 'RepeatedArrowData',
    as ArrayRef[ArrowData()];

coerce 'RepeatedArrowData',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Storage::V1::Storage::AppendRowsRequest::ArrowData'->new($_) } @$_ ] };

declare 'MapStringArrowData',
    as HashRef[ArrowData()];

declare 'ProtoData',
    as InstanceOf['Google::Cloud::Bigquery::Storage::V1::Storage::AppendRowsRequest::ProtoData'];

coerce 'ProtoData',
    from HashRef, via { 'Google::Cloud::Bigquery::Storage::V1::Storage::AppendRowsRequest::ProtoData'->new($_) };

declare 'RepeatedProtoData',
    as ArrayRef[ProtoData()];

coerce 'RepeatedProtoData',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Storage::V1::Storage::AppendRowsRequest::ProtoData'->new($_) } @$_ ] };

declare 'MapStringProtoData',
    as HashRef[ProtoData()];

declare 'MissingValueInterpretationsEntry',
    as InstanceOf['Google::Cloud::Bigquery::Storage::V1::Storage::AppendRowsRequest::MissingValueInterpretationsEntry'];

coerce 'MissingValueInterpretationsEntry',
    from HashRef, via { 'Google::Cloud::Bigquery::Storage::V1::Storage::AppendRowsRequest::MissingValueInterpretationsEntry'->new($_) };

declare 'RepeatedMissingValueInterpretationsEntry',
    as ArrayRef[MissingValueInterpretationsEntry()];

coerce 'RepeatedMissingValueInterpretationsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Storage::V1::Storage::AppendRowsRequest::MissingValueInterpretationsEntry'->new($_) } @$_ ] };

declare 'MapStringMissingValueInterpretationsEntry',
    as HashRef[MissingValueInterpretationsEntry()];

declare 'AppendRowsResponse',
    as InstanceOf['Google::Cloud::Bigquery::Storage::V1::Storage::AppendRowsResponse'];

coerce 'AppendRowsResponse',
    from HashRef, via { 'Google::Cloud::Bigquery::Storage::V1::Storage::AppendRowsResponse'->new($_) };

declare 'RepeatedAppendRowsResponse',
    as ArrayRef[AppendRowsResponse()];

coerce 'RepeatedAppendRowsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Storage::V1::Storage::AppendRowsResponse'->new($_) } @$_ ] };

declare 'MapStringAppendRowsResponse',
    as HashRef[AppendRowsResponse()];

declare 'AppendResult',
    as InstanceOf['Google::Cloud::Bigquery::Storage::V1::Storage::AppendRowsResponse::AppendResult'];

coerce 'AppendResult',
    from HashRef, via { 'Google::Cloud::Bigquery::Storage::V1::Storage::AppendRowsResponse::AppendResult'->new($_) };

declare 'RepeatedAppendResult',
    as ArrayRef[AppendResult()];

coerce 'RepeatedAppendResult',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Storage::V1::Storage::AppendRowsResponse::AppendResult'->new($_) } @$_ ] };

declare 'MapStringAppendResult',
    as HashRef[AppendResult()];

declare 'GetWriteStreamRequest',
    as InstanceOf['Google::Cloud::Bigquery::Storage::V1::Storage::GetWriteStreamRequest'];

coerce 'GetWriteStreamRequest',
    from HashRef, via { 'Google::Cloud::Bigquery::Storage::V1::Storage::GetWriteStreamRequest'->new($_) };

declare 'RepeatedGetWriteStreamRequest',
    as ArrayRef[GetWriteStreamRequest()];

coerce 'RepeatedGetWriteStreamRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Storage::V1::Storage::GetWriteStreamRequest'->new($_) } @$_ ] };

declare 'MapStringGetWriteStreamRequest',
    as HashRef[GetWriteStreamRequest()];

declare 'BatchCommitWriteStreamsRequest',
    as InstanceOf['Google::Cloud::Bigquery::Storage::V1::Storage::BatchCommitWriteStreamsRequest'];

coerce 'BatchCommitWriteStreamsRequest',
    from HashRef, via { 'Google::Cloud::Bigquery::Storage::V1::Storage::BatchCommitWriteStreamsRequest'->new($_) };

declare 'RepeatedBatchCommitWriteStreamsRequest',
    as ArrayRef[BatchCommitWriteStreamsRequest()];

coerce 'RepeatedBatchCommitWriteStreamsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Storage::V1::Storage::BatchCommitWriteStreamsRequest'->new($_) } @$_ ] };

declare 'MapStringBatchCommitWriteStreamsRequest',
    as HashRef[BatchCommitWriteStreamsRequest()];

declare 'BatchCommitWriteStreamsResponse',
    as InstanceOf['Google::Cloud::Bigquery::Storage::V1::Storage::BatchCommitWriteStreamsResponse'];

coerce 'BatchCommitWriteStreamsResponse',
    from HashRef, via { 'Google::Cloud::Bigquery::Storage::V1::Storage::BatchCommitWriteStreamsResponse'->new($_) };

declare 'RepeatedBatchCommitWriteStreamsResponse',
    as ArrayRef[BatchCommitWriteStreamsResponse()];

coerce 'RepeatedBatchCommitWriteStreamsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Storage::V1::Storage::BatchCommitWriteStreamsResponse'->new($_) } @$_ ] };

declare 'MapStringBatchCommitWriteStreamsResponse',
    as HashRef[BatchCommitWriteStreamsResponse()];

declare 'FinalizeWriteStreamRequest',
    as InstanceOf['Google::Cloud::Bigquery::Storage::V1::Storage::FinalizeWriteStreamRequest'];

coerce 'FinalizeWriteStreamRequest',
    from HashRef, via { 'Google::Cloud::Bigquery::Storage::V1::Storage::FinalizeWriteStreamRequest'->new($_) };

declare 'RepeatedFinalizeWriteStreamRequest',
    as ArrayRef[FinalizeWriteStreamRequest()];

coerce 'RepeatedFinalizeWriteStreamRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Storage::V1::Storage::FinalizeWriteStreamRequest'->new($_) } @$_ ] };

declare 'MapStringFinalizeWriteStreamRequest',
    as HashRef[FinalizeWriteStreamRequest()];

declare 'FinalizeWriteStreamResponse',
    as InstanceOf['Google::Cloud::Bigquery::Storage::V1::Storage::FinalizeWriteStreamResponse'];

coerce 'FinalizeWriteStreamResponse',
    from HashRef, via { 'Google::Cloud::Bigquery::Storage::V1::Storage::FinalizeWriteStreamResponse'->new($_) };

declare 'RepeatedFinalizeWriteStreamResponse',
    as ArrayRef[FinalizeWriteStreamResponse()];

coerce 'RepeatedFinalizeWriteStreamResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Storage::V1::Storage::FinalizeWriteStreamResponse'->new($_) } @$_ ] };

declare 'MapStringFinalizeWriteStreamResponse',
    as HashRef[FinalizeWriteStreamResponse()];

declare 'FlushRowsRequest',
    as InstanceOf['Google::Cloud::Bigquery::Storage::V1::Storage::FlushRowsRequest'];

coerce 'FlushRowsRequest',
    from HashRef, via { 'Google::Cloud::Bigquery::Storage::V1::Storage::FlushRowsRequest'->new($_) };

declare 'RepeatedFlushRowsRequest',
    as ArrayRef[FlushRowsRequest()];

coerce 'RepeatedFlushRowsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Storage::V1::Storage::FlushRowsRequest'->new($_) } @$_ ] };

declare 'MapStringFlushRowsRequest',
    as HashRef[FlushRowsRequest()];

declare 'FlushRowsResponse',
    as InstanceOf['Google::Cloud::Bigquery::Storage::V1::Storage::FlushRowsResponse'];

coerce 'FlushRowsResponse',
    from HashRef, via { 'Google::Cloud::Bigquery::Storage::V1::Storage::FlushRowsResponse'->new($_) };

declare 'RepeatedFlushRowsResponse',
    as ArrayRef[FlushRowsResponse()];

coerce 'RepeatedFlushRowsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Storage::V1::Storage::FlushRowsResponse'->new($_) } @$_ ] };

declare 'MapStringFlushRowsResponse',
    as HashRef[FlushRowsResponse()];

declare 'StorageError',
    as InstanceOf['Google::Cloud::Bigquery::Storage::V1::Storage::StorageError'];

coerce 'StorageError',
    from HashRef, via { 'Google::Cloud::Bigquery::Storage::V1::Storage::StorageError'->new($_) };

declare 'RepeatedStorageError',
    as ArrayRef[StorageError()];

coerce 'RepeatedStorageError',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Storage::V1::Storage::StorageError'->new($_) } @$_ ] };

declare 'MapStringStorageError',
    as HashRef[StorageError()];

declare 'StorageErrorCode',
    as (Int | Str);

declare 'RowError',
    as InstanceOf['Google::Cloud::Bigquery::Storage::V1::Storage::RowError'];

coerce 'RowError',
    from HashRef, via { 'Google::Cloud::Bigquery::Storage::V1::Storage::RowError'->new($_) };

declare 'RepeatedRowError',
    as ArrayRef[RowError()];

coerce 'RepeatedRowError',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Storage::V1::Storage::RowError'->new($_) } @$_ ] };

declare 'MapStringRowError',
    as HashRef[RowError()];

declare 'RowErrorCode',
    as (Int | Str);

1;

__END__

=head1 NAME

Google::Cloud::Bigquery::Storage::V1::Storage::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
