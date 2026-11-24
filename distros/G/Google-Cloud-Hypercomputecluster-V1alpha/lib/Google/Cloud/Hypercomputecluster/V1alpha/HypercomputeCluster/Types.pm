package Google::Cloud::Hypercomputecluster::V1alpha::HypercomputeCluster::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Cluster',
    as InstanceOf['Google::Cloud::Hypercomputecluster::V1alpha::HypercomputeCluster::Cluster'];

coerce 'Cluster',
    from HashRef, via { 'Google::Cloud::Hypercomputecluster::V1alpha::HypercomputeCluster::Cluster'->new($_) };

declare 'RepeatedCluster',
    as ArrayRef[Cluster()];

coerce 'RepeatedCluster',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Hypercomputecluster::V1alpha::HypercomputeCluster::Cluster'->new($_) } @$_ ] };

declare 'MapStringCluster',
    as HashRef[Cluster()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Hypercomputecluster::V1alpha::HypercomputeCluster::Cluster::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Hypercomputecluster::V1alpha::HypercomputeCluster::Cluster::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Hypercomputecluster::V1alpha::HypercomputeCluster::Cluster::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'NetworkResourcesEntry',
    as InstanceOf['Google::Cloud::Hypercomputecluster::V1alpha::HypercomputeCluster::Cluster::NetworkResourcesEntry'];

coerce 'NetworkResourcesEntry',
    from HashRef, via { 'Google::Cloud::Hypercomputecluster::V1alpha::HypercomputeCluster::Cluster::NetworkResourcesEntry'->new($_) };

declare 'RepeatedNetworkResourcesEntry',
    as ArrayRef[NetworkResourcesEntry()];

coerce 'RepeatedNetworkResourcesEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Hypercomputecluster::V1alpha::HypercomputeCluster::Cluster::NetworkResourcesEntry'->new($_) } @$_ ] };

declare 'MapStringNetworkResourcesEntry',
    as HashRef[NetworkResourcesEntry()];

declare 'StorageResourcesEntry',
    as InstanceOf['Google::Cloud::Hypercomputecluster::V1alpha::HypercomputeCluster::Cluster::StorageResourcesEntry'];

coerce 'StorageResourcesEntry',
    from HashRef, via { 'Google::Cloud::Hypercomputecluster::V1alpha::HypercomputeCluster::Cluster::StorageResourcesEntry'->new($_) };

declare 'RepeatedStorageResourcesEntry',
    as ArrayRef[StorageResourcesEntry()];

coerce 'RepeatedStorageResourcesEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Hypercomputecluster::V1alpha::HypercomputeCluster::Cluster::StorageResourcesEntry'->new($_) } @$_ ] };

declare 'MapStringStorageResourcesEntry',
    as HashRef[StorageResourcesEntry()];

declare 'ComputeResourcesEntry',
    as InstanceOf['Google::Cloud::Hypercomputecluster::V1alpha::HypercomputeCluster::Cluster::ComputeResourcesEntry'];

coerce 'ComputeResourcesEntry',
    from HashRef, via { 'Google::Cloud::Hypercomputecluster::V1alpha::HypercomputeCluster::Cluster::ComputeResourcesEntry'->new($_) };

declare 'RepeatedComputeResourcesEntry',
    as ArrayRef[ComputeResourcesEntry()];

coerce 'RepeatedComputeResourcesEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Hypercomputecluster::V1alpha::HypercomputeCluster::Cluster::ComputeResourcesEntry'->new($_) } @$_ ] };

declare 'MapStringComputeResourcesEntry',
    as HashRef[ComputeResourcesEntry()];

declare 'ListClustersRequest',
    as InstanceOf['Google::Cloud::Hypercomputecluster::V1alpha::HypercomputeCluster::ListClustersRequest'];

coerce 'ListClustersRequest',
    from HashRef, via { 'Google::Cloud::Hypercomputecluster::V1alpha::HypercomputeCluster::ListClustersRequest'->new($_) };

declare 'RepeatedListClustersRequest',
    as ArrayRef[ListClustersRequest()];

coerce 'RepeatedListClustersRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Hypercomputecluster::V1alpha::HypercomputeCluster::ListClustersRequest'->new($_) } @$_ ] };

declare 'MapStringListClustersRequest',
    as HashRef[ListClustersRequest()];

declare 'ListClustersResponse',
    as InstanceOf['Google::Cloud::Hypercomputecluster::V1alpha::HypercomputeCluster::ListClustersResponse'];

coerce 'ListClustersResponse',
    from HashRef, via { 'Google::Cloud::Hypercomputecluster::V1alpha::HypercomputeCluster::ListClustersResponse'->new($_) };

declare 'RepeatedListClustersResponse',
    as ArrayRef[ListClustersResponse()];

coerce 'RepeatedListClustersResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Hypercomputecluster::V1alpha::HypercomputeCluster::ListClustersResponse'->new($_) } @$_ ] };

declare 'MapStringListClustersResponse',
    as HashRef[ListClustersResponse()];

declare 'GetClusterRequest',
    as InstanceOf['Google::Cloud::Hypercomputecluster::V1alpha::HypercomputeCluster::GetClusterRequest'];

coerce 'GetClusterRequest',
    from HashRef, via { 'Google::Cloud::Hypercomputecluster::V1alpha::HypercomputeCluster::GetClusterRequest'->new($_) };

declare 'RepeatedGetClusterRequest',
    as ArrayRef[GetClusterRequest()];

coerce 'RepeatedGetClusterRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Hypercomputecluster::V1alpha::HypercomputeCluster::GetClusterRequest'->new($_) } @$_ ] };

declare 'MapStringGetClusterRequest',
    as HashRef[GetClusterRequest()];

declare 'CreateClusterRequest',
    as InstanceOf['Google::Cloud::Hypercomputecluster::V1alpha::HypercomputeCluster::CreateClusterRequest'];

coerce 'CreateClusterRequest',
    from HashRef, via { 'Google::Cloud::Hypercomputecluster::V1alpha::HypercomputeCluster::CreateClusterRequest'->new($_) };

declare 'RepeatedCreateClusterRequest',
    as ArrayRef[CreateClusterRequest()];

coerce 'RepeatedCreateClusterRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Hypercomputecluster::V1alpha::HypercomputeCluster::CreateClusterRequest'->new($_) } @$_ ] };

declare 'MapStringCreateClusterRequest',
    as HashRef[CreateClusterRequest()];

declare 'UpdateClusterRequest',
    as InstanceOf['Google::Cloud::Hypercomputecluster::V1alpha::HypercomputeCluster::UpdateClusterRequest'];

coerce 'UpdateClusterRequest',
    from HashRef, via { 'Google::Cloud::Hypercomputecluster::V1alpha::HypercomputeCluster::UpdateClusterRequest'->new($_) };

declare 'RepeatedUpdateClusterRequest',
    as ArrayRef[UpdateClusterRequest()];

coerce 'RepeatedUpdateClusterRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Hypercomputecluster::V1alpha::HypercomputeCluster::UpdateClusterRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateClusterRequest',
    as HashRef[UpdateClusterRequest()];

declare 'DeleteClusterRequest',
    as InstanceOf['Google::Cloud::Hypercomputecluster::V1alpha::HypercomputeCluster::DeleteClusterRequest'];

coerce 'DeleteClusterRequest',
    from HashRef, via { 'Google::Cloud::Hypercomputecluster::V1alpha::HypercomputeCluster::DeleteClusterRequest'->new($_) };

declare 'RepeatedDeleteClusterRequest',
    as ArrayRef[DeleteClusterRequest()];

coerce 'RepeatedDeleteClusterRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Hypercomputecluster::V1alpha::HypercomputeCluster::DeleteClusterRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteClusterRequest',
    as HashRef[DeleteClusterRequest()];

declare 'GetNodeRequest',
    as InstanceOf['Google::Cloud::Hypercomputecluster::V1alpha::HypercomputeCluster::GetNodeRequest'];

coerce 'GetNodeRequest',
    from HashRef, via { 'Google::Cloud::Hypercomputecluster::V1alpha::HypercomputeCluster::GetNodeRequest'->new($_) };

declare 'RepeatedGetNodeRequest',
    as ArrayRef[GetNodeRequest()];

coerce 'RepeatedGetNodeRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Hypercomputecluster::V1alpha::HypercomputeCluster::GetNodeRequest'->new($_) } @$_ ] };

declare 'MapStringGetNodeRequest',
    as HashRef[GetNodeRequest()];

declare 'ListNodesRequest',
    as InstanceOf['Google::Cloud::Hypercomputecluster::V1alpha::HypercomputeCluster::ListNodesRequest'];

coerce 'ListNodesRequest',
    from HashRef, via { 'Google::Cloud::Hypercomputecluster::V1alpha::HypercomputeCluster::ListNodesRequest'->new($_) };

declare 'RepeatedListNodesRequest',
    as ArrayRef[ListNodesRequest()];

coerce 'RepeatedListNodesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Hypercomputecluster::V1alpha::HypercomputeCluster::ListNodesRequest'->new($_) } @$_ ] };

declare 'MapStringListNodesRequest',
    as HashRef[ListNodesRequest()];

declare 'ListNodesResponse',
    as InstanceOf['Google::Cloud::Hypercomputecluster::V1alpha::HypercomputeCluster::ListNodesResponse'];

coerce 'ListNodesResponse',
    from HashRef, via { 'Google::Cloud::Hypercomputecluster::V1alpha::HypercomputeCluster::ListNodesResponse'->new($_) };

declare 'RepeatedListNodesResponse',
    as ArrayRef[ListNodesResponse()];

coerce 'RepeatedListNodesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Hypercomputecluster::V1alpha::HypercomputeCluster::ListNodesResponse'->new($_) } @$_ ] };

declare 'MapStringListNodesResponse',
    as HashRef[ListNodesResponse()];

declare 'NetworkResource',
    as InstanceOf['Google::Cloud::Hypercomputecluster::V1alpha::HypercomputeCluster::NetworkResource'];

coerce 'NetworkResource',
    from HashRef, via { 'Google::Cloud::Hypercomputecluster::V1alpha::HypercomputeCluster::NetworkResource'->new($_) };

declare 'RepeatedNetworkResource',
    as ArrayRef[NetworkResource()];

coerce 'RepeatedNetworkResource',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Hypercomputecluster::V1alpha::HypercomputeCluster::NetworkResource'->new($_) } @$_ ] };

declare 'MapStringNetworkResource',
    as HashRef[NetworkResource()];

declare 'NetworkReference',
    as InstanceOf['Google::Cloud::Hypercomputecluster::V1alpha::HypercomputeCluster::NetworkReference'];

coerce 'NetworkReference',
    from HashRef, via { 'Google::Cloud::Hypercomputecluster::V1alpha::HypercomputeCluster::NetworkReference'->new($_) };

declare 'RepeatedNetworkReference',
    as ArrayRef[NetworkReference()];

coerce 'RepeatedNetworkReference',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Hypercomputecluster::V1alpha::HypercomputeCluster::NetworkReference'->new($_) } @$_ ] };

declare 'MapStringNetworkReference',
    as HashRef[NetworkReference()];

declare 'NetworkResourceConfig',
    as InstanceOf['Google::Cloud::Hypercomputecluster::V1alpha::HypercomputeCluster::NetworkResourceConfig'];

coerce 'NetworkResourceConfig',
    from HashRef, via { 'Google::Cloud::Hypercomputecluster::V1alpha::HypercomputeCluster::NetworkResourceConfig'->new($_) };

declare 'RepeatedNetworkResourceConfig',
    as ArrayRef[NetworkResourceConfig()];

coerce 'RepeatedNetworkResourceConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Hypercomputecluster::V1alpha::HypercomputeCluster::NetworkResourceConfig'->new($_) } @$_ ] };

declare 'MapStringNetworkResourceConfig',
    as HashRef[NetworkResourceConfig()];

declare 'NewNetworkConfig',
    as InstanceOf['Google::Cloud::Hypercomputecluster::V1alpha::HypercomputeCluster::NewNetworkConfig'];

