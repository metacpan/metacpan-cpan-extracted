package Google::Bigtable::V2::Bigtable::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'ReadRowsRequest',
    as InstanceOf['Google::Bigtable::V2::Bigtable::ReadRowsRequest'];

coerce 'ReadRowsRequest',
    from HashRef, via { 'Google::Bigtable::V2::Bigtable::ReadRowsRequest'->new($_) };

declare 'RepeatedReadRowsRequest',
    as ArrayRef[ReadRowsRequest()];

coerce 'RepeatedReadRowsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::V2::Bigtable::ReadRowsRequest'->new($_) } @$_ ] };

declare 'MapStringReadRowsRequest',
    as HashRef[ReadRowsRequest()];

declare 'RequestStatsView',
    as (Int | Str);

declare 'ReadRowsResponse',
    as InstanceOf['Google::Bigtable::V2::Bigtable::ReadRowsResponse'];

coerce 'ReadRowsResponse',
    from HashRef, via { 'Google::Bigtable::V2::Bigtable::ReadRowsResponse'->new($_) };

declare 'RepeatedReadRowsResponse',
    as ArrayRef[ReadRowsResponse()];

coerce 'RepeatedReadRowsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::V2::Bigtable::ReadRowsResponse'->new($_) } @$_ ] };

declare 'MapStringReadRowsResponse',
    as HashRef[ReadRowsResponse()];

declare 'CellChunk',
    as InstanceOf['Google::Bigtable::V2::Bigtable::ReadRowsResponse::CellChunk'];

coerce 'CellChunk',
    from HashRef, via { 'Google::Bigtable::V2::Bigtable::ReadRowsResponse::CellChunk'->new($_) };

declare 'RepeatedCellChunk',
    as ArrayRef[CellChunk()];

coerce 'RepeatedCellChunk',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::V2::Bigtable::ReadRowsResponse::CellChunk'->new($_) } @$_ ] };

declare 'MapStringCellChunk',
    as HashRef[CellChunk()];

declare 'SampleRowKeysRequest',
    as InstanceOf['Google::Bigtable::V2::Bigtable::SampleRowKeysRequest'];

coerce 'SampleRowKeysRequest',
    from HashRef, via { 'Google::Bigtable::V2::Bigtable::SampleRowKeysRequest'->new($_) };

declare 'RepeatedSampleRowKeysRequest',
    as ArrayRef[SampleRowKeysRequest()];

coerce 'RepeatedSampleRowKeysRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::V2::Bigtable::SampleRowKeysRequest'->new($_) } @$_ ] };

declare 'MapStringSampleRowKeysRequest',
    as HashRef[SampleRowKeysRequest()];

declare 'SampleRowKeysResponse',
    as InstanceOf['Google::Bigtable::V2::Bigtable::SampleRowKeysResponse'];

coerce 'SampleRowKeysResponse',
    from HashRef, via { 'Google::Bigtable::V2::Bigtable::SampleRowKeysResponse'->new($_) };

declare 'RepeatedSampleRowKeysResponse',
    as ArrayRef[SampleRowKeysResponse()];

coerce 'RepeatedSampleRowKeysResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::V2::Bigtable::SampleRowKeysResponse'->new($_) } @$_ ] };

declare 'MapStringSampleRowKeysResponse',
    as HashRef[SampleRowKeysResponse()];

declare 'MutateRowRequest',
    as InstanceOf['Google::Bigtable::V2::Bigtable::MutateRowRequest'];

coerce 'MutateRowRequest',
    from HashRef, via { 'Google::Bigtable::V2::Bigtable::MutateRowRequest'->new($_) };

declare 'RepeatedMutateRowRequest',
    as ArrayRef[MutateRowRequest()];

coerce 'RepeatedMutateRowRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::V2::Bigtable::MutateRowRequest'->new($_) } @$_ ] };

declare 'MapStringMutateRowRequest',
    as HashRef[MutateRowRequest()];

declare 'MutateRowResponse',
    as InstanceOf['Google::Bigtable::V2::Bigtable::MutateRowResponse'];

coerce 'MutateRowResponse',
    from HashRef, via { 'Google::Bigtable::V2::Bigtable::MutateRowResponse'->new($_) };

declare 'RepeatedMutateRowResponse',
    as ArrayRef[MutateRowResponse()];

coerce 'RepeatedMutateRowResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::V2::Bigtable::MutateRowResponse'->new($_) } @$_ ] };

declare 'MapStringMutateRowResponse',
    as HashRef[MutateRowResponse()];

declare 'MutateRowsRequest',
    as InstanceOf['Google::Bigtable::V2::Bigtable::MutateRowsRequest'];

