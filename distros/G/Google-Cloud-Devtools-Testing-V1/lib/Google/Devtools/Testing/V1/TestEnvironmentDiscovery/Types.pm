package Google::Devtools::Testing::V1::TestEnvironmentDiscovery::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'DeviceForm',
    as (Int | Str);

declare 'DeviceFormFactor',
    as (Int | Str);

declare 'DeviceCapacity',
    as (Int | Str);

declare 'DeviceIpBlock',
    as InstanceOf['Google::Devtools::Testing::V1::TestEnvironmentDiscovery::DeviceIpBlock'];

coerce 'DeviceIpBlock',
    from HashRef, via { 'Google::Devtools::Testing::V1::TestEnvironmentDiscovery::DeviceIpBlock'->new($_) };

declare 'RepeatedDeviceIpBlock',
    as ArrayRef[DeviceIpBlock()];

coerce 'RepeatedDeviceIpBlock',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Testing::V1::TestEnvironmentDiscovery::DeviceIpBlock'->new($_) } @$_ ] };

declare 'MapStringDeviceIpBlock',
    as HashRef[DeviceIpBlock()];

declare 'GetTestEnvironmentCatalogRequest',
    as InstanceOf['Google::Devtools::Testing::V1::TestEnvironmentDiscovery::GetTestEnvironmentCatalogRequest'];

coerce 'GetTestEnvironmentCatalogRequest',
    from HashRef, via { 'Google::Devtools::Testing::V1::TestEnvironmentDiscovery::GetTestEnvironmentCatalogRequest'->new($_) };

declare 'RepeatedGetTestEnvironmentCatalogRequest',
    as ArrayRef[GetTestEnvironmentCatalogRequest()];

coerce 'RepeatedGetTestEnvironmentCatalogRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Testing::V1::TestEnvironmentDiscovery::GetTestEnvironmentCatalogRequest'->new($_) } @$_ ] };

declare 'MapStringGetTestEnvironmentCatalogRequest',
    as HashRef[GetTestEnvironmentCatalogRequest()];

declare 'EnvironmentType',
    as (Int | Str);

declare 'TestEnvironmentCatalog',
    as InstanceOf['Google::Devtools::Testing::V1::TestEnvironmentDiscovery::TestEnvironmentCatalog'];

coerce 'TestEnvironmentCatalog',
    from HashRef, via { 'Google::Devtools::Testing::V1::TestEnvironmentDiscovery::TestEnvironmentCatalog'->new($_) };

declare 'RepeatedTestEnvironmentCatalog',
    as ArrayRef[TestEnvironmentCatalog()];

coerce 'RepeatedTestEnvironmentCatalog',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Testing::V1::TestEnvironmentDiscovery::TestEnvironmentCatalog'->new($_) } @$_ ] };

declare 'MapStringTestEnvironmentCatalog',
    as HashRef[TestEnvironmentCatalog()];

declare 'DeviceIpBlockCatalog',
    as InstanceOf['Google::Devtools::Testing::V1::TestEnvironmentDiscovery::DeviceIpBlockCatalog'];

coerce 'DeviceIpBlockCatalog',
    from HashRef, via { 'Google::Devtools::Testing::V1::TestEnvironmentDiscovery::DeviceIpBlockCatalog'->new($_) };

declare 'RepeatedDeviceIpBlockCatalog',
    as ArrayRef[DeviceIpBlockCatalog()];

coerce 'RepeatedDeviceIpBlockCatalog',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Testing::V1::TestEnvironmentDiscovery::DeviceIpBlockCatalog'->new($_) } @$_ ] };

declare 'MapStringDeviceIpBlockCatalog',
    as HashRef[DeviceIpBlockCatalog()];

declare 'AndroidDeviceCatalog',
    as InstanceOf['Google::Devtools::Testing::V1::TestEnvironmentDiscovery::AndroidDeviceCatalog'];

coerce 'AndroidDeviceCatalog',
    from HashRef, via { 'Google::Devtools::Testing::V1::TestEnvironmentDiscovery::AndroidDeviceCatalog'->new($_) };

declare 'RepeatedAndroidDeviceCatalog',
    as ArrayRef[AndroidDeviceCatalog()];

coerce 'RepeatedAndroidDeviceCatalog',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Testing::V1::TestEnvironmentDiscovery::AndroidDeviceCatalog'->new($_) } @$_ ] };

declare 'MapStringAndroidDeviceCatalog',
    as HashRef[AndroidDeviceCatalog()];

