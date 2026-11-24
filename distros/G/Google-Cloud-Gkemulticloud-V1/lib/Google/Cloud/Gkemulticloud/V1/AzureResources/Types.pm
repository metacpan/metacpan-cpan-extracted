package Google::Cloud::Gkemulticloud::V1::AzureResources::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'AzureCluster',
    as InstanceOf['Google::Cloud::Gkemulticloud::V1::AzureResources::AzureCluster'];

coerce 'AzureCluster',
    from HashRef, via { 'Google::Cloud::Gkemulticloud::V1::AzureResources::AzureCluster'->new($_) };

declare 'RepeatedAzureCluster',
    as ArrayRef[AzureCluster()];

coerce 'RepeatedAzureCluster',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkemulticloud::V1::AzureResources::AzureCluster'->new($_) } @$_ ] };

declare 'MapStringAzureCluster',
    as HashRef[AzureCluster()];

declare 'State',
    as (Int | Str);

declare 'AnnotationsEntry',
    as InstanceOf['Google::Cloud::Gkemulticloud::V1::AzureResources::AzureCluster::AnnotationsEntry'];

coerce 'AnnotationsEntry',
    from HashRef, via { 'Google::Cloud::Gkemulticloud::V1::AzureResources::AzureCluster::AnnotationsEntry'->new($_) };

declare 'RepeatedAnnotationsEntry',
    as ArrayRef[AnnotationsEntry()];

coerce 'RepeatedAnnotationsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkemulticloud::V1::AzureResources::AzureCluster::AnnotationsEntry'->new($_) } @$_ ] };

declare 'MapStringAnnotationsEntry',
    as HashRef[AnnotationsEntry()];

declare 'AzureClusterNetworking',
    as InstanceOf['Google::Cloud::Gkemulticloud::V1::AzureResources::AzureClusterNetworking'];

coerce 'AzureClusterNetworking',
    from HashRef, via { 'Google::Cloud::Gkemulticloud::V1::AzureResources::AzureClusterNetworking'->new($_) };

declare 'RepeatedAzureClusterNetworking',
    as ArrayRef[AzureClusterNetworking()];

coerce 'RepeatedAzureClusterNetworking',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkemulticloud::V1::AzureResources::AzureClusterNetworking'->new($_) } @$_ ] };

declare 'MapStringAzureClusterNetworking',
    as HashRef[AzureClusterNetworking()];

declare 'AzureControlPlane',
    as InstanceOf['Google::Cloud::Gkemulticloud::V1::AzureResources::AzureControlPlane'];

coerce 'AzureControlPlane',
    from HashRef, via { 'Google::Cloud::Gkemulticloud::V1::AzureResources::AzureControlPlane'->new($_) };

declare 'RepeatedAzureControlPlane',
    as ArrayRef[AzureControlPlane()];

coerce 'RepeatedAzureControlPlane',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkemulticloud::V1::AzureResources::AzureControlPlane'->new($_) } @$_ ] };

declare 'MapStringAzureControlPlane',
    as HashRef[AzureControlPlane()];

declare 'TagsEntry',
    as InstanceOf['Google::Cloud::Gkemulticloud::V1::AzureResources::AzureControlPlane::TagsEntry'];

coerce 'TagsEntry',
    from HashRef, via { 'Google::Cloud::Gkemulticloud::V1::AzureResources::AzureControlPlane::TagsEntry'->new($_) };

declare 'RepeatedTagsEntry',
    as ArrayRef[TagsEntry()];

coerce 'RepeatedTagsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkemulticloud::V1::AzureResources::AzureControlPlane::TagsEntry'->new($_) } @$_ ] };

declare 'MapStringTagsEntry',
    as HashRef[TagsEntry()];

declare 'ReplicaPlacement',
    as InstanceOf['Google::Cloud::Gkemulticloud::V1::AzureResources::ReplicaPlacement'];

coerce 'ReplicaPlacement',
    from HashRef, via { 'Google::Cloud::Gkemulticloud::V1::AzureResources::ReplicaPlacement'->new($_) };

declare 'RepeatedReplicaPlacement',
    as ArrayRef[ReplicaPlacement()];

coerce 'RepeatedReplicaPlacement',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkemulticloud::V1::AzureResources::ReplicaPlacement'->new($_) } @$_ ] };

