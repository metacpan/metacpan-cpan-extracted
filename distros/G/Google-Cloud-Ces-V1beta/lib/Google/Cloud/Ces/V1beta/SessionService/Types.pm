package Google::Cloud::Ces::V1beta::SessionService::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'AudioEncoding',
    as (Int | Str);

declare 'MockConfig',
    as InstanceOf['Google::Cloud::Ces::V1beta::SessionService::MockConfig'];

coerce 'MockConfig',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::SessionService::MockConfig'->new($_) };

declare 'RepeatedMockConfig',
    as ArrayRef[MockConfig()];

coerce 'RepeatedMockConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::SessionService::MockConfig'->new($_) } @$_ ] };

declare 'MapStringMockConfig',
    as HashRef[MockConfig()];

declare 'UnmatchedToolCallBehavior',
    as (Int | Str);

declare 'InputAudioConfig',
    as InstanceOf['Google::Cloud::Ces::V1beta::SessionService::InputAudioConfig'];

coerce 'InputAudioConfig',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::SessionService::InputAudioConfig'->new($_) };

declare 'RepeatedInputAudioConfig',
    as ArrayRef[InputAudioConfig()];

coerce 'RepeatedInputAudioConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::SessionService::InputAudioConfig'->new($_) } @$_ ] };

declare 'MapStringInputAudioConfig',
    as HashRef[InputAudioConfig()];

declare 'OutputAudioConfig',
    as InstanceOf['Google::Cloud::Ces::V1beta::SessionService::OutputAudioConfig'];

coerce 'OutputAudioConfig',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::SessionService::OutputAudioConfig'->new($_) };

declare 'RepeatedOutputAudioConfig',
    as ArrayRef[OutputAudioConfig()];

coerce 'RepeatedOutputAudioConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::SessionService::OutputAudioConfig'->new($_) } @$_ ] };

declare 'MapStringOutputAudioConfig',
    as HashRef[OutputAudioConfig()];

declare 'SessionConfig',
    as InstanceOf['Google::Cloud::Ces::V1beta::SessionService::SessionConfig'];

coerce 'SessionConfig',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::SessionService::SessionConfig'->new($_) };

declare 'RepeatedSessionConfig',
    as ArrayRef[SessionConfig()];

coerce 'RepeatedSessionConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::SessionService::SessionConfig'->new($_) } @$_ ] };

declare 'MapStringSessionConfig',
    as HashRef[SessionConfig()];

declare 'RemoteDialogflowQueryParameters',
    as InstanceOf['Google::Cloud::Ces::V1beta::SessionService::SessionConfig::RemoteDialogflowQueryParameters'];

coerce 'RemoteDialogflowQueryParameters',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::SessionService::SessionConfig::RemoteDialogflowQueryParameters'->new($_) };

declare 'RepeatedRemoteDialogflowQueryParameters',
    as ArrayRef[RemoteDialogflowQueryParameters()];

coerce 'RepeatedRemoteDialogflowQueryParameters',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::SessionService::SessionConfig::RemoteDialogflowQueryParameters'->new($_) } @$_ ] };

declare 'MapStringRemoteDialogflowQueryParameters',
    as HashRef[RemoteDialogflowQueryParameters()];

declare 'WebhookHeadersEntry',
    as InstanceOf['Google::Cloud::Ces::V1beta::SessionService::SessionConfig::RemoteDialogflowQueryParameters::WebhookHeadersEntry'];

coerce 'WebhookHeadersEntry',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::SessionService::SessionConfig::RemoteDialogflowQueryParameters::WebhookHeadersEntry'->new($_) };

declare 'RepeatedWebhookHeadersEntry',
    as ArrayRef[WebhookHeadersEntry()];

coerce 'RepeatedWebhookHeadersEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::SessionService::SessionConfig::RemoteDialogflowQueryParameters::WebhookHeadersEntry'->new($_) } @$_ ] };

declare 'MapStringWebhookHeadersEntry',
    as HashRef[WebhookHeadersEntry()];

declare 'ToolCalls',
    as InstanceOf['Google::Cloud::Ces::V1beta::SessionService::ToolCalls'];