declare 'AndroidRuntimeConfiguration',
    as InstanceOf['Google::Devtools::Testing::V1::TestEnvironmentDiscovery::AndroidRuntimeConfiguration'];

coerce 'AndroidRuntimeConfiguration',
    from HashRef, via { 'Google::Devtools::Testing::V1::TestEnvironmentDiscovery::AndroidRuntimeConfiguration'->new($_) };

declare 'RepeatedAndroidRuntimeConfiguration',
    as ArrayRef[AndroidRuntimeConfiguration()];

coerce 'RepeatedAndroidRuntimeConfiguration',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Testing::V1::TestEnvironmentDiscovery::AndroidRuntimeConfiguration'->new($_) } @$_ ] };

declare 'MapStringAndroidRuntimeConfiguration',
    as HashRef[AndroidRuntimeConfiguration()];

declare 'AndroidModel',
    as InstanceOf['Google::Devtools::Testing::V1::TestEnvironmentDiscovery::AndroidModel'];

coerce 'AndroidModel',
    from HashRef, via { 'Google::Devtools::Testing::V1::TestEnvironmentDiscovery::AndroidModel'->new($_) };

declare 'RepeatedAndroidModel',
    as ArrayRef[AndroidModel()];

coerce 'RepeatedAndroidModel',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Testing::V1::TestEnvironmentDiscovery::AndroidModel'->new($_) } @$_ ] };

declare 'MapStringAndroidModel',
    as HashRef[AndroidModel()];

declare 'AccessDeniedReason',
    as (Int | Str);

declare 'AndroidVersion',
    as InstanceOf['Google::Devtools::Testing::V1::TestEnvironmentDiscovery::AndroidVersion'];

coerce 'AndroidVersion',
    from HashRef, via { 'Google::Devtools::Testing::V1::TestEnvironmentDiscovery::AndroidVersion'->new($_) };

declare 'RepeatedAndroidVersion',
    as ArrayRef[AndroidVersion()];

coerce 'RepeatedAndroidVersion',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Testing::V1::TestEnvironmentDiscovery::AndroidVersion'->new($_) } @$_ ] };

declare 'MapStringAndroidVersion',
    as HashRef[AndroidVersion()];

declare 'PerAndroidVersionInfo',
    as InstanceOf['Google::Devtools::Testing::V1::TestEnvironmentDiscovery::PerAndroidVersionInfo'];

coerce 'PerAndroidVersionInfo',
    from HashRef, via { 'Google::Devtools::Testing::V1::TestEnvironmentDiscovery::PerAndroidVersionInfo'->new($_) };

declare 'RepeatedPerAndroidVersionInfo',
    as ArrayRef[PerAndroidVersionInfo()];

coerce 'RepeatedPerAndroidVersionInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Testing::V1::TestEnvironmentDiscovery::PerAndroidVersionInfo'->new($_) } @$_ ] };

declare 'MapStringPerAndroidVersionInfo',
    as HashRef[PerAndroidVersionInfo()];

declare 'DirectAccessVersionInfo',
    as InstanceOf['Google::Devtools::Testing::V1::TestEnvironmentDiscovery::DirectAccessVersionInfo'];

coerce 'DirectAccessVersionInfo',
    from HashRef, via { 'Google::Devtools::Testing::V1::TestEnvironmentDiscovery::DirectAccessVersionInfo'->new($_) };

declare 'RepeatedDirectAccessVersionInfo',
    as ArrayRef[DirectAccessVersionInfo()];

coerce 'RepeatedDirectAccessVersionInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Testing::V1::TestEnvironmentDiscovery::DirectAccessVersionInfo'->new($_) } @$_ ] };

declare 'MapStringDirectAccessVersionInfo',
    as HashRef[DirectAccessVersionInfo()];

declare 'Distribution',
    as InstanceOf['Google::Devtools::Testing::V1::TestEnvironmentDiscovery::Distribution'];

coerce 'Distribution',
    from HashRef, via { 'Google::Devtools::Testing::V1::TestEnvironmentDiscovery::Distribution'->new($_) };

declare 'RepeatedDistribution',
    as ArrayRef[Distribution()];

coerce 'RepeatedDistribution',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Testing::V1::TestEnvironmentDiscovery::Distribution'->new($_) } @$_ ] };

declare 'MapStringDistribution',
    as HashRef[Distribution()];

declare 'LabInfo',
    as InstanceOf['Google::Devtools::Testing::V1::TestEnvironmentDiscovery::LabInfo'];

