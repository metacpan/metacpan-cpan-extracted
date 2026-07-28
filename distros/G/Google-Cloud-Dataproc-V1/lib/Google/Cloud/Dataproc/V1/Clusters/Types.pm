package Google::Cloud::Dataproc::V1::Clusters::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Cluster',
    as InstanceOf['Google::Cloud::Dataproc::V1::Clusters::Cluster'];

coerce 'Cluster',
    from HashRef, via { 'Google::Cloud::Dataproc::V1::Clusters::Cluster'->new($_) };

declare 'RepeatedCluster',
    as ArrayRef[Cluster()];

coerce 'RepeatedCluster',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataproc::V1::Clusters::Cluster'->new($_) } @$_ ] };

declare 'MapStringCluster',
    as HashRef[Cluster()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Dataproc::V1::Clusters::Cluster::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Dataproc::V1::Clusters::Cluster::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataproc::V1::Clusters::Cluster::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'ClusterConfig',
    as InstanceOf['Google::Cloud::Dataproc::V1::Clusters::ClusterConfig'];

coerce 'ClusterConfig',
    from HashRef, via { 'Google::Cloud::Dataproc::V1::Clusters::ClusterConfig'->new($_) };

declare 'RepeatedClusterConfig',
    as ArrayRef[ClusterConfig()];

coerce 'RepeatedClusterConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataproc::V1::Clusters::ClusterConfig'->new($_) } @$_ ] };

declare 'MapStringClusterConfig',
    as HashRef[ClusterConfig()];

declare 'ClusterType',
    as (Int | Str);

declare 'ClusterTier',
    as (Int | Str);

declare 'Engine',
    as (Int | Str);

declare 'VirtualClusterConfig',
    as InstanceOf['Google::Cloud::Dataproc::V1::Clusters::VirtualClusterConfig'];

coerce 'VirtualClusterConfig',
    from HashRef, via { 'Google::Cloud::Dataproc::V1::Clusters::VirtualClusterConfig'->new($_) };

declare 'RepeatedVirtualClusterConfig',
    as ArrayRef[VirtualClusterConfig()];

coerce 'RepeatedVirtualClusterConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataproc::V1::Clusters::VirtualClusterConfig'->new($_) } @$_ ] };

declare 'MapStringVirtualClusterConfig',
    as HashRef[VirtualClusterConfig()];

declare 'AuxiliaryServicesConfig',
    as InstanceOf['Google::Cloud::Dataproc::V1::Clusters::AuxiliaryServicesConfig'];

coerce 'AuxiliaryServicesConfig',
    from HashRef, via { 'Google::Cloud::Dataproc::V1::Clusters::AuxiliaryServicesConfig'->new($_) };

declare 'RepeatedAuxiliaryServicesConfig',
    as ArrayRef[AuxiliaryServicesConfig()];

coerce 'RepeatedAuxiliaryServicesConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataproc::V1::Clusters::AuxiliaryServicesConfig'->new($_) } @$_ ] };

declare 'MapStringAuxiliaryServicesConfig',
    as HashRef[AuxiliaryServicesConfig()];

declare 'EndpointConfig',
    as InstanceOf['Google::Cloud::Dataproc::V1::Clusters::EndpointConfig'];

coerce 'EndpointConfig',
    from HashRef, via { 'Google::Cloud::Dataproc::V1::Clusters::EndpointConfig'->new($_) };

declare 'RepeatedEndpointConfig',
    as ArrayRef[EndpointConfig()];

coerce 'RepeatedEndpointConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataproc::V1::Clusters::EndpointConfig'->new($_) } @$_ ] };

declare 'MapStringEndpointConfig',
    as HashRef[EndpointConfig()];

declare 'HttpPortsEntry',
    as InstanceOf['Google::Cloud::Dataproc::V1::Clusters::EndpointConfig::HttpPortsEntry'];

coerce 'HttpPortsEntry',
    from HashRef, via { 'Google::Cloud::Dataproc::V1::Clusters::EndpointConfig::HttpPortsEntry'->new($_) };

declare 'RepeatedHttpPortsEntry',
    as ArrayRef[HttpPortsEntry()];

coerce 'RepeatedHttpPortsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataproc::V1::Clusters::EndpointConfig::HttpPortsEntry'->new($_) } @$_ ] };

declare 'MapStringHttpPortsEntry',
    as HashRef[HttpPortsEntry()];

declare 'AutoscalingConfig',
    as InstanceOf['Google::Cloud::Dataproc::V1::Clusters::AutoscalingConfig'];

