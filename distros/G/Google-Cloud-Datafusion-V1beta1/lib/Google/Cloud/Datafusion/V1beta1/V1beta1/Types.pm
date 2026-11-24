package Google::Cloud::Datafusion::V1beta1::V1beta1::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'NamespaceView',
    as (Int | Str);

declare 'NetworkConfig',
    as InstanceOf['Google::Cloud::Datafusion::V1beta1::V1beta1::NetworkConfig'];

coerce 'NetworkConfig',
    from HashRef, via { 'Google::Cloud::Datafusion::V1beta1::V1beta1::NetworkConfig'->new($_) };

declare 'RepeatedNetworkConfig',
    as ArrayRef[NetworkConfig()];

coerce 'RepeatedNetworkConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datafusion::V1beta1::V1beta1::NetworkConfig'->new($_) } @$_ ] };

declare 'MapStringNetworkConfig',
    as HashRef[NetworkConfig()];

declare 'Version',
    as InstanceOf['Google::Cloud::Datafusion::V1beta1::V1beta1::Version'];

coerce 'Version',
    from HashRef, via { 'Google::Cloud::Datafusion::V1beta1::V1beta1::Version'->new($_) };

declare 'RepeatedVersion',
    as ArrayRef[Version()];

coerce 'RepeatedVersion',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datafusion::V1beta1::V1beta1::Version'->new($_) } @$_ ] };

declare 'MapStringVersion',
    as HashRef[Version()];

declare 'Type',
    as (Int | Str);

declare 'Accelerator',
    as InstanceOf['Google::Cloud::Datafusion::V1beta1::V1beta1::Accelerator'];

coerce 'Accelerator',
    from HashRef, via { 'Google::Cloud::Datafusion::V1beta1::V1beta1::Accelerator'->new($_) };

declare 'RepeatedAccelerator',
    as ArrayRef[Accelerator()];

coerce 'RepeatedAccelerator',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datafusion::V1beta1::V1beta1::Accelerator'->new($_) } @$_ ] };

declare 'MapStringAccelerator',
    as HashRef[Accelerator()];

declare 'AcceleratorType',
    as (Int | Str);

declare 'CryptoKeyConfig',
    as InstanceOf['Google::Cloud::Datafusion::V1beta1::V1beta1::CryptoKeyConfig'];

coerce 'CryptoKeyConfig',
    from HashRef, via { 'Google::Cloud::Datafusion::V1beta1::V1beta1::CryptoKeyConfig'->new($_) };

declare 'RepeatedCryptoKeyConfig',
    as ArrayRef[CryptoKeyConfig()];

coerce 'RepeatedCryptoKeyConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datafusion::V1beta1::V1beta1::CryptoKeyConfig'->new($_) } @$_ ] };

declare 'MapStringCryptoKeyConfig',
    as HashRef[CryptoKeyConfig()];

declare 'Instance',
    as InstanceOf['Google::Cloud::Datafusion::V1beta1::V1beta1::Instance'];

coerce 'Instance',
    from HashRef, via { 'Google::Cloud::Datafusion::V1beta1::V1beta1::Instance'->new($_) };

declare 'RepeatedInstance',
    as ArrayRef[Instance()];

coerce 'RepeatedInstance',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datafusion::V1beta1::V1beta1::Instance'->new($_) } @$_ ] };

declare 'MapStringInstance',
    as HashRef[Instance()];

declare 'Type',
    as (Int | Str);

declare 'State',
    as (Int | Str);

declare 'DisabledReason',
    as (Int | Str);

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Datafusion::V1beta1::V1beta1::Instance::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Datafusion::V1beta1::V1beta1::Instance::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datafusion::V1beta1::V1beta1::Instance::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'OptionsEntry',
    as InstanceOf['Google::Cloud::Datafusion::V1beta1::V1beta1::Instance::OptionsEntry'];

coerce 'OptionsEntry',
    from HashRef, via { 'Google::Cloud::Datafusion::V1beta1::V1beta1::Instance::OptionsEntry'->new($_) };

declare 'RepeatedOptionsEntry',
    as ArrayRef[OptionsEntry()];

coerce 'RepeatedOptionsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datafusion::V1beta1::V1beta1::Instance::OptionsEntry'->new($_) } @$_ ] };

declare 'MapStringOptionsEntry',
    as HashRef[OptionsEntry()];

