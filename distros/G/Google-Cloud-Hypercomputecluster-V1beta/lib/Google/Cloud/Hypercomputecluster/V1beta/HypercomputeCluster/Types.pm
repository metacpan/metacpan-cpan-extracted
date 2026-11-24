package Google::Cloud::Hypercomputecluster::V1beta::HypercomputeCluster::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Cluster',
    as InstanceOf['Google::Cloud::Hypercomputecluster::V1beta::HypercomputeCluster::Cluster'];

coerce 'Cluster',
    from HashRef, via { 'Google::Cloud::Hypercomputecluster::V1beta::HypercomputeCluster::Cluster'->new($_) };

declare 'RepeatedCluster',
    as ArrayRef[Cluster()];

coerce 'RepeatedCluster',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Hypercomputecluster::V1beta::HypercomputeCluster::Cluster'->new($_) } @$_ ] };

declare 'MapStringCluster',
    as HashRef[Cluster()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Hypercomputecluster::V1beta::HypercomputeCluster::Cluster::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Hypercomputecluster::V1beta::HypercomputeCluster::Cluster::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Hypercomputecluster::V1beta::HypercomputeCluster::Cluster::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'NetworkResourcesEntry',
    as InstanceOf['Google::Cloud::Hypercomputecluster::V1beta::HypercomputeCluster::Cluster::NetworkResourcesEntry'];

coerce 'NetworkResourcesEntry',
    from HashRef, via { 'Google::Cloud::Hypercomputecluster::V1beta::HypercomputeCluster::Cluster::NetworkResourcesEntry'->new($_) };

declare 'RepeatedNetworkResourcesEntry',
    as ArrayRef[NetworkResourcesEntry()];

coerce 'RepeatedNetworkResourcesEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Hypercomputecluster::V1beta::HypercomputeCluster::Cluster::NetworkResourcesEntry'->new($_) } @$_ ] };

declare 'MapStringNetworkResourcesEntry',
    as HashRef[NetworkResourcesEntry()];

declare 'StorageResourcesEntry',
    as InstanceOf['Google::Cloud::Hypercomputecluster::V1beta::HypercomputeCluster::Cluster::StorageResourcesEntry'];

coerce 'StorageResourcesEntry',
    from HashRef, via { 'Google::Cloud::Hypercomputecluster::V1beta::HypercomputeCluster::Cluster::StorageResourcesEntry'->new($_) };

declare 'RepeatedStorageResourcesEntry',
    as ArrayRef[StorageResourcesEntry()];

coerce 'RepeatedStorageResourcesEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Hypercomputecluster::V1beta::HypercomputeCluster::Cluster::StorageResourcesEntry'->new($_) } @$_ ] };

declare 'MapStringStorageResourcesEntry',
    as HashRef[StorageResourcesEntry()];

declare 'ComputeResourcesEntry',
    as InstanceOf['Google::Cloud::Hypercomputecluster::V1beta::HypercomputeCluster::Cluster::ComputeResourcesEntry'];

coerce 'ComputeResourcesEntry',
    from HashRef, via { 'Google::Cloud::Hypercomputecluster::V1beta::HypercomputeCluster::Cluster::ComputeResourcesEntry'->new($_) };

declare 'RepeatedComputeResourcesEntry',
    as ArrayRef[ComputeResourcesEntry()];

coerce 'RepeatedComputeResourcesEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Hypercomputecluster::V1beta::HypercomputeCluster::Cluster::ComputeResourcesEntry'->new($_) } @$_ ] };

declare 'MapStringComputeResourcesEntry',
    as HashRef[ComputeResourcesEntry()];

declare 'ListClustersRequest',
    as InstanceOf['Google::Cloud::Hypercomputecluster::V1beta::HypercomputeCluster::ListClustersRequest'];

coerce 'ListClustersRequest',
    from HashRef, via { 'Google::Cloud::Hypercomputecluster::V1beta::HypercomputeCluster::ListClustersRequest'->new($_) };

declare 'RepeatedListClustersRequest',
    as ArrayRef[ListClustersRequest()];

coerce 'RepeatedListClustersRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Hypercomputecluster::V1beta::HypercomputeCluster::ListClustersRequest'->new($_) } @$_ ] };

declare 'MapStringListClustersRequest',
    as HashRef[ListClustersRequest()];

declare 'ListClustersResponse',
    as InstanceOf['Google::Cloud::Hypercomputecluster::V1beta::HypercomputeCluster::ListClustersResponse'];

coerce 'ListClustersResponse',
    from HashRef, via { 'Google::Cloud::Hypercomputecluster::V1beta::HypercomputeCluster::ListClustersResponse'->new($_) };

declare 'RepeatedListClustersResponse',
    as ArrayRef[ListClustersResponse()];

coerce 'RepeatedListClustersResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Hypercomputecluster::V1beta::HypercomputeCluster::ListClustersResponse'->new($_) } @$_ ] };

declare 'MapStringListClustersResponse',
    as HashRef[ListClustersResponse()];

declare 'GetClusterRequest',
    as InstanceOf['Google::Cloud::Hypercomputecluster::V1beta::HypercomputeCluster::GetClusterRequest'];

coerce 'GetClusterRequest',
    from HashRef, via { 'Google::Cloud::Hypercomputecluster::V1beta::HypercomputeCluster::GetClusterRequest'->new($_) };

declare 'RepeatedGetClusterRequest',
    as ArrayRef[GetClusterRequest()];

coerce 'RepeatedGetClusterRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Hypercomputecluster::V1beta::HypercomputeCluster::GetClusterRequest'->new($_) } @$_ ] };

declare 'MapStringGetClusterRequest',
    as HashRef[GetClusterRequest()];

declare 'CreateClusterRequest',
    as InstanceOf['Google::Cloud::Hypercomputecluster::V1beta::HypercomputeCluster::CreateClusterRequest'];