coerce 'AutoscalingConfig',
    from HashRef, via { 'Google::Cloud::Dataproc::V1::Clusters::AutoscalingConfig'->new($_) };

declare 'RepeatedAutoscalingConfig',
    as ArrayRef[AutoscalingConfig()];

coerce 'RepeatedAutoscalingConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataproc::V1::Clusters::AutoscalingConfig'->new($_) } @$_ ] };

declare 'MapStringAutoscalingConfig',
    as HashRef[AutoscalingConfig()];

declare 'EncryptionConfig',
    as InstanceOf['Google::Cloud::Dataproc::V1::Clusters::EncryptionConfig'];

coerce 'EncryptionConfig',
    from HashRef, via { 'Google::Cloud::Dataproc::V1::Clusters::EncryptionConfig'->new($_) };

declare 'RepeatedEncryptionConfig',
    as ArrayRef[EncryptionConfig()];

coerce 'RepeatedEncryptionConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataproc::V1::Clusters::EncryptionConfig'->new($_) } @$_ ] };

declare 'MapStringEncryptionConfig',
    as HashRef[EncryptionConfig()];

declare 'GceClusterConfig',
    as InstanceOf['Google::Cloud::Dataproc::V1::Clusters::GceClusterConfig'];

coerce 'GceClusterConfig',
    from HashRef, via { 'Google::Cloud::Dataproc::V1::Clusters::GceClusterConfig'->new($_) };

declare 'RepeatedGceClusterConfig',
    as ArrayRef[GceClusterConfig()];

coerce 'RepeatedGceClusterConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataproc::V1::Clusters::GceClusterConfig'->new($_) } @$_ ] };

declare 'MapStringGceClusterConfig',
    as HashRef[GceClusterConfig()];

declare 'PrivateIpv6GoogleAccess',
    as (Int | Str);

declare 'MetadataEntry',
    as InstanceOf['Google::Cloud::Dataproc::V1::Clusters::GceClusterConfig::MetadataEntry'];

coerce 'MetadataEntry',
    from HashRef, via { 'Google::Cloud::Dataproc::V1::Clusters::GceClusterConfig::MetadataEntry'->new($_) };

declare 'RepeatedMetadataEntry',
    as ArrayRef[MetadataEntry()];

coerce 'RepeatedMetadataEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataproc::V1::Clusters::GceClusterConfig::MetadataEntry'->new($_) } @$_ ] };

declare 'MapStringMetadataEntry',
    as HashRef[MetadataEntry()];

declare 'ResourceManagerTagsEntry',
    as InstanceOf['Google::Cloud::Dataproc::V1::Clusters::GceClusterConfig::ResourceManagerTagsEntry'];

coerce 'ResourceManagerTagsEntry',
    from HashRef, via { 'Google::Cloud::Dataproc::V1::Clusters::GceClusterConfig::ResourceManagerTagsEntry'->new($_) };

declare 'RepeatedResourceManagerTagsEntry',
    as ArrayRef[ResourceManagerTagsEntry()];

coerce 'RepeatedResourceManagerTagsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataproc::V1::Clusters::GceClusterConfig::ResourceManagerTagsEntry'->new($_) } @$_ ] };

declare 'MapStringResourceManagerTagsEntry',
    as HashRef[ResourceManagerTagsEntry()];

declare 'NodeGroupAffinity',
    as InstanceOf['Google::Cloud::Dataproc::V1::Clusters::NodeGroupAffinity'];

coerce 'NodeGroupAffinity',
    from HashRef, via { 'Google::Cloud::Dataproc::V1::Clusters::NodeGroupAffinity'->new($_) };

declare 'RepeatedNodeGroupAffinity',
    as ArrayRef[NodeGroupAffinity()];

coerce 'RepeatedNodeGroupAffinity',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataproc::V1::Clusters::NodeGroupAffinity'->new($_) } @$_ ] };

declare 'MapStringNodeGroupAffinity',
    as HashRef[NodeGroupAffinity()];

declare 'ShieldedInstanceConfig',
    as InstanceOf['Google::Cloud::Dataproc::V1::Clusters::ShieldedInstanceConfig'];

coerce 'ShieldedInstanceConfig',
    from HashRef, via { 'Google::Cloud::Dataproc::V1::Clusters::ShieldedInstanceConfig'->new($_) };

declare 'RepeatedShieldedInstanceConfig',
    as ArrayRef[ShieldedInstanceConfig()];

coerce 'RepeatedShieldedInstanceConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataproc::V1::Clusters::ShieldedInstanceConfig'->new($_) } @$_ ] };

