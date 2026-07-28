package Google::Dataflow::V1beta3::Messages::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'JobMessageImportance',
    as (Int | Str);

declare 'JobMessage',
    as InstanceOf['Google::Dataflow::V1beta3::Messages::JobMessage'];

coerce 'JobMessage',
    from HashRef, via { 'Google::Dataflow::V1beta3::Messages::JobMessage'->new($_) };

declare 'RepeatedJobMessage',
    as ArrayRef[JobMessage()];

coerce 'RepeatedJobMessage',
    from ArrayRef[HashRef], via { [ map { 'Google::Dataflow::V1beta3::Messages::JobMessage'->new($_) } @$_ ] };

declare 'MapStringJobMessage',
    as HashRef[JobMessage()];

declare 'StructuredMessage',
    as InstanceOf['Google::Dataflow::V1beta3::Messages::StructuredMessage'];

coerce 'StructuredMessage',
    from HashRef, via { 'Google::Dataflow::V1beta3::Messages::StructuredMessage'->new($_) };

declare 'RepeatedStructuredMessage',
    as ArrayRef[StructuredMessage()];

coerce 'RepeatedStructuredMessage',
    from ArrayRef[HashRef], via { [ map { 'Google::Dataflow::V1beta3::Messages::StructuredMessage'->new($_) } @$_ ] };

declare 'MapStringStructuredMessage',
    as HashRef[StructuredMessage()];

declare 'Parameter',
    as InstanceOf['Google::Dataflow::V1beta3::Messages::StructuredMessage::Parameter'];

coerce 'Parameter',
    from HashRef, via { 'Google::Dataflow::V1beta3::Messages::StructuredMessage::Parameter'->new($_) };

declare 'RepeatedParameter',
    as ArrayRef[Parameter()];

coerce 'RepeatedParameter',
    from ArrayRef[HashRef], via { [ map { 'Google::Dataflow::V1beta3::Messages::StructuredMessage::Parameter'->new($_) } @$_ ] };

declare 'MapStringParameter',
    as HashRef[Parameter()];

declare 'AutoscalingEvent',
    as InstanceOf['Google::Dataflow::V1beta3::Messages::AutoscalingEvent'];

coerce 'AutoscalingEvent',
    from HashRef, via { 'Google::Dataflow::V1beta3::Messages::AutoscalingEvent'->new($_) };

declare 'RepeatedAutoscalingEvent',
    as ArrayRef[AutoscalingEvent()];

coerce 'RepeatedAutoscalingEvent',
    from ArrayRef[HashRef], via { [ map { 'Google::Dataflow::V1beta3::Messages::AutoscalingEvent'->new($_) } @$_ ] };

declare 'MapStringAutoscalingEvent',
    as HashRef[AutoscalingEvent()];

declare 'AutoscalingEventType',
    as (Int | Str);

declare 'ListJobMessagesRequest',
    as InstanceOf['Google::Dataflow::V1beta3::Messages::ListJobMessagesRequest'];

coerce 'ListJobMessagesRequest',
    from HashRef, via { 'Google::Dataflow::V1beta3::Messages::ListJobMessagesRequest'->new($_) };

declare 'RepeatedListJobMessagesRequest',
    as ArrayRef[ListJobMessagesRequest()];

coerce 'RepeatedListJobMessagesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Dataflow::V1beta3::Messages::ListJobMessagesRequest'->new($_) } @$_ ] };

declare 'MapStringListJobMessagesRequest',
    as HashRef[ListJobMessagesRequest()];

declare 'ListJobMessagesResponse',
    as InstanceOf['Google::Dataflow::V1beta3::Messages::ListJobMessagesResponse'];

coerce 'ListJobMessagesResponse',
    from HashRef, via { 'Google::Dataflow::V1beta3::Messages::ListJobMessagesResponse'->new($_) };

declare 'RepeatedListJobMessagesResponse',
    as ArrayRef[ListJobMessagesResponse()];

coerce 'RepeatedListJobMessagesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Dataflow::V1beta3::Messages::ListJobMessagesResponse'->new($_) } @$_ ] };

declare 'MapStringListJobMessagesResponse',
    as HashRef[ListJobMessagesResponse()];

1;

__END__

=head1 NAME

Google::Dataflow::V1beta3::Messages::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