coerce 'CreateClusterRequest',
    from HashRef, via { 'Google::Cloud::Hypercomputecluster::V1beta::HypercomputeCluster::CreateClusterRequest'->new($_) };

declare 'RepeatedCreateClusterRequest',
    as ArrayRef[CreateClusterRequest()];

coerce 'RepeatedCreateClusterRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Hypercomputecluster::V1beta::HypercomputeCluster::CreateClusterRequest'->new($_) } @$_ ] };

declare 'MapStringCreateClusterRequest',
    as HashRef[CreateClusterRequest()];

declare 'UpdateClusterRequest',
    as InstanceOf['Google::Cloud::Hypercomputecluster::V1beta::HypercomputeCluster::UpdateClusterRequest'];

coerce 'UpdateClusterRequest',
    from HashRef, via { 'Google::Cloud::Hypercomputecluster::V1beta::HypercomputeCluster::UpdateClusterRequest'->new($_) };

declare 'RepeatedUpdateClusterRequest',
    as ArrayRef[UpdateClusterRequest()];

coerce 'RepeatedUpdateClusterRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Hypercomputecluster::V1beta::HypercomputeCluster::UpdateClusterRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateClusterRequest',
    as HashRef[UpdateClusterRequest()];

declare 'DeleteClusterRequest',
    as InstanceOf['Google::Cloud::Hypercomputecluster::V1beta::HypercomputeCluster::DeleteClusterRequest'];

coerce 'DeleteClusterRequest',
    from HashRef, via { 'Google::Cloud::Hypercomputecluster::V1beta::HypercomputeCluster::DeleteClusterRequest'->new($_) };

declare 'RepeatedDeleteClusterRequest',
    as ArrayRef[DeleteClusterRequest()];

coerce 'RepeatedDeleteClusterRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Hypercomputecluster::V1beta::HypercomputeCluster::DeleteClusterRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteClusterRequest',
    as HashRef[DeleteClusterRequest()];

declare 'ListNodesRequest',
    as InstanceOf['Google::Cloud::Hypercomputecluster::V1beta::HypercomputeCluster::ListNodesRequest'];

coerce 'ListNodesRequest',
    from HashRef, via { 'Google::Cloud::Hypercomputecluster::V1beta::HypercomputeCluster::ListNodesRequest'->new($_) };

declare 'RepeatedListNodesRequest',
    as ArrayRef[ListNodesRequest()];

coerce 'RepeatedListNodesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Hypercomputecluster::V1beta::HypercomputeCluster::ListNodesRequest'->new($_) } @$_ ] };

declare 'MapStringListNodesRequest',
    as HashRef[ListNodesRequest()];

declare 'ListNodesResponse',
    as InstanceOf['Google::Cloud::Hypercomputecluster::V1beta::HypercomputeCluster::ListNodesResponse'];

coerce 'ListNodesResponse',
    from HashRef, via { 'Google::Cloud::Hypercomputecluster::V1beta::HypercomputeCluster::ListNodesResponse'->new($_) };

declare 'RepeatedListNodesResponse',
    as ArrayRef[ListNodesResponse()];

coerce 'RepeatedListNodesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Hypercomputecluster::V1beta::HypercomputeCluster::ListNodesResponse'->new($_) } @$_ ] };

declare 'MapStringListNodesResponse',
    as HashRef[ListNodesResponse()];

declare 'NetworkResource',
    as InstanceOf['Google::Cloud::Hypercomputecluster::V1beta::HypercomputeCluster::NetworkResource'];

coerce 'NetworkResource',
    from HashRef, via { 'Google::Cloud::Hypercomputecluster::V1beta::HypercomputeCluster::NetworkResource'->new($_) };

declare 'RepeatedNetworkResource',
    as ArrayRef[NetworkResource()];

coerce 'RepeatedNetworkResource',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Hypercomputecluster::V1beta::HypercomputeCluster::NetworkResource'->new($_) } @$_ ] };

declare 'MapStringNetworkResource',
    as HashRef[NetworkResource()];

declare 'NetworkReference',
    as InstanceOf['Google::Cloud::Hypercomputecluster::V1beta::HypercomputeCluster::NetworkReference'];

coerce 'NetworkReference',
    from HashRef, via { 'Google::Cloud::Hypercomputecluster::V1beta::HypercomputeCluster::NetworkReference'->new($_) };

declare 'RepeatedNetworkReference',
    as ArrayRef[NetworkReference()];

coerce 'RepeatedNetworkReference',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Hypercomputecluster::V1beta::HypercomputeCluster::NetworkReference'->new($_) } @$_ ] };

declare 'MapStringNetworkReference',
    as HashRef[NetworkReference()];

declare 'NetworkResourceConfig',
    as InstanceOf['Google::Cloud::Hypercomputecluster::V1beta::HypercomputeCluster::NetworkResourceConfig'];

coerce 'NetworkResourceConfig',
    from HashRef, via { 'Google::Cloud::Hypercomputecluster::V1beta::HypercomputeCluster::NetworkResourceConfig'->new($_) };

declare 'RepeatedNetworkResourceConfig',
    as ArrayRef[NetworkResourceConfig()];

coerce 'RepeatedNetworkResourceConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Hypercomputecluster::V1beta::HypercomputeCluster::NetworkResourceConfig'->new($_) } @$_ ] };

declare 'MapStringNetworkResourceConfig',
    as HashRef[NetworkResourceConfig()];

declare 'NewNetworkConfig',
    as InstanceOf['Google::Cloud::Hypercomputecluster::V1beta::HypercomputeCluster::NewNetworkConfig'];

coerce 'NewNetworkConfig',
    from HashRef, via { 'Google::Cloud::Hypercomputecluster::V1beta::HypercomputeCluster::NewNetworkConfig'->new($_) };

