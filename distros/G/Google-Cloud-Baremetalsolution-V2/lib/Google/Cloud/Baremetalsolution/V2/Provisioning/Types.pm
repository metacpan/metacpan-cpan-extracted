package Google::Cloud::Baremetalsolution::V2::Provisioning::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'ProvisioningConfig',
    as InstanceOf['Google::Cloud::Baremetalsolution::V2::Provisioning::ProvisioningConfig'];

coerce 'ProvisioningConfig',
    from HashRef, via { 'Google::Cloud::Baremetalsolution::V2::Provisioning::ProvisioningConfig'->new($_) };

declare 'RepeatedProvisioningConfig',
    as ArrayRef[ProvisioningConfig()];

coerce 'RepeatedProvisioningConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Baremetalsolution::V2::Provisioning::ProvisioningConfig'->new($_) } @$_ ] };

declare 'MapStringProvisioningConfig',
    as HashRef[ProvisioningConfig()];

declare 'State',
    as (Int | Str);

declare 'SubmitProvisioningConfigRequest',
    as InstanceOf['Google::Cloud::Baremetalsolution::V2::Provisioning::SubmitProvisioningConfigRequest'];

coerce 'SubmitProvisioningConfigRequest',
    from HashRef, via { 'Google::Cloud::Baremetalsolution::V2::Provisioning::SubmitProvisioningConfigRequest'->new($_) };

declare 'RepeatedSubmitProvisioningConfigRequest',
    as ArrayRef[SubmitProvisioningConfigRequest()];

coerce 'RepeatedSubmitProvisioningConfigRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Baremetalsolution::V2::Provisioning::SubmitProvisioningConfigRequest'->new($_) } @$_ ] };

declare 'MapStringSubmitProvisioningConfigRequest',
    as HashRef[SubmitProvisioningConfigRequest()];

declare 'SubmitProvisioningConfigResponse',
    as InstanceOf['Google::Cloud::Baremetalsolution::V2::Provisioning::SubmitProvisioningConfigResponse'];

coerce 'SubmitProvisioningConfigResponse',
    from HashRef, via { 'Google::Cloud::Baremetalsolution::V2::Provisioning::SubmitProvisioningConfigResponse'->new($_) };

declare 'RepeatedSubmitProvisioningConfigResponse',
    as ArrayRef[SubmitProvisioningConfigResponse()];

coerce 'RepeatedSubmitProvisioningConfigResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Baremetalsolution::V2::Provisioning::SubmitProvisioningConfigResponse'->new($_) } @$_ ] };

declare 'MapStringSubmitProvisioningConfigResponse',
    as HashRef[SubmitProvisioningConfigResponse()];

declare 'ProvisioningQuota',
    as InstanceOf['Google::Cloud::Baremetalsolution::V2::Provisioning::ProvisioningQuota'];

coerce 'ProvisioningQuota',
    from HashRef, via { 'Google::Cloud::Baremetalsolution::V2::Provisioning::ProvisioningQuota'->new($_) };

declare 'RepeatedProvisioningQuota',
    as ArrayRef[ProvisioningQuota()];

coerce 'RepeatedProvisioningQuota',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Baremetalsolution::V2::Provisioning::ProvisioningQuota'->new($_) } @$_ ] };

declare 'MapStringProvisioningQuota',
    as HashRef[ProvisioningQuota()];

declare 'AssetType',
    as (Int | Str);

declare 'ListProvisioningQuotasRequest',
    as InstanceOf['Google::Cloud::Baremetalsolution::V2::Provisioning::ListProvisioningQuotasRequest'];

coerce 'ListProvisioningQuotasRequest',
    from HashRef, via { 'Google::Cloud::Baremetalsolution::V2::Provisioning::ListProvisioningQuotasRequest'->new($_) };

declare 'RepeatedListProvisioningQuotasRequest',
    as ArrayRef[ListProvisioningQuotasRequest()];

coerce 'RepeatedListProvisioningQuotasRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Baremetalsolution::V2::Provisioning::ListProvisioningQuotasRequest'->new($_) } @$_ ] };

declare 'MapStringListProvisioningQuotasRequest',
    as HashRef[ListProvisioningQuotasRequest()];

declare 'ListProvisioningQuotasResponse',
    as InstanceOf['Google::Cloud::Baremetalsolution::V2::Provisioning::ListProvisioningQuotasResponse'];

