package Google::Cloud::Tpu::V2alpha1::CloudTpu::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'GuestAttributes',
    as InstanceOf['Google::Cloud::Tpu::V2alpha1::CloudTpu::GuestAttributes'];

coerce 'GuestAttributes',
    from HashRef, via { 'Google::Cloud::Tpu::V2alpha1::CloudTpu::GuestAttributes'->new($_) };

declare 'RepeatedGuestAttributes',
    as ArrayRef[GuestAttributes()];

coerce 'RepeatedGuestAttributes',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Tpu::V2alpha1::CloudTpu::GuestAttributes'->new($_) } @$_ ] };

declare 'MapStringGuestAttributes',
    as HashRef[GuestAttributes()];

declare 'GuestAttributesValue',
    as InstanceOf['Google::Cloud::Tpu::V2alpha1::CloudTpu::GuestAttributesValue'];

coerce 'GuestAttributesValue',
    from HashRef, via { 'Google::Cloud::Tpu::V2alpha1::CloudTpu::GuestAttributesValue'->new($_) };

declare 'RepeatedGuestAttributesValue',
    as ArrayRef[GuestAttributesValue()];

coerce 'RepeatedGuestAttributesValue',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Tpu::V2alpha1::CloudTpu::GuestAttributesValue'->new($_) } @$_ ] };

declare 'MapStringGuestAttributesValue',
    as HashRef[GuestAttributesValue()];

declare 'GuestAttributesEntry',
    as InstanceOf['Google::Cloud::Tpu::V2alpha1::CloudTpu::GuestAttributesEntry'];

coerce 'GuestAttributesEntry',
    from HashRef, via { 'Google::Cloud::Tpu::V2alpha1::CloudTpu::GuestAttributesEntry'->new($_) };

declare 'RepeatedGuestAttributesEntry',
    as ArrayRef[GuestAttributesEntry()];

coerce 'RepeatedGuestAttributesEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Tpu::V2alpha1::CloudTpu::GuestAttributesEntry'->new($_) } @$_ ] };

declare 'MapStringGuestAttributesEntry',
    as HashRef[GuestAttributesEntry()];

declare 'AttachedDisk',
    as InstanceOf['Google::Cloud::Tpu::V2alpha1::CloudTpu::AttachedDisk'];

coerce 'AttachedDisk',
    from HashRef, via { 'Google::Cloud::Tpu::V2alpha1::CloudTpu::AttachedDisk'->new($_) };

declare 'RepeatedAttachedDisk',
    as ArrayRef[AttachedDisk()];

coerce 'RepeatedAttachedDisk',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Tpu::V2alpha1::CloudTpu::AttachedDisk'->new($_) } @$_ ] };

declare 'MapStringAttachedDisk',
    as HashRef[AttachedDisk()];

declare 'DiskMode',
    as (Int | Str);

declare 'SchedulingConfig',
    as InstanceOf['Google::Cloud::Tpu::V2alpha1::CloudTpu::SchedulingConfig'];

coerce 'SchedulingConfig',
    from HashRef, via { 'Google::Cloud::Tpu::V2alpha1::CloudTpu::SchedulingConfig'->new($_) };

declare 'RepeatedSchedulingConfig',
    as ArrayRef[SchedulingConfig()];

coerce 'RepeatedSchedulingConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Tpu::V2alpha1::CloudTpu::SchedulingConfig'->new($_) } @$_ ] };

declare 'MapStringSchedulingConfig',
    as HashRef[SchedulingConfig()];

declare 'NetworkEndpoint',
    as InstanceOf['Google::Cloud::Tpu::V2alpha1::CloudTpu::NetworkEndpoint'];

coerce 'NetworkEndpoint',
    from HashRef, via { 'Google::Cloud::Tpu::V2alpha1::CloudTpu::NetworkEndpoint'->new($_) };

declare 'RepeatedNetworkEndpoint',
    as ArrayRef[NetworkEndpoint()];

coerce 'RepeatedNetworkEndpoint',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Tpu::V2alpha1::CloudTpu::NetworkEndpoint'->new($_) } @$_ ] };

declare 'MapStringNetworkEndpoint',
    as HashRef[NetworkEndpoint()];

declare 'AccessConfig',
    as InstanceOf['Google::Cloud::Tpu::V2alpha1::CloudTpu::AccessConfig'];

coerce 'AccessConfig',
    from HashRef, via { 'Google::Cloud::Tpu::V2alpha1::CloudTpu::AccessConfig'->new($_) };

declare 'RepeatedAccessConfig',
    as ArrayRef[AccessConfig()];

coerce 'RepeatedAccessConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Tpu::V2alpha1::CloudTpu::AccessConfig'->new($_) } @$_ ] };

declare 'MapStringAccessConfig',
    as HashRef[AccessConfig()];

declare 'NetworkConfig',
    as InstanceOf['Google::Cloud::Tpu::V2alpha1::CloudTpu::NetworkConfig'];

coerce 'NetworkConfig',
    from HashRef, via { 'Google::Cloud::Tpu::V2alpha1::CloudTpu::NetworkConfig'->new($_) };

declare 'RepeatedNetworkConfig',
    as ArrayRef[NetworkConfig()];

coerce 'RepeatedNetworkConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Tpu::V2alpha1::CloudTpu::NetworkConfig'->new($_) } @$_ ] };

declare 'MapStringNetworkConfig',
    as HashRef[NetworkConfig()];

declare 'ServiceAccount',
    as InstanceOf['Google::Cloud::Tpu::V2alpha1::CloudTpu::ServiceAccount'];

coerce 'ServiceAccount',
    from HashRef, via { 'Google::Cloud::Tpu::V2alpha1::CloudTpu::ServiceAccount'->new($_) };

declare 'RepeatedServiceAccount',
    as ArrayRef[ServiceAccount()];

coerce 'RepeatedServiceAccount',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Tpu::V2alpha1::CloudTpu::ServiceAccount'->new($_) } @$_ ] };

declare 'MapStringServiceAccount',
    as HashRef[ServiceAccount()];

declare 'Node',
    as InstanceOf['Google::Cloud::Tpu::V2alpha1::CloudTpu::Node'];

