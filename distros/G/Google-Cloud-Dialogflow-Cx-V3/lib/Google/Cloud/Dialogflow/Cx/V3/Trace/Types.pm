package Google::Cloud::Dialogflow::Cx::V3::Trace::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'OutputState',
    as (Int | Str);

declare 'TraceBlock',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3::Trace::TraceBlock'];

coerce 'TraceBlock',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3::Trace::TraceBlock'->new($_) };

declare 'RepeatedTraceBlock',
    as ArrayRef[TraceBlock()];

coerce 'RepeatedTraceBlock',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3::Trace::TraceBlock'->new($_) } @$_ ] };

declare 'MapStringTraceBlock',
    as HashRef[TraceBlock()];

declare 'SpeechProcessingMetadata',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3::Trace::SpeechProcessingMetadata'];

coerce 'SpeechProcessingMetadata',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3::Trace::SpeechProcessingMetadata'->new($_) };

declare 'RepeatedSpeechProcessingMetadata',
    as ArrayRef[SpeechProcessingMetadata()];

coerce 'RepeatedSpeechProcessingMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3::Trace::SpeechProcessingMetadata'->new($_) } @$_ ] };

declare 'MapStringSpeechProcessingMetadata',
    as HashRef[SpeechProcessingMetadata()];

declare 'PlaybookTraceMetadata',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3::Trace::PlaybookTraceMetadata'];

coerce 'PlaybookTraceMetadata',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3::Trace::PlaybookTraceMetadata'->new($_) };

declare 'RepeatedPlaybookTraceMetadata',
    as ArrayRef[PlaybookTraceMetadata()];

coerce 'RepeatedPlaybookTraceMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3::Trace::PlaybookTraceMetadata'->new($_) } @$_ ] };

declare 'MapStringPlaybookTraceMetadata',
    as HashRef[PlaybookTraceMetadata()];

declare 'FlowTraceMetadata',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3::Trace::FlowTraceMetadata'];

coerce 'FlowTraceMetadata',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3::Trace::FlowTraceMetadata'->new($_) };

declare 'RepeatedFlowTraceMetadata',
    as ArrayRef[FlowTraceMetadata()];

coerce 'RepeatedFlowTraceMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3::Trace::FlowTraceMetadata'->new($_) } @$_ ] };

declare 'MapStringFlowTraceMetadata',
    as HashRef[FlowTraceMetadata()];

declare 'PlaybookInput',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3::Trace::PlaybookInput'];

coerce 'PlaybookInput',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3::Trace::PlaybookInput'->new($_) };

declare 'RepeatedPlaybookInput',
    as ArrayRef[PlaybookInput()];

coerce 'RepeatedPlaybookInput',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3::Trace::PlaybookInput'->new($_) } @$_ ] };

declare 'MapStringPlaybookInput',
    as HashRef[PlaybookInput()];

declare 'PlaybookOutput',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3::Trace::PlaybookOutput'];

coerce 'PlaybookOutput',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3::Trace::PlaybookOutput'->new($_) };

declare 'RepeatedPlaybookOutput',
    as ArrayRef[PlaybookOutput()];

coerce 'RepeatedPlaybookOutput',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3::Trace::PlaybookOutput'->new($_) } @$_ ] };

declare 'MapStringPlaybookOutput',
    as HashRef[PlaybookOutput()];

declare 'Action',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3::Trace::Action'];

coerce 'Action',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3::Trace::Action'->new($_) };

declare 'RepeatedAction',
    as ArrayRef[Action()];

coerce 'RepeatedAction',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3::Trace::Action'->new($_) } @$_ ] };

declare 'MapStringAction',
    as HashRef[Action()];

declare 'UserUtterance',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3::Trace::UserUtterance'];

coerce 'UserUtterance',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3::Trace::UserUtterance'->new($_) };

declare 'RepeatedUserUtterance',
    as ArrayRef[UserUtterance()];

coerce 'RepeatedUserUtterance',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3::Trace::UserUtterance'->new($_) } @$_ ] };

declare 'MapStringUserUtterance',
    as HashRef[UserUtterance()];

declare 'AgentUtterance',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3::Trace::AgentUtterance'];

coerce 'AgentUtterance',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3::Trace::AgentUtterance'->new($_) };

declare 'RepeatedAgentUtterance',
    as ArrayRef[AgentUtterance()];

coerce 'RepeatedAgentUtterance',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3::Trace::AgentUtterance'->new($_) } @$_ ] };

declare 'MapStringAgentUtterance',
    as HashRef[AgentUtterance()];

declare 'ToolUse',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3::Trace::ToolUse'];

coerce 'ToolUse',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3::Trace::ToolUse'->new($_) };

declare 'RepeatedToolUse',
    as ArrayRef[ToolUse()];

coerce 'RepeatedToolUse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3::Trace::ToolUse'->new($_) } @$_ ] };

declare 'MapStringToolUse',
    as HashRef[ToolUse()];

declare 'PlaybookInvocation',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3::Trace::PlaybookInvocation'];

coerce 'PlaybookInvocation',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3::Trace::PlaybookInvocation'->new($_) };

declare 'RepeatedPlaybookInvocation',
    as ArrayRef[PlaybookInvocation()];

coerce 'RepeatedPlaybookInvocation',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3::Trace::PlaybookInvocation'->new($_) } @$_ ] };

declare 'MapStringPlaybookInvocation',
    as HashRef[PlaybookInvocation()];

declare 'FlowInvocation',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3::Trace::FlowInvocation'];

coerce 'FlowInvocation',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3::Trace::FlowInvocation'->new($_) };

declare 'RepeatedFlowInvocation',
    as ArrayRef[FlowInvocation()];

coerce 'RepeatedFlowInvocation',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3::Trace::FlowInvocation'->new($_) } @$_ ] };

declare 'MapStringFlowInvocation',
    as HashRef[FlowInvocation()];

declare 'PlaybookTransition',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3::Trace::PlaybookTransition'];

coerce 'PlaybookTransition',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3::Trace::PlaybookTransition'->new($_) };

declare 'RepeatedPlaybookTransition',
    as ArrayRef[PlaybookTransition()];

coerce 'RepeatedPlaybookTransition',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3::Trace::PlaybookTransition'->new($_) } @$_ ] };

declare 'MapStringPlaybookTransition',
    as HashRef[PlaybookTransition()];

declare 'FlowTransition',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3::Trace::FlowTransition'];

coerce 'FlowTransition',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3::Trace::FlowTransition'->new($_) };

declare 'RepeatedFlowTransition',
    as ArrayRef[FlowTransition()];

coerce 'RepeatedFlowTransition',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3::Trace::FlowTransition'->new($_) } @$_ ] };

declare 'MapStringFlowTransition',
    as HashRef[FlowTransition()];

1;

__END__

=head1 NAME

Google::Cloud::Dialogflow::Cx::V3::Trace::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
