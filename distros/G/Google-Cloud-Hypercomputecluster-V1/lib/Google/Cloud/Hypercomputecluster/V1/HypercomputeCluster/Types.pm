package Google::Cloud::Hypercomputecluster::V1::HypercomputeCluster::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Cluster',
    as InstanceOf['Google::Cloud::Hypercomputecluster::V1::HypercomputeCluster::Cluster'];

coerce 'Cluster',
    from HashRef, via { 'Google::Cloud::Hypercomputecluster::V1::HypercomputeCluster::Cluster'->new($_) };

declare 'RepeatedCluster',
    as ArrayRef[Cluster()];

coerce 'RepeatedCluster',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Hypercomputecluster::V1::HypercomputeCluster::Cluster'->new($_) } @$_ ] };

declare 'MapStringCluster',
    as HashRef[Cluster()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Hypercomputecluster::V1::HypercomputeCluster::Cluster::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Hypercomputecluster::V1::HypercomputeCluster::Cluster::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Hypercomputecluster::V1::HypercomputeCluster::Cluster::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'NetworkResourcesEntry',
    as InstanceOf['Google::Cloud::Hypercomputecluster::V1::HypercomputeCluster::Cluster::NetworkResourcesEntry'];

coerce 'NetworkResourcesEntry',
    from HashRef, via { 'Google::Cloud::Hypercomputecluster::V1::HypercomputeCluster::Cluster::NetworkResourcesEntry'->new($_) };

declare 'RepeatedNetworkResourcesEntry',
    as ArrayRef[NetworkResourcesEntry()];

coerce 'RepeatedNetworkResourcesEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Hypercomputecluster::V1::HypercomputeCluster::Cluster::NetworkResourcesEntry'->new($_) } @$_ ] };

declare 'MapStringNetworkResourcesEntry',
    as HashRef[NetworkResourcesEntry()];

declare 'StorageResourcesEntry',
    as InstanceOf['Google::Cloud::Hypercomputecluster::V1::HypercomputeCluster::Cluster::StorageResourcesEntry'];

coerce 'StorageResourcesEntry',
    from HashRef, via { 'Google::Cloud::Hypercomputecluster::V1::HypercomputeCluster::Cluster::StorageResourcesEntry'->new($_) };

declare 'RepeatedStorageResourcesEntry',
    as ArrayRef[StorageResourcesEntry()];

coerce 'RepeatedStorageResourcesEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Hypercomputecluster::V1::HypercomputeCluster::Cluster::StorageResourcesEntry'->new($_) } @$_ ] };

declare 'MapStringStorageResourcesEntry',
    as HashRef[StorageResourcesEntry()];

declare 'ComputeResourcesEntry',
    as InstanceOf['Google::Cloud::Hypercomputecluster::V1::HypercomputeCluster::Cluster::ComputeResourcesEntry'];

coerce 'ComputeResourcesEntry',
    from HashRef, via { 'Google::Cloud::Hypercomputecluster::V1::HypercomputeCluster::Cluster::ComputeResourcesEntry'->new($_) };

declare 'RepeatedComputeResourcesEntry',
    as ArrayRef[ComputeResourcesEntry()];

coerce 'RepeatedComputeResourcesEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Hypercomputecluster::V1::HypercomputeCluster::Cluster::ComputeResourcesEntry'->new($_) } @$_ ] };

declare 'MapStringComputeResourcesEntry',
    as HashRef[ComputeResourcesEntry()];

declare 'ListClustersRequest',
    as InstanceOf['Google::Cloud::Hypercomputecluster::V1::HypercomputeCluster::ListClustersRequest'];

coerce 'ListClustersRequest',
    from HashRef, via { 'Google::Cloud::Hypercomputecluster::V1::HypercomputeCluster::ListClustersRequest'->new($_) };

declare 'RepeatedListClustersRequest',
    as ArrayRef[ListClustersRequest()];

coerce 'RepeatedListClustersRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Hypercomputecluster::V1::HypercomputeCluster::ListClustersRequest'->new($_) } @$_ ] };

declare 'MapStringListClustersRequest',
    as HashRef[ListClustersRequest()];

