package Google::Cloud::Gkemulticloud::V1::AwsResources::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'AwsCluster',
    as InstanceOf['Google::Cloud::Gkemulticloud::V1::AwsResources::AwsCluster'];

coerce 'AwsCluster',
    from HashRef, via { 'Google::Cloud::Gkemulticloud::V1::AwsResources::AwsCluster'->new($_) };

declare 'RepeatedAwsCluster',
    as ArrayRef[AwsCluster()];

coerce 'RepeatedAwsCluster',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkemulticloud::V1::AwsResources::AwsCluster'->new($_) } @$_ ] };

declare 'MapStringAwsCluster',
    as HashRef[AwsCluster()];

declare 'State',
    as (Int | Str);

declare 'AnnotationsEntry',
    as InstanceOf['Google::Cloud::Gkemulticloud::V1::AwsResources::AwsCluster::AnnotationsEntry'];

coerce 'AnnotationsEntry',
    from HashRef, via { 'Google::Cloud::Gkemulticloud::V1::AwsResources::AwsCluster::AnnotationsEntry'->new($_) };

declare 'RepeatedAnnotationsEntry',
    as ArrayRef[AnnotationsEntry()];

coerce 'RepeatedAnnotationsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkemulticloud::V1::AwsResources::AwsCluster::AnnotationsEntry'->new($_) } @$_ ] };

declare 'MapStringAnnotationsEntry',
    as HashRef[AnnotationsEntry()];

declare 'AwsControlPlane',
    as InstanceOf['Google::Cloud::Gkemulticloud::V1::AwsResources::AwsControlPlane'];

coerce 'AwsControlPlane',
    from HashRef, via { 'Google::Cloud::Gkemulticloud::V1::AwsResources::AwsControlPlane'->new($_) };

declare 'RepeatedAwsControlPlane',
    as ArrayRef[AwsControlPlane()];

coerce 'RepeatedAwsControlPlane',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkemulticloud::V1::AwsResources::AwsControlPlane'->new($_) } @$_ ] };

declare 'MapStringAwsControlPlane',
    as HashRef[AwsControlPlane()];

declare 'TagsEntry',
    as InstanceOf['Google::Cloud::Gkemulticloud::V1::AwsResources::AwsControlPlane::TagsEntry'];

coerce 'TagsEntry',
    from HashRef, via { 'Google::Cloud::Gkemulticloud::V1::AwsResources::AwsControlPlane::TagsEntry'->new($_) };

declare 'RepeatedTagsEntry',
    as ArrayRef[TagsEntry()];

coerce 'RepeatedTagsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkemulticloud::V1::AwsResources::AwsControlPlane::TagsEntry'->new($_) } @$_ ] };

declare 'MapStringTagsEntry',
    as HashRef[TagsEntry()];

declare 'AwsServicesAuthentication',
    as InstanceOf['Google::Cloud::Gkemulticloud::V1::AwsResources::AwsServicesAuthentication'];

coerce 'AwsServicesAuthentication',
    from HashRef, via { 'Google::Cloud::Gkemulticloud::V1::AwsResources::AwsServicesAuthentication'->new($_) };

declare 'RepeatedAwsServicesAuthentication',
    as ArrayRef[AwsServicesAuthentication()];

coerce 'RepeatedAwsServicesAuthentication',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkemulticloud::V1::AwsResources::AwsServicesAuthentication'->new($_) } @$_ ] };

declare 'MapStringAwsServicesAuthentication',
    as HashRef[AwsServicesAuthentication()];

declare 'AwsAuthorization',
    as InstanceOf['Google::Cloud::Gkemulticloud::V1::AwsResources::AwsAuthorization'];

coerce 'AwsAuthorization',
    from HashRef, via { 'Google::Cloud::Gkemulticloud::V1::AwsResources::AwsAuthorization'->new($_) };

declare 'RepeatedAwsAuthorization',
    as ArrayRef[AwsAuthorization()];

coerce 'RepeatedAwsAuthorization',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkemulticloud::V1::AwsResources::AwsAuthorization'->new($_) } @$_ ] };

declare 'MapStringAwsAuthorization',
    as HashRef[AwsAuthorization()];

declare 'AwsClusterUser',
    as InstanceOf['Google::Cloud::Gkemulticloud::V1::AwsResources::AwsClusterUser'];

coerce 'AwsClusterUser',
    from HashRef, via { 'Google::Cloud::Gkemulticloud::V1::AwsResources::AwsClusterUser'->new($_) };

