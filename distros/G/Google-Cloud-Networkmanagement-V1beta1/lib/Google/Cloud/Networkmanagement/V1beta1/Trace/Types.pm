package Google::Cloud::Networkmanagement::V1beta1::Trace::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'LoadBalancerType',
    as (Int | Str);

declare 'Trace',
    as InstanceOf['Google::Cloud::Networkmanagement::V1beta1::Trace::Trace'];

coerce 'Trace',
    from HashRef, via { 'Google::Cloud::Networkmanagement::V1beta1::Trace::Trace'->new($_) };

declare 'RepeatedTrace',
    as ArrayRef[Trace()];

coerce 'RepeatedTrace',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkmanagement::V1beta1::Trace::Trace'->new($_) } @$_ ] };

declare 'MapStringTrace',
    as HashRef[Trace()];

declare 'Step',
    as InstanceOf['Google::Cloud::Networkmanagement::V1beta1::Trace::Step'];

coerce 'Step',
    from HashRef, via { 'Google::Cloud::Networkmanagement::V1beta1::Trace::Step'->new($_) };

declare 'RepeatedStep',
    as ArrayRef[Step()];

coerce 'RepeatedStep',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkmanagement::V1beta1::Trace::Step'->new($_) } @$_ ] };

declare 'MapStringStep',
    as HashRef[Step()];

declare 'State',
    as (Int | Str);

declare 'InstanceInfo',
    as InstanceOf['Google::Cloud::Networkmanagement::V1beta1::Trace::InstanceInfo'];

coerce 'InstanceInfo',
    from HashRef, via { 'Google::Cloud::Networkmanagement::V1beta1::Trace::InstanceInfo'->new($_) };

declare 'RepeatedInstanceInfo',
    as ArrayRef[InstanceInfo()];

coerce 'RepeatedInstanceInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkmanagement::V1beta1::Trace::InstanceInfo'->new($_) } @$_ ] };

declare 'MapStringInstanceInfo',
    as HashRef[InstanceInfo()];

declare 'Status',
    as (Int | Str);

declare 'NetworkInfo',
    as InstanceOf['Google::Cloud::Networkmanagement::V1beta1::Trace::NetworkInfo'];

coerce 'NetworkInfo',
    from HashRef, via { 'Google::Cloud::Networkmanagement::V1beta1::Trace::NetworkInfo'->new($_) };

declare 'RepeatedNetworkInfo',
    as ArrayRef[NetworkInfo()];

coerce 'RepeatedNetworkInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkmanagement::V1beta1::Trace::NetworkInfo'->new($_) } @$_ ] };

declare 'MapStringNetworkInfo',
    as HashRef[NetworkInfo()];

declare 'FirewallInfo',
    as InstanceOf['Google::Cloud::Networkmanagement::V1beta1::Trace::FirewallInfo'];

coerce 'FirewallInfo',
    from HashRef, via { 'Google::Cloud::Networkmanagement::V1beta1::Trace::FirewallInfo'->new($_) };

declare 'RepeatedFirewallInfo',
    as ArrayRef[FirewallInfo()];

coerce 'RepeatedFirewallInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkmanagement::V1beta1::Trace::FirewallInfo'->new($_) } @$_ ] };

declare 'MapStringFirewallInfo',
    as HashRef[FirewallInfo()];

declare 'FirewallRuleType',
    as (Int | Str);

declare 'TargetType',
    as (Int | Str);

declare 'RouteInfo',
    as InstanceOf['Google::Cloud::Networkmanagement::V1beta1::Trace::RouteInfo'];

coerce 'RouteInfo',
    from HashRef, via { 'Google::Cloud::Networkmanagement::V1beta1::Trace::RouteInfo'->new($_) };

declare 'RepeatedRouteInfo',
    as ArrayRef[RouteInfo()];

coerce 'RepeatedRouteInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkmanagement::V1beta1::Trace::RouteInfo'->new($_) } @$_ ] };

declare 'MapStringRouteInfo',
    as HashRef[RouteInfo()];

declare 'RouteType',
    as (Int | Str);

declare 'NextHopType',
    as (Int | Str);

declare 'RouteScope',
    as (Int | Str);

declare 'GoogleServiceInfo',
    as InstanceOf['Google::Cloud::Networkmanagement::V1beta1::Trace::GoogleServiceInfo'];