declare 'ListClustersResponse',
    as InstanceOf['Google::Cloud::Hypercomputecluster::V1::HypercomputeCluster::ListClustersResponse'];

coerce 'ListClustersResponse',
    from HashRef, via { 'Google::Cloud::Hypercomputecluster::V1::HypercomputeCluster::ListClustersResponse'->new($_) };

declare 'RepeatedListClustersResponse',
    as ArrayRef[ListClustersResponse()];

coerce 'RepeatedListClustersResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Hypercomputecluster::V1::HypercomputeCluster::ListClustersResponse'->new($_) } @$_ ] };

declare 'MapStringListClustersResponse',
    as HashRef[ListClustersResponse()];

declare 'GetClusterRequest',
    as InstanceOf['Google::Cloud::Hypercomputecluster::V1::HypercomputeCluster::GetClusterRequest'];

coerce 'GetClusterRequest',
    from HashRef, via { 'Google::Cloud::Hypercomputecluster::V1::HypercomputeCluster::GetClusterRequest'->new($_) };

declare 'RepeatedGetClusterRequest',
    as ArrayRef[GetClusterRequest()];

coerce 'RepeatedGetClusterRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Hypercomputecluster::V1::HypercomputeCluster::GetClusterRequest'->new($_) } @$_ ] };

declare 'MapStringGetClusterRequest',
    as HashRef[GetClusterRequest()];

declare 'CreateClusterRequest',
    as InstanceOf['Google::Cloud::Hypercomputecluster::V1::HypercomputeCluster::CreateClusterRequest'];

coerce 'CreateClusterRequest',
    from HashRef, via { 'Google::Cloud::Hypercomputecluster::V1::HypercomputeCluster::CreateClusterRequest'->new($_) };

declare 'RepeatedCreateClusterRequest',
    as ArrayRef[CreateClusterRequest()];

coerce 'RepeatedCreateClusterRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Hypercomputecluster::V1::HypercomputeCluster::CreateClusterRequest'->new($_) } @$_ ] };

declare 'MapStringCreateClusterRequest',
    as HashRef[CreateClusterRequest()];

declare 'UpdateClusterRequest',
    as InstanceOf['Google::Cloud::Hypercomputecluster::V1::HypercomputeCluster::UpdateClusterRequest'];

coerce 'UpdateClusterRequest',
    from HashRef, via { 'Google::Cloud::Hypercomputecluster::V1::HypercomputeCluster::UpdateClusterRequest'->new($_) };

declare 'RepeatedUpdateClusterRequest',
    as ArrayRef[UpdateClusterRequest()];

coerce 'RepeatedUpdateClusterRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Hypercomputecluster::V1::HypercomputeCluster::UpdateClusterRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateClusterRequest',
    as HashRef[UpdateClusterRequest()];

declare 'DeleteClusterRequest',
    as InstanceOf['Google::Cloud::Hypercomputecluster::V1::HypercomputeCluster::DeleteClusterRequest'];

coerce 'DeleteClusterRequest',
    from HashRef, via { 'Google::Cloud::Hypercomputecluster::V1::HypercomputeCluster::DeleteClusterRequest'->new($_) };

declare 'RepeatedDeleteClusterRequest',
    as ArrayRef[DeleteClusterRequest()];

coerce 'RepeatedDeleteClusterRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Hypercomputecluster::V1::HypercomputeCluster::DeleteClusterRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteClusterRequest',
    as HashRef[DeleteClusterRequest()];

declare 'NetworkResource',
    as InstanceOf['Google::Cloud::Hypercomputecluster::V1::HypercomputeCluster::NetworkResource'];

coerce 'NetworkResource',
    from HashRef, via { 'Google::Cloud::Hypercomputecluster::V1::HypercomputeCluster::NetworkResource'->new($_) };

declare 'RepeatedNetworkResource',
    as ArrayRef[NetworkResource()];

coerce 'RepeatedNetworkResource',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Hypercomputecluster::V1::HypercomputeCluster::NetworkResource'->new($_) } @$_ ] };

declare 'MapStringNetworkResource',
    as HashRef[NetworkResource()];