declare 'RepeatedNewNetworkConfig',
    as ArrayRef[NewNetworkConfig()];

coerce 'RepeatedNewNetworkConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Hypercomputecluster::V1beta::HypercomputeCluster::NewNetworkConfig'->new($_) } @$_ ] };

declare 'MapStringNewNetworkConfig',
    as HashRef[NewNetworkConfig()];

declare 'ExistingNetworkConfig',
    as InstanceOf['Google::Cloud::Hypercomputecluster::V1beta::HypercomputeCluster::ExistingNetworkConfig'];

coerce 'ExistingNetworkConfig',
    from HashRef, via { 'Google::Cloud::Hypercomputecluster::V1beta::HypercomputeCluster::ExistingNetworkConfig'->new($_) };

declare 'RepeatedExistingNetworkConfig',
    as ArrayRef[ExistingNetworkConfig()];

coerce 'RepeatedExistingNetworkConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Hypercomputecluster::V1beta::HypercomputeCluster::ExistingNetworkConfig'->new($_) } @$_ ] };

declare 'MapStringExistingNetworkConfig',
    as HashRef[ExistingNetworkConfig()];

declare 'StorageResource',
    as InstanceOf['Google::Cloud::Hypercomputecluster::V1beta::HypercomputeCluster::StorageResource'];

coerce 'StorageResource',
    from HashRef, via { 'Google::Cloud::Hypercomputecluster::V1beta::HypercomputeCluster::StorageResource'->new($_) };

declare 'RepeatedStorageResource',
    as ArrayRef[StorageResource()];

coerce 'RepeatedStorageResource',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Hypercomputecluster::V1beta::HypercomputeCluster::StorageResource'->new($_) } @$_ ] };

declare 'MapStringStorageResource',
    as HashRef[StorageResource()];

declare 'FilestoreReference',
    as InstanceOf['Google::Cloud::Hypercomputecluster::V1beta::HypercomputeCluster::FilestoreReference'];

coerce 'FilestoreReference',
    from HashRef, via { 'Google::Cloud::Hypercomputecluster::V1beta::HypercomputeCluster::FilestoreReference'->new($_) };

declare 'RepeatedFilestoreReference',
    as ArrayRef[FilestoreReference()];

coerce 'RepeatedFilestoreReference',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Hypercomputecluster::V1beta::HypercomputeCluster::FilestoreReference'->new($_) } @$_ ] };

declare 'MapStringFilestoreReference',
    as HashRef[FilestoreReference()];

declare 'BucketReference',
    as InstanceOf['Google::Cloud::Hypercomputecluster::V1beta::HypercomputeCluster::BucketReference'];

coerce 'BucketReference',
    from HashRef, via { 'Google::Cloud::Hypercomputecluster::V1beta::HypercomputeCluster::BucketReference'->new($_) };

declare 'RepeatedBucketReference',
    as ArrayRef[BucketReference()];

coerce 'RepeatedBucketReference',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Hypercomputecluster::V1beta::HypercomputeCluster::BucketReference'->new($_) } @$_ ] };

declare 'MapStringBucketReference',
    as HashRef[BucketReference()];

declare 'LustreReference',
    as InstanceOf['Google::Cloud::Hypercomputecluster::V1beta::HypercomputeCluster::LustreReference'];

coerce 'LustreReference',
    from HashRef, via { 'Google::Cloud::Hypercomputecluster::V1beta::HypercomputeCluster::LustreReference'->new($_) };

declare 'RepeatedLustreReference',
    as ArrayRef[LustreReference()];

coerce 'RepeatedLustreReference',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Hypercomputecluster::V1beta::HypercomputeCluster::LustreReference'->new($_) } @$_ ] };

declare 'MapStringLustreReference',
    as HashRef[LustreReference()];

declare 'StorageResourceConfig',
    as InstanceOf['Google::Cloud::Hypercomputecluster::V1beta::HypercomputeCluster::StorageResourceConfig'];

coerce 'StorageResourceConfig',
    from HashRef, via { 'Google::Cloud::Hypercomputecluster::V1beta::HypercomputeCluster::StorageResourceConfig'->new($_) };

declare 'RepeatedStorageResourceConfig',
    as ArrayRef[StorageResourceConfig()];

coerce 'RepeatedStorageResourceConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Hypercomputecluster::V1beta::HypercomputeCluster::StorageResourceConfig'->new($_) } @$_ ] };

declare 'MapStringStorageResourceConfig',
    as HashRef[StorageResourceConfig()];

declare 'NewFilestoreConfig',
    as InstanceOf['Google::Cloud::Hypercomputecluster::V1beta::HypercomputeCluster::NewFilestoreConfig'];

coerce 'NewFilestoreConfig',
    from HashRef, via { 'Google::Cloud::Hypercomputecluster::V1beta::HypercomputeCluster::NewFilestoreConfig'->new($_) };

declare 'RepeatedNewFilestoreConfig',
    as ArrayRef[NewFilestoreConfig()];

coerce 'RepeatedNewFilestoreConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Hypercomputecluster::V1beta::HypercomputeCluster::NewFilestoreConfig'->new($_) } @$_ ] };

declare 'MapStringNewFilestoreConfig',
    as HashRef[NewFilestoreConfig()];

declare 'Tier',
    as (Int | Str);

declare 'Protocol',
    as (Int | Str);

declare 'FileShareConfig',
    as InstanceOf['Google::Cloud::Hypercomputecluster::V1beta::HypercomputeCluster::FileShareConfig'];

coerce 'FileShareConfig',
    from HashRef, via { 'Google::Cloud::Hypercomputecluster::V1beta::HypercomputeCluster::FileShareConfig'->new($_) };

declare 'RepeatedFileShareConfig',
    as ArrayRef[FileShareConfig()];

