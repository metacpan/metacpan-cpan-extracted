package Google::Cloud::Vmwareengine::V1::VmwareengineResources::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'NetworkConfig',
    as InstanceOf['Google::Cloud::Vmwareengine::V1::VmwareengineResources::NetworkConfig'];

coerce 'NetworkConfig',
    from HashRef, via { 'Google::Cloud::Vmwareengine::V1::VmwareengineResources::NetworkConfig'->new($_) };

declare 'RepeatedNetworkConfig',
    as ArrayRef[NetworkConfig()];

coerce 'RepeatedNetworkConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmwareengine::V1::VmwareengineResources::NetworkConfig'->new($_) } @$_ ] };

declare 'MapStringNetworkConfig',
    as HashRef[NetworkConfig()];

declare 'NodeTypeConfig',
    as InstanceOf['Google::Cloud::Vmwareengine::V1::VmwareengineResources::NodeTypeConfig'];

coerce 'NodeTypeConfig',
    from HashRef, via { 'Google::Cloud::Vmwareengine::V1::VmwareengineResources::NodeTypeConfig'->new($_) };

declare 'RepeatedNodeTypeConfig',
    as ArrayRef[NodeTypeConfig()];

coerce 'RepeatedNodeTypeConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmwareengine::V1::VmwareengineResources::NodeTypeConfig'->new($_) } @$_ ] };

declare 'MapStringNodeTypeConfig',
    as HashRef[NodeTypeConfig()];

declare 'StretchedClusterConfig',
    as InstanceOf['Google::Cloud::Vmwareengine::V1::VmwareengineResources::StretchedClusterConfig'];

coerce 'StretchedClusterConfig',
    from HashRef, via { 'Google::Cloud::Vmwareengine::V1::VmwareengineResources::StretchedClusterConfig'->new($_) };

declare 'RepeatedStretchedClusterConfig',
    as ArrayRef[StretchedClusterConfig()];

coerce 'RepeatedStretchedClusterConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmwareengine::V1::VmwareengineResources::StretchedClusterConfig'->new($_) } @$_ ] };

declare 'MapStringStretchedClusterConfig',
    as HashRef[StretchedClusterConfig()];

declare 'PrivateCloud',
    as InstanceOf['Google::Cloud::Vmwareengine::V1::VmwareengineResources::PrivateCloud'];

coerce 'PrivateCloud',
    from HashRef, via { 'Google::Cloud::Vmwareengine::V1::VmwareengineResources::PrivateCloud'->new($_) };

declare 'RepeatedPrivateCloud',
    as ArrayRef[PrivateCloud()];

coerce 'RepeatedPrivateCloud',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmwareengine::V1::VmwareengineResources::PrivateCloud'->new($_) } @$_ ] };

declare 'MapStringPrivateCloud',
    as HashRef[PrivateCloud()];

declare 'State',
    as (Int | Str);

declare 'Type',
    as (Int | Str);

declare 'ManagementCluster',
    as InstanceOf['Google::Cloud::Vmwareengine::V1::VmwareengineResources::PrivateCloud::ManagementCluster'];

coerce 'ManagementCluster',
    from HashRef, via { 'Google::Cloud::Vmwareengine::V1::VmwareengineResources::PrivateCloud::ManagementCluster'->new($_) };

declare 'RepeatedManagementCluster',
    as ArrayRef[ManagementCluster()];

coerce 'RepeatedManagementCluster',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmwareengine::V1::VmwareengineResources::PrivateCloud::ManagementCluster'->new($_) } @$_ ] };

declare 'MapStringManagementCluster',
    as HashRef[ManagementCluster()];

declare 'NodeTypeConfigsEntry',
    as InstanceOf['Google::Cloud::Vmwareengine::V1::VmwareengineResources::PrivateCloud::ManagementCluster::NodeTypeConfigsEntry'];

coerce 'NodeTypeConfigsEntry',
    from HashRef, via { 'Google::Cloud::Vmwareengine::V1::VmwareengineResources::PrivateCloud::ManagementCluster::NodeTypeConfigsEntry'->new($_) };

declare 'RepeatedNodeTypeConfigsEntry',
    as ArrayRef[NodeTypeConfigsEntry()];

coerce 'RepeatedNodeTypeConfigsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmwareengine::V1::VmwareengineResources::PrivateCloud::ManagementCluster::NodeTypeConfigsEntry'->new($_) } @$_ ] };