declare 'NetworkReference',
    as InstanceOf['Google::Cloud::Hypercomputecluster::V1::HypercomputeCluster::NetworkReference'];

coerce 'NetworkReference',
    from HashRef, via { 'Google::Cloud::Hypercomputecluster::V1::HypercomputeCluster::NetworkReference'->new($_) };

declare 'RepeatedNetworkReference',
    as ArrayRef[NetworkReference()];

coerce 'RepeatedNetworkReference',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Hypercomputecluster::V1::HypercomputeCluster::NetworkReference'->new($_) } @$_ ] };

declare 'MapStringNetworkReference',
    as HashRef[NetworkReference()];

declare 'NetworkResourceConfig',
    as InstanceOf['Google::Cloud::Hypercomputecluster::V1::HypercomputeCluster::NetworkResourceConfig'];

coerce 'NetworkResourceConfig',
    from HashRef, via { 'Google::Cloud::Hypercomputecluster::V1::HypercomputeCluster::NetworkResourceConfig'->new($_) };

declare 'RepeatedNetworkResourceConfig',
    as ArrayRef[NetworkResourceConfig()];

coerce 'RepeatedNetworkResourceConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Hypercomputecluster::V1::HypercomputeCluster::NetworkResourceConfig'->new($_) } @$_ ] };

declare 'MapStringNetworkResourceConfig',
    as HashRef[NetworkResourceConfig()];

declare 'NewNetworkConfig',
    as InstanceOf['Google::Cloud::Hypercomputecluster::V1::HypercomputeCluster::NewNetworkConfig'];

coerce 'NewNetworkConfig',
    from HashRef, via { 'Google::Cloud::Hypercomputecluster::V1::HypercomputeCluster::NewNetworkConfig'->new($_) };

declare 'RepeatedNewNetworkConfig',
    as ArrayRef[NewNetworkConfig()];

coerce 'RepeatedNewNetworkConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Hypercomputecluster::V1::HypercomputeCluster::NewNetworkConfig'->new($_) } @$_ ] };

declare 'MapStringNewNetworkConfig',
    as HashRef[NewNetworkConfig()];

declare 'ExistingNetworkConfig',
    as InstanceOf['Google::Cloud::Hypercomputecluster::V1::HypercomputeCluster::ExistingNetworkConfig'];

coerce 'ExistingNetworkConfig',
    from HashRef, via { 'Google::Cloud::Hypercomputecluster::V1::HypercomputeCluster::ExistingNetworkConfig'->new($_) };

declare 'RepeatedExistingNetworkConfig',
    as ArrayRef[ExistingNetworkConfig()];

coerce 'RepeatedExistingNetworkConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Hypercomputecluster::V1::HypercomputeCluster::ExistingNetworkConfig'->new($_) } @$_ ] };

declare 'MapStringExistingNetworkConfig',
    as HashRef[ExistingNetworkConfig()];

declare 'StorageResource',
    as InstanceOf['Google::Cloud::Hypercomputecluster::V1::HypercomputeCluster::StorageResource'];

coerce 'StorageResource',
    from HashRef, via { 'Google::Cloud::Hypercomputecluster::V1::HypercomputeCluster::StorageResource'->new($_) };

declare 'RepeatedStorageResource',
    as ArrayRef[StorageResource()];

coerce 'RepeatedStorageResource',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Hypercomputecluster::V1::HypercomputeCluster::StorageResource'->new($_) } @$_ ] };

declare 'MapStringStorageResource',
    as HashRef[StorageResource()];

declare 'FilestoreReference',
    as InstanceOf['Google::Cloud::Hypercomputecluster::V1::HypercomputeCluster::FilestoreReference'];

coerce 'FilestoreReference',
    from HashRef, via { 'Google::Cloud::Hypercomputecluster::V1::HypercomputeCluster::FilestoreReference'->new($_) };

declare 'RepeatedFilestoreReference',
    as ArrayRef[FilestoreReference()];

coerce 'RepeatedFilestoreReference',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Hypercomputecluster::V1::HypercomputeCluster::FilestoreReference'->new($_) } @$_ ] };

declare 'MapStringFilestoreReference',
    as HashRef[FilestoreReference()];