coerce 'GoogleServiceInfo',
    from HashRef, via { 'Google::Cloud::Networkmanagement::V1beta1::Trace::GoogleServiceInfo'->new($_) };

declare 'RepeatedGoogleServiceInfo',
    as ArrayRef[GoogleServiceInfo()];

coerce 'RepeatedGoogleServiceInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkmanagement::V1beta1::Trace::GoogleServiceInfo'->new($_) } @$_ ] };

declare 'MapStringGoogleServiceInfo',
    as HashRef[GoogleServiceInfo()];

declare 'GoogleServiceType',
    as (Int | Str);

declare 'ForwardingRuleInfo',
    as InstanceOf['Google::Cloud::Networkmanagement::V1beta1::Trace::ForwardingRuleInfo'];

coerce 'ForwardingRuleInfo',
    from HashRef, via { 'Google::Cloud::Networkmanagement::V1beta1::Trace::ForwardingRuleInfo'->new($_) };

declare 'RepeatedForwardingRuleInfo',
    as ArrayRef[ForwardingRuleInfo()];

coerce 'RepeatedForwardingRuleInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkmanagement::V1beta1::Trace::ForwardingRuleInfo'->new($_) } @$_ ] };

declare 'MapStringForwardingRuleInfo',
    as HashRef[ForwardingRuleInfo()];

declare 'LoadBalancerInfo',
    as InstanceOf['Google::Cloud::Networkmanagement::V1beta1::Trace::LoadBalancerInfo'];

coerce 'LoadBalancerInfo',
    from HashRef, via { 'Google::Cloud::Networkmanagement::V1beta1::Trace::LoadBalancerInfo'->new($_) };

declare 'RepeatedLoadBalancerInfo',
    as ArrayRef[LoadBalancerInfo()];

coerce 'RepeatedLoadBalancerInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkmanagement::V1beta1::Trace::LoadBalancerInfo'->new($_) } @$_ ] };

declare 'MapStringLoadBalancerInfo',
    as HashRef[LoadBalancerInfo()];

declare 'LoadBalancerType',
    as (Int | Str);

declare 'BackendType',
    as (Int | Str);

declare 'LoadBalancerBackend',
    as InstanceOf['Google::Cloud::Networkmanagement::V1beta1::Trace::LoadBalancerBackend'];

coerce 'LoadBalancerBackend',
    from HashRef, via { 'Google::Cloud::Networkmanagement::V1beta1::Trace::LoadBalancerBackend'->new($_) };

declare 'RepeatedLoadBalancerBackend',
    as ArrayRef[LoadBalancerBackend()];

coerce 'RepeatedLoadBalancerBackend',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkmanagement::V1beta1::Trace::LoadBalancerBackend'->new($_) } @$_ ] };

declare 'MapStringLoadBalancerBackend',
    as HashRef[LoadBalancerBackend()];

declare 'HealthCheckFirewallState',
    as (Int | Str);

declare 'HybridSubnetInfo',
    as InstanceOf['Google::Cloud::Networkmanagement::V1beta1::Trace::HybridSubnetInfo'];

coerce 'HybridSubnetInfo',
    from HashRef, via { 'Google::Cloud::Networkmanagement::V1beta1::Trace::HybridSubnetInfo'->new($_) };

declare 'RepeatedHybridSubnetInfo',
    as ArrayRef[HybridSubnetInfo()];

coerce 'RepeatedHybridSubnetInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkmanagement::V1beta1::Trace::HybridSubnetInfo'->new($_) } @$_ ] };

declare 'MapStringHybridSubnetInfo',
    as HashRef[HybridSubnetInfo()];

declare 'VpnGatewayInfo',
    as InstanceOf['Google::Cloud::Networkmanagement::V1beta1::Trace::VpnGatewayInfo'];

coerce 'VpnGatewayInfo',
    from HashRef, via { 'Google::Cloud::Networkmanagement::V1beta1::Trace::VpnGatewayInfo'->new($_) };

declare 'RepeatedVpnGatewayInfo',
    as ArrayRef[VpnGatewayInfo()];

coerce 'RepeatedVpnGatewayInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkmanagement::V1beta1::Trace::VpnGatewayInfo'->new($_) } @$_ ] };

declare 'MapStringVpnGatewayInfo',
    as HashRef[VpnGatewayInfo()];

