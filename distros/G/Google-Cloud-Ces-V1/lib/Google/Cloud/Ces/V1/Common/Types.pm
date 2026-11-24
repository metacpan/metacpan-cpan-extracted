package Google::Cloud::Ces::V1::Common::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'ExecutionType',
    as (Int | Str);

declare 'Callback',
    as InstanceOf['Google::Cloud::Ces::V1::Common::Callback'];

coerce 'Callback',
    from HashRef, via { 'Google::Cloud::Ces::V1::Common::Callback'->new($_) };

declare 'RepeatedCallback',
    as ArrayRef[Callback()];

coerce 'RepeatedCallback',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1::Common::Callback'->new($_) } @$_ ] };

declare 'MapStringCallback',
    as HashRef[Callback()];

declare 'ModelSettings',
    as InstanceOf['Google::Cloud::Ces::V1::Common::ModelSettings'];

coerce 'ModelSettings',
    from HashRef, via { 'Google::Cloud::Ces::V1::Common::ModelSettings'->new($_) };

declare 'RepeatedModelSettings',
    as ArrayRef[ModelSettings()];

coerce 'RepeatedModelSettings',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1::Common::ModelSettings'->new($_) } @$_ ] };

declare 'MapStringModelSettings',
    as HashRef[ModelSettings()];

declare 'TriggerAction',
    as InstanceOf['Google::Cloud::Ces::V1::Common::TriggerAction'];

coerce 'TriggerAction',
    from HashRef, via { 'Google::Cloud::Ces::V1::Common::TriggerAction'->new($_) };

declare 'RepeatedTriggerAction',
    as ArrayRef[TriggerAction()];

coerce 'RepeatedTriggerAction',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1::Common::TriggerAction'->new($_) } @$_ ] };

declare 'MapStringTriggerAction',
    as HashRef[TriggerAction()];

declare 'Response',
    as InstanceOf['Google::Cloud::Ces::V1::Common::TriggerAction::Response'];

coerce 'Response',
    from HashRef, via { 'Google::Cloud::Ces::V1::Common::TriggerAction::Response'->new($_) };

declare 'RepeatedResponse',
    as ArrayRef[Response()];

coerce 'RepeatedResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1::Common::TriggerAction::Response'->new($_) } @$_ ] };

declare 'MapStringResponse',
    as HashRef[Response()];

declare 'RespondImmediately',
    as InstanceOf['Google::Cloud::Ces::V1::Common::TriggerAction::RespondImmediately'];

coerce 'RespondImmediately',
    from HashRef, via { 'Google::Cloud::Ces::V1::Common::TriggerAction::RespondImmediately'->new($_) };

declare 'RepeatedRespondImmediately',
    as ArrayRef[RespondImmediately()];

coerce 'RepeatedRespondImmediately',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1::Common::TriggerAction::RespondImmediately'->new($_) } @$_ ] };

declare 'MapStringRespondImmediately',
    as HashRef[RespondImmediately()];

declare 'GenerativeAnswer',
    as InstanceOf['Google::Cloud::Ces::V1::Common::TriggerAction::GenerativeAnswer'];

coerce 'GenerativeAnswer',
    from HashRef, via { 'Google::Cloud::Ces::V1::Common::TriggerAction::GenerativeAnswer'->new($_) };

declare 'RepeatedGenerativeAnswer',
    as ArrayRef[GenerativeAnswer()];

coerce 'RepeatedGenerativeAnswer',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1::Common::TriggerAction::GenerativeAnswer'->new($_) } @$_ ] };

declare 'MapStringGenerativeAnswer',
    as HashRef[GenerativeAnswer()];

declare 'TransferAgent',
    as InstanceOf['Google::Cloud::Ces::V1::Common::TriggerAction::TransferAgent'];

coerce 'TransferAgent',
    from HashRef, via { 'Google::Cloud::Ces::V1::Common::TriggerAction::TransferAgent'->new($_) };

declare 'RepeatedTransferAgent',
    as ArrayRef[TransferAgent()];

coerce 'RepeatedTransferAgent',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1::Common::TriggerAction::TransferAgent'->new($_) } @$_ ] };

declare 'MapStringTransferAgent',
    as HashRef[TransferAgent()];

declare 'TlsConfig',
    as InstanceOf['Google::Cloud::Ces::V1::Common::TlsConfig'];

coerce 'TlsConfig',
    from HashRef, via { 'Google::Cloud::Ces::V1::Common::TlsConfig'->new($_) };

declare 'RepeatedTlsConfig',
    as ArrayRef[TlsConfig()];

coerce 'RepeatedTlsConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1::Common::TlsConfig'->new($_) } @$_ ] };

declare 'MapStringTlsConfig',
    as HashRef[TlsConfig()];

declare 'CaCert',
    as InstanceOf['Google::Cloud::Ces::V1::Common::TlsConfig::CaCert'];

coerce 'CaCert',
    from HashRef, via { 'Google::Cloud::Ces::V1::Common::TlsConfig::CaCert'->new($_) };

declare 'RepeatedCaCert',
    as ArrayRef[CaCert()];

coerce 'RepeatedCaCert',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1::Common::TlsConfig::CaCert'->new($_) } @$_ ] };

declare 'MapStringCaCert',
    as HashRef[CaCert()];