coerce 'ListProvisioningQuotasResponse',
    from HashRef, via { 'Google::Cloud::Baremetalsolution::V2::Provisioning::ListProvisioningQuotasResponse'->new($_) };

declare 'RepeatedListProvisioningQuotasResponse',
    as ArrayRef[ListProvisioningQuotasResponse()];

coerce 'RepeatedListProvisioningQuotasResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Baremetalsolution::V2::Provisioning::ListProvisioningQuotasResponse'->new($_) } @$_ ] };

declare 'MapStringListProvisioningQuotasResponse',
    as HashRef[ListProvisioningQuotasResponse()];

declare 'InstanceConfig',
    as InstanceOf['Google::Cloud::Baremetalsolution::V2::Provisioning::InstanceConfig'];

coerce 'InstanceConfig',
    from HashRef, via { 'Google::Cloud::Baremetalsolution::V2::Provisioning::InstanceConfig'->new($_) };

declare 'RepeatedInstanceConfig',
    as ArrayRef[InstanceConfig()];

coerce 'RepeatedInstanceConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Baremetalsolution::V2::Provisioning::InstanceConfig'->new($_) } @$_ ] };

declare 'MapStringInstanceConfig',
    as HashRef[InstanceConfig()];

declare 'NetworkConfig',
    as (Int | Str);

declare 'NetworkAddress',
    as InstanceOf['Google::Cloud::Baremetalsolution::V2::Provisioning::InstanceConfig::NetworkAddress'];

coerce 'NetworkAddress',
    from HashRef, via { 'Google::Cloud::Baremetalsolution::V2::Provisioning::InstanceConfig::NetworkAddress'->new($_) };

declare 'RepeatedNetworkAddress',
    as ArrayRef[NetworkAddress()];

coerce 'RepeatedNetworkAddress',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Baremetalsolution::V2::Provisioning::InstanceConfig::NetworkAddress'->new($_) } @$_ ] };

declare 'MapStringNetworkAddress',
    as HashRef[NetworkAddress()];

declare 'VolumeConfig',
    as InstanceOf['Google::Cloud::Baremetalsolution::V2::Provisioning::VolumeConfig'];

coerce 'VolumeConfig',
    from HashRef, via { 'Google::Cloud::Baremetalsolution::V2::Provisioning::VolumeConfig'->new($_) };

declare 'RepeatedVolumeConfig',
    as ArrayRef[VolumeConfig()];

coerce 'RepeatedVolumeConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Baremetalsolution::V2::Provisioning::VolumeConfig'->new($_) } @$_ ] };

declare 'MapStringVolumeConfig',
    as HashRef[VolumeConfig()];

declare 'Type',
    as (Int | Str);

declare 'Protocol',
    as (Int | Str);

declare 'LunRange',
    as InstanceOf['Google::Cloud::Baremetalsolution::V2::Provisioning::VolumeConfig::LunRange'];

coerce 'LunRange',
    from HashRef, via { 'Google::Cloud::Baremetalsolution::V2::Provisioning::VolumeConfig::LunRange'->new($_) };

declare 'RepeatedLunRange',
    as ArrayRef[LunRange()];

coerce 'RepeatedLunRange',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Baremetalsolution::V2::Provisioning::VolumeConfig::LunRange'->new($_) } @$_ ] };

declare 'MapStringLunRange',
    as HashRef[LunRange()];

declare 'NfsExport',
    as InstanceOf['Google::Cloud::Baremetalsolution::V2::Provisioning::VolumeConfig::NfsExport'];

coerce 'NfsExport',
    from HashRef, via { 'Google::Cloud::Baremetalsolution::V2::Provisioning::VolumeConfig::NfsExport'->new($_) };

declare 'RepeatedNfsExport',
    as ArrayRef[NfsExport()];

coerce 'RepeatedNfsExport',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Baremetalsolution::V2::Provisioning::VolumeConfig::NfsExport'->new($_) } @$_ ] };

declare 'MapStringNfsExport',
    as HashRef[NfsExport()];

declare 'Permissions',
    as (Int | Str);

declare 'NetworkConfig',
    as InstanceOf['Google::Cloud::Baremetalsolution::V2::Provisioning::NetworkConfig'];

coerce 'NetworkConfig',
    from HashRef, via { 'Google::Cloud::Baremetalsolution::V2::Provisioning::NetworkConfig'->new($_) };

