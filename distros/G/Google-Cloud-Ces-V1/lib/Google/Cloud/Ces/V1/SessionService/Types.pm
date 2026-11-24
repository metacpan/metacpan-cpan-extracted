package Google::Cloud::Ces::V1::SessionService::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'AudioEncoding',
    as (Int | Str);

declare 'MockConfig',
    as InstanceOf['Google::Cloud::Ces::V1::SessionService::MockConfig'];

coerce 'MockConfig',
    from HashRef, via { 'Google::Cloud::Ces::V1::SessionService::MockConfig'->new($_) };

declare 'RepeatedMockConfig',
    as ArrayRef[MockConfig()];

coerce 'RepeatedMockConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1::SessionService::MockConfig'->new($_) } @$_ ] };

declare 'MapStringMockConfig',
    as HashRef[MockConfig()];

declare 'UnmatchedToolCallBehavior',
    as (Int | Str);

declare 'InputAudioConfig',
    as InstanceOf['Google::Cloud::Ces::V1::SessionService::InputAudioConfig'];

coerce 'InputAudioConfig',
    from HashRef, via { 'Google::Cloud::Ces::V1::SessionService::InputAudioConfig'->new($_) };

declare 'RepeatedInputAudioConfig',
    as ArrayRef[InputAudioConfig()];

coerce 'RepeatedInputAudioConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1::SessionService::InputAudioConfig'->new($_) } @$_ ] };

declare 'MapStringInputAudioConfig',
    as HashRef[InputAudioConfig()];

declare 'OutputAudioConfig',
    as InstanceOf['Google::Cloud::Ces::V1::SessionService::OutputAudioConfig'];

coerce 'OutputAudioConfig',
    from HashRef, via { 'Google::Cloud::Ces::V1::SessionService::OutputAudioConfig'->new($_) };

declare 'RepeatedOutputAudioConfig',
    as ArrayRef[OutputAudioConfig()];

coerce 'RepeatedOutputAudioConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1::SessionService::OutputAudioConfig'->new($_) } @$_ ] };

declare 'MapStringOutputAudioConfig',
    as HashRef[OutputAudioConfig()];

declare 'SessionConfig',
    as InstanceOf['Google::Cloud::Ces::V1::SessionService::SessionConfig'];

coerce 'SessionConfig',
    from HashRef, via { 'Google::Cloud::Ces::V1::SessionService::SessionConfig'->new($_) };

declare 'RepeatedSessionConfig',
    as ArrayRef[SessionConfig()];

coerce 'RepeatedSessionConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1::SessionService::SessionConfig'->new($_) } @$_ ] };

declare 'MapStringSessionConfig',
    as HashRef[SessionConfig()];

declare 'RemoteDialogflowQueryParameters',
    as InstanceOf['Google::Cloud::Ces::V1::SessionService::SessionConfig::RemoteDialogflowQueryParameters'];

coerce 'RemoteDialogflowQueryParameters',
    from HashRef, via { 'Google::Cloud::Ces::V1::SessionService::SessionConfig::RemoteDialogflowQueryParameters'->new($_) };

declare 'RepeatedRemoteDialogflowQueryParameters',
    as ArrayRef[RemoteDialogflowQueryParameters()];

coerce 'RepeatedRemoteDialogflowQueryParameters',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1::SessionService::SessionConfig::RemoteDialogflowQueryParameters'->new($_) } @$_ ] };

declare 'MapStringRemoteDialogflowQueryParameters',
    as HashRef[RemoteDialogflowQueryParameters()];

declare 'WebhookHeadersEntry',
    as InstanceOf['Google::Cloud::Ces::V1::SessionService::SessionConfig::RemoteDialogflowQueryParameters::WebhookHeadersEntry'];

coerce 'WebhookHeadersEntry',
    from HashRef, via { 'Google::Cloud::Ces::V1::SessionService::SessionConfig::RemoteDialogflowQueryParameters::WebhookHeadersEntry'->new($_) };

declare 'RepeatedWebhookHeadersEntry',
    as ArrayRef[WebhookHeadersEntry()];

coerce 'RepeatedWebhookHeadersEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1::SessionService::SessionConfig::RemoteDialogflowQueryParameters::WebhookHeadersEntry'->new($_) } @$_ ] };

declare 'MapStringWebhookHeadersEntry',
    as HashRef[WebhookHeadersEntry()];

declare 'ToolCalls',
    as InstanceOf['Google::Cloud::Ces::V1::SessionService::ToolCalls'];

