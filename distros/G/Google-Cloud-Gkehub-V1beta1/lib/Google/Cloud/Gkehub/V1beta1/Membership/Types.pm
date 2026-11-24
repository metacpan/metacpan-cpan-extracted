package Google::Cloud::Gkehub::V1beta1::Membership::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Membership',
    as InstanceOf['Google::Cloud::Gkehub::V1beta1::Membership::Membership'];

coerce 'Membership',
    from HashRef, via { 'Google::Cloud::Gkehub::V1beta1::Membership::Membership'->new($_) };

declare 'RepeatedMembership',
    as ArrayRef[Membership()];

coerce 'RepeatedMembership',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkehub::V1beta1::Membership::Membership'->new($_) } @$_ ] };

declare 'MapStringMembership',
    as HashRef[Membership()];

declare 'InfrastructureType',
    as (Int | Str);

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Gkehub::V1beta1::Membership::Membership::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Gkehub::V1beta1::Membership::Membership::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkehub::V1beta1::Membership::Membership::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'MembershipEndpoint',
    as InstanceOf['Google::Cloud::Gkehub::V1beta1::Membership::MembershipEndpoint'];

coerce 'MembershipEndpoint',
    from HashRef, via { 'Google::Cloud::Gkehub::V1beta1::Membership::MembershipEndpoint'->new($_) };

declare 'RepeatedMembershipEndpoint',
    as ArrayRef[MembershipEndpoint()];

coerce 'RepeatedMembershipEndpoint',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkehub::V1beta1::Membership::MembershipEndpoint'->new($_) } @$_ ] };

declare 'MapStringMembershipEndpoint',
    as HashRef[MembershipEndpoint()];

declare 'KubernetesResource',
    as InstanceOf['Google::Cloud::Gkehub::V1beta1::Membership::KubernetesResource'];

coerce 'KubernetesResource',
    from HashRef, via { 'Google::Cloud::Gkehub::V1beta1::Membership::KubernetesResource'->new($_) };

declare 'RepeatedKubernetesResource',
    as ArrayRef[KubernetesResource()];

coerce 'RepeatedKubernetesResource',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkehub::V1beta1::Membership::KubernetesResource'->new($_) } @$_ ] };

declare 'MapStringKubernetesResource',
    as HashRef[KubernetesResource()];

declare 'ResourceOptions',
    as InstanceOf['Google::Cloud::Gkehub::V1beta1::Membership::ResourceOptions'];

coerce 'ResourceOptions',
    from HashRef, via { 'Google::Cloud::Gkehub::V1beta1::Membership::ResourceOptions'->new($_) };

declare 'RepeatedResourceOptions',
    as ArrayRef[ResourceOptions()];

coerce 'RepeatedResourceOptions',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkehub::V1beta1::Membership::ResourceOptions'->new($_) } @$_ ] };

declare 'MapStringResourceOptions',
    as HashRef[ResourceOptions()];

declare 'ResourceManifest',
    as InstanceOf['Google::Cloud::Gkehub::V1beta1::Membership::ResourceManifest'];

coerce 'ResourceManifest',
    from HashRef, via { 'Google::Cloud::Gkehub::V1beta1::Membership::ResourceManifest'->new($_) };

declare 'RepeatedResourceManifest',
    as ArrayRef[ResourceManifest()];

coerce 'RepeatedResourceManifest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkehub::V1beta1::Membership::ResourceManifest'->new($_) } @$_ ] };

declare 'MapStringResourceManifest',
    as HashRef[ResourceManifest()];

declare 'GkeCluster',
    as InstanceOf['Google::Cloud::Gkehub::V1beta1::Membership::GkeCluster'];

coerce 'GkeCluster',
    from HashRef, via { 'Google::Cloud::Gkehub::V1beta1::Membership::GkeCluster'->new($_) };

declare 'RepeatedGkeCluster',
    as ArrayRef[GkeCluster()];

coerce 'RepeatedGkeCluster',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkehub::V1beta1::Membership::GkeCluster'->new($_) } @$_ ] };