coerce 'MutateRowsRequest',
    from HashRef, via { 'Google::Bigtable::V2::Bigtable::MutateRowsRequest'->new($_) };

declare 'RepeatedMutateRowsRequest',
    as ArrayRef[MutateRowsRequest()];

coerce 'RepeatedMutateRowsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::V2::Bigtable::MutateRowsRequest'->new($_) } @$_ ] };

declare 'MapStringMutateRowsRequest',
    as HashRef[MutateRowsRequest()];

declare 'Entry',
    as InstanceOf['Google::Bigtable::V2::Bigtable::MutateRowsRequest::Entry'];

coerce 'Entry',
    from HashRef, via { 'Google::Bigtable::V2::Bigtable::MutateRowsRequest::Entry'->new($_) };

declare 'RepeatedEntry',
    as ArrayRef[Entry()];

coerce 'RepeatedEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::V2::Bigtable::MutateRowsRequest::Entry'->new($_) } @$_ ] };

declare 'MapStringEntry',
    as HashRef[Entry()];

declare 'MutateRowsResponse',
    as InstanceOf['Google::Bigtable::V2::Bigtable::MutateRowsResponse'];

coerce 'MutateRowsResponse',
    from HashRef, via { 'Google::Bigtable::V2::Bigtable::MutateRowsResponse'->new($_) };

declare 'RepeatedMutateRowsResponse',
    as ArrayRef[MutateRowsResponse()];

coerce 'RepeatedMutateRowsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::V2::Bigtable::MutateRowsResponse'->new($_) } @$_ ] };

declare 'MapStringMutateRowsResponse',
    as HashRef[MutateRowsResponse()];

declare 'Entry',
    as InstanceOf['Google::Bigtable::V2::Bigtable::MutateRowsResponse::Entry'];

coerce 'Entry',
    from HashRef, via { 'Google::Bigtable::V2::Bigtable::MutateRowsResponse::Entry'->new($_) };

declare 'RepeatedEntry',
    as ArrayRef[Entry()];

coerce 'RepeatedEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::V2::Bigtable::MutateRowsResponse::Entry'->new($_) } @$_ ] };

declare 'MapStringEntry',
    as HashRef[Entry()];

declare 'RateLimitInfo',
    as InstanceOf['Google::Bigtable::V2::Bigtable::RateLimitInfo'];

coerce 'RateLimitInfo',
    from HashRef, via { 'Google::Bigtable::V2::Bigtable::RateLimitInfo'->new($_) };

declare 'RepeatedRateLimitInfo',
    as ArrayRef[RateLimitInfo()];

coerce 'RepeatedRateLimitInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::V2::Bigtable::RateLimitInfo'->new($_) } @$_ ] };

declare 'MapStringRateLimitInfo',
    as HashRef[RateLimitInfo()];

declare 'CheckAndMutateRowRequest',
    as InstanceOf['Google::Bigtable::V2::Bigtable::CheckAndMutateRowRequest'];

coerce 'CheckAndMutateRowRequest',
    from HashRef, via { 'Google::Bigtable::V2::Bigtable::CheckAndMutateRowRequest'->new($_) };

declare 'RepeatedCheckAndMutateRowRequest',
    as ArrayRef[CheckAndMutateRowRequest()];

coerce 'RepeatedCheckAndMutateRowRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::V2::Bigtable::CheckAndMutateRowRequest'->new($_) } @$_ ] };

declare 'MapStringCheckAndMutateRowRequest',
    as HashRef[CheckAndMutateRowRequest()];

declare 'CheckAndMutateRowResponse',
    as InstanceOf['Google::Bigtable::V2::Bigtable::CheckAndMutateRowResponse'];

coerce 'CheckAndMutateRowResponse',
    from HashRef, via { 'Google::Bigtable::V2::Bigtable::CheckAndMutateRowResponse'->new($_) };

declare 'RepeatedCheckAndMutateRowResponse',
    as ArrayRef[CheckAndMutateRowResponse()];

coerce 'RepeatedCheckAndMutateRowResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::V2::Bigtable::CheckAndMutateRowResponse'->new($_) } @$_ ] };

declare 'MapStringCheckAndMutateRowResponse',
    as HashRef[CheckAndMutateRowResponse()];

declare 'PingAndWarmRequest',
    as InstanceOf['Google::Bigtable::V2::Bigtable::PingAndWarmRequest'];

coerce 'PingAndWarmRequest',
    from HashRef, via { 'Google::Bigtable::V2::Bigtable::PingAndWarmRequest'->new($_) };