declare 'MapStringNodeTypeConfigsEntry',
    as HashRef[NodeTypeConfigsEntry()];

declare 'Cluster',
    as InstanceOf['Google::Cloud::Vmwareengine::V1::VmwareengineResources::Cluster'];

coerce 'Cluster',
    from HashRef, via { 'Google::Cloud::Vmwareengine::V1::VmwareengineResources::Cluster'->new($_) };

declare 'RepeatedCluster',
    as ArrayRef[Cluster()];

coerce 'RepeatedCluster',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmwareengine::V1::VmwareengineResources::Cluster'->new($_) } @$_ ] };

declare 'MapStringCluster',
    as HashRef[Cluster()];

declare 'State',
    as (Int | Str);

declare 'NodeTypeConfigsEntry',
    as InstanceOf['Google::Cloud::Vmwareengine::V1::VmwareengineResources::Cluster::NodeTypeConfigsEntry'];

coerce 'NodeTypeConfigsEntry',
    from HashRef, via { 'Google::Cloud::Vmwareengine::V1::VmwareengineResources::Cluster::NodeTypeConfigsEntry'->new($_) };

declare 'RepeatedNodeTypeConfigsEntry',
    as ArrayRef[NodeTypeConfigsEntry()];

coerce 'RepeatedNodeTypeConfigsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmwareengine::V1::VmwareengineResources::Cluster::NodeTypeConfigsEntry'->new($_) } @$_ ] };

declare 'MapStringNodeTypeConfigsEntry',
    as HashRef[NodeTypeConfigsEntry()];

declare 'Node',
    as InstanceOf['Google::Cloud::Vmwareengine::V1::VmwareengineResources::Node'];

coerce 'Node',
    from HashRef, via { 'Google::Cloud::Vmwareengine::V1::VmwareengineResources::Node'->new($_) };

declare 'RepeatedNode',
    as ArrayRef[Node()];

coerce 'RepeatedNode',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmwareengine::V1::VmwareengineResources::Node'->new($_) } @$_ ] };

declare 'MapStringNode',
    as HashRef[Node()];

declare 'State',
    as (Int | Str);

declare 'ExternalAddress',
    as InstanceOf['Google::Cloud::Vmwareengine::V1::VmwareengineResources::ExternalAddress'];

coerce 'ExternalAddress',
    from HashRef, via { 'Google::Cloud::Vmwareengine::V1::VmwareengineResources::ExternalAddress'->new($_) };

declare 'RepeatedExternalAddress',
    as ArrayRef[ExternalAddress()];

coerce 'RepeatedExternalAddress',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmwareengine::V1::VmwareengineResources::ExternalAddress'->new($_) } @$_ ] };

declare 'MapStringExternalAddress',
    as HashRef[ExternalAddress()];

declare 'State',
    as (Int | Str);

declare 'Subnet',
    as InstanceOf['Google::Cloud::Vmwareengine::V1::VmwareengineResources::Subnet'];

coerce 'Subnet',
    from HashRef, via { 'Google::Cloud::Vmwareengine::V1::VmwareengineResources::Subnet'->new($_) };

declare 'RepeatedSubnet',
    as ArrayRef[Subnet()];

coerce 'RepeatedSubnet',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmwareengine::V1::VmwareengineResources::Subnet'->new($_) } @$_ ] };

declare 'MapStringSubnet',
    as HashRef[Subnet()];

declare 'State',
    as (Int | Str);

declare 'ExternalAccessRule',
    as InstanceOf['Google::Cloud::Vmwareengine::V1::VmwareengineResources::ExternalAccessRule'];

coerce 'ExternalAccessRule',
    from HashRef, via { 'Google::Cloud::Vmwareengine::V1::VmwareengineResources::ExternalAccessRule'->new($_) };

declare 'RepeatedExternalAccessRule',
    as ArrayRef[ExternalAccessRule()];

coerce 'RepeatedExternalAccessRule',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmwareengine::V1::VmwareengineResources::ExternalAccessRule'->new($_) } @$_ ] };

declare 'MapStringExternalAccessRule',
    as HashRef[ExternalAccessRule()];

declare 'Action',
    as (Int | Str);

declare 'State',
    as (Int | Str);

declare 'IpRange',
    as InstanceOf['Google::Cloud::Vmwareengine::V1::VmwareengineResources::ExternalAccessRule::IpRange'];