coerce 'ToolCalls',
    from HashRef, via { 'Google::Cloud::Ces::V1::SessionService::ToolCalls'->new($_) };

declare 'RepeatedToolCalls',
    as ArrayRef[ToolCalls()];

coerce 'RepeatedToolCalls',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1::SessionService::ToolCalls'->new($_) } @$_ ] };

declare 'MapStringToolCalls',
    as HashRef[ToolCalls()];

declare 'ToolResponses',
    as InstanceOf['Google::Cloud::Ces::V1::SessionService::ToolResponses'];

coerce 'ToolResponses',
    from HashRef, via { 'Google::Cloud::Ces::V1::SessionService::ToolResponses'->new($_) };

declare 'RepeatedToolResponses',
    as ArrayRef[ToolResponses()];

coerce 'RepeatedToolResponses',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1::SessionService::ToolResponses'->new($_) } @$_ ] };

declare 'MapStringToolResponses',
    as HashRef[ToolResponses()];

declare 'Citations',
    as InstanceOf['Google::Cloud::Ces::V1::SessionService::Citations'];

coerce 'Citations',
    from HashRef, via { 'Google::Cloud::Ces::V1::SessionService::Citations'->new($_) };

declare 'RepeatedCitations',
    as ArrayRef[Citations()];

coerce 'RepeatedCitations',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1::SessionService::Citations'->new($_) } @$_ ] };

declare 'MapStringCitations',
    as HashRef[Citations()];

declare 'CitedChunk',
    as InstanceOf['Google::Cloud::Ces::V1::SessionService::Citations::CitedChunk'];

coerce 'CitedChunk',
    from HashRef, via { 'Google::Cloud::Ces::V1::SessionService::Citations::CitedChunk'->new($_) };

declare 'RepeatedCitedChunk',
    as ArrayRef[CitedChunk()];

coerce 'RepeatedCitedChunk',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1::SessionService::Citations::CitedChunk'->new($_) } @$_ ] };

declare 'MapStringCitedChunk',
    as HashRef[CitedChunk()];

declare 'Event',
    as InstanceOf['Google::Cloud::Ces::V1::SessionService::Event'];

coerce 'Event',
    from HashRef, via { 'Google::Cloud::Ces::V1::SessionService::Event'->new($_) };

declare 'RepeatedEvent',
    as ArrayRef[Event()];

coerce 'RepeatedEvent',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1::SessionService::Event'->new($_) } @$_ ] };

declare 'MapStringEvent',
    as HashRef[Event()];

declare 'SessionInput',
    as InstanceOf['Google::Cloud::Ces::V1::SessionService::SessionInput'];

coerce 'SessionInput',
    from HashRef, via { 'Google::Cloud::Ces::V1::SessionService::SessionInput'->new($_) };

declare 'RepeatedSessionInput',
    as ArrayRef[SessionInput()];

coerce 'RepeatedSessionInput',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1::SessionService::SessionInput'->new($_) } @$_ ] };

declare 'MapStringSessionInput',
    as HashRef[SessionInput()];

declare 'SessionOutput',
    as InstanceOf['Google::Cloud::Ces::V1::SessionService::SessionOutput'];

coerce 'SessionOutput',
    from HashRef, via { 'Google::Cloud::Ces::V1::SessionService::SessionOutput'->new($_) };

declare 'RepeatedSessionOutput',
    as ArrayRef[SessionOutput()];

coerce 'RepeatedSessionOutput',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1::SessionService::SessionOutput'->new($_) } @$_ ] };

declare 'MapStringSessionOutput',
    as HashRef[SessionOutput()];

declare 'DiagnosticInfo',
    as InstanceOf['Google::Cloud::Ces::V1::SessionService::SessionOutput::DiagnosticInfo'];

coerce 'DiagnosticInfo',
    from HashRef, via { 'Google::Cloud::Ces::V1::SessionService::SessionOutput::DiagnosticInfo'->new($_) };

declare 'RepeatedDiagnosticInfo',
    as ArrayRef[DiagnosticInfo()];

coerce 'RepeatedDiagnosticInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1::SessionService::SessionOutput::DiagnosticInfo'->new($_) } @$_ ] };

declare 'MapStringDiagnosticInfo',
    as HashRef[DiagnosticInfo()];

declare 'RecognitionResult',
    as InstanceOf['Google::Cloud::Ces::V1::SessionService::RecognitionResult'];

coerce 'RecognitionResult',
    from HashRef, via { 'Google::Cloud::Ces::V1::SessionService::RecognitionResult'->new($_) };

