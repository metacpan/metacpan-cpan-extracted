package Google::Cloud::Texttospeech::V1beta1::CloudTts::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'SsmlVoiceGender',
    as (Int | Str);

declare 'AudioEncoding',
    as (Int | Str);

declare 'ListVoicesRequest',
    as InstanceOf['Google::Cloud::Texttospeech::V1beta1::CloudTts::ListVoicesRequest'];

coerce 'ListVoicesRequest',
    from HashRef, via { 'Google::Cloud::Texttospeech::V1beta1::CloudTts::ListVoicesRequest'->new($_) };

declare 'RepeatedListVoicesRequest',
    as ArrayRef[ListVoicesRequest()];

coerce 'RepeatedListVoicesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Texttospeech::V1beta1::CloudTts::ListVoicesRequest'->new($_) } @$_ ] };

declare 'MapStringListVoicesRequest',
    as HashRef[ListVoicesRequest()];

declare 'ListVoicesResponse',
    as InstanceOf['Google::Cloud::Texttospeech::V1beta1::CloudTts::ListVoicesResponse'];

coerce 'ListVoicesResponse',
    from HashRef, via { 'Google::Cloud::Texttospeech::V1beta1::CloudTts::ListVoicesResponse'->new($_) };

declare 'RepeatedListVoicesResponse',
    as ArrayRef[ListVoicesResponse()];

coerce 'RepeatedListVoicesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Texttospeech::V1beta1::CloudTts::ListVoicesResponse'->new($_) } @$_ ] };

declare 'MapStringListVoicesResponse',
    as HashRef[ListVoicesResponse()];

declare 'Voice',
    as InstanceOf['Google::Cloud::Texttospeech::V1beta1::CloudTts::Voice'];

coerce 'Voice',
    from HashRef, via { 'Google::Cloud::Texttospeech::V1beta1::CloudTts::Voice'->new($_) };

declare 'RepeatedVoice',
    as ArrayRef[Voice()];

coerce 'RepeatedVoice',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Texttospeech::V1beta1::CloudTts::Voice'->new($_) } @$_ ] };

declare 'MapStringVoice',
    as HashRef[Voice()];

declare 'AdvancedVoiceOptions',
    as InstanceOf['Google::Cloud::Texttospeech::V1beta1::CloudTts::AdvancedVoiceOptions'];

coerce 'AdvancedVoiceOptions',
    from HashRef, via { 'Google::Cloud::Texttospeech::V1beta1::CloudTts::AdvancedVoiceOptions'->new($_) };

declare 'RepeatedAdvancedVoiceOptions',
    as ArrayRef[AdvancedVoiceOptions()];

coerce 'RepeatedAdvancedVoiceOptions',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Texttospeech::V1beta1::CloudTts::AdvancedVoiceOptions'->new($_) } @$_ ] };

declare 'MapStringAdvancedVoiceOptions',
    as HashRef[AdvancedVoiceOptions()];

declare 'HarmCategory',
    as (Int | Str);

declare 'HarmBlockThreshold',
    as (Int | Str);

declare 'SafetySetting',
    as InstanceOf['Google::Cloud::Texttospeech::V1beta1::CloudTts::AdvancedVoiceOptions::SafetySetting'];

coerce 'SafetySetting',
    from HashRef, via { 'Google::Cloud::Texttospeech::V1beta1::CloudTts::AdvancedVoiceOptions::SafetySetting'->new($_) };

declare 'RepeatedSafetySetting',
    as ArrayRef[SafetySetting()];

coerce 'RepeatedSafetySetting',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Texttospeech::V1beta1::CloudTts::AdvancedVoiceOptions::SafetySetting'->new($_) } @$_ ] };

declare 'MapStringSafetySetting',
    as HashRef[SafetySetting()];

declare 'SafetySettings',
    as InstanceOf['Google::Cloud::Texttospeech::V1beta1::CloudTts::AdvancedVoiceOptions::SafetySettings'];

coerce 'SafetySettings',
    from HashRef, via { 'Google::Cloud::Texttospeech::V1beta1::CloudTts::AdvancedVoiceOptions::SafetySettings'->new($_) };

declare 'RepeatedSafetySettings',
    as ArrayRef[SafetySettings()];

coerce 'RepeatedSafetySettings',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Texttospeech::V1beta1::CloudTts::AdvancedVoiceOptions::SafetySettings'->new($_) } @$_ ] };

declare 'MapStringSafetySettings',
    as HashRef[SafetySettings()];

declare 'SynthesizeSpeechRequest',
    as InstanceOf['Google::Cloud::Texttospeech::V1beta1::CloudTts::SynthesizeSpeechRequest'];