coerce 'IpRange',
    from HashRef, via { 'Google::Cloud::Vmwareengine::V1::VmwareengineResources::ExternalAccessRule::IpRange'->new($_) };

declare 'RepeatedIpRange',
    as ArrayRef[IpRange()];

coerce 'RepeatedIpRange',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmwareengine::V1::VmwareengineResources::ExternalAccessRule::IpRange'->new($_) } @$_ ] };

declare 'MapStringIpRange',
    as HashRef[IpRange()];

declare 'LoggingServer',
    as InstanceOf['Google::Cloud::Vmwareengine::V1::VmwareengineResources::LoggingServer'];

coerce 'LoggingServer',
    from HashRef, via { 'Google::Cloud::Vmwareengine::V1::VmwareengineResources::LoggingServer'->new($_) };

declare 'RepeatedLoggingServer',
    as ArrayRef[LoggingServer()];

coerce 'RepeatedLoggingServer',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmwareengine::V1::VmwareengineResources::LoggingServer'->new($_) } @$_ ] };

declare 'MapStringLoggingServer',
    as HashRef[LoggingServer()];

declare 'Protocol',
    as (Int | Str);

declare 'SourceType',
    as (Int | Str);

declare 'NodeType',
    as InstanceOf['Google::Cloud::Vmwareengine::V1::VmwareengineResources::NodeType'];

coerce 'NodeType',
    from HashRef, via { 'Google::Cloud::Vmwareengine::V1::VmwareengineResources::NodeType'->new($_) };

declare 'RepeatedNodeType',
    as ArrayRef[NodeType()];

coerce 'RepeatedNodeType',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmwareengine::V1::VmwareengineResources::NodeType'->new($_) } @$_ ] };

declare 'MapStringNodeType',
    as HashRef[NodeType()];

declare 'Kind',
    as (Int | Str);

declare 'Capability',
    as (Int | Str);

declare 'Credentials',
    as InstanceOf['Google::Cloud::Vmwareengine::V1::VmwareengineResources::Credentials'];

coerce 'Credentials',
    from HashRef, via { 'Google::Cloud::Vmwareengine::V1::VmwareengineResources::Credentials'->new($_) };

declare 'RepeatedCredentials',
    as ArrayRef[Credentials()];

coerce 'RepeatedCredentials',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmwareengine::V1::VmwareengineResources::Credentials'->new($_) } @$_ ] };

declare 'MapStringCredentials',
    as HashRef[Credentials()];

declare 'HcxActivationKey',
    as InstanceOf['Google::Cloud::Vmwareengine::V1::VmwareengineResources::HcxActivationKey'];

coerce 'HcxActivationKey',
    from HashRef, via { 'Google::Cloud::Vmwareengine::V1::VmwareengineResources::HcxActivationKey'->new($_) };

declare 'RepeatedHcxActivationKey',
    as ArrayRef[HcxActivationKey()];

coerce 'RepeatedHcxActivationKey',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmwareengine::V1::VmwareengineResources::HcxActivationKey'->new($_) } @$_ ] };

declare 'MapStringHcxActivationKey',
    as HashRef[HcxActivationKey()];

declare 'State',
    as (Int | Str);

declare 'Hcx',
    as InstanceOf['Google::Cloud::Vmwareengine::V1::VmwareengineResources::Hcx'];

coerce 'Hcx',
    from HashRef, via { 'Google::Cloud::Vmwareengine::V1::VmwareengineResources::Hcx'->new($_) };

declare 'RepeatedHcx',
    as ArrayRef[Hcx()];

coerce 'RepeatedHcx',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmwareengine::V1::VmwareengineResources::Hcx'->new($_) } @$_ ] };

declare 'MapStringHcx',
    as HashRef[Hcx()];

declare 'State',
    as (Int | Str);

declare 'Nsx',
    as InstanceOf['Google::Cloud::Vmwareengine::V1::VmwareengineResources::Nsx'];

coerce 'Nsx',
    from HashRef, via { 'Google::Cloud::Vmwareengine::V1::VmwareengineResources::Nsx'->new($_) };

declare 'RepeatedNsx',
    as ArrayRef[Nsx()];

coerce 'RepeatedNsx',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmwareengine::V1::VmwareengineResources::Nsx'->new($_) } @$_ ] };

declare 'MapStringNsx',
    as HashRef[Nsx()];

declare 'State',
    as (Int | Str);