declare 'RepeatedAwsClusterUser',
    as ArrayRef[AwsClusterUser()];

coerce 'RepeatedAwsClusterUser',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkemulticloud::V1::AwsResources::AwsClusterUser'->new($_) } @$_ ] };

declare 'MapStringAwsClusterUser',
    as HashRef[AwsClusterUser()];

declare 'AwsClusterGroup',
    as InstanceOf['Google::Cloud::Gkemulticloud::V1::AwsResources::AwsClusterGroup'];

coerce 'AwsClusterGroup',
    from HashRef, via { 'Google::Cloud::Gkemulticloud::V1::AwsResources::AwsClusterGroup'->new($_) };

declare 'RepeatedAwsClusterGroup',
    as ArrayRef[AwsClusterGroup()];

coerce 'RepeatedAwsClusterGroup',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkemulticloud::V1::AwsResources::AwsClusterGroup'->new($_) } @$_ ] };

declare 'MapStringAwsClusterGroup',
    as HashRef[AwsClusterGroup()];

declare 'AwsDatabaseEncryption',
    as InstanceOf['Google::Cloud::Gkemulticloud::V1::AwsResources::AwsDatabaseEncryption'];

coerce 'AwsDatabaseEncryption',
    from HashRef, via { 'Google::Cloud::Gkemulticloud::V1::AwsResources::AwsDatabaseEncryption'->new($_) };

declare 'RepeatedAwsDatabaseEncryption',
    as ArrayRef[AwsDatabaseEncryption()];

coerce 'RepeatedAwsDatabaseEncryption',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkemulticloud::V1::AwsResources::AwsDatabaseEncryption'->new($_) } @$_ ] };

declare 'MapStringAwsDatabaseEncryption',
    as HashRef[AwsDatabaseEncryption()];

declare 'AwsVolumeTemplate',
    as InstanceOf['Google::Cloud::Gkemulticloud::V1::AwsResources::AwsVolumeTemplate'];

coerce 'AwsVolumeTemplate',
    from HashRef, via { 'Google::Cloud::Gkemulticloud::V1::AwsResources::AwsVolumeTemplate'->new($_) };

declare 'RepeatedAwsVolumeTemplate',
    as ArrayRef[AwsVolumeTemplate()];

coerce 'RepeatedAwsVolumeTemplate',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkemulticloud::V1::AwsResources::AwsVolumeTemplate'->new($_) } @$_ ] };

declare 'MapStringAwsVolumeTemplate',
    as HashRef[AwsVolumeTemplate()];

declare 'VolumeType',
    as (Int | Str);

declare 'AwsClusterNetworking',
    as InstanceOf['Google::Cloud::Gkemulticloud::V1::AwsResources::AwsClusterNetworking'];

coerce 'AwsClusterNetworking',
    from HashRef, via { 'Google::Cloud::Gkemulticloud::V1::AwsResources::AwsClusterNetworking'->new($_) };

declare 'RepeatedAwsClusterNetworking',
    as ArrayRef[AwsClusterNetworking()];

coerce 'RepeatedAwsClusterNetworking',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkemulticloud::V1::AwsResources::AwsClusterNetworking'->new($_) } @$_ ] };

declare 'MapStringAwsClusterNetworking',
    as HashRef[AwsClusterNetworking()];

declare 'AwsNodePool',
    as InstanceOf['Google::Cloud::Gkemulticloud::V1::AwsResources::AwsNodePool'];

coerce 'AwsNodePool',
    from HashRef, via { 'Google::Cloud::Gkemulticloud::V1::AwsResources::AwsNodePool'->new($_) };

declare 'RepeatedAwsNodePool',
    as ArrayRef[AwsNodePool()];

coerce 'RepeatedAwsNodePool',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkemulticloud::V1::AwsResources::AwsNodePool'->new($_) } @$_ ] };

declare 'MapStringAwsNodePool',
    as HashRef[AwsNodePool()];

declare 'State',
    as (Int | Str);

declare 'AnnotationsEntry',
    as InstanceOf['Google::Cloud::Gkemulticloud::V1::AwsResources::AwsNodePool::AnnotationsEntry'];

coerce 'AnnotationsEntry',
    from HashRef, via { 'Google::Cloud::Gkemulticloud::V1::AwsResources::AwsNodePool::AnnotationsEntry'->new($_) };