declare 'MapStringShieldedInstanceConfig',
    as HashRef[ShieldedInstanceConfig()];

declare 'ConfidentialInstanceConfig',
    as InstanceOf['Google::Cloud::Dataproc::V1::Clusters::ConfidentialInstanceConfig'];

coerce 'ConfidentialInstanceConfig',
    from HashRef, via { 'Google::Cloud::Dataproc::V1::Clusters::ConfidentialInstanceConfig'->new($_) };

declare 'RepeatedConfidentialInstanceConfig',
    as ArrayRef[ConfidentialInstanceConfig()];

coerce 'RepeatedConfidentialInstanceConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataproc::V1::Clusters::ConfidentialInstanceConfig'->new($_) } @$_ ] };

declare 'MapStringConfidentialInstanceConfig',
    as HashRef[ConfidentialInstanceConfig()];

declare 'ConfidentialInstanceType',
    as (Int | Str);

declare 'InstanceGroupConfig',
    as InstanceOf['Google::Cloud::Dataproc::V1::Clusters::InstanceGroupConfig'];

coerce 'InstanceGroupConfig',
    from HashRef, via { 'Google::Cloud::Dataproc::V1::Clusters::InstanceGroupConfig'->new($_) };

declare 'RepeatedInstanceGroupConfig',
    as ArrayRef[InstanceGroupConfig()];

coerce 'RepeatedInstanceGroupConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataproc::V1::Clusters::InstanceGroupConfig'->new($_) } @$_ ] };

declare 'MapStringInstanceGroupConfig',
    as HashRef[InstanceGroupConfig()];

declare 'Preemptibility',
    as (Int | Str);

declare 'StartupConfig',
    as InstanceOf['Google::Cloud::Dataproc::V1::Clusters::StartupConfig'];

coerce 'StartupConfig',
    from HashRef, via { 'Google::Cloud::Dataproc::V1::Clusters::StartupConfig'->new($_) };

declare 'RepeatedStartupConfig',
    as ArrayRef[StartupConfig()];

coerce 'RepeatedStartupConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataproc::V1::Clusters::StartupConfig'->new($_) } @$_ ] };

declare 'MapStringStartupConfig',
    as HashRef[StartupConfig()];

declare 'InstanceReference',
    as InstanceOf['Google::Cloud::Dataproc::V1::Clusters::InstanceReference'];

coerce 'InstanceReference',
    from HashRef, via { 'Google::Cloud::Dataproc::V1::Clusters::InstanceReference'->new($_) };

declare 'RepeatedInstanceReference',
    as ArrayRef[InstanceReference()];

coerce 'RepeatedInstanceReference',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataproc::V1::Clusters::InstanceReference'->new($_) } @$_ ] };

declare 'MapStringInstanceReference',
    as HashRef[InstanceReference()];

declare 'ManagedGroupConfig',
    as InstanceOf['Google::Cloud::Dataproc::V1::Clusters::ManagedGroupConfig'];

coerce 'ManagedGroupConfig',
    from HashRef, via { 'Google::Cloud::Dataproc::V1::Clusters::ManagedGroupConfig'->new($_) };

declare 'RepeatedManagedGroupConfig',
    as ArrayRef[ManagedGroupConfig()];

coerce 'RepeatedManagedGroupConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataproc::V1::Clusters::ManagedGroupConfig'->new($_) } @$_ ] };

declare 'MapStringManagedGroupConfig',
    as HashRef[ManagedGroupConfig()];

declare 'InstanceFlexibilityPolicy',
    as InstanceOf['Google::Cloud::Dataproc::V1::Clusters::InstanceFlexibilityPolicy'];

coerce 'InstanceFlexibilityPolicy',
    from HashRef, via { 'Google::Cloud::Dataproc::V1::Clusters::InstanceFlexibilityPolicy'->new($_) };

declare 'RepeatedInstanceFlexibilityPolicy',
    as ArrayRef[InstanceFlexibilityPolicy()];

coerce 'RepeatedInstanceFlexibilityPolicy',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataproc::V1::Clusters::InstanceFlexibilityPolicy'->new($_) } @$_ ] };

declare 'MapStringInstanceFlexibilityPolicy',
    as HashRef[InstanceFlexibilityPolicy()];

declare 'ProvisioningModelMix',
    as InstanceOf['Google::Cloud::Dataproc::V1::Clusters::InstanceFlexibilityPolicy::ProvisioningModelMix'];

