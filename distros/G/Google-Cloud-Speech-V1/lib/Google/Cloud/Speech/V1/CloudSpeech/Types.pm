package Google::Cloud::Speech::V1::CloudSpeech::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'RecognizeRequest',
    as InstanceOf['Google::Cloud::Speech::V1::CloudSpeech::RecognizeRequest'];

coerce 'RecognizeRequest',
    from HashRef, via { 'Google::Cloud::Speech::V1::CloudSpeech::RecognizeRequest'->new($_) };

declare 'RepeatedRecognizeRequest',
    as ArrayRef[RecognizeRequest()];

coerce 'RepeatedRecognizeRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Speech::V1::CloudSpeech::RecognizeRequest'->new($_) } @$_ ] };

declare 'MapStringRecognizeRequest',
    as HashRef[RecognizeRequest()];

declare 'LongRunningRecognizeRequest',
    as InstanceOf['Google::Cloud::Speech::V1::CloudSpeech::LongRunningRecognizeRequest'];

coerce 'LongRunningRecognizeRequest',
    from HashRef, via { 'Google::Cloud::Speech::V1::CloudSpeech::LongRunningRecognizeRequest'->new($_) };

declare 'RepeatedLongRunningRecognizeRequest',
    as ArrayRef[LongRunningRecognizeRequest()];

coerce 'RepeatedLongRunningRecognizeRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Speech::V1::CloudSpeech::LongRunningRecognizeRequest'->new($_) } @$_ ] };

declare 'MapStringLongRunningRecognizeRequest',
    as HashRef[LongRunningRecognizeRequest()];

declare 'TranscriptOutputConfig',
    as InstanceOf['Google::Cloud::Speech::V1::CloudSpeech::TranscriptOutputConfig'];

coerce 'TranscriptOutputConfig',
    from HashRef, via { 'Google::Cloud::Speech::V1::CloudSpeech::TranscriptOutputConfig'->new($_) };

declare 'RepeatedTranscriptOutputConfig',
    as ArrayRef[TranscriptOutputConfig()];

coerce 'RepeatedTranscriptOutputConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Speech::V1::CloudSpeech::TranscriptOutputConfig'->new($_) } @$_ ] };

declare 'MapStringTranscriptOutputConfig',
    as HashRef[TranscriptOutputConfig()];

declare 'StreamingRecognizeRequest',
    as InstanceOf['Google::Cloud::Speech::V1::CloudSpeech::StreamingRecognizeRequest'];

coerce 'StreamingRecognizeRequest',
    from HashRef, via { 'Google::Cloud::Speech::V1::CloudSpeech::StreamingRecognizeRequest'->new($_) };

declare 'RepeatedStreamingRecognizeRequest',
    as ArrayRef[StreamingRecognizeRequest()];

coerce 'RepeatedStreamingRecognizeRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Speech::V1::CloudSpeech::StreamingRecognizeRequest'->new($_) } @$_ ] };

declare 'MapStringStreamingRecognizeRequest',
    as HashRef[StreamingRecognizeRequest()];

declare 'StreamingRecognitionConfig',
    as InstanceOf['Google::Cloud::Speech::V1::CloudSpeech::StreamingRecognitionConfig'];

coerce 'StreamingRecognitionConfig',
    from HashRef, via { 'Google::Cloud::Speech::V1::CloudSpeech::StreamingRecognitionConfig'->new($_) };

declare 'RepeatedStreamingRecognitionConfig',
    as ArrayRef[StreamingRecognitionConfig()];

coerce 'RepeatedStreamingRecognitionConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Speech::V1::CloudSpeech::StreamingRecognitionConfig'->new($_) } @$_ ] };

declare 'MapStringStreamingRecognitionConfig',
    as HashRef[StreamingRecognitionConfig()];

declare 'VoiceActivityTimeout',
    as InstanceOf['Google::Cloud::Speech::V1::CloudSpeech::StreamingRecognitionConfig::VoiceActivityTimeout'];

coerce 'VoiceActivityTimeout',
    from HashRef, via { 'Google::Cloud::Speech::V1::CloudSpeech::StreamingRecognitionConfig::VoiceActivityTimeout'->new($_) };

declare 'RepeatedVoiceActivityTimeout',
    as ArrayRef[VoiceActivityTimeout()];

coerce 'RepeatedVoiceActivityTimeout',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Speech::V1::CloudSpeech::StreamingRecognitionConfig::VoiceActivityTimeout'->new($_) } @$_ ] };

declare 'MapStringVoiceActivityTimeout',
    as HashRef[VoiceActivityTimeout()];

declare 'RecognitionConfig',
    as InstanceOf['Google::Cloud::Speech::V1::CloudSpeech::RecognitionConfig'];

coerce 'RecognitionConfig',
    from HashRef, via { 'Google::Cloud::Speech::V1::CloudSpeech::RecognitionConfig'->new($_) };