declare 'MapStringGkeCluster',
    as HashRef[GkeCluster()];

declare 'OnPremCluster',
    as InstanceOf['Google::Cloud::Gkehub::V1beta1::Membership::OnPremCluster'];

coerce 'OnPremCluster',
    from HashRef, via { 'Google::Cloud::Gkehub::V1beta1::Membership::OnPremCluster'->new($_) };

declare 'RepeatedOnPremCluster',
    as ArrayRef[OnPremCluster()];

coerce 'RepeatedOnPremCluster',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkehub::V1beta1::Membership::OnPremCluster'->new($_) } @$_ ] };

declare 'MapStringOnPremCluster',
    as HashRef[OnPremCluster()];

declare 'ClusterType',
    as (Int | Str);

declare 'MultiCloudCluster',
    as InstanceOf['Google::Cloud::Gkehub::V1beta1::Membership::MultiCloudCluster'];

coerce 'MultiCloudCluster',
    from HashRef, via { 'Google::Cloud::Gkehub::V1beta1::Membership::MultiCloudCluster'->new($_) };

declare 'RepeatedMultiCloudCluster',
    as ArrayRef[MultiCloudCluster()];

coerce 'RepeatedMultiCloudCluster',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkehub::V1beta1::Membership::MultiCloudCluster'->new($_) } @$_ ] };

declare 'MapStringMultiCloudCluster',
    as HashRef[MultiCloudCluster()];

declare 'EdgeCluster',
    as InstanceOf['Google::Cloud::Gkehub::V1beta1::Membership::EdgeCluster'];

coerce 'EdgeCluster',
    from HashRef, via { 'Google::Cloud::Gkehub::V1beta1::Membership::EdgeCluster'->new($_) };

declare 'RepeatedEdgeCluster',
    as ArrayRef[EdgeCluster()];

coerce 'RepeatedEdgeCluster',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkehub::V1beta1::Membership::EdgeCluster'->new($_) } @$_ ] };

declare 'MapStringEdgeCluster',
    as HashRef[EdgeCluster()];

declare 'ApplianceCluster',
    as InstanceOf['Google::Cloud::Gkehub::V1beta1::Membership::ApplianceCluster'];

coerce 'ApplianceCluster',
    from HashRef, via { 'Google::Cloud::Gkehub::V1beta1::Membership::ApplianceCluster'->new($_) };

declare 'RepeatedApplianceCluster',
    as ArrayRef[ApplianceCluster()];

coerce 'RepeatedApplianceCluster',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkehub::V1beta1::Membership::ApplianceCluster'->new($_) } @$_ ] };

declare 'MapStringApplianceCluster',
    as HashRef[ApplianceCluster()];

declare 'KubernetesMetadata',
    as InstanceOf['Google::Cloud::Gkehub::V1beta1::Membership::KubernetesMetadata'];

coerce 'KubernetesMetadata',
    from HashRef, via { 'Google::Cloud::Gkehub::V1beta1::Membership::KubernetesMetadata'->new($_) };

declare 'RepeatedKubernetesMetadata',
    as ArrayRef[KubernetesMetadata()];

coerce 'RepeatedKubernetesMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkehub::V1beta1::Membership::KubernetesMetadata'->new($_) } @$_ ] };

declare 'MapStringKubernetesMetadata',
    as HashRef[KubernetesMetadata()];

declare 'Authority',
    as InstanceOf['Google::Cloud::Gkehub::V1beta1::Membership::Authority'];

coerce 'Authority',
    from HashRef, via { 'Google::Cloud::Gkehub::V1beta1::Membership::Authority'->new($_) };

declare 'RepeatedAuthority',
    as ArrayRef[Authority()];

coerce 'RepeatedAuthority',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkehub::V1beta1::Membership::Authority'->new($_) } @$_ ] };

declare 'MapStringAuthority',
    as HashRef[Authority()];

declare 'MonitoringConfig',
    as InstanceOf['Google::Cloud::Gkehub::V1beta1::Membership::MonitoringConfig'];

coerce 'MonitoringConfig',
    from HashRef, via { 'Google::Cloud::Gkehub::V1beta1::Membership::MonitoringConfig'->new($_) };