coerce 'ProvisioningModelMix',
    from HashRef, via { 'Google::Cloud::Dataproc::V1::Clusters::InstanceFlexibilityPolicy::ProvisioningModelMix'->new($_) };

declare 'RepeatedProvisioningModelMix',
    as ArrayRef[ProvisioningModelMix()];

coerce 'RepeatedProvisioningModelMix',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataproc::V1::Clusters::InstanceFlexibilityPolicy::ProvisioningModelMix'->new($_) } @$_ ] };

declare 'MapStringProvisioningModelMix',
    as HashRef[ProvisioningModelMix()];

declare 'InstanceSelection',
    as InstanceOf['Google::Cloud::Dataproc::V1::Clusters::InstanceFlexibilityPolicy::InstanceSelection'];

coerce 'InstanceSelection',
    from HashRef, via { 'Google::Cloud::Dataproc::V1::Clusters::InstanceFlexibilityPolicy::InstanceSelection'->new($_) };

declare 'RepeatedInstanceSelection',
    as ArrayRef[InstanceSelection()];

coerce 'RepeatedInstanceSelection',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataproc::V1::Clusters::InstanceFlexibilityPolicy::InstanceSelection'->new($_) } @$_ ] };

declare 'MapStringInstanceSelection',
    as HashRef[InstanceSelection()];

declare 'InstanceSelectionResult',
    as InstanceOf['Google::Cloud::Dataproc::V1::Clusters::InstanceFlexibilityPolicy::InstanceSelectionResult'];

coerce 'InstanceSelectionResult',
    from HashRef, via { 'Google::Cloud::Dataproc::V1::Clusters::InstanceFlexibilityPolicy::InstanceSelectionResult'->new($_) };

declare 'RepeatedInstanceSelectionResult',
    as ArrayRef[InstanceSelectionResult()];

coerce 'RepeatedInstanceSelectionResult',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataproc::V1::Clusters::InstanceFlexibilityPolicy::InstanceSelectionResult'->new($_) } @$_ ] };

declare 'MapStringInstanceSelectionResult',
    as HashRef[InstanceSelectionResult()];

declare 'AcceleratorConfig',
    as InstanceOf['Google::Cloud::Dataproc::V1::Clusters::AcceleratorConfig'];

coerce 'AcceleratorConfig',
    from HashRef, via { 'Google::Cloud::Dataproc::V1::Clusters::AcceleratorConfig'->new($_) };

declare 'RepeatedAcceleratorConfig',
    as ArrayRef[AcceleratorConfig()];

coerce 'RepeatedAcceleratorConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataproc::V1::Clusters::AcceleratorConfig'->new($_) } @$_ ] };

declare 'MapStringAcceleratorConfig',
    as HashRef[AcceleratorConfig()];

declare 'DiskConfig',
    as InstanceOf['Google::Cloud::Dataproc::V1::Clusters::DiskConfig'];

coerce 'DiskConfig',
    from HashRef, via { 'Google::Cloud::Dataproc::V1::Clusters::DiskConfig'->new($_) };

declare 'RepeatedDiskConfig',
    as ArrayRef[DiskConfig()];

coerce 'RepeatedDiskConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataproc::V1::Clusters::DiskConfig'->new($_) } @$_ ] };

declare 'MapStringDiskConfig',
    as HashRef[DiskConfig()];

declare 'AttachedDiskConfig',
    as InstanceOf['Google::Cloud::Dataproc::V1::Clusters::AttachedDiskConfig'];

coerce 'AttachedDiskConfig',
    from HashRef, via { 'Google::Cloud::Dataproc::V1::Clusters::AttachedDiskConfig'->new($_) };

declare 'RepeatedAttachedDiskConfig',
    as ArrayRef[AttachedDiskConfig()];

coerce 'RepeatedAttachedDiskConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataproc::V1::Clusters::AttachedDiskConfig'->new($_) } @$_ ] };

declare 'MapStringAttachedDiskConfig',
    as HashRef[AttachedDiskConfig()];

declare 'DiskType',
    as (Int | Str);

declare 'AuxiliaryNodeGroup',
    as InstanceOf['Google::Cloud::Dataproc::V1::Clusters::AuxiliaryNodeGroup'];

coerce 'AuxiliaryNodeGroup',
    from HashRef, via { 'Google::Cloud::Dataproc::V1::Clusters::AuxiliaryNodeGroup'->new($_) };

declare 'RepeatedAuxiliaryNodeGroup',
    as ArrayRef[AuxiliaryNodeGroup()];