coerce 'NewNetworkConfig',
    from HashRef, via { 'Google::Cloud::Hypercomputecluster::V1alpha::HypercomputeCluster::NewNetworkConfig'->new($_) };

declare 'RepeatedNewNetworkConfig',
    as ArrayRef[NewNetworkConfig()];

coerce 'RepeatedNewNetworkConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Hypercomputecluster::V1alpha::HypercomputeCluster::NewNetworkConfig'->new($_) } @$_ ] };

declare 'MapStringNewNetworkConfig',
    as HashRef[NewNetworkConfig()];

declare 'ExistingNetworkConfig',
    as InstanceOf['Google::Cloud::Hypercomputecluster::V1alpha::HypercomputeCluster::ExistingNetworkConfig'];

coerce 'ExistingNetworkConfig',
    from HashRef, via { 'Google::Cloud::Hypercomputecluster::V1alpha::HypercomputeCluster::ExistingNetworkConfig'->new($_) };

declare 'RepeatedExistingNetworkConfig',
    as ArrayRef[ExistingNetworkConfig()];

coerce 'RepeatedExistingNetworkConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Hypercomputecluster::V1alpha::HypercomputeCluster::ExistingNetworkConfig'->new($_) } @$_ ] };

declare 'MapStringExistingNetworkConfig',
    as HashRef[ExistingNetworkConfig()];

declare 'StorageResource',
    as InstanceOf['Google::Cloud::Hypercomputecluster::V1alpha::HypercomputeCluster::StorageResource'];

coerce 'StorageResource',
    from HashRef, via { 'Google::Cloud::Hypercomputecluster::V1alpha::HypercomputeCluster::StorageResource'->new($_) };

declare 'RepeatedStorageResource',
    as ArrayRef[StorageResource()];

coerce 'RepeatedStorageResource',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Hypercomputecluster::V1alpha::HypercomputeCluster::StorageResource'->new($_) } @$_ ] };

declare 'MapStringStorageResource',
    as HashRef[StorageResource()];

declare 'FilestoreReference',
    as InstanceOf['Google::Cloud::Hypercomputecluster::V1alpha::HypercomputeCluster::FilestoreReference'];

coerce 'FilestoreReference',
    from HashRef, via { 'Google::Cloud::Hypercomputecluster::V1alpha::HypercomputeCluster::FilestoreReference'->new($_) };

declare 'RepeatedFilestoreReference',
    as ArrayRef[FilestoreReference()];

coerce 'RepeatedFilestoreReference',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Hypercomputecluster::V1alpha::HypercomputeCluster::FilestoreReference'->new($_) } @$_ ] };

declare 'MapStringFilestoreReference',
    as HashRef[FilestoreReference()];

declare 'BucketReference',
    as InstanceOf['Google::Cloud::Hypercomputecluster::V1alpha::HypercomputeCluster::BucketReference'];

coerce 'BucketReference',
    from HashRef, via { 'Google::Cloud::Hypercomputecluster::V1alpha::HypercomputeCluster::BucketReference'->new($_) };

declare 'RepeatedBucketReference',
    as ArrayRef[BucketReference()];

coerce 'RepeatedBucketReference',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Hypercomputecluster::V1alpha::HypercomputeCluster::BucketReference'->new($_) } @$_ ] };

declare 'MapStringBucketReference',
    as HashRef[BucketReference()];

declare 'LustreReference',
    as InstanceOf['Google::Cloud::Hypercomputecluster::V1alpha::HypercomputeCluster::LustreReference'];

coerce 'LustreReference',
    from HashRef, via { 'Google::Cloud::Hypercomputecluster::V1alpha::HypercomputeCluster::LustreReference'->new($_) };

declare 'RepeatedLustreReference',
    as ArrayRef[LustreReference()];

coerce 'RepeatedLustreReference',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Hypercomputecluster::V1alpha::HypercomputeCluster::LustreReference'->new($_) } @$_ ] };

declare 'MapStringLustreReference',
    as HashRef[LustreReference()];

declare 'StorageResourceConfig',
    as InstanceOf['Google::Cloud::Hypercomputecluster::V1alpha::HypercomputeCluster::StorageResourceConfig'];

coerce 'StorageResourceConfig',
    from HashRef, via { 'Google::Cloud::Hypercomputecluster::V1alpha::HypercomputeCluster::StorageResourceConfig'->new($_) };

declare 'RepeatedStorageResourceConfig',
    as ArrayRef[StorageResourceConfig()];

coerce 'RepeatedStorageResourceConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Hypercomputecluster::V1alpha::HypercomputeCluster::StorageResourceConfig'->new($_) } @$_ ] };

declare 'MapStringStorageResourceConfig',
    as HashRef[StorageResourceConfig()];

declare 'NewFilestoreConfig',
    as InstanceOf['Google::Cloud::Hypercomputecluster::V1alpha::HypercomputeCluster::NewFilestoreConfig'];

coerce 'NewFilestoreConfig',
    from HashRef, via { 'Google::Cloud::Hypercomputecluster::V1alpha::HypercomputeCluster::NewFilestoreConfig'->new($_) };

declare 'RepeatedNewFilestoreConfig',
    as ArrayRef[NewFilestoreConfig()];

coerce 'RepeatedNewFilestoreConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Hypercomputecluster::V1alpha::HypercomputeCluster::NewFilestoreConfig'->new($_) } @$_ ] };

declare 'MapStringNewFilestoreConfig',
    as HashRef[NewFilestoreConfig()];

declare 'Tier',
    as (Int | Str);

declare 'Protocol',
    as (Int | Str);

declare 'FileShareConfig',
    as InstanceOf['Google::Cloud::Hypercomputecluster::V1alpha::HypercomputeCluster::FileShareConfig'];

coerce 'FileShareConfig',
    from HashRef, via { 'Google::Cloud::Hypercomputecluster::V1alpha::HypercomputeCluster::FileShareConfig'->new($_) };

declare 'RepeatedFileShareConfig',
    as ArrayRef[FileShareConfig()];

coerce 'RepeatedFileShareConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Hypercomputecluster::V1alpha::HypercomputeCluster::FileShareConfig'->new($_) } @$_ ] };

declare 'MapStringFileShareConfig',
    as HashRef[FileShareConfig()];

