package Google::Cloud::Edgecontainer::V1::Resources::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'KmsKeyState',
    as (Int | Str);

declare 'ResourceState',
    as (Int | Str);

declare 'Cluster',
    as InstanceOf['Google::Cloud::Edgecontainer::V1::Resources::Cluster'];

coerce 'Cluster',
    from HashRef, via { 'Google::Cloud::Edgecontainer::V1::Resources::Cluster'->new($_) };

declare 'RepeatedCluster',
    as ArrayRef[Cluster()];

coerce 'RepeatedCluster',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Edgecontainer::V1::Resources::Cluster'->new($_) } @$_ ] };

declare 'MapStringCluster',
    as HashRef[Cluster()];

declare 'Status',
    as (Int | Str);

declare 'ReleaseChannel',
    as (Int | Str);

declare 'ControlPlane',
    as InstanceOf['Google::Cloud::Edgecontainer::V1::Resources::Cluster::ControlPlane'];

coerce 'ControlPlane',
    from HashRef, via { 'Google::Cloud::Edgecontainer::V1::Resources::Cluster::ControlPlane'->new($_) };

declare 'RepeatedControlPlane',
    as ArrayRef[ControlPlane()];

coerce 'RepeatedControlPlane',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Edgecontainer::V1::Resources::Cluster::ControlPlane'->new($_) } @$_ ] };

declare 'MapStringControlPlane',
    as HashRef[ControlPlane()];

declare 'SharedDeploymentPolicy',
    as (Int | Str);

declare 'Remote',
    as InstanceOf['Google::Cloud::Edgecontainer::V1::Resources::Cluster::ControlPlane::Remote'];

coerce 'Remote',
    from HashRef, via { 'Google::Cloud::Edgecontainer::V1::Resources::Cluster::ControlPlane::Remote'->new($_) };

declare 'RepeatedRemote',
    as ArrayRef[Remote()];

coerce 'RepeatedRemote',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Edgecontainer::V1::Resources::Cluster::ControlPlane::Remote'->new($_) } @$_ ] };

declare 'MapStringRemote',
    as HashRef[Remote()];

declare 'Local',
    as InstanceOf['Google::Cloud::Edgecontainer::V1::Resources::Cluster::ControlPlane::Local'];

coerce 'Local',
    from HashRef, via { 'Google::Cloud::Edgecontainer::V1::Resources::Cluster::ControlPlane::Local'->new($_) };

declare 'RepeatedLocal',
    as ArrayRef[Local()];

coerce 'RepeatedLocal',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Edgecontainer::V1::Resources::Cluster::ControlPlane::Local'->new($_) } @$_ ] };

declare 'MapStringLocal',
    as HashRef[Local()];

declare 'SystemAddonsConfig',
    as InstanceOf['Google::Cloud::Edgecontainer::V1::Resources::Cluster::SystemAddonsConfig'];

coerce 'SystemAddonsConfig',
    from HashRef, via { 'Google::Cloud::Edgecontainer::V1::Resources::Cluster::SystemAddonsConfig'->new($_) };

declare 'RepeatedSystemAddonsConfig',
    as ArrayRef[SystemAddonsConfig()];

coerce 'RepeatedSystemAddonsConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Edgecontainer::V1::Resources::Cluster::SystemAddonsConfig'->new($_) } @$_ ] };

declare 'MapStringSystemAddonsConfig',
    as HashRef[SystemAddonsConfig()];

declare 'Ingress',
    as InstanceOf['Google::Cloud::Edgecontainer::V1::Resources::Cluster::SystemAddonsConfig::Ingress'];

coerce 'Ingress',
    from HashRef, via { 'Google::Cloud::Edgecontainer::V1::Resources::Cluster::SystemAddonsConfig::Ingress'->new($_) };

declare 'RepeatedIngress',
    as ArrayRef[Ingress()];

coerce 'RepeatedIngress',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Edgecontainer::V1::Resources::Cluster::SystemAddonsConfig::Ingress'->new($_) } @$_ ] };

declare 'MapStringIngress',
    as HashRef[Ingress()];

declare 'VMServiceConfig',
    as InstanceOf['Google::Cloud::Edgecontainer::V1::Resources::Cluster::SystemAddonsConfig::VMServiceConfig'];

coerce 'VMServiceConfig',
    from HashRef, via { 'Google::Cloud::Edgecontainer::V1::Resources::Cluster::SystemAddonsConfig::VMServiceConfig'->new($_) };

