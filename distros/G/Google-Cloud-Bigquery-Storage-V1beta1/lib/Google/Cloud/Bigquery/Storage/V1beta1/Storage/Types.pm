package Google::Cloud::Bigquery::Storage::V1beta1::Storage::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'DataFormat',
    as (Int | Str);

declare 'ShardingStrategy',
    as (Int | Str);

declare 'Stream',
    as InstanceOf['Google::Cloud::Bigquery::Storage::V1beta1::Storage::Stream'];

coerce 'Stream',
    from HashRef, via { 'Google::Cloud::Bigquery::Storage::V1beta1::Storage::Stream'->new($_) };

declare 'RepeatedStream',
    as ArrayRef[Stream()];

coerce 'RepeatedStream',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Storage::V1beta1::Storage::Stream'->new($_) } @$_ ] };

declare 'MapStringStream',
    as HashRef[Stream()];

declare 'StreamPosition',
    as InstanceOf['Google::Cloud::Bigquery::Storage::V1beta1::Storage::StreamPosition'];

coerce 'StreamPosition',
    from HashRef, via { 'Google::Cloud::Bigquery::Storage::V1beta1::Storage::StreamPosition'->new($_) };

declare 'RepeatedStreamPosition',
    as ArrayRef[StreamPosition()];

coerce 'RepeatedStreamPosition',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Storage::V1beta1::Storage::StreamPosition'->new($_) } @$_ ] };

declare 'MapStringStreamPosition',
    as HashRef[StreamPosition()];

declare 'ReadSession',
    as InstanceOf['Google::Cloud::Bigquery::Storage::V1beta1::Storage::ReadSession'];

coerce 'ReadSession',
    from HashRef, via { 'Google::Cloud::Bigquery::Storage::V1beta1::Storage::ReadSession'->new($_) };

declare 'RepeatedReadSession',
    as ArrayRef[ReadSession()];

coerce 'RepeatedReadSession',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Storage::V1beta1::Storage::ReadSession'->new($_) } @$_ ] };

declare 'MapStringReadSession',
    as HashRef[ReadSession()];

declare 'CreateReadSessionRequest',
    as InstanceOf['Google::Cloud::Bigquery::Storage::V1beta1::Storage::CreateReadSessionRequest'];

coerce 'CreateReadSessionRequest',
    from HashRef, via { 'Google::Cloud::Bigquery::Storage::V1beta1::Storage::CreateReadSessionRequest'->new($_) };

declare 'RepeatedCreateReadSessionRequest',
    as ArrayRef[CreateReadSessionRequest()];

coerce 'RepeatedCreateReadSessionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Storage::V1beta1::Storage::CreateReadSessionRequest'->new($_) } @$_ ] };

declare 'MapStringCreateReadSessionRequest',
    as HashRef[CreateReadSessionRequest()];

declare 'ReadRowsRequest',
    as InstanceOf['Google::Cloud::Bigquery::Storage::V1beta1::Storage::ReadRowsRequest'];

coerce 'ReadRowsRequest',
    from HashRef, via { 'Google::Cloud::Bigquery::Storage::V1beta1::Storage::ReadRowsRequest'->new($_) };

declare 'RepeatedReadRowsRequest',
    as ArrayRef[ReadRowsRequest()];

coerce 'RepeatedReadRowsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Storage::V1beta1::Storage::ReadRowsRequest'->new($_) } @$_ ] };

declare 'MapStringReadRowsRequest',
    as HashRef[ReadRowsRequest()];

declare 'StreamStatus',
    as InstanceOf['Google::Cloud::Bigquery::Storage::V1beta1::Storage::StreamStatus'];

coerce 'StreamStatus',
    from HashRef, via { 'Google::Cloud::Bigquery::Storage::V1beta1::Storage::StreamStatus'->new($_) };

declare 'RepeatedStreamStatus',
    as ArrayRef[StreamStatus()];

coerce 'RepeatedStreamStatus',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Storage::V1beta1::Storage::StreamStatus'->new($_) } @$_ ] };

declare 'MapStringStreamStatus',
    as HashRef[StreamStatus()];

declare 'Progress',
    as InstanceOf['Google::Cloud::Bigquery::Storage::V1beta1::Storage::Progress'];

coerce 'Progress',
    from HashRef, via { 'Google::Cloud::Bigquery::Storage::V1beta1::Storage::Progress'->new($_) };

declare 'RepeatedProgress',
    as ArrayRef[Progress()];

coerce 'RepeatedProgress',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Storage::V1beta1::Storage::Progress'->new($_) } @$_ ] };

declare 'MapStringProgress',
    as HashRef[Progress()];

declare 'ThrottleStatus',
    as InstanceOf['Google::Cloud::Bigquery::Storage::V1beta1::Storage::ThrottleStatus'];

coerce 'ThrottleStatus',
    from HashRef, via { 'Google::Cloud::Bigquery::Storage::V1beta1::Storage::ThrottleStatus'->new($_) };

declare 'RepeatedThrottleStatus',
    as ArrayRef[ThrottleStatus()];