declare 'Vcenter',
    as InstanceOf['Google::Cloud::Vmwareengine::V1::VmwareengineResources::Vcenter'];

coerce 'Vcenter',
    from HashRef, via { 'Google::Cloud::Vmwareengine::V1::VmwareengineResources::Vcenter'->new($_) };

declare 'RepeatedVcenter',
    as ArrayRef[Vcenter()];

coerce 'RepeatedVcenter',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmwareengine::V1::VmwareengineResources::Vcenter'->new($_) } @$_ ] };

declare 'MapStringVcenter',
    as HashRef[Vcenter()];

declare 'State',
    as (Int | Str);

declare 'AutoscalingSettings',
    as InstanceOf['Google::Cloud::Vmwareengine::V1::VmwareengineResources::AutoscalingSettings'];

coerce 'AutoscalingSettings',
    from HashRef, via { 'Google::Cloud::Vmwareengine::V1::VmwareengineResources::AutoscalingSettings'->new($_) };

declare 'RepeatedAutoscalingSettings',
    as ArrayRef[AutoscalingSettings()];

coerce 'RepeatedAutoscalingSettings',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmwareengine::V1::VmwareengineResources::AutoscalingSettings'->new($_) } @$_ ] };

declare 'MapStringAutoscalingSettings',
    as HashRef[AutoscalingSettings()];

declare 'Thresholds',
    as InstanceOf['Google::Cloud::Vmwareengine::V1::VmwareengineResources::AutoscalingSettings::Thresholds'];

coerce 'Thresholds',
    from HashRef, via { 'Google::Cloud::Vmwareengine::V1::VmwareengineResources::AutoscalingSettings::Thresholds'->new($_) };

declare 'RepeatedThresholds',
    as ArrayRef[Thresholds()];

coerce 'RepeatedThresholds',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmwareengine::V1::VmwareengineResources::AutoscalingSettings::Thresholds'->new($_) } @$_ ] };

declare 'MapStringThresholds',
    as HashRef[Thresholds()];

declare 'AutoscalingPolicy',
    as InstanceOf['Google::Cloud::Vmwareengine::V1::VmwareengineResources::AutoscalingSettings::AutoscalingPolicy'];

coerce 'AutoscalingPolicy',
    from HashRef, via { 'Google::Cloud::Vmwareengine::V1::VmwareengineResources::AutoscalingSettings::AutoscalingPolicy'->new($_) };

declare 'RepeatedAutoscalingPolicy',
    as ArrayRef[AutoscalingPolicy()];

coerce 'RepeatedAutoscalingPolicy',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmwareengine::V1::VmwareengineResources::AutoscalingSettings::AutoscalingPolicy'->new($_) } @$_ ] };

declare 'MapStringAutoscalingPolicy',
    as HashRef[AutoscalingPolicy()];

declare 'AutoscalingPoliciesEntry',
    as InstanceOf['Google::Cloud::Vmwareengine::V1::VmwareengineResources::AutoscalingSettings::AutoscalingPoliciesEntry'];

coerce 'AutoscalingPoliciesEntry',
    from HashRef, via { 'Google::Cloud::Vmwareengine::V1::VmwareengineResources::AutoscalingSettings::AutoscalingPoliciesEntry'->new($_) };

declare 'RepeatedAutoscalingPoliciesEntry',
    as ArrayRef[AutoscalingPoliciesEntry()];

coerce 'RepeatedAutoscalingPoliciesEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmwareengine::V1::VmwareengineResources::AutoscalingSettings::AutoscalingPoliciesEntry'->new($_) } @$_ ] };

declare 'MapStringAutoscalingPoliciesEntry',
    as HashRef[AutoscalingPoliciesEntry()];

declare 'DnsForwarding',
    as InstanceOf['Google::Cloud::Vmwareengine::V1::VmwareengineResources::DnsForwarding'];

coerce 'DnsForwarding',
    from HashRef, via { 'Google::Cloud::Vmwareengine::V1::VmwareengineResources::DnsForwarding'->new($_) };

declare 'RepeatedDnsForwarding',
    as ArrayRef[DnsForwarding()];

coerce 'RepeatedDnsForwarding',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmwareengine::V1::VmwareengineResources::DnsForwarding'->new($_) } @$_ ] };

declare 'MapStringDnsForwarding',
    as HashRef[DnsForwarding()];

declare 'ForwardingRule',
    as InstanceOf['Google::Cloud::Vmwareengine::V1::VmwareengineResources::DnsForwarding::ForwardingRule'];

