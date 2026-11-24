package Google::Cloud::Apiregistry::V1::Resources::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'McpServer',
    as InstanceOf['Google::Cloud::Apiregistry::V1::Resources::McpServer'];

coerce 'McpServer',
    from HashRef, via { 'Google::Cloud::Apiregistry::V1::Resources::McpServer'->new($_) };

declare 'RepeatedMcpServer',
    as ArrayRef[McpServer()];

coerce 'RepeatedMcpServer',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apiregistry::V1::Resources::McpServer'->new($_) } @$_ ] };

declare 'MapStringMcpServer',
    as HashRef[McpServer()];

declare 'McpTool',
    as InstanceOf['Google::Cloud::Apiregistry::V1::Resources::McpTool'];

coerce 'McpTool',
    from HashRef, via { 'Google::Cloud::Apiregistry::V1::Resources::McpTool'->new($_) };

declare 'RepeatedMcpTool',
    as ArrayRef[McpTool()];

coerce 'RepeatedMcpTool',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apiregistry::V1::Resources::McpTool'->new($_) } @$_ ] };

declare 'MapStringMcpTool',
    as HashRef[McpTool()];

1;

__END__

=head1 NAME

Google::Cloud::Apiregistry::V1::Resources::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
