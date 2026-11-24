package Google::Cloud::Dialogflow::Cx::V3beta1::Trace::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'OutputState',
    as (Int | Str);

declare 'RetrievalStrategy',
    as (Int | Str);

declare 'TraceBlock',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3beta1::Trace::TraceBlock'];

coerce 'TraceBlock',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3beta1::Trace::TraceBlock'->new($_) };

declare 'RepeatedTraceBlock',
    as ArrayRef[TraceBlock()];

coerce 'RepeatedTraceBlock',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3beta1::Trace::TraceBlock'->new($_) } @$_ ] };

declare 'MapStringTraceBlock',
    as HashRef[TraceBlock()];

declare 'SpeechProcessingMetadata',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3beta1::Trace::SpeechProcessingMetadata'];

coerce 'SpeechProcessingMetadata',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3beta1::Trace::SpeechProcessingMetadata'->new($_) };

declare 'RepeatedSpeechProcessingMetadata',
    as ArrayRef[SpeechProcessingMetadata()];

coerce 'RepeatedSpeechProcessingMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3beta1::Trace::SpeechProcessingMetadata'->new($_) } @$_ ] };

declare 'MapStringSpeechProcessingMetadata',
    as HashRef[SpeechProcessingMetadata()];

declare 'PlaybookTraceMetadata',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3beta1::Trace::PlaybookTraceMetadata'];

coerce 'PlaybookTraceMetadata',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3beta1::Trace::PlaybookTraceMetadata'->new($_) };

declare 'RepeatedPlaybookTraceMetadata',
    as ArrayRef[PlaybookTraceMetadata()];

coerce 'RepeatedPlaybookTraceMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3beta1::Trace::PlaybookTraceMetadata'->new($_) } @$_ ] };

declare 'MapStringPlaybookTraceMetadata',
    as HashRef[PlaybookTraceMetadata()];

declare 'FlowTraceMetadata',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3beta1::Trace::FlowTraceMetadata'];

coerce 'FlowTraceMetadata',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3beta1::Trace::FlowTraceMetadata'->new($_) };

declare 'RepeatedFlowTraceMetadata',
    as ArrayRef[FlowTraceMetadata()];

coerce 'RepeatedFlowTraceMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3beta1::Trace::FlowTraceMetadata'->new($_) } @$_ ] };

declare 'MapStringFlowTraceMetadata',
    as HashRef[FlowTraceMetadata()];

declare 'Action',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3beta1::Trace::Action'];

coerce 'Action',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3beta1::Trace::Action'->new($_) };

declare 'RepeatedAction',
    as ArrayRef[Action()];

coerce 'RepeatedAction',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3beta1::Trace::Action'->new($_) } @$_ ] };

declare 'MapStringAction',
    as HashRef[Action()];

declare 'IntentMatch',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3beta1::Trace::Action::IntentMatch'];

coerce 'IntentMatch',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3beta1::Trace::Action::IntentMatch'->new($_) };

declare 'RepeatedIntentMatch',
    as ArrayRef[IntentMatch()];

coerce 'RepeatedIntentMatch',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3beta1::Trace::Action::IntentMatch'->new($_) } @$_ ] };

declare 'MapStringIntentMatch',
    as HashRef[IntentMatch()];

declare 'MatchedIntent',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3beta1::Trace::Action::IntentMatch::MatchedIntent'];

coerce 'MatchedIntent',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3beta1::Trace::Action::IntentMatch::MatchedIntent'->new($_) };

declare 'RepeatedMatchedIntent',
    as ArrayRef[MatchedIntent()];

coerce 'RepeatedMatchedIntent',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3beta1::Trace::Action::IntentMatch::MatchedIntent'->new($_) } @$_ ] };

declare 'MapStringMatchedIntent',
    as HashRef[MatchedIntent()];

declare 'FlowStateUpdate',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3beta1::Trace::Action::FlowStateUpdate'];

coerce 'FlowStateUpdate',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3beta1::Trace::Action::FlowStateUpdate'->new($_) };

declare 'RepeatedFlowStateUpdate',
    as ArrayRef[FlowStateUpdate()];

coerce 'RepeatedFlowStateUpdate',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3beta1::Trace::Action::FlowStateUpdate'->new($_) } @$_ ] };

declare 'MapStringFlowStateUpdate',
    as HashRef[FlowStateUpdate()];

declare 'PageState',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3beta1::Trace::Action::FlowStateUpdate::PageState'];

coerce 'PageState',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3beta1::Trace::Action::FlowStateUpdate::PageState'->new($_) };

declare 'RepeatedPageState',
    as ArrayRef[PageState()];

coerce 'RepeatedPageState',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3beta1::Trace::Action::FlowStateUpdate::PageState'->new($_) } @$_ ] };

declare 'MapStringPageState',
    as HashRef[PageState()];

declare 'FunctionCall',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3beta1::Trace::Action::FlowStateUpdate::FunctionCall'];

coerce 'FunctionCall',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3beta1::Trace::Action::FlowStateUpdate::FunctionCall'->new($_) };