coerce 'ForwardingRule',
    from HashRef, via { 'Google::Cloud::Vmwareengine::V1::VmwareengineResources::DnsForwarding::ForwardingRule'->new($_) };

declare 'RepeatedForwardingRule',
    as ArrayRef[ForwardingRule()];

coerce 'RepeatedForwardingRule',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmwareengine::V1::VmwareengineResources::DnsForwarding::ForwardingRule'->new($_) } @$_ ] };

declare 'MapStringForwardingRule',
    as HashRef[ForwardingRule()];

declare 'NetworkPeering',
    as InstanceOf['Google::Cloud::Vmwareengine::V1::VmwareengineResources::NetworkPeering'];

coerce 'NetworkPeering',
    from HashRef, via { 'Google::Cloud::Vmwareengine::V1::VmwareengineResources::NetworkPeering'->new($_) };

declare 'RepeatedNetworkPeering',
    as ArrayRef[NetworkPeering()];

coerce 'RepeatedNetworkPeering',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmwareengine::V1::VmwareengineResources::NetworkPeering'->new($_) } @$_ ] };

declare 'MapStringNetworkPeering',
    as HashRef[NetworkPeering()];

declare 'State',
    as (Int | Str);

declare 'PeerNetworkType',
    as (Int | Str);

declare 'PeeringRoute',
    as InstanceOf['Google::Cloud::Vmwareengine::V1::VmwareengineResources::PeeringRoute'];

coerce 'PeeringRoute',
    from HashRef, via { 'Google::Cloud::Vmwareengine::V1::VmwareengineResources::PeeringRoute'->new($_) };

declare 'RepeatedPeeringRoute',
    as ArrayRef[PeeringRoute()];

coerce 'RepeatedPeeringRoute',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmwareengine::V1::VmwareengineResources::PeeringRoute'->new($_) } @$_ ] };

declare 'MapStringPeeringRoute',
    as HashRef[PeeringRoute()];

declare 'Type',
    as (Int | Str);

declare 'Direction',
    as (Int | Str);

declare 'NetworkPolicy',
    as InstanceOf['Google::Cloud::Vmwareengine::V1::VmwareengineResources::NetworkPolicy'];

coerce 'NetworkPolicy',
    from HashRef, via { 'Google::Cloud::Vmwareengine::V1::VmwareengineResources::NetworkPolicy'->new($_) };

declare 'RepeatedNetworkPolicy',
    as ArrayRef[NetworkPolicy()];

coerce 'RepeatedNetworkPolicy',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmwareengine::V1::VmwareengineResources::NetworkPolicy'->new($_) } @$_ ] };

declare 'MapStringNetworkPolicy',
    as HashRef[NetworkPolicy()];

declare 'NetworkService',
    as InstanceOf['Google::Cloud::Vmwareengine::V1::VmwareengineResources::NetworkPolicy::NetworkService'];

coerce 'NetworkService',
    from HashRef, via { 'Google::Cloud::Vmwareengine::V1::VmwareengineResources::NetworkPolicy::NetworkService'->new($_) };

declare 'RepeatedNetworkService',
    as ArrayRef[NetworkService()];

coerce 'RepeatedNetworkService',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmwareengine::V1::VmwareengineResources::NetworkPolicy::NetworkService'->new($_) } @$_ ] };

declare 'MapStringNetworkService',
    as HashRef[NetworkService()];

declare 'State',
    as (Int | Str);

declare 'ManagementDnsZoneBinding',
    as InstanceOf['Google::Cloud::Vmwareengine::V1::VmwareengineResources::ManagementDnsZoneBinding'];

coerce 'ManagementDnsZoneBinding',
    from HashRef, via { 'Google::Cloud::Vmwareengine::V1::VmwareengineResources::ManagementDnsZoneBinding'->new($_) };

declare 'RepeatedManagementDnsZoneBinding',
    as ArrayRef[ManagementDnsZoneBinding()];

coerce 'RepeatedManagementDnsZoneBinding',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmwareengine::V1::VmwareengineResources::ManagementDnsZoneBinding'->new($_) } @$_ ] };

declare 'MapStringManagementDnsZoneBinding',
    as HashRef[ManagementDnsZoneBinding()];

declare 'State',
    as (Int | Str);

declare 'VmwareEngineNetwork',
    as InstanceOf['Google::Cloud::Vmwareengine::V1::VmwareengineResources::VmwareEngineNetwork'];