declare 'ListInstancesRequest',
    as InstanceOf['Google::Cloud::Datafusion::V1beta1::V1beta1::ListInstancesRequest'];

coerce 'ListInstancesRequest',
    from HashRef, via { 'Google::Cloud::Datafusion::V1beta1::V1beta1::ListInstancesRequest'->new($_) };

declare 'RepeatedListInstancesRequest',
    as ArrayRef[ListInstancesRequest()];

coerce 'RepeatedListInstancesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datafusion::V1beta1::V1beta1::ListInstancesRequest'->new($_) } @$_ ] };

declare 'MapStringListInstancesRequest',
    as HashRef[ListInstancesRequest()];

declare 'ListInstancesResponse',
    as InstanceOf['Google::Cloud::Datafusion::V1beta1::V1beta1::ListInstancesResponse'];

coerce 'ListInstancesResponse',
    from HashRef, via { 'Google::Cloud::Datafusion::V1beta1::V1beta1::ListInstancesResponse'->new($_) };

declare 'RepeatedListInstancesResponse',
    as ArrayRef[ListInstancesResponse()];

coerce 'RepeatedListInstancesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datafusion::V1beta1::V1beta1::ListInstancesResponse'->new($_) } @$_ ] };

declare 'MapStringListInstancesResponse',
    as HashRef[ListInstancesResponse()];

declare 'ListAvailableVersionsRequest',
    as InstanceOf['Google::Cloud::Datafusion::V1beta1::V1beta1::ListAvailableVersionsRequest'];

coerce 'ListAvailableVersionsRequest',
    from HashRef, via { 'Google::Cloud::Datafusion::V1beta1::V1beta1::ListAvailableVersionsRequest'->new($_) };

declare 'RepeatedListAvailableVersionsRequest',
    as ArrayRef[ListAvailableVersionsRequest()];

coerce 'RepeatedListAvailableVersionsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datafusion::V1beta1::V1beta1::ListAvailableVersionsRequest'->new($_) } @$_ ] };

declare 'MapStringListAvailableVersionsRequest',
    as HashRef[ListAvailableVersionsRequest()];

declare 'ListAvailableVersionsResponse',
    as InstanceOf['Google::Cloud::Datafusion::V1beta1::V1beta1::ListAvailableVersionsResponse'];

coerce 'ListAvailableVersionsResponse',
    from HashRef, via { 'Google::Cloud::Datafusion::V1beta1::V1beta1::ListAvailableVersionsResponse'->new($_) };

declare 'RepeatedListAvailableVersionsResponse',
    as ArrayRef[ListAvailableVersionsResponse()];

coerce 'RepeatedListAvailableVersionsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datafusion::V1beta1::V1beta1::ListAvailableVersionsResponse'->new($_) } @$_ ] };

declare 'MapStringListAvailableVersionsResponse',
    as HashRef[ListAvailableVersionsResponse()];

declare 'GetInstanceRequest',
    as InstanceOf['Google::Cloud::Datafusion::V1beta1::V1beta1::GetInstanceRequest'];

coerce 'GetInstanceRequest',
    from HashRef, via { 'Google::Cloud::Datafusion::V1beta1::V1beta1::GetInstanceRequest'->new($_) };

declare 'RepeatedGetInstanceRequest',
    as ArrayRef[GetInstanceRequest()];

coerce 'RepeatedGetInstanceRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datafusion::V1beta1::V1beta1::GetInstanceRequest'->new($_) } @$_ ] };

declare 'MapStringGetInstanceRequest',
    as HashRef[GetInstanceRequest()];

declare 'CreateInstanceRequest',
    as InstanceOf['Google::Cloud::Datafusion::V1beta1::V1beta1::CreateInstanceRequest'];

coerce 'CreateInstanceRequest',
    from HashRef, via { 'Google::Cloud::Datafusion::V1beta1::V1beta1::CreateInstanceRequest'->new($_) };

declare 'RepeatedCreateInstanceRequest',
    as ArrayRef[CreateInstanceRequest()];

coerce 'RepeatedCreateInstanceRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datafusion::V1beta1::V1beta1::CreateInstanceRequest'->new($_) } @$_ ] };

declare 'MapStringCreateInstanceRequest',
    as HashRef[CreateInstanceRequest()];

