package Google::Cloud::Managedkafka::V1::Resources::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Cluster',
    as InstanceOf['Google::Cloud::Managedkafka::V1::Resources::Cluster'];

coerce 'Cluster',
    from HashRef, via { 'Google::Cloud::Managedkafka::V1::Resources::Cluster'->new($_) };

declare 'RepeatedCluster',
    as ArrayRef[Cluster()];

coerce 'RepeatedCluster',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Managedkafka::V1::Resources::Cluster'->new($_) } @$_ ] };

declare 'MapStringCluster',
    as HashRef[Cluster()];

declare 'State',
    as (Int | Str);

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Managedkafka::V1::Resources::Cluster::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Managedkafka::V1::Resources::Cluster::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Managedkafka::V1::Resources::Cluster::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'CapacityConfig',
    as InstanceOf['Google::Cloud::Managedkafka::V1::Resources::CapacityConfig'];

coerce 'CapacityConfig',
    from HashRef, via { 'Google::Cloud::Managedkafka::V1::Resources::CapacityConfig'->new($_) };

declare 'RepeatedCapacityConfig',
    as ArrayRef[CapacityConfig()];

coerce 'RepeatedCapacityConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Managedkafka::V1::Resources::CapacityConfig'->new($_) } @$_ ] };

declare 'MapStringCapacityConfig',
    as HashRef[CapacityConfig()];

declare 'RebalanceConfig',
    as InstanceOf['Google::Cloud::Managedkafka::V1::Resources::RebalanceConfig'];

coerce 'RebalanceConfig',
    from HashRef, via { 'Google::Cloud::Managedkafka::V1::Resources::RebalanceConfig'->new($_) };

declare 'RepeatedRebalanceConfig',
    as ArrayRef[RebalanceConfig()];

coerce 'RepeatedRebalanceConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Managedkafka::V1::Resources::RebalanceConfig'->new($_) } @$_ ] };

declare 'MapStringRebalanceConfig',
    as HashRef[RebalanceConfig()];

declare 'Mode',
    as (Int | Str);

declare 'NetworkConfig',
    as InstanceOf['Google::Cloud::Managedkafka::V1::Resources::NetworkConfig'];

coerce 'NetworkConfig',
    from HashRef, via { 'Google::Cloud::Managedkafka::V1::Resources::NetworkConfig'->new($_) };

declare 'RepeatedNetworkConfig',
    as ArrayRef[NetworkConfig()];

coerce 'RepeatedNetworkConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Managedkafka::V1::Resources::NetworkConfig'->new($_) } @$_ ] };

declare 'MapStringNetworkConfig',
    as HashRef[NetworkConfig()];

declare 'AccessConfig',
    as InstanceOf['Google::Cloud::Managedkafka::V1::Resources::AccessConfig'];

coerce 'AccessConfig',
    from HashRef, via { 'Google::Cloud::Managedkafka::V1::Resources::AccessConfig'->new($_) };

declare 'RepeatedAccessConfig',
    as ArrayRef[AccessConfig()];

coerce 'RepeatedAccessConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Managedkafka::V1::Resources::AccessConfig'->new($_) } @$_ ] };

declare 'MapStringAccessConfig',
    as HashRef[AccessConfig()];

declare 'GcpConfig',
    as InstanceOf['Google::Cloud::Managedkafka::V1::Resources::GcpConfig'];

coerce 'GcpConfig',
    from HashRef, via { 'Google::Cloud::Managedkafka::V1::Resources::GcpConfig'->new($_) };

declare 'RepeatedGcpConfig',
    as ArrayRef[GcpConfig()];

coerce 'RepeatedGcpConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Managedkafka::V1::Resources::GcpConfig'->new($_) } @$_ ] };

declare 'MapStringGcpConfig',
    as HashRef[GcpConfig()];

declare 'TlsConfig',
    as InstanceOf['Google::Cloud::Managedkafka::V1::Resources::TlsConfig'];

coerce 'TlsConfig',
    from HashRef, via { 'Google::Cloud::Managedkafka::V1::Resources::TlsConfig'->new($_) };

declare 'RepeatedTlsConfig',
    as ArrayRef[TlsConfig()];

coerce 'RepeatedTlsConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Managedkafka::V1::Resources::TlsConfig'->new($_) } @$_ ] };

declare 'MapStringTlsConfig',
    as HashRef[TlsConfig()];