declare 'RepeatedRecognitionConfig',
    as ArrayRef[RecognitionConfig()];

coerce 'RepeatedRecognitionConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Speech::V1::CloudSpeech::RecognitionConfig'->new($_) } @$_ ] };

declare 'MapStringRecognitionConfig',
    as HashRef[RecognitionConfig()];

declare 'AudioEncoding',
    as (Int | Str);

declare 'SpeakerDiarizationConfig',
    as InstanceOf['Google::Cloud::Speech::V1::CloudSpeech::SpeakerDiarizationConfig'];

coerce 'SpeakerDiarizationConfig',
    from HashRef, via { 'Google::Cloud::Speech::V1::CloudSpeech::SpeakerDiarizationConfig'->new($_) };

declare 'RepeatedSpeakerDiarizationConfig',
    as ArrayRef[SpeakerDiarizationConfig()];

coerce 'RepeatedSpeakerDiarizationConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Speech::V1::CloudSpeech::SpeakerDiarizationConfig'->new($_) } @$_ ] };

declare 'MapStringSpeakerDiarizationConfig',
    as HashRef[SpeakerDiarizationConfig()];

declare 'RecognitionMetadata',
    as InstanceOf['Google::Cloud::Speech::V1::CloudSpeech::RecognitionMetadata'];

coerce 'RecognitionMetadata',
    from HashRef, via { 'Google::Cloud::Speech::V1::CloudSpeech::RecognitionMetadata'->new($_) };

declare 'RepeatedRecognitionMetadata',
    as ArrayRef[RecognitionMetadata()];

coerce 'RepeatedRecognitionMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Speech::V1::CloudSpeech::RecognitionMetadata'->new($_) } @$_ ] };

declare 'MapStringRecognitionMetadata',
    as HashRef[RecognitionMetadata()];

declare 'InteractionType',
    as (Int | Str);

declare 'MicrophoneDistance',
    as (Int | Str);

declare 'OriginalMediaType',
    as (Int | Str);

declare 'RecordingDeviceType',
    as (Int | Str);

declare 'SpeechContext',
    as InstanceOf['Google::Cloud::Speech::V1::CloudSpeech::SpeechContext'];

coerce 'SpeechContext',
    from HashRef, via { 'Google::Cloud::Speech::V1::CloudSpeech::SpeechContext'->new($_) };

declare 'RepeatedSpeechContext',
    as ArrayRef[SpeechContext()];

coerce 'RepeatedSpeechContext',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Speech::V1::CloudSpeech::SpeechContext'->new($_) } @$_ ] };

declare 'MapStringSpeechContext',
    as HashRef[SpeechContext()];

declare 'RecognitionAudio',
    as InstanceOf['Google::Cloud::Speech::V1::CloudSpeech::RecognitionAudio'];

coerce 'RecognitionAudio',
    from HashRef, via { 'Google::Cloud::Speech::V1::CloudSpeech::RecognitionAudio'->new($_) };

declare 'RepeatedRecognitionAudio',
    as ArrayRef[RecognitionAudio()];

coerce 'RepeatedRecognitionAudio',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Speech::V1::CloudSpeech::RecognitionAudio'->new($_) } @$_ ] };

declare 'MapStringRecognitionAudio',
    as HashRef[RecognitionAudio()];

declare 'RecognizeResponse',
    as InstanceOf['Google::Cloud::Speech::V1::CloudSpeech::RecognizeResponse'];

coerce 'RecognizeResponse',
    from HashRef, via { 'Google::Cloud::Speech::V1::CloudSpeech::RecognizeResponse'->new($_) };

declare 'RepeatedRecognizeResponse',
    as ArrayRef[RecognizeResponse()];

coerce 'RepeatedRecognizeResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Speech::V1::CloudSpeech::RecognizeResponse'->new($_) } @$_ ] };

declare 'MapStringRecognizeResponse',
    as HashRef[RecognizeResponse()];

declare 'LongRunningRecognizeResponse',
    as InstanceOf['Google::Cloud::Speech::V1::CloudSpeech::LongRunningRecognizeResponse'];

coerce 'LongRunningRecognizeResponse',
    from HashRef, via { 'Google::Cloud::Speech::V1::CloudSpeech::LongRunningRecognizeResponse'->new($_) };

declare 'RepeatedLongRunningRecognizeResponse',
    as ArrayRef[LongRunningRecognizeResponse()];

coerce 'RepeatedLongRunningRecognizeResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Speech::V1::CloudSpeech::LongRunningRecognizeResponse'->new($_) } @$_ ] };

declare 'MapStringLongRunningRecognizeResponse',
    as HashRef[LongRunningRecognizeResponse()];

declare 'LongRunningRecognizeMetadata',
    as InstanceOf['Google::Cloud::Speech::V1::CloudSpeech::LongRunningRecognizeMetadata'];

