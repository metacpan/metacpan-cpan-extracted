package Google::Cloud::Pubsublite::V1::Cursor::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'InitialCommitCursorRequest',
    as InstanceOf['Google::Cloud::Pubsublite::V1::Cursor::InitialCommitCursorRequest'];

coerce 'InitialCommitCursorRequest',
    from HashRef, via { 'Google::Cloud::Pubsublite::V1::Cursor::InitialCommitCursorRequest'->new($_) };

declare 'RepeatedInitialCommitCursorRequest',
    as ArrayRef[InitialCommitCursorRequest()];

coerce 'RepeatedInitialCommitCursorRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Pubsublite::V1::Cursor::InitialCommitCursorRequest'->new($_) } @$_ ] };

declare 'MapStringInitialCommitCursorRequest',
    as HashRef[InitialCommitCursorRequest()];

declare 'InitialCommitCursorResponse',
    as InstanceOf['Google::Cloud::Pubsublite::V1::Cursor::InitialCommitCursorResponse'];

coerce 'InitialCommitCursorResponse',
    from HashRef, via { 'Google::Cloud::Pubsublite::V1::Cursor::InitialCommitCursorResponse'->new($_) };

declare 'RepeatedInitialCommitCursorResponse',
    as ArrayRef[InitialCommitCursorResponse()];

coerce 'RepeatedInitialCommitCursorResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Pubsublite::V1::Cursor::InitialCommitCursorResponse'->new($_) } @$_ ] };

declare 'MapStringInitialCommitCursorResponse',
    as HashRef[InitialCommitCursorResponse()];

declare 'SequencedCommitCursorRequest',
    as InstanceOf['Google::Cloud::Pubsublite::V1::Cursor::SequencedCommitCursorRequest'];

coerce 'SequencedCommitCursorRequest',
    from HashRef, via { 'Google::Cloud::Pubsublite::V1::Cursor::SequencedCommitCursorRequest'->new($_) };

declare 'RepeatedSequencedCommitCursorRequest',
    as ArrayRef[SequencedCommitCursorRequest()];

coerce 'RepeatedSequencedCommitCursorRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Pubsublite::V1::Cursor::SequencedCommitCursorRequest'->new($_) } @$_ ] };

declare 'MapStringSequencedCommitCursorRequest',
    as HashRef[SequencedCommitCursorRequest()];

declare 'SequencedCommitCursorResponse',
    as InstanceOf['Google::Cloud::Pubsublite::V1::Cursor::SequencedCommitCursorResponse'];

coerce 'SequencedCommitCursorResponse',
    from HashRef, via { 'Google::Cloud::Pubsublite::V1::Cursor::SequencedCommitCursorResponse'->new($_) };

declare 'RepeatedSequencedCommitCursorResponse',
    as ArrayRef[SequencedCommitCursorResponse()];

coerce 'RepeatedSequencedCommitCursorResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Pubsublite::V1::Cursor::SequencedCommitCursorResponse'->new($_) } @$_ ] };

declare 'MapStringSequencedCommitCursorResponse',
    as HashRef[SequencedCommitCursorResponse()];

declare 'StreamingCommitCursorRequest',
    as InstanceOf['Google::Cloud::Pubsublite::V1::Cursor::StreamingCommitCursorRequest'];

coerce 'StreamingCommitCursorRequest',
    from HashRef, via { 'Google::Cloud::Pubsublite::V1::Cursor::StreamingCommitCursorRequest'->new($_) };

declare 'RepeatedStreamingCommitCursorRequest',
    as ArrayRef[StreamingCommitCursorRequest()];

coerce 'RepeatedStreamingCommitCursorRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Pubsublite::V1::Cursor::StreamingCommitCursorRequest'->new($_) } @$_ ] };

declare 'MapStringStreamingCommitCursorRequest',
    as HashRef[StreamingCommitCursorRequest()];

declare 'StreamingCommitCursorResponse',
    as InstanceOf['Google::Cloud::Pubsublite::V1::Cursor::StreamingCommitCursorResponse'];