declare 'TrustConfig',
    as InstanceOf['Google::Cloud::Managedkafka::V1::Resources::TrustConfig'];

coerce 'TrustConfig',
    from HashRef, via { 'Google::Cloud::Managedkafka::V1::Resources::TrustConfig'->new($_) };

declare 'RepeatedTrustConfig',
    as ArrayRef[TrustConfig()];

coerce 'RepeatedTrustConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Managedkafka::V1::Resources::TrustConfig'->new($_) } @$_ ] };

declare 'MapStringTrustConfig',
    as HashRef[TrustConfig()];

declare 'CertificateAuthorityServiceConfig',
    as InstanceOf['Google::Cloud::Managedkafka::V1::Resources::TrustConfig::CertificateAuthorityServiceConfig'];

coerce 'CertificateAuthorityServiceConfig',
    from HashRef, via { 'Google::Cloud::Managedkafka::V1::Resources::TrustConfig::CertificateAuthorityServiceConfig'->new($_) };

declare 'RepeatedCertificateAuthorityServiceConfig',
    as ArrayRef[CertificateAuthorityServiceConfig()];

coerce 'RepeatedCertificateAuthorityServiceConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Managedkafka::V1::Resources::TrustConfig::CertificateAuthorityServiceConfig'->new($_) } @$_ ] };

declare 'MapStringCertificateAuthorityServiceConfig',
    as HashRef[CertificateAuthorityServiceConfig()];

declare 'Topic',
    as InstanceOf['Google::Cloud::Managedkafka::V1::Resources::Topic'];

coerce 'Topic',
    from HashRef, via { 'Google::Cloud::Managedkafka::V1::Resources::Topic'->new($_) };

declare 'RepeatedTopic',
    as ArrayRef[Topic()];

coerce 'RepeatedTopic',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Managedkafka::V1::Resources::Topic'->new($_) } @$_ ] };

declare 'MapStringTopic',
    as HashRef[Topic()];

declare 'ConfigsEntry',
    as InstanceOf['Google::Cloud::Managedkafka::V1::Resources::Topic::ConfigsEntry'];

coerce 'ConfigsEntry',
    from HashRef, via { 'Google::Cloud::Managedkafka::V1::Resources::Topic::ConfigsEntry'->new($_) };

declare 'RepeatedConfigsEntry',
    as ArrayRef[ConfigsEntry()];

coerce 'RepeatedConfigsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Managedkafka::V1::Resources::Topic::ConfigsEntry'->new($_) } @$_ ] };

declare 'MapStringConfigsEntry',
    as HashRef[ConfigsEntry()];

declare 'ConsumerTopicMetadata',
    as InstanceOf['Google::Cloud::Managedkafka::V1::Resources::ConsumerTopicMetadata'];

coerce 'ConsumerTopicMetadata',
    from HashRef, via { 'Google::Cloud::Managedkafka::V1::Resources::ConsumerTopicMetadata'->new($_) };

declare 'RepeatedConsumerTopicMetadata',
    as ArrayRef[ConsumerTopicMetadata()];

coerce 'RepeatedConsumerTopicMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Managedkafka::V1::Resources::ConsumerTopicMetadata'->new($_) } @$_ ] };

declare 'MapStringConsumerTopicMetadata',
    as HashRef[ConsumerTopicMetadata()];

declare 'PartitionsEntry',
    as InstanceOf['Google::Cloud::Managedkafka::V1::Resources::ConsumerTopicMetadata::PartitionsEntry'];

coerce 'PartitionsEntry',
    from HashRef, via { 'Google::Cloud::Managedkafka::V1::Resources::ConsumerTopicMetadata::PartitionsEntry'->new($_) };

declare 'RepeatedPartitionsEntry',
    as ArrayRef[PartitionsEntry()];

coerce 'RepeatedPartitionsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Managedkafka::V1::Resources::ConsumerTopicMetadata::PartitionsEntry'->new($_) } @$_ ] };

declare 'MapStringPartitionsEntry',
    as HashRef[PartitionsEntry()];

declare 'ConsumerPartitionMetadata',
    as InstanceOf['Google::Cloud::Managedkafka::V1::Resources::ConsumerPartitionMetadata'];

coerce 'ConsumerPartitionMetadata',
    from HashRef, via { 'Google::Cloud::Managedkafka::V1::Resources::ConsumerPartitionMetadata'->new($_) };

