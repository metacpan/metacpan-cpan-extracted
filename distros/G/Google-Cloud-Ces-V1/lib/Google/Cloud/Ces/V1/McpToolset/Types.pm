package Google::Cloud::Ces::V1::McpToolset::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'McpToolset',
    as InstanceOf['Google::Cloud::Ces::V1::McpToolset::McpToolset'];

coerce 'McpToolset',
    from HashRef, via { 'Google::Cloud::Ces::V1::McpToolset::McpToolset'->new($_) };

declare 'RepeatedMcpToolset',
    as ArrayRef[McpToolset()];

coerce 'RepeatedMcpToolset',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1::McpToolset::McpToolset'->new($_) } @$_ ] };

declare 'MapStringMcpToolset',
    as HashRef[McpToolset()];

declare 'CustomHeadersEntry',
    as InstanceOf['Google::Cloud::Ces::V1::McpToolset::McpToolset::CustomHeadersEntry'];

coerce 'CustomHeadersEntry',
    from HashRef, via { 'Google::Cloud::Ces::V1::McpToolset::McpToolset::CustomHeadersEntry'->new($_) };

declare 'RepeatedCustomHeadersEntry',
    as ArrayRef[CustomHeadersEntry()];

coerce 'RepeatedCustomHeadersEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1::McpToolset::McpToolset::CustomHeadersEntry'->new($_) } @$_ ] };

declare 'MapStringCustomHeadersEntry',
    as HashRef[CustomHeadersEntry()];

declare 'McpToolOverride',
    as InstanceOf['Google::Cloud::Ces::V1::McpToolset::McpToolOverride'];

coerce 'McpToolOverride',
    from HashRef, via { 'Google::Cloud::Ces::V1::McpToolset::McpToolOverride'->new($_) };

declare 'RepeatedMcpToolOverride',
    as ArrayRef[McpToolOverride()];

coerce 'RepeatedMcpToolOverride',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1::McpToolset::McpToolOverride'->new($_) } @$_ ] };

declare 'MapStringMcpToolOverride',
    as HashRef[McpToolOverride()];

declare 'McpToolDefinition',
    as InstanceOf['Google::Cloud::Ces::V1::McpToolset::McpToolDefinition'];

coerce 'McpToolDefinition',
    from HashRef, via { 'Google::Cloud::Ces::V1::McpToolset::McpToolDefinition'->new($_) };

declare 'RepeatedMcpToolDefinition',
    as ArrayRef[McpToolDefinition()];

coerce 'RepeatedMcpToolDefinition',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1::McpToolset::McpToolDefinition'->new($_) } @$_ ] };

declare 'MapStringMcpToolDefinition',
    as HashRef[McpToolDefinition()];

1;

__END__

=head1 NAME

Google::Cloud::Ces::V1::McpToolset::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
