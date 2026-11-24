package Google::Cloud::Pubsublite::V1::Subscriber::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'InitialSubscribeRequest',
    as InstanceOf['Google::Cloud::Pubsublite::V1::Subscriber::InitialSubscribeRequest'];

coerce 'InitialSubscribeRequest',
    from HashRef, via { 'Google::Cloud::Pubsublite::V1::Subscriber::InitialSubscribeRequest'->new($_) };

declare 'RepeatedInitialSubscribeRequest',
    as ArrayRef[InitialSubscribeRequest()];

coerce 'RepeatedInitialSubscribeRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Pubsublite::V1::Subscriber::InitialSubscribeRequest'->new($_) } @$_ ] };

declare 'MapStringInitialSubscribeRequest',
    as HashRef[InitialSubscribeRequest()];

declare 'InitialSubscribeResponse',
    as InstanceOf['Google::Cloud::Pubsublite::V1::Subscriber::InitialSubscribeResponse'];

coerce 'InitialSubscribeResponse',
    from HashRef, via { 'Google::Cloud::Pubsublite::V1::Subscriber::InitialSubscribeResponse'->new($_) };

declare 'RepeatedInitialSubscribeResponse',
    as ArrayRef[InitialSubscribeResponse()];

coerce 'RepeatedInitialSubscribeResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Pubsublite::V1::Subscriber::InitialSubscribeResponse'->new($_) } @$_ ] };

declare 'MapStringInitialSubscribeResponse',
    as HashRef[InitialSubscribeResponse()];

declare 'SeekRequest',
    as InstanceOf['Google::Cloud::Pubsublite::V1::Subscriber::SeekRequest'];

coerce 'SeekRequest',
    from HashRef, via { 'Google::Cloud::Pubsublite::V1::Subscriber::SeekRequest'->new($_) };

declare 'RepeatedSeekRequest',
    as ArrayRef[SeekRequest()];

coerce 'RepeatedSeekRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Pubsublite::V1::Subscriber::SeekRequest'->new($_) } @$_ ] };

declare 'MapStringSeekRequest',
    as HashRef[SeekRequest()];

declare 'NamedTarget',
    as (Int | Str);

declare 'SeekResponse',
    as InstanceOf['Google::Cloud::Pubsublite::V1::Subscriber::SeekResponse'];

coerce 'SeekResponse',
    from HashRef, via { 'Google::Cloud::Pubsublite::V1::Subscriber::SeekResponse'->new($_) };

declare 'RepeatedSeekResponse',
    as ArrayRef[SeekResponse()];

coerce 'RepeatedSeekResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Pubsublite::V1::Subscriber::SeekResponse'->new($_) } @$_ ] };

declare 'MapStringSeekResponse',
    as HashRef[SeekResponse()];

declare 'FlowControlRequest',
    as InstanceOf['Google::Cloud::Pubsublite::V1::Subscriber::FlowControlRequest'];

coerce 'FlowControlRequest',
    from HashRef, via { 'Google::Cloud::Pubsublite::V1::Subscriber::FlowControlRequest'->new($_) };

declare 'RepeatedFlowControlRequest',
    as ArrayRef[FlowControlRequest()];

coerce 'RepeatedFlowControlRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Pubsublite::V1::Subscriber::FlowControlRequest'->new($_) } @$_ ] };

declare 'MapStringFlowControlRequest',
    as HashRef[FlowControlRequest()];

declare 'SubscribeRequest',
    as InstanceOf['Google::Cloud::Pubsublite::V1::Subscriber::SubscribeRequest'];

coerce 'SubscribeRequest',
    from HashRef, via { 'Google::Cloud::Pubsublite::V1::Subscriber::SubscribeRequest'->new($_) };

declare 'RepeatedSubscribeRequest',
    as ArrayRef[SubscribeRequest()];

coerce 'RepeatedSubscribeRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Pubsublite::V1::Subscriber::SubscribeRequest'->new($_) } @$_ ] };

declare 'MapStringSubscribeRequest',
    as HashRef[SubscribeRequest()];

declare 'MessageResponse',
    as InstanceOf['Google::Cloud::Pubsublite::V1::Subscriber::MessageResponse'];