declare 'RepeatedPingAndWarmRequest',
    as ArrayRef[PingAndWarmRequest()];

coerce 'RepeatedPingAndWarmRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::V2::Bigtable::PingAndWarmRequest'->new($_) } @$_ ] };

declare 'MapStringPingAndWarmRequest',
    as HashRef[PingAndWarmRequest()];

declare 'PingAndWarmResponse',
    as InstanceOf['Google::Bigtable::V2::Bigtable::PingAndWarmResponse'];

coerce 'PingAndWarmResponse',
    from HashRef, via { 'Google::Bigtable::V2::Bigtable::PingAndWarmResponse'->new($_) };

declare 'RepeatedPingAndWarmResponse',
    as ArrayRef[PingAndWarmResponse()];

coerce 'RepeatedPingAndWarmResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::V2::Bigtable::PingAndWarmResponse'->new($_) } @$_ ] };

declare 'MapStringPingAndWarmResponse',
    as HashRef[PingAndWarmResponse()];

declare 'ReadModifyWriteRowRequest',
    as InstanceOf['Google::Bigtable::V2::Bigtable::ReadModifyWriteRowRequest'];

coerce 'ReadModifyWriteRowRequest',
    from HashRef, via { 'Google::Bigtable::V2::Bigtable::ReadModifyWriteRowRequest'->new($_) };

declare 'RepeatedReadModifyWriteRowRequest',
    as ArrayRef[ReadModifyWriteRowRequest()];

coerce 'RepeatedReadModifyWriteRowRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::V2::Bigtable::ReadModifyWriteRowRequest'->new($_) } @$_ ] };

declare 'MapStringReadModifyWriteRowRequest',
    as HashRef[ReadModifyWriteRowRequest()];

declare 'ReadModifyWriteRowResponse',
    as InstanceOf['Google::Bigtable::V2::Bigtable::ReadModifyWriteRowResponse'];

coerce 'ReadModifyWriteRowResponse',
    from HashRef, via { 'Google::Bigtable::V2::Bigtable::ReadModifyWriteRowResponse'->new($_) };

declare 'RepeatedReadModifyWriteRowResponse',
    as ArrayRef[ReadModifyWriteRowResponse()];

coerce 'RepeatedReadModifyWriteRowResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::V2::Bigtable::ReadModifyWriteRowResponse'->new($_) } @$_ ] };

declare 'MapStringReadModifyWriteRowResponse',
    as HashRef[ReadModifyWriteRowResponse()];

declare 'GenerateInitialChangeStreamPartitionsRequest',
    as InstanceOf['Google::Bigtable::V2::Bigtable::GenerateInitialChangeStreamPartitionsRequest'];

coerce 'GenerateInitialChangeStreamPartitionsRequest',
    from HashRef, via { 'Google::Bigtable::V2::Bigtable::GenerateInitialChangeStreamPartitionsRequest'->new($_) };

declare 'RepeatedGenerateInitialChangeStreamPartitionsRequest',
    as ArrayRef[GenerateInitialChangeStreamPartitionsRequest()];

coerce 'RepeatedGenerateInitialChangeStreamPartitionsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::V2::Bigtable::GenerateInitialChangeStreamPartitionsRequest'->new($_) } @$_ ] };

declare 'MapStringGenerateInitialChangeStreamPartitionsRequest',
    as HashRef[GenerateInitialChangeStreamPartitionsRequest()];

declare 'GenerateInitialChangeStreamPartitionsResponse',
    as InstanceOf['Google::Bigtable::V2::Bigtable::GenerateInitialChangeStreamPartitionsResponse'];

coerce 'GenerateInitialChangeStreamPartitionsResponse',
    from HashRef, via { 'Google::Bigtable::V2::Bigtable::GenerateInitialChangeStreamPartitionsResponse'->new($_) };

declare 'RepeatedGenerateInitialChangeStreamPartitionsResponse',
    as ArrayRef[GenerateInitialChangeStreamPartitionsResponse()];

coerce 'RepeatedGenerateInitialChangeStreamPartitionsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::V2::Bigtable::GenerateInitialChangeStreamPartitionsResponse'->new($_) } @$_ ] };

declare 'MapStringGenerateInitialChangeStreamPartitionsResponse',
    as HashRef[GenerateInitialChangeStreamPartitionsResponse()];

declare 'ReadChangeStreamRequest',
    as InstanceOf['Google::Bigtable::V2::Bigtable::ReadChangeStreamRequest'];

coerce 'ReadChangeStreamRequest',
    from HashRef, via { 'Google::Bigtable::V2::Bigtable::ReadChangeStreamRequest'->new($_) };

