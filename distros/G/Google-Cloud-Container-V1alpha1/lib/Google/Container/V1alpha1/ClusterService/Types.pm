package Google::Container::V1alpha1::ClusterService::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'NodeConfig',
    as InstanceOf['Google::Container::V1alpha1::ClusterService::NodeConfig'];

coerce 'NodeConfig',
    from HashRef, via { 'Google::Container::V1alpha1::ClusterService::NodeConfig'->new($_) };

declare 'RepeatedNodeConfig',
    as ArrayRef[NodeConfig()];

coerce 'RepeatedNodeConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1alpha1::ClusterService::NodeConfig'->new($_) } @$_ ] };

declare 'MapStringNodeConfig',
    as HashRef[NodeConfig()];

declare 'MetadataEntry',
    as InstanceOf['Google::Container::V1alpha1::ClusterService::NodeConfig::MetadataEntry'];

coerce 'MetadataEntry',
    from HashRef, via { 'Google::Container::V1alpha1::ClusterService::NodeConfig::MetadataEntry'->new($_) };

declare 'RepeatedMetadataEntry',
    as ArrayRef[MetadataEntry()];

coerce 'RepeatedMetadataEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1alpha1::ClusterService::NodeConfig::MetadataEntry'->new($_) } @$_ ] };

declare 'MapStringMetadataEntry',
    as HashRef[MetadataEntry()];

declare 'LabelsEntry',
    as InstanceOf['Google::Container::V1alpha1::ClusterService::NodeConfig::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Container::V1alpha1::ClusterService::NodeConfig::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1alpha1::ClusterService::NodeConfig::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'NodeTaint',
    as InstanceOf['Google::Container::V1alpha1::ClusterService::NodeTaint'];

coerce 'NodeTaint',
    from HashRef, via { 'Google::Container::V1alpha1::ClusterService::NodeTaint'->new($_) };

declare 'RepeatedNodeTaint',
    as ArrayRef[NodeTaint()];

coerce 'RepeatedNodeTaint',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1alpha1::ClusterService::NodeTaint'->new($_) } @$_ ] };

declare 'MapStringNodeTaint',
    as HashRef[NodeTaint()];

declare 'Effect',
    as (Int | Str);

declare 'MasterAuth',
    as InstanceOf['Google::Container::V1alpha1::ClusterService::MasterAuth'];

coerce 'MasterAuth',
    from HashRef, via { 'Google::Container::V1alpha1::ClusterService::MasterAuth'->new($_) };

declare 'RepeatedMasterAuth',
    as ArrayRef[MasterAuth()];

coerce 'RepeatedMasterAuth',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1alpha1::ClusterService::MasterAuth'->new($_) } @$_ ] };

declare 'MapStringMasterAuth',
    as HashRef[MasterAuth()];

declare 'ClientCertificateConfig',
    as InstanceOf['Google::Container::V1alpha1::ClusterService::ClientCertificateConfig'];

coerce 'ClientCertificateConfig',
    from HashRef, via { 'Google::Container::V1alpha1::ClusterService::ClientCertificateConfig'->new($_) };

declare 'RepeatedClientCertificateConfig',
    as ArrayRef[ClientCertificateConfig()];

coerce 'RepeatedClientCertificateConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1alpha1::ClusterService::ClientCertificateConfig'->new($_) } @$_ ] };

declare 'MapStringClientCertificateConfig',
    as HashRef[ClientCertificateConfig()];

declare 'AddonsConfig',
    as InstanceOf['Google::Container::V1alpha1::ClusterService::AddonsConfig'];

coerce 'AddonsConfig',
    from HashRef, via { 'Google::Container::V1alpha1::ClusterService::AddonsConfig'->new($_) };

declare 'RepeatedAddonsConfig',
    as ArrayRef[AddonsConfig()];

coerce 'RepeatedAddonsConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1alpha1::ClusterService::AddonsConfig'->new($_) } @$_ ] };

declare 'MapStringAddonsConfig',
    as HashRef[AddonsConfig()];

declare 'HttpLoadBalancing',
    as InstanceOf['Google::Container::V1alpha1::ClusterService::HttpLoadBalancing'];

coerce 'HttpLoadBalancing',
    from HashRef, via { 'Google::Container::V1alpha1::ClusterService::HttpLoadBalancing'->new($_) };

declare 'RepeatedHttpLoadBalancing',
    as ArrayRef[HttpLoadBalancing()];

coerce 'RepeatedHttpLoadBalancing',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1alpha1::ClusterService::HttpLoadBalancing'->new($_) } @$_ ] };

declare 'MapStringHttpLoadBalancing',
    as HashRef[HttpLoadBalancing()];

declare 'HorizontalPodAutoscaling',
    as InstanceOf['Google::Container::V1alpha1::ClusterService::HorizontalPodAutoscaling'];

coerce 'HorizontalPodAutoscaling',
    from HashRef, via { 'Google::Container::V1alpha1::ClusterService::HorizontalPodAutoscaling'->new($_) };

declare 'RepeatedHorizontalPodAutoscaling',
    as ArrayRef[HorizontalPodAutoscaling()];