coerce 'LabInfo',
    from HashRef, via { 'Google::Devtools::Testing::V1::TestEnvironmentDiscovery::LabInfo'->new($_) };

declare 'RepeatedLabInfo',
    as ArrayRef[LabInfo()];

coerce 'RepeatedLabInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Testing::V1::TestEnvironmentDiscovery::LabInfo'->new($_) } @$_ ] };

declare 'MapStringLabInfo',
    as HashRef[LabInfo()];

declare 'IosDeviceCatalog',
    as InstanceOf['Google::Devtools::Testing::V1::TestEnvironmentDiscovery::IosDeviceCatalog'];

coerce 'IosDeviceCatalog',
    from HashRef, via { 'Google::Devtools::Testing::V1::TestEnvironmentDiscovery::IosDeviceCatalog'->new($_) };

declare 'RepeatedIosDeviceCatalog',
    as ArrayRef[IosDeviceCatalog()];

coerce 'RepeatedIosDeviceCatalog',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Testing::V1::TestEnvironmentDiscovery::IosDeviceCatalog'->new($_) } @$_ ] };

declare 'MapStringIosDeviceCatalog',
    as HashRef[IosDeviceCatalog()];

declare 'IosRuntimeConfiguration',
    as InstanceOf['Google::Devtools::Testing::V1::TestEnvironmentDiscovery::IosRuntimeConfiguration'];

coerce 'IosRuntimeConfiguration',
    from HashRef, via { 'Google::Devtools::Testing::V1::TestEnvironmentDiscovery::IosRuntimeConfiguration'->new($_) };

declare 'RepeatedIosRuntimeConfiguration',
    as ArrayRef[IosRuntimeConfiguration()];

coerce 'RepeatedIosRuntimeConfiguration',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Testing::V1::TestEnvironmentDiscovery::IosRuntimeConfiguration'->new($_) } @$_ ] };

declare 'MapStringIosRuntimeConfiguration',
    as HashRef[IosRuntimeConfiguration()];

declare 'IosModel',
    as InstanceOf['Google::Devtools::Testing::V1::TestEnvironmentDiscovery::IosModel'];

coerce 'IosModel',
    from HashRef, via { 'Google::Devtools::Testing::V1::TestEnvironmentDiscovery::IosModel'->new($_) };

declare 'RepeatedIosModel',
    as ArrayRef[IosModel()];

coerce 'RepeatedIosModel',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Testing::V1::TestEnvironmentDiscovery::IosModel'->new($_) } @$_ ] };

declare 'MapStringIosModel',
    as HashRef[IosModel()];

declare 'IosVersion',
    as InstanceOf['Google::Devtools::Testing::V1::TestEnvironmentDiscovery::IosVersion'];

coerce 'IosVersion',
    from HashRef, via { 'Google::Devtools::Testing::V1::TestEnvironmentDiscovery::IosVersion'->new($_) };

declare 'RepeatedIosVersion',
    as ArrayRef[IosVersion()];

coerce 'RepeatedIosVersion',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Testing::V1::TestEnvironmentDiscovery::IosVersion'->new($_) } @$_ ] };

declare 'MapStringIosVersion',
    as HashRef[IosVersion()];

declare 'PerIosVersionInfo',
    as InstanceOf['Google::Devtools::Testing::V1::TestEnvironmentDiscovery::PerIosVersionInfo'];

coerce 'PerIosVersionInfo',
    from HashRef, via { 'Google::Devtools::Testing::V1::TestEnvironmentDiscovery::PerIosVersionInfo'->new($_) };

declare 'RepeatedPerIosVersionInfo',
    as ArrayRef[PerIosVersionInfo()];

coerce 'RepeatedPerIosVersionInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Testing::V1::TestEnvironmentDiscovery::PerIosVersionInfo'->new($_) } @$_ ] };

declare 'MapStringPerIosVersionInfo',
    as HashRef[PerIosVersionInfo()];

declare 'Locale',
    as InstanceOf['Google::Devtools::Testing::V1::TestEnvironmentDiscovery::Locale'];

coerce 'Locale',
    from HashRef, via { 'Google::Devtools::Testing::V1::TestEnvironmentDiscovery::Locale'->new($_) };

declare 'RepeatedLocale',
    as ArrayRef[Locale()];

coerce 'RepeatedLocale',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Testing::V1::TestEnvironmentDiscovery::Locale'->new($_) } @$_ ] };

