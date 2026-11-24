package Google::Cloud::Ces::V1beta::McpTool::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'McpTool',
    as InstanceOf['Google::Cloud::Ces::V1beta::McpTool::McpTool'];

coerce 'McpTool',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::McpTool::McpTool'->new($_) };

declare 'RepeatedMcpTool',
    as ArrayRef[McpTool()];

coerce 'RepeatedMcpTool',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::McpTool::McpTool'->new($_) } @$_ ] };

declare 'MapStringMcpTool',
    as HashRef[McpTool()];

declare 'State',
    as (Int | Str);

declare 'CustomHeadersEntry',
    as InstanceOf['Google::Cloud::Ces::V1beta::McpTool::McpTool::CustomHeadersEntry'];

coerce 'CustomHeadersEntry',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::McpTool::McpTool::CustomHeadersEntry'->new($_) };

declare 'RepeatedCustomHeadersEntry',
    as ArrayRef[CustomHeadersEntry()];

coerce 'RepeatedCustomHeadersEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::McpTool::McpTool::CustomHeadersEntry'->new($_) } @$_ ] };

declare 'MapStringCustomHeadersEntry',
    as HashRef[CustomHeadersEntry()];

1;

__END__

=head1 NAME

Google::Cloud::Ces::V1beta::McpTool::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