declare 'BucketReference',
    as InstanceOf['Google::Cloud::Hypercomputecluster::V1::HypercomputeCluster::BucketReference'];

coerce 'BucketReference',
    from HashRef, via { 'Google::Cloud::Hypercomputecluster::V1::HypercomputeCluster::BucketReference'->new($_) };

declare 'RepeatedBucketReference',
    as ArrayRef[BucketReference()];

coerce 'RepeatedBucketReference',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Hypercomputecluster::V1::HypercomputeCluster::BucketReference'->new($_) } @$_ ] };

declare 'MapStringBucketReference',
    as HashRef[BucketReference()];

declare 'LustreReference',
    as InstanceOf['Google::Cloud::Hypercomputecluster::V1::HypercomputeCluster::LustreReference'];

coerce 'LustreReference',
    from HashRef, via { 'Google::Cloud::Hypercomputecluster::V1::HypercomputeCluster::LustreReference'->new($_) };

declare 'RepeatedLustreReference',
    as ArrayRef[LustreReference()];

coerce 'RepeatedLustreReference',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Hypercomputecluster::V1::HypercomputeCluster::LustreReference'->new($_) } @$_ ] };

declare 'MapStringLustreReference',
    as HashRef[LustreReference()];

declare 'StorageResourceConfig',
    as InstanceOf['Google::Cloud::Hypercomputecluster::V1::HypercomputeCluster::StorageResourceConfig'];

coerce 'StorageResourceConfig',
    from HashRef, via { 'Google::Cloud::Hypercomputecluster::V1::HypercomputeCluster::StorageResourceConfig'->new($_) };

declare 'RepeatedStorageResourceConfig',
    as ArrayRef[StorageResourceConfig()];

coerce 'RepeatedStorageResourceConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Hypercomputecluster::V1::HypercomputeCluster::StorageResourceConfig'->new($_) } @$_ ] };

declare 'MapStringStorageResourceConfig',
    as HashRef[StorageResourceConfig()];

declare 'NewFilestoreConfig',
    as InstanceOf['Google::Cloud::Hypercomputecluster::V1::HypercomputeCluster::NewFilestoreConfig'];

coerce 'NewFilestoreConfig',
    from HashRef, via { 'Google::Cloud::Hypercomputecluster::V1::HypercomputeCluster::NewFilestoreConfig'->new($_) };

declare 'RepeatedNewFilestoreConfig',
    as ArrayRef[NewFilestoreConfig()];

coerce 'RepeatedNewFilestoreConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Hypercomputecluster::V1::HypercomputeCluster::NewFilestoreConfig'->new($_) } @$_ ] };

declare 'MapStringNewFilestoreConfig',
    as HashRef[NewFilestoreConfig()];

declare 'Tier',
    as (Int | Str);

declare 'Protocol',
    as (Int | Str);

declare 'FileShareConfig',
    as InstanceOf['Google::Cloud::Hypercomputecluster::V1::HypercomputeCluster::FileShareConfig'];

coerce 'FileShareConfig',
    from HashRef, via { 'Google::Cloud::Hypercomputecluster::V1::HypercomputeCluster::FileShareConfig'->new($_) };

declare 'RepeatedFileShareConfig',
    as ArrayRef[FileShareConfig()];

coerce 'RepeatedFileShareConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Hypercomputecluster::V1::HypercomputeCluster::FileShareConfig'->new($_) } @$_ ] };

declare 'MapStringFileShareConfig',
    as HashRef[FileShareConfig()];

declare 'ExistingFilestoreConfig',
    as InstanceOf['Google::Cloud::Hypercomputecluster::V1::HypercomputeCluster::ExistingFilestoreConfig'];

coerce 'ExistingFilestoreConfig',
    from HashRef, via { 'Google::Cloud::Hypercomputecluster::V1::HypercomputeCluster::ExistingFilestoreConfig'->new($_) };

declare 'RepeatedExistingFilestoreConfig',
    as ArrayRef[ExistingFilestoreConfig()];

coerce 'RepeatedExistingFilestoreConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Hypercomputecluster::V1::HypercomputeCluster::ExistingFilestoreConfig'->new($_) } @$_ ] };