declare 'RepeatedMonitoringConfig',
    as ArrayRef[MonitoringConfig()];

coerce 'RepeatedMonitoringConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkehub::V1beta1::Membership::MonitoringConfig'->new($_) } @$_ ] };

declare 'MapStringMonitoringConfig',
    as HashRef[MonitoringConfig()];

declare 'MembershipState',
    as InstanceOf['Google::Cloud::Gkehub::V1beta1::Membership::MembershipState'];

coerce 'MembershipState',
    from HashRef, via { 'Google::Cloud::Gkehub::V1beta1::Membership::MembershipState'->new($_) };

declare 'RepeatedMembershipState',
    as ArrayRef[MembershipState()];

coerce 'RepeatedMembershipState',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkehub::V1beta1::Membership::MembershipState'->new($_) } @$_ ] };

declare 'MapStringMembershipState',
    as HashRef[MembershipState()];

declare 'Code',
    as (Int | Str);

declare 'ListMembershipsRequest',
    as InstanceOf['Google::Cloud::Gkehub::V1beta1::Membership::ListMembershipsRequest'];

coerce 'ListMembershipsRequest',
    from HashRef, via { 'Google::Cloud::Gkehub::V1beta1::Membership::ListMembershipsRequest'->new($_) };

declare 'RepeatedListMembershipsRequest',
    as ArrayRef[ListMembershipsRequest()];

coerce 'RepeatedListMembershipsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkehub::V1beta1::Membership::ListMembershipsRequest'->new($_) } @$_ ] };

declare 'MapStringListMembershipsRequest',
    as HashRef[ListMembershipsRequest()];

declare 'ListMembershipsResponse',
    as InstanceOf['Google::Cloud::Gkehub::V1beta1::Membership::ListMembershipsResponse'];

coerce 'ListMembershipsResponse',
    from HashRef, via { 'Google::Cloud::Gkehub::V1beta1::Membership::ListMembershipsResponse'->new($_) };

declare 'RepeatedListMembershipsResponse',
    as ArrayRef[ListMembershipsResponse()];

coerce 'RepeatedListMembershipsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkehub::V1beta1::Membership::ListMembershipsResponse'->new($_) } @$_ ] };

declare 'MapStringListMembershipsResponse',
    as HashRef[ListMembershipsResponse()];

declare 'GetMembershipRequest',
    as InstanceOf['Google::Cloud::Gkehub::V1beta1::Membership::GetMembershipRequest'];

coerce 'GetMembershipRequest',
    from HashRef, via { 'Google::Cloud::Gkehub::V1beta1::Membership::GetMembershipRequest'->new($_) };

declare 'RepeatedGetMembershipRequest',
    as ArrayRef[GetMembershipRequest()];

coerce 'RepeatedGetMembershipRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkehub::V1beta1::Membership::GetMembershipRequest'->new($_) } @$_ ] };

declare 'MapStringGetMembershipRequest',
    as HashRef[GetMembershipRequest()];

declare 'CreateMembershipRequest',
    as InstanceOf['Google::Cloud::Gkehub::V1beta1::Membership::CreateMembershipRequest'];

coerce 'CreateMembershipRequest',
    from HashRef, via { 'Google::Cloud::Gkehub::V1beta1::Membership::CreateMembershipRequest'->new($_) };

declare 'RepeatedCreateMembershipRequest',
    as ArrayRef[CreateMembershipRequest()];

coerce 'RepeatedCreateMembershipRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkehub::V1beta1::Membership::CreateMembershipRequest'->new($_) } @$_ ] };

declare 'MapStringCreateMembershipRequest',
    as HashRef[CreateMembershipRequest()];

declare 'DeleteMembershipRequest',
    as InstanceOf['Google::Cloud::Gkehub::V1beta1::Membership::DeleteMembershipRequest'];

coerce 'DeleteMembershipRequest',
    from HashRef, via { 'Google::Cloud::Gkehub::V1beta1::Membership::DeleteMembershipRequest'->new($_) };