coerce 'RepeatedFileShareConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Hypercomputecluster::V1beta::HypercomputeCluster::FileShareConfig'->new($_) } @$_ ] };

declare 'MapStringFileShareConfig',
    as HashRef[FileShareConfig()];

declare 'ExistingFilestoreConfig',
    as InstanceOf['Google::Cloud::Hypercomputecluster::V1beta::HypercomputeCluster::ExistingFilestoreConfig'];

coerce 'ExistingFilestoreConfig',
    from HashRef, via { 'Google::Cloud::Hypercomputecluster::V1beta::HypercomputeCluster::ExistingFilestoreConfig'->new($_) };

declare 'RepeatedExistingFilestoreConfig',
    as ArrayRef[ExistingFilestoreConfig()];

coerce 'RepeatedExistingFilestoreConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Hypercomputecluster::V1beta::HypercomputeCluster::ExistingFilestoreConfig'->new($_) } @$_ ] };

declare 'MapStringExistingFilestoreConfig',
    as HashRef[ExistingFilestoreConfig()];

declare 'NewBucketConfig',
    as InstanceOf['Google::Cloud::Hypercomputecluster::V1beta::HypercomputeCluster::NewBucketConfig'];

coerce 'NewBucketConfig',
    from HashRef, via { 'Google::Cloud::Hypercomputecluster::V1beta::HypercomputeCluster::NewBucketConfig'->new($_) };

declare 'RepeatedNewBucketConfig',
    as ArrayRef[NewBucketConfig()];

coerce 'RepeatedNewBucketConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Hypercomputecluster::V1beta::HypercomputeCluster::NewBucketConfig'->new($_) } @$_ ] };

declare 'MapStringNewBucketConfig',
    as HashRef[NewBucketConfig()];

declare 'StorageClass',
    as (Int | Str);

declare 'GcsAutoclassConfig',
    as InstanceOf['Google::Cloud::Hypercomputecluster::V1beta::HypercomputeCluster::GcsAutoclassConfig'];

coerce 'GcsAutoclassConfig',
    from HashRef, via { 'Google::Cloud::Hypercomputecluster::V1beta::HypercomputeCluster::GcsAutoclassConfig'->new($_) };

declare 'RepeatedGcsAutoclassConfig',
    as ArrayRef[GcsAutoclassConfig()];

coerce 'RepeatedGcsAutoclassConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Hypercomputecluster::V1beta::HypercomputeCluster::GcsAutoclassConfig'->new($_) } @$_ ] };

declare 'MapStringGcsAutoclassConfig',
    as HashRef[GcsAutoclassConfig()];

declare 'TerminalStorageClass',
    as (Int | Str);

declare 'GcsHierarchicalNamespaceConfig',
    as InstanceOf['Google::Cloud::Hypercomputecluster::V1beta::HypercomputeCluster::GcsHierarchicalNamespaceConfig'];

coerce 'GcsHierarchicalNamespaceConfig',
    from HashRef, via { 'Google::Cloud::Hypercomputecluster::V1beta::HypercomputeCluster::GcsHierarchicalNamespaceConfig'->new($_) };

declare 'RepeatedGcsHierarchicalNamespaceConfig',
    as ArrayRef[GcsHierarchicalNamespaceConfig()];

coerce 'RepeatedGcsHierarchicalNamespaceConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Hypercomputecluster::V1beta::HypercomputeCluster::GcsHierarchicalNamespaceConfig'->new($_) } @$_ ] };

declare 'MapStringGcsHierarchicalNamespaceConfig',
    as HashRef[GcsHierarchicalNamespaceConfig()];

declare 'ExistingBucketConfig',
    as InstanceOf['Google::Cloud::Hypercomputecluster::V1beta::HypercomputeCluster::ExistingBucketConfig'];

coerce 'ExistingBucketConfig',
    from HashRef, via { 'Google::Cloud::Hypercomputecluster::V1beta::HypercomputeCluster::ExistingBucketConfig'->new($_) };

declare 'RepeatedExistingBucketConfig',
    as ArrayRef[ExistingBucketConfig()];

coerce 'RepeatedExistingBucketConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Hypercomputecluster::V1beta::HypercomputeCluster::ExistingBucketConfig'->new($_) } @$_ ] };

declare 'MapStringExistingBucketConfig',
    as HashRef[ExistingBucketConfig()];

declare 'NewLustreConfig',
    as InstanceOf['Google::Cloud::Hypercomputecluster::V1beta::HypercomputeCluster::NewLustreConfig'];

coerce 'NewLustreConfig',
    from HashRef, via { 'Google::Cloud::Hypercomputecluster::V1beta::HypercomputeCluster::NewLustreConfig'->new($_) };

declare 'RepeatedNewLustreConfig',
    as ArrayRef[NewLustreConfig()];

coerce 'RepeatedNewLustreConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Hypercomputecluster::V1beta::HypercomputeCluster::NewLustreConfig'->new($_) } @$_ ] };

declare 'MapStringNewLustreConfig',
    as HashRef[NewLustreConfig()];

declare 'ExistingLustreConfig',
    as InstanceOf['Google::Cloud::Hypercomputecluster::V1beta::HypercomputeCluster::ExistingLustreConfig'];

coerce 'ExistingLustreConfig',
    from HashRef, via { 'Google::Cloud::Hypercomputecluster::V1beta::HypercomputeCluster::ExistingLustreConfig'->new($_) };

declare 'RepeatedExistingLustreConfig',
    as ArrayRef[ExistingLustreConfig()];

coerce 'RepeatedExistingLustreConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Hypercomputecluster::V1beta::HypercomputeCluster::ExistingLustreConfig'->new($_) } @$_ ] };

declare 'MapStringExistingLustreConfig',
    as HashRef[ExistingLustreConfig()];

declare 'ExistingNfsConfig',
    as InstanceOf['Google::Cloud::Hypercomputecluster::V1beta::HypercomputeCluster::ExistingNfsConfig'];