declare 'MapStringExistingFilestoreConfig',
    as HashRef[ExistingFilestoreConfig()];

declare 'NewBucketConfig',
    as InstanceOf['Google::Cloud::Hypercomputecluster::V1::HypercomputeCluster::NewBucketConfig'];

coerce 'NewBucketConfig',
    from HashRef, via { 'Google::Cloud::Hypercomputecluster::V1::HypercomputeCluster::NewBucketConfig'->new($_) };

declare 'RepeatedNewBucketConfig',
    as ArrayRef[NewBucketConfig()];

coerce 'RepeatedNewBucketConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Hypercomputecluster::V1::HypercomputeCluster::NewBucketConfig'->new($_) } @$_ ] };

declare 'MapStringNewBucketConfig',
    as HashRef[NewBucketConfig()];

declare 'StorageClass',
    as (Int | Str);

declare 'GcsAutoclassConfig',
    as InstanceOf['Google::Cloud::Hypercomputecluster::V1::HypercomputeCluster::GcsAutoclassConfig'];

coerce 'GcsAutoclassConfig',
    from HashRef, via { 'Google::Cloud::Hypercomputecluster::V1::HypercomputeCluster::GcsAutoclassConfig'->new($_) };

declare 'RepeatedGcsAutoclassConfig',
    as ArrayRef[GcsAutoclassConfig()];

coerce 'RepeatedGcsAutoclassConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Hypercomputecluster::V1::HypercomputeCluster::GcsAutoclassConfig'->new($_) } @$_ ] };

declare 'MapStringGcsAutoclassConfig',
    as HashRef[GcsAutoclassConfig()];

declare 'TerminalStorageClass',
    as (Int | Str);

declare 'GcsHierarchicalNamespaceConfig',
    as InstanceOf['Google::Cloud::Hypercomputecluster::V1::HypercomputeCluster::GcsHierarchicalNamespaceConfig'];

coerce 'GcsHierarchicalNamespaceConfig',
    from HashRef, via { 'Google::Cloud::Hypercomputecluster::V1::HypercomputeCluster::GcsHierarchicalNamespaceConfig'->new($_) };

declare 'RepeatedGcsHierarchicalNamespaceConfig',
    as ArrayRef[GcsHierarchicalNamespaceConfig()];

coerce 'RepeatedGcsHierarchicalNamespaceConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Hypercomputecluster::V1::HypercomputeCluster::GcsHierarchicalNamespaceConfig'->new($_) } @$_ ] };

declare 'MapStringGcsHierarchicalNamespaceConfig',
    as HashRef[GcsHierarchicalNamespaceConfig()];

declare 'ExistingBucketConfig',
    as InstanceOf['Google::Cloud::Hypercomputecluster::V1::HypercomputeCluster::ExistingBucketConfig'];

coerce 'ExistingBucketConfig',
    from HashRef, via { 'Google::Cloud::Hypercomputecluster::V1::HypercomputeCluster::ExistingBucketConfig'->new($_) };

declare 'RepeatedExistingBucketConfig',
    as ArrayRef[ExistingBucketConfig()];

coerce 'RepeatedExistingBucketConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Hypercomputecluster::V1::HypercomputeCluster::ExistingBucketConfig'->new($_) } @$_ ] };

declare 'MapStringExistingBucketConfig',
    as HashRef[ExistingBucketConfig()];

declare 'NewLustreConfig',
    as InstanceOf['Google::Cloud::Hypercomputecluster::V1::HypercomputeCluster::NewLustreConfig'];

coerce 'NewLustreConfig',
    from HashRef, via { 'Google::Cloud::Hypercomputecluster::V1::HypercomputeCluster::NewLustreConfig'->new($_) };

declare 'RepeatedNewLustreConfig',
    as ArrayRef[NewLustreConfig()];

coerce 'RepeatedNewLustreConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Hypercomputecluster::V1::HypercomputeCluster::NewLustreConfig'->new($_) } @$_ ] };

declare 'MapStringNewLustreConfig',
    as HashRef[NewLustreConfig()];

declare 'ExistingLustreConfig',
    as InstanceOf['Google::Cloud::Hypercomputecluster::V1::HypercomputeCluster::ExistingLustreConfig'];