declare 'MapStringReplicaPlacement',
    as HashRef[ReplicaPlacement()];

declare 'AzureProxyConfig',
    as InstanceOf['Google::Cloud::Gkemulticloud::V1::AzureResources::AzureProxyConfig'];

coerce 'AzureProxyConfig',
    from HashRef, via { 'Google::Cloud::Gkemulticloud::V1::AzureResources::AzureProxyConfig'->new($_) };

declare 'RepeatedAzureProxyConfig',
    as ArrayRef[AzureProxyConfig()];

coerce 'RepeatedAzureProxyConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkemulticloud::V1::AzureResources::AzureProxyConfig'->new($_) } @$_ ] };

declare 'MapStringAzureProxyConfig',
    as HashRef[AzureProxyConfig()];

declare 'AzureDatabaseEncryption',
    as InstanceOf['Google::Cloud::Gkemulticloud::V1::AzureResources::AzureDatabaseEncryption'];

coerce 'AzureDatabaseEncryption',
    from HashRef, via { 'Google::Cloud::Gkemulticloud::V1::AzureResources::AzureDatabaseEncryption'->new($_) };

declare 'RepeatedAzureDatabaseEncryption',
    as ArrayRef[AzureDatabaseEncryption()];

coerce 'RepeatedAzureDatabaseEncryption',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkemulticloud::V1::AzureResources::AzureDatabaseEncryption'->new($_) } @$_ ] };

declare 'MapStringAzureDatabaseEncryption',
    as HashRef[AzureDatabaseEncryption()];

declare 'AzureConfigEncryption',
    as InstanceOf['Google::Cloud::Gkemulticloud::V1::AzureResources::AzureConfigEncryption'];

coerce 'AzureConfigEncryption',
    from HashRef, via { 'Google::Cloud::Gkemulticloud::V1::AzureResources::AzureConfigEncryption'->new($_) };

declare 'RepeatedAzureConfigEncryption',
    as ArrayRef[AzureConfigEncryption()];

coerce 'RepeatedAzureConfigEncryption',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkemulticloud::V1::AzureResources::AzureConfigEncryption'->new($_) } @$_ ] };

declare 'MapStringAzureConfigEncryption',
    as HashRef[AzureConfigEncryption()];

declare 'AzureDiskTemplate',
    as InstanceOf['Google::Cloud::Gkemulticloud::V1::AzureResources::AzureDiskTemplate'];

coerce 'AzureDiskTemplate',
    from HashRef, via { 'Google::Cloud::Gkemulticloud::V1::AzureResources::AzureDiskTemplate'->new($_) };

declare 'RepeatedAzureDiskTemplate',
    as ArrayRef[AzureDiskTemplate()];

coerce 'RepeatedAzureDiskTemplate',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkemulticloud::V1::AzureResources::AzureDiskTemplate'->new($_) } @$_ ] };

declare 'MapStringAzureDiskTemplate',
    as HashRef[AzureDiskTemplate()];

declare 'AzureClient',
    as InstanceOf['Google::Cloud::Gkemulticloud::V1::AzureResources::AzureClient'];

coerce 'AzureClient',
    from HashRef, via { 'Google::Cloud::Gkemulticloud::V1::AzureResources::AzureClient'->new($_) };

declare 'RepeatedAzureClient',
    as ArrayRef[AzureClient()];

coerce 'RepeatedAzureClient',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkemulticloud::V1::AzureResources::AzureClient'->new($_) } @$_ ] };

declare 'MapStringAzureClient',
    as HashRef[AzureClient()];

declare 'AnnotationsEntry',
    as InstanceOf['Google::Cloud::Gkemulticloud::V1::AzureResources::AzureClient::AnnotationsEntry'];

coerce 'AnnotationsEntry',
    from HashRef, via { 'Google::Cloud::Gkemulticloud::V1::AzureResources::AzureClient::AnnotationsEntry'->new($_) };

declare 'RepeatedAnnotationsEntry',
    as ArrayRef[AnnotationsEntry()];

coerce 'RepeatedAnnotationsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkemulticloud::V1::AzureResources::AzureClient::AnnotationsEntry'->new($_) } @$_ ] };

declare 'MapStringAnnotationsEntry',
    as HashRef[AnnotationsEntry()];