coerce 'SynthesizeSpeechRequest',
    from HashRef, via { 'Google::Cloud::Texttospeech::V1beta1::CloudTts::SynthesizeSpeechRequest'->new($_) };

declare 'RepeatedSynthesizeSpeechRequest',
    as ArrayRef[SynthesizeSpeechRequest()];

coerce 'RepeatedSynthesizeSpeechRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Texttospeech::V1beta1::CloudTts::SynthesizeSpeechRequest'->new($_) } @$_ ] };

declare 'MapStringSynthesizeSpeechRequest',
    as HashRef[SynthesizeSpeechRequest()];

declare 'TimepointType',
    as (Int | Str);

declare 'CustomPronunciationParams',
    as InstanceOf['Google::Cloud::Texttospeech::V1beta1::CloudTts::CustomPronunciationParams'];

coerce 'CustomPronunciationParams',
    from HashRef, via { 'Google::Cloud::Texttospeech::V1beta1::CloudTts::CustomPronunciationParams'->new($_) };

declare 'RepeatedCustomPronunciationParams',
    as ArrayRef[CustomPronunciationParams()];

coerce 'RepeatedCustomPronunciationParams',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Texttospeech::V1beta1::CloudTts::CustomPronunciationParams'->new($_) } @$_ ] };

declare 'MapStringCustomPronunciationParams',
    as HashRef[CustomPronunciationParams()];

declare 'PhoneticEncoding',
    as (Int | Str);

declare 'CustomPronunciations',
    as InstanceOf['Google::Cloud::Texttospeech::V1beta1::CloudTts::CustomPronunciations'];

coerce 'CustomPronunciations',
    from HashRef, via { 'Google::Cloud::Texttospeech::V1beta1::CloudTts::CustomPronunciations'->new($_) };

declare 'RepeatedCustomPronunciations',
    as ArrayRef[CustomPronunciations()];

coerce 'RepeatedCustomPronunciations',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Texttospeech::V1beta1::CloudTts::CustomPronunciations'->new($_) } @$_ ] };

declare 'MapStringCustomPronunciations',
    as HashRef[CustomPronunciations()];

declare 'MultiSpeakerMarkup',
    as InstanceOf['Google::Cloud::Texttospeech::V1beta1::CloudTts::MultiSpeakerMarkup'];

coerce 'MultiSpeakerMarkup',
    from HashRef, via { 'Google::Cloud::Texttospeech::V1beta1::CloudTts::MultiSpeakerMarkup'->new($_) };

declare 'RepeatedMultiSpeakerMarkup',
    as ArrayRef[MultiSpeakerMarkup()];

coerce 'RepeatedMultiSpeakerMarkup',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Texttospeech::V1beta1::CloudTts::MultiSpeakerMarkup'->new($_) } @$_ ] };

declare 'MapStringMultiSpeakerMarkup',
    as HashRef[MultiSpeakerMarkup()];

declare 'Turn',
    as InstanceOf['Google::Cloud::Texttospeech::V1beta1::CloudTts::MultiSpeakerMarkup::Turn'];

coerce 'Turn',
    from HashRef, via { 'Google::Cloud::Texttospeech::V1beta1::CloudTts::MultiSpeakerMarkup::Turn'->new($_) };

declare 'RepeatedTurn',
    as ArrayRef[Turn()];

coerce 'RepeatedTurn',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Texttospeech::V1beta1::CloudTts::MultiSpeakerMarkup::Turn'->new($_) } @$_ ] };

declare 'MapStringTurn',
    as HashRef[Turn()];

declare 'MultispeakerPrebuiltVoice',
    as InstanceOf['Google::Cloud::Texttospeech::V1beta1::CloudTts::MultispeakerPrebuiltVoice'];

coerce 'MultispeakerPrebuiltVoice',
    from HashRef, via { 'Google::Cloud::Texttospeech::V1beta1::CloudTts::MultispeakerPrebuiltVoice'->new($_) };

declare 'RepeatedMultispeakerPrebuiltVoice',
    as ArrayRef[MultispeakerPrebuiltVoice()];

coerce 'RepeatedMultispeakerPrebuiltVoice',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Texttospeech::V1beta1::CloudTts::MultispeakerPrebuiltVoice'->new($_) } @$_ ] };

declare 'MapStringMultispeakerPrebuiltVoice',
    as HashRef[MultispeakerPrebuiltVoice()];

declare 'MultiSpeakerVoiceConfig',
    as InstanceOf['Google::Cloud::Texttospeech::V1beta1::CloudTts::MultiSpeakerVoiceConfig'];