coerce 'Node',
    from HashRef, via { 'Google::Cloud::Tpu::V2alpha1::CloudTpu::Node'->new($_) };

declare 'RepeatedNode',
    as ArrayRef[Node()];

coerce 'RepeatedNode',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Tpu::V2alpha1::CloudTpu::Node'->new($_) } @$_ ] };

declare 'MapStringNode',
    as HashRef[Node()];

declare 'State',
    as (Int | Str);

declare 'Health',
    as (Int | Str);

declare 'ApiVersion',
    as (Int | Str);

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Tpu::V2alpha1::CloudTpu::Node::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Tpu::V2alpha1::CloudTpu::Node::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Tpu::V2alpha1::CloudTpu::Node::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'MetadataEntry',
    as InstanceOf['Google::Cloud::Tpu::V2alpha1::CloudTpu::Node::MetadataEntry'];

coerce 'MetadataEntry',
    from HashRef, via { 'Google::Cloud::Tpu::V2alpha1::CloudTpu::Node::MetadataEntry'->new($_) };

declare 'RepeatedMetadataEntry',
    as ArrayRef[MetadataEntry()];

coerce 'RepeatedMetadataEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Tpu::V2alpha1::CloudTpu::Node::MetadataEntry'->new($_) } @$_ ] };

declare 'MapStringMetadataEntry',
    as HashRef[MetadataEntry()];

declare 'QueuedResource',
    as InstanceOf['Google::Cloud::Tpu::V2alpha1::CloudTpu::QueuedResource'];

coerce 'QueuedResource',
    from HashRef, via { 'Google::Cloud::Tpu::V2alpha1::CloudTpu::QueuedResource'->new($_) };

declare 'RepeatedQueuedResource',
    as ArrayRef[QueuedResource()];

coerce 'RepeatedQueuedResource',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Tpu::V2alpha1::CloudTpu::QueuedResource'->new($_) } @$_ ] };

declare 'MapStringQueuedResource',
    as HashRef[QueuedResource()];

declare 'Tpu',
    as InstanceOf['Google::Cloud::Tpu::V2alpha1::CloudTpu::QueuedResource::Tpu'];

coerce 'Tpu',
    from HashRef, via { 'Google::Cloud::Tpu::V2alpha1::CloudTpu::QueuedResource::Tpu'->new($_) };

declare 'RepeatedTpu',
    as ArrayRef[Tpu()];

coerce 'RepeatedTpu',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Tpu::V2alpha1::CloudTpu::QueuedResource::Tpu'->new($_) } @$_ ] };

declare 'MapStringTpu',
    as HashRef[Tpu()];

declare 'NodeSpec',
    as InstanceOf['Google::Cloud::Tpu::V2alpha1::CloudTpu::QueuedResource::Tpu::NodeSpec'];

coerce 'NodeSpec',
    from HashRef, via { 'Google::Cloud::Tpu::V2alpha1::CloudTpu::QueuedResource::Tpu::NodeSpec'->new($_) };

declare 'RepeatedNodeSpec',
    as ArrayRef[NodeSpec()];

coerce 'RepeatedNodeSpec',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Tpu::V2alpha1::CloudTpu::QueuedResource::Tpu::NodeSpec'->new($_) } @$_ ] };

declare 'MapStringNodeSpec',
    as HashRef[NodeSpec()];

declare 'MultiNodeParams',
    as InstanceOf['Google::Cloud::Tpu::V2alpha1::CloudTpu::QueuedResource::Tpu::NodeSpec::MultiNodeParams'];

coerce 'MultiNodeParams',
    from HashRef, via { 'Google::Cloud::Tpu::V2alpha1::CloudTpu::QueuedResource::Tpu::NodeSpec::MultiNodeParams'->new($_) };

declare 'RepeatedMultiNodeParams',
    as ArrayRef[MultiNodeParams()];

coerce 'RepeatedMultiNodeParams',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Tpu::V2alpha1::CloudTpu::QueuedResource::Tpu::NodeSpec::MultiNodeParams'->new($_) } @$_ ] };

declare 'MapStringMultiNodeParams',
    as HashRef[MultiNodeParams()];

declare 'WorkloadType',
    as (Int | Str);

declare 'BestEffort',
    as InstanceOf['Google::Cloud::Tpu::V2alpha1::CloudTpu::QueuedResource::BestEffort'];

coerce 'BestEffort',
    from HashRef, via { 'Google::Cloud::Tpu::V2alpha1::CloudTpu::QueuedResource::BestEffort'->new($_) };

declare 'RepeatedBestEffort',
    as ArrayRef[BestEffort()];

coerce 'RepeatedBestEffort',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Tpu::V2alpha1::CloudTpu::QueuedResource::BestEffort'->new($_) } @$_ ] };

declare 'MapStringBestEffort',
    as HashRef[BestEffort()];

declare 'Spot',
    as InstanceOf['Google::Cloud::Tpu::V2alpha1::CloudTpu::QueuedResource::Spot'];

coerce 'Spot',
    from HashRef, via { 'Google::Cloud::Tpu::V2alpha1::CloudTpu::QueuedResource::Spot'->new($_) };

declare 'RepeatedSpot',
    as ArrayRef[Spot()];

coerce 'RepeatedSpot',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Tpu::V2alpha1::CloudTpu::QueuedResource::Spot'->new($_) } @$_ ] };

declare 'MapStringSpot',
    as HashRef[Spot()];

declare 'Guaranteed',
    as InstanceOf['Google::Cloud::Tpu::V2alpha1::CloudTpu::QueuedResource::Guaranteed'];

coerce 'Guaranteed',
    from HashRef, via { 'Google::Cloud::Tpu::V2alpha1::CloudTpu::QueuedResource::Guaranteed'->new($_) };

declare 'RepeatedGuaranteed',
    as ArrayRef[Guaranteed()];

coerce 'RepeatedGuaranteed',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Tpu::V2alpha1::CloudTpu::QueuedResource::Guaranteed'->new($_) } @$_ ] };

declare 'MapStringGuaranteed',
    as HashRef[Guaranteed()];

declare 'QueueingPolicy',
    as InstanceOf['Google::Cloud::Tpu::V2alpha1::CloudTpu::QueuedResource::QueueingPolicy'];