coerce 'RepeatedHorizontalPodAutoscaling',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1alpha1::ClusterService::HorizontalPodAutoscaling'->new($_) } @$_ ] };

declare 'MapStringHorizontalPodAutoscaling',
    as HashRef[HorizontalPodAutoscaling()];

declare 'KubernetesDashboard',
    as InstanceOf['Google::Container::V1alpha1::ClusterService::KubernetesDashboard'];

coerce 'KubernetesDashboard',
    from HashRef, via { 'Google::Container::V1alpha1::ClusterService::KubernetesDashboard'->new($_) };

declare 'RepeatedKubernetesDashboard',
    as ArrayRef[KubernetesDashboard()];

coerce 'RepeatedKubernetesDashboard',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1alpha1::ClusterService::KubernetesDashboard'->new($_) } @$_ ] };

declare 'MapStringKubernetesDashboard',
    as HashRef[KubernetesDashboard()];

declare 'NetworkPolicyConfig',
    as InstanceOf['Google::Container::V1alpha1::ClusterService::NetworkPolicyConfig'];

coerce 'NetworkPolicyConfig',
    from HashRef, via { 'Google::Container::V1alpha1::ClusterService::NetworkPolicyConfig'->new($_) };

declare 'RepeatedNetworkPolicyConfig',
    as ArrayRef[NetworkPolicyConfig()];

coerce 'RepeatedNetworkPolicyConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1alpha1::ClusterService::NetworkPolicyConfig'->new($_) } @$_ ] };

declare 'MapStringNetworkPolicyConfig',
    as HashRef[NetworkPolicyConfig()];

declare 'MasterAuthorizedNetworksConfig',
    as InstanceOf['Google::Container::V1alpha1::ClusterService::MasterAuthorizedNetworksConfig'];

coerce 'MasterAuthorizedNetworksConfig',
    from HashRef, via { 'Google::Container::V1alpha1::ClusterService::MasterAuthorizedNetworksConfig'->new($_) };

declare 'RepeatedMasterAuthorizedNetworksConfig',
    as ArrayRef[MasterAuthorizedNetworksConfig()];

coerce 'RepeatedMasterAuthorizedNetworksConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1alpha1::ClusterService::MasterAuthorizedNetworksConfig'->new($_) } @$_ ] };

declare 'MapStringMasterAuthorizedNetworksConfig',
    as HashRef[MasterAuthorizedNetworksConfig()];

declare 'CidrBlock',
    as InstanceOf['Google::Container::V1alpha1::ClusterService::MasterAuthorizedNetworksConfig::CidrBlock'];

coerce 'CidrBlock',
    from HashRef, via { 'Google::Container::V1alpha1::ClusterService::MasterAuthorizedNetworksConfig::CidrBlock'->new($_) };

declare 'RepeatedCidrBlock',
    as ArrayRef[CidrBlock()];

coerce 'RepeatedCidrBlock',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1alpha1::ClusterService::MasterAuthorizedNetworksConfig::CidrBlock'->new($_) } @$_ ] };

declare 'MapStringCidrBlock',
    as HashRef[CidrBlock()];

declare 'NetworkPolicy',
    as InstanceOf['Google::Container::V1alpha1::ClusterService::NetworkPolicy'];

coerce 'NetworkPolicy',
    from HashRef, via { 'Google::Container::V1alpha1::ClusterService::NetworkPolicy'->new($_) };

declare 'RepeatedNetworkPolicy',
    as ArrayRef[NetworkPolicy()];

coerce 'RepeatedNetworkPolicy',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1alpha1::ClusterService::NetworkPolicy'->new($_) } @$_ ] };

declare 'MapStringNetworkPolicy',
    as HashRef[NetworkPolicy()];

declare 'Provider',
    as (Int | Str);

declare 'IPAllocationPolicy',
    as InstanceOf['Google::Container::V1alpha1::ClusterService::IPAllocationPolicy'];

coerce 'IPAllocationPolicy',
    from HashRef, via { 'Google::Container::V1alpha1::ClusterService::IPAllocationPolicy'->new($_) };

declare 'RepeatedIPAllocationPolicy',
    as ArrayRef[IPAllocationPolicy()];

coerce 'RepeatedIPAllocationPolicy',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1alpha1::ClusterService::IPAllocationPolicy'->new($_) } @$_ ] };

declare 'MapStringIPAllocationPolicy',
    as HashRef[IPAllocationPolicy()];

declare 'PodSecurityPolicyConfig',
    as InstanceOf['Google::Container::V1alpha1::ClusterService::PodSecurityPolicyConfig'];

coerce 'PodSecurityPolicyConfig',
    from HashRef, via { 'Google::Container::V1alpha1::ClusterService::PodSecurityPolicyConfig'->new($_) };

declare 'RepeatedPodSecurityPolicyConfig',
    as ArrayRef[PodSecurityPolicyConfig()];

coerce 'RepeatedPodSecurityPolicyConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1alpha1::ClusterService::PodSecurityPolicyConfig'->new($_) } @$_ ] };