coerce 'RepeatedAuxiliaryNodeGroup',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataproc::V1::Clusters::AuxiliaryNodeGroup'->new($_) } @$_ ] };

declare 'MapStringAuxiliaryNodeGroup',
    as HashRef[AuxiliaryNodeGroup()];

declare 'NodeGroup',
    as InstanceOf['Google::Cloud::Dataproc::V1::Clusters::NodeGroup'];

coerce 'NodeGroup',
    from HashRef, via { 'Google::Cloud::Dataproc::V1::Clusters::NodeGroup'->new($_) };

declare 'RepeatedNodeGroup',
    as ArrayRef[NodeGroup()];

coerce 'RepeatedNodeGroup',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataproc::V1::Clusters::NodeGroup'->new($_) } @$_ ] };

declare 'MapStringNodeGroup',
    as HashRef[NodeGroup()];

declare 'Role',
    as (Int | Str);

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Dataproc::V1::Clusters::NodeGroup::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Dataproc::V1::Clusters::NodeGroup::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataproc::V1::Clusters::NodeGroup::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'NodeInitializationAction',
    as InstanceOf['Google::Cloud::Dataproc::V1::Clusters::NodeInitializationAction'];

coerce 'NodeInitializationAction',
    from HashRef, via { 'Google::Cloud::Dataproc::V1::Clusters::NodeInitializationAction'->new($_) };

declare 'RepeatedNodeInitializationAction',
    as ArrayRef[NodeInitializationAction()];

coerce 'RepeatedNodeInitializationAction',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataproc::V1::Clusters::NodeInitializationAction'->new($_) } @$_ ] };

declare 'MapStringNodeInitializationAction',
    as HashRef[NodeInitializationAction()];

declare 'ClusterStatus',
    as InstanceOf['Google::Cloud::Dataproc::V1::Clusters::ClusterStatus'];

coerce 'ClusterStatus',
    from HashRef, via { 'Google::Cloud::Dataproc::V1::Clusters::ClusterStatus'->new($_) };

declare 'RepeatedClusterStatus',
    as ArrayRef[ClusterStatus()];

coerce 'RepeatedClusterStatus',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataproc::V1::Clusters::ClusterStatus'->new($_) } @$_ ] };

declare 'MapStringClusterStatus',
    as HashRef[ClusterStatus()];

declare 'State',
    as (Int | Str);

declare 'Substate',
    as (Int | Str);

declare 'SecurityConfig',
    as InstanceOf['Google::Cloud::Dataproc::V1::Clusters::SecurityConfig'];

coerce 'SecurityConfig',
    from HashRef, via { 'Google::Cloud::Dataproc::V1::Clusters::SecurityConfig'->new($_) };

declare 'RepeatedSecurityConfig',
    as ArrayRef[SecurityConfig()];

coerce 'RepeatedSecurityConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataproc::V1::Clusters::SecurityConfig'->new($_) } @$_ ] };

declare 'MapStringSecurityConfig',
    as HashRef[SecurityConfig()];

declare 'KerberosConfig',
    as InstanceOf['Google::Cloud::Dataproc::V1::Clusters::KerberosConfig'];

coerce 'KerberosConfig',
    from HashRef, via { 'Google::Cloud::Dataproc::V1::Clusters::KerberosConfig'->new($_) };

declare 'RepeatedKerberosConfig',
    as ArrayRef[KerberosConfig()];

coerce 'RepeatedKerberosConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataproc::V1::Clusters::KerberosConfig'->new($_) } @$_ ] };

declare 'MapStringKerberosConfig',
    as HashRef[KerberosConfig()];

declare 'IdentityConfig',
    as InstanceOf['Google::Cloud::Dataproc::V1::Clusters::IdentityConfig'];

coerce 'IdentityConfig',
    from HashRef, via { 'Google::Cloud::Dataproc::V1::Clusters::IdentityConfig'->new($_) };

declare 'RepeatedIdentityConfig',
    as ArrayRef[IdentityConfig()];

coerce 'RepeatedIdentityConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataproc::V1::Clusters::IdentityConfig'->new($_) } @$_ ] };

declare 'MapStringIdentityConfig',
    as HashRef[IdentityConfig()];

declare 'UserServiceAccountMappingEntry',
    as InstanceOf['Google::Cloud::Dataproc::V1::Clusters::IdentityConfig::UserServiceAccountMappingEntry'];

coerce 'UserServiceAccountMappingEntry',
    from HashRef, via { 'Google::Cloud::Dataproc::V1::Clusters::IdentityConfig::UserServiceAccountMappingEntry'->new($_) };