coerce 'QueueingPolicy',
    from HashRef, via { 'Google::Cloud::Tpu::V2alpha1::CloudTpu::QueuedResource::QueueingPolicy'->new($_) };

declare 'RepeatedQueueingPolicy',
    as ArrayRef[QueueingPolicy()];

coerce 'RepeatedQueueingPolicy',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Tpu::V2alpha1::CloudTpu::QueuedResource::QueueingPolicy'->new($_) } @$_ ] };

declare 'MapStringQueueingPolicy',
    as HashRef[QueueingPolicy()];

declare 'QueuedResourceState',
    as InstanceOf['Google::Cloud::Tpu::V2alpha1::CloudTpu::QueuedResourceState'];

coerce 'QueuedResourceState',
    from HashRef, via { 'Google::Cloud::Tpu::V2alpha1::CloudTpu::QueuedResourceState'->new($_) };

declare 'RepeatedQueuedResourceState',
    as ArrayRef[QueuedResourceState()];

coerce 'RepeatedQueuedResourceState',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Tpu::V2alpha1::CloudTpu::QueuedResourceState'->new($_) } @$_ ] };

declare 'MapStringQueuedResourceState',
    as HashRef[QueuedResourceState()];

declare 'State',
    as (Int | Str);

declare 'StateInitiator',
    as (Int | Str);

declare 'CreatingData',
    as InstanceOf['Google::Cloud::Tpu::V2alpha1::CloudTpu::QueuedResourceState::CreatingData'];

coerce 'CreatingData',
    from HashRef, via { 'Google::Cloud::Tpu::V2alpha1::CloudTpu::QueuedResourceState::CreatingData'->new($_) };

declare 'RepeatedCreatingData',
    as ArrayRef[CreatingData()];

coerce 'RepeatedCreatingData',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Tpu::V2alpha1::CloudTpu::QueuedResourceState::CreatingData'->new($_) } @$_ ] };

declare 'MapStringCreatingData',
    as HashRef[CreatingData()];

declare 'AcceptedData',
    as InstanceOf['Google::Cloud::Tpu::V2alpha1::CloudTpu::QueuedResourceState::AcceptedData'];

coerce 'AcceptedData',
    from HashRef, via { 'Google::Cloud::Tpu::V2alpha1::CloudTpu::QueuedResourceState::AcceptedData'->new($_) };

declare 'RepeatedAcceptedData',
    as ArrayRef[AcceptedData()];

coerce 'RepeatedAcceptedData',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Tpu::V2alpha1::CloudTpu::QueuedResourceState::AcceptedData'->new($_) } @$_ ] };

declare 'MapStringAcceptedData',
    as HashRef[AcceptedData()];

declare 'ProvisioningData',
    as InstanceOf['Google::Cloud::Tpu::V2alpha1::CloudTpu::QueuedResourceState::ProvisioningData'];

coerce 'ProvisioningData',
    from HashRef, via { 'Google::Cloud::Tpu::V2alpha1::CloudTpu::QueuedResourceState::ProvisioningData'->new($_) };

declare 'RepeatedProvisioningData',
    as ArrayRef[ProvisioningData()];

coerce 'RepeatedProvisioningData',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Tpu::V2alpha1::CloudTpu::QueuedResourceState::ProvisioningData'->new($_) } @$_ ] };

declare 'MapStringProvisioningData',
    as HashRef[ProvisioningData()];

declare 'FailedData',
    as InstanceOf['Google::Cloud::Tpu::V2alpha1::CloudTpu::QueuedResourceState::FailedData'];

coerce 'FailedData',
    from HashRef, via { 'Google::Cloud::Tpu::V2alpha1::CloudTpu::QueuedResourceState::FailedData'->new($_) };

declare 'RepeatedFailedData',
    as ArrayRef[FailedData()];

coerce 'RepeatedFailedData',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Tpu::V2alpha1::CloudTpu::QueuedResourceState::FailedData'->new($_) } @$_ ] };

declare 'MapStringFailedData',
    as HashRef[FailedData()];

declare 'DeletingData',
    as InstanceOf['Google::Cloud::Tpu::V2alpha1::CloudTpu::QueuedResourceState::DeletingData'];

coerce 'DeletingData',
    from HashRef, via { 'Google::Cloud::Tpu::V2alpha1::CloudTpu::QueuedResourceState::DeletingData'->new($_) };

declare 'RepeatedDeletingData',
    as ArrayRef[DeletingData()];

coerce 'RepeatedDeletingData',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Tpu::V2alpha1::CloudTpu::QueuedResourceState::DeletingData'->new($_) } @$_ ] };

declare 'MapStringDeletingData',
    as HashRef[DeletingData()];

declare 'ActiveData',
    as InstanceOf['Google::Cloud::Tpu::V2alpha1::CloudTpu::QueuedResourceState::ActiveData'];

coerce 'ActiveData',
    from HashRef, via { 'Google::Cloud::Tpu::V2alpha1::CloudTpu::QueuedResourceState::ActiveData'->new($_) };

declare 'RepeatedActiveData',
    as ArrayRef[ActiveData()];

coerce 'RepeatedActiveData',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Tpu::V2alpha1::CloudTpu::QueuedResourceState::ActiveData'->new($_) } @$_ ] };

declare 'MapStringActiveData',
    as HashRef[ActiveData()];

declare 'SuspendingData',
    as InstanceOf['Google::Cloud::Tpu::V2alpha1::CloudTpu::QueuedResourceState::SuspendingData'];

coerce 'SuspendingData',
    from HashRef, via { 'Google::Cloud::Tpu::V2alpha1::CloudTpu::QueuedResourceState::SuspendingData'->new($_) };

declare 'RepeatedSuspendingData',
    as ArrayRef[SuspendingData()];

coerce 'RepeatedSuspendingData',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Tpu::V2alpha1::CloudTpu::QueuedResourceState::SuspendingData'->new($_) } @$_ ] };

declare 'MapStringSuspendingData',
    as HashRef[SuspendingData()];

declare 'SuspendedData',
    as InstanceOf['Google::Cloud::Tpu::V2alpha1::CloudTpu::QueuedResourceState::SuspendedData'];

