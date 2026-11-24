package Google::Assistant::Embedded::V1alpha1::EmbeddedAssistant::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'ConverseConfig',
    as InstanceOf['Google::Assistant::Embedded::V1alpha1::EmbeddedAssistant::ConverseConfig'];

coerce 'ConverseConfig',
    from HashRef, via { 'Google::Assistant::Embedded::V1alpha1::EmbeddedAssistant::ConverseConfig'->new($_) };

declare 'RepeatedConverseConfig',
    as ArrayRef[ConverseConfig()];

coerce 'RepeatedConverseConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Assistant::Embedded::V1alpha1::EmbeddedAssistant::ConverseConfig'->new($_) } @$_ ] };

declare 'MapStringConverseConfig',
    as HashRef[ConverseConfig()];

declare 'AudioInConfig',
    as InstanceOf['Google::Assistant::Embedded::V1alpha1::EmbeddedAssistant::AudioInConfig'];

coerce 'AudioInConfig',
    from HashRef, via { 'Google::Assistant::Embedded::V1alpha1::EmbeddedAssistant::AudioInConfig'->new($_) };

declare 'RepeatedAudioInConfig',
    as ArrayRef[AudioInConfig()];

coerce 'RepeatedAudioInConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Assistant::Embedded::V1alpha1::EmbeddedAssistant::AudioInConfig'->new($_) } @$_ ] };

declare 'MapStringAudioInConfig',
    as HashRef[AudioInConfig()];

declare 'Encoding',
    as (Int | Str);

declare 'AudioOutConfig',
    as InstanceOf['Google::Assistant::Embedded::V1alpha1::EmbeddedAssistant::AudioOutConfig'];

coerce 'AudioOutConfig',
    from HashRef, via { 'Google::Assistant::Embedded::V1alpha1::EmbeddedAssistant::AudioOutConfig'->new($_) };

declare 'RepeatedAudioOutConfig',
    as ArrayRef[AudioOutConfig()];

coerce 'RepeatedAudioOutConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Assistant::Embedded::V1alpha1::EmbeddedAssistant::AudioOutConfig'->new($_) } @$_ ] };

declare 'MapStringAudioOutConfig',
    as HashRef[AudioOutConfig()];

declare 'Encoding',
    as (Int | Str);

declare 'ConverseState',
    as InstanceOf['Google::Assistant::Embedded::V1alpha1::EmbeddedAssistant::ConverseState'];

coerce 'ConverseState',
    from HashRef, via { 'Google::Assistant::Embedded::V1alpha1::EmbeddedAssistant::ConverseState'->new($_) };

declare 'RepeatedConverseState',
    as ArrayRef[ConverseState()];

coerce 'RepeatedConverseState',
    from ArrayRef[HashRef], via { [ map { 'Google::Assistant::Embedded::V1alpha1::EmbeddedAssistant::ConverseState'->new($_) } @$_ ] };

declare 'MapStringConverseState',
    as HashRef[ConverseState()];

declare 'AudioOut',
    as InstanceOf['Google::Assistant::Embedded::V1alpha1::EmbeddedAssistant::AudioOut'];

coerce 'AudioOut',
    from HashRef, via { 'Google::Assistant::Embedded::V1alpha1::EmbeddedAssistant::AudioOut'->new($_) };

declare 'RepeatedAudioOut',
    as ArrayRef[AudioOut()];

coerce 'RepeatedAudioOut',
    from ArrayRef[HashRef], via { [ map { 'Google::Assistant::Embedded::V1alpha1::EmbeddedAssistant::AudioOut'->new($_) } @$_ ] };

declare 'MapStringAudioOut',
    as HashRef[AudioOut()];

declare 'ConverseResult',
    as InstanceOf['Google::Assistant::Embedded::V1alpha1::EmbeddedAssistant::ConverseResult'];

coerce 'ConverseResult',
    from HashRef, via { 'Google::Assistant::Embedded::V1alpha1::EmbeddedAssistant::ConverseResult'->new($_) };

declare 'RepeatedConverseResult',
    as ArrayRef[ConverseResult()];

coerce 'RepeatedConverseResult',
    from ArrayRef[HashRef], via { [ map { 'Google::Assistant::Embedded::V1alpha1::EmbeddedAssistant::ConverseResult'->new($_) } @$_ ] };

declare 'MapStringConverseResult',
    as HashRef[ConverseResult()];

declare 'MicrophoneMode',
    as (Int | Str);

declare 'ConverseRequest',
    as InstanceOf['Google::Assistant::Embedded::V1alpha1::EmbeddedAssistant::ConverseRequest'];

coerce 'ConverseRequest',
    from HashRef, via { 'Google::Assistant::Embedded::V1alpha1::EmbeddedAssistant::ConverseRequest'->new($_) };

declare 'RepeatedConverseRequest',
    as ArrayRef[ConverseRequest()];

coerce 'RepeatedConverseRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Assistant::Embedded::V1alpha1::EmbeddedAssistant::ConverseRequest'->new($_) } @$_ ] };

declare 'MapStringConverseRequest',
    as HashRef[ConverseRequest()];

declare 'ConverseResponse',
    as InstanceOf['Google::Assistant::Embedded::V1alpha1::EmbeddedAssistant::ConverseResponse'];

coerce 'ConverseResponse',
    from HashRef, via { 'Google::Assistant::Embedded::V1alpha1::EmbeddedAssistant::ConverseResponse'->new($_) };

declare 'RepeatedConverseResponse',
    as ArrayRef[ConverseResponse()];

coerce 'RepeatedConverseResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Assistant::Embedded::V1alpha1::EmbeddedAssistant::ConverseResponse'->new($_) } @$_ ] };

declare 'MapStringConverseResponse',
    as HashRef[ConverseResponse()];

declare 'EventType',
    as (Int | Str);

1;

__END__

=head1 NAME

Google::Assistant::Embedded::V1alpha1::EmbeddedAssistant::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