declare 'AzureAuthorization',
    as InstanceOf['Google::Cloud::Gkemulticloud::V1::AzureResources::AzureAuthorization'];

coerce 'AzureAuthorization',
    from HashRef, via { 'Google::Cloud::Gkemulticloud::V1::AzureResources::AzureAuthorization'->new($_) };

declare 'RepeatedAzureAuthorization',
    as ArrayRef[AzureAuthorization()];

coerce 'RepeatedAzureAuthorization',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkemulticloud::V1::AzureResources::AzureAuthorization'->new($_) } @$_ ] };

declare 'MapStringAzureAuthorization',
    as HashRef[AzureAuthorization()];

declare 'AzureServicesAuthentication',
    as InstanceOf['Google::Cloud::Gkemulticloud::V1::AzureResources::AzureServicesAuthentication'];

coerce 'AzureServicesAuthentication',
    from HashRef, via { 'Google::Cloud::Gkemulticloud::V1::AzureResources::AzureServicesAuthentication'->new($_) };

declare 'RepeatedAzureServicesAuthentication',
    as ArrayRef[AzureServicesAuthentication()];

coerce 'RepeatedAzureServicesAuthentication',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkemulticloud::V1::AzureResources::AzureServicesAuthentication'->new($_) } @$_ ] };

declare 'MapStringAzureServicesAuthentication',
    as HashRef[AzureServicesAuthentication()];

declare 'AzureClusterUser',
    as InstanceOf['Google::Cloud::Gkemulticloud::V1::AzureResources::AzureClusterUser'];

coerce 'AzureClusterUser',
    from HashRef, via { 'Google::Cloud::Gkemulticloud::V1::AzureResources::AzureClusterUser'->new($_) };

declare 'RepeatedAzureClusterUser',
    as ArrayRef[AzureClusterUser()];

coerce 'RepeatedAzureClusterUser',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkemulticloud::V1::AzureResources::AzureClusterUser'->new($_) } @$_ ] };

declare 'MapStringAzureClusterUser',
    as HashRef[AzureClusterUser()];

declare 'AzureClusterGroup',
    as InstanceOf['Google::Cloud::Gkemulticloud::V1::AzureResources::AzureClusterGroup'];

coerce 'AzureClusterGroup',
    from HashRef, via { 'Google::Cloud::Gkemulticloud::V1::AzureResources::AzureClusterGroup'->new($_) };

declare 'RepeatedAzureClusterGroup',
    as ArrayRef[AzureClusterGroup()];

coerce 'RepeatedAzureClusterGroup',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkemulticloud::V1::AzureResources::AzureClusterGroup'->new($_) } @$_ ] };

declare 'MapStringAzureClusterGroup',
    as HashRef[AzureClusterGroup()];

declare 'AzureNodePool',
    as InstanceOf['Google::Cloud::Gkemulticloud::V1::AzureResources::AzureNodePool'];

coerce 'AzureNodePool',
    from HashRef, via { 'Google::Cloud::Gkemulticloud::V1::AzureResources::AzureNodePool'->new($_) };

declare 'RepeatedAzureNodePool',
    as ArrayRef[AzureNodePool()];

coerce 'RepeatedAzureNodePool',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkemulticloud::V1::AzureResources::AzureNodePool'->new($_) } @$_ ] };

declare 'MapStringAzureNodePool',
    as HashRef[AzureNodePool()];

declare 'State',
    as (Int | Str);

declare 'AnnotationsEntry',
    as InstanceOf['Google::Cloud::Gkemulticloud::V1::AzureResources::AzureNodePool::AnnotationsEntry'];

coerce 'AnnotationsEntry',
    from HashRef, via { 'Google::Cloud::Gkemulticloud::V1::AzureResources::AzureNodePool::AnnotationsEntry'->new($_) };

declare 'RepeatedAnnotationsEntry',
    as ArrayRef[AnnotationsEntry()];

coerce 'RepeatedAnnotationsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkemulticloud::V1::AzureResources::AzureNodePool::AnnotationsEntry'->new($_) } @$_ ] };

declare 'MapStringAnnotationsEntry',
    as HashRef[AnnotationsEntry()];

declare 'AzureNodeManagement',
    as InstanceOf['Google::Cloud::Gkemulticloud::V1::AzureResources::AzureNodeManagement'];