coerce 'SuspendedData',
    from HashRef, via { 'Google::Cloud::Tpu::V2alpha1::CloudTpu::QueuedResourceState::SuspendedData'->new($_) };

declare 'RepeatedSuspendedData',
    as ArrayRef[SuspendedData()];

coerce 'RepeatedSuspendedData',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Tpu::V2alpha1::CloudTpu::QueuedResourceState::SuspendedData'->new($_) } @$_ ] };

declare 'MapStringSuspendedData',
    as HashRef[SuspendedData()];

declare 'ListNodesRequest',
    as InstanceOf['Google::Cloud::Tpu::V2alpha1::CloudTpu::ListNodesRequest'];

coerce 'ListNodesRequest',
    from HashRef, via { 'Google::Cloud::Tpu::V2alpha1::CloudTpu::ListNodesRequest'->new($_) };

declare 'RepeatedListNodesRequest',
    as ArrayRef[ListNodesRequest()];

coerce 'RepeatedListNodesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Tpu::V2alpha1::CloudTpu::ListNodesRequest'->new($_) } @$_ ] };

declare 'MapStringListNodesRequest',
    as HashRef[ListNodesRequest()];

declare 'ListNodesResponse',
    as InstanceOf['Google::Cloud::Tpu::V2alpha1::CloudTpu::ListNodesResponse'];

coerce 'ListNodesResponse',
    from HashRef, via { 'Google::Cloud::Tpu::V2alpha1::CloudTpu::ListNodesResponse'->new($_) };

declare 'RepeatedListNodesResponse',
    as ArrayRef[ListNodesResponse()];

coerce 'RepeatedListNodesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Tpu::V2alpha1::CloudTpu::ListNodesResponse'->new($_) } @$_ ] };

declare 'MapStringListNodesResponse',
    as HashRef[ListNodesResponse()];

declare 'GetNodeRequest',
    as InstanceOf['Google::Cloud::Tpu::V2alpha1::CloudTpu::GetNodeRequest'];

coerce 'GetNodeRequest',
    from HashRef, via { 'Google::Cloud::Tpu::V2alpha1::CloudTpu::GetNodeRequest'->new($_) };

declare 'RepeatedGetNodeRequest',
    as ArrayRef[GetNodeRequest()];

coerce 'RepeatedGetNodeRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Tpu::V2alpha1::CloudTpu::GetNodeRequest'->new($_) } @$_ ] };

declare 'MapStringGetNodeRequest',
    as HashRef[GetNodeRequest()];

declare 'CreateNodeRequest',
    as InstanceOf['Google::Cloud::Tpu::V2alpha1::CloudTpu::CreateNodeRequest'];

coerce 'CreateNodeRequest',
    from HashRef, via { 'Google::Cloud::Tpu::V2alpha1::CloudTpu::CreateNodeRequest'->new($_) };

declare 'RepeatedCreateNodeRequest',
    as ArrayRef[CreateNodeRequest()];

coerce 'RepeatedCreateNodeRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Tpu::V2alpha1::CloudTpu::CreateNodeRequest'->new($_) } @$_ ] };

declare 'MapStringCreateNodeRequest',
    as HashRef[CreateNodeRequest()];

declare 'DeleteNodeRequest',
    as InstanceOf['Google::Cloud::Tpu::V2alpha1::CloudTpu::DeleteNodeRequest'];

coerce 'DeleteNodeRequest',
    from HashRef, via { 'Google::Cloud::Tpu::V2alpha1::CloudTpu::DeleteNodeRequest'->new($_) };

declare 'RepeatedDeleteNodeRequest',
    as ArrayRef[DeleteNodeRequest()];

coerce 'RepeatedDeleteNodeRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Tpu::V2alpha1::CloudTpu::DeleteNodeRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteNodeRequest',
    as HashRef[DeleteNodeRequest()];

declare 'StopNodeRequest',
    as InstanceOf['Google::Cloud::Tpu::V2alpha1::CloudTpu::StopNodeRequest'];

coerce 'StopNodeRequest',
    from HashRef, via { 'Google::Cloud::Tpu::V2alpha1::CloudTpu::StopNodeRequest'->new($_) };

declare 'RepeatedStopNodeRequest',
    as ArrayRef[StopNodeRequest()];

coerce 'RepeatedStopNodeRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Tpu::V2alpha1::CloudTpu::StopNodeRequest'->new($_) } @$_ ] };

declare 'MapStringStopNodeRequest',
    as HashRef[StopNodeRequest()];

declare 'StartNodeRequest',
    as InstanceOf['Google::Cloud::Tpu::V2alpha1::CloudTpu::StartNodeRequest'];

coerce 'StartNodeRequest',
    from HashRef, via { 'Google::Cloud::Tpu::V2alpha1::CloudTpu::StartNodeRequest'->new($_) };

declare 'RepeatedStartNodeRequest',
    as ArrayRef[StartNodeRequest()];

coerce 'RepeatedStartNodeRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Tpu::V2alpha1::CloudTpu::StartNodeRequest'->new($_) } @$_ ] };

declare 'MapStringStartNodeRequest',
    as HashRef[StartNodeRequest()];

declare 'UpdateNodeRequest',
    as InstanceOf['Google::Cloud::Tpu::V2alpha1::CloudTpu::UpdateNodeRequest'];

coerce 'UpdateNodeRequest',
    from HashRef, via { 'Google::Cloud::Tpu::V2alpha1::CloudTpu::UpdateNodeRequest'->new($_) };

declare 'RepeatedUpdateNodeRequest',
    as ArrayRef[UpdateNodeRequest()];

coerce 'RepeatedUpdateNodeRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Tpu::V2alpha1::CloudTpu::UpdateNodeRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateNodeRequest',
    as HashRef[UpdateNodeRequest()];

declare 'ListQueuedResourcesRequest',
    as InstanceOf['Google::Cloud::Tpu::V2alpha1::CloudTpu::ListQueuedResourcesRequest'];

coerce 'ListQueuedResourcesRequest',
    from HashRef, via { 'Google::Cloud::Tpu::V2alpha1::CloudTpu::ListQueuedResourcesRequest'->new($_) };

declare 'RepeatedListQueuedResourcesRequest',
    as ArrayRef[ListQueuedResourcesRequest()];

coerce 'RepeatedListQueuedResourcesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Tpu::V2alpha1::CloudTpu::ListQueuedResourcesRequest'->new($_) } @$_ ] };

declare 'MapStringListQueuedResourcesRequest',
    as HashRef[ListQueuedResourcesRequest()];

declare 'ListQueuedResourcesResponse',
    as InstanceOf['Google::Cloud::Tpu::V2alpha1::CloudTpu::ListQueuedResourcesResponse'];

coerce 'ListQueuedResourcesResponse',
    from HashRef, via { 'Google::Cloud::Tpu::V2alpha1::CloudTpu::ListQueuedResourcesResponse'->new($_) };

declare 'RepeatedListQueuedResourcesResponse',
    as ArrayRef[ListQueuedResourcesResponse()];

coerce 'RepeatedListQueuedResourcesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Tpu::V2alpha1::CloudTpu::ListQueuedResourcesResponse'->new($_) } @$_ ] };

declare 'MapStringListQueuedResourcesResponse',
    as HashRef[ListQueuedResourcesResponse()];

declare 'GetQueuedResourceRequest',
    as InstanceOf['Google::Cloud::Tpu::V2alpha1::CloudTpu::GetQueuedResourceRequest'];

coerce 'GetQueuedResourceRequest',
    from HashRef, via { 'Google::Cloud::Tpu::V2alpha1::CloudTpu::GetQueuedResourceRequest'->new($_) };

declare 'RepeatedGetQueuedResourceRequest',
    as ArrayRef[GetQueuedResourceRequest()];

coerce 'RepeatedGetQueuedResourceRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Tpu::V2alpha1::CloudTpu::GetQueuedResourceRequest'->new($_) } @$_ ] };

declare 'MapStringGetQueuedResourceRequest',
    as HashRef[GetQueuedResourceRequest()];

declare 'CreateQueuedResourceRequest',
    as InstanceOf['Google::Cloud::Tpu::V2alpha1::CloudTpu::CreateQueuedResourceRequest'];

coerce 'CreateQueuedResourceRequest',
    from HashRef, via { 'Google::Cloud::Tpu::V2alpha1::CloudTpu::CreateQueuedResourceRequest'->new($_) };

declare 'RepeatedCreateQueuedResourceRequest',
    as ArrayRef[CreateQueuedResourceRequest()];

coerce 'RepeatedCreateQueuedResourceRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Tpu::V2alpha1::CloudTpu::CreateQueuedResourceRequest'->new($_) } @$_ ] };

declare 'MapStringCreateQueuedResourceRequest',
    as HashRef[CreateQueuedResourceRequest()];

declare 'DeleteQueuedResourceRequest',
    as InstanceOf['Google::Cloud::Tpu::V2alpha1::CloudTpu::DeleteQueuedResourceRequest'];

coerce 'DeleteQueuedResourceRequest',
    from HashRef, via { 'Google::Cloud::Tpu::V2alpha1::CloudTpu::DeleteQueuedResourceRequest'->new($_) };

declare 'RepeatedDeleteQueuedResourceRequest',
    as ArrayRef[DeleteQueuedResourceRequest()];

coerce 'RepeatedDeleteQueuedResourceRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Tpu::V2alpha1::CloudTpu::DeleteQueuedResourceRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteQueuedResourceRequest',
    as HashRef[DeleteQueuedResourceRequest()];

declare 'ResetQueuedResourceRequest',
    as InstanceOf['Google::Cloud::Tpu::V2alpha1::CloudTpu::ResetQueuedResourceRequest'];

coerce 'ResetQueuedResourceRequest',
    from HashRef, via { 'Google::Cloud::Tpu::V2alpha1::CloudTpu::ResetQueuedResourceRequest'->new($_) };

declare 'RepeatedResetQueuedResourceRequest',
    as ArrayRef[ResetQueuedResourceRequest()];

coerce 'RepeatedResetQueuedResourceRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Tpu::V2alpha1::CloudTpu::ResetQueuedResourceRequest'->new($_) } @$_ ] };

declare 'MapStringResetQueuedResourceRequest',
    as HashRef[ResetQueuedResourceRequest()];

declare 'ServiceIdentity',
    as InstanceOf['Google::Cloud::Tpu::V2alpha1::CloudTpu::ServiceIdentity'];

coerce 'ServiceIdentity',
    from HashRef, via { 'Google::Cloud::Tpu::V2alpha1::CloudTpu::ServiceIdentity'->new($_) };

declare 'RepeatedServiceIdentity',
    as ArrayRef[ServiceIdentity()];

coerce 'RepeatedServiceIdentity',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Tpu::V2alpha1::CloudTpu::ServiceIdentity'->new($_) } @$_ ] };

declare 'MapStringServiceIdentity',
    as HashRef[ServiceIdentity()];

declare 'GenerateServiceIdentityRequest',
    as InstanceOf['Google::Cloud::Tpu::V2alpha1::CloudTpu::GenerateServiceIdentityRequest'];

coerce 'GenerateServiceIdentityRequest',
    from HashRef, via { 'Google::Cloud::Tpu::V2alpha1::CloudTpu::GenerateServiceIdentityRequest'->new($_) };

declare 'RepeatedGenerateServiceIdentityRequest',
    as ArrayRef[GenerateServiceIdentityRequest()];

coerce 'RepeatedGenerateServiceIdentityRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Tpu::V2alpha1::CloudTpu::GenerateServiceIdentityRequest'->new($_) } @$_ ] };

declare 'MapStringGenerateServiceIdentityRequest',
    as HashRef[GenerateServiceIdentityRequest()];

declare 'GenerateServiceIdentityResponse',
    as InstanceOf['Google::Cloud::Tpu::V2alpha1::CloudTpu::GenerateServiceIdentityResponse'];

coerce 'GenerateServiceIdentityResponse',
    from HashRef, via { 'Google::Cloud::Tpu::V2alpha1::CloudTpu::GenerateServiceIdentityResponse'->new($_) };

declare 'RepeatedGenerateServiceIdentityResponse',
    as ArrayRef[GenerateServiceIdentityResponse()];

coerce 'RepeatedGenerateServiceIdentityResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Tpu::V2alpha1::CloudTpu::GenerateServiceIdentityResponse'->new($_) } @$_ ] };