declare 'RepeatedVMServiceConfig',
    as ArrayRef[VMServiceConfig()];

coerce 'RepeatedVMServiceConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Edgecontainer::V1::Resources::Cluster::SystemAddonsConfig::VMServiceConfig'->new($_) } @$_ ] };

declare 'MapStringVMServiceConfig',
    as HashRef[VMServiceConfig()];

declare 'ControlPlaneEncryption',
    as InstanceOf['Google::Cloud::Edgecontainer::V1::Resources::Cluster::ControlPlaneEncryption'];

coerce 'ControlPlaneEncryption',
    from HashRef, via { 'Google::Cloud::Edgecontainer::V1::Resources::Cluster::ControlPlaneEncryption'->new($_) };

declare 'RepeatedControlPlaneEncryption',
    as ArrayRef[ControlPlaneEncryption()];

coerce 'RepeatedControlPlaneEncryption',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Edgecontainer::V1::Resources::Cluster::ControlPlaneEncryption'->new($_) } @$_ ] };

declare 'MapStringControlPlaneEncryption',
    as HashRef[ControlPlaneEncryption()];

declare 'MaintenanceEvent',
    as InstanceOf['Google::Cloud::Edgecontainer::V1::Resources::Cluster::MaintenanceEvent'];

coerce 'MaintenanceEvent',
    from HashRef, via { 'Google::Cloud::Edgecontainer::V1::Resources::Cluster::MaintenanceEvent'->new($_) };

declare 'RepeatedMaintenanceEvent',
    as ArrayRef[MaintenanceEvent()];

coerce 'RepeatedMaintenanceEvent',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Edgecontainer::V1::Resources::Cluster::MaintenanceEvent'->new($_) } @$_ ] };

declare 'MapStringMaintenanceEvent',
    as HashRef[MaintenanceEvent()];

declare 'Type',
    as (Int | Str);

declare 'Schedule',
    as (Int | Str);

declare 'State',
    as (Int | Str);

declare 'SurvivabilityConfig',
    as InstanceOf['Google::Cloud::Edgecontainer::V1::Resources::Cluster::SurvivabilityConfig'];

coerce 'SurvivabilityConfig',
    from HashRef, via { 'Google::Cloud::Edgecontainer::V1::Resources::Cluster::SurvivabilityConfig'->new($_) };

declare 'RepeatedSurvivabilityConfig',
    as ArrayRef[SurvivabilityConfig()];

coerce 'RepeatedSurvivabilityConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Edgecontainer::V1::Resources::Cluster::SurvivabilityConfig'->new($_) } @$_ ] };

declare 'MapStringSurvivabilityConfig',
    as HashRef[SurvivabilityConfig()];

declare 'ConnectionState',
    as InstanceOf['Google::Cloud::Edgecontainer::V1::Resources::Cluster::ConnectionState'];

coerce 'ConnectionState',
    from HashRef, via { 'Google::Cloud::Edgecontainer::V1::Resources::Cluster::ConnectionState'->new($_) };

declare 'RepeatedConnectionState',
    as ArrayRef[ConnectionState()];

coerce 'RepeatedConnectionState',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Edgecontainer::V1::Resources::Cluster::ConnectionState'->new($_) } @$_ ] };

declare 'MapStringConnectionState',
    as HashRef[ConnectionState()];

declare 'State',
    as (Int | Str);

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Edgecontainer::V1::Resources::Cluster::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Edgecontainer::V1::Resources::Cluster::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Edgecontainer::V1::Resources::Cluster::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'ClusterNetworking',
    as InstanceOf['Google::Cloud::Edgecontainer::V1::Resources::ClusterNetworking'];

coerce 'ClusterNetworking',
    from HashRef, via { 'Google::Cloud::Edgecontainer::V1::Resources::ClusterNetworking'->new($_) };

declare 'RepeatedClusterNetworking',
    as ArrayRef[ClusterNetworking()];

coerce 'RepeatedClusterNetworking',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Edgecontainer::V1::Resources::ClusterNetworking'->new($_) } @$_ ] };

declare 'MapStringClusterNetworking',
    as HashRef[ClusterNetworking()];

declare 'Fleet',
    as InstanceOf['Google::Cloud::Edgecontainer::V1::Resources::Fleet'];