coerce 'RepeatedThrottleStatus',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Storage::V1beta1::Storage::ThrottleStatus'->new($_) } @$_ ] };

declare 'MapStringThrottleStatus',
    as HashRef[ThrottleStatus()];

declare 'ReadRowsResponse',
    as InstanceOf['Google::Cloud::Bigquery::Storage::V1beta1::Storage::ReadRowsResponse'];

coerce 'ReadRowsResponse',
    from HashRef, via { 'Google::Cloud::Bigquery::Storage::V1beta1::Storage::ReadRowsResponse'->new($_) };

declare 'RepeatedReadRowsResponse',
    as ArrayRef[ReadRowsResponse()];

coerce 'RepeatedReadRowsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Storage::V1beta1::Storage::ReadRowsResponse'->new($_) } @$_ ] };

declare 'MapStringReadRowsResponse',
    as HashRef[ReadRowsResponse()];

declare 'BatchCreateReadSessionStreamsRequest',
    as InstanceOf['Google::Cloud::Bigquery::Storage::V1beta1::Storage::BatchCreateReadSessionStreamsRequest'];

coerce 'BatchCreateReadSessionStreamsRequest',
    from HashRef, via { 'Google::Cloud::Bigquery::Storage::V1beta1::Storage::BatchCreateReadSessionStreamsRequest'->new($_) };

declare 'RepeatedBatchCreateReadSessionStreamsRequest',
    as ArrayRef[BatchCreateReadSessionStreamsRequest()];

coerce 'RepeatedBatchCreateReadSessionStreamsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Storage::V1beta1::Storage::BatchCreateReadSessionStreamsRequest'->new($_) } @$_ ] };

declare 'MapStringBatchCreateReadSessionStreamsRequest',
    as HashRef[BatchCreateReadSessionStreamsRequest()];

declare 'BatchCreateReadSessionStreamsResponse',
    as InstanceOf['Google::Cloud::Bigquery::Storage::V1beta1::Storage::BatchCreateReadSessionStreamsResponse'];

coerce 'BatchCreateReadSessionStreamsResponse',
    from HashRef, via { 'Google::Cloud::Bigquery::Storage::V1beta1::Storage::BatchCreateReadSessionStreamsResponse'->new($_) };

declare 'RepeatedBatchCreateReadSessionStreamsResponse',
    as ArrayRef[BatchCreateReadSessionStreamsResponse()];

coerce 'RepeatedBatchCreateReadSessionStreamsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Storage::V1beta1::Storage::BatchCreateReadSessionStreamsResponse'->new($_) } @$_ ] };

declare 'MapStringBatchCreateReadSessionStreamsResponse',
    as HashRef[BatchCreateReadSessionStreamsResponse()];

declare 'FinalizeStreamRequest',
    as InstanceOf['Google::Cloud::Bigquery::Storage::V1beta1::Storage::FinalizeStreamRequest'];

coerce 'FinalizeStreamRequest',
    from HashRef, via { 'Google::Cloud::Bigquery::Storage::V1beta1::Storage::FinalizeStreamRequest'->new($_) };

declare 'RepeatedFinalizeStreamRequest',
    as ArrayRef[FinalizeStreamRequest()];

coerce 'RepeatedFinalizeStreamRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Storage::V1beta1::Storage::FinalizeStreamRequest'->new($_) } @$_ ] };

declare 'MapStringFinalizeStreamRequest',
    as HashRef[FinalizeStreamRequest()];

declare 'SplitReadStreamRequest',
    as InstanceOf['Google::Cloud::Bigquery::Storage::V1beta1::Storage::SplitReadStreamRequest'];

coerce 'SplitReadStreamRequest',
    from HashRef, via { 'Google::Cloud::Bigquery::Storage::V1beta1::Storage::SplitReadStreamRequest'->new($_) };

declare 'RepeatedSplitReadStreamRequest',
    as ArrayRef[SplitReadStreamRequest()];

coerce 'RepeatedSplitReadStreamRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Storage::V1beta1::Storage::SplitReadStreamRequest'->new($_) } @$_ ] };

declare 'MapStringSplitReadStreamRequest',
    as HashRef[SplitReadStreamRequest()];

declare 'SplitReadStreamResponse',
    as InstanceOf['Google::Cloud::Bigquery::Storage::V1beta1::Storage::SplitReadStreamResponse'];

coerce 'SplitReadStreamResponse',
    from HashRef, via { 'Google::Cloud::Bigquery::Storage::V1beta1::Storage::SplitReadStreamResponse'->new($_) };

declare 'RepeatedSplitReadStreamResponse',
    as ArrayRef[SplitReadStreamResponse()];

coerce 'RepeatedSplitReadStreamResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Storage::V1beta1::Storage::SplitReadStreamResponse'->new($_) } @$_ ] };

declare 'MapStringSplitReadStreamResponse',
    as HashRef[SplitReadStreamResponse()];

1;

__END__

=head1 NAME

Google::Cloud::Bigquery::Storage::V1beta1::Storage::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