declare 'DeleteInstanceRequest',
    as InstanceOf['Google::Cloud::Datafusion::V1beta1::V1beta1::DeleteInstanceRequest'];

coerce 'DeleteInstanceRequest',
    from HashRef, via { 'Google::Cloud::Datafusion::V1beta1::V1beta1::DeleteInstanceRequest'->new($_) };

declare 'RepeatedDeleteInstanceRequest',
    as ArrayRef[DeleteInstanceRequest()];

coerce 'RepeatedDeleteInstanceRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datafusion::V1beta1::V1beta1::DeleteInstanceRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteInstanceRequest',
    as HashRef[DeleteInstanceRequest()];

declare 'UpdateInstanceRequest',
    as InstanceOf['Google::Cloud::Datafusion::V1beta1::V1beta1::UpdateInstanceRequest'];

coerce 'UpdateInstanceRequest',
    from HashRef, via { 'Google::Cloud::Datafusion::V1beta1::V1beta1::UpdateInstanceRequest'->new($_) };

declare 'RepeatedUpdateInstanceRequest',
    as ArrayRef[UpdateInstanceRequest()];

coerce 'RepeatedUpdateInstanceRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datafusion::V1beta1::V1beta1::UpdateInstanceRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateInstanceRequest',
    as HashRef[UpdateInstanceRequest()];

declare 'RestartInstanceRequest',
    as InstanceOf['Google::Cloud::Datafusion::V1beta1::V1beta1::RestartInstanceRequest'];

coerce 'RestartInstanceRequest',
    from HashRef, via { 'Google::Cloud::Datafusion::V1beta1::V1beta1::RestartInstanceRequest'->new($_) };

declare 'RepeatedRestartInstanceRequest',
    as ArrayRef[RestartInstanceRequest()];

coerce 'RepeatedRestartInstanceRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datafusion::V1beta1::V1beta1::RestartInstanceRequest'->new($_) } @$_ ] };

declare 'MapStringRestartInstanceRequest',
    as HashRef[RestartInstanceRequest()];

declare 'UpgradeInstanceRequest',
    as InstanceOf['Google::Cloud::Datafusion::V1beta1::V1beta1::UpgradeInstanceRequest'];

coerce 'UpgradeInstanceRequest',
    from HashRef, via { 'Google::Cloud::Datafusion::V1beta1::V1beta1::UpgradeInstanceRequest'->new($_) };

declare 'RepeatedUpgradeInstanceRequest',
    as ArrayRef[UpgradeInstanceRequest()];

coerce 'RepeatedUpgradeInstanceRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datafusion::V1beta1::V1beta1::UpgradeInstanceRequest'->new($_) } @$_ ] };

declare 'MapStringUpgradeInstanceRequest',
    as HashRef[UpgradeInstanceRequest()];

declare 'OperationMetadata',
    as InstanceOf['Google::Cloud::Datafusion::V1beta1::V1beta1::OperationMetadata'];

coerce 'OperationMetadata',
    from HashRef, via { 'Google::Cloud::Datafusion::V1beta1::V1beta1::OperationMetadata'->new($_) };

declare 'RepeatedOperationMetadata',
    as ArrayRef[OperationMetadata()];

coerce 'RepeatedOperationMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datafusion::V1beta1::V1beta1::OperationMetadata'->new($_) } @$_ ] };

declare 'MapStringOperationMetadata',
    as HashRef[OperationMetadata()];

declare 'RemoveIamPolicyRequest',
    as InstanceOf['Google::Cloud::Datafusion::V1beta1::V1beta1::RemoveIamPolicyRequest'];

coerce 'RemoveIamPolicyRequest',
    from HashRef, via { 'Google::Cloud::Datafusion::V1beta1::V1beta1::RemoveIamPolicyRequest'->new($_) };

declare 'RepeatedRemoveIamPolicyRequest',
    as ArrayRef[RemoveIamPolicyRequest()];

coerce 'RepeatedRemoveIamPolicyRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datafusion::V1beta1::V1beta1::RemoveIamPolicyRequest'->new($_) } @$_ ] };

declare 'MapStringRemoveIamPolicyRequest',
    as HashRef[RemoveIamPolicyRequest()];

declare 'RemoveIamPolicyResponse',
    as InstanceOf['Google::Cloud::Datafusion::V1beta1::V1beta1::RemoveIamPolicyResponse'];

