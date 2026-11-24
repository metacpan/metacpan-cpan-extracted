package Google::Assistant::Embedded::V1alpha2::EmbeddedAssistant::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'AssistRequest',
    as InstanceOf['Google::Assistant::Embedded::V1alpha2::EmbeddedAssistant::AssistRequest'];

coerce 'AssistRequest',
    from HashRef, via { 'Google::Assistant::Embedded::V1alpha2::EmbeddedAssistant::AssistRequest'->new($_) };

declare 'RepeatedAssistRequest',
    as ArrayRef[AssistRequest()];

coerce 'RepeatedAssistRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Assistant::Embedded::V1alpha2::EmbeddedAssistant::AssistRequest'->new($_) } @$_ ] };

declare 'MapStringAssistRequest',
    as HashRef[AssistRequest()];

declare 'AssistResponse',
    as InstanceOf['Google::Assistant::Embedded::V1alpha2::EmbeddedAssistant::AssistResponse'];

coerce 'AssistResponse',
    from HashRef, via { 'Google::Assistant::Embedded::V1alpha2::EmbeddedAssistant::AssistResponse'->new($_) };

declare 'RepeatedAssistResponse',
    as ArrayRef[AssistResponse()];

coerce 'RepeatedAssistResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Assistant::Embedded::V1alpha2::EmbeddedAssistant::AssistResponse'->new($_) } @$_ ] };

declare 'MapStringAssistResponse',
    as HashRef[AssistResponse()];

declare 'EventType',
    as (Int | Str);

declare 'DebugInfo',
    as InstanceOf['Google::Assistant::Embedded::V1alpha2::EmbeddedAssistant::DebugInfo'];

coerce 'DebugInfo',
    from HashRef, via { 'Google::Assistant::Embedded::V1alpha2::EmbeddedAssistant::DebugInfo'->new($_) };

declare 'RepeatedDebugInfo',
    as ArrayRef[DebugInfo()];

coerce 'RepeatedDebugInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Assistant::Embedded::V1alpha2::EmbeddedAssistant::DebugInfo'->new($_) } @$_ ] };

declare 'MapStringDebugInfo',
    as HashRef[DebugInfo()];

declare 'AssistConfig',
    as InstanceOf['Google::Assistant::Embedded::V1alpha2::EmbeddedAssistant::AssistConfig'];

coerce 'AssistConfig',
    from HashRef, via { 'Google::Assistant::Embedded::V1alpha2::EmbeddedAssistant::AssistConfig'->new($_) };

declare 'RepeatedAssistConfig',
    as ArrayRef[AssistConfig()];

coerce 'RepeatedAssistConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Assistant::Embedded::V1alpha2::EmbeddedAssistant::AssistConfig'->new($_) } @$_ ] };

declare 'MapStringAssistConfig',
    as HashRef[AssistConfig()];

declare 'AudioInConfig',
    as InstanceOf['Google::Assistant::Embedded::V1alpha2::EmbeddedAssistant::AudioInConfig'];

coerce 'AudioInConfig',
    from HashRef, via { 'Google::Assistant::Embedded::V1alpha2::EmbeddedAssistant::AudioInConfig'->new($_) };

declare 'RepeatedAudioInConfig',
    as ArrayRef[AudioInConfig()];

coerce 'RepeatedAudioInConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Assistant::Embedded::V1alpha2::EmbeddedAssistant::AudioInConfig'->new($_) } @$_ ] };

declare 'MapStringAudioInConfig',
    as HashRef[AudioInConfig()];

declare 'Encoding',
    as (Int | Str);

declare 'AudioOutConfig',
    as InstanceOf['Google::Assistant::Embedded::V1alpha2::EmbeddedAssistant::AudioOutConfig'];

coerce 'AudioOutConfig',
    from HashRef, via { 'Google::Assistant::Embedded::V1alpha2::EmbeddedAssistant::AudioOutConfig'->new($_) };

declare 'RepeatedAudioOutConfig',
    as ArrayRef[AudioOutConfig()];