coerce 'ExistingNfsConfig',
    from HashRef, via { 'Google::Cloud::Hypercomputecluster::V1beta::HypercomputeCluster::ExistingNfsConfig'->new($_) };

declare 'RepeatedExistingNfsConfig',
    as ArrayRef[ExistingNfsConfig()];

coerce 'RepeatedExistingNfsConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Hypercomputecluster::V1beta::HypercomputeCluster::ExistingNfsConfig'->new($_) } @$_ ] };

declare 'MapStringExistingNfsConfig',
    as HashRef[ExistingNfsConfig()];

declare 'ComputeResource',
    as InstanceOf['Google::Cloud::Hypercomputecluster::V1beta::HypercomputeCluster::ComputeResource'];

coerce 'ComputeResource',
    from HashRef, via { 'Google::Cloud::Hypercomputecluster::V1beta::HypercomputeCluster::ComputeResource'->new($_) };

declare 'RepeatedComputeResource',
    as ArrayRef[ComputeResource()];

coerce 'RepeatedComputeResource',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Hypercomputecluster::V1beta::HypercomputeCluster::ComputeResource'->new($_) } @$_ ] };

declare 'MapStringComputeResource',
    as HashRef[ComputeResource()];

declare 'ComputeResourceConfig',
    as InstanceOf['Google::Cloud::Hypercomputecluster::V1beta::HypercomputeCluster::ComputeResourceConfig'];

coerce 'ComputeResourceConfig',
    from HashRef, via { 'Google::Cloud::Hypercomputecluster::V1beta::HypercomputeCluster::ComputeResourceConfig'->new($_) };

declare 'RepeatedComputeResourceConfig',
    as ArrayRef[ComputeResourceConfig()];

coerce 'RepeatedComputeResourceConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Hypercomputecluster::V1beta::HypercomputeCluster::ComputeResourceConfig'->new($_) } @$_ ] };

declare 'MapStringComputeResourceConfig',
    as HashRef[ComputeResourceConfig()];

declare 'NewOnDemandInstancesConfig',
    as InstanceOf['Google::Cloud::Hypercomputecluster::V1beta::HypercomputeCluster::NewOnDemandInstancesConfig'];

coerce 'NewOnDemandInstancesConfig',
    from HashRef, via { 'Google::Cloud::Hypercomputecluster::V1beta::HypercomputeCluster::NewOnDemandInstancesConfig'->new($_) };

declare 'RepeatedNewOnDemandInstancesConfig',
    as ArrayRef[NewOnDemandInstancesConfig()];

coerce 'RepeatedNewOnDemandInstancesConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Hypercomputecluster::V1beta::HypercomputeCluster::NewOnDemandInstancesConfig'->new($_) } @$_ ] };

declare 'MapStringNewOnDemandInstancesConfig',
    as HashRef[NewOnDemandInstancesConfig()];

declare 'NewSpotInstancesConfig',
    as InstanceOf['Google::Cloud::Hypercomputecluster::V1beta::HypercomputeCluster::NewSpotInstancesConfig'];

coerce 'NewSpotInstancesConfig',
    from HashRef, via { 'Google::Cloud::Hypercomputecluster::V1beta::HypercomputeCluster::NewSpotInstancesConfig'->new($_) };

declare 'RepeatedNewSpotInstancesConfig',
    as ArrayRef[NewSpotInstancesConfig()];

coerce 'RepeatedNewSpotInstancesConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Hypercomputecluster::V1beta::HypercomputeCluster::NewSpotInstancesConfig'->new($_) } @$_ ] };

declare 'MapStringNewSpotInstancesConfig',
    as HashRef[NewSpotInstancesConfig()];

declare 'TerminationAction',
    as (Int | Str);

declare 'NewReservedInstancesConfig',
    as InstanceOf['Google::Cloud::Hypercomputecluster::V1beta::HypercomputeCluster::NewReservedInstancesConfig'];

coerce 'NewReservedInstancesConfig',
    from HashRef, via { 'Google::Cloud::Hypercomputecluster::V1beta::HypercomputeCluster::NewReservedInstancesConfig'->new($_) };

declare 'RepeatedNewReservedInstancesConfig',
    as ArrayRef[NewReservedInstancesConfig()];

coerce 'RepeatedNewReservedInstancesConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Hypercomputecluster::V1beta::HypercomputeCluster::NewReservedInstancesConfig'->new($_) } @$_ ] };

declare 'MapStringNewReservedInstancesConfig',
    as HashRef[NewReservedInstancesConfig()];

declare 'NewFlexStartInstancesConfig',
    as InstanceOf['Google::Cloud::Hypercomputecluster::V1beta::HypercomputeCluster::NewFlexStartInstancesConfig'];

coerce 'NewFlexStartInstancesConfig',
    from HashRef, via { 'Google::Cloud::Hypercomputecluster::V1beta::HypercomputeCluster::NewFlexStartInstancesConfig'->new($_) };

declare 'RepeatedNewFlexStartInstancesConfig',
    as ArrayRef[NewFlexStartInstancesConfig()];

coerce 'RepeatedNewFlexStartInstancesConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Hypercomputecluster::V1beta::HypercomputeCluster::NewFlexStartInstancesConfig'->new($_) } @$_ ] };

declare 'MapStringNewFlexStartInstancesConfig',
    as HashRef[NewFlexStartInstancesConfig()];

declare 'BootDisk',
    as InstanceOf['Google::Cloud::Hypercomputecluster::V1beta::HypercomputeCluster::BootDisk'];

coerce 'BootDisk',
    from HashRef, via { 'Google::Cloud::Hypercomputecluster::V1beta::HypercomputeCluster::BootDisk'->new($_) };

declare 'RepeatedBootDisk',
    as ArrayRef[BootDisk()];