coerce 'ExistingLustreConfig',
    from HashRef, via { 'Google::Cloud::Hypercomputecluster::V1::HypercomputeCluster::ExistingLustreConfig'->new($_) };

declare 'RepeatedExistingLustreConfig',
    as ArrayRef[ExistingLustreConfig()];

coerce 'RepeatedExistingLustreConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Hypercomputecluster::V1::HypercomputeCluster::ExistingLustreConfig'->new($_) } @$_ ] };

declare 'MapStringExistingLustreConfig',
    as HashRef[ExistingLustreConfig()];

declare 'ComputeResource',
    as InstanceOf['Google::Cloud::Hypercomputecluster::V1::HypercomputeCluster::ComputeResource'];

coerce 'ComputeResource',
    from HashRef, via { 'Google::Cloud::Hypercomputecluster::V1::HypercomputeCluster::ComputeResource'->new($_) };

declare 'RepeatedComputeResource',
    as ArrayRef[ComputeResource()];

coerce 'RepeatedComputeResource',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Hypercomputecluster::V1::HypercomputeCluster::ComputeResource'->new($_) } @$_ ] };

declare 'MapStringComputeResource',
    as HashRef[ComputeResource()];

declare 'ComputeResourceConfig',
    as InstanceOf['Google::Cloud::Hypercomputecluster::V1::HypercomputeCluster::ComputeResourceConfig'];

coerce 'ComputeResourceConfig',
    from HashRef, via { 'Google::Cloud::Hypercomputecluster::V1::HypercomputeCluster::ComputeResourceConfig'->new($_) };

declare 'RepeatedComputeResourceConfig',
    as ArrayRef[ComputeResourceConfig()];

coerce 'RepeatedComputeResourceConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Hypercomputecluster::V1::HypercomputeCluster::ComputeResourceConfig'->new($_) } @$_ ] };

declare 'MapStringComputeResourceConfig',
    as HashRef[ComputeResourceConfig()];

declare 'NewOnDemandInstancesConfig',
    as InstanceOf['Google::Cloud::Hypercomputecluster::V1::HypercomputeCluster::NewOnDemandInstancesConfig'];

coerce 'NewOnDemandInstancesConfig',
    from HashRef, via { 'Google::Cloud::Hypercomputecluster::V1::HypercomputeCluster::NewOnDemandInstancesConfig'->new($_) };

declare 'RepeatedNewOnDemandInstancesConfig',
    as ArrayRef[NewOnDemandInstancesConfig()];

coerce 'RepeatedNewOnDemandInstancesConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Hypercomputecluster::V1::HypercomputeCluster::NewOnDemandInstancesConfig'->new($_) } @$_ ] };

declare 'MapStringNewOnDemandInstancesConfig',
    as HashRef[NewOnDemandInstancesConfig()];

declare 'NewSpotInstancesConfig',
    as InstanceOf['Google::Cloud::Hypercomputecluster::V1::HypercomputeCluster::NewSpotInstancesConfig'];

coerce 'NewSpotInstancesConfig',
    from HashRef, via { 'Google::Cloud::Hypercomputecluster::V1::HypercomputeCluster::NewSpotInstancesConfig'->new($_) };

declare 'RepeatedNewSpotInstancesConfig',
    as ArrayRef[NewSpotInstancesConfig()];

coerce 'RepeatedNewSpotInstancesConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Hypercomputecluster::V1::HypercomputeCluster::NewSpotInstancesConfig'->new($_) } @$_ ] };

declare 'MapStringNewSpotInstancesConfig',
    as HashRef[NewSpotInstancesConfig()];

declare 'TerminationAction',
    as (Int | Str);

declare 'NewReservedInstancesConfig',
    as InstanceOf['Google::Cloud::Hypercomputecluster::V1::HypercomputeCluster::NewReservedInstancesConfig'];

coerce 'NewReservedInstancesConfig',
    from HashRef, via { 'Google::Cloud::Hypercomputecluster::V1::HypercomputeCluster::NewReservedInstancesConfig'->new($_) };