coerce 'RepeatedAudioOutConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Assistant::Embedded::V1alpha2::EmbeddedAssistant::AudioOutConfig'->new($_) } @$_ ] };

declare 'MapStringAudioOutConfig',
    as HashRef[AudioOutConfig()];

declare 'Encoding',
    as (Int | Str);

declare 'ScreenOutConfig',
    as InstanceOf['Google::Assistant::Embedded::V1alpha2::EmbeddedAssistant::ScreenOutConfig'];

coerce 'ScreenOutConfig',
    from HashRef, via { 'Google::Assistant::Embedded::V1alpha2::EmbeddedAssistant::ScreenOutConfig'->new($_) };

declare 'RepeatedScreenOutConfig',
    as ArrayRef[ScreenOutConfig()];

coerce 'RepeatedScreenOutConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Assistant::Embedded::V1alpha2::EmbeddedAssistant::ScreenOutConfig'->new($_) } @$_ ] };

declare 'MapStringScreenOutConfig',
    as HashRef[ScreenOutConfig()];

declare 'ScreenMode',
    as (Int | Str);

declare 'DialogStateIn',
    as InstanceOf['Google::Assistant::Embedded::V1alpha2::EmbeddedAssistant::DialogStateIn'];

coerce 'DialogStateIn',
    from HashRef, via { 'Google::Assistant::Embedded::V1alpha2::EmbeddedAssistant::DialogStateIn'->new($_) };

declare 'RepeatedDialogStateIn',
    as ArrayRef[DialogStateIn()];

coerce 'RepeatedDialogStateIn',
    from ArrayRef[HashRef], via { [ map { 'Google::Assistant::Embedded::V1alpha2::EmbeddedAssistant::DialogStateIn'->new($_) } @$_ ] };

declare 'MapStringDialogStateIn',
    as HashRef[DialogStateIn()];

declare 'DeviceConfig',
    as InstanceOf['Google::Assistant::Embedded::V1alpha2::EmbeddedAssistant::DeviceConfig'];

coerce 'DeviceConfig',
    from HashRef, via { 'Google::Assistant::Embedded::V1alpha2::EmbeddedAssistant::DeviceConfig'->new($_) };

declare 'RepeatedDeviceConfig',
    as ArrayRef[DeviceConfig()];

coerce 'RepeatedDeviceConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Assistant::Embedded::V1alpha2::EmbeddedAssistant::DeviceConfig'->new($_) } @$_ ] };

declare 'MapStringDeviceConfig',
    as HashRef[DeviceConfig()];

declare 'AudioOut',
    as InstanceOf['Google::Assistant::Embedded::V1alpha2::EmbeddedAssistant::AudioOut'];

coerce 'AudioOut',
    from HashRef, via { 'Google::Assistant::Embedded::V1alpha2::EmbeddedAssistant::AudioOut'->new($_) };

declare 'RepeatedAudioOut',
    as ArrayRef[AudioOut()];

coerce 'RepeatedAudioOut',
    from ArrayRef[HashRef], via { [ map { 'Google::Assistant::Embedded::V1alpha2::EmbeddedAssistant::AudioOut'->new($_) } @$_ ] };

declare 'MapStringAudioOut',
    as HashRef[AudioOut()];

declare 'ScreenOut',
    as InstanceOf['Google::Assistant::Embedded::V1alpha2::EmbeddedAssistant::ScreenOut'];

coerce 'ScreenOut',
    from HashRef, via { 'Google::Assistant::Embedded::V1alpha2::EmbeddedAssistant::ScreenOut'->new($_) };

declare 'RepeatedScreenOut',
    as ArrayRef[ScreenOut()];

coerce 'RepeatedScreenOut',
    from ArrayRef[HashRef], via { [ map { 'Google::Assistant::Embedded::V1alpha2::EmbeddedAssistant::ScreenOut'->new($_) } @$_ ] };

declare 'MapStringScreenOut',
    as HashRef[ScreenOut()];