declare 'RepeatedFunctionCall',
    as ArrayRef[FunctionCall()];

coerce 'RepeatedFunctionCall',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3beta1::Trace::Action::FlowStateUpdate::FunctionCall'->new($_) } @$_ ] };

declare 'MapStringFunctionCall',
    as HashRef[FunctionCall()];

declare 'TTS',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3beta1::Trace::Action::TTS'];

coerce 'TTS',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3beta1::Trace::Action::TTS'->new($_) };

declare 'RepeatedTTS',
    as ArrayRef[TTS()];

coerce 'RepeatedTTS',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3beta1::Trace::Action::TTS'->new($_) } @$_ ] };

declare 'MapStringTTS',
    as HashRef[TTS()];

declare 'STT',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3beta1::Trace::Action::STT'];

coerce 'STT',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3beta1::Trace::Action::STT'->new($_) };

declare 'RepeatedSTT',
    as ArrayRef[STT()];

coerce 'RepeatedSTT',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3beta1::Trace::Action::STT'->new($_) } @$_ ] };

declare 'MapStringSTT',
    as HashRef[STT()];

declare 'UserUtterance',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3beta1::Trace::UserUtterance'];

coerce 'UserUtterance',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3beta1::Trace::UserUtterance'->new($_) };

declare 'RepeatedUserUtterance',
    as ArrayRef[UserUtterance()];

coerce 'RepeatedUserUtterance',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3beta1::Trace::UserUtterance'->new($_) } @$_ ] };

declare 'MapStringUserUtterance',
    as HashRef[UserUtterance()];

declare 'Event',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3beta1::Trace::Event'];

coerce 'Event',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3beta1::Trace::Event'->new($_) };

declare 'RepeatedEvent',
    as ArrayRef[Event()];

coerce 'RepeatedEvent',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3beta1::Trace::Event'->new($_) } @$_ ] };

declare 'MapStringEvent',
    as HashRef[Event()];

declare 'AgentUtterance',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3beta1::Trace::AgentUtterance'];

coerce 'AgentUtterance',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3beta1::Trace::AgentUtterance'->new($_) };

declare 'RepeatedAgentUtterance',
    as ArrayRef[AgentUtterance()];

coerce 'RepeatedAgentUtterance',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3beta1::Trace::AgentUtterance'->new($_) } @$_ ] };

declare 'MapStringAgentUtterance',
    as HashRef[AgentUtterance()];

declare 'ToolUse',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3beta1::Trace::ToolUse'];

coerce 'ToolUse',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3beta1::Trace::ToolUse'->new($_) };

declare 'RepeatedToolUse',
    as ArrayRef[ToolUse()];

coerce 'RepeatedToolUse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3beta1::Trace::ToolUse'->new($_) } @$_ ] };

declare 'MapStringToolUse',
    as HashRef[ToolUse()];

declare 'DataStoreToolTrace',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3beta1::Trace::ToolUse::DataStoreToolTrace'];

coerce 'DataStoreToolTrace',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3beta1::Trace::ToolUse::DataStoreToolTrace'->new($_) };

declare 'RepeatedDataStoreToolTrace',
    as ArrayRef[DataStoreToolTrace()];

coerce 'RepeatedDataStoreToolTrace',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3beta1::Trace::ToolUse::DataStoreToolTrace'->new($_) } @$_ ] };

declare 'MapStringDataStoreToolTrace',
    as HashRef[DataStoreToolTrace()];

declare 'WebhookToolTrace',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3beta1::Trace::ToolUse::WebhookToolTrace'];

coerce 'WebhookToolTrace',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3beta1::Trace::ToolUse::WebhookToolTrace'->new($_) };

declare 'RepeatedWebhookToolTrace',
    as ArrayRef[WebhookToolTrace()];

coerce 'RepeatedWebhookToolTrace',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3beta1::Trace::ToolUse::WebhookToolTrace'->new($_) } @$_ ] };

declare 'MapStringWebhookToolTrace',
    as HashRef[WebhookToolTrace()];

declare 'LlmCall',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3beta1::Trace::LlmCall'];

coerce 'LlmCall',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3beta1::Trace::LlmCall'->new($_) };

declare 'RepeatedLlmCall',
    as ArrayRef[LlmCall()];

coerce 'RepeatedLlmCall',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3beta1::Trace::LlmCall'->new($_) } @$_ ] };

declare 'MapStringLlmCall',
    as HashRef[LlmCall()];

declare 'RetrievedExample',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3beta1::Trace::LlmCall::RetrievedExample'];

coerce 'RetrievedExample',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3beta1::Trace::LlmCall::RetrievedExample'->new($_) };

declare 'RepeatedRetrievedExample',
    as ArrayRef[RetrievedExample()];

coerce 'RepeatedRetrievedExample',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3beta1::Trace::LlmCall::RetrievedExample'->new($_) } @$_ ] };

declare 'MapStringRetrievedExample',
    as HashRef[RetrievedExample()];

declare 'TokenCount',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3beta1::Trace::LlmCall::TokenCount'];

coerce 'TokenCount',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3beta1::Trace::LlmCall::TokenCount'->new($_) };