declare 'MapStringPodSecurityPolicyConfig',
    as HashRef[PodSecurityPolicyConfig()];

declare 'Cluster',
    as InstanceOf['Google::Container::V1alpha1::ClusterService::Cluster'];

coerce 'Cluster',
    from HashRef, via { 'Google::Container::V1alpha1::ClusterService::Cluster'->new($_) };

declare 'RepeatedCluster',
    as ArrayRef[Cluster()];

coerce 'RepeatedCluster',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1alpha1::ClusterService::Cluster'->new($_) } @$_ ] };

declare 'MapStringCluster',
    as HashRef[Cluster()];

declare 'Status',
    as (Int | Str);

declare 'ClusterUpdate',
    as InstanceOf['Google::Container::V1alpha1::ClusterService::ClusterUpdate'];

coerce 'ClusterUpdate',
    from HashRef, via { 'Google::Container::V1alpha1::ClusterService::ClusterUpdate'->new($_) };

declare 'RepeatedClusterUpdate',
    as ArrayRef[ClusterUpdate()];

coerce 'RepeatedClusterUpdate',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1alpha1::ClusterService::ClusterUpdate'->new($_) } @$_ ] };

declare 'MapStringClusterUpdate',
    as HashRef[ClusterUpdate()];

declare 'Operation',
    as InstanceOf['Google::Container::V1alpha1::ClusterService::Operation'];

coerce 'Operation',
    from HashRef, via { 'Google::Container::V1alpha1::ClusterService::Operation'->new($_) };

declare 'RepeatedOperation',
    as ArrayRef[Operation()];

coerce 'RepeatedOperation',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1alpha1::ClusterService::Operation'->new($_) } @$_ ] };

declare 'MapStringOperation',
    as HashRef[Operation()];

declare 'Status',
    as (Int | Str);

declare 'Type',
    as (Int | Str);

declare 'CreateClusterRequest',
    as InstanceOf['Google::Container::V1alpha1::ClusterService::CreateClusterRequest'];

coerce 'CreateClusterRequest',
    from HashRef, via { 'Google::Container::V1alpha1::ClusterService::CreateClusterRequest'->new($_) };

declare 'RepeatedCreateClusterRequest',
    as ArrayRef[CreateClusterRequest()];

coerce 'RepeatedCreateClusterRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1alpha1::ClusterService::CreateClusterRequest'->new($_) } @$_ ] };

declare 'MapStringCreateClusterRequest',
    as HashRef[CreateClusterRequest()];

declare 'GetClusterRequest',
    as InstanceOf['Google::Container::V1alpha1::ClusterService::GetClusterRequest'];

coerce 'GetClusterRequest',
    from HashRef, via { 'Google::Container::V1alpha1::ClusterService::GetClusterRequest'->new($_) };

declare 'RepeatedGetClusterRequest',
    as ArrayRef[GetClusterRequest()];

coerce 'RepeatedGetClusterRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1alpha1::ClusterService::GetClusterRequest'->new($_) } @$_ ] };

declare 'MapStringGetClusterRequest',
    as HashRef[GetClusterRequest()];

declare 'UpdateClusterRequest',
    as InstanceOf['Google::Container::V1alpha1::ClusterService::UpdateClusterRequest'];

coerce 'UpdateClusterRequest',
    from HashRef, via { 'Google::Container::V1alpha1::ClusterService::UpdateClusterRequest'->new($_) };

declare 'RepeatedUpdateClusterRequest',
    as ArrayRef[UpdateClusterRequest()];

coerce 'RepeatedUpdateClusterRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1alpha1::ClusterService::UpdateClusterRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateClusterRequest',
    as HashRef[UpdateClusterRequest()];

declare 'UpdateNodePoolRequest',
    as InstanceOf['Google::Container::V1alpha1::ClusterService::UpdateNodePoolRequest'];

coerce 'UpdateNodePoolRequest',
    from HashRef, via { 'Google::Container::V1alpha1::ClusterService::UpdateNodePoolRequest'->new($_) };

declare 'RepeatedUpdateNodePoolRequest',
    as ArrayRef[UpdateNodePoolRequest()];

coerce 'RepeatedUpdateNodePoolRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1alpha1::ClusterService::UpdateNodePoolRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateNodePoolRequest',
    as HashRef[UpdateNodePoolRequest()];

declare 'SetNodePoolAutoscalingRequest',
    as InstanceOf['Google::Container::V1alpha1::ClusterService::SetNodePoolAutoscalingRequest'];

coerce 'SetNodePoolAutoscalingRequest',
    from HashRef, via { 'Google::Container::V1alpha1::ClusterService::SetNodePoolAutoscalingRequest'->new($_) };

declare 'RepeatedSetNodePoolAutoscalingRequest',
    as ArrayRef[SetNodePoolAutoscalingRequest()];

coerce 'RepeatedSetNodePoolAutoscalingRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1alpha1::ClusterService::SetNodePoolAutoscalingRequest'->new($_) } @$_ ] };