coerce 'AzureNodeManagement',
    from HashRef, via { 'Google::Cloud::Gkemulticloud::V1::AzureResources::AzureNodeManagement'->new($_) };

declare 'RepeatedAzureNodeManagement',
    as ArrayRef[AzureNodeManagement()];

coerce 'RepeatedAzureNodeManagement',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkemulticloud::V1::AzureResources::AzureNodeManagement'->new($_) } @$_ ] };

declare 'MapStringAzureNodeManagement',
    as HashRef[AzureNodeManagement()];

declare 'AzureNodeConfig',
    as InstanceOf['Google::Cloud::Gkemulticloud::V1::AzureResources::AzureNodeConfig'];

coerce 'AzureNodeConfig',
    from HashRef, via { 'Google::Cloud::Gkemulticloud::V1::AzureResources::AzureNodeConfig'->new($_) };

declare 'RepeatedAzureNodeConfig',
    as ArrayRef[AzureNodeConfig()];

coerce 'RepeatedAzureNodeConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkemulticloud::V1::AzureResources::AzureNodeConfig'->new($_) } @$_ ] };

declare 'MapStringAzureNodeConfig',
    as HashRef[AzureNodeConfig()];

declare 'TagsEntry',
    as InstanceOf['Google::Cloud::Gkemulticloud::V1::AzureResources::AzureNodeConfig::TagsEntry'];

coerce 'TagsEntry',
    from HashRef, via { 'Google::Cloud::Gkemulticloud::V1::AzureResources::AzureNodeConfig::TagsEntry'->new($_) };

declare 'RepeatedTagsEntry',
    as ArrayRef[TagsEntry()];

coerce 'RepeatedTagsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkemulticloud::V1::AzureResources::AzureNodeConfig::TagsEntry'->new($_) } @$_ ] };

declare 'MapStringTagsEntry',
    as HashRef[TagsEntry()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Gkemulticloud::V1::AzureResources::AzureNodeConfig::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Gkemulticloud::V1::AzureResources::AzureNodeConfig::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkemulticloud::V1::AzureResources::AzureNodeConfig::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'AzureNodePoolAutoscaling',
    as InstanceOf['Google::Cloud::Gkemulticloud::V1::AzureResources::AzureNodePoolAutoscaling'];

coerce 'AzureNodePoolAutoscaling',
    from HashRef, via { 'Google::Cloud::Gkemulticloud::V1::AzureResources::AzureNodePoolAutoscaling'->new($_) };

declare 'RepeatedAzureNodePoolAutoscaling',
    as ArrayRef[AzureNodePoolAutoscaling()];

coerce 'RepeatedAzureNodePoolAutoscaling',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkemulticloud::V1::AzureResources::AzureNodePoolAutoscaling'->new($_) } @$_ ] };

declare 'MapStringAzureNodePoolAutoscaling',
    as HashRef[AzureNodePoolAutoscaling()];

declare 'AzureOpenIdConfig',
    as InstanceOf['Google::Cloud::Gkemulticloud::V1::AzureResources::AzureOpenIdConfig'];

coerce 'AzureOpenIdConfig',
    from HashRef, via { 'Google::Cloud::Gkemulticloud::V1::AzureResources::AzureOpenIdConfig'->new($_) };

declare 'RepeatedAzureOpenIdConfig',
    as ArrayRef[AzureOpenIdConfig()];

coerce 'RepeatedAzureOpenIdConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkemulticloud::V1::AzureResources::AzureOpenIdConfig'->new($_) } @$_ ] };

declare 'MapStringAzureOpenIdConfig',
    as HashRef[AzureOpenIdConfig()];

declare 'AzureJsonWebKeys',
    as InstanceOf['Google::Cloud::Gkemulticloud::V1::AzureResources::AzureJsonWebKeys'];

coerce 'AzureJsonWebKeys',
    from HashRef, via { 'Google::Cloud::Gkemulticloud::V1::AzureResources::AzureJsonWebKeys'->new($_) };

declare 'RepeatedAzureJsonWebKeys',
    as ArrayRef[AzureJsonWebKeys()];

coerce 'RepeatedAzureJsonWebKeys',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkemulticloud::V1::AzureResources::AzureJsonWebKeys'->new($_) } @$_ ] };