declare 'MapStringGenerateServiceIdentityResponse',
    as HashRef[GenerateServiceIdentityResponse()];

declare 'AcceleratorType',
    as InstanceOf['Google::Cloud::Tpu::V2alpha1::CloudTpu::AcceleratorType'];

coerce 'AcceleratorType',
    from HashRef, via { 'Google::Cloud::Tpu::V2alpha1::CloudTpu::AcceleratorType'->new($_) };

declare 'RepeatedAcceleratorType',
    as ArrayRef[AcceleratorType()];

coerce 'RepeatedAcceleratorType',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Tpu::V2alpha1::CloudTpu::AcceleratorType'->new($_) } @$_ ] };

declare 'MapStringAcceleratorType',
    as HashRef[AcceleratorType()];

declare 'GetAcceleratorTypeRequest',
    as InstanceOf['Google::Cloud::Tpu::V2alpha1::CloudTpu::GetAcceleratorTypeRequest'];

coerce 'GetAcceleratorTypeRequest',
    from HashRef, via { 'Google::Cloud::Tpu::V2alpha1::CloudTpu::GetAcceleratorTypeRequest'->new($_) };

declare 'RepeatedGetAcceleratorTypeRequest',
    as ArrayRef[GetAcceleratorTypeRequest()];

coerce 'RepeatedGetAcceleratorTypeRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Tpu::V2alpha1::CloudTpu::GetAcceleratorTypeRequest'->new($_) } @$_ ] };

declare 'MapStringGetAcceleratorTypeRequest',
    as HashRef[GetAcceleratorTypeRequest()];

declare 'ListAcceleratorTypesRequest',
    as InstanceOf['Google::Cloud::Tpu::V2alpha1::CloudTpu::ListAcceleratorTypesRequest'];

coerce 'ListAcceleratorTypesRequest',
    from HashRef, via { 'Google::Cloud::Tpu::V2alpha1::CloudTpu::ListAcceleratorTypesRequest'->new($_) };

declare 'RepeatedListAcceleratorTypesRequest',
    as ArrayRef[ListAcceleratorTypesRequest()];

coerce 'RepeatedListAcceleratorTypesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Tpu::V2alpha1::CloudTpu::ListAcceleratorTypesRequest'->new($_) } @$_ ] };

declare 'MapStringListAcceleratorTypesRequest',
    as HashRef[ListAcceleratorTypesRequest()];

declare 'ListAcceleratorTypesResponse',
    as InstanceOf['Google::Cloud::Tpu::V2alpha1::CloudTpu::ListAcceleratorTypesResponse'];

coerce 'ListAcceleratorTypesResponse',
    from HashRef, via { 'Google::Cloud::Tpu::V2alpha1::CloudTpu::ListAcceleratorTypesResponse'->new($_) };

declare 'RepeatedListAcceleratorTypesResponse',
    as ArrayRef[ListAcceleratorTypesResponse()];

coerce 'RepeatedListAcceleratorTypesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Tpu::V2alpha1::CloudTpu::ListAcceleratorTypesResponse'->new($_) } @$_ ] };

declare 'MapStringListAcceleratorTypesResponse',
    as HashRef[ListAcceleratorTypesResponse()];

declare 'RuntimeVersion',
    as InstanceOf['Google::Cloud::Tpu::V2alpha1::CloudTpu::RuntimeVersion'];

coerce 'RuntimeVersion',
    from HashRef, via { 'Google::Cloud::Tpu::V2alpha1::CloudTpu::RuntimeVersion'->new($_) };

declare 'RepeatedRuntimeVersion',
    as ArrayRef[RuntimeVersion()];

coerce 'RepeatedRuntimeVersion',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Tpu::V2alpha1::CloudTpu::RuntimeVersion'->new($_) } @$_ ] };

declare 'MapStringRuntimeVersion',
    as HashRef[RuntimeVersion()];

declare 'GetRuntimeVersionRequest',
    as InstanceOf['Google::Cloud::Tpu::V2alpha1::CloudTpu::GetRuntimeVersionRequest'];

coerce 'GetRuntimeVersionRequest',
    from HashRef, via { 'Google::Cloud::Tpu::V2alpha1::CloudTpu::GetRuntimeVersionRequest'->new($_) };

declare 'RepeatedGetRuntimeVersionRequest',
    as ArrayRef[GetRuntimeVersionRequest()];

coerce 'RepeatedGetRuntimeVersionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Tpu::V2alpha1::CloudTpu::GetRuntimeVersionRequest'->new($_) } @$_ ] };

declare 'MapStringGetRuntimeVersionRequest',
    as HashRef[GetRuntimeVersionRequest()];

declare 'ListRuntimeVersionsRequest',
    as InstanceOf['Google::Cloud::Tpu::V2alpha1::CloudTpu::ListRuntimeVersionsRequest'];

coerce 'ListRuntimeVersionsRequest',
    from HashRef, via { 'Google::Cloud::Tpu::V2alpha1::CloudTpu::ListRuntimeVersionsRequest'->new($_) };

declare 'RepeatedListRuntimeVersionsRequest',
    as ArrayRef[ListRuntimeVersionsRequest()];

coerce 'RepeatedListRuntimeVersionsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Tpu::V2alpha1::CloudTpu::ListRuntimeVersionsRequest'->new($_) } @$_ ] };

declare 'MapStringListRuntimeVersionsRequest',
    as HashRef[ListRuntimeVersionsRequest()];

declare 'ListRuntimeVersionsResponse',
    as InstanceOf['Google::Cloud::Tpu::V2alpha1::CloudTpu::ListRuntimeVersionsResponse'];

coerce 'ListRuntimeVersionsResponse',
    from HashRef, via { 'Google::Cloud::Tpu::V2alpha1::CloudTpu::ListRuntimeVersionsResponse'->new($_) };

declare 'RepeatedListRuntimeVersionsResponse',
    as ArrayRef[ListRuntimeVersionsResponse()];

coerce 'RepeatedListRuntimeVersionsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Tpu::V2alpha1::CloudTpu::ListRuntimeVersionsResponse'->new($_) } @$_ ] };