declare 'Format',
    as (Int | Str);

declare 'DeviceAction',
    as InstanceOf['Google::Assistant::Embedded::V1alpha2::EmbeddedAssistant::DeviceAction'];

coerce 'DeviceAction',
    from HashRef, via { 'Google::Assistant::Embedded::V1alpha2::EmbeddedAssistant::DeviceAction'->new($_) };

declare 'RepeatedDeviceAction',
    as ArrayRef[DeviceAction()];

coerce 'RepeatedDeviceAction',
    from ArrayRef[HashRef], via { [ map { 'Google::Assistant::Embedded::V1alpha2::EmbeddedAssistant::DeviceAction'->new($_) } @$_ ] };

declare 'MapStringDeviceAction',
    as HashRef[DeviceAction()];

declare 'SpeechRecognitionResult',
    as InstanceOf['Google::Assistant::Embedded::V1alpha2::EmbeddedAssistant::SpeechRecognitionResult'];

coerce 'SpeechRecognitionResult',
    from HashRef, via { 'Google::Assistant::Embedded::V1alpha2::EmbeddedAssistant::SpeechRecognitionResult'->new($_) };

declare 'RepeatedSpeechRecognitionResult',
    as ArrayRef[SpeechRecognitionResult()];

coerce 'RepeatedSpeechRecognitionResult',
    from ArrayRef[HashRef], via { [ map { 'Google::Assistant::Embedded::V1alpha2::EmbeddedAssistant::SpeechRecognitionResult'->new($_) } @$_ ] };

declare 'MapStringSpeechRecognitionResult',
    as HashRef[SpeechRecognitionResult()];

declare 'DialogStateOut',
    as InstanceOf['Google::Assistant::Embedded::V1alpha2::EmbeddedAssistant::DialogStateOut'];

coerce 'DialogStateOut',
    from HashRef, via { 'Google::Assistant::Embedded::V1alpha2::EmbeddedAssistant::DialogStateOut'->new($_) };

declare 'RepeatedDialogStateOut',
    as ArrayRef[DialogStateOut()];

coerce 'RepeatedDialogStateOut',
    from ArrayRef[HashRef], via { [ map { 'Google::Assistant::Embedded::V1alpha2::EmbeddedAssistant::DialogStateOut'->new($_) } @$_ ] };

declare 'MapStringDialogStateOut',
    as HashRef[DialogStateOut()];

declare 'MicrophoneMode',
    as (Int | Str);

declare 'DebugConfig',
    as InstanceOf['Google::Assistant::Embedded::V1alpha2::EmbeddedAssistant::DebugConfig'];

coerce 'DebugConfig',
    from HashRef, via { 'Google::Assistant::Embedded::V1alpha2::EmbeddedAssistant::DebugConfig'->new($_) };

declare 'RepeatedDebugConfig',
    as ArrayRef[DebugConfig()];

coerce 'RepeatedDebugConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Assistant::Embedded::V1alpha2::EmbeddedAssistant::DebugConfig'->new($_) } @$_ ] };

declare 'MapStringDebugConfig',
    as HashRef[DebugConfig()];

declare 'DeviceLocation',
    as InstanceOf['Google::Assistant::Embedded::V1alpha2::EmbeddedAssistant::DeviceLocation'];

coerce 'DeviceLocation',
    from HashRef, via { 'Google::Assistant::Embedded::V1alpha2::EmbeddedAssistant::DeviceLocation'->new($_) };

declare 'RepeatedDeviceLocation',
    as ArrayRef[DeviceLocation()];

coerce 'RepeatedDeviceLocation',
    from ArrayRef[HashRef], via { [ map { 'Google::Assistant::Embedded::V1alpha2::EmbeddedAssistant::DeviceLocation'->new($_) } @$_ ] };

declare 'MapStringDeviceLocation',
    as HashRef[DeviceLocation()];

1;

__END__

=head1 NAME

Google::Assistant::Embedded::V1alpha2::EmbeddedAssistant::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