coerce 'MultiSpeakerVoiceConfig',
    from HashRef, via { 'Google::Cloud::Texttospeech::V1beta1::CloudTts::MultiSpeakerVoiceConfig'->new($_) };

declare 'RepeatedMultiSpeakerVoiceConfig',
    as ArrayRef[MultiSpeakerVoiceConfig()];

coerce 'RepeatedMultiSpeakerVoiceConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Texttospeech::V1beta1::CloudTts::MultiSpeakerVoiceConfig'->new($_) } @$_ ] };

declare 'MapStringMultiSpeakerVoiceConfig',
    as HashRef[MultiSpeakerVoiceConfig()];

declare 'SynthesisInput',
    as InstanceOf['Google::Cloud::Texttospeech::V1beta1::CloudTts::SynthesisInput'];

coerce 'SynthesisInput',
    from HashRef, via { 'Google::Cloud::Texttospeech::V1beta1::CloudTts::SynthesisInput'->new($_) };

declare 'RepeatedSynthesisInput',
    as ArrayRef[SynthesisInput()];

coerce 'RepeatedSynthesisInput',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Texttospeech::V1beta1::CloudTts::SynthesisInput'->new($_) } @$_ ] };

declare 'MapStringSynthesisInput',
    as HashRef[SynthesisInput()];

declare 'VoiceSelectionParams',
    as InstanceOf['Google::Cloud::Texttospeech::V1beta1::CloudTts::VoiceSelectionParams'];

coerce 'VoiceSelectionParams',
    from HashRef, via { 'Google::Cloud::Texttospeech::V1beta1::CloudTts::VoiceSelectionParams'->new($_) };

declare 'RepeatedVoiceSelectionParams',
    as ArrayRef[VoiceSelectionParams()];

coerce 'RepeatedVoiceSelectionParams',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Texttospeech::V1beta1::CloudTts::VoiceSelectionParams'->new($_) } @$_ ] };

declare 'MapStringVoiceSelectionParams',
    as HashRef[VoiceSelectionParams()];

declare 'AudioConfig',
    as InstanceOf['Google::Cloud::Texttospeech::V1beta1::CloudTts::AudioConfig'];

coerce 'AudioConfig',
    from HashRef, via { 'Google::Cloud::Texttospeech::V1beta1::CloudTts::AudioConfig'->new($_) };

declare 'RepeatedAudioConfig',
    as ArrayRef[AudioConfig()];

coerce 'RepeatedAudioConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Texttospeech::V1beta1::CloudTts::AudioConfig'->new($_) } @$_ ] };

declare 'MapStringAudioConfig',
    as HashRef[AudioConfig()];

declare 'CustomVoiceParams',
    as InstanceOf['Google::Cloud::Texttospeech::V1beta1::CloudTts::CustomVoiceParams'];

coerce 'CustomVoiceParams',
    from HashRef, via { 'Google::Cloud::Texttospeech::V1beta1::CloudTts::CustomVoiceParams'->new($_) };

declare 'RepeatedCustomVoiceParams',
    as ArrayRef[CustomVoiceParams()];

coerce 'RepeatedCustomVoiceParams',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Texttospeech::V1beta1::CloudTts::CustomVoiceParams'->new($_) } @$_ ] };

declare 'MapStringCustomVoiceParams',
    as HashRef[CustomVoiceParams()];

declare 'ReportedUsage',
    as (Int | Str);

declare 'VoiceCloneParams',
    as InstanceOf['Google::Cloud::Texttospeech::V1beta1::CloudTts::VoiceCloneParams'];

coerce 'VoiceCloneParams',
    from HashRef, via { 'Google::Cloud::Texttospeech::V1beta1::CloudTts::VoiceCloneParams'->new($_) };

declare 'RepeatedVoiceCloneParams',
    as ArrayRef[VoiceCloneParams()];

coerce 'RepeatedVoiceCloneParams',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Texttospeech::V1beta1::CloudTts::VoiceCloneParams'->new($_) } @$_ ] };

declare 'MapStringVoiceCloneParams',
    as HashRef[VoiceCloneParams()];

declare 'SynthesizeSpeechResponse',
    as InstanceOf['Google::Cloud::Texttospeech::V1beta1::CloudTts::SynthesizeSpeechResponse'];

coerce 'SynthesizeSpeechResponse',
    from HashRef, via { 'Google::Cloud::Texttospeech::V1beta1::CloudTts::SynthesizeSpeechResponse'->new($_) };

declare 'RepeatedSynthesizeSpeechResponse',
    as ArrayRef[SynthesizeSpeechResponse()];

coerce 'RepeatedSynthesizeSpeechResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Texttospeech::V1beta1::CloudTts::SynthesizeSpeechResponse'->new($_) } @$_ ] };