coerce 'Fleet',
    from HashRef, via { 'Google::Cloud::Edgecontainer::V1::Resources::Fleet'->new($_) };

declare 'RepeatedFleet',
    as ArrayRef[Fleet()];

coerce 'RepeatedFleet',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Edgecontainer::V1::Resources::Fleet'->new($_) } @$_ ] };

declare 'MapStringFleet',
    as HashRef[Fleet()];

declare 'ClusterUser',
    as InstanceOf['Google::Cloud::Edgecontainer::V1::Resources::ClusterUser'];

coerce 'ClusterUser',
    from HashRef, via { 'Google::Cloud::Edgecontainer::V1::Resources::ClusterUser'->new($_) };

declare 'RepeatedClusterUser',
    as ArrayRef[ClusterUser()];

coerce 'RepeatedClusterUser',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Edgecontainer::V1::Resources::ClusterUser'->new($_) } @$_ ] };

declare 'MapStringClusterUser',
    as HashRef[ClusterUser()];

declare 'Authorization',
    as InstanceOf['Google::Cloud::Edgecontainer::V1::Resources::Authorization'];

coerce 'Authorization',
    from HashRef, via { 'Google::Cloud::Edgecontainer::V1::Resources::Authorization'->new($_) };

declare 'RepeatedAuthorization',
    as ArrayRef[Authorization()];

coerce 'RepeatedAuthorization',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Edgecontainer::V1::Resources::Authorization'->new($_) } @$_ ] };

declare 'MapStringAuthorization',
    as HashRef[Authorization()];

declare 'NodePool',
    as InstanceOf['Google::Cloud::Edgecontainer::V1::Resources::NodePool'];

coerce 'NodePool',
    from HashRef, via { 'Google::Cloud::Edgecontainer::V1::Resources::NodePool'->new($_) };

declare 'RepeatedNodePool',
    as ArrayRef[NodePool()];

coerce 'RepeatedNodePool',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Edgecontainer::V1::Resources::NodePool'->new($_) } @$_ ] };

declare 'MapStringNodePool',
    as HashRef[NodePool()];

declare 'LocalDiskEncryption',
    as InstanceOf['Google::Cloud::Edgecontainer::V1::Resources::NodePool::LocalDiskEncryption'];

coerce 'LocalDiskEncryption',
    from HashRef, via { 'Google::Cloud::Edgecontainer::V1::Resources::NodePool::LocalDiskEncryption'->new($_) };

declare 'RepeatedLocalDiskEncryption',
    as ArrayRef[LocalDiskEncryption()];

coerce 'RepeatedLocalDiskEncryption',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Edgecontainer::V1::Resources::NodePool::LocalDiskEncryption'->new($_) } @$_ ] };

declare 'MapStringLocalDiskEncryption',
    as HashRef[LocalDiskEncryption()];

declare 'NodeConfig',
    as InstanceOf['Google::Cloud::Edgecontainer::V1::Resources::NodePool::NodeConfig'];

coerce 'NodeConfig',
    from HashRef, via { 'Google::Cloud::Edgecontainer::V1::Resources::NodePool::NodeConfig'->new($_) };

declare 'RepeatedNodeConfig',
    as ArrayRef[NodeConfig()];

coerce 'RepeatedNodeConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Edgecontainer::V1::Resources::NodePool::NodeConfig'->new($_) } @$_ ] };