declare 'RepeatedAnnotationsEntry',
    as ArrayRef[AnnotationsEntry()];

coerce 'RepeatedAnnotationsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkemulticloud::V1::AwsResources::AwsNodePool::AnnotationsEntry'->new($_) } @$_ ] };

declare 'MapStringAnnotationsEntry',
    as HashRef[AnnotationsEntry()];

declare 'UpdateSettings',
    as InstanceOf['Google::Cloud::Gkemulticloud::V1::AwsResources::UpdateSettings'];

coerce 'UpdateSettings',
    from HashRef, via { 'Google::Cloud::Gkemulticloud::V1::AwsResources::UpdateSettings'->new($_) };

declare 'RepeatedUpdateSettings',
    as ArrayRef[UpdateSettings()];

coerce 'RepeatedUpdateSettings',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkemulticloud::V1::AwsResources::UpdateSettings'->new($_) } @$_ ] };

declare 'MapStringUpdateSettings',
    as HashRef[UpdateSettings()];

declare 'SurgeSettings',
    as InstanceOf['Google::Cloud::Gkemulticloud::V1::AwsResources::SurgeSettings'];

coerce 'SurgeSettings',
    from HashRef, via { 'Google::Cloud::Gkemulticloud::V1::AwsResources::SurgeSettings'->new($_) };

declare 'RepeatedSurgeSettings',
    as ArrayRef[SurgeSettings()];

coerce 'RepeatedSurgeSettings',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkemulticloud::V1::AwsResources::SurgeSettings'->new($_) } @$_ ] };

declare 'MapStringSurgeSettings',
    as HashRef[SurgeSettings()];

declare 'AwsNodeManagement',
    as InstanceOf['Google::Cloud::Gkemulticloud::V1::AwsResources::AwsNodeManagement'];

coerce 'AwsNodeManagement',
    from HashRef, via { 'Google::Cloud::Gkemulticloud::V1::AwsResources::AwsNodeManagement'->new($_) };

declare 'RepeatedAwsNodeManagement',
    as ArrayRef[AwsNodeManagement()];

coerce 'RepeatedAwsNodeManagement',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkemulticloud::V1::AwsResources::AwsNodeManagement'->new($_) } @$_ ] };

declare 'MapStringAwsNodeManagement',
    as HashRef[AwsNodeManagement()];

declare 'AwsNodeConfig',
    as InstanceOf['Google::Cloud::Gkemulticloud::V1::AwsResources::AwsNodeConfig'];

coerce 'AwsNodeConfig',
    from HashRef, via { 'Google::Cloud::Gkemulticloud::V1::AwsResources::AwsNodeConfig'->new($_) };

declare 'RepeatedAwsNodeConfig',
    as ArrayRef[AwsNodeConfig()];

coerce 'RepeatedAwsNodeConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkemulticloud::V1::AwsResources::AwsNodeConfig'->new($_) } @$_ ] };

declare 'MapStringAwsNodeConfig',
    as HashRef[AwsNodeConfig()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Gkemulticloud::V1::AwsResources::AwsNodeConfig::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Gkemulticloud::V1::AwsResources::AwsNodeConfig::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkemulticloud::V1::AwsResources::AwsNodeConfig::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'TagsEntry',
    as InstanceOf['Google::Cloud::Gkemulticloud::V1::AwsResources::AwsNodeConfig::TagsEntry'];

coerce 'TagsEntry',
    from HashRef, via { 'Google::Cloud::Gkemulticloud::V1::AwsResources::AwsNodeConfig::TagsEntry'->new($_) };

declare 'RepeatedTagsEntry',
    as ArrayRef[TagsEntry()];

coerce 'RepeatedTagsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkemulticloud::V1::AwsResources::AwsNodeConfig::TagsEntry'->new($_) } @$_ ] };

declare 'MapStringTagsEntry',
    as HashRef[TagsEntry()];

declare 'AwsNodePoolAutoscaling',
    as InstanceOf['Google::Cloud::Gkemulticloud::V1::AwsResources::AwsNodePoolAutoscaling'];

coerce 'AwsNodePoolAutoscaling',
    from HashRef, via { 'Google::Cloud::Gkemulticloud::V1::AwsResources::AwsNodePoolAutoscaling'->new($_) };

declare 'RepeatedAwsNodePoolAutoscaling',
    as ArrayRef[AwsNodePoolAutoscaling()];

coerce 'RepeatedAwsNodePoolAutoscaling',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkemulticloud::V1::AwsResources::AwsNodePoolAutoscaling'->new($_) } @$_ ] };