coerce 'ToolCalls',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::SessionService::ToolCalls'->new($_) };

declare 'RepeatedToolCalls',
    as ArrayRef[ToolCalls()];

coerce 'RepeatedToolCalls',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::SessionService::ToolCalls'->new($_) } @$_ ] };

declare 'MapStringToolCalls',
    as HashRef[ToolCalls()];

declare 'ToolResponses',
    as InstanceOf['Google::Cloud::Ces::V1beta::SessionService::ToolResponses'];

coerce 'ToolResponses',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::SessionService::ToolResponses'->new($_) };

declare 'RepeatedToolResponses',
    as ArrayRef[ToolResponses()];

coerce 'RepeatedToolResponses',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::SessionService::ToolResponses'->new($_) } @$_ ] };

declare 'MapStringToolResponses',
    as HashRef[ToolResponses()];

declare 'Citations',
    as InstanceOf['Google::Cloud::Ces::V1beta::SessionService::Citations'];

coerce 'Citations',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::SessionService::Citations'->new($_) };

declare 'RepeatedCitations',
    as ArrayRef[Citations()];

coerce 'RepeatedCitations',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::SessionService::Citations'->new($_) } @$_ ] };

declare 'MapStringCitations',
    as HashRef[Citations()];

declare 'CitedChunk',
    as InstanceOf['Google::Cloud::Ces::V1beta::SessionService::Citations::CitedChunk'];

coerce 'CitedChunk',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::SessionService::Citations::CitedChunk'->new($_) };

declare 'RepeatedCitedChunk',
    as ArrayRef[CitedChunk()];

coerce 'RepeatedCitedChunk',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::SessionService::Citations::CitedChunk'->new($_) } @$_ ] };

declare 'MapStringCitedChunk',
    as HashRef[CitedChunk()];

declare 'InlineCitation',
    as InstanceOf['Google::Cloud::Ces::V1beta::SessionService::Citations::InlineCitation'];

coerce 'InlineCitation',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::SessionService::Citations::InlineCitation'->new($_) };

declare 'RepeatedInlineCitation',
    as ArrayRef[InlineCitation()];

coerce 'RepeatedInlineCitation',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::SessionService::Citations::InlineCitation'->new($_) } @$_ ] };

declare 'MapStringInlineCitation',
    as HashRef[InlineCitation()];

declare 'Event',
    as InstanceOf['Google::Cloud::Ces::V1beta::SessionService::Event'];

coerce 'Event',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::SessionService::Event'->new($_) };

declare 'RepeatedEvent',
    as ArrayRef[Event()];

coerce 'RepeatedEvent',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::SessionService::Event'->new($_) } @$_ ] };

declare 'MapStringEvent',
    as HashRef[Event()];

declare 'SessionInput',
    as InstanceOf['Google::Cloud::Ces::V1beta::SessionService::SessionInput'];

coerce 'SessionInput',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::SessionService::SessionInput'->new($_) };

declare 'RepeatedSessionInput',
    as ArrayRef[SessionInput()];

coerce 'RepeatedSessionInput',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::SessionService::SessionInput'->new($_) } @$_ ] };

declare 'MapStringSessionInput',
    as HashRef[SessionInput()];

declare 'RecordingControl',
    as (Int | Str);

declare 'SessionOutput',
    as InstanceOf['Google::Cloud::Ces::V1beta::SessionService::SessionOutput'];

coerce 'SessionOutput',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::SessionService::SessionOutput'->new($_) };

declare 'RepeatedSessionOutput',
    as ArrayRef[SessionOutput()];

coerce 'RepeatedSessionOutput',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::SessionService::SessionOutput'->new($_) } @$_ ] };

declare 'MapStringSessionOutput',
    as HashRef[SessionOutput()];

declare 'DiagnosticInfo',
    as InstanceOf['Google::Cloud::Ces::V1beta::SessionService::SessionOutput::DiagnosticInfo'];

coerce 'DiagnosticInfo',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::SessionService::SessionOutput::DiagnosticInfo'->new($_) };

declare 'RepeatedDiagnosticInfo',
    as ArrayRef[DiagnosticInfo()];

coerce 'RepeatedDiagnosticInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::SessionService::SessionOutput::DiagnosticInfo'->new($_) } @$_ ] };