declare 'MapStringNodeConfig',
    as HashRef[NodeConfig()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Edgecontainer::V1::Resources::NodePool::NodeConfig::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Edgecontainer::V1::Resources::NodePool::NodeConfig::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Edgecontainer::V1::Resources::NodePool::NodeConfig::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Edgecontainer::V1::Resources::NodePool::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Edgecontainer::V1::Resources::NodePool::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Edgecontainer::V1::Resources::NodePool::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'Machine',
    as InstanceOf['Google::Cloud::Edgecontainer::V1::Resources::Machine'];

coerce 'Machine',
    from HashRef, via { 'Google::Cloud::Edgecontainer::V1::Resources::Machine'->new($_) };

declare 'RepeatedMachine',
    as ArrayRef[Machine()];

coerce 'RepeatedMachine',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Edgecontainer::V1::Resources::Machine'->new($_) } @$_ ] };

declare 'MapStringMachine',
    as HashRef[Machine()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Edgecontainer::V1::Resources::Machine::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Edgecontainer::V1::Resources::Machine::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Edgecontainer::V1::Resources::Machine::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'VpnConnection',
    as InstanceOf['Google::Cloud::Edgecontainer::V1::Resources::VpnConnection'];

coerce 'VpnConnection',
    from HashRef, via { 'Google::Cloud::Edgecontainer::V1::Resources::VpnConnection'->new($_) };

declare 'RepeatedVpnConnection',
    as ArrayRef[VpnConnection()];

coerce 'RepeatedVpnConnection',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Edgecontainer::V1::Resources::VpnConnection'->new($_) } @$_ ] };

declare 'MapStringVpnConnection',
    as HashRef[VpnConnection()];

declare 'BgpRoutingMode',
    as (Int | Str);

declare 'VpcProject',
    as InstanceOf['Google::Cloud::Edgecontainer::V1::Resources::VpnConnection::VpcProject'];

coerce 'VpcProject',
    from HashRef, via { 'Google::Cloud::Edgecontainer::V1::Resources::VpnConnection::VpcProject'->new($_) };

declare 'RepeatedVpcProject',
    as ArrayRef[VpcProject()];

coerce 'RepeatedVpcProject',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Edgecontainer::V1::Resources::VpnConnection::VpcProject'->new($_) } @$_ ] };

declare 'MapStringVpcProject',
    as HashRef[VpcProject()];

declare 'Details',
    as InstanceOf['Google::Cloud::Edgecontainer::V1::Resources::VpnConnection::Details'];

coerce 'Details',
    from HashRef, via { 'Google::Cloud::Edgecontainer::V1::Resources::VpnConnection::Details'->new($_) };

declare 'RepeatedDetails',
    as ArrayRef[Details()];

coerce 'RepeatedDetails',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Edgecontainer::V1::Resources::VpnConnection::Details'->new($_) } @$_ ] };

declare 'MapStringDetails',
    as HashRef[Details()];

declare 'State',
    as (Int | Str);

declare 'CloudRouter',
    as InstanceOf['Google::Cloud::Edgecontainer::V1::Resources::VpnConnection::Details::CloudRouter'];

coerce 'CloudRouter',
    from HashRef, via { 'Google::Cloud::Edgecontainer::V1::Resources::VpnConnection::Details::CloudRouter'->new($_) };

declare 'RepeatedCloudRouter',
    as ArrayRef[CloudRouter()];

coerce 'RepeatedCloudRouter',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Edgecontainer::V1::Resources::VpnConnection::Details::CloudRouter'->new($_) } @$_ ] };

declare 'MapStringCloudRouter',
    as HashRef[CloudRouter()];

declare 'CloudVpn',
    as InstanceOf['Google::Cloud::Edgecontainer::V1::Resources::VpnConnection::Details::CloudVpn'];

coerce 'CloudVpn',
    from HashRef, via { 'Google::Cloud::Edgecontainer::V1::Resources::VpnConnection::Details::CloudVpn'->new($_) };

declare 'RepeatedCloudVpn',
    as ArrayRef[CloudVpn()];

coerce 'RepeatedCloudVpn',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Edgecontainer::V1::Resources::VpnConnection::Details::CloudVpn'->new($_) } @$_ ] };

declare 'MapStringCloudVpn',
    as HashRef[CloudVpn()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Edgecontainer::V1::Resources::VpnConnection::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Edgecontainer::V1::Resources::VpnConnection::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Edgecontainer::V1::Resources::VpnConnection::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'LocationMetadata',
    as InstanceOf['Google::Cloud::Edgecontainer::V1::Resources::LocationMetadata'];

coerce 'LocationMetadata',
    from HashRef, via { 'Google::Cloud::Edgecontainer::V1::Resources::LocationMetadata'->new($_) };

declare 'RepeatedLocationMetadata',
    as ArrayRef[LocationMetadata()];

coerce 'RepeatedLocationMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Edgecontainer::V1::Resources::LocationMetadata'->new($_) } @$_ ] };

declare 'MapStringLocationMetadata',
    as HashRef[LocationMetadata()];

declare 'AvailableZonesEntry',
    as InstanceOf['Google::Cloud::Edgecontainer::V1::Resources::LocationMetadata::AvailableZonesEntry'];

coerce 'AvailableZonesEntry',
    from HashRef, via { 'Google::Cloud::Edgecontainer::V1::Resources::LocationMetadata::AvailableZonesEntry'->new($_) };