declare 'MapStringAwsNodePoolAutoscaling',
    as HashRef[AwsNodePoolAutoscaling()];

declare 'AwsOpenIdConfig',
    as InstanceOf['Google::Cloud::Gkemulticloud::V1::AwsResources::AwsOpenIdConfig'];

coerce 'AwsOpenIdConfig',
    from HashRef, via { 'Google::Cloud::Gkemulticloud::V1::AwsResources::AwsOpenIdConfig'->new($_) };

declare 'RepeatedAwsOpenIdConfig',
    as ArrayRef[AwsOpenIdConfig()];

coerce 'RepeatedAwsOpenIdConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkemulticloud::V1::AwsResources::AwsOpenIdConfig'->new($_) } @$_ ] };

declare 'MapStringAwsOpenIdConfig',
    as HashRef[AwsOpenIdConfig()];

declare 'AwsJsonWebKeys',
    as InstanceOf['Google::Cloud::Gkemulticloud::V1::AwsResources::AwsJsonWebKeys'];

coerce 'AwsJsonWebKeys',
    from HashRef, via { 'Google::Cloud::Gkemulticloud::V1::AwsResources::AwsJsonWebKeys'->new($_) };

declare 'RepeatedAwsJsonWebKeys',
    as ArrayRef[AwsJsonWebKeys()];

coerce 'RepeatedAwsJsonWebKeys',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkemulticloud::V1::AwsResources::AwsJsonWebKeys'->new($_) } @$_ ] };

declare 'MapStringAwsJsonWebKeys',
    as HashRef[AwsJsonWebKeys()];

declare 'AwsServerConfig',
    as InstanceOf['Google::Cloud::Gkemulticloud::V1::AwsResources::AwsServerConfig'];

coerce 'AwsServerConfig',
    from HashRef, via { 'Google::Cloud::Gkemulticloud::V1::AwsResources::AwsServerConfig'->new($_) };

declare 'RepeatedAwsServerConfig',
    as ArrayRef[AwsServerConfig()];

coerce 'RepeatedAwsServerConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkemulticloud::V1::AwsResources::AwsServerConfig'->new($_) } @$_ ] };

declare 'MapStringAwsServerConfig',
    as HashRef[AwsServerConfig()];

declare 'AwsK8sVersionInfo',
    as InstanceOf['Google::Cloud::Gkemulticloud::V1::AwsResources::AwsK8sVersionInfo'];

coerce 'AwsK8sVersionInfo',
    from HashRef, via { 'Google::Cloud::Gkemulticloud::V1::AwsResources::AwsK8sVersionInfo'->new($_) };

declare 'RepeatedAwsK8sVersionInfo',
    as ArrayRef[AwsK8sVersionInfo()];

coerce 'RepeatedAwsK8sVersionInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkemulticloud::V1::AwsResources::AwsK8sVersionInfo'->new($_) } @$_ ] };

declare 'MapStringAwsK8sVersionInfo',
    as HashRef[AwsK8sVersionInfo()];

declare 'AwsSshConfig',
    as InstanceOf['Google::Cloud::Gkemulticloud::V1::AwsResources::AwsSshConfig'];

coerce 'AwsSshConfig',
    from HashRef, via { 'Google::Cloud::Gkemulticloud::V1::AwsResources::AwsSshConfig'->new($_) };

declare 'RepeatedAwsSshConfig',
    as ArrayRef[AwsSshConfig()];

coerce 'RepeatedAwsSshConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkemulticloud::V1::AwsResources::AwsSshConfig'->new($_) } @$_ ] };

declare 'MapStringAwsSshConfig',
    as HashRef[AwsSshConfig()];

declare 'AwsProxyConfig',
    as InstanceOf['Google::Cloud::Gkemulticloud::V1::AwsResources::AwsProxyConfig'];

coerce 'AwsProxyConfig',
    from HashRef, via { 'Google::Cloud::Gkemulticloud::V1::AwsResources::AwsProxyConfig'->new($_) };

declare 'RepeatedAwsProxyConfig',
    as ArrayRef[AwsProxyConfig()];

coerce 'RepeatedAwsProxyConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkemulticloud::V1::AwsResources::AwsProxyConfig'->new($_) } @$_ ] };

declare 'MapStringAwsProxyConfig',
    as HashRef[AwsProxyConfig()];