coerce 'RemoveIamPolicyResponse',
    from HashRef, via { 'Google::Cloud::Datafusion::V1beta1::V1beta1::RemoveIamPolicyResponse'->new($_) };

declare 'RepeatedRemoveIamPolicyResponse',
    as ArrayRef[RemoveIamPolicyResponse()];

coerce 'RepeatedRemoveIamPolicyResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datafusion::V1beta1::V1beta1::RemoveIamPolicyResponse'->new($_) } @$_ ] };

declare 'MapStringRemoveIamPolicyResponse',
    as HashRef[RemoveIamPolicyResponse()];

declare 'ListNamespacesRequest',
    as InstanceOf['Google::Cloud::Datafusion::V1beta1::V1beta1::ListNamespacesRequest'];

coerce 'ListNamespacesRequest',
    from HashRef, via { 'Google::Cloud::Datafusion::V1beta1::V1beta1::ListNamespacesRequest'->new($_) };

declare 'RepeatedListNamespacesRequest',
    as ArrayRef[ListNamespacesRequest()];

coerce 'RepeatedListNamespacesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datafusion::V1beta1::V1beta1::ListNamespacesRequest'->new($_) } @$_ ] };

declare 'MapStringListNamespacesRequest',
    as HashRef[ListNamespacesRequest()];

declare 'IAMPolicy',
    as InstanceOf['Google::Cloud::Datafusion::V1beta1::V1beta1::IAMPolicy'];

coerce 'IAMPolicy',
    from HashRef, via { 'Google::Cloud::Datafusion::V1beta1::V1beta1::IAMPolicy'->new($_) };

declare 'RepeatedIAMPolicy',
    as ArrayRef[IAMPolicy()];

coerce 'RepeatedIAMPolicy',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datafusion::V1beta1::V1beta1::IAMPolicy'->new($_) } @$_ ] };

declare 'MapStringIAMPolicy',
    as HashRef[IAMPolicy()];

declare 'Namespace',
    as InstanceOf['Google::Cloud::Datafusion::V1beta1::V1beta1::Namespace'];

coerce 'Namespace',
    from HashRef, via { 'Google::Cloud::Datafusion::V1beta1::V1beta1::Namespace'->new($_) };

declare 'RepeatedNamespace',
    as ArrayRef[Namespace()];

coerce 'RepeatedNamespace',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datafusion::V1beta1::V1beta1::Namespace'->new($_) } @$_ ] };

declare 'MapStringNamespace',
    as HashRef[Namespace()];

declare 'ListNamespacesResponse',
    as InstanceOf['Google::Cloud::Datafusion::V1beta1::V1beta1::ListNamespacesResponse'];

coerce 'ListNamespacesResponse',
    from HashRef, via { 'Google::Cloud::Datafusion::V1beta1::V1beta1::ListNamespacesResponse'->new($_) };

declare 'RepeatedListNamespacesResponse',
    as ArrayRef[ListNamespacesResponse()];

coerce 'RepeatedListNamespacesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datafusion::V1beta1::V1beta1::ListNamespacesResponse'->new($_) } @$_ ] };

declare 'MapStringListNamespacesResponse',
    as HashRef[ListNamespacesResponse()];

declare 'DnsPeering',
    as InstanceOf['Google::Cloud::Datafusion::V1beta1::V1beta1::DnsPeering'];

coerce 'DnsPeering',
    from HashRef, via { 'Google::Cloud::Datafusion::V1beta1::V1beta1::DnsPeering'->new($_) };

declare 'RepeatedDnsPeering',
    as ArrayRef[DnsPeering()];

coerce 'RepeatedDnsPeering',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datafusion::V1beta1::V1beta1::DnsPeering'->new($_) } @$_ ] };

declare 'MapStringDnsPeering',
    as HashRef[DnsPeering()];

declare 'AddDnsPeeringRequest',
    as InstanceOf['Google::Cloud::Datafusion::V1beta1::V1beta1::AddDnsPeeringRequest'];

coerce 'AddDnsPeeringRequest',
    from HashRef, via { 'Google::Cloud::Datafusion::V1beta1::V1beta1::AddDnsPeeringRequest'->new($_) };

declare 'RepeatedAddDnsPeeringRequest',
    as ArrayRef[AddDnsPeeringRequest()];

coerce 'RepeatedAddDnsPeeringRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datafusion::V1beta1::V1beta1::AddDnsPeeringRequest'->new($_) } @$_ ] };

declare 'MapStringAddDnsPeeringRequest',
    as HashRef[AddDnsPeeringRequest()];

declare 'AddDnsPeeringResponse',
    as InstanceOf['Google::Cloud::Datafusion::V1beta1::V1beta1::AddDnsPeeringResponse'];

coerce 'AddDnsPeeringResponse',
    from HashRef, via { 'Google::Cloud::Datafusion::V1beta1::V1beta1::AddDnsPeeringResponse'->new($_) };

declare 'RepeatedAddDnsPeeringResponse',
    as ArrayRef[AddDnsPeeringResponse()];

coerce 'RepeatedAddDnsPeeringResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datafusion::V1beta1::V1beta1::AddDnsPeeringResponse'->new($_) } @$_ ] };

declare 'MapStringAddDnsPeeringResponse',
    as HashRef[AddDnsPeeringResponse()];

declare 'RemoveDnsPeeringRequest',
    as InstanceOf['Google::Cloud::Datafusion::V1beta1::V1beta1::RemoveDnsPeeringRequest'];

coerce 'RemoveDnsPeeringRequest',
    from HashRef, via { 'Google::Cloud::Datafusion::V1beta1::V1beta1::RemoveDnsPeeringRequest'->new($_) };

declare 'RepeatedRemoveDnsPeeringRequest',
    as ArrayRef[RemoveDnsPeeringRequest()];

coerce 'RepeatedRemoveDnsPeeringRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datafusion::V1beta1::V1beta1::RemoveDnsPeeringRequest'->new($_) } @$_ ] };

declare 'MapStringRemoveDnsPeeringRequest',
    as HashRef[RemoveDnsPeeringRequest()];

declare 'RemoveDnsPeeringResponse',
    as InstanceOf['Google::Cloud::Datafusion::V1beta1::V1beta1::RemoveDnsPeeringResponse'];

coerce 'RemoveDnsPeeringResponse',
    from HashRef, via { 'Google::Cloud::Datafusion::V1beta1::V1beta1::RemoveDnsPeeringResponse'->new($_) };

declare 'RepeatedRemoveDnsPeeringResponse',
    as ArrayRef[RemoveDnsPeeringResponse()];

coerce 'RepeatedRemoveDnsPeeringResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datafusion::V1beta1::V1beta1::RemoveDnsPeeringResponse'->new($_) } @$_ ] };

declare 'MapStringRemoveDnsPeeringResponse',
    as HashRef[RemoveDnsPeeringResponse()];

declare 'ListDnsPeeringsRequest',
    as InstanceOf['Google::Cloud::Datafusion::V1beta1::V1beta1::ListDnsPeeringsRequest'];

coerce 'ListDnsPeeringsRequest',
    from HashRef, via { 'Google::Cloud::Datafusion::V1beta1::V1beta1::ListDnsPeeringsRequest'->new($_) };

declare 'RepeatedListDnsPeeringsRequest',
    as ArrayRef[ListDnsPeeringsRequest()];

coerce 'RepeatedListDnsPeeringsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datafusion::V1beta1::V1beta1::ListDnsPeeringsRequest'->new($_) } @$_ ] };

declare 'MapStringListDnsPeeringsRequest',
    as HashRef[ListDnsPeeringsRequest()];

declare 'ListDnsPeeringsResponse',
    as InstanceOf['Google::Cloud::Datafusion::V1beta1::V1beta1::ListDnsPeeringsResponse'];

coerce 'ListDnsPeeringsResponse',
    from HashRef, via { 'Google::Cloud::Datafusion::V1beta1::V1beta1::ListDnsPeeringsResponse'->new($_) };

declare 'RepeatedListDnsPeeringsResponse',
    as ArrayRef[ListDnsPeeringsResponse()];

coerce 'RepeatedListDnsPeeringsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datafusion::V1beta1::V1beta1::ListDnsPeeringsResponse'->new($_) } @$_ ] };

declare 'MapStringListDnsPeeringsResponse',
    as HashRef[ListDnsPeeringsResponse()];

1;

__END__

=head1 NAME

Google::Cloud::Datafusion::V1beta1::V1beta1::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