declare 'MapStringDiagnosticInfo',
    as HashRef[DiagnosticInfo()];

declare 'RecognitionResult',
    as InstanceOf['Google::Cloud::Ces::V1beta::SessionService::RecognitionResult'];

coerce 'RecognitionResult',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::SessionService::RecognitionResult'->new($_) };

declare 'RepeatedRecognitionResult',
    as ArrayRef[RecognitionResult()];

coerce 'RepeatedRecognitionResult',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::SessionService::RecognitionResult'->new($_) } @$_ ] };

declare 'MapStringRecognitionResult',
    as HashRef[RecognitionResult()];

declare 'InterruptionSignal',
    as InstanceOf['Google::Cloud::Ces::V1beta::SessionService::InterruptionSignal'];

coerce 'InterruptionSignal',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::SessionService::InterruptionSignal'->new($_) };

declare 'RepeatedInterruptionSignal',
    as ArrayRef[InterruptionSignal()];

coerce 'RepeatedInterruptionSignal',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::SessionService::InterruptionSignal'->new($_) } @$_ ] };

declare 'MapStringInterruptionSignal',
    as HashRef[InterruptionSignal()];

declare 'EndSession',
    as InstanceOf['Google::Cloud::Ces::V1beta::SessionService::EndSession'];

coerce 'EndSession',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::SessionService::EndSession'->new($_) };

declare 'RepeatedEndSession',
    as ArrayRef[EndSession()];

coerce 'RepeatedEndSession',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::SessionService::EndSession'->new($_) } @$_ ] };

declare 'MapStringEndSession',
    as HashRef[EndSession()];

declare 'GoAway',
    as InstanceOf['Google::Cloud::Ces::V1beta::SessionService::GoAway'];

coerce 'GoAway',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::SessionService::GoAway'->new($_) };

declare 'RepeatedGoAway',
    as ArrayRef[GoAway()];

coerce 'RepeatedGoAway',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::SessionService::GoAway'->new($_) } @$_ ] };

declare 'MapStringGoAway',
    as HashRef[GoAway()];

declare 'RunSessionRequest',
    as InstanceOf['Google::Cloud::Ces::V1beta::SessionService::RunSessionRequest'];

coerce 'RunSessionRequest',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::SessionService::RunSessionRequest'->new($_) };

declare 'RepeatedRunSessionRequest',
    as ArrayRef[RunSessionRequest()];

coerce 'RepeatedRunSessionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::SessionService::RunSessionRequest'->new($_) } @$_ ] };

declare 'MapStringRunSessionRequest',
    as HashRef[RunSessionRequest()];

declare 'RunSessionResponse',
    as InstanceOf['Google::Cloud::Ces::V1beta::SessionService::RunSessionResponse'];

coerce 'RunSessionResponse',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::SessionService::RunSessionResponse'->new($_) };

declare 'RepeatedRunSessionResponse',
    as ArrayRef[RunSessionResponse()];

coerce 'RepeatedRunSessionResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::SessionService::RunSessionResponse'->new($_) } @$_ ] };

declare 'MapStringRunSessionResponse',
    as HashRef[RunSessionResponse()];

declare 'BidiSessionClientMessage',
    as InstanceOf['Google::Cloud::Ces::V1beta::SessionService::BidiSessionClientMessage'];

coerce 'BidiSessionClientMessage',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::SessionService::BidiSessionClientMessage'->new($_) };

declare 'RepeatedBidiSessionClientMessage',
    as ArrayRef[BidiSessionClientMessage()];

coerce 'RepeatedBidiSessionClientMessage',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::SessionService::BidiSessionClientMessage'->new($_) } @$_ ] };

declare 'MapStringBidiSessionClientMessage',
    as HashRef[BidiSessionClientMessage()];

declare 'BidiSessionServerMessage',
    as InstanceOf['Google::Cloud::Ces::V1beta::SessionService::BidiSessionServerMessage'];

coerce 'BidiSessionServerMessage',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::SessionService::BidiSessionServerMessage'->new($_) };

declare 'RepeatedBidiSessionServerMessage',
    as ArrayRef[BidiSessionServerMessage()];