declare 'RepeatedConsumerPartitionMetadata',
    as ArrayRef[ConsumerPartitionMetadata()];

coerce 'RepeatedConsumerPartitionMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Managedkafka::V1::Resources::ConsumerPartitionMetadata'->new($_) } @$_ ] };

declare 'MapStringConsumerPartitionMetadata',
    as HashRef[ConsumerPartitionMetadata()];

declare 'ConsumerGroup',
    as InstanceOf['Google::Cloud::Managedkafka::V1::Resources::ConsumerGroup'];

coerce 'ConsumerGroup',
    from HashRef, via { 'Google::Cloud::Managedkafka::V1::Resources::ConsumerGroup'->new($_) };

declare 'RepeatedConsumerGroup',
    as ArrayRef[ConsumerGroup()];

coerce 'RepeatedConsumerGroup',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Managedkafka::V1::Resources::ConsumerGroup'->new($_) } @$_ ] };

declare 'MapStringConsumerGroup',
    as HashRef[ConsumerGroup()];

declare 'TopicsEntry',
    as InstanceOf['Google::Cloud::Managedkafka::V1::Resources::ConsumerGroup::TopicsEntry'];

coerce 'TopicsEntry',
    from HashRef, via { 'Google::Cloud::Managedkafka::V1::Resources::ConsumerGroup::TopicsEntry'->new($_) };

declare 'RepeatedTopicsEntry',
    as ArrayRef[TopicsEntry()];

coerce 'RepeatedTopicsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Managedkafka::V1::Resources::ConsumerGroup::TopicsEntry'->new($_) } @$_ ] };

declare 'MapStringTopicsEntry',
    as HashRef[TopicsEntry()];

declare 'OperationMetadata',
    as InstanceOf['Google::Cloud::Managedkafka::V1::Resources::OperationMetadata'];

coerce 'OperationMetadata',
    from HashRef, via { 'Google::Cloud::Managedkafka::V1::Resources::OperationMetadata'->new($_) };

declare 'RepeatedOperationMetadata',
    as ArrayRef[OperationMetadata()];

coerce 'RepeatedOperationMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Managedkafka::V1::Resources::OperationMetadata'->new($_) } @$_ ] };

declare 'MapStringOperationMetadata',
    as HashRef[OperationMetadata()];

declare 'ConnectCluster',
    as InstanceOf['Google::Cloud::Managedkafka::V1::Resources::ConnectCluster'];

coerce 'ConnectCluster',
    from HashRef, via { 'Google::Cloud::Managedkafka::V1::Resources::ConnectCluster'->new($_) };

declare 'RepeatedConnectCluster',
    as ArrayRef[ConnectCluster()];

coerce 'RepeatedConnectCluster',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Managedkafka::V1::Resources::ConnectCluster'->new($_) } @$_ ] };

declare 'MapStringConnectCluster',
    as HashRef[ConnectCluster()];

declare 'State',
    as (Int | Str);

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Managedkafka::V1::Resources::ConnectCluster::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Managedkafka::V1::Resources::ConnectCluster::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Managedkafka::V1::Resources::ConnectCluster::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'ConfigEntry',
    as InstanceOf['Google::Cloud::Managedkafka::V1::Resources::ConnectCluster::ConfigEntry'];

coerce 'ConfigEntry',
    from HashRef, via { 'Google::Cloud::Managedkafka::V1::Resources::ConnectCluster::ConfigEntry'->new($_) };

declare 'RepeatedConfigEntry',
    as ArrayRef[ConfigEntry()];

coerce 'RepeatedConfigEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Managedkafka::V1::Resources::ConnectCluster::ConfigEntry'->new($_) } @$_ ] };

declare 'MapStringConfigEntry',
    as HashRef[ConfigEntry()];

declare 'ConnectNetworkConfig',
    as InstanceOf['Google::Cloud::Managedkafka::V1::Resources::ConnectNetworkConfig'];

coerce 'ConnectNetworkConfig',
    from HashRef, via { 'Google::Cloud::Managedkafka::V1::Resources::ConnectNetworkConfig'->new($_) };

declare 'RepeatedConnectNetworkConfig',
    as ArrayRef[ConnectNetworkConfig()];

coerce 'RepeatedConnectNetworkConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Managedkafka::V1::Resources::ConnectNetworkConfig'->new($_) } @$_ ] };

declare 'MapStringConnectNetworkConfig',
    as HashRef[ConnectNetworkConfig()];

