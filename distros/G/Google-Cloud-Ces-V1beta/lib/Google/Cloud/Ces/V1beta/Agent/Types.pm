package Google::Cloud::Ces::V1beta::Agent::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Agent',
    as InstanceOf['Google::Cloud::Ces::V1beta::Agent::Agent'];

coerce 'Agent',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::Agent::Agent'->new($_) };

declare 'RepeatedAgent',
    as ArrayRef[Agent()];

coerce 'RepeatedAgent',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::Agent::Agent'->new($_) } @$_ ] };

declare 'MapStringAgent',
    as HashRef[Agent()];

declare 'LlmAgent',
    as InstanceOf['Google::Cloud::Ces::V1beta::Agent::Agent::LlmAgent'];

coerce 'LlmAgent',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::Agent::Agent::LlmAgent'->new($_) };

declare 'RepeatedLlmAgent',
    as ArrayRef[LlmAgent()];

coerce 'RepeatedLlmAgent',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::Agent::Agent::LlmAgent'->new($_) } @$_ ] };

declare 'MapStringLlmAgent',
    as HashRef[LlmAgent()];

declare 'RemoteDialogflowAgent',
    as InstanceOf['Google::Cloud::Ces::V1beta::Agent::Agent::RemoteDialogflowAgent'];

coerce 'RemoteDialogflowAgent',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::Agent::Agent::RemoteDialogflowAgent'->new($_) };

declare 'RepeatedRemoteDialogflowAgent',
    as ArrayRef[RemoteDialogflowAgent()];

coerce 'RepeatedRemoteDialogflowAgent',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::Agent::Agent::RemoteDialogflowAgent'->new($_) } @$_ ] };

declare 'MapStringRemoteDialogflowAgent',
    as HashRef[RemoteDialogflowAgent()];

declare 'InputVariableMappingEntry',
    as InstanceOf['Google::Cloud::Ces::V1beta::Agent::Agent::RemoteDialogflowAgent::InputVariableMappingEntry'];

coerce 'InputVariableMappingEntry',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::Agent::Agent::RemoteDialogflowAgent::InputVariableMappingEntry'->new($_) };

declare 'RepeatedInputVariableMappingEntry',
    as ArrayRef[InputVariableMappingEntry()];

coerce 'RepeatedInputVariableMappingEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::Agent::Agent::RemoteDialogflowAgent::InputVariableMappingEntry'->new($_) } @$_ ] };

declare 'MapStringInputVariableMappingEntry',
    as HashRef[InputVariableMappingEntry()];

declare 'OutputVariableMappingEntry',
    as InstanceOf['Google::Cloud::Ces::V1beta::Agent::Agent::RemoteDialogflowAgent::OutputVariableMappingEntry'];

coerce 'OutputVariableMappingEntry',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::Agent::Agent::RemoteDialogflowAgent::OutputVariableMappingEntry'->new($_) };

declare 'RepeatedOutputVariableMappingEntry',
    as ArrayRef[OutputVariableMappingEntry()];

coerce 'RepeatedOutputVariableMappingEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::Agent::Agent::RemoteDialogflowAgent::OutputVariableMappingEntry'->new($_) } @$_ ] };

declare 'MapStringOutputVariableMappingEntry',
    as HashRef[OutputVariableMappingEntry()];

declare 'RemoteA2aAgent',
    as InstanceOf['Google::Cloud::Ces::V1beta::Agent::Agent::RemoteA2aAgent'];

coerce 'RemoteA2aAgent',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::Agent::Agent::RemoteA2aAgent'->new($_) };

declare 'RepeatedRemoteA2aAgent',
    as ArrayRef[RemoteA2aAgent()];

coerce 'RepeatedRemoteA2aAgent',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::Agent::Agent::RemoteA2aAgent'->new($_) } @$_ ] };

declare 'MapStringRemoteA2aAgent',
    as HashRef[RemoteA2aAgent()];

declare 'AgentToolset',
    as InstanceOf['Google::Cloud::Ces::V1beta::Agent::Agent::AgentToolset'];

coerce 'AgentToolset',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::Agent::Agent::AgentToolset'->new($_) };

declare 'RepeatedAgentToolset',
    as ArrayRef[AgentToolset()];

coerce 'RepeatedAgentToolset',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::Agent::Agent::AgentToolset'->new($_) } @$_ ] };

declare 'MapStringAgentToolset',
    as HashRef[AgentToolset()];

1;

__END__

=head1 NAME

Google::Cloud::Ces::V1beta::Agent::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