declare 'MapStringSetNodePoolAutoscalingRequest',
    as HashRef[SetNodePoolAutoscalingRequest()];

declare 'SetLoggingServiceRequest',
    as InstanceOf['Google::Container::V1alpha1::ClusterService::SetLoggingServiceRequest'];

coerce 'SetLoggingServiceRequest',
    from HashRef, via { 'Google::Container::V1alpha1::ClusterService::SetLoggingServiceRequest'->new($_) };

declare 'RepeatedSetLoggingServiceRequest',
    as ArrayRef[SetLoggingServiceRequest()];

coerce 'RepeatedSetLoggingServiceRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1alpha1::ClusterService::SetLoggingServiceRequest'->new($_) } @$_ ] };

declare 'MapStringSetLoggingServiceRequest',
    as HashRef[SetLoggingServiceRequest()];

declare 'SetMonitoringServiceRequest',
    as InstanceOf['Google::Container::V1alpha1::ClusterService::SetMonitoringServiceRequest'];

coerce 'SetMonitoringServiceRequest',
    from HashRef, via { 'Google::Container::V1alpha1::ClusterService::SetMonitoringServiceRequest'->new($_) };

declare 'RepeatedSetMonitoringServiceRequest',
    as ArrayRef[SetMonitoringServiceRequest()];

coerce 'RepeatedSetMonitoringServiceRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1alpha1::ClusterService::SetMonitoringServiceRequest'->new($_) } @$_ ] };

declare 'MapStringSetMonitoringServiceRequest',
    as HashRef[SetMonitoringServiceRequest()];

declare 'SetAddonsConfigRequest',
    as InstanceOf['Google::Container::V1alpha1::ClusterService::SetAddonsConfigRequest'];

coerce 'SetAddonsConfigRequest',
    from HashRef, via { 'Google::Container::V1alpha1::ClusterService::SetAddonsConfigRequest'->new($_) };

declare 'RepeatedSetAddonsConfigRequest',
    as ArrayRef[SetAddonsConfigRequest()];

coerce 'RepeatedSetAddonsConfigRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1alpha1::ClusterService::SetAddonsConfigRequest'->new($_) } @$_ ] };

declare 'MapStringSetAddonsConfigRequest',
    as HashRef[SetAddonsConfigRequest()];

declare 'SetLocationsRequest',
    as InstanceOf['Google::Container::V1alpha1::ClusterService::SetLocationsRequest'];

coerce 'SetLocationsRequest',
    from HashRef, via { 'Google::Container::V1alpha1::ClusterService::SetLocationsRequest'->new($_) };

declare 'RepeatedSetLocationsRequest',
    as ArrayRef[SetLocationsRequest()];

coerce 'RepeatedSetLocationsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1alpha1::ClusterService::SetLocationsRequest'->new($_) } @$_ ] };

declare 'MapStringSetLocationsRequest',
    as HashRef[SetLocationsRequest()];

declare 'UpdateMasterRequest',
    as InstanceOf['Google::Container::V1alpha1::ClusterService::UpdateMasterRequest'];

coerce 'UpdateMasterRequest',
    from HashRef, via { 'Google::Container::V1alpha1::ClusterService::UpdateMasterRequest'->new($_) };

declare 'RepeatedUpdateMasterRequest',
    as ArrayRef[UpdateMasterRequest()];

coerce 'RepeatedUpdateMasterRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1alpha1::ClusterService::UpdateMasterRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateMasterRequest',
    as HashRef[UpdateMasterRequest()];

declare 'SetMasterAuthRequest',
    as InstanceOf['Google::Container::V1alpha1::ClusterService::SetMasterAuthRequest'];

coerce 'SetMasterAuthRequest',
    from HashRef, via { 'Google::Container::V1alpha1::ClusterService::SetMasterAuthRequest'->new($_) };

declare 'RepeatedSetMasterAuthRequest',
    as ArrayRef[SetMasterAuthRequest()];

coerce 'RepeatedSetMasterAuthRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1alpha1::ClusterService::SetMasterAuthRequest'->new($_) } @$_ ] };

declare 'MapStringSetMasterAuthRequest',
    as HashRef[SetMasterAuthRequest()];

declare 'Action',
    as (Int | Str);

declare 'DeleteClusterRequest',
    as InstanceOf['Google::Container::V1alpha1::ClusterService::DeleteClusterRequest'];

coerce 'DeleteClusterRequest',
    from HashRef, via { 'Google::Container::V1alpha1::ClusterService::DeleteClusterRequest'->new($_) };

declare 'RepeatedDeleteClusterRequest',
    as ArrayRef[DeleteClusterRequest()];

coerce 'RepeatedDeleteClusterRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1alpha1::ClusterService::DeleteClusterRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteClusterRequest',
    as HashRef[DeleteClusterRequest()];

declare 'ListClustersRequest',
    as InstanceOf['Google::Container::V1alpha1::ClusterService::ListClustersRequest'];

coerce 'ListClustersRequest',
    from HashRef, via { 'Google::Container::V1alpha1::ClusterService::ListClustersRequest'->new($_) };