declare 'ExistingFilestoreConfig',
    as InstanceOf['Google::Cloud::Hypercomputecluster::V1alpha::HypercomputeCluster::ExistingFilestoreConfig'];

coerce 'ExistingFilestoreConfig',
    from HashRef, via { 'Google::Cloud::Hypercomputecluster::V1alpha::HypercomputeCluster::ExistingFilestoreConfig'->new($_) };

declare 'RepeatedExistingFilestoreConfig',
    as ArrayRef[ExistingFilestoreConfig()];

coerce 'RepeatedExistingFilestoreConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Hypercomputecluster::V1alpha::HypercomputeCluster::ExistingFilestoreConfig'->new($_) } @$_ ] };

declare 'MapStringExistingFilestoreConfig',
    as HashRef[ExistingFilestoreConfig()];

declare 'NewBucketConfig',
    as InstanceOf['Google::Cloud::Hypercomputecluster::V1alpha::HypercomputeCluster::NewBucketConfig'];

coerce 'NewBucketConfig',
    from HashRef, via { 'Google::Cloud::Hypercomputecluster::V1alpha::HypercomputeCluster::NewBucketConfig'->new($_) };

declare 'RepeatedNewBucketConfig',
    as ArrayRef[NewBucketConfig()];

coerce 'RepeatedNewBucketConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Hypercomputecluster::V1alpha::HypercomputeCluster::NewBucketConfig'->new($_) } @$_ ] };

declare 'MapStringNewBucketConfig',
    as HashRef[NewBucketConfig()];

declare 'StorageClass',
    as (Int | Str);

declare 'GcsAutoclassConfig',
    as InstanceOf['Google::Cloud::Hypercomputecluster::V1alpha::HypercomputeCluster::GcsAutoclassConfig'];

coerce 'GcsAutoclassConfig',
    from HashRef, via { 'Google::Cloud::Hypercomputecluster::V1alpha::HypercomputeCluster::GcsAutoclassConfig'->new($_) };

declare 'RepeatedGcsAutoclassConfig',
    as ArrayRef[GcsAutoclassConfig()];

coerce 'RepeatedGcsAutoclassConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Hypercomputecluster::V1alpha::HypercomputeCluster::GcsAutoclassConfig'->new($_) } @$_ ] };

declare 'MapStringGcsAutoclassConfig',
    as HashRef[GcsAutoclassConfig()];

declare 'TerminalStorageClass',
    as (Int | Str);

declare 'GcsHierarchicalNamespaceConfig',
    as InstanceOf['Google::Cloud::Hypercomputecluster::V1alpha::HypercomputeCluster::GcsHierarchicalNamespaceConfig'];

coerce 'GcsHierarchicalNamespaceConfig',
    from HashRef, via { 'Google::Cloud::Hypercomputecluster::V1alpha::HypercomputeCluster::GcsHierarchicalNamespaceConfig'->new($_) };

declare 'RepeatedGcsHierarchicalNamespaceConfig',
    as ArrayRef[GcsHierarchicalNamespaceConfig()];

coerce 'RepeatedGcsHierarchicalNamespaceConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Hypercomputecluster::V1alpha::HypercomputeCluster::GcsHierarchicalNamespaceConfig'->new($_) } @$_ ] };

declare 'MapStringGcsHierarchicalNamespaceConfig',
    as HashRef[GcsHierarchicalNamespaceConfig()];

declare 'ExistingBucketConfig',
    as InstanceOf['Google::Cloud::Hypercomputecluster::V1alpha::HypercomputeCluster::ExistingBucketConfig'];

coerce 'ExistingBucketConfig',
    from HashRef, via { 'Google::Cloud::Hypercomputecluster::V1alpha::HypercomputeCluster::ExistingBucketConfig'->new($_) };

declare 'RepeatedExistingBucketConfig',
    as ArrayRef[ExistingBucketConfig()];

coerce 'RepeatedExistingBucketConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Hypercomputecluster::V1alpha::HypercomputeCluster::ExistingBucketConfig'->new($_) } @$_ ] };

declare 'MapStringExistingBucketConfig',
    as HashRef[ExistingBucketConfig()];

declare 'NewLustreConfig',
    as InstanceOf['Google::Cloud::Hypercomputecluster::V1alpha::HypercomputeCluster::NewLustreConfig'];

coerce 'NewLustreConfig',
    from HashRef, via { 'Google::Cloud::Hypercomputecluster::V1alpha::HypercomputeCluster::NewLustreConfig'->new($_) };

declare 'RepeatedNewLustreConfig',
    as ArrayRef[NewLustreConfig()];

coerce 'RepeatedNewLustreConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Hypercomputecluster::V1alpha::HypercomputeCluster::NewLustreConfig'->new($_) } @$_ ] };

declare 'MapStringNewLustreConfig',
    as HashRef[NewLustreConfig()];

declare 'ExistingLustreConfig',
    as InstanceOf['Google::Cloud::Hypercomputecluster::V1alpha::HypercomputeCluster::ExistingLustreConfig'];

coerce 'ExistingLustreConfig',
    from HashRef, via { 'Google::Cloud::Hypercomputecluster::V1alpha::HypercomputeCluster::ExistingLustreConfig'->new($_) };

declare 'RepeatedExistingLustreConfig',
    as ArrayRef[ExistingLustreConfig()];

coerce 'RepeatedExistingLustreConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Hypercomputecluster::V1alpha::HypercomputeCluster::ExistingLustreConfig'->new($_) } @$_ ] };

declare 'MapStringExistingLustreConfig',
    as HashRef[ExistingLustreConfig()];

declare 'ComputeResource',
    as InstanceOf['Google::Cloud::Hypercomputecluster::V1alpha::HypercomputeCluster::ComputeResource'];

coerce 'ComputeResource',
    from HashRef, via { 'Google::Cloud::Hypercomputecluster::V1alpha::HypercomputeCluster::ComputeResource'->new($_) };

declare 'RepeatedComputeResource',
    as ArrayRef[ComputeResource()];

coerce 'RepeatedComputeResource',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Hypercomputecluster::V1alpha::HypercomputeCluster::ComputeResource'->new($_) } @$_ ] };