declare 'MapStringLocale',
    as HashRef[Locale()];

declare 'Orientation',
    as InstanceOf['Google::Devtools::Testing::V1::TestEnvironmentDiscovery::Orientation'];

coerce 'Orientation',
    from HashRef, via { 'Google::Devtools::Testing::V1::TestEnvironmentDiscovery::Orientation'->new($_) };

declare 'RepeatedOrientation',
    as ArrayRef[Orientation()];

coerce 'RepeatedOrientation',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Testing::V1::TestEnvironmentDiscovery::Orientation'->new($_) } @$_ ] };

declare 'MapStringOrientation',
    as HashRef[Orientation()];

declare 'XcodeVersion',
    as InstanceOf['Google::Devtools::Testing::V1::TestEnvironmentDiscovery::XcodeVersion'];

coerce 'XcodeVersion',
    from HashRef, via { 'Google::Devtools::Testing::V1::TestEnvironmentDiscovery::XcodeVersion'->new($_) };

declare 'RepeatedXcodeVersion',
    as ArrayRef[XcodeVersion()];

coerce 'RepeatedXcodeVersion',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Testing::V1::TestEnvironmentDiscovery::XcodeVersion'->new($_) } @$_ ] };

declare 'MapStringXcodeVersion',
    as HashRef[XcodeVersion()];

declare 'NetworkConfigurationCatalog',
    as InstanceOf['Google::Devtools::Testing::V1::TestEnvironmentDiscovery::NetworkConfigurationCatalog'];

coerce 'NetworkConfigurationCatalog',
    from HashRef, via { 'Google::Devtools::Testing::V1::TestEnvironmentDiscovery::NetworkConfigurationCatalog'->new($_) };

declare 'RepeatedNetworkConfigurationCatalog',
    as ArrayRef[NetworkConfigurationCatalog()];

coerce 'RepeatedNetworkConfigurationCatalog',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Testing::V1::TestEnvironmentDiscovery::NetworkConfigurationCatalog'->new($_) } @$_ ] };

declare 'MapStringNetworkConfigurationCatalog',
    as HashRef[NetworkConfigurationCatalog()];

declare 'NetworkConfiguration',
    as InstanceOf['Google::Devtools::Testing::V1::TestEnvironmentDiscovery::NetworkConfiguration'];

coerce 'NetworkConfiguration',
    from HashRef, via { 'Google::Devtools::Testing::V1::TestEnvironmentDiscovery::NetworkConfiguration'->new($_) };

declare 'RepeatedNetworkConfiguration',
    as ArrayRef[NetworkConfiguration()];

coerce 'RepeatedNetworkConfiguration',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Testing::V1::TestEnvironmentDiscovery::NetworkConfiguration'->new($_) } @$_ ] };

declare 'MapStringNetworkConfiguration',
    as HashRef[NetworkConfiguration()];

declare 'TrafficRule',
    as InstanceOf['Google::Devtools::Testing::V1::TestEnvironmentDiscovery::TrafficRule'];

coerce 'TrafficRule',
    from HashRef, via { 'Google::Devtools::Testing::V1::TestEnvironmentDiscovery::TrafficRule'->new($_) };

declare 'RepeatedTrafficRule',
    as ArrayRef[TrafficRule()];

coerce 'RepeatedTrafficRule',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Testing::V1::TestEnvironmentDiscovery::TrafficRule'->new($_) } @$_ ] };

declare 'MapStringTrafficRule',
    as HashRef[TrafficRule()];

declare 'ProvidedSoftwareCatalog',
    as InstanceOf['Google::Devtools::Testing::V1::TestEnvironmentDiscovery::ProvidedSoftwareCatalog'];

coerce 'ProvidedSoftwareCatalog',
    from HashRef, via { 'Google::Devtools::Testing::V1::TestEnvironmentDiscovery::ProvidedSoftwareCatalog'->new($_) };

declare 'RepeatedProvidedSoftwareCatalog',
    as ArrayRef[ProvidedSoftwareCatalog()];

coerce 'RepeatedProvidedSoftwareCatalog',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Testing::V1::TestEnvironmentDiscovery::ProvidedSoftwareCatalog'->new($_) } @$_ ] };

declare 'MapStringProvidedSoftwareCatalog',
    as HashRef[ProvidedSoftwareCatalog()];

1;

__END__

=head1 NAME

Google::Devtools::Testing::V1::TestEnvironmentDiscovery::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