declare 'RepeatedNewReservedInstancesConfig',
    as ArrayRef[NewReservedInstancesConfig()];

coerce 'RepeatedNewReservedInstancesConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Hypercomputecluster::V1::HypercomputeCluster::NewReservedInstancesConfig'->new($_) } @$_ ] };

declare 'MapStringNewReservedInstancesConfig',
    as HashRef[NewReservedInstancesConfig()];

declare 'NewFlexStartInstancesConfig',
    as InstanceOf['Google::Cloud::Hypercomputecluster::V1::HypercomputeCluster::NewFlexStartInstancesConfig'];

coerce 'NewFlexStartInstancesConfig',
    from HashRef, via { 'Google::Cloud::Hypercomputecluster::V1::HypercomputeCluster::NewFlexStartInstancesConfig'->new($_) };

declare 'RepeatedNewFlexStartInstancesConfig',
    as ArrayRef[NewFlexStartInstancesConfig()];

coerce 'RepeatedNewFlexStartInstancesConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Hypercomputecluster::V1::HypercomputeCluster::NewFlexStartInstancesConfig'->new($_) } @$_ ] };

declare 'MapStringNewFlexStartInstancesConfig',
    as HashRef[NewFlexStartInstancesConfig()];

declare 'BootDisk',
    as InstanceOf['Google::Cloud::Hypercomputecluster::V1::HypercomputeCluster::BootDisk'];

coerce 'BootDisk',
    from HashRef, via { 'Google::Cloud::Hypercomputecluster::V1::HypercomputeCluster::BootDisk'->new($_) };

declare 'RepeatedBootDisk',
    as ArrayRef[BootDisk()];

coerce 'RepeatedBootDisk',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Hypercomputecluster::V1::HypercomputeCluster::BootDisk'->new($_) } @$_ ] };

declare 'MapStringBootDisk',
    as HashRef[BootDisk()];

declare 'Orchestrator',
    as InstanceOf['Google::Cloud::Hypercomputecluster::V1::HypercomputeCluster::Orchestrator'];

coerce 'Orchestrator',
    from HashRef, via { 'Google::Cloud::Hypercomputecluster::V1::HypercomputeCluster::Orchestrator'->new($_) };

declare 'RepeatedOrchestrator',
    as ArrayRef[Orchestrator()];

coerce 'RepeatedOrchestrator',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Hypercomputecluster::V1::HypercomputeCluster::Orchestrator'->new($_) } @$_ ] };

declare 'MapStringOrchestrator',
    as HashRef[Orchestrator()];

declare 'SlurmOrchestrator',
    as InstanceOf['Google::Cloud::Hypercomputecluster::V1::HypercomputeCluster::SlurmOrchestrator'];

coerce 'SlurmOrchestrator',
    from HashRef, via { 'Google::Cloud::Hypercomputecluster::V1::HypercomputeCluster::SlurmOrchestrator'->new($_) };

declare 'RepeatedSlurmOrchestrator',
    as ArrayRef[SlurmOrchestrator()];

coerce 'RepeatedSlurmOrchestrator',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Hypercomputecluster::V1::HypercomputeCluster::SlurmOrchestrator'->new($_) } @$_ ] };

declare 'MapStringSlurmOrchestrator',
    as HashRef[SlurmOrchestrator()];

declare 'SlurmNodeSet',
    as InstanceOf['Google::Cloud::Hypercomputecluster::V1::HypercomputeCluster::SlurmNodeSet'];

coerce 'SlurmNodeSet',
    from HashRef, via { 'Google::Cloud::Hypercomputecluster::V1::HypercomputeCluster::SlurmNodeSet'->new($_) };

declare 'RepeatedSlurmNodeSet',
    as ArrayRef[SlurmNodeSet()];

coerce 'RepeatedSlurmNodeSet',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Hypercomputecluster::V1::HypercomputeCluster::SlurmNodeSet'->new($_) } @$_ ] };

declare 'MapStringSlurmNodeSet',
    as HashRef[SlurmNodeSet()];

declare 'ComputeInstanceSlurmNodeSet',
    as InstanceOf['Google::Cloud::Hypercomputecluster::V1::HypercomputeCluster::ComputeInstanceSlurmNodeSet'];