coerce 'RepeatedBootDisk',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Hypercomputecluster::V1beta::HypercomputeCluster::BootDisk'->new($_) } @$_ ] };

declare 'MapStringBootDisk',
    as HashRef[BootDisk()];

declare 'Orchestrator',
    as InstanceOf['Google::Cloud::Hypercomputecluster::V1beta::HypercomputeCluster::Orchestrator'];

coerce 'Orchestrator',
    from HashRef, via { 'Google::Cloud::Hypercomputecluster::V1beta::HypercomputeCluster::Orchestrator'->new($_) };

declare 'RepeatedOrchestrator',
    as ArrayRef[Orchestrator()];

coerce 'RepeatedOrchestrator',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Hypercomputecluster::V1beta::HypercomputeCluster::Orchestrator'->new($_) } @$_ ] };

declare 'MapStringOrchestrator',
    as HashRef[Orchestrator()];

declare 'SlurmOrchestrator',
    as InstanceOf['Google::Cloud::Hypercomputecluster::V1beta::HypercomputeCluster::SlurmOrchestrator'];

coerce 'SlurmOrchestrator',
    from HashRef, via { 'Google::Cloud::Hypercomputecluster::V1beta::HypercomputeCluster::SlurmOrchestrator'->new($_) };

declare 'RepeatedSlurmOrchestrator',
    as ArrayRef[SlurmOrchestrator()];

coerce 'RepeatedSlurmOrchestrator',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Hypercomputecluster::V1beta::HypercomputeCluster::SlurmOrchestrator'->new($_) } @$_ ] };

declare 'MapStringSlurmOrchestrator',
    as HashRef[SlurmOrchestrator()];

declare 'SlurmNodeSet',
    as InstanceOf['Google::Cloud::Hypercomputecluster::V1beta::HypercomputeCluster::SlurmNodeSet'];

coerce 'SlurmNodeSet',
    from HashRef, via { 'Google::Cloud::Hypercomputecluster::V1beta::HypercomputeCluster::SlurmNodeSet'->new($_) };

declare 'RepeatedSlurmNodeSet',
    as ArrayRef[SlurmNodeSet()];

coerce 'RepeatedSlurmNodeSet',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Hypercomputecluster::V1beta::HypercomputeCluster::SlurmNodeSet'->new($_) } @$_ ] };

declare 'MapStringSlurmNodeSet',
    as HashRef[SlurmNodeSet()];

declare 'ComputeInstanceSlurmNodeSet',
    as InstanceOf['Google::Cloud::Hypercomputecluster::V1beta::HypercomputeCluster::ComputeInstanceSlurmNodeSet'];

coerce 'ComputeInstanceSlurmNodeSet',
    from HashRef, via { 'Google::Cloud::Hypercomputecluster::V1beta::HypercomputeCluster::ComputeInstanceSlurmNodeSet'->new($_) };

declare 'RepeatedComputeInstanceSlurmNodeSet',
    as ArrayRef[ComputeInstanceSlurmNodeSet()];

coerce 'RepeatedComputeInstanceSlurmNodeSet',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Hypercomputecluster::V1beta::HypercomputeCluster::ComputeInstanceSlurmNodeSet'->new($_) } @$_ ] };

declare 'MapStringComputeInstanceSlurmNodeSet',
    as HashRef[ComputeInstanceSlurmNodeSet()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Hypercomputecluster::V1beta::HypercomputeCluster::ComputeInstanceSlurmNodeSet::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Hypercomputecluster::V1beta::HypercomputeCluster::ComputeInstanceSlurmNodeSet::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Hypercomputecluster::V1beta::HypercomputeCluster::ComputeInstanceSlurmNodeSet::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'ResourcePolicyConfig',
    as InstanceOf['Google::Cloud::Hypercomputecluster::V1beta::HypercomputeCluster::ResourcePolicyConfig'];

coerce 'ResourcePolicyConfig',
    from HashRef, via { 'Google::Cloud::Hypercomputecluster::V1beta::HypercomputeCluster::ResourcePolicyConfig'->new($_) };

declare 'RepeatedResourcePolicyConfig',
    as ArrayRef[ResourcePolicyConfig()];

coerce 'RepeatedResourcePolicyConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Hypercomputecluster::V1beta::HypercomputeCluster::ResourcePolicyConfig'->new($_) } @$_ ] };

declare 'MapStringResourcePolicyConfig',
    as HashRef[ResourcePolicyConfig()];

declare 'SlurmPartition',
    as InstanceOf['Google::Cloud::Hypercomputecluster::V1beta::HypercomputeCluster::SlurmPartition'];

coerce 'SlurmPartition',
    from HashRef, via { 'Google::Cloud::Hypercomputecluster::V1beta::HypercomputeCluster::SlurmPartition'->new($_) };

declare 'RepeatedSlurmPartition',
    as ArrayRef[SlurmPartition()];

coerce 'RepeatedSlurmPartition',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Hypercomputecluster::V1beta::HypercomputeCluster::SlurmPartition'->new($_) } @$_ ] };

declare 'MapStringSlurmPartition',
    as HashRef[SlurmPartition()];

declare 'SlurmLoginNodes',
    as InstanceOf['Google::Cloud::Hypercomputecluster::V1beta::HypercomputeCluster::SlurmLoginNodes'];

coerce 'SlurmLoginNodes',
    from HashRef, via { 'Google::Cloud::Hypercomputecluster::V1beta::HypercomputeCluster::SlurmLoginNodes'->new($_) };

declare 'RepeatedSlurmLoginNodes',
    as ArrayRef[SlurmLoginNodes()];

coerce 'RepeatedSlurmLoginNodes',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Hypercomputecluster::V1beta::HypercomputeCluster::SlurmLoginNodes'->new($_) } @$_ ] };