declare 'MapStringComputeResource',
    as HashRef[ComputeResource()];

declare 'ComputeResourceConfig',
    as InstanceOf['Google::Cloud::Hypercomputecluster::V1alpha::HypercomputeCluster::ComputeResourceConfig'];

coerce 'ComputeResourceConfig',
    from HashRef, via { 'Google::Cloud::Hypercomputecluster::V1alpha::HypercomputeCluster::ComputeResourceConfig'->new($_) };

declare 'RepeatedComputeResourceConfig',
    as ArrayRef[ComputeResourceConfig()];

coerce 'RepeatedComputeResourceConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Hypercomputecluster::V1alpha::HypercomputeCluster::ComputeResourceConfig'->new($_) } @$_ ] };

declare 'MapStringComputeResourceConfig',
    as HashRef[ComputeResourceConfig()];

declare 'NewOnDemandInstancesConfig',
    as InstanceOf['Google::Cloud::Hypercomputecluster::V1alpha::HypercomputeCluster::NewOnDemandInstancesConfig'];

coerce 'NewOnDemandInstancesConfig',
    from HashRef, via { 'Google::Cloud::Hypercomputecluster::V1alpha::HypercomputeCluster::NewOnDemandInstancesConfig'->new($_) };

declare 'RepeatedNewOnDemandInstancesConfig',
    as ArrayRef[NewOnDemandInstancesConfig()];

coerce 'RepeatedNewOnDemandInstancesConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Hypercomputecluster::V1alpha::HypercomputeCluster::NewOnDemandInstancesConfig'->new($_) } @$_ ] };

declare 'MapStringNewOnDemandInstancesConfig',
    as HashRef[NewOnDemandInstancesConfig()];

declare 'AtmTagsEntry',
    as InstanceOf['Google::Cloud::Hypercomputecluster::V1alpha::HypercomputeCluster::NewOnDemandInstancesConfig::AtmTagsEntry'];

coerce 'AtmTagsEntry',
    from HashRef, via { 'Google::Cloud::Hypercomputecluster::V1alpha::HypercomputeCluster::NewOnDemandInstancesConfig::AtmTagsEntry'->new($_) };

declare 'RepeatedAtmTagsEntry',
    as ArrayRef[AtmTagsEntry()];

coerce 'RepeatedAtmTagsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Hypercomputecluster::V1alpha::HypercomputeCluster::NewOnDemandInstancesConfig::AtmTagsEntry'->new($_) } @$_ ] };

declare 'MapStringAtmTagsEntry',
    as HashRef[AtmTagsEntry()];

declare 'NewSpotInstancesConfig',
    as InstanceOf['Google::Cloud::Hypercomputecluster::V1alpha::HypercomputeCluster::NewSpotInstancesConfig'];

coerce 'NewSpotInstancesConfig',
    from HashRef, via { 'Google::Cloud::Hypercomputecluster::V1alpha::HypercomputeCluster::NewSpotInstancesConfig'->new($_) };

declare 'RepeatedNewSpotInstancesConfig',
    as ArrayRef[NewSpotInstancesConfig()];

coerce 'RepeatedNewSpotInstancesConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Hypercomputecluster::V1alpha::HypercomputeCluster::NewSpotInstancesConfig'->new($_) } @$_ ] };

declare 'MapStringNewSpotInstancesConfig',
    as HashRef[NewSpotInstancesConfig()];

declare 'TerminationAction',
    as (Int | Str);

declare 'AtmTagsEntry',
    as InstanceOf['Google::Cloud::Hypercomputecluster::V1alpha::HypercomputeCluster::NewSpotInstancesConfig::AtmTagsEntry'];

coerce 'AtmTagsEntry',
    from HashRef, via { 'Google::Cloud::Hypercomputecluster::V1alpha::HypercomputeCluster::NewSpotInstancesConfig::AtmTagsEntry'->new($_) };

declare 'RepeatedAtmTagsEntry',
    as ArrayRef[AtmTagsEntry()];

coerce 'RepeatedAtmTagsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Hypercomputecluster::V1alpha::HypercomputeCluster::NewSpotInstancesConfig::AtmTagsEntry'->new($_) } @$_ ] };

declare 'MapStringAtmTagsEntry',
    as HashRef[AtmTagsEntry()];

declare 'NewReservedInstancesConfig',
    as InstanceOf['Google::Cloud::Hypercomputecluster::V1alpha::HypercomputeCluster::NewReservedInstancesConfig'];

coerce 'NewReservedInstancesConfig',
    from HashRef, via { 'Google::Cloud::Hypercomputecluster::V1alpha::HypercomputeCluster::NewReservedInstancesConfig'->new($_) };

declare 'RepeatedNewReservedInstancesConfig',
    as ArrayRef[NewReservedInstancesConfig()];

coerce 'RepeatedNewReservedInstancesConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Hypercomputecluster::V1alpha::HypercomputeCluster::NewReservedInstancesConfig'->new($_) } @$_ ] };

declare 'MapStringNewReservedInstancesConfig',
    as HashRef[NewReservedInstancesConfig()];

declare 'AtmTagsEntry',
    as InstanceOf['Google::Cloud::Hypercomputecluster::V1alpha::HypercomputeCluster::NewReservedInstancesConfig::AtmTagsEntry'];

coerce 'AtmTagsEntry',
    from HashRef, via { 'Google::Cloud::Hypercomputecluster::V1alpha::HypercomputeCluster::NewReservedInstancesConfig::AtmTagsEntry'->new($_) };

declare 'RepeatedAtmTagsEntry',
    as ArrayRef[AtmTagsEntry()];

coerce 'RepeatedAtmTagsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Hypercomputecluster::V1alpha::HypercomputeCluster::NewReservedInstancesConfig::AtmTagsEntry'->new($_) } @$_ ] };

declare 'MapStringAtmTagsEntry',
    as HashRef[AtmTagsEntry()];

declare 'NewFlexStartInstancesConfig',
    as InstanceOf['Google::Cloud::Hypercomputecluster::V1alpha::HypercomputeCluster::NewFlexStartInstancesConfig'];

