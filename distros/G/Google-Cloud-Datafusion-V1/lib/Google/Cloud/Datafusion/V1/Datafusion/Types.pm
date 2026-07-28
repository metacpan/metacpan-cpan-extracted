package Google::Cloud::Datafusion::V1::Datafusion::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'NetworkConfig',
    as InstanceOf['Google::Cloud::Datafusion::V1::Datafusion::NetworkConfig'];

coerce 'NetworkConfig',
    from HashRef, via { 'Google::Cloud::Datafusion::V1::Datafusion::NetworkConfig'->new($_) };

declare 'RepeatedNetworkConfig',
    as ArrayRef[NetworkConfig()];

coerce 'RepeatedNetworkConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datafusion::V1::Datafusion::NetworkConfig'->new($_) } @$_ ] };

declare 'MapStringNetworkConfig',
    as HashRef[NetworkConfig()];

declare 'Version',
    as InstanceOf['Google::Cloud::Datafusion::V1::Datafusion::Version'];

coerce 'Version',
    from HashRef, via { 'Google::Cloud::Datafusion::V1::Datafusion::Version'->new($_) };

declare 'RepeatedVersion',
    as ArrayRef[Version()];

coerce 'RepeatedVersion',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datafusion::V1::Datafusion::Version'->new($_) } @$_ ] };

declare 'MapStringVersion',
    as HashRef[Version()];

declare 'Type',
    as (Int | Str);

declare 'Accelerator',
    as InstanceOf['Google::Cloud::Datafusion::V1::Datafusion::Accelerator'];

coerce 'Accelerator',
    from HashRef, via { 'Google::Cloud::Datafusion::V1::Datafusion::Accelerator'->new($_) };

declare 'RepeatedAccelerator',
    as ArrayRef[Accelerator()];

coerce 'RepeatedAccelerator',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datafusion::V1::Datafusion::Accelerator'->new($_) } @$_ ] };

declare 'MapStringAccelerator',
    as HashRef[Accelerator()];

declare 'AcceleratorType',
    as (Int | Str);

declare 'State',
    as (Int | Str);

declare 'CryptoKeyConfig',
    as InstanceOf['Google::Cloud::Datafusion::V1::Datafusion::CryptoKeyConfig'];

coerce 'CryptoKeyConfig',
    from HashRef, via { 'Google::Cloud::Datafusion::V1::Datafusion::CryptoKeyConfig'->new($_) };

declare 'RepeatedCryptoKeyConfig',
    as ArrayRef[CryptoKeyConfig()];

coerce 'RepeatedCryptoKeyConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datafusion::V1::Datafusion::CryptoKeyConfig'->new($_) } @$_ ] };

declare 'MapStringCryptoKeyConfig',
    as HashRef[CryptoKeyConfig()];

declare 'Instance',
    as InstanceOf['Google::Cloud::Datafusion::V1::Datafusion::Instance'];

coerce 'Instance',
    from HashRef, via { 'Google::Cloud::Datafusion::V1::Datafusion::Instance'->new($_) };

declare 'RepeatedInstance',
    as ArrayRef[Instance()];

coerce 'RepeatedInstance',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datafusion::V1::Datafusion::Instance'->new($_) } @$_ ] };

declare 'MapStringInstance',
    as HashRef[Instance()];

declare 'Type',
    as (Int | Str);

declare 'State',
    as (Int | Str);

declare 'DisabledReason',
    as (Int | Str);

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Datafusion::V1::Datafusion::Instance::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Datafusion::V1::Datafusion::Instance::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datafusion::V1::Datafusion::Instance::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'OptionsEntry',
    as InstanceOf['Google::Cloud::Datafusion::V1::Datafusion::Instance::OptionsEntry'];

coerce 'OptionsEntry',
    from HashRef, via { 'Google::Cloud::Datafusion::V1::Datafusion::Instance::OptionsEntry'->new($_) };