declare 'RepeatedTokenCount',
    as ArrayRef[TokenCount()];

coerce 'RepeatedTokenCount',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3beta1::Trace::LlmCall::TokenCount'->new($_) } @$_ ] };

declare 'MapStringTokenCount',
    as HashRef[TokenCount()];

declare 'PlaybookInvocation',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3beta1::Trace::PlaybookInvocation'];

coerce 'PlaybookInvocation',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3beta1::Trace::PlaybookInvocation'->new($_) };

declare 'RepeatedPlaybookInvocation',
    as ArrayRef[PlaybookInvocation()];

coerce 'RepeatedPlaybookInvocation',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3beta1::Trace::PlaybookInvocation'->new($_) } @$_ ] };

declare 'MapStringPlaybookInvocation',
    as HashRef[PlaybookInvocation()];

declare 'FlowInvocation',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3beta1::Trace::FlowInvocation'];

coerce 'FlowInvocation',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3beta1::Trace::FlowInvocation'->new($_) };

declare 'RepeatedFlowInvocation',
    as ArrayRef[FlowInvocation()];

coerce 'RepeatedFlowInvocation',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3beta1::Trace::FlowInvocation'->new($_) } @$_ ] };

declare 'MapStringFlowInvocation',
    as HashRef[FlowInvocation()];

declare 'PlaybookTransition',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3beta1::Trace::PlaybookTransition'];

coerce 'PlaybookTransition',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3beta1::Trace::PlaybookTransition'->new($_) };

declare 'RepeatedPlaybookTransition',
    as ArrayRef[PlaybookTransition()];

coerce 'RepeatedPlaybookTransition',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3beta1::Trace::PlaybookTransition'->new($_) } @$_ ] };

declare 'MapStringPlaybookTransition',
    as HashRef[PlaybookTransition()];

declare 'FlowTransition',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3beta1::Trace::FlowTransition'];

coerce 'FlowTransition',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3beta1::Trace::FlowTransition'->new($_) };

declare 'RepeatedFlowTransition',
    as ArrayRef[FlowTransition()];

coerce 'RepeatedFlowTransition',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3beta1::Trace::FlowTransition'->new($_) } @$_ ] };

declare 'MapStringFlowTransition',
    as HashRef[FlowTransition()];

declare 'PlaybookInput',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3beta1::Trace::PlaybookInput'];

coerce 'PlaybookInput',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3beta1::Trace::PlaybookInput'->new($_) };

declare 'RepeatedPlaybookInput',
    as ArrayRef[PlaybookInput()];

coerce 'RepeatedPlaybookInput',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3beta1::Trace::PlaybookInput'->new($_) } @$_ ] };

declare 'MapStringPlaybookInput',
    as HashRef[PlaybookInput()];

declare 'PlaybookOutput',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3beta1::Trace::PlaybookOutput'];

coerce 'PlaybookOutput',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3beta1::Trace::PlaybookOutput'->new($_) };

declare 'RepeatedPlaybookOutput',
    as ArrayRef[PlaybookOutput()];

coerce 'RepeatedPlaybookOutput',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3beta1::Trace::PlaybookOutput'->new($_) } @$_ ] };

declare 'MapStringPlaybookOutput',
    as HashRef[PlaybookOutput()];

declare 'State',
    as (Int | Str);

declare 'Span',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3beta1::Trace::Span'];

coerce 'Span',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3beta1::Trace::Span'->new($_) };

declare 'RepeatedSpan',
    as ArrayRef[Span()];

coerce 'RepeatedSpan',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3beta1::Trace::Span'->new($_) } @$_ ] };

declare 'MapStringSpan',
    as HashRef[Span()];

declare 'NamedMetric',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3beta1::Trace::NamedMetric'];

coerce 'NamedMetric',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3beta1::Trace::NamedMetric'->new($_) };

declare 'RepeatedNamedMetric',
    as ArrayRef[NamedMetric()];

coerce 'RepeatedNamedMetric',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3beta1::Trace::NamedMetric'->new($_) } @$_ ] };

declare 'MapStringNamedMetric',
    as HashRef[NamedMetric()];

declare 'Status',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3beta1::Trace::Status'];

coerce 'Status',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3beta1::Trace::Status'->new($_) };

declare 'RepeatedStatus',
    as ArrayRef[Status()];

coerce 'RepeatedStatus',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3beta1::Trace::Status'->new($_) } @$_ ] };

declare 'MapStringStatus',
    as HashRef[Status()];

declare 'ExceptionDetail',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3beta1::Trace::ExceptionDetail'];

coerce 'ExceptionDetail',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3beta1::Trace::ExceptionDetail'->new($_) };

declare 'RepeatedExceptionDetail',
    as ArrayRef[ExceptionDetail()];

coerce 'RepeatedExceptionDetail',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3beta1::Trace::ExceptionDetail'->new($_) } @$_ ] };

declare 'MapStringExceptionDetail',
    as HashRef[ExceptionDetail()];

1;

__END__

=head1 NAME

Google::Cloud::Dialogflow::Cx::V3beta1::Trace::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