coerce 'LongRunningRecognizeMetadata',
    from HashRef, via { 'Google::Cloud::Speech::V1::CloudSpeech::LongRunningRecognizeMetadata'->new($_) };

declare 'RepeatedLongRunningRecognizeMetadata',
    as ArrayRef[LongRunningRecognizeMetadata()];

coerce 'RepeatedLongRunningRecognizeMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Speech::V1::CloudSpeech::LongRunningRecognizeMetadata'->new($_) } @$_ ] };

declare 'MapStringLongRunningRecognizeMetadata',
    as HashRef[LongRunningRecognizeMetadata()];

declare 'StreamingRecognizeResponse',
    as InstanceOf['Google::Cloud::Speech::V1::CloudSpeech::StreamingRecognizeResponse'];

coerce 'StreamingRecognizeResponse',
    from HashRef, via { 'Google::Cloud::Speech::V1::CloudSpeech::StreamingRecognizeResponse'->new($_) };

declare 'RepeatedStreamingRecognizeResponse',
    as ArrayRef[StreamingRecognizeResponse()];

coerce 'RepeatedStreamingRecognizeResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Speech::V1::CloudSpeech::StreamingRecognizeResponse'->new($_) } @$_ ] };

declare 'MapStringStreamingRecognizeResponse',
    as HashRef[StreamingRecognizeResponse()];

declare 'SpeechEventType',
    as (Int | Str);

declare 'StreamingRecognitionResult',
    as InstanceOf['Google::Cloud::Speech::V1::CloudSpeech::StreamingRecognitionResult'];

coerce 'StreamingRecognitionResult',
    from HashRef, via { 'Google::Cloud::Speech::V1::CloudSpeech::StreamingRecognitionResult'->new($_) };

declare 'RepeatedStreamingRecognitionResult',
    as ArrayRef[StreamingRecognitionResult()];

coerce 'RepeatedStreamingRecognitionResult',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Speech::V1::CloudSpeech::StreamingRecognitionResult'->new($_) } @$_ ] };

declare 'MapStringStreamingRecognitionResult',
    as HashRef[StreamingRecognitionResult()];

declare 'SpeechRecognitionResult',
    as InstanceOf['Google::Cloud::Speech::V1::CloudSpeech::SpeechRecognitionResult'];

coerce 'SpeechRecognitionResult',
    from HashRef, via { 'Google::Cloud::Speech::V1::CloudSpeech::SpeechRecognitionResult'->new($_) };

declare 'RepeatedSpeechRecognitionResult',
    as ArrayRef[SpeechRecognitionResult()];

coerce 'RepeatedSpeechRecognitionResult',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Speech::V1::CloudSpeech::SpeechRecognitionResult'->new($_) } @$_ ] };

declare 'MapStringSpeechRecognitionResult',
    as HashRef[SpeechRecognitionResult()];

declare 'SpeechRecognitionAlternative',
    as InstanceOf['Google::Cloud::Speech::V1::CloudSpeech::SpeechRecognitionAlternative'];

coerce 'SpeechRecognitionAlternative',
    from HashRef, via { 'Google::Cloud::Speech::V1::CloudSpeech::SpeechRecognitionAlternative'->new($_) };

declare 'RepeatedSpeechRecognitionAlternative',
    as ArrayRef[SpeechRecognitionAlternative()];

coerce 'RepeatedSpeechRecognitionAlternative',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Speech::V1::CloudSpeech::SpeechRecognitionAlternative'->new($_) } @$_ ] };

declare 'MapStringSpeechRecognitionAlternative',
    as HashRef[SpeechRecognitionAlternative()];

declare 'WordInfo',
    as InstanceOf['Google::Cloud::Speech::V1::CloudSpeech::WordInfo'];

coerce 'WordInfo',
    from HashRef, via { 'Google::Cloud::Speech::V1::CloudSpeech::WordInfo'->new($_) };

declare 'RepeatedWordInfo',
    as ArrayRef[WordInfo()];

coerce 'RepeatedWordInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Speech::V1::CloudSpeech::WordInfo'->new($_) } @$_ ] };

declare 'MapStringWordInfo',
    as HashRef[WordInfo()];

declare 'SpeechAdaptationInfo',
    as InstanceOf['Google::Cloud::Speech::V1::CloudSpeech::SpeechAdaptationInfo'];

coerce 'SpeechAdaptationInfo',
    from HashRef, via { 'Google::Cloud::Speech::V1::CloudSpeech::SpeechAdaptationInfo'->new($_) };

declare 'RepeatedSpeechAdaptationInfo',
    as ArrayRef[SpeechAdaptationInfo()];

coerce 'RepeatedSpeechAdaptationInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Speech::V1::CloudSpeech::SpeechAdaptationInfo'->new($_) } @$_ ] };

declare 'MapStringSpeechAdaptationInfo',
    as HashRef[SpeechAdaptationInfo()];

1;

__END__

=head1 NAME

Google::Cloud::Speech::V1::CloudSpeech::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
