package Google::Cloud::Iot::V1::Resources::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'MqttState',
    as (Int | Str);

declare 'HttpState',
    as (Int | Str);

declare 'LogLevel',
    as (Int | Str);

declare 'GatewayType',
    as (Int | Str);

declare 'GatewayAuthMethod',
    as (Int | Str);

declare 'PublicKeyCertificateFormat',
    as (Int | Str);

declare 'PublicKeyFormat',
    as (Int | Str);

declare 'Device',
    as InstanceOf['Google::Cloud::Iot::V1::Resources::Device'];

coerce 'Device',
    from HashRef, via { 'Google::Cloud::Iot::V1::Resources::Device'->new($_) };

declare 'RepeatedDevice',
    as ArrayRef[Device()];

coerce 'RepeatedDevice',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Iot::V1::Resources::Device'->new($_) } @$_ ] };

declare 'MapStringDevice',
    as HashRef[Device()];

declare 'MetadataEntry',
    as InstanceOf['Google::Cloud::Iot::V1::Resources::Device::MetadataEntry'];

coerce 'MetadataEntry',
    from HashRef, via { 'Google::Cloud::Iot::V1::Resources::Device::MetadataEntry'->new($_) };

declare 'RepeatedMetadataEntry',
    as ArrayRef[MetadataEntry()];

coerce 'RepeatedMetadataEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Iot::V1::Resources::Device::MetadataEntry'->new($_) } @$_ ] };

declare 'MapStringMetadataEntry',
    as HashRef[MetadataEntry()];

declare 'GatewayConfig',
    as InstanceOf['Google::Cloud::Iot::V1::Resources::GatewayConfig'];

coerce 'GatewayConfig',
    from HashRef, via { 'Google::Cloud::Iot::V1::Resources::GatewayConfig'->new($_) };

declare 'RepeatedGatewayConfig',
    as ArrayRef[GatewayConfig()];

coerce 'RepeatedGatewayConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Iot::V1::Resources::GatewayConfig'->new($_) } @$_ ] };

declare 'MapStringGatewayConfig',
    as HashRef[GatewayConfig()];

declare 'DeviceRegistry',
    as InstanceOf['Google::Cloud::Iot::V1::Resources::DeviceRegistry'];

coerce 'DeviceRegistry',
    from HashRef, via { 'Google::Cloud::Iot::V1::Resources::DeviceRegistry'->new($_) };

declare 'RepeatedDeviceRegistry',
    as ArrayRef[DeviceRegistry()];

coerce 'RepeatedDeviceRegistry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Iot::V1::Resources::DeviceRegistry'->new($_) } @$_ ] };

declare 'MapStringDeviceRegistry',
    as HashRef[DeviceRegistry()];

declare 'MqttConfig',
    as InstanceOf['Google::Cloud::Iot::V1::Resources::MqttConfig'];

coerce 'MqttConfig',
    from HashRef, via { 'Google::Cloud::Iot::V1::Resources::MqttConfig'->new($_) };

declare 'RepeatedMqttConfig',
    as ArrayRef[MqttConfig()];

coerce 'RepeatedMqttConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Iot::V1::Resources::MqttConfig'->new($_) } @$_ ] };

declare 'MapStringMqttConfig',
    as HashRef[MqttConfig()];

declare 'HttpConfig',
    as InstanceOf['Google::Cloud::Iot::V1::Resources::HttpConfig'];

coerce 'HttpConfig',
    from HashRef, via { 'Google::Cloud::Iot::V1::Resources::HttpConfig'->new($_) };

declare 'RepeatedHttpConfig',
    as ArrayRef[HttpConfig()];

coerce 'RepeatedHttpConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Iot::V1::Resources::HttpConfig'->new($_) } @$_ ] };

declare 'MapStringHttpConfig',
    as HashRef[HttpConfig()];

declare 'EventNotificationConfig',
    as InstanceOf['Google::Cloud::Iot::V1::Resources::EventNotificationConfig'];

coerce 'EventNotificationConfig',
    from HashRef, via { 'Google::Cloud::Iot::V1::Resources::EventNotificationConfig'->new($_) };

declare 'RepeatedEventNotificationConfig',
    as ArrayRef[EventNotificationConfig()];

coerce 'RepeatedEventNotificationConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Iot::V1::Resources::EventNotificationConfig'->new($_) } @$_ ] };

declare 'MapStringEventNotificationConfig',
    as HashRef[EventNotificationConfig()];

declare 'StateNotificationConfig',
    as InstanceOf['Google::Cloud::Iot::V1::Resources::StateNotificationConfig'];

coerce 'StateNotificationConfig',
    from HashRef, via { 'Google::Cloud::Iot::V1::Resources::StateNotificationConfig'->new($_) };