coerce 'RepeatedBidiSessionServerMessage',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::SessionService::BidiSessionServerMessage'->new($_) } @$_ ] };

declare 'MapStringBidiSessionServerMessage',
    as HashRef[BidiSessionServerMessage()];

declare 'StreamChatAiAssistantRequest',
    as InstanceOf['Google::Cloud::Ces::V1beta::SessionService::StreamChatAiAssistantRequest'];

coerce 'StreamChatAiAssistantRequest',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::SessionService::StreamChatAiAssistantRequest'->new($_) };

declare 'RepeatedStreamChatAiAssistantRequest',
    as ArrayRef[StreamChatAiAssistantRequest()];

coerce 'RepeatedStreamChatAiAssistantRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::SessionService::StreamChatAiAssistantRequest'->new($_) } @$_ ] };

declare 'MapStringStreamChatAiAssistantRequest',
    as HashRef[StreamChatAiAssistantRequest()];

declare 'ClientCapability',
    as (Int | Str);

declare 'AssistantSuggestion',
    as InstanceOf['Google::Cloud::Ces::V1beta::SessionService::AssistantSuggestion'];

coerce 'AssistantSuggestion',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::SessionService::AssistantSuggestion'->new($_) };

declare 'RepeatedAssistantSuggestion',
    as ArrayRef[AssistantSuggestion()];

coerce 'RepeatedAssistantSuggestion',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::SessionService::AssistantSuggestion'->new($_) } @$_ ] };

declare 'MapStringAssistantSuggestion',
    as HashRef[AssistantSuggestion()];

declare 'Icon',
    as (Int | Str);

declare 'Source',
    as (Int | Str);

declare 'LoadSession',
    as InstanceOf['Google::Cloud::Ces::V1beta::SessionService::AssistantSuggestion::LoadSession'];

coerce 'LoadSession',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::SessionService::AssistantSuggestion::LoadSession'->new($_) };

declare 'RepeatedLoadSession',
    as ArrayRef[LoadSession()];

coerce 'RepeatedLoadSession',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::SessionService::AssistantSuggestion::LoadSession'->new($_) } @$_ ] };

declare 'MapStringLoadSession',
    as HashRef[LoadSession()];

declare 'GenerateOnboardingSuggestionsRequest',
    as InstanceOf['Google::Cloud::Ces::V1beta::SessionService::GenerateOnboardingSuggestionsRequest'];

coerce 'GenerateOnboardingSuggestionsRequest',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::SessionService::GenerateOnboardingSuggestionsRequest'->new($_) };

declare 'RepeatedGenerateOnboardingSuggestionsRequest',
    as ArrayRef[GenerateOnboardingSuggestionsRequest()];

coerce 'RepeatedGenerateOnboardingSuggestionsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::SessionService::GenerateOnboardingSuggestionsRequest'->new($_) } @$_ ] };

declare 'MapStringGenerateOnboardingSuggestionsRequest',
    as HashRef[GenerateOnboardingSuggestionsRequest()];

declare 'GenerateOnboardingSuggestionsResponse',
    as InstanceOf['Google::Cloud::Ces::V1beta::SessionService::GenerateOnboardingSuggestionsResponse'];

coerce 'GenerateOnboardingSuggestionsResponse',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::SessionService::GenerateOnboardingSuggestionsResponse'->new($_) };

declare 'RepeatedGenerateOnboardingSuggestionsResponse',
    as ArrayRef[GenerateOnboardingSuggestionsResponse()];

coerce 'RepeatedGenerateOnboardingSuggestionsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::SessionService::GenerateOnboardingSuggestionsResponse'->new($_) } @$_ ] };

declare 'MapStringGenerateOnboardingSuggestionsResponse',
    as HashRef[GenerateOnboardingSuggestionsResponse()];

declare 'UserProfile',
    as (Int | Str);

declare 'ArtifactChunk',
    as InstanceOf['Google::Cloud::Ces::V1beta::SessionService::ArtifactChunk'];

coerce 'ArtifactChunk',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::SessionService::ArtifactChunk'->new($_) };

declare 'RepeatedArtifactChunk',
    as ArrayRef[ArtifactChunk()];