coerce 'NewFlexStartInstancesConfig',
    from HashRef, via { 'Google::Cloud::Hypercomputecluster::V1alpha::HypercomputeCluster::NewFlexStartInstancesConfig'->new($_) };

declare 'RepeatedNewFlexStartInstancesConfig',
    as ArrayRef[NewFlexStartInstancesConfig()];

coerce 'RepeatedNewFlexStartInstancesConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Hypercomputecluster::V1alpha::HypercomputeCluster::NewFlexStartInstancesConfig'->new($_) } @$_ ] };

declare 'MapStringNewFlexStartInstancesConfig',
    as HashRef[NewFlexStartInstancesConfig()];

declare 'AtmTagsEntry',
    as InstanceOf['Google::Cloud::Hypercomputecluster::V1alpha::HypercomputeCluster::NewFlexStartInstancesConfig::AtmTagsEntry'];

coerce 'AtmTagsEntry',
    from HashRef, via { 'Google::Cloud::Hypercomputecluster::V1alpha::HypercomputeCluster::NewFlexStartInstancesConfig::AtmTagsEntry'->new($_) };

declare 'RepeatedAtmTagsEntry',
    as ArrayRef[AtmTagsEntry()];

coerce 'RepeatedAtmTagsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Hypercomputecluster::V1alpha::HypercomputeCluster::NewFlexStartInstancesConfig::AtmTagsEntry'->new($_) } @$_ ] };

declare 'MapStringAtmTagsEntry',
    as HashRef[AtmTagsEntry()];

declare 'BootDisk',
    as InstanceOf['Google::Cloud::Hypercomputecluster::V1alpha::HypercomputeCluster::BootDisk'];

coerce 'BootDisk',
    from HashRef, via { 'Google::Cloud::Hypercomputecluster::V1alpha::HypercomputeCluster::BootDisk'->new($_) };

declare 'RepeatedBootDisk',
    as ArrayRef[BootDisk()];

coerce 'RepeatedBootDisk',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Hypercomputecluster::V1alpha::HypercomputeCluster::BootDisk'->new($_) } @$_ ] };

declare 'MapStringBootDisk',
    as HashRef[BootDisk()];

declare 'AtmTag',
    as InstanceOf['Google::Cloud::Hypercomputecluster::V1alpha::HypercomputeCluster::AtmTag'];

coerce 'AtmTag',
    from HashRef, via { 'Google::Cloud::Hypercomputecluster::V1alpha::HypercomputeCluster::AtmTag'->new($_) };

declare 'RepeatedAtmTag',
    as ArrayRef[AtmTag()];

coerce 'RepeatedAtmTag',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Hypercomputecluster::V1alpha::HypercomputeCluster::AtmTag'->new($_) } @$_ ] };

declare 'MapStringAtmTag',
    as HashRef[AtmTag()];

declare 'Orchestrator',
    as InstanceOf['Google::Cloud::Hypercomputecluster::V1alpha::HypercomputeCluster::Orchestrator'];

coerce 'Orchestrator',
    from HashRef, via { 'Google::Cloud::Hypercomputecluster::V1alpha::HypercomputeCluster::Orchestrator'->new($_) };

declare 'RepeatedOrchestrator',
    as ArrayRef[Orchestrator()];

coerce 'RepeatedOrchestrator',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Hypercomputecluster::V1alpha::HypercomputeCluster::Orchestrator'->new($_) } @$_ ] };

declare 'MapStringOrchestrator',
    as HashRef[Orchestrator()];

declare 'SlurmOrchestrator',
    as InstanceOf['Google::Cloud::Hypercomputecluster::V1alpha::HypercomputeCluster::SlurmOrchestrator'];

coerce 'SlurmOrchestrator',
    from HashRef, via { 'Google::Cloud::Hypercomputecluster::V1alpha::HypercomputeCluster::SlurmOrchestrator'->new($_) };

declare 'RepeatedSlurmOrchestrator',
    as ArrayRef[SlurmOrchestrator()];

coerce 'RepeatedSlurmOrchestrator',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Hypercomputecluster::V1alpha::HypercomputeCluster::SlurmOrchestrator'->new($_) } @$_ ] };

declare 'MapStringSlurmOrchestrator',
    as HashRef[SlurmOrchestrator()];

declare 'SlurmConfig',
    as InstanceOf['Google::Cloud::Hypercomputecluster::V1alpha::HypercomputeCluster::SlurmOrchestrator::SlurmConfig'];

coerce 'SlurmConfig',
    from HashRef, via { 'Google::Cloud::Hypercomputecluster::V1alpha::HypercomputeCluster::SlurmOrchestrator::SlurmConfig'->new($_) };

declare 'RepeatedSlurmConfig',
    as ArrayRef[SlurmConfig()];

coerce 'RepeatedSlurmConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Hypercomputecluster::V1alpha::HypercomputeCluster::SlurmOrchestrator::SlurmConfig'->new($_) } @$_ ] };

declare 'MapStringSlurmConfig',
    as HashRef[SlurmConfig()];

declare 'PrologFlag',
    as (Int | Str);

declare 'AccountingStorageEnforceFlag',
    as (Int | Str);

declare 'PriorityType',
    as (Int | Str);

declare 'PreemptMode',
    as (Int | Str);

declare 'PreemptType',
    as (Int | Str);

declare 'SlurmNodeSet',
    as InstanceOf['Google::Cloud::Hypercomputecluster::V1alpha::HypercomputeCluster::SlurmNodeSet'];

coerce 'SlurmNodeSet',
    from HashRef, via { 'Google::Cloud::Hypercomputecluster::V1alpha::HypercomputeCluster::SlurmNodeSet'->new($_) };

declare 'RepeatedSlurmNodeSet',
    as ArrayRef[SlurmNodeSet()];

coerce 'RepeatedSlurmNodeSet',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Hypercomputecluster::V1alpha::HypercomputeCluster::SlurmNodeSet'->new($_) } @$_ ] };