declare 'RepeatedDeleteMembershipRequest',
    as ArrayRef[DeleteMembershipRequest()];

coerce 'RepeatedDeleteMembershipRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkehub::V1beta1::Membership::DeleteMembershipRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteMembershipRequest',
    as HashRef[DeleteMembershipRequest()];

declare 'UpdateMembershipRequest',
    as InstanceOf['Google::Cloud::Gkehub::V1beta1::Membership::UpdateMembershipRequest'];

coerce 'UpdateMembershipRequest',
    from HashRef, via { 'Google::Cloud::Gkehub::V1beta1::Membership::UpdateMembershipRequest'->new($_) };

declare 'RepeatedUpdateMembershipRequest',
    as ArrayRef[UpdateMembershipRequest()];

coerce 'RepeatedUpdateMembershipRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkehub::V1beta1::Membership::UpdateMembershipRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateMembershipRequest',
    as HashRef[UpdateMembershipRequest()];

declare 'GenerateConnectManifestRequest',
    as InstanceOf['Google::Cloud::Gkehub::V1beta1::Membership::GenerateConnectManifestRequest'];

coerce 'GenerateConnectManifestRequest',
    from HashRef, via { 'Google::Cloud::Gkehub::V1beta1::Membership::GenerateConnectManifestRequest'->new($_) };

declare 'RepeatedGenerateConnectManifestRequest',
    as ArrayRef[GenerateConnectManifestRequest()];

coerce 'RepeatedGenerateConnectManifestRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkehub::V1beta1::Membership::GenerateConnectManifestRequest'->new($_) } @$_ ] };

declare 'MapStringGenerateConnectManifestRequest',
    as HashRef[GenerateConnectManifestRequest()];

declare 'GenerateConnectManifestResponse',
    as InstanceOf['Google::Cloud::Gkehub::V1beta1::Membership::GenerateConnectManifestResponse'];

coerce 'GenerateConnectManifestResponse',
    from HashRef, via { 'Google::Cloud::Gkehub::V1beta1::Membership::GenerateConnectManifestResponse'->new($_) };

declare 'RepeatedGenerateConnectManifestResponse',
    as ArrayRef[GenerateConnectManifestResponse()];

coerce 'RepeatedGenerateConnectManifestResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkehub::V1beta1::Membership::GenerateConnectManifestResponse'->new($_) } @$_ ] };

declare 'MapStringGenerateConnectManifestResponse',
    as HashRef[GenerateConnectManifestResponse()];

declare 'ConnectAgentResource',
    as InstanceOf['Google::Cloud::Gkehub::V1beta1::Membership::ConnectAgentResource'];

coerce 'ConnectAgentResource',
    from HashRef, via { 'Google::Cloud::Gkehub::V1beta1::Membership::ConnectAgentResource'->new($_) };

declare 'RepeatedConnectAgentResource',
    as ArrayRef[ConnectAgentResource()];

coerce 'RepeatedConnectAgentResource',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkehub::V1beta1::Membership::ConnectAgentResource'->new($_) } @$_ ] };

declare 'MapStringConnectAgentResource',
    as HashRef[ConnectAgentResource()];

declare 'TypeMeta',
    as InstanceOf['Google::Cloud::Gkehub::V1beta1::Membership::TypeMeta'];

coerce 'TypeMeta',
    from HashRef, via { 'Google::Cloud::Gkehub::V1beta1::Membership::TypeMeta'->new($_) };

declare 'RepeatedTypeMeta',
    as ArrayRef[TypeMeta()];

coerce 'RepeatedTypeMeta',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkehub::V1beta1::Membership::TypeMeta'->new($_) } @$_ ] };

declare 'MapStringTypeMeta',
    as HashRef[TypeMeta()];

declare 'ConnectAgent',
    as InstanceOf['Google::Cloud::Gkehub::V1beta1::Membership::ConnectAgent'];

coerce 'ConnectAgent',
    from HashRef, via { 'Google::Cloud::Gkehub::V1beta1::Membership::ConnectAgent'->new($_) };

declare 'RepeatedConnectAgent',
    as ArrayRef[ConnectAgent()];