declare 'MapStringAzureJsonWebKeys',
    as HashRef[AzureJsonWebKeys()];

declare 'AzureServerConfig',
    as InstanceOf['Google::Cloud::Gkemulticloud::V1::AzureResources::AzureServerConfig'];

coerce 'AzureServerConfig',
    from HashRef, via { 'Google::Cloud::Gkemulticloud::V1::AzureResources::AzureServerConfig'->new($_) };

declare 'RepeatedAzureServerConfig',
    as ArrayRef[AzureServerConfig()];

coerce 'RepeatedAzureServerConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkemulticloud::V1::AzureResources::AzureServerConfig'->new($_) } @$_ ] };

declare 'MapStringAzureServerConfig',
    as HashRef[AzureServerConfig()];

declare 'AzureK8sVersionInfo',
    as InstanceOf['Google::Cloud::Gkemulticloud::V1::AzureResources::AzureK8sVersionInfo'];

coerce 'AzureK8sVersionInfo',
    from HashRef, via { 'Google::Cloud::Gkemulticloud::V1::AzureResources::AzureK8sVersionInfo'->new($_) };

declare 'RepeatedAzureK8sVersionInfo',
    as ArrayRef[AzureK8sVersionInfo()];

coerce 'RepeatedAzureK8sVersionInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkemulticloud::V1::AzureResources::AzureK8sVersionInfo'->new($_) } @$_ ] };

declare 'MapStringAzureK8sVersionInfo',
    as HashRef[AzureK8sVersionInfo()];

declare 'AzureSshConfig',
    as InstanceOf['Google::Cloud::Gkemulticloud::V1::AzureResources::AzureSshConfig'];

coerce 'AzureSshConfig',
    from HashRef, via { 'Google::Cloud::Gkemulticloud::V1::AzureResources::AzureSshConfig'->new($_) };

declare 'RepeatedAzureSshConfig',
    as ArrayRef[AzureSshConfig()];

coerce 'RepeatedAzureSshConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkemulticloud::V1::AzureResources::AzureSshConfig'->new($_) } @$_ ] };

declare 'MapStringAzureSshConfig',
    as HashRef[AzureSshConfig()];

declare 'AzureClusterResources',
    as InstanceOf['Google::Cloud::Gkemulticloud::V1::AzureResources::AzureClusterResources'];

coerce 'AzureClusterResources',
    from HashRef, via { 'Google::Cloud::Gkemulticloud::V1::AzureResources::AzureClusterResources'->new($_) };

declare 'RepeatedAzureClusterResources',
    as ArrayRef[AzureClusterResources()];

coerce 'RepeatedAzureClusterResources',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkemulticloud::V1::AzureResources::AzureClusterResources'->new($_) } @$_ ] };

declare 'MapStringAzureClusterResources',
    as HashRef[AzureClusterResources()];

declare 'AzureClusterError',
    as InstanceOf['Google::Cloud::Gkemulticloud::V1::AzureResources::AzureClusterError'];

coerce 'AzureClusterError',
    from HashRef, via { 'Google::Cloud::Gkemulticloud::V1::AzureResources::AzureClusterError'->new($_) };

declare 'RepeatedAzureClusterError',
    as ArrayRef[AzureClusterError()];

coerce 'RepeatedAzureClusterError',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkemulticloud::V1::AzureResources::AzureClusterError'->new($_) } @$_ ] };

declare 'MapStringAzureClusterError',
    as HashRef[AzureClusterError()];

declare 'AzureNodePoolError',
    as InstanceOf['Google::Cloud::Gkemulticloud::V1::AzureResources::AzureNodePoolError'];

coerce 'AzureNodePoolError',
    from HashRef, via { 'Google::Cloud::Gkemulticloud::V1::AzureResources::AzureNodePoolError'->new($_) };

declare 'RepeatedAzureNodePoolError',
    as ArrayRef[AzureNodePoolError()];

coerce 'RepeatedAzureNodePoolError',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkemulticloud::V1::AzureResources::AzureNodePoolError'->new($_) } @$_ ] };

declare 'MapStringAzureNodePoolError',
    as HashRef[AzureNodePoolError()];

1;

__END__

=head1 NAME

Google::Cloud::Gkemulticloud::V1::AzureResources::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