declare 'VpnTunnelInfo',
    as InstanceOf['Google::Cloud::Networkmanagement::V1beta1::Trace::VpnTunnelInfo'];

coerce 'VpnTunnelInfo',
    from HashRef, via { 'Google::Cloud::Networkmanagement::V1beta1::Trace::VpnTunnelInfo'->new($_) };

declare 'RepeatedVpnTunnelInfo',
    as ArrayRef[VpnTunnelInfo()];

coerce 'RepeatedVpnTunnelInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkmanagement::V1beta1::Trace::VpnTunnelInfo'->new($_) } @$_ ] };

declare 'MapStringVpnTunnelInfo',
    as HashRef[VpnTunnelInfo()];

declare 'RoutingType',
    as (Int | Str);

declare 'InterconnectAttachmentInfo',
    as InstanceOf['Google::Cloud::Networkmanagement::V1beta1::Trace::InterconnectAttachmentInfo'];

coerce 'InterconnectAttachmentInfo',
    from HashRef, via { 'Google::Cloud::Networkmanagement::V1beta1::Trace::InterconnectAttachmentInfo'->new($_) };

declare 'RepeatedInterconnectAttachmentInfo',
    as ArrayRef[InterconnectAttachmentInfo()];

coerce 'RepeatedInterconnectAttachmentInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkmanagement::V1beta1::Trace::InterconnectAttachmentInfo'->new($_) } @$_ ] };

declare 'MapStringInterconnectAttachmentInfo',
    as HashRef[InterconnectAttachmentInfo()];

declare 'Type',
    as (Int | Str);

declare 'EndpointInfo',
    as InstanceOf['Google::Cloud::Networkmanagement::V1beta1::Trace::EndpointInfo'];

coerce 'EndpointInfo',
    from HashRef, via { 'Google::Cloud::Networkmanagement::V1beta1::Trace::EndpointInfo'->new($_) };

declare 'RepeatedEndpointInfo',
    as ArrayRef[EndpointInfo()];

coerce 'RepeatedEndpointInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkmanagement::V1beta1::Trace::EndpointInfo'->new($_) } @$_ ] };

declare 'MapStringEndpointInfo',
    as HashRef[EndpointInfo()];

declare 'DeliverInfo',
    as InstanceOf['Google::Cloud::Networkmanagement::V1beta1::Trace::DeliverInfo'];

coerce 'DeliverInfo',
    from HashRef, via { 'Google::Cloud::Networkmanagement::V1beta1::Trace::DeliverInfo'->new($_) };

declare 'RepeatedDeliverInfo',
    as ArrayRef[DeliverInfo()];

coerce 'RepeatedDeliverInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkmanagement::V1beta1::Trace::DeliverInfo'->new($_) } @$_ ] };

declare 'MapStringDeliverInfo',
    as HashRef[DeliverInfo()];

declare 'Target',
    as (Int | Str);

declare 'GoogleServiceType',
    as (Int | Str);

declare 'ForwardInfo',
    as InstanceOf['Google::Cloud::Networkmanagement::V1beta1::Trace::ForwardInfo'];

coerce 'ForwardInfo',
    from HashRef, via { 'Google::Cloud::Networkmanagement::V1beta1::Trace::ForwardInfo'->new($_) };

declare 'RepeatedForwardInfo',
    as ArrayRef[ForwardInfo()];

coerce 'RepeatedForwardInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkmanagement::V1beta1::Trace::ForwardInfo'->new($_) } @$_ ] };

declare 'MapStringForwardInfo',
    as HashRef[ForwardInfo()];

declare 'Target',
    as (Int | Str);

declare 'AbortInfo',
    as InstanceOf['Google::Cloud::Networkmanagement::V1beta1::Trace::AbortInfo'];

coerce 'AbortInfo',
    from HashRef, via { 'Google::Cloud::Networkmanagement::V1beta1::Trace::AbortInfo'->new($_) };

declare 'RepeatedAbortInfo',
    as ArrayRef[AbortInfo()];

coerce 'RepeatedAbortInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkmanagement::V1beta1::Trace::AbortInfo'->new($_) } @$_ ] };

declare 'MapStringAbortInfo',
    as HashRef[AbortInfo()];

declare 'Cause',
    as (Int | Str);