coerce 'RepeatedConnectAgent',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkehub::V1beta1::Membership::ConnectAgent'->new($_) } @$_ ] };

declare 'MapStringConnectAgent',
    as HashRef[ConnectAgent()];

declare 'ValidateExclusivityRequest',
    as InstanceOf['Google::Cloud::Gkehub::V1beta1::Membership::ValidateExclusivityRequest'];

coerce 'ValidateExclusivityRequest',
    from HashRef, via { 'Google::Cloud::Gkehub::V1beta1::Membership::ValidateExclusivityRequest'->new($_) };

declare 'RepeatedValidateExclusivityRequest',
    as ArrayRef[ValidateExclusivityRequest()];

coerce 'RepeatedValidateExclusivityRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkehub::V1beta1::Membership::ValidateExclusivityRequest'->new($_) } @$_ ] };

declare 'MapStringValidateExclusivityRequest',
    as HashRef[ValidateExclusivityRequest()];

declare 'ValidateExclusivityResponse',
    as InstanceOf['Google::Cloud::Gkehub::V1beta1::Membership::ValidateExclusivityResponse'];

coerce 'ValidateExclusivityResponse',
    from HashRef, via { 'Google::Cloud::Gkehub::V1beta1::Membership::ValidateExclusivityResponse'->new($_) };

declare 'RepeatedValidateExclusivityResponse',
    as ArrayRef[ValidateExclusivityResponse()];

coerce 'RepeatedValidateExclusivityResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkehub::V1beta1::Membership::ValidateExclusivityResponse'->new($_) } @$_ ] };

declare 'MapStringValidateExclusivityResponse',
    as HashRef[ValidateExclusivityResponse()];

declare 'GenerateExclusivityManifestRequest',
    as InstanceOf['Google::Cloud::Gkehub::V1beta1::Membership::GenerateExclusivityManifestRequest'];

coerce 'GenerateExclusivityManifestRequest',
    from HashRef, via { 'Google::Cloud::Gkehub::V1beta1::Membership::GenerateExclusivityManifestRequest'->new($_) };

declare 'RepeatedGenerateExclusivityManifestRequest',
    as ArrayRef[GenerateExclusivityManifestRequest()];

coerce 'RepeatedGenerateExclusivityManifestRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkehub::V1beta1::Membership::GenerateExclusivityManifestRequest'->new($_) } @$_ ] };

declare 'MapStringGenerateExclusivityManifestRequest',
    as HashRef[GenerateExclusivityManifestRequest()];

declare 'GenerateExclusivityManifestResponse',
    as InstanceOf['Google::Cloud::Gkehub::V1beta1::Membership::GenerateExclusivityManifestResponse'];

coerce 'GenerateExclusivityManifestResponse',
    from HashRef, via { 'Google::Cloud::Gkehub::V1beta1::Membership::GenerateExclusivityManifestResponse'->new($_) };

declare 'RepeatedGenerateExclusivityManifestResponse',
    as ArrayRef[GenerateExclusivityManifestResponse()];

coerce 'RepeatedGenerateExclusivityManifestResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkehub::V1beta1::Membership::GenerateExclusivityManifestResponse'->new($_) } @$_ ] };

declare 'MapStringGenerateExclusivityManifestResponse',
    as HashRef[GenerateExclusivityManifestResponse()];

declare 'OperationMetadata',
    as InstanceOf['Google::Cloud::Gkehub::V1beta1::Membership::OperationMetadata'];

coerce 'OperationMetadata',
    from HashRef, via { 'Google::Cloud::Gkehub::V1beta1::Membership::OperationMetadata'->new($_) };

declare 'RepeatedOperationMetadata',
    as ArrayRef[OperationMetadata()];

coerce 'RepeatedOperationMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkehub::V1beta1::Membership::OperationMetadata'->new($_) } @$_ ] };

declare 'MapStringOperationMetadata',
    as HashRef[OperationMetadata()];

1;

__END__

=head1 NAME

Google::Cloud::Gkehub::V1beta1::Membership::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