coerce 'MessageResponse',
    from HashRef, via { 'Google::Cloud::Pubsublite::V1::Subscriber::MessageResponse'->new($_) };

declare 'RepeatedMessageResponse',
    as ArrayRef[MessageResponse()];

coerce 'RepeatedMessageResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Pubsublite::V1::Subscriber::MessageResponse'->new($_) } @$_ ] };

declare 'MapStringMessageResponse',
    as HashRef[MessageResponse()];

declare 'SubscribeResponse',
    as InstanceOf['Google::Cloud::Pubsublite::V1::Subscriber::SubscribeResponse'];

coerce 'SubscribeResponse',
    from HashRef, via { 'Google::Cloud::Pubsublite::V1::Subscriber::SubscribeResponse'->new($_) };

declare 'RepeatedSubscribeResponse',
    as ArrayRef[SubscribeResponse()];

coerce 'RepeatedSubscribeResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Pubsublite::V1::Subscriber::SubscribeResponse'->new($_) } @$_ ] };

declare 'MapStringSubscribeResponse',
    as HashRef[SubscribeResponse()];

declare 'InitialPartitionAssignmentRequest',
    as InstanceOf['Google::Cloud::Pubsublite::V1::Subscriber::InitialPartitionAssignmentRequest'];

coerce 'InitialPartitionAssignmentRequest',
    from HashRef, via { 'Google::Cloud::Pubsublite::V1::Subscriber::InitialPartitionAssignmentRequest'->new($_) };

declare 'RepeatedInitialPartitionAssignmentRequest',
    as ArrayRef[InitialPartitionAssignmentRequest()];

coerce 'RepeatedInitialPartitionAssignmentRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Pubsublite::V1::Subscriber::InitialPartitionAssignmentRequest'->new($_) } @$_ ] };

declare 'MapStringInitialPartitionAssignmentRequest',
    as HashRef[InitialPartitionAssignmentRequest()];

declare 'PartitionAssignment',
    as InstanceOf['Google::Cloud::Pubsublite::V1::Subscriber::PartitionAssignment'];

coerce 'PartitionAssignment',
    from HashRef, via { 'Google::Cloud::Pubsublite::V1::Subscriber::PartitionAssignment'->new($_) };

declare 'RepeatedPartitionAssignment',
    as ArrayRef[PartitionAssignment()];

coerce 'RepeatedPartitionAssignment',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Pubsublite::V1::Subscriber::PartitionAssignment'->new($_) } @$_ ] };

declare 'MapStringPartitionAssignment',
    as HashRef[PartitionAssignment()];

declare 'PartitionAssignmentAck',
    as InstanceOf['Google::Cloud::Pubsublite::V1::Subscriber::PartitionAssignmentAck'];

coerce 'PartitionAssignmentAck',
    from HashRef, via { 'Google::Cloud::Pubsublite::V1::Subscriber::PartitionAssignmentAck'->new($_) };

declare 'RepeatedPartitionAssignmentAck',
    as ArrayRef[PartitionAssignmentAck()];

coerce 'RepeatedPartitionAssignmentAck',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Pubsublite::V1::Subscriber::PartitionAssignmentAck'->new($_) } @$_ ] };

declare 'MapStringPartitionAssignmentAck',
    as HashRef[PartitionAssignmentAck()];

declare 'PartitionAssignmentRequest',
    as InstanceOf['Google::Cloud::Pubsublite::V1::Subscriber::PartitionAssignmentRequest'];

coerce 'PartitionAssignmentRequest',
    from HashRef, via { 'Google::Cloud::Pubsublite::V1::Subscriber::PartitionAssignmentRequest'->new($_) };

declare 'RepeatedPartitionAssignmentRequest',
    as ArrayRef[PartitionAssignmentRequest()];

coerce 'RepeatedPartitionAssignmentRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Pubsublite::V1::Subscriber::PartitionAssignmentRequest'->new($_) } @$_ ] };

declare 'MapStringPartitionAssignmentRequest',
    as HashRef[PartitionAssignmentRequest()];

1;

__END__

=head1 NAME

Google::Cloud::Pubsublite::V1::Subscriber::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