declare 'DropInfo',
    as InstanceOf['Google::Cloud::Networkmanagement::V1beta1::Trace::DropInfo'];

coerce 'DropInfo',
    from HashRef, via { 'Google::Cloud::Networkmanagement::V1beta1::Trace::DropInfo'->new($_) };

declare 'RepeatedDropInfo',
    as ArrayRef[DropInfo()];

coerce 'RepeatedDropInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkmanagement::V1beta1::Trace::DropInfo'->new($_) } @$_ ] };

declare 'MapStringDropInfo',
    as HashRef[DropInfo()];

declare 'Cause',
    as (Int | Str);

declare 'GKEMasterInfo',
    as InstanceOf['Google::Cloud::Networkmanagement::V1beta1::Trace::GKEMasterInfo'];

coerce 'GKEMasterInfo',
    from HashRef, via { 'Google::Cloud::Networkmanagement::V1beta1::Trace::GKEMasterInfo'->new($_) };

declare 'RepeatedGKEMasterInfo',
    as ArrayRef[GKEMasterInfo()];

coerce 'RepeatedGKEMasterInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkmanagement::V1beta1::Trace::GKEMasterInfo'->new($_) } @$_ ] };

declare 'MapStringGKEMasterInfo',
    as HashRef[GKEMasterInfo()];

declare 'GkePodInfo',
    as InstanceOf['Google::Cloud::Networkmanagement::V1beta1::Trace::GkePodInfo'];

coerce 'GkePodInfo',
    from HashRef, via { 'Google::Cloud::Networkmanagement::V1beta1::Trace::GkePodInfo'->new($_) };

declare 'RepeatedGkePodInfo',
    as ArrayRef[GkePodInfo()];

coerce 'RepeatedGkePodInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkmanagement::V1beta1::Trace::GkePodInfo'->new($_) } @$_ ] };

declare 'MapStringGkePodInfo',
    as HashRef[GkePodInfo()];

declare 'IpMasqueradingSkippedInfo',
    as InstanceOf['Google::Cloud::Networkmanagement::V1beta1::Trace::IpMasqueradingSkippedInfo'];

coerce 'IpMasqueradingSkippedInfo',
    from HashRef, via { 'Google::Cloud::Networkmanagement::V1beta1::Trace::IpMasqueradingSkippedInfo'->new($_) };

declare 'RepeatedIpMasqueradingSkippedInfo',
    as ArrayRef[IpMasqueradingSkippedInfo()];

coerce 'RepeatedIpMasqueradingSkippedInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkmanagement::V1beta1::Trace::IpMasqueradingSkippedInfo'->new($_) } @$_ ] };

declare 'MapStringIpMasqueradingSkippedInfo',
    as HashRef[IpMasqueradingSkippedInfo()];

declare 'Reason',
    as (Int | Str);

declare 'GkeNetworkPolicyInfo',
    as InstanceOf['Google::Cloud::Networkmanagement::V1beta1::Trace::GkeNetworkPolicyInfo'];

coerce 'GkeNetworkPolicyInfo',
    from HashRef, via { 'Google::Cloud::Networkmanagement::V1beta1::Trace::GkeNetworkPolicyInfo'->new($_) };

declare 'RepeatedGkeNetworkPolicyInfo',
    as ArrayRef[GkeNetworkPolicyInfo()];

coerce 'RepeatedGkeNetworkPolicyInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkmanagement::V1beta1::Trace::GkeNetworkPolicyInfo'->new($_) } @$_ ] };

declare 'MapStringGkeNetworkPolicyInfo',
    as HashRef[GkeNetworkPolicyInfo()];

declare 'GkeNetworkPolicySkippedInfo',
    as InstanceOf['Google::Cloud::Networkmanagement::V1beta1::Trace::GkeNetworkPolicySkippedInfo'];

coerce 'GkeNetworkPolicySkippedInfo',
    from HashRef, via { 'Google::Cloud::Networkmanagement::V1beta1::Trace::GkeNetworkPolicySkippedInfo'->new($_) };

declare 'RepeatedGkeNetworkPolicySkippedInfo',
    as ArrayRef[GkeNetworkPolicySkippedInfo()];

coerce 'RepeatedGkeNetworkPolicySkippedInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkmanagement::V1beta1::Trace::GkeNetworkPolicySkippedInfo'->new($_) } @$_ ] };