declare 'RepeatedListClustersRequest',
    as ArrayRef[ListClustersRequest()];

coerce 'RepeatedListClustersRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1alpha1::ClusterService::ListClustersRequest'->new($_) } @$_ ] };

declare 'MapStringListClustersRequest',
    as HashRef[ListClustersRequest()];

declare 'ListClustersResponse',
    as InstanceOf['Google::Container::V1alpha1::ClusterService::ListClustersResponse'];

coerce 'ListClustersResponse',
    from HashRef, via { 'Google::Container::V1alpha1::ClusterService::ListClustersResponse'->new($_) };

declare 'RepeatedListClustersResponse',
    as ArrayRef[ListClustersResponse()];

coerce 'RepeatedListClustersResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1alpha1::ClusterService::ListClustersResponse'->new($_) } @$_ ] };

declare 'MapStringListClustersResponse',
    as HashRef[ListClustersResponse()];

declare 'GetOperationRequest',
    as InstanceOf['Google::Container::V1alpha1::ClusterService::GetOperationRequest'];

coerce 'GetOperationRequest',
    from HashRef, via { 'Google::Container::V1alpha1::ClusterService::GetOperationRequest'->new($_) };

declare 'RepeatedGetOperationRequest',
    as ArrayRef[GetOperationRequest()];

coerce 'RepeatedGetOperationRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1alpha1::ClusterService::GetOperationRequest'->new($_) } @$_ ] };

declare 'MapStringGetOperationRequest',
    as HashRef[GetOperationRequest()];

declare 'ListOperationsRequest',
    as InstanceOf['Google::Container::V1alpha1::ClusterService::ListOperationsRequest'];

coerce 'ListOperationsRequest',
    from HashRef, via { 'Google::Container::V1alpha1::ClusterService::ListOperationsRequest'->new($_) };

declare 'RepeatedListOperationsRequest',
    as ArrayRef[ListOperationsRequest()];

coerce 'RepeatedListOperationsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1alpha1::ClusterService::ListOperationsRequest'->new($_) } @$_ ] };

declare 'MapStringListOperationsRequest',
    as HashRef[ListOperationsRequest()];

declare 'CancelOperationRequest',
    as InstanceOf['Google::Container::V1alpha1::ClusterService::CancelOperationRequest'];

coerce 'CancelOperationRequest',
    from HashRef, via { 'Google::Container::V1alpha1::ClusterService::CancelOperationRequest'->new($_) };

declare 'RepeatedCancelOperationRequest',
    as ArrayRef[CancelOperationRequest()];

coerce 'RepeatedCancelOperationRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1alpha1::ClusterService::CancelOperationRequest'->new($_) } @$_ ] };

declare 'MapStringCancelOperationRequest',
    as HashRef[CancelOperationRequest()];

declare 'ListOperationsResponse',
    as InstanceOf['Google::Container::V1alpha1::ClusterService::ListOperationsResponse'];

coerce 'ListOperationsResponse',
    from HashRef, via { 'Google::Container::V1alpha1::ClusterService::ListOperationsResponse'->new($_) };

declare 'RepeatedListOperationsResponse',
    as ArrayRef[ListOperationsResponse()];

coerce 'RepeatedListOperationsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1alpha1::ClusterService::ListOperationsResponse'->new($_) } @$_ ] };

declare 'MapStringListOperationsResponse',
    as HashRef[ListOperationsResponse()];

declare 'GetServerConfigRequest',
    as InstanceOf['Google::Container::V1alpha1::ClusterService::GetServerConfigRequest'];

coerce 'GetServerConfigRequest',
    from HashRef, via { 'Google::Container::V1alpha1::ClusterService::GetServerConfigRequest'->new($_) };

declare 'RepeatedGetServerConfigRequest',
    as ArrayRef[GetServerConfigRequest()];

coerce 'RepeatedGetServerConfigRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1alpha1::ClusterService::GetServerConfigRequest'->new($_) } @$_ ] };

declare 'MapStringGetServerConfigRequest',
    as HashRef[GetServerConfigRequest()];

declare 'ServerConfig',
    as InstanceOf['Google::Container::V1alpha1::ClusterService::ServerConfig'];

coerce 'ServerConfig',
    from HashRef, via { 'Google::Container::V1alpha1::ClusterService::ServerConfig'->new($_) };

declare 'RepeatedServerConfig',
    as ArrayRef[ServerConfig()];

coerce 'RepeatedServerConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1alpha1::ClusterService::ServerConfig'->new($_) } @$_ ] };

declare 'MapStringServerConfig',
    as HashRef[ServerConfig()];

declare 'CreateNodePoolRequest',
    as InstanceOf['Google::Container::V1alpha1::ClusterService::CreateNodePoolRequest'];

coerce 'CreateNodePoolRequest',
    from HashRef, via { 'Google::Container::V1alpha1::ClusterService::CreateNodePoolRequest'->new($_) };

declare 'RepeatedCreateNodePoolRequest',
    as ArrayRef[CreateNodePoolRequest()];

coerce 'RepeatedCreateNodePoolRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1alpha1::ClusterService::CreateNodePoolRequest'->new($_) } @$_ ] };