declare 'RepeatedReadChangeStreamRequest',
    as ArrayRef[ReadChangeStreamRequest()];

coerce 'RepeatedReadChangeStreamRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::V2::Bigtable::ReadChangeStreamRequest'->new($_) } @$_ ] };

declare 'MapStringReadChangeStreamRequest',
    as HashRef[ReadChangeStreamRequest()];

declare 'ReadChangeStreamResponse',
    as InstanceOf['Google::Bigtable::V2::Bigtable::ReadChangeStreamResponse'];

coerce 'ReadChangeStreamResponse',
    from HashRef, via { 'Google::Bigtable::V2::Bigtable::ReadChangeStreamResponse'->new($_) };

declare 'RepeatedReadChangeStreamResponse',
    as ArrayRef[ReadChangeStreamResponse()];

coerce 'RepeatedReadChangeStreamResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::V2::Bigtable::ReadChangeStreamResponse'->new($_) } @$_ ] };

declare 'MapStringReadChangeStreamResponse',
    as HashRef[ReadChangeStreamResponse()];

declare 'MutationChunk',
    as InstanceOf['Google::Bigtable::V2::Bigtable::ReadChangeStreamResponse::MutationChunk'];

coerce 'MutationChunk',
    from HashRef, via { 'Google::Bigtable::V2::Bigtable::ReadChangeStreamResponse::MutationChunk'->new($_) };

declare 'RepeatedMutationChunk',
    as ArrayRef[MutationChunk()];

coerce 'RepeatedMutationChunk',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::V2::Bigtable::ReadChangeStreamResponse::MutationChunk'->new($_) } @$_ ] };

declare 'MapStringMutationChunk',
    as HashRef[MutationChunk()];

declare 'ChunkInfo',
    as InstanceOf['Google::Bigtable::V2::Bigtable::ReadChangeStreamResponse::MutationChunk::ChunkInfo'];

coerce 'ChunkInfo',
    from HashRef, via { 'Google::Bigtable::V2::Bigtable::ReadChangeStreamResponse::MutationChunk::ChunkInfo'->new($_) };

declare 'RepeatedChunkInfo',
    as ArrayRef[ChunkInfo()];

coerce 'RepeatedChunkInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::V2::Bigtable::ReadChangeStreamResponse::MutationChunk::ChunkInfo'->new($_) } @$_ ] };

declare 'MapStringChunkInfo',
    as HashRef[ChunkInfo()];

declare 'DataChange',
    as InstanceOf['Google::Bigtable::V2::Bigtable::ReadChangeStreamResponse::DataChange'];

coerce 'DataChange',
    from HashRef, via { 'Google::Bigtable::V2::Bigtable::ReadChangeStreamResponse::DataChange'->new($_) };

declare 'RepeatedDataChange',
    as ArrayRef[DataChange()];

coerce 'RepeatedDataChange',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::V2::Bigtable::ReadChangeStreamResponse::DataChange'->new($_) } @$_ ] };

declare 'MapStringDataChange',
    as HashRef[DataChange()];

declare 'Type',
    as (Int | Str);

declare 'Heartbeat',
    as InstanceOf['Google::Bigtable::V2::Bigtable::ReadChangeStreamResponse::Heartbeat'];

coerce 'Heartbeat',
    from HashRef, via { 'Google::Bigtable::V2::Bigtable::ReadChangeStreamResponse::Heartbeat'->new($_) };

declare 'RepeatedHeartbeat',
    as ArrayRef[Heartbeat()];

coerce 'RepeatedHeartbeat',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::V2::Bigtable::ReadChangeStreamResponse::Heartbeat'->new($_) } @$_ ] };

declare 'MapStringHeartbeat',
    as HashRef[Heartbeat()];

declare 'CloseStream',
    as InstanceOf['Google::Bigtable::V2::Bigtable::ReadChangeStreamResponse::CloseStream'];

coerce 'CloseStream',
    from HashRef, via { 'Google::Bigtable::V2::Bigtable::ReadChangeStreamResponse::CloseStream'->new($_) };

declare 'RepeatedCloseStream',
    as ArrayRef[CloseStream()];

coerce 'RepeatedCloseStream',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::V2::Bigtable::ReadChangeStreamResponse::CloseStream'->new($_) } @$_ ] };

declare 'MapStringCloseStream',
    as HashRef[CloseStream()];

declare 'ExecuteQueryRequest',
    as InstanceOf['Google::Bigtable::V2::Bigtable::ExecuteQueryRequest'];