declare 'RepeatedRecognitionResult',
    as ArrayRef[RecognitionResult()];

coerce 'RepeatedRecognitionResult',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1::SessionService::RecognitionResult'->new($_) } @$_ ] };

declare 'MapStringRecognitionResult',
    as HashRef[RecognitionResult()];

declare 'InterruptionSignal',
    as InstanceOf['Google::Cloud::Ces::V1::SessionService::InterruptionSignal'];

coerce 'InterruptionSignal',
    from HashRef, via { 'Google::Cloud::Ces::V1::SessionService::InterruptionSignal'->new($_) };

declare 'RepeatedInterruptionSignal',
    as ArrayRef[InterruptionSignal()];

coerce 'RepeatedInterruptionSignal',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1::SessionService::InterruptionSignal'->new($_) } @$_ ] };

declare 'MapStringInterruptionSignal',
    as HashRef[InterruptionSignal()];

declare 'EndSession',
    as InstanceOf['Google::Cloud::Ces::V1::SessionService::EndSession'];

coerce 'EndSession',
    from HashRef, via { 'Google::Cloud::Ces::V1::SessionService::EndSession'->new($_) };

declare 'RepeatedEndSession',
    as ArrayRef[EndSession()];

coerce 'RepeatedEndSession',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1::SessionService::EndSession'->new($_) } @$_ ] };

declare 'MapStringEndSession',
    as HashRef[EndSession()];

declare 'GoAway',
    as InstanceOf['Google::Cloud::Ces::V1::SessionService::GoAway'];

coerce 'GoAway',
    from HashRef, via { 'Google::Cloud::Ces::V1::SessionService::GoAway'->new($_) };

declare 'RepeatedGoAway',
    as ArrayRef[GoAway()];

coerce 'RepeatedGoAway',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1::SessionService::GoAway'->new($_) } @$_ ] };

declare 'MapStringGoAway',
    as HashRef[GoAway()];

declare 'RunSessionRequest',
    as InstanceOf['Google::Cloud::Ces::V1::SessionService::RunSessionRequest'];

coerce 'RunSessionRequest',
    from HashRef, via { 'Google::Cloud::Ces::V1::SessionService::RunSessionRequest'->new($_) };

declare 'RepeatedRunSessionRequest',
    as ArrayRef[RunSessionRequest()];

coerce 'RepeatedRunSessionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1::SessionService::RunSessionRequest'->new($_) } @$_ ] };

declare 'MapStringRunSessionRequest',
    as HashRef[RunSessionRequest()];

declare 'RunSessionResponse',
    as InstanceOf['Google::Cloud::Ces::V1::SessionService::RunSessionResponse'];

coerce 'RunSessionResponse',
    from HashRef, via { 'Google::Cloud::Ces::V1::SessionService::RunSessionResponse'->new($_) };

declare 'RepeatedRunSessionResponse',
    as ArrayRef[RunSessionResponse()];

coerce 'RepeatedRunSessionResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1::SessionService::RunSessionResponse'->new($_) } @$_ ] };

declare 'MapStringRunSessionResponse',
    as HashRef[RunSessionResponse()];

declare 'BidiSessionClientMessage',
    as InstanceOf['Google::Cloud::Ces::V1::SessionService::BidiSessionClientMessage'];

coerce 'BidiSessionClientMessage',
    from HashRef, via { 'Google::Cloud::Ces::V1::SessionService::BidiSessionClientMessage'->new($_) };

declare 'RepeatedBidiSessionClientMessage',
    as ArrayRef[BidiSessionClientMessage()];

coerce 'RepeatedBidiSessionClientMessage',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1::SessionService::BidiSessionClientMessage'->new($_) } @$_ ] };

declare 'MapStringBidiSessionClientMessage',
    as HashRef[BidiSessionClientMessage()];

declare 'BidiSessionServerMessage',
    as InstanceOf['Google::Cloud::Ces::V1::SessionService::BidiSessionServerMessage'];

coerce 'BidiSessionServerMessage',
    from HashRef, via { 'Google::Cloud::Ces::V1::SessionService::BidiSessionServerMessage'->new($_) };

declare 'RepeatedBidiSessionServerMessage',
    as ArrayRef[BidiSessionServerMessage()];

coerce 'RepeatedBidiSessionServerMessage',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1::SessionService::BidiSessionServerMessage'->new($_) } @$_ ] };

declare 'MapStringBidiSessionServerMessage',
    as HashRef[BidiSessionServerMessage()];

1;

__END__

=head1 NAME

Google::Cloud::Ces::V1::SessionService::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