declare 'RepeatedUserServiceAccountMappingEntry',
    as ArrayRef[UserServiceAccountMappingEntry()];

coerce 'RepeatedUserServiceAccountMappingEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataproc::V1::Clusters::IdentityConfig::UserServiceAccountMappingEntry'->new($_) } @$_ ] };

declare 'MapStringUserServiceAccountMappingEntry',
    as HashRef[UserServiceAccountMappingEntry()];

declare 'SoftwareConfig',
    as InstanceOf['Google::Cloud::Dataproc::V1::Clusters::SoftwareConfig'];

coerce 'SoftwareConfig',
    from HashRef, via { 'Google::Cloud::Dataproc::V1::Clusters::SoftwareConfig'->new($_) };

declare 'RepeatedSoftwareConfig',
    as ArrayRef[SoftwareConfig()];

coerce 'RepeatedSoftwareConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataproc::V1::Clusters::SoftwareConfig'->new($_) } @$_ ] };

declare 'MapStringSoftwareConfig',
    as HashRef[SoftwareConfig()];

declare 'PropertiesEntry',
    as InstanceOf['Google::Cloud::Dataproc::V1::Clusters::SoftwareConfig::PropertiesEntry'];

coerce 'PropertiesEntry',
    from HashRef, via { 'Google::Cloud::Dataproc::V1::Clusters::SoftwareConfig::PropertiesEntry'->new($_) };

declare 'RepeatedPropertiesEntry',
    as ArrayRef[PropertiesEntry()];

coerce 'RepeatedPropertiesEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataproc::V1::Clusters::SoftwareConfig::PropertiesEntry'->new($_) } @$_ ] };

declare 'MapStringPropertiesEntry',
    as HashRef[PropertiesEntry()];

declare 'LifecycleConfig',
    as InstanceOf['Google::Cloud::Dataproc::V1::Clusters::LifecycleConfig'];

coerce 'LifecycleConfig',
    from HashRef, via { 'Google::Cloud::Dataproc::V1::Clusters::LifecycleConfig'->new($_) };

declare 'RepeatedLifecycleConfig',
    as ArrayRef[LifecycleConfig()];

coerce 'RepeatedLifecycleConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataproc::V1::Clusters::LifecycleConfig'->new($_) } @$_ ] };

declare 'MapStringLifecycleConfig',
    as HashRef[LifecycleConfig()];

declare 'MetastoreConfig',
    as InstanceOf['Google::Cloud::Dataproc::V1::Clusters::MetastoreConfig'];

coerce 'MetastoreConfig',
    from HashRef, via { 'Google::Cloud::Dataproc::V1::Clusters::MetastoreConfig'->new($_) };

declare 'RepeatedMetastoreConfig',
    as ArrayRef[MetastoreConfig()];

coerce 'RepeatedMetastoreConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataproc::V1::Clusters::MetastoreConfig'->new($_) } @$_ ] };

declare 'MapStringMetastoreConfig',
    as HashRef[MetastoreConfig()];

declare 'ClusterMetrics',
    as InstanceOf['Google::Cloud::Dataproc::V1::Clusters::ClusterMetrics'];

coerce 'ClusterMetrics',
    from HashRef, via { 'Google::Cloud::Dataproc::V1::Clusters::ClusterMetrics'->new($_) };

declare 'RepeatedClusterMetrics',
    as ArrayRef[ClusterMetrics()];

coerce 'RepeatedClusterMetrics',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataproc::V1::Clusters::ClusterMetrics'->new($_) } @$_ ] };

declare 'MapStringClusterMetrics',
    as HashRef[ClusterMetrics()];

declare 'HdfsMetricsEntry',
    as InstanceOf['Google::Cloud::Dataproc::V1::Clusters::ClusterMetrics::HdfsMetricsEntry'];

coerce 'HdfsMetricsEntry',
    from HashRef, via { 'Google::Cloud::Dataproc::V1::Clusters::ClusterMetrics::HdfsMetricsEntry'->new($_) };

declare 'RepeatedHdfsMetricsEntry',
    as ArrayRef[HdfsMetricsEntry()];

coerce 'RepeatedHdfsMetricsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataproc::V1::Clusters::ClusterMetrics::HdfsMetricsEntry'->new($_) } @$_ ] };

declare 'MapStringHdfsMetricsEntry',
    as HashRef[HdfsMetricsEntry()];

declare 'YarnMetricsEntry',
    as InstanceOf['Google::Cloud::Dataproc::V1::Clusters::ClusterMetrics::YarnMetricsEntry'];