declare 'ServiceDirectoryConfig',
    as InstanceOf['Google::Cloud::Ces::V1::Common::ServiceDirectoryConfig'];

coerce 'ServiceDirectoryConfig',
    from HashRef, via { 'Google::Cloud::Ces::V1::Common::ServiceDirectoryConfig'->new($_) };

declare 'RepeatedServiceDirectoryConfig',
    as ArrayRef[ServiceDirectoryConfig()];

coerce 'RepeatedServiceDirectoryConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1::Common::ServiceDirectoryConfig'->new($_) } @$_ ] };

declare 'MapStringServiceDirectoryConfig',
    as HashRef[ServiceDirectoryConfig()];

declare 'ChannelProfile',
    as InstanceOf['Google::Cloud::Ces::V1::Common::ChannelProfile'];

coerce 'ChannelProfile',
    from HashRef, via { 'Google::Cloud::Ces::V1::Common::ChannelProfile'->new($_) };

declare 'RepeatedChannelProfile',
    as ArrayRef[ChannelProfile()];

coerce 'RepeatedChannelProfile',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1::Common::ChannelProfile'->new($_) } @$_ ] };

declare 'MapStringChannelProfile',
    as HashRef[ChannelProfile()];

declare 'ChannelType',
    as (Int | Str);

declare 'PersonaProperty',
    as InstanceOf['Google::Cloud::Ces::V1::Common::ChannelProfile::PersonaProperty'];

coerce 'PersonaProperty',
    from HashRef, via { 'Google::Cloud::Ces::V1::Common::ChannelProfile::PersonaProperty'->new($_) };

declare 'RepeatedPersonaProperty',
    as ArrayRef[PersonaProperty()];

coerce 'RepeatedPersonaProperty',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1::Common::ChannelProfile::PersonaProperty'->new($_) } @$_ ] };

declare 'MapStringPersonaProperty',
    as HashRef[PersonaProperty()];

declare 'Persona',
    as (Int | Str);

declare 'WebWidgetConfig',
    as InstanceOf['Google::Cloud::Ces::V1::Common::ChannelProfile::WebWidgetConfig'];

coerce 'WebWidgetConfig',
    from HashRef, via { 'Google::Cloud::Ces::V1::Common::ChannelProfile::WebWidgetConfig'->new($_) };

declare 'RepeatedWebWidgetConfig',
    as ArrayRef[WebWidgetConfig()];

coerce 'RepeatedWebWidgetConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1::Common::ChannelProfile::WebWidgetConfig'->new($_) } @$_ ] };

declare 'MapStringWebWidgetConfig',
    as HashRef[WebWidgetConfig()];

declare 'Modality',
    as (Int | Str);

declare 'Theme',
    as (Int | Str);

declare 'SecuritySettings',
    as InstanceOf['Google::Cloud::Ces::V1::Common::ChannelProfile::WebWidgetConfig::SecuritySettings'];

coerce 'SecuritySettings',
    from HashRef, via { 'Google::Cloud::Ces::V1::Common::ChannelProfile::WebWidgetConfig::SecuritySettings'->new($_) };

declare 'RepeatedSecuritySettings',
    as ArrayRef[SecuritySettings()];

coerce 'RepeatedSecuritySettings',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1::Common::ChannelProfile::WebWidgetConfig::SecuritySettings'->new($_) } @$_ ] };

declare 'MapStringSecuritySettings',
    as HashRef[SecuritySettings()];

declare 'WhatsAppConfig',
    as InstanceOf['Google::Cloud::Ces::V1::Common::ChannelProfile::WhatsAppConfig'];

coerce 'WhatsAppConfig',
    from HashRef, via { 'Google::Cloud::Ces::V1::Common::ChannelProfile::WhatsAppConfig'->new($_) };

declare 'RepeatedWhatsAppConfig',
    as ArrayRef[WhatsAppConfig()];

coerce 'RepeatedWhatsAppConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1::Common::ChannelProfile::WhatsAppConfig'->new($_) } @$_ ] };

declare 'MapStringWhatsAppConfig',
    as HashRef[WhatsAppConfig()];

declare 'InstagramConfig',
    as InstanceOf['Google::Cloud::Ces::V1::Common::ChannelProfile::InstagramConfig'];

coerce 'InstagramConfig',
    from HashRef, via { 'Google::Cloud::Ces::V1::Common::ChannelProfile::InstagramConfig'->new($_) };

declare 'RepeatedInstagramConfig',
    as ArrayRef[InstagramConfig()];

coerce 'RepeatedInstagramConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1::Common::ChannelProfile::InstagramConfig'->new($_) } @$_ ] };

declare 'MapStringInstagramConfig',
    as HashRef[InstagramConfig()];

declare 'Span',
    as InstanceOf['Google::Cloud::Ces::V1::Common::Span'];

coerce 'Span',
    from HashRef, via { 'Google::Cloud::Ces::V1::Common::Span'->new($_) };

declare 'RepeatedSpan',
    as ArrayRef[Span()];

coerce 'RepeatedSpan',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1::Common::Span'->new($_) } @$_ ] };

declare 'MapStringSpan',
    as HashRef[Span()];

1;

__END__

=head1 NAME

Google::Cloud::Ces::V1::Common::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