declare 'MapStringCreateNodePoolRequest',
    as HashRef[CreateNodePoolRequest()];

declare 'DeleteNodePoolRequest',
    as InstanceOf['Google::Container::V1alpha1::ClusterService::DeleteNodePoolRequest'];

coerce 'DeleteNodePoolRequest',
    from HashRef, via { 'Google::Container::V1alpha1::ClusterService::DeleteNodePoolRequest'->new($_) };

declare 'RepeatedDeleteNodePoolRequest',
    as ArrayRef[DeleteNodePoolRequest()];

coerce 'RepeatedDeleteNodePoolRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1alpha1::ClusterService::DeleteNodePoolRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteNodePoolRequest',
    as HashRef[DeleteNodePoolRequest()];

declare 'ListNodePoolsRequest',
    as InstanceOf['Google::Container::V1alpha1::ClusterService::ListNodePoolsRequest'];

coerce 'ListNodePoolsRequest',
    from HashRef, via { 'Google::Container::V1alpha1::ClusterService::ListNodePoolsRequest'->new($_) };

declare 'RepeatedListNodePoolsRequest',
    as ArrayRef[ListNodePoolsRequest()];

coerce 'RepeatedListNodePoolsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1alpha1::ClusterService::ListNodePoolsRequest'->new($_) } @$_ ] };

declare 'MapStringListNodePoolsRequest',
    as HashRef[ListNodePoolsRequest()];

declare 'GetNodePoolRequest',
    as InstanceOf['Google::Container::V1alpha1::ClusterService::GetNodePoolRequest'];

coerce 'GetNodePoolRequest',
    from HashRef, via { 'Google::Container::V1alpha1::ClusterService::GetNodePoolRequest'->new($_) };

declare 'RepeatedGetNodePoolRequest',
    as ArrayRef[GetNodePoolRequest()];

coerce 'RepeatedGetNodePoolRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1alpha1::ClusterService::GetNodePoolRequest'->new($_) } @$_ ] };

declare 'MapStringGetNodePoolRequest',
    as HashRef[GetNodePoolRequest()];

declare 'NodePool',
    as InstanceOf['Google::Container::V1alpha1::ClusterService::NodePool'];

coerce 'NodePool',
    from HashRef, via { 'Google::Container::V1alpha1::ClusterService::NodePool'->new($_) };

declare 'RepeatedNodePool',
    as ArrayRef[NodePool()];

coerce 'RepeatedNodePool',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1alpha1::ClusterService::NodePool'->new($_) } @$_ ] };

declare 'MapStringNodePool',
    as HashRef[NodePool()];

declare 'Status',
    as (Int | Str);

declare 'NodeManagement',
    as InstanceOf['Google::Container::V1alpha1::ClusterService::NodeManagement'];

coerce 'NodeManagement',
    from HashRef, via { 'Google::Container::V1alpha1::ClusterService::NodeManagement'->new($_) };

declare 'RepeatedNodeManagement',
    as ArrayRef[NodeManagement()];

coerce 'RepeatedNodeManagement',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1alpha1::ClusterService::NodeManagement'->new($_) } @$_ ] };

declare 'MapStringNodeManagement',
    as HashRef[NodeManagement()];

declare 'AutoUpgradeOptions',
    as InstanceOf['Google::Container::V1alpha1::ClusterService::AutoUpgradeOptions'];

coerce 'AutoUpgradeOptions',
    from HashRef, via { 'Google::Container::V1alpha1::ClusterService::AutoUpgradeOptions'->new($_) };

declare 'RepeatedAutoUpgradeOptions',
    as ArrayRef[AutoUpgradeOptions()];

coerce 'RepeatedAutoUpgradeOptions',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1alpha1::ClusterService::AutoUpgradeOptions'->new($_) } @$_ ] };

declare 'MapStringAutoUpgradeOptions',
    as HashRef[AutoUpgradeOptions()];

declare 'MaintenancePolicy',
    as InstanceOf['Google::Container::V1alpha1::ClusterService::MaintenancePolicy'];

coerce 'MaintenancePolicy',
    from HashRef, via { 'Google::Container::V1alpha1::ClusterService::MaintenancePolicy'->new($_) };

declare 'RepeatedMaintenancePolicy',
    as ArrayRef[MaintenancePolicy()];

coerce 'RepeatedMaintenancePolicy',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1alpha1::ClusterService::MaintenancePolicy'->new($_) } @$_ ] };

declare 'MapStringMaintenancePolicy',
    as HashRef[MaintenancePolicy()];

declare 'MaintenanceWindow',
    as InstanceOf['Google::Container::V1alpha1::ClusterService::MaintenanceWindow'];

coerce 'MaintenanceWindow',
    from HashRef, via { 'Google::Container::V1alpha1::ClusterService::MaintenanceWindow'->new($_) };

declare 'RepeatedMaintenanceWindow',
    as ArrayRef[MaintenanceWindow()];

coerce 'RepeatedMaintenanceWindow',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1alpha1::ClusterService::MaintenanceWindow'->new($_) } @$_ ] };

