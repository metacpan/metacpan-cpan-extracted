package Google::Cloud::Dialogflow::Cx::V3::AudioConfig::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'AudioEncoding',
    as (Int | Str);

declare 'SpeechModelVariant',
    as (Int | Str);

declare 'SsmlVoiceGender',
    as (Int | Str);

declare 'OutputAudioEncoding',
    as (Int | Str);

declare 'SpeechWordInfo',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3::AudioConfig::SpeechWordInfo'];

coerce 'SpeechWordInfo',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3::AudioConfig::SpeechWordInfo'->new($_) };

declare 'RepeatedSpeechWordInfo',
    as ArrayRef[SpeechWordInfo()];

coerce 'RepeatedSpeechWordInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3::AudioConfig::SpeechWordInfo'->new($_) } @$_ ] };

declare 'MapStringSpeechWordInfo',
    as HashRef[SpeechWordInfo()];

declare 'BargeInConfig',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3::AudioConfig::BargeInConfig'];

coerce 'BargeInConfig',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3::AudioConfig::BargeInConfig'->new($_) };

declare 'RepeatedBargeInConfig',
    as ArrayRef[BargeInConfig()];

coerce 'RepeatedBargeInConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3::AudioConfig::BargeInConfig'->new($_) } @$_ ] };

declare 'MapStringBargeInConfig',
    as HashRef[BargeInConfig()];

declare 'InputAudioConfig',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3::AudioConfig::InputAudioConfig'];

coerce 'InputAudioConfig',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3::AudioConfig::InputAudioConfig'->new($_) };

declare 'RepeatedInputAudioConfig',
    as ArrayRef[InputAudioConfig()];

coerce 'RepeatedInputAudioConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3::AudioConfig::InputAudioConfig'->new($_) } @$_ ] };

declare 'MapStringInputAudioConfig',
    as HashRef[InputAudioConfig()];

declare 'VoiceSelectionParams',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3::AudioConfig::VoiceSelectionParams'];

coerce 'VoiceSelectionParams',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3::AudioConfig::VoiceSelectionParams'->new($_) };

declare 'RepeatedVoiceSelectionParams',
    as ArrayRef[VoiceSelectionParams()];

coerce 'RepeatedVoiceSelectionParams',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3::AudioConfig::VoiceSelectionParams'->new($_) } @$_ ] };

declare 'MapStringVoiceSelectionParams',
    as HashRef[VoiceSelectionParams()];

declare 'SynthesizeSpeechConfig',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3::AudioConfig::SynthesizeSpeechConfig'];

coerce 'SynthesizeSpeechConfig',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3::AudioConfig::SynthesizeSpeechConfig'->new($_) };

declare 'RepeatedSynthesizeSpeechConfig',
    as ArrayRef[SynthesizeSpeechConfig()];

coerce 'RepeatedSynthesizeSpeechConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3::AudioConfig::SynthesizeSpeechConfig'->new($_) } @$_ ] };

declare 'MapStringSynthesizeSpeechConfig',
    as HashRef[SynthesizeSpeechConfig()];

declare 'OutputAudioConfig',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3::AudioConfig::OutputAudioConfig'];

coerce 'OutputAudioConfig',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3::AudioConfig::OutputAudioConfig'->new($_) };

declare 'RepeatedOutputAudioConfig',
    as ArrayRef[OutputAudioConfig()];

coerce 'RepeatedOutputAudioConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3::AudioConfig::OutputAudioConfig'->new($_) } @$_ ] };

declare 'MapStringOutputAudioConfig',
    as HashRef[OutputAudioConfig()];

declare 'TextToSpeechSettings',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3::AudioConfig::TextToSpeechSettings'];

coerce 'TextToSpeechSettings',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3::AudioConfig::TextToSpeechSettings'->new($_) };

declare 'RepeatedTextToSpeechSettings',
    as ArrayRef[TextToSpeechSettings()];

coerce 'RepeatedTextToSpeechSettings',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3::AudioConfig::TextToSpeechSettings'->new($_) } @$_ ] };

declare 'MapStringTextToSpeechSettings',
    as HashRef[TextToSpeechSettings()];

declare 'SynthesizeSpeechConfigsEntry',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3::AudioConfig::TextToSpeechSettings::SynthesizeSpeechConfigsEntry'];

coerce 'SynthesizeSpeechConfigsEntry',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3::AudioConfig::TextToSpeechSettings::SynthesizeSpeechConfigsEntry'->new($_) };

declare 'RepeatedSynthesizeSpeechConfigsEntry',
    as ArrayRef[SynthesizeSpeechConfigsEntry()];

coerce 'RepeatedSynthesizeSpeechConfigsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3::AudioConfig::TextToSpeechSettings::SynthesizeSpeechConfigsEntry'->new($_) } @$_ ] };

declare 'MapStringSynthesizeSpeechConfigsEntry',
    as HashRef[SynthesizeSpeechConfigsEntry()];

1;

__END__

=head1 NAME

Google::Cloud::Dialogflow::Cx::V3::AudioConfig::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