declare 'RepeatedStateNotificationConfig',
    as ArrayRef[StateNotificationConfig()];

coerce 'RepeatedStateNotificationConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Iot::V1::Resources::StateNotificationConfig'->new($_) } @$_ ] };

declare 'MapStringStateNotificationConfig',
    as HashRef[StateNotificationConfig()];

declare 'RegistryCredential',
    as InstanceOf['Google::Cloud::Iot::V1::Resources::RegistryCredential'];

coerce 'RegistryCredential',
    from HashRef, via { 'Google::Cloud::Iot::V1::Resources::RegistryCredential'->new($_) };

declare 'RepeatedRegistryCredential',
    as ArrayRef[RegistryCredential()];

coerce 'RepeatedRegistryCredential',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Iot::V1::Resources::RegistryCredential'->new($_) } @$_ ] };

declare 'MapStringRegistryCredential',
    as HashRef[RegistryCredential()];

declare 'X509CertificateDetails',
    as InstanceOf['Google::Cloud::Iot::V1::Resources::X509CertificateDetails'];

coerce 'X509CertificateDetails',
    from HashRef, via { 'Google::Cloud::Iot::V1::Resources::X509CertificateDetails'->new($_) };

declare 'RepeatedX509CertificateDetails',
    as ArrayRef[X509CertificateDetails()];

coerce 'RepeatedX509CertificateDetails',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Iot::V1::Resources::X509CertificateDetails'->new($_) } @$_ ] };

declare 'MapStringX509CertificateDetails',
    as HashRef[X509CertificateDetails()];

declare 'PublicKeyCertificate',
    as InstanceOf['Google::Cloud::Iot::V1::Resources::PublicKeyCertificate'];

coerce 'PublicKeyCertificate',
    from HashRef, via { 'Google::Cloud::Iot::V1::Resources::PublicKeyCertificate'->new($_) };

declare 'RepeatedPublicKeyCertificate',
    as ArrayRef[PublicKeyCertificate()];

coerce 'RepeatedPublicKeyCertificate',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Iot::V1::Resources::PublicKeyCertificate'->new($_) } @$_ ] };

declare 'MapStringPublicKeyCertificate',
    as HashRef[PublicKeyCertificate()];

declare 'DeviceCredential',
    as InstanceOf['Google::Cloud::Iot::V1::Resources::DeviceCredential'];

coerce 'DeviceCredential',
    from HashRef, via { 'Google::Cloud::Iot::V1::Resources::DeviceCredential'->new($_) };

declare 'RepeatedDeviceCredential',
    as ArrayRef[DeviceCredential()];

coerce 'RepeatedDeviceCredential',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Iot::V1::Resources::DeviceCredential'->new($_) } @$_ ] };

declare 'MapStringDeviceCredential',
    as HashRef[DeviceCredential()];

declare 'PublicKeyCredential',
    as InstanceOf['Google::Cloud::Iot::V1::Resources::PublicKeyCredential'];

coerce 'PublicKeyCredential',
    from HashRef, via { 'Google::Cloud::Iot::V1::Resources::PublicKeyCredential'->new($_) };

declare 'RepeatedPublicKeyCredential',
    as ArrayRef[PublicKeyCredential()];

coerce 'RepeatedPublicKeyCredential',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Iot::V1::Resources::PublicKeyCredential'->new($_) } @$_ ] };

declare 'MapStringPublicKeyCredential',
    as HashRef[PublicKeyCredential()];

declare 'DeviceConfig',
    as InstanceOf['Google::Cloud::Iot::V1::Resources::DeviceConfig'];

coerce 'DeviceConfig',
    from HashRef, via { 'Google::Cloud::Iot::V1::Resources::DeviceConfig'->new($_) };

declare 'RepeatedDeviceConfig',
    as ArrayRef[DeviceConfig()];

coerce 'RepeatedDeviceConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Iot::V1::Resources::DeviceConfig'->new($_) } @$_ ] };

declare 'MapStringDeviceConfig',
    as HashRef[DeviceConfig()];

declare 'DeviceState',
    as InstanceOf['Google::Cloud::Iot::V1::Resources::DeviceState'];

coerce 'DeviceState',
    from HashRef, via { 'Google::Cloud::Iot::V1::Resources::DeviceState'->new($_) };

declare 'RepeatedDeviceState',
    as ArrayRef[DeviceState()];

coerce 'RepeatedDeviceState',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Iot::V1::Resources::DeviceState'->new($_) } @$_ ] };

declare 'MapStringDeviceState',
    as HashRef[DeviceState()];

1;

__END__

=head1 NAME

Google::Cloud::Iot::V1::Resources::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