declare 'RepeatedNetworkConfig',
    as ArrayRef[NetworkConfig()];

coerce 'RepeatedNetworkConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Baremetalsolution::V2::Provisioning::NetworkConfig'->new($_) } @$_ ] };

declare 'MapStringNetworkConfig',
    as HashRef[NetworkConfig()];

declare 'Type',
    as (Int | Str);

declare 'Bandwidth',
    as (Int | Str);

declare 'ServiceCidr',
    as (Int | Str);

declare 'IntakeVlanAttachment',
    as InstanceOf['Google::Cloud::Baremetalsolution::V2::Provisioning::NetworkConfig::IntakeVlanAttachment'];

coerce 'IntakeVlanAttachment',
    from HashRef, via { 'Google::Cloud::Baremetalsolution::V2::Provisioning::NetworkConfig::IntakeVlanAttachment'->new($_) };

declare 'RepeatedIntakeVlanAttachment',
    as ArrayRef[IntakeVlanAttachment()];

coerce 'RepeatedIntakeVlanAttachment',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Baremetalsolution::V2::Provisioning::NetworkConfig::IntakeVlanAttachment'->new($_) } @$_ ] };

declare 'MapStringIntakeVlanAttachment',
    as HashRef[IntakeVlanAttachment()];

declare 'InstanceQuota',
    as InstanceOf['Google::Cloud::Baremetalsolution::V2::Provisioning::InstanceQuota'];

coerce 'InstanceQuota',
    from HashRef, via { 'Google::Cloud::Baremetalsolution::V2::Provisioning::InstanceQuota'->new($_) };

declare 'RepeatedInstanceQuota',
    as ArrayRef[InstanceQuota()];

coerce 'RepeatedInstanceQuota',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Baremetalsolution::V2::Provisioning::InstanceQuota'->new($_) } @$_ ] };

declare 'MapStringInstanceQuota',
    as HashRef[InstanceQuota()];

declare 'GetProvisioningConfigRequest',
    as InstanceOf['Google::Cloud::Baremetalsolution::V2::Provisioning::GetProvisioningConfigRequest'];

coerce 'GetProvisioningConfigRequest',
    from HashRef, via { 'Google::Cloud::Baremetalsolution::V2::Provisioning::GetProvisioningConfigRequest'->new($_) };

declare 'RepeatedGetProvisioningConfigRequest',
    as ArrayRef[GetProvisioningConfigRequest()];

coerce 'RepeatedGetProvisioningConfigRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Baremetalsolution::V2::Provisioning::GetProvisioningConfigRequest'->new($_) } @$_ ] };

declare 'MapStringGetProvisioningConfigRequest',
    as HashRef[GetProvisioningConfigRequest()];

declare 'CreateProvisioningConfigRequest',
    as InstanceOf['Google::Cloud::Baremetalsolution::V2::Provisioning::CreateProvisioningConfigRequest'];

coerce 'CreateProvisioningConfigRequest',
    from HashRef, via { 'Google::Cloud::Baremetalsolution::V2::Provisioning::CreateProvisioningConfigRequest'->new($_) };

declare 'RepeatedCreateProvisioningConfigRequest',
    as ArrayRef[CreateProvisioningConfigRequest()];

coerce 'RepeatedCreateProvisioningConfigRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Baremetalsolution::V2::Provisioning::CreateProvisioningConfigRequest'->new($_) } @$_ ] };

declare 'MapStringCreateProvisioningConfigRequest',
    as HashRef[CreateProvisioningConfigRequest()];

declare 'UpdateProvisioningConfigRequest',
    as InstanceOf['Google::Cloud::Baremetalsolution::V2::Provisioning::UpdateProvisioningConfigRequest'];

coerce 'UpdateProvisioningConfigRequest',
    from HashRef, via { 'Google::Cloud::Baremetalsolution::V2::Provisioning::UpdateProvisioningConfigRequest'->new($_) };

declare 'RepeatedUpdateProvisioningConfigRequest',
    as ArrayRef[UpdateProvisioningConfigRequest()];

coerce 'RepeatedUpdateProvisioningConfigRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Baremetalsolution::V2::Provisioning::UpdateProvisioningConfigRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateProvisioningConfigRequest',
    as HashRef[UpdateProvisioningConfigRequest()];

1;

__END__

=head1 NAME

Google::Cloud::Baremetalsolution::V2::Provisioning::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