declare 'MapStringListRuntimeVersionsResponse',
    as HashRef[ListRuntimeVersionsResponse()];

declare 'OperationMetadata',
    as InstanceOf['Google::Cloud::Tpu::V2alpha1::CloudTpu::OperationMetadata'];

coerce 'OperationMetadata',
    from HashRef, via { 'Google::Cloud::Tpu::V2alpha1::CloudTpu::OperationMetadata'->new($_) };

declare 'RepeatedOperationMetadata',
    as ArrayRef[OperationMetadata()];

coerce 'RepeatedOperationMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Tpu::V2alpha1::CloudTpu::OperationMetadata'->new($_) } @$_ ] };

declare 'MapStringOperationMetadata',
    as HashRef[OperationMetadata()];

declare 'Symptom',
    as InstanceOf['Google::Cloud::Tpu::V2alpha1::CloudTpu::Symptom'];

coerce 'Symptom',
    from HashRef, via { 'Google::Cloud::Tpu::V2alpha1::CloudTpu::Symptom'->new($_) };

declare 'RepeatedSymptom',
    as ArrayRef[Symptom()];

coerce 'RepeatedSymptom',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Tpu::V2alpha1::CloudTpu::Symptom'->new($_) } @$_ ] };

declare 'MapStringSymptom',
    as HashRef[Symptom()];

declare 'SymptomType',
    as (Int | Str);

declare 'GetGuestAttributesRequest',
    as InstanceOf['Google::Cloud::Tpu::V2alpha1::CloudTpu::GetGuestAttributesRequest'];

coerce 'GetGuestAttributesRequest',
    from HashRef, via { 'Google::Cloud::Tpu::V2alpha1::CloudTpu::GetGuestAttributesRequest'->new($_) };

declare 'RepeatedGetGuestAttributesRequest',
    as ArrayRef[GetGuestAttributesRequest()];

coerce 'RepeatedGetGuestAttributesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Tpu::V2alpha1::CloudTpu::GetGuestAttributesRequest'->new($_) } @$_ ] };

declare 'MapStringGetGuestAttributesRequest',
    as HashRef[GetGuestAttributesRequest()];

declare 'GetGuestAttributesResponse',
    as InstanceOf['Google::Cloud::Tpu::V2alpha1::CloudTpu::GetGuestAttributesResponse'];

coerce 'GetGuestAttributesResponse',
    from HashRef, via { 'Google::Cloud::Tpu::V2alpha1::CloudTpu::GetGuestAttributesResponse'->new($_) };

declare 'RepeatedGetGuestAttributesResponse',
    as ArrayRef[GetGuestAttributesResponse()];

coerce 'RepeatedGetGuestAttributesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Tpu::V2alpha1::CloudTpu::GetGuestAttributesResponse'->new($_) } @$_ ] };

declare 'MapStringGetGuestAttributesResponse',
    as HashRef[GetGuestAttributesResponse()];

declare 'SimulateMaintenanceEventRequest',
    as InstanceOf['Google::Cloud::Tpu::V2alpha1::CloudTpu::SimulateMaintenanceEventRequest'];

coerce 'SimulateMaintenanceEventRequest',
    from HashRef, via { 'Google::Cloud::Tpu::V2alpha1::CloudTpu::SimulateMaintenanceEventRequest'->new($_) };

declare 'RepeatedSimulateMaintenanceEventRequest',
    as ArrayRef[SimulateMaintenanceEventRequest()];

coerce 'RepeatedSimulateMaintenanceEventRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Tpu::V2alpha1::CloudTpu::SimulateMaintenanceEventRequest'->new($_) } @$_ ] };

declare 'MapStringSimulateMaintenanceEventRequest',
    as HashRef[SimulateMaintenanceEventRequest()];

declare 'PerformMaintenanceRequest',
    as InstanceOf['Google::Cloud::Tpu::V2alpha1::CloudTpu::PerformMaintenanceRequest'];

coerce 'PerformMaintenanceRequest',
    from HashRef, via { 'Google::Cloud::Tpu::V2alpha1::CloudTpu::PerformMaintenanceRequest'->new($_) };

declare 'RepeatedPerformMaintenanceRequest',
    as ArrayRef[PerformMaintenanceRequest()];

coerce 'RepeatedPerformMaintenanceRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Tpu::V2alpha1::CloudTpu::PerformMaintenanceRequest'->new($_) } @$_ ] };

declare 'MapStringPerformMaintenanceRequest',
    as HashRef[PerformMaintenanceRequest()];

declare 'PerformMaintenanceQueuedResourceRequest',
    as InstanceOf['Google::Cloud::Tpu::V2alpha1::CloudTpu::PerformMaintenanceQueuedResourceRequest'];

coerce 'PerformMaintenanceQueuedResourceRequest',
    from HashRef, via { 'Google::Cloud::Tpu::V2alpha1::CloudTpu::PerformMaintenanceQueuedResourceRequest'->new($_) };

declare 'RepeatedPerformMaintenanceQueuedResourceRequest',
    as ArrayRef[PerformMaintenanceQueuedResourceRequest()];

coerce 'RepeatedPerformMaintenanceQueuedResourceRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Tpu::V2alpha1::CloudTpu::PerformMaintenanceQueuedResourceRequest'->new($_) } @$_ ] };

declare 'MapStringPerformMaintenanceQueuedResourceRequest',
    as HashRef[PerformMaintenanceQueuedResourceRequest()];

declare 'Reservation',
    as InstanceOf['Google::Cloud::Tpu::V2alpha1::CloudTpu::Reservation'];

coerce 'Reservation',
    from HashRef, via { 'Google::Cloud::Tpu::V2alpha1::CloudTpu::Reservation'->new($_) };

declare 'RepeatedReservation',
    as ArrayRef[Reservation()];

coerce 'RepeatedReservation',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Tpu::V2alpha1::CloudTpu::Reservation'->new($_) } @$_ ] };

declare 'MapStringReservation',
    as HashRef[Reservation()];

declare 'State',
    as (Int | Str);

declare 'Standard',
    as InstanceOf['Google::Cloud::Tpu::V2alpha1::CloudTpu::Reservation::Standard'];

coerce 'Standard',
    from HashRef, via { 'Google::Cloud::Tpu::V2alpha1::CloudTpu::Reservation::Standard'->new($_) };