coerce 'VmwareEngineNetwork',
    from HashRef, via { 'Google::Cloud::Vmwareengine::V1::VmwareengineResources::VmwareEngineNetwork'->new($_) };

declare 'RepeatedVmwareEngineNetwork',
    as ArrayRef[VmwareEngineNetwork()];

coerce 'RepeatedVmwareEngineNetwork',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmwareengine::V1::VmwareengineResources::VmwareEngineNetwork'->new($_) } @$_ ] };

declare 'MapStringVmwareEngineNetwork',
    as HashRef[VmwareEngineNetwork()];

declare 'State',
    as (Int | Str);

declare 'Type',
    as (Int | Str);

declare 'VpcNetwork',
    as InstanceOf['Google::Cloud::Vmwareengine::V1::VmwareengineResources::VmwareEngineNetwork::VpcNetwork'];

coerce 'VpcNetwork',
    from HashRef, via { 'Google::Cloud::Vmwareengine::V1::VmwareengineResources::VmwareEngineNetwork::VpcNetwork'->new($_) };

declare 'RepeatedVpcNetwork',
    as ArrayRef[VpcNetwork()];

coerce 'RepeatedVpcNetwork',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmwareengine::V1::VmwareengineResources::VmwareEngineNetwork::VpcNetwork'->new($_) } @$_ ] };

declare 'MapStringVpcNetwork',
    as HashRef[VpcNetwork()];

declare 'Type',
    as (Int | Str);

declare 'PrivateConnection',
    as InstanceOf['Google::Cloud::Vmwareengine::V1::VmwareengineResources::PrivateConnection'];

coerce 'PrivateConnection',
    from HashRef, via { 'Google::Cloud::Vmwareengine::V1::VmwareengineResources::PrivateConnection'->new($_) };

declare 'RepeatedPrivateConnection',
    as ArrayRef[PrivateConnection()];

coerce 'RepeatedPrivateConnection',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmwareengine::V1::VmwareengineResources::PrivateConnection'->new($_) } @$_ ] };

declare 'MapStringPrivateConnection',
    as HashRef[PrivateConnection()];

declare 'State',
    as (Int | Str);

declare 'Type',
    as (Int | Str);

declare 'RoutingMode',
    as (Int | Str);

declare 'PeeringState',
    as (Int | Str);

declare 'LocationMetadata',
    as InstanceOf['Google::Cloud::Vmwareengine::V1::VmwareengineResources::LocationMetadata'];

coerce 'LocationMetadata',
    from HashRef, via { 'Google::Cloud::Vmwareengine::V1::VmwareengineResources::LocationMetadata'->new($_) };

declare 'RepeatedLocationMetadata',
    as ArrayRef[LocationMetadata()];

coerce 'RepeatedLocationMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmwareengine::V1::VmwareengineResources::LocationMetadata'->new($_) } @$_ ] };

declare 'MapStringLocationMetadata',
    as HashRef[LocationMetadata()];

declare 'Capability',
    as (Int | Str);

declare 'DnsBindPermission',
    as InstanceOf['Google::Cloud::Vmwareengine::V1::VmwareengineResources::DnsBindPermission'];

coerce 'DnsBindPermission',
    from HashRef, via { 'Google::Cloud::Vmwareengine::V1::VmwareengineResources::DnsBindPermission'->new($_) };

declare 'RepeatedDnsBindPermission',
    as ArrayRef[DnsBindPermission()];

coerce 'RepeatedDnsBindPermission',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmwareengine::V1::VmwareengineResources::DnsBindPermission'->new($_) } @$_ ] };

declare 'MapStringDnsBindPermission',
    as HashRef[DnsBindPermission()];

declare 'Principal',
    as InstanceOf['Google::Cloud::Vmwareengine::V1::VmwareengineResources::Principal'];

coerce 'Principal',
    from HashRef, via { 'Google::Cloud::Vmwareengine::V1::VmwareengineResources::Principal'->new($_) };

declare 'RepeatedPrincipal',
    as ArrayRef[Principal()];

coerce 'RepeatedPrincipal',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmwareengine::V1::VmwareengineResources::Principal'->new($_) } @$_ ] };

declare 'MapStringPrincipal',
    as HashRef[Principal()];

1;

__END__

=head1 NAME

Google::Cloud::Vmwareengine::V1::VmwareengineResources::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