declare 'MapStringSlurmNodeSet',
    as HashRef[SlurmNodeSet()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Hypercomputecluster::V1alpha::HypercomputeCluster::SlurmNodeSet::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Hypercomputecluster::V1alpha::HypercomputeCluster::SlurmNodeSet::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Hypercomputecluster::V1alpha::HypercomputeCluster::SlurmNodeSet::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'ComputeInstanceSlurmNodeSet',
    as InstanceOf['Google::Cloud::Hypercomputecluster::V1alpha::HypercomputeCluster::ComputeInstanceSlurmNodeSet'];

coerce 'ComputeInstanceSlurmNodeSet',
    from HashRef, via { 'Google::Cloud::Hypercomputecluster::V1alpha::HypercomputeCluster::ComputeInstanceSlurmNodeSet'->new($_) };

declare 'RepeatedComputeInstanceSlurmNodeSet',
    as ArrayRef[ComputeInstanceSlurmNodeSet()];

coerce 'RepeatedComputeInstanceSlurmNodeSet',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Hypercomputecluster::V1alpha::HypercomputeCluster::ComputeInstanceSlurmNodeSet'->new($_) } @$_ ] };

declare 'MapStringComputeInstanceSlurmNodeSet',
    as HashRef[ComputeInstanceSlurmNodeSet()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Hypercomputecluster::V1alpha::HypercomputeCluster::ComputeInstanceSlurmNodeSet::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Hypercomputecluster::V1alpha::HypercomputeCluster::ComputeInstanceSlurmNodeSet::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Hypercomputecluster::V1alpha::HypercomputeCluster::ComputeInstanceSlurmNodeSet::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'ContainerNodePoolSlurmNodeSet',
    as InstanceOf['Google::Cloud::Hypercomputecluster::V1alpha::HypercomputeCluster::ContainerNodePoolSlurmNodeSet'];

coerce 'ContainerNodePoolSlurmNodeSet',
    from HashRef, via { 'Google::Cloud::Hypercomputecluster::V1alpha::HypercomputeCluster::ContainerNodePoolSlurmNodeSet'->new($_) };

declare 'RepeatedContainerNodePoolSlurmNodeSet',
    as ArrayRef[ContainerNodePoolSlurmNodeSet()];

coerce 'RepeatedContainerNodePoolSlurmNodeSet',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Hypercomputecluster::V1alpha::HypercomputeCluster::ContainerNodePoolSlurmNodeSet'->new($_) } @$_ ] };

declare 'MapStringContainerNodePoolSlurmNodeSet',
    as HashRef[ContainerNodePoolSlurmNodeSet()];

declare 'ResourceLabelsEntry',
    as InstanceOf['Google::Cloud::Hypercomputecluster::V1alpha::HypercomputeCluster::ContainerNodePoolSlurmNodeSet::ResourceLabelsEntry'];

coerce 'ResourceLabelsEntry',
    from HashRef, via { 'Google::Cloud::Hypercomputecluster::V1alpha::HypercomputeCluster::ContainerNodePoolSlurmNodeSet::ResourceLabelsEntry'->new($_) };

declare 'RepeatedResourceLabelsEntry',
    as ArrayRef[ResourceLabelsEntry()];

coerce 'RepeatedResourceLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Hypercomputecluster::V1alpha::HypercomputeCluster::ContainerNodePoolSlurmNodeSet::ResourceLabelsEntry'->new($_) } @$_ ] };

declare 'MapStringResourceLabelsEntry',
    as HashRef[ResourceLabelsEntry()];

declare 'SlurmPartition',
    as InstanceOf['Google::Cloud::Hypercomputecluster::V1alpha::HypercomputeCluster::SlurmPartition'];

coerce 'SlurmPartition',
    from HashRef, via { 'Google::Cloud::Hypercomputecluster::V1alpha::HypercomputeCluster::SlurmPartition'->new($_) };

declare 'RepeatedSlurmPartition',
    as ArrayRef[SlurmPartition()];

coerce 'RepeatedSlurmPartition',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Hypercomputecluster::V1alpha::HypercomputeCluster::SlurmPartition'->new($_) } @$_ ] };

declare 'MapStringSlurmPartition',
    as HashRef[SlurmPartition()];

declare 'SlurmLoginNodes',
    as InstanceOf['Google::Cloud::Hypercomputecluster::V1alpha::HypercomputeCluster::SlurmLoginNodes'];

coerce 'SlurmLoginNodes',
    from HashRef, via { 'Google::Cloud::Hypercomputecluster::V1alpha::HypercomputeCluster::SlurmLoginNodes'->new($_) };

declare 'RepeatedSlurmLoginNodes',
    as ArrayRef[SlurmLoginNodes()];

coerce 'RepeatedSlurmLoginNodes',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Hypercomputecluster::V1alpha::HypercomputeCluster::SlurmLoginNodes'->new($_) } @$_ ] };

declare 'MapStringSlurmLoginNodes',
    as HashRef[SlurmLoginNodes()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Hypercomputecluster::V1alpha::HypercomputeCluster::SlurmLoginNodes::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Hypercomputecluster::V1alpha::HypercomputeCluster::SlurmLoginNodes::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Hypercomputecluster::V1alpha::HypercomputeCluster::SlurmLoginNodes::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'ServiceAccount',
    as InstanceOf['Google::Cloud::Hypercomputecluster::V1alpha::HypercomputeCluster::ServiceAccount'];

coerce 'ServiceAccount',
    from HashRef, via { 'Google::Cloud::Hypercomputecluster::V1alpha::HypercomputeCluster::ServiceAccount'->new($_) };

declare 'RepeatedServiceAccount',
    as ArrayRef[ServiceAccount()];

coerce 'RepeatedServiceAccount',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Hypercomputecluster::V1alpha::HypercomputeCluster::ServiceAccount'->new($_) } @$_ ] };

declare 'MapStringServiceAccount',
    as HashRef[ServiceAccount()];

declare 'StorageConfig',
    as InstanceOf['Google::Cloud::Hypercomputecluster::V1alpha::HypercomputeCluster::StorageConfig'];

coerce 'StorageConfig',
    from HashRef, via { 'Google::Cloud::Hypercomputecluster::V1alpha::HypercomputeCluster::StorageConfig'->new($_) };

declare 'RepeatedStorageConfig',
    as ArrayRef[StorageConfig()];

coerce 'RepeatedStorageConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Hypercomputecluster::V1alpha::HypercomputeCluster::StorageConfig'->new($_) } @$_ ] };