declare 'MapStringGkeNetworkPolicySkippedInfo',
    as HashRef[GkeNetworkPolicySkippedInfo()];

declare 'Reason',
    as (Int | Str);

declare 'CloudSQLInstanceInfo',
    as InstanceOf['Google::Cloud::Networkmanagement::V1beta1::Trace::CloudSQLInstanceInfo'];

coerce 'CloudSQLInstanceInfo',
    from HashRef, via { 'Google::Cloud::Networkmanagement::V1beta1::Trace::CloudSQLInstanceInfo'->new($_) };

declare 'RepeatedCloudSQLInstanceInfo',
    as ArrayRef[CloudSQLInstanceInfo()];

coerce 'RepeatedCloudSQLInstanceInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkmanagement::V1beta1::Trace::CloudSQLInstanceInfo'->new($_) } @$_ ] };

declare 'MapStringCloudSQLInstanceInfo',
    as HashRef[CloudSQLInstanceInfo()];

declare 'RedisInstanceInfo',
    as InstanceOf['Google::Cloud::Networkmanagement::V1beta1::Trace::RedisInstanceInfo'];

coerce 'RedisInstanceInfo',
    from HashRef, via { 'Google::Cloud::Networkmanagement::V1beta1::Trace::RedisInstanceInfo'->new($_) };

declare 'RepeatedRedisInstanceInfo',
    as ArrayRef[RedisInstanceInfo()];

coerce 'RepeatedRedisInstanceInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkmanagement::V1beta1::Trace::RedisInstanceInfo'->new($_) } @$_ ] };

declare 'MapStringRedisInstanceInfo',
    as HashRef[RedisInstanceInfo()];

declare 'RedisClusterInfo',
    as InstanceOf['Google::Cloud::Networkmanagement::V1beta1::Trace::RedisClusterInfo'];

coerce 'RedisClusterInfo',
    from HashRef, via { 'Google::Cloud::Networkmanagement::V1beta1::Trace::RedisClusterInfo'->new($_) };

declare 'RepeatedRedisClusterInfo',
    as ArrayRef[RedisClusterInfo()];

coerce 'RepeatedRedisClusterInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkmanagement::V1beta1::Trace::RedisClusterInfo'->new($_) } @$_ ] };

declare 'MapStringRedisClusterInfo',
    as HashRef[RedisClusterInfo()];

declare 'CloudFunctionInfo',
    as InstanceOf['Google::Cloud::Networkmanagement::V1beta1::Trace::CloudFunctionInfo'];

coerce 'CloudFunctionInfo',
    from HashRef, via { 'Google::Cloud::Networkmanagement::V1beta1::Trace::CloudFunctionInfo'->new($_) };

declare 'RepeatedCloudFunctionInfo',
    as ArrayRef[CloudFunctionInfo()];

coerce 'RepeatedCloudFunctionInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkmanagement::V1beta1::Trace::CloudFunctionInfo'->new($_) } @$_ ] };

declare 'MapStringCloudFunctionInfo',
    as HashRef[CloudFunctionInfo()];

declare 'CloudRunRevisionInfo',
    as InstanceOf['Google::Cloud::Networkmanagement::V1beta1::Trace::CloudRunRevisionInfo'];

coerce 'CloudRunRevisionInfo',
    from HashRef, via { 'Google::Cloud::Networkmanagement::V1beta1::Trace::CloudRunRevisionInfo'->new($_) };

declare 'RepeatedCloudRunRevisionInfo',
    as ArrayRef[CloudRunRevisionInfo()];

coerce 'RepeatedCloudRunRevisionInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkmanagement::V1beta1::Trace::CloudRunRevisionInfo'->new($_) } @$_ ] };

declare 'MapStringCloudRunRevisionInfo',
    as HashRef[CloudRunRevisionInfo()];

declare 'CloudRunJobInfo',
    as InstanceOf['Google::Cloud::Networkmanagement::V1beta1::Trace::CloudRunJobInfo'];

coerce 'CloudRunJobInfo',
    from HashRef, via { 'Google::Cloud::Networkmanagement::V1beta1::Trace::CloudRunJobInfo'->new($_) };

declare 'RepeatedCloudRunJobInfo',
    as ArrayRef[CloudRunJobInfo()];

coerce 'RepeatedCloudRunJobInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkmanagement::V1beta1::Trace::CloudRunJobInfo'->new($_) } @$_ ] };

declare 'MapStringCloudRunJobInfo',
    as HashRef[CloudRunJobInfo()];

declare 'AppEngineVersionInfo',
    as InstanceOf['Google::Cloud::Networkmanagement::V1beta1::Trace::AppEngineVersionInfo'];

coerce 'AppEngineVersionInfo',
    from HashRef, via { 'Google::Cloud::Networkmanagement::V1beta1::Trace::AppEngineVersionInfo'->new($_) };

declare 'RepeatedAppEngineVersionInfo',
    as ArrayRef[AppEngineVersionInfo()];

coerce 'RepeatedAppEngineVersionInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkmanagement::V1beta1::Trace::AppEngineVersionInfo'->new($_) } @$_ ] };

declare 'MapStringAppEngineVersionInfo',
    as HashRef[AppEngineVersionInfo()];

declare 'VpcConnectorInfo',
    as InstanceOf['Google::Cloud::Networkmanagement::V1beta1::Trace::VpcConnectorInfo'];

coerce 'VpcConnectorInfo',
    from HashRef, via { 'Google::Cloud::Networkmanagement::V1beta1::Trace::VpcConnectorInfo'->new($_) };

declare 'RepeatedVpcConnectorInfo',
    as ArrayRef[VpcConnectorInfo()];

coerce 'RepeatedVpcConnectorInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkmanagement::V1beta1::Trace::VpcConnectorInfo'->new($_) } @$_ ] };

declare 'MapStringVpcConnectorInfo',
    as HashRef[VpcConnectorInfo()];

declare 'DirectVpcEgressConnectionInfo',
    as InstanceOf['Google::Cloud::Networkmanagement::V1beta1::Trace::DirectVpcEgressConnectionInfo'];

coerce 'DirectVpcEgressConnectionInfo',
    from HashRef, via { 'Google::Cloud::Networkmanagement::V1beta1::Trace::DirectVpcEgressConnectionInfo'->new($_) };

declare 'RepeatedDirectVpcEgressConnectionInfo',
    as ArrayRef[DirectVpcEgressConnectionInfo()];

coerce 'RepeatedDirectVpcEgressConnectionInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkmanagement::V1beta1::Trace::DirectVpcEgressConnectionInfo'->new($_) } @$_ ] };

declare 'MapStringDirectVpcEgressConnectionInfo',
    as HashRef[DirectVpcEgressConnectionInfo()];

declare 'ServerlessExternalConnectionInfo',
    as InstanceOf['Google::Cloud::Networkmanagement::V1beta1::Trace::ServerlessExternalConnectionInfo'];

coerce 'ServerlessExternalConnectionInfo',
    from HashRef, via { 'Google::Cloud::Networkmanagement::V1beta1::Trace::ServerlessExternalConnectionInfo'->new($_) };

declare 'RepeatedServerlessExternalConnectionInfo',
    as ArrayRef[ServerlessExternalConnectionInfo()];

coerce 'RepeatedServerlessExternalConnectionInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkmanagement::V1beta1::Trace::ServerlessExternalConnectionInfo'->new($_) } @$_ ] };

declare 'MapStringServerlessExternalConnectionInfo',
    as HashRef[ServerlessExternalConnectionInfo()];

declare 'NatInfo',
    as InstanceOf['Google::Cloud::Networkmanagement::V1beta1::Trace::NatInfo'];

coerce 'NatInfo',
    from HashRef, via { 'Google::Cloud::Networkmanagement::V1beta1::Trace::NatInfo'->new($_) };

declare 'RepeatedNatInfo',
    as ArrayRef[NatInfo()];

coerce 'RepeatedNatInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkmanagement::V1beta1::Trace::NatInfo'->new($_) } @$_ ] };

declare 'MapStringNatInfo',
    as HashRef[NatInfo()];

declare 'Type',
    as (Int | Str);

declare 'CloudNatGatewayType',
    as (Int | Str);

declare 'ProxyConnectionInfo',
    as InstanceOf['Google::Cloud::Networkmanagement::V1beta1::Trace::ProxyConnectionInfo'];

coerce 'ProxyConnectionInfo',
    from HashRef, via { 'Google::Cloud::Networkmanagement::V1beta1::Trace::ProxyConnectionInfo'->new($_) };