declare 'RepeatedOptionsEntry',
    as ArrayRef[OptionsEntry()];

coerce 'RepeatedOptionsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datafusion::V1::Datafusion::Instance::OptionsEntry'->new($_) } @$_ ] };

declare 'MapStringOptionsEntry',
    as HashRef[OptionsEntry()];

declare 'ListInstancesRequest',
    as InstanceOf['Google::Cloud::Datafusion::V1::Datafusion::ListInstancesRequest'];

coerce 'ListInstancesRequest',
    from HashRef, via { 'Google::Cloud::Datafusion::V1::Datafusion::ListInstancesRequest'->new($_) };

declare 'RepeatedListInstancesRequest',
    as ArrayRef[ListInstancesRequest()];

coerce 'RepeatedListInstancesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datafusion::V1::Datafusion::ListInstancesRequest'->new($_) } @$_ ] };

declare 'MapStringListInstancesRequest',
    as HashRef[ListInstancesRequest()];

declare 'ListInstancesResponse',
    as InstanceOf['Google::Cloud::Datafusion::V1::Datafusion::ListInstancesResponse'];

coerce 'ListInstancesResponse',
    from HashRef, via { 'Google::Cloud::Datafusion::V1::Datafusion::ListInstancesResponse'->new($_) };

declare 'RepeatedListInstancesResponse',
    as ArrayRef[ListInstancesResponse()];

coerce 'RepeatedListInstancesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datafusion::V1::Datafusion::ListInstancesResponse'->new($_) } @$_ ] };

declare 'MapStringListInstancesResponse',
    as HashRef[ListInstancesResponse()];

declare 'ListAvailableVersionsRequest',
    as InstanceOf['Google::Cloud::Datafusion::V1::Datafusion::ListAvailableVersionsRequest'];

coerce 'ListAvailableVersionsRequest',
    from HashRef, via { 'Google::Cloud::Datafusion::V1::Datafusion::ListAvailableVersionsRequest'->new($_) };

declare 'RepeatedListAvailableVersionsRequest',
    as ArrayRef[ListAvailableVersionsRequest()];

coerce 'RepeatedListAvailableVersionsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datafusion::V1::Datafusion::ListAvailableVersionsRequest'->new($_) } @$_ ] };

declare 'MapStringListAvailableVersionsRequest',
    as HashRef[ListAvailableVersionsRequest()];

declare 'ListAvailableVersionsResponse',
    as InstanceOf['Google::Cloud::Datafusion::V1::Datafusion::ListAvailableVersionsResponse'];

coerce 'ListAvailableVersionsResponse',
    from HashRef, via { 'Google::Cloud::Datafusion::V1::Datafusion::ListAvailableVersionsResponse'->new($_) };

declare 'RepeatedListAvailableVersionsResponse',
    as ArrayRef[ListAvailableVersionsResponse()];

coerce 'RepeatedListAvailableVersionsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datafusion::V1::Datafusion::ListAvailableVersionsResponse'->new($_) } @$_ ] };

declare 'MapStringListAvailableVersionsResponse',
    as HashRef[ListAvailableVersionsResponse()];

declare 'GetInstanceRequest',
    as InstanceOf['Google::Cloud::Datafusion::V1::Datafusion::GetInstanceRequest'];

coerce 'GetInstanceRequest',
    from HashRef, via { 'Google::Cloud::Datafusion::V1::Datafusion::GetInstanceRequest'->new($_) };

declare 'RepeatedGetInstanceRequest',
    as ArrayRef[GetInstanceRequest()];

coerce 'RepeatedGetInstanceRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datafusion::V1::Datafusion::GetInstanceRequest'->new($_) } @$_ ] };

declare 'MapStringGetInstanceRequest',
    as HashRef[GetInstanceRequest()];

declare 'CreateInstanceRequest',
    as InstanceOf['Google::Cloud::Datafusion::V1::Datafusion::CreateInstanceRequest'];