declare 'MapStringStorageConfig',
    as HashRef[StorageConfig()];

declare 'ComputeInstance',
    as InstanceOf['Google::Cloud::Hypercomputecluster::V1alpha::HypercomputeCluster::ComputeInstance'];

coerce 'ComputeInstance',
    from HashRef, via { 'Google::Cloud::Hypercomputecluster::V1alpha::HypercomputeCluster::ComputeInstance'->new($_) };

declare 'RepeatedComputeInstance',
    as ArrayRef[ComputeInstance()];

coerce 'RepeatedComputeInstance',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Hypercomputecluster::V1alpha::HypercomputeCluster::ComputeInstance'->new($_) } @$_ ] };

declare 'MapStringComputeInstance',
    as HashRef[ComputeInstance()];

declare 'MaintenancePolicy',
    as InstanceOf['Google::Cloud::Hypercomputecluster::V1alpha::HypercomputeCluster::MaintenancePolicy'];

coerce 'MaintenancePolicy',
    from HashRef, via { 'Google::Cloud::Hypercomputecluster::V1alpha::HypercomputeCluster::MaintenancePolicy'->new($_) };

declare 'RepeatedMaintenancePolicy',
    as ArrayRef[MaintenancePolicy()];

coerce 'RepeatedMaintenancePolicy',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Hypercomputecluster::V1alpha::HypercomputeCluster::MaintenancePolicy'->new($_) } @$_ ] };

declare 'MapStringMaintenancePolicy',
    as HashRef[MaintenancePolicy()];

declare 'MaintenanceWindow',
    as InstanceOf['Google::Cloud::Hypercomputecluster::V1alpha::HypercomputeCluster::MaintenanceWindow'];

coerce 'MaintenanceWindow',
    from HashRef, via { 'Google::Cloud::Hypercomputecluster::V1alpha::HypercomputeCluster::MaintenanceWindow'->new($_) };

declare 'RepeatedMaintenanceWindow',
    as ArrayRef[MaintenanceWindow()];

coerce 'RepeatedMaintenanceWindow',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Hypercomputecluster::V1alpha::HypercomputeCluster::MaintenanceWindow'->new($_) } @$_ ] };

declare 'MapStringMaintenanceWindow',
    as HashRef[MaintenanceWindow()];

declare 'Compute',
    as InstanceOf['Google::Cloud::Hypercomputecluster::V1alpha::HypercomputeCluster::Compute'];

coerce 'Compute',
    from HashRef, via { 'Google::Cloud::Hypercomputecluster::V1alpha::HypercomputeCluster::Compute'->new($_) };

declare 'RepeatedCompute',
    as ArrayRef[Compute()];

coerce 'RepeatedCompute',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Hypercomputecluster::V1alpha::HypercomputeCluster::Compute'->new($_) } @$_ ] };

declare 'MapStringCompute',
    as HashRef[Compute()];

declare 'Node',
    as InstanceOf['Google::Cloud::Hypercomputecluster::V1alpha::HypercomputeCluster::Node'];

coerce 'Node',
    from HashRef, via { 'Google::Cloud::Hypercomputecluster::V1alpha::HypercomputeCluster::Node'->new($_) };

declare 'RepeatedNode',
    as ArrayRef[Node()];

coerce 'RepeatedNode',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Hypercomputecluster::V1alpha::HypercomputeCluster::Node'->new($_) } @$_ ] };

declare 'MapStringNode',
    as HashRef[Node()];

declare 'State',
    as (Int | Str);

declare 'SlurmNodeDetails',
    as InstanceOf['Google::Cloud::Hypercomputecluster::V1alpha::HypercomputeCluster::SlurmNodeDetails'];

coerce 'SlurmNodeDetails',
    from HashRef, via { 'Google::Cloud::Hypercomputecluster::V1alpha::HypercomputeCluster::SlurmNodeDetails'->new($_) };

declare 'RepeatedSlurmNodeDetails',
    as ArrayRef[SlurmNodeDetails()];

coerce 'RepeatedSlurmNodeDetails',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Hypercomputecluster::V1alpha::HypercomputeCluster::SlurmNodeDetails'->new($_) } @$_ ] };

declare 'MapStringSlurmNodeDetails',
    as HashRef[SlurmNodeDetails()];

declare 'ComputeEngineNodeDetails',
    as InstanceOf['Google::Cloud::Hypercomputecluster::V1alpha::HypercomputeCluster::ComputeEngineNodeDetails'];

coerce 'ComputeEngineNodeDetails',
    from HashRef, via { 'Google::Cloud::Hypercomputecluster::V1alpha::HypercomputeCluster::ComputeEngineNodeDetails'->new($_) };

declare 'RepeatedComputeEngineNodeDetails',
    as ArrayRef[ComputeEngineNodeDetails()];

coerce 'RepeatedComputeEngineNodeDetails',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Hypercomputecluster::V1alpha::HypercomputeCluster::ComputeEngineNodeDetails'->new($_) } @$_ ] };

declare 'MapStringComputeEngineNodeDetails',
    as HashRef[ComputeEngineNodeDetails()];

declare 'ContainerEngineNodeDetails',
    as InstanceOf['Google::Cloud::Hypercomputecluster::V1alpha::HypercomputeCluster::ContainerEngineNodeDetails'];

coerce 'ContainerEngineNodeDetails',
    from HashRef, via { 'Google::Cloud::Hypercomputecluster::V1alpha::HypercomputeCluster::ContainerEngineNodeDetails'->new($_) };

declare 'RepeatedContainerEngineNodeDetails',
    as ArrayRef[ContainerEngineNodeDetails()];

coerce 'RepeatedContainerEngineNodeDetails',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Hypercomputecluster::V1alpha::HypercomputeCluster::ContainerEngineNodeDetails'->new($_) } @$_ ] };

declare 'MapStringContainerEngineNodeDetails',
    as HashRef[ContainerEngineNodeDetails()];

1;

__END__

=head1 NAME

Google::Cloud::Hypercomputecluster::V1alpha::HypercomputeCluster::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