declare 'MapStringMaintenanceWindow',
    as HashRef[MaintenanceWindow()];

declare 'DailyMaintenanceWindow',
    as InstanceOf['Google::Container::V1alpha1::ClusterService::DailyMaintenanceWindow'];

coerce 'DailyMaintenanceWindow',
    from HashRef, via { 'Google::Container::V1alpha1::ClusterService::DailyMaintenanceWindow'->new($_) };

declare 'RepeatedDailyMaintenanceWindow',
    as ArrayRef[DailyMaintenanceWindow()];

coerce 'RepeatedDailyMaintenanceWindow',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1alpha1::ClusterService::DailyMaintenanceWindow'->new($_) } @$_ ] };

declare 'MapStringDailyMaintenanceWindow',
    as HashRef[DailyMaintenanceWindow()];

declare 'SetNodePoolManagementRequest',
    as InstanceOf['Google::Container::V1alpha1::ClusterService::SetNodePoolManagementRequest'];

coerce 'SetNodePoolManagementRequest',
    from HashRef, via { 'Google::Container::V1alpha1::ClusterService::SetNodePoolManagementRequest'->new($_) };

declare 'RepeatedSetNodePoolManagementRequest',
    as ArrayRef[SetNodePoolManagementRequest()];

coerce 'RepeatedSetNodePoolManagementRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1alpha1::ClusterService::SetNodePoolManagementRequest'->new($_) } @$_ ] };

declare 'MapStringSetNodePoolManagementRequest',
    as HashRef[SetNodePoolManagementRequest()];

declare 'SetNodePoolSizeRequest',
    as InstanceOf['Google::Container::V1alpha1::ClusterService::SetNodePoolSizeRequest'];

coerce 'SetNodePoolSizeRequest',
    from HashRef, via { 'Google::Container::V1alpha1::ClusterService::SetNodePoolSizeRequest'->new($_) };

declare 'RepeatedSetNodePoolSizeRequest',
    as ArrayRef[SetNodePoolSizeRequest()];

coerce 'RepeatedSetNodePoolSizeRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1alpha1::ClusterService::SetNodePoolSizeRequest'->new($_) } @$_ ] };

declare 'MapStringSetNodePoolSizeRequest',
    as HashRef[SetNodePoolSizeRequest()];

declare 'RollbackNodePoolUpgradeRequest',
    as InstanceOf['Google::Container::V1alpha1::ClusterService::RollbackNodePoolUpgradeRequest'];

coerce 'RollbackNodePoolUpgradeRequest',
    from HashRef, via { 'Google::Container::V1alpha1::ClusterService::RollbackNodePoolUpgradeRequest'->new($_) };

declare 'RepeatedRollbackNodePoolUpgradeRequest',
    as ArrayRef[RollbackNodePoolUpgradeRequest()];

coerce 'RepeatedRollbackNodePoolUpgradeRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1alpha1::ClusterService::RollbackNodePoolUpgradeRequest'->new($_) } @$_ ] };

declare 'MapStringRollbackNodePoolUpgradeRequest',
    as HashRef[RollbackNodePoolUpgradeRequest()];

declare 'ListNodePoolsResponse',
    as InstanceOf['Google::Container::V1alpha1::ClusterService::ListNodePoolsResponse'];

coerce 'ListNodePoolsResponse',
    from HashRef, via { 'Google::Container::V1alpha1::ClusterService::ListNodePoolsResponse'->new($_) };

declare 'RepeatedListNodePoolsResponse',
    as ArrayRef[ListNodePoolsResponse()];

coerce 'RepeatedListNodePoolsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1alpha1::ClusterService::ListNodePoolsResponse'->new($_) } @$_ ] };

declare 'MapStringListNodePoolsResponse',
    as HashRef[ListNodePoolsResponse()];

declare 'NodePoolAutoscaling',
    as InstanceOf['Google::Container::V1alpha1::ClusterService::NodePoolAutoscaling'];

coerce 'NodePoolAutoscaling',
    from HashRef, via { 'Google::Container::V1alpha1::ClusterService::NodePoolAutoscaling'->new($_) };

declare 'RepeatedNodePoolAutoscaling',
    as ArrayRef[NodePoolAutoscaling()];

coerce 'RepeatedNodePoolAutoscaling',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1alpha1::ClusterService::NodePoolAutoscaling'->new($_) } @$_ ] };

declare 'MapStringNodePoolAutoscaling',
    as HashRef[NodePoolAutoscaling()];

declare 'SetLabelsRequest',
    as InstanceOf['Google::Container::V1alpha1::ClusterService::SetLabelsRequest'];

coerce 'SetLabelsRequest',
    from HashRef, via { 'Google::Container::V1alpha1::ClusterService::SetLabelsRequest'->new($_) };

declare 'RepeatedSetLabelsRequest',
    as ArrayRef[SetLabelsRequest()];

coerce 'RepeatedSetLabelsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1alpha1::ClusterService::SetLabelsRequest'->new($_) } @$_ ] };