coerce 'RepeatedArtifactChunk',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::SessionService::ArtifactChunk'->new($_) } @$_ ] };

declare 'MapStringArtifactChunk',
    as HashRef[ArtifactChunk()];

declare 'State',
    as (Int | Str);

declare 'OptionQuestionsChunk',
    as InstanceOf['Google::Cloud::Ces::V1beta::SessionService::OptionQuestionsChunk'];

coerce 'OptionQuestionsChunk',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::SessionService::OptionQuestionsChunk'->new($_) };

declare 'RepeatedOptionQuestionsChunk',
    as ArrayRef[OptionQuestionsChunk()];

coerce 'RepeatedOptionQuestionsChunk',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::SessionService::OptionQuestionsChunk'->new($_) } @$_ ] };

declare 'MapStringOptionQuestionsChunk',
    as HashRef[OptionQuestionsChunk()];

declare 'Option',
    as InstanceOf['Google::Cloud::Ces::V1beta::SessionService::OptionQuestionsChunk::Option'];

coerce 'Option',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::SessionService::OptionQuestionsChunk::Option'->new($_) };

declare 'RepeatedOption',
    as ArrayRef[Option()];

coerce 'RepeatedOption',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::SessionService::OptionQuestionsChunk::Option'->new($_) } @$_ ] };

declare 'MapStringOption',
    as HashRef[Option()];

declare 'Question',
    as InstanceOf['Google::Cloud::Ces::V1beta::SessionService::OptionQuestionsChunk::Question'];

coerce 'Question',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::SessionService::OptionQuestionsChunk::Question'->new($_) };

declare 'RepeatedQuestion',
    as ArrayRef[Question()];

coerce 'RepeatedQuestion',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::SessionService::OptionQuestionsChunk::Question'->new($_) } @$_ ] };

declare 'MapStringQuestion',
    as HashRef[Question()];

declare 'AssistantConfirmationRequest',
    as InstanceOf['Google::Cloud::Ces::V1beta::SessionService::AssistantConfirmationRequest'];

coerce 'AssistantConfirmationRequest',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::SessionService::AssistantConfirmationRequest'->new($_) };

declare 'RepeatedAssistantConfirmationRequest',
    as ArrayRef[AssistantConfirmationRequest()];

coerce 'RepeatedAssistantConfirmationRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::SessionService::AssistantConfirmationRequest'->new($_) } @$_ ] };

declare 'MapStringAssistantConfirmationRequest',
    as HashRef[AssistantConfirmationRequest()];

declare 'AssistantConfirmationResponse',
    as InstanceOf['Google::Cloud::Ces::V1beta::SessionService::AssistantConfirmationResponse'];

coerce 'AssistantConfirmationResponse',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::SessionService::AssistantConfirmationResponse'->new($_) };

declare 'RepeatedAssistantConfirmationResponse',
    as ArrayRef[AssistantConfirmationResponse()];

coerce 'RepeatedAssistantConfirmationResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::SessionService::AssistantConfirmationResponse'->new($_) } @$_ ] };

declare 'MapStringAssistantConfirmationResponse',
    as HashRef[AssistantConfirmationResponse()];

declare 'OperationCompletedEvent',
    as InstanceOf['Google::Cloud::Ces::V1beta::SessionService::OperationCompletedEvent'];

coerce 'OperationCompletedEvent',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::SessionService::OperationCompletedEvent'->new($_) };

declare 'RepeatedOperationCompletedEvent',
    as ArrayRef[OperationCompletedEvent()];

coerce 'RepeatedOperationCompletedEvent',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::SessionService::OperationCompletedEvent'->new($_) } @$_ ] };

declare 'MapStringOperationCompletedEvent',
    as HashRef[OperationCompletedEvent()];

declare 'TurnMetadata',
    as InstanceOf['Google::Cloud::Ces::V1beta::SessionService::TurnMetadata'];

coerce 'TurnMetadata',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::SessionService::TurnMetadata'->new($_) };

declare 'RepeatedTurnMetadata',
    as ArrayRef[TurnMetadata()];

coerce 'RepeatedTurnMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::SessionService::TurnMetadata'->new($_) } @$_ ] };