declare 'ConnectAccessConfig',
    as InstanceOf['Google::Cloud::Managedkafka::V1::Resources::ConnectAccessConfig'];

coerce 'ConnectAccessConfig',
    from HashRef, via { 'Google::Cloud::Managedkafka::V1::Resources::ConnectAccessConfig'->new($_) };

declare 'RepeatedConnectAccessConfig',
    as ArrayRef[ConnectAccessConfig()];

coerce 'RepeatedConnectAccessConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Managedkafka::V1::Resources::ConnectAccessConfig'->new($_) } @$_ ] };

declare 'MapStringConnectAccessConfig',
    as HashRef[ConnectAccessConfig()];

declare 'ConnectGcpConfig',
    as InstanceOf['Google::Cloud::Managedkafka::V1::Resources::ConnectGcpConfig'];

coerce 'ConnectGcpConfig',
    from HashRef, via { 'Google::Cloud::Managedkafka::V1::Resources::ConnectGcpConfig'->new($_) };

declare 'RepeatedConnectGcpConfig',
    as ArrayRef[ConnectGcpConfig()];

coerce 'RepeatedConnectGcpConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Managedkafka::V1::Resources::ConnectGcpConfig'->new($_) } @$_ ] };

declare 'MapStringConnectGcpConfig',
    as HashRef[ConnectGcpConfig()];

declare 'Connector',
    as InstanceOf['Google::Cloud::Managedkafka::V1::Resources::Connector'];

coerce 'Connector',
    from HashRef, via { 'Google::Cloud::Managedkafka::V1::Resources::Connector'->new($_) };

declare 'RepeatedConnector',
    as ArrayRef[Connector()];

coerce 'RepeatedConnector',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Managedkafka::V1::Resources::Connector'->new($_) } @$_ ] };

declare 'MapStringConnector',
    as HashRef[Connector()];

declare 'State',
    as (Int | Str);

declare 'ConfigsEntry',
    as InstanceOf['Google::Cloud::Managedkafka::V1::Resources::Connector::ConfigsEntry'];

coerce 'ConfigsEntry',
    from HashRef, via { 'Google::Cloud::Managedkafka::V1::Resources::Connector::ConfigsEntry'->new($_) };

declare 'RepeatedConfigsEntry',
    as ArrayRef[ConfigsEntry()];

coerce 'RepeatedConfigsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Managedkafka::V1::Resources::Connector::ConfigsEntry'->new($_) } @$_ ] };

declare 'MapStringConfigsEntry',
    as HashRef[ConfigsEntry()];

declare 'TaskRetryPolicy',
    as InstanceOf['Google::Cloud::Managedkafka::V1::Resources::TaskRetryPolicy'];

coerce 'TaskRetryPolicy',
    from HashRef, via { 'Google::Cloud::Managedkafka::V1::Resources::TaskRetryPolicy'->new($_) };

declare 'RepeatedTaskRetryPolicy',
    as ArrayRef[TaskRetryPolicy()];

coerce 'RepeatedTaskRetryPolicy',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Managedkafka::V1::Resources::TaskRetryPolicy'->new($_) } @$_ ] };

declare 'MapStringTaskRetryPolicy',
    as HashRef[TaskRetryPolicy()];

declare 'Acl',
    as InstanceOf['Google::Cloud::Managedkafka::V1::Resources::Acl'];

coerce 'Acl',
    from HashRef, via { 'Google::Cloud::Managedkafka::V1::Resources::Acl'->new($_) };

declare 'RepeatedAcl',
    as ArrayRef[Acl()];

coerce 'RepeatedAcl',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Managedkafka::V1::Resources::Acl'->new($_) } @$_ ] };

declare 'MapStringAcl',
    as HashRef[Acl()];

declare 'AclEntry',
    as InstanceOf['Google::Cloud::Managedkafka::V1::Resources::AclEntry'];

coerce 'AclEntry',
    from HashRef, via { 'Google::Cloud::Managedkafka::V1::Resources::AclEntry'->new($_) };

declare 'RepeatedAclEntry',
    as ArrayRef[AclEntry()];

coerce 'RepeatedAclEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Managedkafka::V1::Resources::AclEntry'->new($_) } @$_ ] };

declare 'MapStringAclEntry',
    as HashRef[AclEntry()];

1;

__END__

=head1 NAME

Google::Cloud::Managedkafka::V1::Resources::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
