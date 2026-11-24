package Google::Cloud::Discoveryengine::V1beta::AgentGatewaySetting::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'AgentGatewaySetting',
    as InstanceOf['Google::Cloud::Discoveryengine::V1beta::AgentGatewaySetting::AgentGatewaySetting'];

coerce 'AgentGatewaySetting',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1beta::AgentGatewaySetting::AgentGatewaySetting'->new($_) };

declare 'RepeatedAgentGatewaySetting',
    as ArrayRef[AgentGatewaySetting()];

coerce 'RepeatedAgentGatewaySetting',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1beta::AgentGatewaySetting::AgentGatewaySetting'->new($_) } @$_ ] };

declare 'MapStringAgentGatewaySetting',
    as HashRef[AgentGatewaySetting()];

declare 'AgentGatewayReference',
    as InstanceOf['Google::Cloud::Discoveryengine::V1beta::AgentGatewaySetting::AgentGatewaySetting::AgentGatewayReference'];

coerce 'AgentGatewayReference',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1beta::AgentGatewaySetting::AgentGatewaySetting::AgentGatewayReference'->new($_) };

declare 'RepeatedAgentGatewayReference',
    as ArrayRef[AgentGatewayReference()];

coerce 'RepeatedAgentGatewayReference',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1beta::AgentGatewaySetting::AgentGatewaySetting::AgentGatewayReference'->new($_) } @$_ ] };

declare 'MapStringAgentGatewayReference',
    as HashRef[AgentGatewayReference()];

1;

__END__

=head1 NAME

Google::Cloud::Discoveryengine::V1beta::AgentGatewaySetting::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