coerce 'CreateInstanceRequest',
    from HashRef, via { 'Google::Cloud::Datafusion::V1::Datafusion::CreateInstanceRequest'->new($_) };

declare 'RepeatedCreateInstanceRequest',
    as ArrayRef[CreateInstanceRequest()];

coerce 'RepeatedCreateInstanceRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datafusion::V1::Datafusion::CreateInstanceRequest'->new($_) } @$_ ] };

declare 'MapStringCreateInstanceRequest',
    as HashRef[CreateInstanceRequest()];

declare 'DeleteInstanceRequest',
    as InstanceOf['Google::Cloud::Datafusion::V1::Datafusion::DeleteInstanceRequest'];

coerce 'DeleteInstanceRequest',
    from HashRef, via { 'Google::Cloud::Datafusion::V1::Datafusion::DeleteInstanceRequest'->new($_) };

declare 'RepeatedDeleteInstanceRequest',
    as ArrayRef[DeleteInstanceRequest()];

coerce 'RepeatedDeleteInstanceRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datafusion::V1::Datafusion::DeleteInstanceRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteInstanceRequest',
    as HashRef[DeleteInstanceRequest()];

declare 'UpdateInstanceRequest',
    as InstanceOf['Google::Cloud::Datafusion::V1::Datafusion::UpdateInstanceRequest'];

coerce 'UpdateInstanceRequest',
    from HashRef, via { 'Google::Cloud::Datafusion::V1::Datafusion::UpdateInstanceRequest'->new($_) };

declare 'RepeatedUpdateInstanceRequest',
    as ArrayRef[UpdateInstanceRequest()];

coerce 'RepeatedUpdateInstanceRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datafusion::V1::Datafusion::UpdateInstanceRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateInstanceRequest',
    as HashRef[UpdateInstanceRequest()];

declare 'RestartInstanceRequest',
    as InstanceOf['Google::Cloud::Datafusion::V1::Datafusion::RestartInstanceRequest'];

coerce 'RestartInstanceRequest',
    from HashRef, via { 'Google::Cloud::Datafusion::V1::Datafusion::RestartInstanceRequest'->new($_) };

declare 'RepeatedRestartInstanceRequest',
    as ArrayRef[RestartInstanceRequest()];

coerce 'RepeatedRestartInstanceRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datafusion::V1::Datafusion::RestartInstanceRequest'->new($_) } @$_ ] };

declare 'MapStringRestartInstanceRequest',
    as HashRef[RestartInstanceRequest()];

declare 'OperationMetadata',
    as InstanceOf['Google::Cloud::Datafusion::V1::Datafusion::OperationMetadata'];

coerce 'OperationMetadata',
    from HashRef, via { 'Google::Cloud::Datafusion::V1::Datafusion::OperationMetadata'->new($_) };

declare 'RepeatedOperationMetadata',
    as ArrayRef[OperationMetadata()];

coerce 'RepeatedOperationMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datafusion::V1::Datafusion::OperationMetadata'->new($_) } @$_ ] };

declare 'MapStringOperationMetadata',
    as HashRef[OperationMetadata()];

declare 'AdditionalStatusEntry',
    as InstanceOf['Google::Cloud::Datafusion::V1::Datafusion::OperationMetadata::AdditionalStatusEntry'];

coerce 'AdditionalStatusEntry',
    from HashRef, via { 'Google::Cloud::Datafusion::V1::Datafusion::OperationMetadata::AdditionalStatusEntry'->new($_) };

declare 'RepeatedAdditionalStatusEntry',
    as ArrayRef[AdditionalStatusEntry()];

coerce 'RepeatedAdditionalStatusEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datafusion::V1::Datafusion::OperationMetadata::AdditionalStatusEntry'->new($_) } @$_ ] };

declare 'MapStringAdditionalStatusEntry',
    as HashRef[AdditionalStatusEntry()];

1;

__END__

=head1 NAME

Google::Cloud::Datafusion::V1::Datafusion::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