declare 'MapStringSlurmLoginNodes',
    as HashRef[SlurmLoginNodes()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Hypercomputecluster::V1beta::HypercomputeCluster::SlurmLoginNodes::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Hypercomputecluster::V1beta::HypercomputeCluster::SlurmLoginNodes::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Hypercomputecluster::V1beta::HypercomputeCluster::SlurmLoginNodes::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'ServiceAccount',
    as InstanceOf['Google::Cloud::Hypercomputecluster::V1beta::HypercomputeCluster::ServiceAccount'];

coerce 'ServiceAccount',
    from HashRef, via { 'Google::Cloud::Hypercomputecluster::V1beta::HypercomputeCluster::ServiceAccount'->new($_) };

declare 'RepeatedServiceAccount',
    as ArrayRef[ServiceAccount()];

coerce 'RepeatedServiceAccount',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Hypercomputecluster::V1beta::HypercomputeCluster::ServiceAccount'->new($_) } @$_ ] };

declare 'MapStringServiceAccount',
    as HashRef[ServiceAccount()];

declare 'StorageConfig',
    as InstanceOf['Google::Cloud::Hypercomputecluster::V1beta::HypercomputeCluster::StorageConfig'];

coerce 'StorageConfig',
    from HashRef, via { 'Google::Cloud::Hypercomputecluster::V1beta::HypercomputeCluster::StorageConfig'->new($_) };

declare 'RepeatedStorageConfig',
    as ArrayRef[StorageConfig()];

coerce 'RepeatedStorageConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Hypercomputecluster::V1beta::HypercomputeCluster::StorageConfig'->new($_) } @$_ ] };

declare 'MapStringStorageConfig',
    as HashRef[StorageConfig()];

declare 'ComputeInstance',
    as InstanceOf['Google::Cloud::Hypercomputecluster::V1beta::HypercomputeCluster::ComputeInstance'];

coerce 'ComputeInstance',
    from HashRef, via { 'Google::Cloud::Hypercomputecluster::V1beta::HypercomputeCluster::ComputeInstance'->new($_) };

declare 'RepeatedComputeInstance',
    as ArrayRef[ComputeInstance()];

coerce 'RepeatedComputeInstance',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Hypercomputecluster::V1beta::HypercomputeCluster::ComputeInstance'->new($_) } @$_ ] };

declare 'MapStringComputeInstance',
    as HashRef[ComputeInstance()];

declare 'Node',
    as InstanceOf['Google::Cloud::Hypercomputecluster::V1beta::HypercomputeCluster::Node'];

coerce 'Node',
    from HashRef, via { 'Google::Cloud::Hypercomputecluster::V1beta::HypercomputeCluster::Node'->new($_) };

declare 'RepeatedNode',
    as ArrayRef[Node()];

coerce 'RepeatedNode',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Hypercomputecluster::V1beta::HypercomputeCluster::Node'->new($_) } @$_ ] };

declare 'MapStringNode',
    as HashRef[Node()];

declare 'State',
    as (Int | Str);

declare 'ProvisioningModel',
    as (Int | Str);

declare 'SlurmNodeDetails',
    as InstanceOf['Google::Cloud::Hypercomputecluster::V1beta::HypercomputeCluster::SlurmNodeDetails'];

coerce 'SlurmNodeDetails',
    from HashRef, via { 'Google::Cloud::Hypercomputecluster::V1beta::HypercomputeCluster::SlurmNodeDetails'->new($_) };

declare 'RepeatedSlurmNodeDetails',
    as ArrayRef[SlurmNodeDetails()];

coerce 'RepeatedSlurmNodeDetails',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Hypercomputecluster::V1beta::HypercomputeCluster::SlurmNodeDetails'->new($_) } @$_ ] };

declare 'MapStringSlurmNodeDetails',
    as HashRef[SlurmNodeDetails()];

declare 'ComputeEngineNodeDetails',
    as InstanceOf['Google::Cloud::Hypercomputecluster::V1beta::HypercomputeCluster::ComputeEngineNodeDetails'];

coerce 'ComputeEngineNodeDetails',
    from HashRef, via { 'Google::Cloud::Hypercomputecluster::V1beta::HypercomputeCluster::ComputeEngineNodeDetails'->new($_) };

declare 'RepeatedComputeEngineNodeDetails',
    as ArrayRef[ComputeEngineNodeDetails()];

coerce 'RepeatedComputeEngineNodeDetails',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Hypercomputecluster::V1beta::HypercomputeCluster::ComputeEngineNodeDetails'->new($_) } @$_ ] };

declare 'MapStringComputeEngineNodeDetails',
    as HashRef[ComputeEngineNodeDetails()];

declare 'ComputeEngineOrchestrator',
    as InstanceOf['Google::Cloud::Hypercomputecluster::V1beta::HypercomputeCluster::ComputeEngineOrchestrator'];

coerce 'ComputeEngineOrchestrator',
    from HashRef, via { 'Google::Cloud::Hypercomputecluster::V1beta::HypercomputeCluster::ComputeEngineOrchestrator'->new($_) };

declare 'RepeatedComputeEngineOrchestrator',
    as ArrayRef[ComputeEngineOrchestrator()];

coerce 'RepeatedComputeEngineOrchestrator',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Hypercomputecluster::V1beta::HypercomputeCluster::ComputeEngineOrchestrator'->new($_) } @$_ ] };

declare 'MapStringComputeEngineOrchestrator',
    as HashRef[ComputeEngineOrchestrator()];

declare 'ManagedInstanceGroupsEntry',
    as InstanceOf['Google::Cloud::Hypercomputecluster::V1beta::HypercomputeCluster::ComputeEngineOrchestrator::ManagedInstanceGroupsEntry'];

coerce 'ManagedInstanceGroupsEntry',
    from HashRef, via { 'Google::Cloud::Hypercomputecluster::V1beta::HypercomputeCluster::ComputeEngineOrchestrator::ManagedInstanceGroupsEntry'->new($_) };

