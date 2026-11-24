package Google::Cloud::Agentregistry::V1::McpServer::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'McpServer',
    as InstanceOf['Google::Cloud::Agentregistry::V1::McpServer::McpServer'];

coerce 'McpServer',
    from HashRef, via { 'Google::Cloud::Agentregistry::V1::McpServer::McpServer'->new($_) };

declare 'RepeatedMcpServer',
    as ArrayRef[McpServer()];

coerce 'RepeatedMcpServer',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Agentregistry::V1::McpServer::McpServer'->new($_) } @$_ ] };

declare 'MapStringMcpServer',
    as HashRef[McpServer()];

declare 'Tool',
    as InstanceOf['Google::Cloud::Agentregistry::V1::McpServer::McpServer::Tool'];

coerce 'Tool',
    from HashRef, via { 'Google::Cloud::Agentregistry::V1::McpServer::McpServer::Tool'->new($_) };

declare 'RepeatedTool',
    as ArrayRef[Tool()];

coerce 'RepeatedTool',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Agentregistry::V1::McpServer::McpServer::Tool'->new($_) } @$_ ] };

declare 'MapStringTool',
    as HashRef[Tool()];

declare 'Annotations',
    as InstanceOf['Google::Cloud::Agentregistry::V1::McpServer::McpServer::Tool::Annotations'];

coerce 'Annotations',
    from HashRef, via { 'Google::Cloud::Agentregistry::V1::McpServer::McpServer::Tool::Annotations'->new($_) };

declare 'RepeatedAnnotations',
    as ArrayRef[Annotations()];

coerce 'RepeatedAnnotations',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Agentregistry::V1::McpServer::McpServer::Tool::Annotations'->new($_) } @$_ ] };

declare 'MapStringAnnotations',
    as HashRef[Annotations()];

declare 'AttributesEntry',
    as InstanceOf['Google::Cloud::Agentregistry::V1::McpServer::McpServer::AttributesEntry'];

coerce 'AttributesEntry',
    from HashRef, via { 'Google::Cloud::Agentregistry::V1::McpServer::McpServer::AttributesEntry'->new($_) };

declare 'RepeatedAttributesEntry',
    as ArrayRef[AttributesEntry()];

coerce 'RepeatedAttributesEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Agentregistry::V1::McpServer::McpServer::AttributesEntry'->new($_) } @$_ ] };

declare 'MapStringAttributesEntry',
    as HashRef[AttributesEntry()];

1;

__END__

=head1 NAME

Google::Cloud::Agentregistry::V1::McpServer::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