coerce 'StreamingCommitCursorResponse',
    from HashRef, via { 'Google::Cloud::Pubsublite::V1::Cursor::StreamingCommitCursorResponse'->new($_) };

declare 'RepeatedStreamingCommitCursorResponse',
    as ArrayRef[StreamingCommitCursorResponse()];

coerce 'RepeatedStreamingCommitCursorResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Pubsublite::V1::Cursor::StreamingCommitCursorResponse'->new($_) } @$_ ] };

declare 'MapStringStreamingCommitCursorResponse',
    as HashRef[StreamingCommitCursorResponse()];

declare 'CommitCursorRequest',
    as InstanceOf['Google::Cloud::Pubsublite::V1::Cursor::CommitCursorRequest'];

coerce 'CommitCursorRequest',
    from HashRef, via { 'Google::Cloud::Pubsublite::V1::Cursor::CommitCursorRequest'->new($_) };

declare 'RepeatedCommitCursorRequest',
    as ArrayRef[CommitCursorRequest()];

coerce 'RepeatedCommitCursorRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Pubsublite::V1::Cursor::CommitCursorRequest'->new($_) } @$_ ] };

declare 'MapStringCommitCursorRequest',
    as HashRef[CommitCursorRequest()];

declare 'CommitCursorResponse',
    as InstanceOf['Google::Cloud::Pubsublite::V1::Cursor::CommitCursorResponse'];

coerce 'CommitCursorResponse',
    from HashRef, via { 'Google::Cloud::Pubsublite::V1::Cursor::CommitCursorResponse'->new($_) };

declare 'RepeatedCommitCursorResponse',
    as ArrayRef[CommitCursorResponse()];

coerce 'RepeatedCommitCursorResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Pubsublite::V1::Cursor::CommitCursorResponse'->new($_) } @$_ ] };

declare 'MapStringCommitCursorResponse',
    as HashRef[CommitCursorResponse()];

declare 'ListPartitionCursorsRequest',
    as InstanceOf['Google::Cloud::Pubsublite::V1::Cursor::ListPartitionCursorsRequest'];

coerce 'ListPartitionCursorsRequest',
    from HashRef, via { 'Google::Cloud::Pubsublite::V1::Cursor::ListPartitionCursorsRequest'->new($_) };

declare 'RepeatedListPartitionCursorsRequest',
    as ArrayRef[ListPartitionCursorsRequest()];

coerce 'RepeatedListPartitionCursorsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Pubsublite::V1::Cursor::ListPartitionCursorsRequest'->new($_) } @$_ ] };

declare 'MapStringListPartitionCursorsRequest',
    as HashRef[ListPartitionCursorsRequest()];

declare 'PartitionCursor',
    as InstanceOf['Google::Cloud::Pubsublite::V1::Cursor::PartitionCursor'];

coerce 'PartitionCursor',
    from HashRef, via { 'Google::Cloud::Pubsublite::V1::Cursor::PartitionCursor'->new($_) };

declare 'RepeatedPartitionCursor',
    as ArrayRef[PartitionCursor()];

coerce 'RepeatedPartitionCursor',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Pubsublite::V1::Cursor::PartitionCursor'->new($_) } @$_ ] };

declare 'MapStringPartitionCursor',
    as HashRef[PartitionCursor()];

declare 'ListPartitionCursorsResponse',
    as InstanceOf['Google::Cloud::Pubsublite::V1::Cursor::ListPartitionCursorsResponse'];

coerce 'ListPartitionCursorsResponse',
    from HashRef, via { 'Google::Cloud::Pubsublite::V1::Cursor::ListPartitionCursorsResponse'->new($_) };

declare 'RepeatedListPartitionCursorsResponse',
    as ArrayRef[ListPartitionCursorsResponse()];

coerce 'RepeatedListPartitionCursorsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Pubsublite::V1::Cursor::ListPartitionCursorsResponse'->new($_) } @$_ ] };

declare 'MapStringListPartitionCursorsResponse',
    as HashRef[ListPartitionCursorsResponse()];

1;

__END__

=head1 NAME

Google::Cloud::Pubsublite::V1::Cursor::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
