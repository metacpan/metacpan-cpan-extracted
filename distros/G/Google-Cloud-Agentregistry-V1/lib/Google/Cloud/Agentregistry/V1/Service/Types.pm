package Google::Cloud::Agentregistry::V1::Service::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Service',
    as InstanceOf['Google::Cloud::Agentregistry::V1::Service::Service'];

coerce 'Service',
    from HashRef, via { 'Google::Cloud::Agentregistry::V1::Service::Service'->new($_) };

declare 'RepeatedService',
    as ArrayRef[Service()];

coerce 'RepeatedService',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Agentregistry::V1::Service::Service'->new($_) } @$_ ] };

declare 'MapStringService',
    as HashRef[Service()];

declare 'AgentSpec',
    as InstanceOf['Google::Cloud::Agentregistry::V1::Service::Service::AgentSpec'];

coerce 'AgentSpec',
    from HashRef, via { 'Google::Cloud::Agentregistry::V1::Service::Service::AgentSpec'->new($_) };

declare 'RepeatedAgentSpec',
    as ArrayRef[AgentSpec()];

coerce 'RepeatedAgentSpec',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Agentregistry::V1::Service::Service::AgentSpec'->new($_) } @$_ ] };

declare 'MapStringAgentSpec',
    as HashRef[AgentSpec()];

declare 'Type',
    as (Int | Str);

declare 'McpServerSpec',
    as InstanceOf['Google::Cloud::Agentregistry::V1::Service::Service::McpServerSpec'];

coerce 'McpServerSpec',
    from HashRef, via { 'Google::Cloud::Agentregistry::V1::Service::Service::McpServerSpec'->new($_) };

declare 'RepeatedMcpServerSpec',
    as ArrayRef[McpServerSpec()];

coerce 'RepeatedMcpServerSpec',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Agentregistry::V1::Service::Service::McpServerSpec'->new($_) } @$_ ] };

declare 'MapStringMcpServerSpec',
    as HashRef[McpServerSpec()];

declare 'Type',
    as (Int | Str);

declare 'EndpointSpec',
    as InstanceOf['Google::Cloud::Agentregistry::V1::Service::Service::EndpointSpec'];

coerce 'EndpointSpec',
    from HashRef, via { 'Google::Cloud::Agentregistry::V1::Service::Service::EndpointSpec'->new($_) };

declare 'RepeatedEndpointSpec',
    as ArrayRef[EndpointSpec()];

coerce 'RepeatedEndpointSpec',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Agentregistry::V1::Service::Service::EndpointSpec'->new($_) } @$_ ] };

declare 'MapStringEndpointSpec',
    as HashRef[EndpointSpec()];

declare 'Type',
    as (Int | Str);

1;

__END__

=head1 NAME

Google::Cloud::Agentregistry::V1::Service::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