declare 'RepeatedAvailableZonesEntry',
    as ArrayRef[AvailableZonesEntry()];

coerce 'RepeatedAvailableZonesEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Edgecontainer::V1::Resources::LocationMetadata::AvailableZonesEntry'->new($_) } @$_ ] };

declare 'MapStringAvailableZonesEntry',
    as HashRef[AvailableZonesEntry()];

declare 'ZoneMetadata',
    as InstanceOf['Google::Cloud::Edgecontainer::V1::Resources::ZoneMetadata'];

coerce 'ZoneMetadata',
    from HashRef, via { 'Google::Cloud::Edgecontainer::V1::Resources::ZoneMetadata'->new($_) };

declare 'RepeatedZoneMetadata',
    as ArrayRef[ZoneMetadata()];

coerce 'RepeatedZoneMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Edgecontainer::V1::Resources::ZoneMetadata'->new($_) } @$_ ] };

declare 'MapStringZoneMetadata',
    as HashRef[ZoneMetadata()];

declare 'RackType',
    as (Int | Str);

declare 'RackTypesEntry',
    as InstanceOf['Google::Cloud::Edgecontainer::V1::Resources::ZoneMetadata::RackTypesEntry'];

coerce 'RackTypesEntry',
    from HashRef, via { 'Google::Cloud::Edgecontainer::V1::Resources::ZoneMetadata::RackTypesEntry'->new($_) };

declare 'RepeatedRackTypesEntry',
    as ArrayRef[RackTypesEntry()];

coerce 'RepeatedRackTypesEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Edgecontainer::V1::Resources::ZoneMetadata::RackTypesEntry'->new($_) } @$_ ] };

declare 'MapStringRackTypesEntry',
    as HashRef[RackTypesEntry()];

declare 'ConfigData',
    as InstanceOf['Google::Cloud::Edgecontainer::V1::Resources::ConfigData'];

coerce 'ConfigData',
    from HashRef, via { 'Google::Cloud::Edgecontainer::V1::Resources::ConfigData'->new($_) };

declare 'RepeatedConfigData',
    as ArrayRef[ConfigData()];

coerce 'RepeatedConfigData',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Edgecontainer::V1::Resources::ConfigData'->new($_) } @$_ ] };

declare 'MapStringConfigData',
    as HashRef[ConfigData()];

declare 'Quota',
    as InstanceOf['Google::Cloud::Edgecontainer::V1::Resources::Quota'];

coerce 'Quota',
    from HashRef, via { 'Google::Cloud::Edgecontainer::V1::Resources::Quota'->new($_) };

declare 'RepeatedQuota',
    as ArrayRef[Quota()];

coerce 'RepeatedQuota',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Edgecontainer::V1::Resources::Quota'->new($_) } @$_ ] };

declare 'MapStringQuota',
    as HashRef[Quota()];

declare 'MaintenancePolicy',
    as InstanceOf['Google::Cloud::Edgecontainer::V1::Resources::MaintenancePolicy'];

coerce 'MaintenancePolicy',
    from HashRef, via { 'Google::Cloud::Edgecontainer::V1::Resources::MaintenancePolicy'->new($_) };

declare 'RepeatedMaintenancePolicy',
    as ArrayRef[MaintenancePolicy()];

coerce 'RepeatedMaintenancePolicy',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Edgecontainer::V1::Resources::MaintenancePolicy'->new($_) } @$_ ] };

declare 'MapStringMaintenancePolicy',
    as HashRef[MaintenancePolicy()];

declare 'MaintenanceWindow',
    as InstanceOf['Google::Cloud::Edgecontainer::V1::Resources::MaintenanceWindow'];

coerce 'MaintenanceWindow',
    from HashRef, via { 'Google::Cloud::Edgecontainer::V1::Resources::MaintenanceWindow'->new($_) };

declare 'RepeatedMaintenanceWindow',
    as ArrayRef[MaintenanceWindow()];

coerce 'RepeatedMaintenanceWindow',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Edgecontainer::V1::Resources::MaintenanceWindow'->new($_) } @$_ ] };

declare 'MapStringMaintenanceWindow',
    as HashRef[MaintenanceWindow()];

declare 'RecurringTimeWindow',
    as InstanceOf['Google::Cloud::Edgecontainer::V1::Resources::RecurringTimeWindow'];