coerce 'YarnMetricsEntry',
    from HashRef, via { 'Google::Cloud::Dataproc::V1::Clusters::ClusterMetrics::YarnMetricsEntry'->new($_) };

declare 'RepeatedYarnMetricsEntry',
    as ArrayRef[YarnMetricsEntry()];

coerce 'RepeatedYarnMetricsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataproc::V1::Clusters::ClusterMetrics::YarnMetricsEntry'->new($_) } @$_ ] };

declare 'MapStringYarnMetricsEntry',
    as HashRef[YarnMetricsEntry()];

declare 'DataprocMetricConfig',
    as InstanceOf['Google::Cloud::Dataproc::V1::Clusters::DataprocMetricConfig'];

coerce 'DataprocMetricConfig',
    from HashRef, via { 'Google::Cloud::Dataproc::V1::Clusters::DataprocMetricConfig'->new($_) };

declare 'RepeatedDataprocMetricConfig',
    as ArrayRef[DataprocMetricConfig()];

coerce 'RepeatedDataprocMetricConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataproc::V1::Clusters::DataprocMetricConfig'->new($_) } @$_ ] };

declare 'MapStringDataprocMetricConfig',
    as HashRef[DataprocMetricConfig()];

declare 'MetricSource',
    as (Int | Str);

declare 'Metric',
    as InstanceOf['Google::Cloud::Dataproc::V1::Clusters::DataprocMetricConfig::Metric'];

coerce 'Metric',
    from HashRef, via { 'Google::Cloud::Dataproc::V1::Clusters::DataprocMetricConfig::Metric'->new($_) };

declare 'RepeatedMetric',
    as ArrayRef[Metric()];

coerce 'RepeatedMetric',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataproc::V1::Clusters::DataprocMetricConfig::Metric'->new($_) } @$_ ] };

declare 'MapStringMetric',
    as HashRef[Metric()];

declare 'CreateClusterRequest',
    as InstanceOf['Google::Cloud::Dataproc::V1::Clusters::CreateClusterRequest'];

coerce 'CreateClusterRequest',
    from HashRef, via { 'Google::Cloud::Dataproc::V1::Clusters::CreateClusterRequest'->new($_) };

declare 'RepeatedCreateClusterRequest',
    as ArrayRef[CreateClusterRequest()];

coerce 'RepeatedCreateClusterRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataproc::V1::Clusters::CreateClusterRequest'->new($_) } @$_ ] };

declare 'MapStringCreateClusterRequest',
    as HashRef[CreateClusterRequest()];

declare 'UpdateClusterRequest',
    as InstanceOf['Google::Cloud::Dataproc::V1::Clusters::UpdateClusterRequest'];

coerce 'UpdateClusterRequest',
    from HashRef, via { 'Google::Cloud::Dataproc::V1::Clusters::UpdateClusterRequest'->new($_) };

declare 'RepeatedUpdateClusterRequest',
    as ArrayRef[UpdateClusterRequest()];

coerce 'RepeatedUpdateClusterRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataproc::V1::Clusters::UpdateClusterRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateClusterRequest',
    as HashRef[UpdateClusterRequest()];

declare 'StopClusterRequest',
    as InstanceOf['Google::Cloud::Dataproc::V1::Clusters::StopClusterRequest'];

coerce 'StopClusterRequest',
    from HashRef, via { 'Google::Cloud::Dataproc::V1::Clusters::StopClusterRequest'->new($_) };

declare 'RepeatedStopClusterRequest',
    as ArrayRef[StopClusterRequest()];

coerce 'RepeatedStopClusterRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataproc::V1::Clusters::StopClusterRequest'->new($_) } @$_ ] };

declare 'MapStringStopClusterRequest',
    as HashRef[StopClusterRequest()];

declare 'StartClusterRequest',
    as InstanceOf['Google::Cloud::Dataproc::V1::Clusters::StartClusterRequest'];

coerce 'StartClusterRequest',
    from HashRef, via { 'Google::Cloud::Dataproc::V1::Clusters::StartClusterRequest'->new($_) };

declare 'RepeatedStartClusterRequest',
    as ArrayRef[StartClusterRequest()];

coerce 'RepeatedStartClusterRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataproc::V1::Clusters::StartClusterRequest'->new($_) } @$_ ] };

declare 'MapStringStartClusterRequest',
    as HashRef[StartClusterRequest()];

declare 'DeleteClusterRequest',
    as InstanceOf['Google::Cloud::Dataproc::V1::Clusters::DeleteClusterRequest'];