declare 'RepeatedStandard',
    as ArrayRef[Standard()];

coerce 'RepeatedStandard',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Tpu::V2alpha1::CloudTpu::Reservation::Standard'->new($_) } @$_ ] };

declare 'MapStringStandard',
    as HashRef[Standard()];

declare 'CapacityUnits',
    as (Int | Str);

declare 'Usage',
    as InstanceOf['Google::Cloud::Tpu::V2alpha1::CloudTpu::Reservation::Standard::Usage'];

coerce 'Usage',
    from HashRef, via { 'Google::Cloud::Tpu::V2alpha1::CloudTpu::Reservation::Standard::Usage'->new($_) };

declare 'RepeatedUsage',
    as ArrayRef[Usage()];

coerce 'RepeatedUsage',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Tpu::V2alpha1::CloudTpu::Reservation::Standard::Usage'->new($_) } @$_ ] };

declare 'MapStringUsage',
    as HashRef[Usage()];

declare 'ListReservationsRequest',
    as InstanceOf['Google::Cloud::Tpu::V2alpha1::CloudTpu::ListReservationsRequest'];

coerce 'ListReservationsRequest',
    from HashRef, via { 'Google::Cloud::Tpu::V2alpha1::CloudTpu::ListReservationsRequest'->new($_) };

declare 'RepeatedListReservationsRequest',
    as ArrayRef[ListReservationsRequest()];

coerce 'RepeatedListReservationsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Tpu::V2alpha1::CloudTpu::ListReservationsRequest'->new($_) } @$_ ] };

declare 'MapStringListReservationsRequest',
    as HashRef[ListReservationsRequest()];

declare 'ListReservationsResponse',
    as InstanceOf['Google::Cloud::Tpu::V2alpha1::CloudTpu::ListReservationsResponse'];

coerce 'ListReservationsResponse',
    from HashRef, via { 'Google::Cloud::Tpu::V2alpha1::CloudTpu::ListReservationsResponse'->new($_) };

declare 'RepeatedListReservationsResponse',
    as ArrayRef[ListReservationsResponse()];

coerce 'RepeatedListReservationsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Tpu::V2alpha1::CloudTpu::ListReservationsResponse'->new($_) } @$_ ] };

declare 'MapStringListReservationsResponse',
    as HashRef[ListReservationsResponse()];

declare 'AcceleratorConfig',
    as InstanceOf['Google::Cloud::Tpu::V2alpha1::CloudTpu::AcceleratorConfig'];

coerce 'AcceleratorConfig',
    from HashRef, via { 'Google::Cloud::Tpu::V2alpha1::CloudTpu::AcceleratorConfig'->new($_) };

declare 'RepeatedAcceleratorConfig',
    as ArrayRef[AcceleratorConfig()];

coerce 'RepeatedAcceleratorConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Tpu::V2alpha1::CloudTpu::AcceleratorConfig'->new($_) } @$_ ] };

declare 'MapStringAcceleratorConfig',
    as HashRef[AcceleratorConfig()];

declare 'Type',
    as (Int | Str);

declare 'ShieldedInstanceConfig',
    as InstanceOf['Google::Cloud::Tpu::V2alpha1::CloudTpu::ShieldedInstanceConfig'];

coerce 'ShieldedInstanceConfig',
    from HashRef, via { 'Google::Cloud::Tpu::V2alpha1::CloudTpu::ShieldedInstanceConfig'->new($_) };

declare 'RepeatedShieldedInstanceConfig',
    as ArrayRef[ShieldedInstanceConfig()];

coerce 'RepeatedShieldedInstanceConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Tpu::V2alpha1::CloudTpu::ShieldedInstanceConfig'->new($_) } @$_ ] };

declare 'MapStringShieldedInstanceConfig',
    as HashRef[ShieldedInstanceConfig()];

declare 'BootDiskConfig',
    as InstanceOf['Google::Cloud::Tpu::V2alpha1::CloudTpu::BootDiskConfig'];

coerce 'BootDiskConfig',
    from HashRef, via { 'Google::Cloud::Tpu::V2alpha1::CloudTpu::BootDiskConfig'->new($_) };

declare 'RepeatedBootDiskConfig',
    as ArrayRef[BootDiskConfig()];

coerce 'RepeatedBootDiskConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Tpu::V2alpha1::CloudTpu::BootDiskConfig'->new($_) } @$_ ] };

declare 'MapStringBootDiskConfig',
    as HashRef[BootDiskConfig()];

declare 'CustomerEncryptionKey',
    as InstanceOf['Google::Cloud::Tpu::V2alpha1::CloudTpu::CustomerEncryptionKey'];

coerce 'CustomerEncryptionKey',
    from HashRef, via { 'Google::Cloud::Tpu::V2alpha1::CloudTpu::CustomerEncryptionKey'->new($_) };

declare 'RepeatedCustomerEncryptionKey',
    as ArrayRef[CustomerEncryptionKey()];

coerce 'RepeatedCustomerEncryptionKey',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Tpu::V2alpha1::CloudTpu::CustomerEncryptionKey'->new($_) } @$_ ] };

declare 'MapStringCustomerEncryptionKey',
    as HashRef[CustomerEncryptionKey()];

declare 'UpcomingMaintenance',
    as InstanceOf['Google::Cloud::Tpu::V2alpha1::CloudTpu::UpcomingMaintenance'];

coerce 'UpcomingMaintenance',
    from HashRef, via { 'Google::Cloud::Tpu::V2alpha1::CloudTpu::UpcomingMaintenance'->new($_) };

declare 'RepeatedUpcomingMaintenance',
    as ArrayRef[UpcomingMaintenance()];

coerce 'RepeatedUpcomingMaintenance',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Tpu::V2alpha1::CloudTpu::UpcomingMaintenance'->new($_) } @$_ ] };

declare 'MapStringUpcomingMaintenance',
    as HashRef[UpcomingMaintenance()];

declare 'MaintenanceType',
    as (Int | Str);

declare 'MaintenanceStatus',
    as (Int | Str);

1;

__END__

=head1 NAME

Google::Cloud::Tpu::V2alpha1::CloudTpu::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