declare 'MapStringTurnMetadata',
    as HashRef[TurnMetadata()];

declare 'ContractStreamingPhase',
    as (Int | Str);

declare 'StreamChatAiAssistantResponse',
    as InstanceOf['Google::Cloud::Ces::V1beta::SessionService::StreamChatAiAssistantResponse'];

coerce 'StreamChatAiAssistantResponse',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::SessionService::StreamChatAiAssistantResponse'->new($_) };

declare 'RepeatedStreamChatAiAssistantResponse',
    as ArrayRef[StreamChatAiAssistantResponse()];

coerce 'RepeatedStreamChatAiAssistantResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::SessionService::StreamChatAiAssistantResponse'->new($_) } @$_ ] };

declare 'MapStringStreamChatAiAssistantResponse',
    as HashRef[StreamChatAiAssistantResponse()];

declare 'CancelAssistantTurnRequest',
    as InstanceOf['Google::Cloud::Ces::V1beta::SessionService::CancelAssistantTurnRequest'];

coerce 'CancelAssistantTurnRequest',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::SessionService::CancelAssistantTurnRequest'->new($_) };

declare 'RepeatedCancelAssistantTurnRequest',
    as ArrayRef[CancelAssistantTurnRequest()];

coerce 'RepeatedCancelAssistantTurnRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::SessionService::CancelAssistantTurnRequest'->new($_) } @$_ ] };

declare 'MapStringCancelAssistantTurnRequest',
    as HashRef[CancelAssistantTurnRequest()];

declare 'CancelAssistantTurnResponse',
    as InstanceOf['Google::Cloud::Ces::V1beta::SessionService::CancelAssistantTurnResponse'];

coerce 'CancelAssistantTurnResponse',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::SessionService::CancelAssistantTurnResponse'->new($_) };

declare 'RepeatedCancelAssistantTurnResponse',
    as ArrayRef[CancelAssistantTurnResponse()];

coerce 'RepeatedCancelAssistantTurnResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::SessionService::CancelAssistantTurnResponse'->new($_) } @$_ ] };

declare 'MapStringCancelAssistantTurnResponse',
    as HashRef[CancelAssistantTurnResponse()];

declare 'TurnResumeSnapshot',
    as InstanceOf['Google::Cloud::Ces::V1beta::SessionService::TurnResumeSnapshot'];

coerce 'TurnResumeSnapshot',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::SessionService::TurnResumeSnapshot'->new($_) };

declare 'RepeatedTurnResumeSnapshot',
    as ArrayRef[TurnResumeSnapshot()];

coerce 'RepeatedTurnResumeSnapshot',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::SessionService::TurnResumeSnapshot'->new($_) } @$_ ] };

declare 'MapStringTurnResumeSnapshot',
    as HashRef[TurnResumeSnapshot()];

declare 'TurnHandoffEvent',
    as InstanceOf['Google::Cloud::Ces::V1beta::SessionService::TurnHandoffEvent'];

coerce 'TurnHandoffEvent',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::SessionService::TurnHandoffEvent'->new($_) };

declare 'RepeatedTurnHandoffEvent',
    as ArrayRef[TurnHandoffEvent()];

coerce 'RepeatedTurnHandoffEvent',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::SessionService::TurnHandoffEvent'->new($_) } @$_ ] };

declare 'MapStringTurnHandoffEvent',
    as HashRef[TurnHandoffEvent()];

declare 'Reason',
    as (Int | Str);

declare 'TurnCompletedEvent',
    as InstanceOf['Google::Cloud::Ces::V1beta::SessionService::TurnCompletedEvent'];

coerce 'TurnCompletedEvent',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::SessionService::TurnCompletedEvent'->new($_) };

declare 'RepeatedTurnCompletedEvent',
    as ArrayRef[TurnCompletedEvent()];

coerce 'RepeatedTurnCompletedEvent',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::SessionService::TurnCompletedEvent'->new($_) } @$_ ] };

declare 'MapStringTurnCompletedEvent',
    as HashRef[TurnCompletedEvent()];

declare 'Reason',
    as (Int | Str);

1;

__END__

=head1 NAME

Google::Cloud::Ces::V1beta::SessionService::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