declare 'RepeatedProxyConnectionInfo',
    as ArrayRef[ProxyConnectionInfo()];

coerce 'RepeatedProxyConnectionInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkmanagement::V1beta1::Trace::ProxyConnectionInfo'->new($_) } @$_ ] };

declare 'MapStringProxyConnectionInfo',
    as HashRef[ProxyConnectionInfo()];

declare 'LoadBalancerBackendInfo',
    as InstanceOf['Google::Cloud::Networkmanagement::V1beta1::Trace::LoadBalancerBackendInfo'];

coerce 'LoadBalancerBackendInfo',
    from HashRef, via { 'Google::Cloud::Networkmanagement::V1beta1::Trace::LoadBalancerBackendInfo'->new($_) };

declare 'RepeatedLoadBalancerBackendInfo',
    as ArrayRef[LoadBalancerBackendInfo()];

coerce 'RepeatedLoadBalancerBackendInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkmanagement::V1beta1::Trace::LoadBalancerBackendInfo'->new($_) } @$_ ] };

declare 'MapStringLoadBalancerBackendInfo',
    as HashRef[LoadBalancerBackendInfo()];

declare 'HealthCheckFirewallsConfigState',
    as (Int | Str);

declare 'StorageBucketInfo',
    as InstanceOf['Google::Cloud::Networkmanagement::V1beta1::Trace::StorageBucketInfo'];

coerce 'StorageBucketInfo',
    from HashRef, via { 'Google::Cloud::Networkmanagement::V1beta1::Trace::StorageBucketInfo'->new($_) };

declare 'RepeatedStorageBucketInfo',
    as ArrayRef[StorageBucketInfo()];

coerce 'RepeatedStorageBucketInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkmanagement::V1beta1::Trace::StorageBucketInfo'->new($_) } @$_ ] };

declare 'MapStringStorageBucketInfo',
    as HashRef[StorageBucketInfo()];

declare 'ServerlessNegInfo',
    as InstanceOf['Google::Cloud::Networkmanagement::V1beta1::Trace::ServerlessNegInfo'];

coerce 'ServerlessNegInfo',
    from HashRef, via { 'Google::Cloud::Networkmanagement::V1beta1::Trace::ServerlessNegInfo'->new($_) };

declare 'RepeatedServerlessNegInfo',
    as ArrayRef[ServerlessNegInfo()];

coerce 'RepeatedServerlessNegInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkmanagement::V1beta1::Trace::ServerlessNegInfo'->new($_) } @$_ ] };

declare 'MapStringServerlessNegInfo',
    as HashRef[ServerlessNegInfo()];

declare 'NgfwPacketInspectionInfo',
    as InstanceOf['Google::Cloud::Networkmanagement::V1beta1::Trace::NgfwPacketInspectionInfo'];

coerce 'NgfwPacketInspectionInfo',
    from HashRef, via { 'Google::Cloud::Networkmanagement::V1beta1::Trace::NgfwPacketInspectionInfo'->new($_) };

declare 'RepeatedNgfwPacketInspectionInfo',
    as ArrayRef[NgfwPacketInspectionInfo()];

coerce 'RepeatedNgfwPacketInspectionInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkmanagement::V1beta1::Trace::NgfwPacketInspectionInfo'->new($_) } @$_ ] };

declare 'MapStringNgfwPacketInspectionInfo',
    as HashRef[NgfwPacketInspectionInfo()];

declare 'PrivateConnectionInfo',
    as InstanceOf['Google::Cloud::Networkmanagement::V1beta1::Trace::PrivateConnectionInfo'];

coerce 'PrivateConnectionInfo',
    from HashRef, via { 'Google::Cloud::Networkmanagement::V1beta1::Trace::PrivateConnectionInfo'->new($_) };

declare 'RepeatedPrivateConnectionInfo',
    as ArrayRef[PrivateConnectionInfo()];

coerce 'RepeatedPrivateConnectionInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkmanagement::V1beta1::Trace::PrivateConnectionInfo'->new($_) } @$_ ] };

declare 'MapStringPrivateConnectionInfo',
    as HashRef[PrivateConnectionInfo()];

1;

__END__

=head1 NAME

Google::Cloud::Networkmanagement::V1beta1::Trace::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
