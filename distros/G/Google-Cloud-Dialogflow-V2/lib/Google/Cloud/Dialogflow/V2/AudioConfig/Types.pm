package Google::Cloud::Dialogflow::V2::AudioConfig::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'TelephonyDtmf',
    as (Int | Str);

declare 'AudioEncoding',
    as (Int | Str);

declare 'SpeechModelVariant',
    as (Int | Str);

declare 'SsmlVoiceGender',
    as (Int | Str);

declare 'OutputAudioEncoding',
    as (Int | Str);

declare 'SpeechContext',
    as InstanceOf['Google::Cloud::Dialogflow::V2::AudioConfig::SpeechContext'];

coerce 'SpeechContext',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::AudioConfig::SpeechContext'->new($_) };

declare 'RepeatedSpeechContext',
    as ArrayRef[SpeechContext()];

coerce 'RepeatedSpeechContext',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::AudioConfig::SpeechContext'->new($_) } @$_ ] };

declare 'MapStringSpeechContext',
    as HashRef[SpeechContext()];

declare 'SpeechWordInfo',
    as InstanceOf['Google::Cloud::Dialogflow::V2::AudioConfig::SpeechWordInfo'];

coerce 'SpeechWordInfo',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::AudioConfig::SpeechWordInfo'->new($_) };

declare 'RepeatedSpeechWordInfo',
    as ArrayRef[SpeechWordInfo()];

coerce 'RepeatedSpeechWordInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::AudioConfig::SpeechWordInfo'->new($_) } @$_ ] };

declare 'MapStringSpeechWordInfo',
    as HashRef[SpeechWordInfo()];

declare 'InputAudioConfig',
    as InstanceOf['Google::Cloud::Dialogflow::V2::AudioConfig::InputAudioConfig'];

coerce 'InputAudioConfig',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::AudioConfig::InputAudioConfig'->new($_) };

declare 'RepeatedInputAudioConfig',
    as ArrayRef[InputAudioConfig()];

coerce 'RepeatedInputAudioConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::AudioConfig::InputAudioConfig'->new($_) } @$_ ] };

declare 'MapStringInputAudioConfig',
    as HashRef[InputAudioConfig()];

declare 'VoiceSelectionParams',
    as InstanceOf['Google::Cloud::Dialogflow::V2::AudioConfig::VoiceSelectionParams'];

coerce 'VoiceSelectionParams',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::AudioConfig::VoiceSelectionParams'->new($_) };

declare 'RepeatedVoiceSelectionParams',
    as ArrayRef[VoiceSelectionParams()];

coerce 'RepeatedVoiceSelectionParams',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::AudioConfig::VoiceSelectionParams'->new($_) } @$_ ] };

declare 'MapStringVoiceSelectionParams',
    as HashRef[VoiceSelectionParams()];

declare 'SynthesizeSpeechConfig',
    as InstanceOf['Google::Cloud::Dialogflow::V2::AudioConfig::SynthesizeSpeechConfig'];

coerce 'SynthesizeSpeechConfig',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::AudioConfig::SynthesizeSpeechConfig'->new($_) };

declare 'RepeatedSynthesizeSpeechConfig',
    as ArrayRef[SynthesizeSpeechConfig()];

coerce 'RepeatedSynthesizeSpeechConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::AudioConfig::SynthesizeSpeechConfig'->new($_) } @$_ ] };

declare 'MapStringSynthesizeSpeechConfig',
    as HashRef[SynthesizeSpeechConfig()];

declare 'CustomPronunciationParams',
    as InstanceOf['Google::Cloud::Dialogflow::V2::AudioConfig::CustomPronunciationParams'];

coerce 'CustomPronunciationParams',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::AudioConfig::CustomPronunciationParams'->new($_) };

declare 'RepeatedCustomPronunciationParams',
    as ArrayRef[CustomPronunciationParams()];

coerce 'RepeatedCustomPronunciationParams',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::AudioConfig::CustomPronunciationParams'->new($_) } @$_ ] };

declare 'MapStringCustomPronunciationParams',
    as HashRef[CustomPronunciationParams()];

declare 'PhoneticEncoding',
    as (Int | Str);

declare 'OutputAudioConfig',
    as InstanceOf['Google::Cloud::Dialogflow::V2::AudioConfig::OutputAudioConfig'];

coerce 'OutputAudioConfig',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::AudioConfig::OutputAudioConfig'->new($_) };

declare 'RepeatedOutputAudioConfig',
    as ArrayRef[OutputAudioConfig()];

coerce 'RepeatedOutputAudioConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::AudioConfig::OutputAudioConfig'->new($_) } @$_ ] };

declare 'MapStringOutputAudioConfig',
    as HashRef[OutputAudioConfig()];

declare 'TelephonyDtmfEvents',
    as InstanceOf['Google::Cloud::Dialogflow::V2::AudioConfig::TelephonyDtmfEvents'];

coerce 'TelephonyDtmfEvents',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::AudioConfig::TelephonyDtmfEvents'->new($_) };

declare 'RepeatedTelephonyDtmfEvents',
    as ArrayRef[TelephonyDtmfEvents()];

coerce 'RepeatedTelephonyDtmfEvents',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::AudioConfig::TelephonyDtmfEvents'->new($_) } @$_ ] };

declare 'MapStringTelephonyDtmfEvents',
    as HashRef[TelephonyDtmfEvents()];

declare 'SpeechToTextConfig',
    as InstanceOf['Google::Cloud::Dialogflow::V2::AudioConfig::SpeechToTextConfig'];

coerce 'SpeechToTextConfig',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::AudioConfig::SpeechToTextConfig'->new($_) };

declare 'RepeatedSpeechToTextConfig',
    as ArrayRef[SpeechToTextConfig()];

coerce 'RepeatedSpeechToTextConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::AudioConfig::SpeechToTextConfig'->new($_) } @$_ ] };

declare 'MapStringSpeechToTextConfig',
    as HashRef[SpeechToTextConfig()];

declare 'GeminiAsrConfig',
    as InstanceOf['Google::Cloud::Dialogflow::V2::AudioConfig::SpeechToTextConfig::GeminiAsrConfig'];

coerce 'GeminiAsrConfig',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::AudioConfig::SpeechToTextConfig::GeminiAsrConfig'->new($_) };

declare 'RepeatedGeminiAsrConfig',
    as ArrayRef[GeminiAsrConfig()];

coerce 'RepeatedGeminiAsrConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::AudioConfig::SpeechToTextConfig::GeminiAsrConfig'->new($_) } @$_ ] };

declare 'MapStringGeminiAsrConfig',
    as HashRef[GeminiAsrConfig()];

declare 'StartSensitivity',
    as (Int | Str);

declare 'EndSensitivity',
    as (Int | Str);

1;

__END__

=head1 NAME

Google::Cloud::Dialogflow::V2::AudioConfig::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
