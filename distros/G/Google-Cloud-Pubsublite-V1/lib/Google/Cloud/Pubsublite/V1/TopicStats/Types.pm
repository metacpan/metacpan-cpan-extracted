package Google::Cloud::Pubsublite::V1::TopicStats::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'ComputeMessageStatsRequest',
    as InstanceOf['Google::Cloud::Pubsublite::V1::TopicStats::ComputeMessageStatsRequest'];

coerce 'ComputeMessageStatsRequest',
    from HashRef, via { 'Google::Cloud::Pubsublite::V1::TopicStats::ComputeMessageStatsRequest'->new($_) };

declare 'RepeatedComputeMessageStatsRequest',
    as ArrayRef[ComputeMessageStatsRequest()];

coerce 'RepeatedComputeMessageStatsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Pubsublite::V1::TopicStats::ComputeMessageStatsRequest'->new($_) } @$_ ] };

declare 'MapStringComputeMessageStatsRequest',
    as HashRef[ComputeMessageStatsRequest()];

declare 'ComputeMessageStatsResponse',
    as InstanceOf['Google::Cloud::Pubsublite::V1::TopicStats::ComputeMessageStatsResponse'];

coerce 'ComputeMessageStatsResponse',
    from HashRef, via { 'Google::Cloud::Pubsublite::V1::TopicStats::ComputeMessageStatsResponse'->new($_) };

declare 'RepeatedComputeMessageStatsResponse',
    as ArrayRef[ComputeMessageStatsResponse()];

coerce 'RepeatedComputeMessageStatsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Pubsublite::V1::TopicStats::ComputeMessageStatsResponse'->new($_) } @$_ ] };

declare 'MapStringComputeMessageStatsResponse',
    as HashRef[ComputeMessageStatsResponse()];

declare 'ComputeHeadCursorRequest',
    as InstanceOf['Google::Cloud::Pubsublite::V1::TopicStats::ComputeHeadCursorRequest'];

coerce 'ComputeHeadCursorRequest',
    from HashRef, via { 'Google::Cloud::Pubsublite::V1::TopicStats::ComputeHeadCursorRequest'->new($_) };

declare 'RepeatedComputeHeadCursorRequest',
    as ArrayRef[ComputeHeadCursorRequest()];

coerce 'RepeatedComputeHeadCursorRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Pubsublite::V1::TopicStats::ComputeHeadCursorRequest'->new($_) } @$_ ] };

declare 'MapStringComputeHeadCursorRequest',
    as HashRef[ComputeHeadCursorRequest()];

declare 'ComputeHeadCursorResponse',
    as InstanceOf['Google::Cloud::Pubsublite::V1::TopicStats::ComputeHeadCursorResponse'];

coerce 'ComputeHeadCursorResponse',
    from HashRef, via { 'Google::Cloud::Pubsublite::V1::TopicStats::ComputeHeadCursorResponse'->new($_) };

declare 'RepeatedComputeHeadCursorResponse',
    as ArrayRef[ComputeHeadCursorResponse()];

coerce 'RepeatedComputeHeadCursorResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Pubsublite::V1::TopicStats::ComputeHeadCursorResponse'->new($_) } @$_ ] };

declare 'MapStringComputeHeadCursorResponse',
    as HashRef[ComputeHeadCursorResponse()];

declare 'ComputeTimeCursorRequest',
    as InstanceOf['Google::Cloud::Pubsublite::V1::TopicStats::ComputeTimeCursorRequest'];

coerce 'ComputeTimeCursorRequest',
    from HashRef, via { 'Google::Cloud::Pubsublite::V1::TopicStats::ComputeTimeCursorRequest'->new($_) };

declare 'RepeatedComputeTimeCursorRequest',
    as ArrayRef[ComputeTimeCursorRequest()];

coerce 'RepeatedComputeTimeCursorRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Pubsublite::V1::TopicStats::ComputeTimeCursorRequest'->new($_) } @$_ ] };

declare 'MapStringComputeTimeCursorRequest',
    as HashRef[ComputeTimeCursorRequest()];

declare 'ComputeTimeCursorResponse',
    as InstanceOf['Google::Cloud::Pubsublite::V1::TopicStats::ComputeTimeCursorResponse'];

coerce 'ComputeTimeCursorResponse',
    from HashRef, via { 'Google::Cloud::Pubsublite::V1::TopicStats::ComputeTimeCursorResponse'->new($_) };

declare 'RepeatedComputeTimeCursorResponse',
    as ArrayRef[ComputeTimeCursorResponse()];

coerce 'RepeatedComputeTimeCursorResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Pubsublite::V1::TopicStats::ComputeTimeCursorResponse'->new($_) } @$_ ] };

declare 'MapStringComputeTimeCursorResponse',
    as HashRef[ComputeTimeCursorResponse()];

1;

__END__

=head1 NAME

Google::Cloud::Pubsublite::V1::TopicStats::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