coerce 'DeleteClusterRequest',
    from HashRef, via { 'Google::Cloud::Dataproc::V1::Clusters::DeleteClusterRequest'->new($_) };

declare 'RepeatedDeleteClusterRequest',
    as ArrayRef[DeleteClusterRequest()];

coerce 'RepeatedDeleteClusterRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataproc::V1::Clusters::DeleteClusterRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteClusterRequest',
    as HashRef[DeleteClusterRequest()];

declare 'GetClusterRequest',
    as InstanceOf['Google::Cloud::Dataproc::V1::Clusters::GetClusterRequest'];

coerce 'GetClusterRequest',
    from HashRef, via { 'Google::Cloud::Dataproc::V1::Clusters::GetClusterRequest'->new($_) };

declare 'RepeatedGetClusterRequest',
    as ArrayRef[GetClusterRequest()];

coerce 'RepeatedGetClusterRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataproc::V1::Clusters::GetClusterRequest'->new($_) } @$_ ] };

declare 'MapStringGetClusterRequest',
    as HashRef[GetClusterRequest()];

declare 'ListClustersRequest',
    as InstanceOf['Google::Cloud::Dataproc::V1::Clusters::ListClustersRequest'];

coerce 'ListClustersRequest',
    from HashRef, via { 'Google::Cloud::Dataproc::V1::Clusters::ListClustersRequest'->new($_) };

declare 'RepeatedListClustersRequest',
    as ArrayRef[ListClustersRequest()];

coerce 'RepeatedListClustersRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataproc::V1::Clusters::ListClustersRequest'->new($_) } @$_ ] };

declare 'MapStringListClustersRequest',
    as HashRef[ListClustersRequest()];

declare 'ListClustersResponse',
    as InstanceOf['Google::Cloud::Dataproc::V1::Clusters::ListClustersResponse'];

coerce 'ListClustersResponse',
    from HashRef, via { 'Google::Cloud::Dataproc::V1::Clusters::ListClustersResponse'->new($_) };

declare 'RepeatedListClustersResponse',
    as ArrayRef[ListClustersResponse()];

coerce 'RepeatedListClustersResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataproc::V1::Clusters::ListClustersResponse'->new($_) } @$_ ] };

declare 'MapStringListClustersResponse',
    as HashRef[ListClustersResponse()];

declare 'DiagnoseClusterRequest',
    as InstanceOf['Google::Cloud::Dataproc::V1::Clusters::DiagnoseClusterRequest'];

coerce 'DiagnoseClusterRequest',
    from HashRef, via { 'Google::Cloud::Dataproc::V1::Clusters::DiagnoseClusterRequest'->new($_) };

declare 'RepeatedDiagnoseClusterRequest',
    as ArrayRef[DiagnoseClusterRequest()];

coerce 'RepeatedDiagnoseClusterRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataproc::V1::Clusters::DiagnoseClusterRequest'->new($_) } @$_ ] };

declare 'MapStringDiagnoseClusterRequest',
    as HashRef[DiagnoseClusterRequest()];

declare 'TarballAccess',
    as (Int | Str);

declare 'DiagnoseClusterResults',
    as InstanceOf['Google::Cloud::Dataproc::V1::Clusters::DiagnoseClusterResults'];

coerce 'DiagnoseClusterResults',
    from HashRef, via { 'Google::Cloud::Dataproc::V1::Clusters::DiagnoseClusterResults'->new($_) };

declare 'RepeatedDiagnoseClusterResults',
    as ArrayRef[DiagnoseClusterResults()];

coerce 'RepeatedDiagnoseClusterResults',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataproc::V1::Clusters::DiagnoseClusterResults'->new($_) } @$_ ] };

declare 'MapStringDiagnoseClusterResults',
    as HashRef[DiagnoseClusterResults()];

declare 'ReservationAffinity',
    as InstanceOf['Google::Cloud::Dataproc::V1::Clusters::ReservationAffinity'];

coerce 'ReservationAffinity',
    from HashRef, via { 'Google::Cloud::Dataproc::V1::Clusters::ReservationAffinity'->new($_) };

declare 'RepeatedReservationAffinity',
    as ArrayRef[ReservationAffinity()];

coerce 'RepeatedReservationAffinity',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataproc::V1::Clusters::ReservationAffinity'->new($_) } @$_ ] };

declare 'MapStringReservationAffinity',
    as HashRef[ReservationAffinity()];

declare 'Type',
    as (Int | Str);

1;

__END__

=head1 NAME

Google::Cloud::Dataproc::V1::Clusters::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