declare 'MapStringSetLabelsRequest',
    as HashRef[SetLabelsRequest()];

declare 'ResourceLabelsEntry',
    as InstanceOf['Google::Container::V1alpha1::ClusterService::SetLabelsRequest::ResourceLabelsEntry'];

coerce 'ResourceLabelsEntry',
    from HashRef, via { 'Google::Container::V1alpha1::ClusterService::SetLabelsRequest::ResourceLabelsEntry'->new($_) };

declare 'RepeatedResourceLabelsEntry',
    as ArrayRef[ResourceLabelsEntry()];

coerce 'RepeatedResourceLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1alpha1::ClusterService::SetLabelsRequest::ResourceLabelsEntry'->new($_) } @$_ ] };

declare 'MapStringResourceLabelsEntry',
    as HashRef[ResourceLabelsEntry()];

declare 'SetLegacyAbacRequest',
    as InstanceOf['Google::Container::V1alpha1::ClusterService::SetLegacyAbacRequest'];

coerce 'SetLegacyAbacRequest',
    from HashRef, via { 'Google::Container::V1alpha1::ClusterService::SetLegacyAbacRequest'->new($_) };

declare 'RepeatedSetLegacyAbacRequest',
    as ArrayRef[SetLegacyAbacRequest()];

coerce 'RepeatedSetLegacyAbacRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1alpha1::ClusterService::SetLegacyAbacRequest'->new($_) } @$_ ] };

declare 'MapStringSetLegacyAbacRequest',
    as HashRef[SetLegacyAbacRequest()];

declare 'StartIPRotationRequest',
    as InstanceOf['Google::Container::V1alpha1::ClusterService::StartIPRotationRequest'];

coerce 'StartIPRotationRequest',
    from HashRef, via { 'Google::Container::V1alpha1::ClusterService::StartIPRotationRequest'->new($_) };

declare 'RepeatedStartIPRotationRequest',
    as ArrayRef[StartIPRotationRequest()];

coerce 'RepeatedStartIPRotationRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1alpha1::ClusterService::StartIPRotationRequest'->new($_) } @$_ ] };

declare 'MapStringStartIPRotationRequest',
    as HashRef[StartIPRotationRequest()];

declare 'CompleteIPRotationRequest',
    as InstanceOf['Google::Container::V1alpha1::ClusterService::CompleteIPRotationRequest'];

coerce 'CompleteIPRotationRequest',
    from HashRef, via { 'Google::Container::V1alpha1::ClusterService::CompleteIPRotationRequest'->new($_) };

declare 'RepeatedCompleteIPRotationRequest',
    as ArrayRef[CompleteIPRotationRequest()];

coerce 'RepeatedCompleteIPRotationRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1alpha1::ClusterService::CompleteIPRotationRequest'->new($_) } @$_ ] };

declare 'MapStringCompleteIPRotationRequest',
    as HashRef[CompleteIPRotationRequest()];

declare 'AcceleratorConfig',
    as InstanceOf['Google::Container::V1alpha1::ClusterService::AcceleratorConfig'];

coerce 'AcceleratorConfig',
    from HashRef, via { 'Google::Container::V1alpha1::ClusterService::AcceleratorConfig'->new($_) };

declare 'RepeatedAcceleratorConfig',
    as ArrayRef[AcceleratorConfig()];

coerce 'RepeatedAcceleratorConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1alpha1::ClusterService::AcceleratorConfig'->new($_) } @$_ ] };

declare 'MapStringAcceleratorConfig',
    as HashRef[AcceleratorConfig()];

declare 'SetNetworkPolicyRequest',
    as InstanceOf['Google::Container::V1alpha1::ClusterService::SetNetworkPolicyRequest'];

coerce 'SetNetworkPolicyRequest',
    from HashRef, via { 'Google::Container::V1alpha1::ClusterService::SetNetworkPolicyRequest'->new($_) };

declare 'RepeatedSetNetworkPolicyRequest',
    as ArrayRef[SetNetworkPolicyRequest()];

coerce 'RepeatedSetNetworkPolicyRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1alpha1::ClusterService::SetNetworkPolicyRequest'->new($_) } @$_ ] };

declare 'MapStringSetNetworkPolicyRequest',
    as HashRef[SetNetworkPolicyRequest()];

declare 'SetMaintenancePolicyRequest',
    as InstanceOf['Google::Container::V1alpha1::ClusterService::SetMaintenancePolicyRequest'];

coerce 'SetMaintenancePolicyRequest',
    from HashRef, via { 'Google::Container::V1alpha1::ClusterService::SetMaintenancePolicyRequest'->new($_) };

declare 'RepeatedSetMaintenancePolicyRequest',
    as ArrayRef[SetMaintenancePolicyRequest()];

coerce 'RepeatedSetMaintenancePolicyRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1alpha1::ClusterService::SetMaintenancePolicyRequest'->new($_) } @$_ ] };

declare 'MapStringSetMaintenancePolicyRequest',
    as HashRef[SetMaintenancePolicyRequest()];

1;

__END__

=head1 NAME

Google::Container::V1alpha1::ClusterService::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