coerce 'ComputeInstanceSlurmNodeSet',
    from HashRef, via { 'Google::Cloud::Hypercomputecluster::V1::HypercomputeCluster::ComputeInstanceSlurmNodeSet'->new($_) };

declare 'RepeatedComputeInstanceSlurmNodeSet',
    as ArrayRef[ComputeInstanceSlurmNodeSet()];

coerce 'RepeatedComputeInstanceSlurmNodeSet',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Hypercomputecluster::V1::HypercomputeCluster::ComputeInstanceSlurmNodeSet'->new($_) } @$_ ] };

declare 'MapStringComputeInstanceSlurmNodeSet',
    as HashRef[ComputeInstanceSlurmNodeSet()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Hypercomputecluster::V1::HypercomputeCluster::ComputeInstanceSlurmNodeSet::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Hypercomputecluster::V1::HypercomputeCluster::ComputeInstanceSlurmNodeSet::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Hypercomputecluster::V1::HypercomputeCluster::ComputeInstanceSlurmNodeSet::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'SlurmPartition',
    as InstanceOf['Google::Cloud::Hypercomputecluster::V1::HypercomputeCluster::SlurmPartition'];

coerce 'SlurmPartition',
    from HashRef, via { 'Google::Cloud::Hypercomputecluster::V1::HypercomputeCluster::SlurmPartition'->new($_) };

declare 'RepeatedSlurmPartition',
    as ArrayRef[SlurmPartition()];

coerce 'RepeatedSlurmPartition',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Hypercomputecluster::V1::HypercomputeCluster::SlurmPartition'->new($_) } @$_ ] };

declare 'MapStringSlurmPartition',
    as HashRef[SlurmPartition()];

declare 'SlurmLoginNodes',
    as InstanceOf['Google::Cloud::Hypercomputecluster::V1::HypercomputeCluster::SlurmLoginNodes'];

coerce 'SlurmLoginNodes',
    from HashRef, via { 'Google::Cloud::Hypercomputecluster::V1::HypercomputeCluster::SlurmLoginNodes'->new($_) };

declare 'RepeatedSlurmLoginNodes',
    as ArrayRef[SlurmLoginNodes()];

coerce 'RepeatedSlurmLoginNodes',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Hypercomputecluster::V1::HypercomputeCluster::SlurmLoginNodes'->new($_) } @$_ ] };

declare 'MapStringSlurmLoginNodes',
    as HashRef[SlurmLoginNodes()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Hypercomputecluster::V1::HypercomputeCluster::SlurmLoginNodes::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Hypercomputecluster::V1::HypercomputeCluster::SlurmLoginNodes::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Hypercomputecluster::V1::HypercomputeCluster::SlurmLoginNodes::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'StorageConfig',
    as InstanceOf['Google::Cloud::Hypercomputecluster::V1::HypercomputeCluster::StorageConfig'];

coerce 'StorageConfig',
    from HashRef, via { 'Google::Cloud::Hypercomputecluster::V1::HypercomputeCluster::StorageConfig'->new($_) };

declare 'RepeatedStorageConfig',
    as ArrayRef[StorageConfig()];

coerce 'RepeatedStorageConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Hypercomputecluster::V1::HypercomputeCluster::StorageConfig'->new($_) } @$_ ] };

declare 'MapStringStorageConfig',
    as HashRef[StorageConfig()];

declare 'ComputeInstance',
    as InstanceOf['Google::Cloud::Hypercomputecluster::V1::HypercomputeCluster::ComputeInstance'];

coerce 'ComputeInstance',
    from HashRef, via { 'Google::Cloud::Hypercomputecluster::V1::HypercomputeCluster::ComputeInstance'->new($_) };

declare 'RepeatedComputeInstance',
    as ArrayRef[ComputeInstance()];

coerce 'RepeatedComputeInstance',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Hypercomputecluster::V1::HypercomputeCluster::ComputeInstance'->new($_) } @$_ ] };

declare 'MapStringComputeInstance',
    as HashRef[ComputeInstance()];

1;

__END__

=head1 NAME

Google::Cloud::Hypercomputecluster::V1::HypercomputeCluster::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
