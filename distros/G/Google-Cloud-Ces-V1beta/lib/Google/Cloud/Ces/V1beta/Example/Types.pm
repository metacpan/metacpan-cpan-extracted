package Google::Cloud::Ces::V1beta::Example::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Example',
    as InstanceOf['Google::Cloud::Ces::V1beta::Example::Example'];

coerce 'Example',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::Example::Example'->new($_) };

declare 'RepeatedExample',
    as ArrayRef[Example()];

coerce 'RepeatedExample',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::Example::Example'->new($_) } @$_ ] };

declare 'MapStringExample',
    as HashRef[Example()];

declare 'Message',
    as InstanceOf['Google::Cloud::Ces::V1beta::Example::Message'];

coerce 'Message',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::Example::Message'->new($_) };

declare 'RepeatedMessage',
    as ArrayRef[Message()];

coerce 'RepeatedMessage',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::Example::Message'->new($_) } @$_ ] };

declare 'MapStringMessage',
    as HashRef[Message()];

declare 'Chunk',
    as InstanceOf['Google::Cloud::Ces::V1beta::Example::Chunk'];

coerce 'Chunk',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::Example::Chunk'->new($_) };

declare 'RepeatedChunk',
    as ArrayRef[Chunk()];

coerce 'RepeatedChunk',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::Example::Chunk'->new($_) } @$_ ] };

declare 'MapStringChunk',
    as HashRef[Chunk()];

declare 'Blob',
    as InstanceOf['Google::Cloud::Ces::V1beta::Example::Blob'];

coerce 'Blob',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::Example::Blob'->new($_) };

declare 'RepeatedBlob',
    as ArrayRef[Blob()];

coerce 'RepeatedBlob',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::Example::Blob'->new($_) } @$_ ] };

declare 'MapStringBlob',
    as HashRef[Blob()];

declare 'Image',
    as InstanceOf['Google::Cloud::Ces::V1beta::Example::Image'];

coerce 'Image',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::Example::Image'->new($_) };

declare 'RepeatedImage',
    as ArrayRef[Image()];

coerce 'RepeatedImage',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::Example::Image'->new($_) } @$_ ] };

declare 'MapStringImage',
    as HashRef[Image()];

declare 'ToolCall',
    as InstanceOf['Google::Cloud::Ces::V1beta::Example::ToolCall'];

coerce 'ToolCall',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::Example::ToolCall'->new($_) };

declare 'RepeatedToolCall',
    as ArrayRef[ToolCall()];

coerce 'RepeatedToolCall',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::Example::ToolCall'->new($_) } @$_ ] };

declare 'MapStringToolCall',
    as HashRef[ToolCall()];

declare 'ToolResponse',
    as InstanceOf['Google::Cloud::Ces::V1beta::Example::ToolResponse'];

coerce 'ToolResponse',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::Example::ToolResponse'->new($_) };

declare 'RepeatedToolResponse',
    as ArrayRef[ToolResponse()];

coerce 'RepeatedToolResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::Example::ToolResponse'->new($_) } @$_ ] };

declare 'MapStringToolResponse',
    as HashRef[ToolResponse()];

declare 'AgentTransfer',
    as InstanceOf['Google::Cloud::Ces::V1beta::Example::AgentTransfer'];

coerce 'AgentTransfer',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::Example::AgentTransfer'->new($_) };

declare 'RepeatedAgentTransfer',
    as ArrayRef[AgentTransfer()];

coerce 'RepeatedAgentTransfer',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::Example::AgentTransfer'->new($_) } @$_ ] };

declare 'MapStringAgentTransfer',
    as HashRef[AgentTransfer()];

1;

__END__

=head1 NAME

Google::Cloud::Ces::V1beta::Example::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
