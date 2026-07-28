package Google::Cloud::Sql::V1::CloudSqlConnect::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'GetConnectSettingsRequest',
    as InstanceOf['Google::Cloud::Sql::V1::CloudSqlConnect::GetConnectSettingsRequest'];

coerce 'GetConnectSettingsRequest',
    from HashRef, via { 'Google::Cloud::Sql::V1::CloudSqlConnect::GetConnectSettingsRequest'->new($_) };

declare 'RepeatedGetConnectSettingsRequest',
    as ArrayRef[GetConnectSettingsRequest()];

coerce 'RepeatedGetConnectSettingsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1::CloudSqlConnect::GetConnectSettingsRequest'->new($_) } @$_ ] };

declare 'MapStringGetConnectSettingsRequest',
    as HashRef[GetConnectSettingsRequest()];

declare 'ResolveConnectSettingsRequest',
    as InstanceOf['Google::Cloud::Sql::V1::CloudSqlConnect::ResolveConnectSettingsRequest'];

coerce 'ResolveConnectSettingsRequest',
    from HashRef, via { 'Google::Cloud::Sql::V1::CloudSqlConnect::ResolveConnectSettingsRequest'->new($_) };

declare 'RepeatedResolveConnectSettingsRequest',
    as ArrayRef[ResolveConnectSettingsRequest()];

coerce 'RepeatedResolveConnectSettingsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1::CloudSqlConnect::ResolveConnectSettingsRequest'->new($_) } @$_ ] };

declare 'MapStringResolveConnectSettingsRequest',
    as HashRef[ResolveConnectSettingsRequest()];

declare 'ConnectSettings',
    as InstanceOf['Google::Cloud::Sql::V1::CloudSqlConnect::ConnectSettings'];

coerce 'ConnectSettings',
    from HashRef, via { 'Google::Cloud::Sql::V1::CloudSqlConnect::ConnectSettings'->new($_) };

declare 'RepeatedConnectSettings',
    as ArrayRef[ConnectSettings()];

coerce 'RepeatedConnectSettings',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1::CloudSqlConnect::ConnectSettings'->new($_) } @$_ ] };

declare 'MapStringConnectSettings',
    as HashRef[ConnectSettings()];

declare 'CaMode',
    as (Int | Str);

declare 'MdxProtocolSupport',
    as (Int | Str);

declare 'ConnectPoolNodeConfig',
    as InstanceOf['Google::Cloud::Sql::V1::CloudSqlConnect::ConnectSettings::ConnectPoolNodeConfig'];

coerce 'ConnectPoolNodeConfig',
    from HashRef, via { 'Google::Cloud::Sql::V1::CloudSqlConnect::ConnectSettings::ConnectPoolNodeConfig'->new($_) };

declare 'RepeatedConnectPoolNodeConfig',
    as ArrayRef[ConnectPoolNodeConfig()];

coerce 'RepeatedConnectPoolNodeConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1::CloudSqlConnect::ConnectSettings::ConnectPoolNodeConfig'->new($_) } @$_ ] };

declare 'MapStringConnectPoolNodeConfig',
    as HashRef[ConnectPoolNodeConfig()];

declare 'GenerateEphemeralCertRequest',
    as InstanceOf['Google::Cloud::Sql::V1::CloudSqlConnect::GenerateEphemeralCertRequest'];

coerce 'GenerateEphemeralCertRequest',
    from HashRef, via { 'Google::Cloud::Sql::V1::CloudSqlConnect::GenerateEphemeralCertRequest'->new($_) };

declare 'RepeatedGenerateEphemeralCertRequest',
    as ArrayRef[GenerateEphemeralCertRequest()];

coerce 'RepeatedGenerateEphemeralCertRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1::CloudSqlConnect::GenerateEphemeralCertRequest'->new($_) } @$_ ] };

declare 'MapStringGenerateEphemeralCertRequest',
    as HashRef[GenerateEphemeralCertRequest()];

declare 'GenerateEphemeralCertResponse',
    as InstanceOf['Google::Cloud::Sql::V1::CloudSqlConnect::GenerateEphemeralCertResponse'];

coerce 'GenerateEphemeralCertResponse',
    from HashRef, via { 'Google::Cloud::Sql::V1::CloudSqlConnect::GenerateEphemeralCertResponse'->new($_) };

declare 'RepeatedGenerateEphemeralCertResponse',
    as ArrayRef[GenerateEphemeralCertResponse()];

coerce 'RepeatedGenerateEphemeralCertResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1::CloudSqlConnect::GenerateEphemeralCertResponse'->new($_) } @$_ ] };

declare 'MapStringGenerateEphemeralCertResponse',
    as HashRef[GenerateEphemeralCertResponse()];

1;

__END__

=head1 NAME

Google::Cloud::Sql::V1::CloudSqlConnect::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