coerce 'RecurringTimeWindow',
    from HashRef, via { 'Google::Cloud::Edgecontainer::V1::Resources::RecurringTimeWindow'->new($_) };

declare 'RepeatedRecurringTimeWindow',
    as ArrayRef[RecurringTimeWindow()];

coerce 'RepeatedRecurringTimeWindow',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Edgecontainer::V1::Resources::RecurringTimeWindow'->new($_) } @$_ ] };

declare 'MapStringRecurringTimeWindow',
    as HashRef[RecurringTimeWindow()];

declare 'MaintenanceExclusionWindow',
    as InstanceOf['Google::Cloud::Edgecontainer::V1::Resources::MaintenanceExclusionWindow'];

coerce 'MaintenanceExclusionWindow',
    from HashRef, via { 'Google::Cloud::Edgecontainer::V1::Resources::MaintenanceExclusionWindow'->new($_) };

declare 'RepeatedMaintenanceExclusionWindow',
    as ArrayRef[MaintenanceExclusionWindow()];

coerce 'RepeatedMaintenanceExclusionWindow',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Edgecontainer::V1::Resources::MaintenanceExclusionWindow'->new($_) } @$_ ] };

declare 'MapStringMaintenanceExclusionWindow',
    as HashRef[MaintenanceExclusionWindow()];

declare 'TimeWindow',
    as InstanceOf['Google::Cloud::Edgecontainer::V1::Resources::TimeWindow'];

coerce 'TimeWindow',
    from HashRef, via { 'Google::Cloud::Edgecontainer::V1::Resources::TimeWindow'->new($_) };

declare 'RepeatedTimeWindow',
    as ArrayRef[TimeWindow()];

coerce 'RepeatedTimeWindow',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Edgecontainer::V1::Resources::TimeWindow'->new($_) } @$_ ] };

declare 'MapStringTimeWindow',
    as HashRef[TimeWindow()];

declare 'ServerConfig',
    as InstanceOf['Google::Cloud::Edgecontainer::V1::Resources::ServerConfig'];

coerce 'ServerConfig',
    from HashRef, via { 'Google::Cloud::Edgecontainer::V1::Resources::ServerConfig'->new($_) };

declare 'RepeatedServerConfig',
    as ArrayRef[ServerConfig()];

coerce 'RepeatedServerConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Edgecontainer::V1::Resources::ServerConfig'->new($_) } @$_ ] };

declare 'MapStringServerConfig',
    as HashRef[ServerConfig()];

declare 'ChannelsEntry',
    as InstanceOf['Google::Cloud::Edgecontainer::V1::Resources::ServerConfig::ChannelsEntry'];

coerce 'ChannelsEntry',
    from HashRef, via { 'Google::Cloud::Edgecontainer::V1::Resources::ServerConfig::ChannelsEntry'->new($_) };

declare 'RepeatedChannelsEntry',
    as ArrayRef[ChannelsEntry()];

coerce 'RepeatedChannelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Edgecontainer::V1::Resources::ServerConfig::ChannelsEntry'->new($_) } @$_ ] };

declare 'MapStringChannelsEntry',
    as HashRef[ChannelsEntry()];

declare 'ChannelConfig',
    as InstanceOf['Google::Cloud::Edgecontainer::V1::Resources::ChannelConfig'];

coerce 'ChannelConfig',
    from HashRef, via { 'Google::Cloud::Edgecontainer::V1::Resources::ChannelConfig'->new($_) };

declare 'RepeatedChannelConfig',
    as ArrayRef[ChannelConfig()];

coerce 'RepeatedChannelConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Edgecontainer::V1::Resources::ChannelConfig'->new($_) } @$_ ] };

declare 'MapStringChannelConfig',
    as HashRef[ChannelConfig()];

declare 'Version',
    as InstanceOf['Google::Cloud::Edgecontainer::V1::Resources::Version'];

coerce 'Version',
    from HashRef, via { 'Google::Cloud::Edgecontainer::V1::Resources::Version'->new($_) };

declare 'RepeatedVersion',
    as ArrayRef[Version()];

coerce 'RepeatedVersion',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Edgecontainer::V1::Resources::Version'->new($_) } @$_ ] };

declare 'MapStringVersion',
    as HashRef[Version()];

1;

__END__

=head1 NAME

Google::Cloud::Edgecontainer::V1::Resources::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
