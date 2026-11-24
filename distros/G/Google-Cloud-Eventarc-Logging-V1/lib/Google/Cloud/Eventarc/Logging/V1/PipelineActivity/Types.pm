package Google::Cloud::Eventarc::Logging::V1::PipelineActivity::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'PipelineActivity',
    as InstanceOf['Google::Cloud::Eventarc::Logging::V1::PipelineActivity::PipelineActivity'];

coerce 'PipelineActivity',
    from HashRef, via { 'Google::Cloud::Eventarc::Logging::V1::PipelineActivity::PipelineActivity'->new($_) };

declare 'RepeatedPipelineActivity',
    as ArrayRef[PipelineActivity()];

coerce 'RepeatedPipelineActivity',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Eventarc::Logging::V1::PipelineActivity::PipelineActivity'->new($_) } @$_ ] };

declare 'MapStringPipelineActivity',
    as HashRef[PipelineActivity()];

declare 'PayloadFormat',
    as (Int | Str);

declare 'MessageReceived',
    as InstanceOf['Google::Cloud::Eventarc::Logging::V1::PipelineActivity::PipelineActivity::MessageReceived'];

coerce 'MessageReceived',
    from HashRef, via { 'Google::Cloud::Eventarc::Logging::V1::PipelineActivity::PipelineActivity::MessageReceived'->new($_) };

declare 'RepeatedMessageReceived',
    as ArrayRef[MessageReceived()];

coerce 'RepeatedMessageReceived',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Eventarc::Logging::V1::PipelineActivity::PipelineActivity::MessageReceived'->new($_) } @$_ ] };

declare 'MapStringMessageReceived',
    as HashRef[MessageReceived()];

declare 'MessageTransformed',
    as InstanceOf['Google::Cloud::Eventarc::Logging::V1::PipelineActivity::PipelineActivity::MessageTransformed'];

coerce 'MessageTransformed',
    from HashRef, via { 'Google::Cloud::Eventarc::Logging::V1::PipelineActivity::PipelineActivity::MessageTransformed'->new($_) };

declare 'RepeatedMessageTransformed',
    as ArrayRef[MessageTransformed()];

coerce 'RepeatedMessageTransformed',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Eventarc::Logging::V1::PipelineActivity::PipelineActivity::MessageTransformed'->new($_) } @$_ ] };

declare 'MapStringMessageTransformed',
    as HashRef[MessageTransformed()];

declare 'MessageConverted',
    as InstanceOf['Google::Cloud::Eventarc::Logging::V1::PipelineActivity::PipelineActivity::MessageConverted'];

coerce 'MessageConverted',
    from HashRef, via { 'Google::Cloud::Eventarc::Logging::V1::PipelineActivity::PipelineActivity::MessageConverted'->new($_) };

declare 'RepeatedMessageConverted',
    as ArrayRef[MessageConverted()];

coerce 'RepeatedMessageConverted',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Eventarc::Logging::V1::PipelineActivity::PipelineActivity::MessageConverted'->new($_) } @$_ ] };

declare 'MapStringMessageConverted',
    as HashRef[MessageConverted()];

declare 'MessageRequestDispatched',
    as InstanceOf['Google::Cloud::Eventarc::Logging::V1::PipelineActivity::PipelineActivity::MessageRequestDispatched'];

coerce 'MessageRequestDispatched',
    from HashRef, via { 'Google::Cloud::Eventarc::Logging::V1::PipelineActivity::PipelineActivity::MessageRequestDispatched'->new($_) };

declare 'RepeatedMessageRequestDispatched',
    as ArrayRef[MessageRequestDispatched()];

coerce 'RepeatedMessageRequestDispatched',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Eventarc::Logging::V1::PipelineActivity::PipelineActivity::MessageRequestDispatched'->new($_) } @$_ ] };

declare 'MapStringMessageRequestDispatched',
    as HashRef[MessageRequestDispatched()];

declare 'MessageResponseReceived',
    as InstanceOf['Google::Cloud::Eventarc::Logging::V1::PipelineActivity::PipelineActivity::MessageResponseReceived'];

coerce 'MessageResponseReceived',
    from HashRef, via { 'Google::Cloud::Eventarc::Logging::V1::PipelineActivity::PipelineActivity::MessageResponseReceived'->new($_) };

declare 'RepeatedMessageResponseReceived',
    as ArrayRef[MessageResponseReceived()];

coerce 'RepeatedMessageResponseReceived',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Eventarc::Logging::V1::PipelineActivity::PipelineActivity::MessageResponseReceived'->new($_) } @$_ ] };

declare 'MapStringMessageResponseReceived',
    as HashRef[MessageResponseReceived()];

declare 'RetryStatus',
    as (Int | Str);

declare 'AttributesEntry',
    as InstanceOf['Google::Cloud::Eventarc::Logging::V1::PipelineActivity::PipelineActivity::AttributesEntry'];

coerce 'AttributesEntry',
    from HashRef, via { 'Google::Cloud::Eventarc::Logging::V1::PipelineActivity::PipelineActivity::AttributesEntry'->new($_) };

declare 'RepeatedAttributesEntry',
    as ArrayRef[AttributesEntry()];

coerce 'RepeatedAttributesEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Eventarc::Logging::V1::PipelineActivity::PipelineActivity::AttributesEntry'->new($_) } @$_ ] };

declare 'MapStringAttributesEntry',
    as HashRef[AttributesEntry()];

1;

__END__

=head1 NAME

Google::Cloud::Eventarc::Logging::V1::PipelineActivity::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