coerce 'ExecuteQueryRequest',
    from HashRef, via { 'Google::Bigtable::V2::Bigtable::ExecuteQueryRequest'->new($_) };

declare 'RepeatedExecuteQueryRequest',
    as ArrayRef[ExecuteQueryRequest()];

coerce 'RepeatedExecuteQueryRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::V2::Bigtable::ExecuteQueryRequest'->new($_) } @$_ ] };

declare 'MapStringExecuteQueryRequest',
    as HashRef[ExecuteQueryRequest()];

declare 'ParamsEntry',
    as InstanceOf['Google::Bigtable::V2::Bigtable::ExecuteQueryRequest::ParamsEntry'];

coerce 'ParamsEntry',
    from HashRef, via { 'Google::Bigtable::V2::Bigtable::ExecuteQueryRequest::ParamsEntry'->new($_) };

declare 'RepeatedParamsEntry',
    as ArrayRef[ParamsEntry()];

coerce 'RepeatedParamsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::V2::Bigtable::ExecuteQueryRequest::ParamsEntry'->new($_) } @$_ ] };

declare 'MapStringParamsEntry',
    as HashRef[ParamsEntry()];

declare 'ViewParametersEntry',
    as InstanceOf['Google::Bigtable::V2::Bigtable::ExecuteQueryRequest::ViewParametersEntry'];

coerce 'ViewParametersEntry',
    from HashRef, via { 'Google::Bigtable::V2::Bigtable::ExecuteQueryRequest::ViewParametersEntry'->new($_) };

declare 'RepeatedViewParametersEntry',
    as ArrayRef[ViewParametersEntry()];

coerce 'RepeatedViewParametersEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::V2::Bigtable::ExecuteQueryRequest::ViewParametersEntry'->new($_) } @$_ ] };

declare 'MapStringViewParametersEntry',
    as HashRef[ViewParametersEntry()];

declare 'ExecuteQueryResponse',
    as InstanceOf['Google::Bigtable::V2::Bigtable::ExecuteQueryResponse'];

coerce 'ExecuteQueryResponse',
    from HashRef, via { 'Google::Bigtable::V2::Bigtable::ExecuteQueryResponse'->new($_) };

declare 'RepeatedExecuteQueryResponse',
    as ArrayRef[ExecuteQueryResponse()];

coerce 'RepeatedExecuteQueryResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::V2::Bigtable::ExecuteQueryResponse'->new($_) } @$_ ] };

declare 'MapStringExecuteQueryResponse',
    as HashRef[ExecuteQueryResponse()];

declare 'PrepareQueryRequest',
    as InstanceOf['Google::Bigtable::V2::Bigtable::PrepareQueryRequest'];

coerce 'PrepareQueryRequest',
    from HashRef, via { 'Google::Bigtable::V2::Bigtable::PrepareQueryRequest'->new($_) };

declare 'RepeatedPrepareQueryRequest',
    as ArrayRef[PrepareQueryRequest()];

coerce 'RepeatedPrepareQueryRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::V2::Bigtable::PrepareQueryRequest'->new($_) } @$_ ] };

declare 'MapStringPrepareQueryRequest',
    as HashRef[PrepareQueryRequest()];

declare 'ParamTypesEntry',
    as InstanceOf['Google::Bigtable::V2::Bigtable::PrepareQueryRequest::ParamTypesEntry'];

coerce 'ParamTypesEntry',
    from HashRef, via { 'Google::Bigtable::V2::Bigtable::PrepareQueryRequest::ParamTypesEntry'->new($_) };

declare 'RepeatedParamTypesEntry',
    as ArrayRef[ParamTypesEntry()];

coerce 'RepeatedParamTypesEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::V2::Bigtable::PrepareQueryRequest::ParamTypesEntry'->new($_) } @$_ ] };

declare 'MapStringParamTypesEntry',
    as HashRef[ParamTypesEntry()];

declare 'PrepareQueryResponse',
    as InstanceOf['Google::Bigtable::V2::Bigtable::PrepareQueryResponse'];

coerce 'PrepareQueryResponse',
    from HashRef, via { 'Google::Bigtable::V2::Bigtable::PrepareQueryResponse'->new($_) };

declare 'RepeatedPrepareQueryResponse',
    as ArrayRef[PrepareQueryResponse()];

coerce 'RepeatedPrepareQueryResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::V2::Bigtable::PrepareQueryResponse'->new($_) } @$_ ] };

declare 'MapStringPrepareQueryResponse',
    as HashRef[PrepareQueryResponse()];

1;

__END__

=head1 NAME

Google::Bigtable::V2::Bigtable::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