declare 'RepeatedManagedInstanceGroupsEntry',
    as ArrayRef[ManagedInstanceGroupsEntry()];

coerce 'RepeatedManagedInstanceGroupsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Hypercomputecluster::V1beta::HypercomputeCluster::ComputeEngineOrchestrator::ManagedInstanceGroupsEntry'->new($_) } @$_ ] };

declare 'MapStringManagedInstanceGroupsEntry',
    as HashRef[ManagedInstanceGroupsEntry()];

declare 'ExistingInstancesEntry',
    as InstanceOf['Google::Cloud::Hypercomputecluster::V1beta::HypercomputeCluster::ComputeEngineOrchestrator::ExistingInstancesEntry'];

coerce 'ExistingInstancesEntry',
    from HashRef, via { 'Google::Cloud::Hypercomputecluster::V1beta::HypercomputeCluster::ComputeEngineOrchestrator::ExistingInstancesEntry'->new($_) };

declare 'RepeatedExistingInstancesEntry',
    as ArrayRef[ExistingInstancesEntry()];

coerce 'RepeatedExistingInstancesEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Hypercomputecluster::V1beta::HypercomputeCluster::ComputeEngineOrchestrator::ExistingInstancesEntry'->new($_) } @$_ ] };

declare 'MapStringExistingInstancesEntry',
    as HashRef[ExistingInstancesEntry()];

declare 'ManagedInstanceGroup',
    as InstanceOf['Google::Cloud::Hypercomputecluster::V1beta::HypercomputeCluster::ManagedInstanceGroup'];

coerce 'ManagedInstanceGroup',
    from HashRef, via { 'Google::Cloud::Hypercomputecluster::V1beta::HypercomputeCluster::ManagedInstanceGroup'->new($_) };

declare 'RepeatedManagedInstanceGroup',
    as ArrayRef[ManagedInstanceGroup()];

coerce 'RepeatedManagedInstanceGroup',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Hypercomputecluster::V1beta::HypercomputeCluster::ManagedInstanceGroup'->new($_) } @$_ ] };

declare 'MapStringManagedInstanceGroup',
    as HashRef[ManagedInstanceGroup()];

declare 'AdditionalDisksEntry',
    as InstanceOf['Google::Cloud::Hypercomputecluster::V1beta::HypercomputeCluster::ManagedInstanceGroup::AdditionalDisksEntry'];

coerce 'AdditionalDisksEntry',
    from HashRef, via { 'Google::Cloud::Hypercomputecluster::V1beta::HypercomputeCluster::ManagedInstanceGroup::AdditionalDisksEntry'->new($_) };

declare 'RepeatedAdditionalDisksEntry',
    as ArrayRef[AdditionalDisksEntry()];

coerce 'RepeatedAdditionalDisksEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Hypercomputecluster::V1beta::HypercomputeCluster::ManagedInstanceGroup::AdditionalDisksEntry'->new($_) } @$_ ] };

declare 'MapStringAdditionalDisksEntry',
    as HashRef[AdditionalDisksEntry()];

declare 'MetadataEntry',
    as InstanceOf['Google::Cloud::Hypercomputecluster::V1beta::HypercomputeCluster::ManagedInstanceGroup::MetadataEntry'];

coerce 'MetadataEntry',
    from HashRef, via { 'Google::Cloud::Hypercomputecluster::V1beta::HypercomputeCluster::ManagedInstanceGroup::MetadataEntry'->new($_) };

declare 'RepeatedMetadataEntry',
    as ArrayRef[MetadataEntry()];

coerce 'RepeatedMetadataEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Hypercomputecluster::V1beta::HypercomputeCluster::ManagedInstanceGroup::MetadataEntry'->new($_) } @$_ ] };

declare 'MapStringMetadataEntry',
    as HashRef[MetadataEntry()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Hypercomputecluster::V1beta::HypercomputeCluster::ManagedInstanceGroup::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Hypercomputecluster::V1beta::HypercomputeCluster::ManagedInstanceGroup::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Hypercomputecluster::V1beta::HypercomputeCluster::ManagedInstanceGroup::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'Disk',
    as InstanceOf['Google::Cloud::Hypercomputecluster::V1beta::HypercomputeCluster::Disk'];

coerce 'Disk',
    from HashRef, via { 'Google::Cloud::Hypercomputecluster::V1beta::HypercomputeCluster::Disk'->new($_) };

declare 'RepeatedDisk',
    as ArrayRef[Disk()];

coerce 'RepeatedDisk',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Hypercomputecluster::V1beta::HypercomputeCluster::Disk'->new($_) } @$_ ] };

declare 'MapStringDisk',
    as HashRef[Disk()];

declare 'ExistingInstances',
    as InstanceOf['Google::Cloud::Hypercomputecluster::V1beta::HypercomputeCluster::ExistingInstances'];

coerce 'ExistingInstances',
    from HashRef, via { 'Google::Cloud::Hypercomputecluster::V1beta::HypercomputeCluster::ExistingInstances'->new($_) };

declare 'RepeatedExistingInstances',
    as ArrayRef[ExistingInstances()];

coerce 'RepeatedExistingInstances',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Hypercomputecluster::V1beta::HypercomputeCluster::ExistingInstances'->new($_) } @$_ ] };

declare 'MapStringExistingInstances',
    as HashRef[ExistingInstances()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Hypercomputecluster::V1beta::HypercomputeCluster::ExistingInstances::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Hypercomputecluster::V1beta::HypercomputeCluster::ExistingInstances::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Hypercomputecluster::V1beta::HypercomputeCluster::ExistingInstances::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

1;

__END__

=head1 NAME

Google::Cloud::Hypercomputecluster::V1beta::HypercomputeCluster::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
