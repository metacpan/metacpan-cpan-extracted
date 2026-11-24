package Google::Cloud::Ces::V1::AgentCard::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'AgentCard',
    as InstanceOf['Google::Cloud::Ces::V1::AgentCard::AgentCard'];

coerce 'AgentCard',
    from HashRef, via { 'Google::Cloud::Ces::V1::AgentCard::AgentCard'->new($_) };

declare 'RepeatedAgentCard',
    as ArrayRef[AgentCard()];

coerce 'RepeatedAgentCard',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1::AgentCard::AgentCard'->new($_) } @$_ ] };

declare 'MapStringAgentCard',
    as HashRef[AgentCard()];

declare 'AgentInterface',
    as InstanceOf['Google::Cloud::Ces::V1::AgentCard::AgentInterface'];

coerce 'AgentInterface',
    from HashRef, via { 'Google::Cloud::Ces::V1::AgentCard::AgentInterface'->new($_) };

declare 'RepeatedAgentInterface',
    as ArrayRef[AgentInterface()];

coerce 'RepeatedAgentInterface',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1::AgentCard::AgentInterface'->new($_) } @$_ ] };

declare 'MapStringAgentInterface',
    as HashRef[AgentInterface()];

declare 'AgentSkill',
    as InstanceOf['Google::Cloud::Ces::V1::AgentCard::AgentSkill'];

coerce 'AgentSkill',
    from HashRef, via { 'Google::Cloud::Ces::V1::AgentCard::AgentSkill'->new($_) };

declare 'RepeatedAgentSkill',
    as ArrayRef[AgentSkill()];

coerce 'RepeatedAgentSkill',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1::AgentCard::AgentSkill'->new($_) } @$_ ] };

declare 'MapStringAgentSkill',
    as HashRef[AgentSkill()];

declare 'RemoteAgentTool',
    as InstanceOf['Google::Cloud::Ces::V1::AgentCard::RemoteAgentTool'];

coerce 'RemoteAgentTool',
    from HashRef, via { 'Google::Cloud::Ces::V1::AgentCard::RemoteAgentTool'->new($_) };

declare 'RepeatedRemoteAgentTool',
    as ArrayRef[RemoteAgentTool()];

coerce 'RepeatedRemoteAgentTool',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1::AgentCard::RemoteAgentTool'->new($_) } @$_ ] };

declare 'MapStringRemoteAgentTool',
    as HashRef[RemoteAgentTool()];

declare 'InputVariableMappingEntry',
    as InstanceOf['Google::Cloud::Ces::V1::AgentCard::RemoteAgentTool::InputVariableMappingEntry'];

coerce 'InputVariableMappingEntry',
    from HashRef, via { 'Google::Cloud::Ces::V1::AgentCard::RemoteAgentTool::InputVariableMappingEntry'->new($_) };

declare 'RepeatedInputVariableMappingEntry',
    as ArrayRef[InputVariableMappingEntry()];

coerce 'RepeatedInputVariableMappingEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1::AgentCard::RemoteAgentTool::InputVariableMappingEntry'->new($_) } @$_ ] };

declare 'MapStringInputVariableMappingEntry',
    as HashRef[InputVariableMappingEntry()];

declare 'OutputVariableMappingEntry',
    as InstanceOf['Google::Cloud::Ces::V1::AgentCard::RemoteAgentTool::OutputVariableMappingEntry'];

coerce 'OutputVariableMappingEntry',
    from HashRef, via { 'Google::Cloud::Ces::V1::AgentCard::RemoteAgentTool::OutputVariableMappingEntry'->new($_) };

declare 'RepeatedOutputVariableMappingEntry',
    as ArrayRef[OutputVariableMappingEntry()];

coerce 'RepeatedOutputVariableMappingEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1::AgentCard::RemoteAgentTool::OutputVariableMappingEntry'->new($_) } @$_ ] };

declare 'MapStringOutputVariableMappingEntry',
    as HashRef[OutputVariableMappingEntry()];

1;

__END__

=head1 NAME

Google::Cloud::Ces::V1::AgentCard::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