declare 'AwsConfigEncryption',
    as InstanceOf['Google::Cloud::Gkemulticloud::V1::AwsResources::AwsConfigEncryption'];

coerce 'AwsConfigEncryption',
    from HashRef, via { 'Google::Cloud::Gkemulticloud::V1::AwsResources::AwsConfigEncryption'->new($_) };

declare 'RepeatedAwsConfigEncryption',
    as ArrayRef[AwsConfigEncryption()];

coerce 'RepeatedAwsConfigEncryption',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkemulticloud::V1::AwsResources::AwsConfigEncryption'->new($_) } @$_ ] };

declare 'MapStringAwsConfigEncryption',
    as HashRef[AwsConfigEncryption()];

declare 'AwsInstancePlacement',
    as InstanceOf['Google::Cloud::Gkemulticloud::V1::AwsResources::AwsInstancePlacement'];

coerce 'AwsInstancePlacement',
    from HashRef, via { 'Google::Cloud::Gkemulticloud::V1::AwsResources::AwsInstancePlacement'->new($_) };

declare 'RepeatedAwsInstancePlacement',
    as ArrayRef[AwsInstancePlacement()];

coerce 'RepeatedAwsInstancePlacement',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkemulticloud::V1::AwsResources::AwsInstancePlacement'->new($_) } @$_ ] };

declare 'MapStringAwsInstancePlacement',
    as HashRef[AwsInstancePlacement()];

declare 'Tenancy',
    as (Int | Str);

declare 'AwsAutoscalingGroupMetricsCollection',
    as InstanceOf['Google::Cloud::Gkemulticloud::V1::AwsResources::AwsAutoscalingGroupMetricsCollection'];

coerce 'AwsAutoscalingGroupMetricsCollection',
    from HashRef, via { 'Google::Cloud::Gkemulticloud::V1::AwsResources::AwsAutoscalingGroupMetricsCollection'->new($_) };

declare 'RepeatedAwsAutoscalingGroupMetricsCollection',
    as ArrayRef[AwsAutoscalingGroupMetricsCollection()];

coerce 'RepeatedAwsAutoscalingGroupMetricsCollection',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkemulticloud::V1::AwsResources::AwsAutoscalingGroupMetricsCollection'->new($_) } @$_ ] };

declare 'MapStringAwsAutoscalingGroupMetricsCollection',
    as HashRef[AwsAutoscalingGroupMetricsCollection()];

declare 'SpotConfig',
    as InstanceOf['Google::Cloud::Gkemulticloud::V1::AwsResources::SpotConfig'];

coerce 'SpotConfig',
    from HashRef, via { 'Google::Cloud::Gkemulticloud::V1::AwsResources::SpotConfig'->new($_) };

declare 'RepeatedSpotConfig',
    as ArrayRef[SpotConfig()];

coerce 'RepeatedSpotConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkemulticloud::V1::AwsResources::SpotConfig'->new($_) } @$_ ] };

declare 'MapStringSpotConfig',
    as HashRef[SpotConfig()];

declare 'AwsClusterError',
    as InstanceOf['Google::Cloud::Gkemulticloud::V1::AwsResources::AwsClusterError'];

coerce 'AwsClusterError',
    from HashRef, via { 'Google::Cloud::Gkemulticloud::V1::AwsResources::AwsClusterError'->new($_) };

declare 'RepeatedAwsClusterError',
    as ArrayRef[AwsClusterError()];

coerce 'RepeatedAwsClusterError',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkemulticloud::V1::AwsResources::AwsClusterError'->new($_) } @$_ ] };

declare 'MapStringAwsClusterError',
    as HashRef[AwsClusterError()];

declare 'AwsNodePoolError',
    as InstanceOf['Google::Cloud::Gkemulticloud::V1::AwsResources::AwsNodePoolError'];

coerce 'AwsNodePoolError',
    from HashRef, via { 'Google::Cloud::Gkemulticloud::V1::AwsResources::AwsNodePoolError'->new($_) };

declare 'RepeatedAwsNodePoolError',
    as ArrayRef[AwsNodePoolError()];

coerce 'RepeatedAwsNodePoolError',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkemulticloud::V1::AwsResources::AwsNodePoolError'->new($_) } @$_ ] };

declare 'MapStringAwsNodePoolError',
    as HashRef[AwsNodePoolError()];

1;

__END__

=head1 NAME

Google::Cloud::Gkemulticloud::V1::AwsResources::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