declare 'MapStringSynthesizeSpeechResponse',
    as HashRef[SynthesizeSpeechResponse()];

declare 'Timepoint',
    as InstanceOf['Google::Cloud::Texttospeech::V1beta1::CloudTts::Timepoint'];

coerce 'Timepoint',
    from HashRef, via { 'Google::Cloud::Texttospeech::V1beta1::CloudTts::Timepoint'->new($_) };

declare 'RepeatedTimepoint',
    as ArrayRef[Timepoint()];

coerce 'RepeatedTimepoint',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Texttospeech::V1beta1::CloudTts::Timepoint'->new($_) } @$_ ] };

declare 'MapStringTimepoint',
    as HashRef[Timepoint()];

declare 'StreamingAudioConfig',
    as InstanceOf['Google::Cloud::Texttospeech::V1beta1::CloudTts::StreamingAudioConfig'];

coerce 'StreamingAudioConfig',
    from HashRef, via { 'Google::Cloud::Texttospeech::V1beta1::CloudTts::StreamingAudioConfig'->new($_) };

declare 'RepeatedStreamingAudioConfig',
    as ArrayRef[StreamingAudioConfig()];

coerce 'RepeatedStreamingAudioConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Texttospeech::V1beta1::CloudTts::StreamingAudioConfig'->new($_) } @$_ ] };

declare 'MapStringStreamingAudioConfig',
    as HashRef[StreamingAudioConfig()];

declare 'StreamingSynthesizeConfig',
    as InstanceOf['Google::Cloud::Texttospeech::V1beta1::CloudTts::StreamingSynthesizeConfig'];

coerce 'StreamingSynthesizeConfig',
    from HashRef, via { 'Google::Cloud::Texttospeech::V1beta1::CloudTts::StreamingSynthesizeConfig'->new($_) };

declare 'RepeatedStreamingSynthesizeConfig',
    as ArrayRef[StreamingSynthesizeConfig()];

coerce 'RepeatedStreamingSynthesizeConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Texttospeech::V1beta1::CloudTts::StreamingSynthesizeConfig'->new($_) } @$_ ] };

declare 'MapStringStreamingSynthesizeConfig',
    as HashRef[StreamingSynthesizeConfig()];

declare 'StreamingSynthesisInput',
    as InstanceOf['Google::Cloud::Texttospeech::V1beta1::CloudTts::StreamingSynthesisInput'];

coerce 'StreamingSynthesisInput',
    from HashRef, via { 'Google::Cloud::Texttospeech::V1beta1::CloudTts::StreamingSynthesisInput'->new($_) };

declare 'RepeatedStreamingSynthesisInput',
    as ArrayRef[StreamingSynthesisInput()];

coerce 'RepeatedStreamingSynthesisInput',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Texttospeech::V1beta1::CloudTts::StreamingSynthesisInput'->new($_) } @$_ ] };

declare 'MapStringStreamingSynthesisInput',
    as HashRef[StreamingSynthesisInput()];

declare 'StreamingSynthesizeRequest',
    as InstanceOf['Google::Cloud::Texttospeech::V1beta1::CloudTts::StreamingSynthesizeRequest'];

coerce 'StreamingSynthesizeRequest',
    from HashRef, via { 'Google::Cloud::Texttospeech::V1beta1::CloudTts::StreamingSynthesizeRequest'->new($_) };

declare 'RepeatedStreamingSynthesizeRequest',
    as ArrayRef[StreamingSynthesizeRequest()];

coerce 'RepeatedStreamingSynthesizeRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Texttospeech::V1beta1::CloudTts::StreamingSynthesizeRequest'->new($_) } @$_ ] };

declare 'MapStringStreamingSynthesizeRequest',
    as HashRef[StreamingSynthesizeRequest()];

declare 'StreamingSynthesizeResponse',
    as InstanceOf['Google::Cloud::Texttospeech::V1beta1::CloudTts::StreamingSynthesizeResponse'];

coerce 'StreamingSynthesizeResponse',
    from HashRef, via { 'Google::Cloud::Texttospeech::V1beta1::CloudTts::StreamingSynthesizeResponse'->new($_) };

declare 'RepeatedStreamingSynthesizeResponse',
    as ArrayRef[StreamingSynthesizeResponse()];

coerce 'RepeatedStreamingSynthesizeResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Texttospeech::V1beta1::CloudTts::StreamingSynthesizeResponse'->new($_) } @$_ ] };

declare 'MapStringStreamingSynthesizeResponse',
    as HashRef[StreamingSynthesizeResponse()];

1;

__END__

=head1 NAME

Google::Cloud::Texttospeech::V1beta1::CloudTts::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
