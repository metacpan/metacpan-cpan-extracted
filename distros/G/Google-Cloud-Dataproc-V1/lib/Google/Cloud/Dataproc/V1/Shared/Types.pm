package Google::Cloud::Dataproc::V1::Shared::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Component',
    as (Int | Str);

declare 'FailureAction',
    as (Int | Str);

declare 'RuntimeConfig',
    as InstanceOf['Google::Cloud::Dataproc::V1::Shared::RuntimeConfig'];

coerce 'RuntimeConfig',
    from HashRef, via { 'Google::Cloud::Dataproc::V1::Shared::RuntimeConfig'->new($_) };

declare 'RepeatedRuntimeConfig',
    as ArrayRef[RuntimeConfig()];

coerce 'RepeatedRuntimeConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataproc::V1::Shared::RuntimeConfig'->new($_) } @$_ ] };

declare 'MapStringRuntimeConfig',
    as HashRef[RuntimeConfig()];

declare 'PropertiesEntry',
    as InstanceOf['Google::Cloud::Dataproc::V1::Shared::RuntimeConfig::PropertiesEntry'];

coerce 'PropertiesEntry',
    from HashRef, via { 'Google::Cloud::Dataproc::V1::Shared::RuntimeConfig::PropertiesEntry'->new($_) };

declare 'RepeatedPropertiesEntry',
    as ArrayRef[PropertiesEntry()];

coerce 'RepeatedPropertiesEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataproc::V1::Shared::RuntimeConfig::PropertiesEntry'->new($_) } @$_ ] };

declare 'MapStringPropertiesEntry',
    as HashRef[PropertiesEntry()];

declare 'EnvironmentConfig',
    as InstanceOf['Google::Cloud::Dataproc::V1::Shared::EnvironmentConfig'];

coerce 'EnvironmentConfig',
    from HashRef, via { 'Google::Cloud::Dataproc::V1::Shared::EnvironmentConfig'->new($_) };

declare 'RepeatedEnvironmentConfig',
    as ArrayRef[EnvironmentConfig()];

coerce 'RepeatedEnvironmentConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataproc::V1::Shared::EnvironmentConfig'->new($_) } @$_ ] };

declare 'MapStringEnvironmentConfig',
    as HashRef[EnvironmentConfig()];

declare 'ExecutionConfig',
    as InstanceOf['Google::Cloud::Dataproc::V1::Shared::ExecutionConfig'];

coerce 'ExecutionConfig',
    from HashRef, via { 'Google::Cloud::Dataproc::V1::Shared::ExecutionConfig'->new($_) };

declare 'RepeatedExecutionConfig',
    as ArrayRef[ExecutionConfig()];

coerce 'RepeatedExecutionConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataproc::V1::Shared::ExecutionConfig'->new($_) } @$_ ] };

declare 'MapStringExecutionConfig',
    as HashRef[ExecutionConfig()];

declare 'ResourceManagerTagsEntry',
    as InstanceOf['Google::Cloud::Dataproc::V1::Shared::ExecutionConfig::ResourceManagerTagsEntry'];

coerce 'ResourceManagerTagsEntry',
    from HashRef, via { 'Google::Cloud::Dataproc::V1::Shared::ExecutionConfig::ResourceManagerTagsEntry'->new($_) };

declare 'RepeatedResourceManagerTagsEntry',
    as ArrayRef[ResourceManagerTagsEntry()];

coerce 'RepeatedResourceManagerTagsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataproc::V1::Shared::ExecutionConfig::ResourceManagerTagsEntry'->new($_) } @$_ ] };

declare 'MapStringResourceManagerTagsEntry',
    as HashRef[ResourceManagerTagsEntry()];

declare 'SparkHistoryServerConfig',
    as InstanceOf['Google::Cloud::Dataproc::V1::Shared::SparkHistoryServerConfig'];

coerce 'SparkHistoryServerConfig',
    from HashRef, via { 'Google::Cloud::Dataproc::V1::Shared::SparkHistoryServerConfig'->new($_) };

declare 'RepeatedSparkHistoryServerConfig',
    as ArrayRef[SparkHistoryServerConfig()];

coerce 'RepeatedSparkHistoryServerConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataproc::V1::Shared::SparkHistoryServerConfig'->new($_) } @$_ ] };

declare 'MapStringSparkHistoryServerConfig',
    as HashRef[SparkHistoryServerConfig()];

declare 'PeripheralsConfig',
    as InstanceOf['Google::Cloud::Dataproc::V1::Shared::PeripheralsConfig'];

coerce 'PeripheralsConfig',
    from HashRef, via { 'Google::Cloud::Dataproc::V1::Shared::PeripheralsConfig'->new($_) };

declare 'RepeatedPeripheralsConfig',
    as ArrayRef[PeripheralsConfig()];

coerce 'RepeatedPeripheralsConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataproc::V1::Shared::PeripheralsConfig'->new($_) } @$_ ] };

declare 'MapStringPeripheralsConfig',
    as HashRef[PeripheralsConfig()];

declare 'RuntimeInfo',
    as InstanceOf['Google::Cloud::Dataproc::V1::Shared::RuntimeInfo'];

coerce 'RuntimeInfo',
    from HashRef, via { 'Google::Cloud::Dataproc::V1::Shared::RuntimeInfo'->new($_) };

declare 'RepeatedRuntimeInfo',
    as ArrayRef[RuntimeInfo()];

coerce 'RepeatedRuntimeInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataproc::V1::Shared::RuntimeInfo'->new($_) } @$_ ] };

declare 'MapStringRuntimeInfo',
    as HashRef[RuntimeInfo()];

declare 'EndpointsEntry',
    as InstanceOf['Google::Cloud::Dataproc::V1::Shared::RuntimeInfo::EndpointsEntry'];

coerce 'EndpointsEntry',
    from HashRef, via { 'Google::Cloud::Dataproc::V1::Shared::RuntimeInfo::EndpointsEntry'->new($_) };

declare 'RepeatedEndpointsEntry',
    as ArrayRef[EndpointsEntry()];

coerce 'RepeatedEndpointsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataproc::V1::Shared::RuntimeInfo::EndpointsEntry'->new($_) } @$_ ] };

declare 'MapStringEndpointsEntry',
    as HashRef[EndpointsEntry()];

declare 'UsageMetrics',
    as InstanceOf['Google::Cloud::Dataproc::V1::Shared::UsageMetrics'];

coerce 'UsageMetrics',
    from HashRef, via { 'Google::Cloud::Dataproc::V1::Shared::UsageMetrics'->new($_) };

declare 'RepeatedUsageMetrics',
    as ArrayRef[UsageMetrics()];

coerce 'RepeatedUsageMetrics',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataproc::V1::Shared::UsageMetrics'->new($_) } @$_ ] };

declare 'MapStringUsageMetrics',
    as HashRef[UsageMetrics()];

declare 'UsageSnapshot',
    as InstanceOf['Google::Cloud::Dataproc::V1::Shared::UsageSnapshot'];

coerce 'UsageSnapshot',
    from HashRef, via { 'Google::Cloud::Dataproc::V1::Shared::UsageSnapshot'->new($_) };

declare 'RepeatedUsageSnapshot',
    as ArrayRef[UsageSnapshot()];

coerce 'RepeatedUsageSnapshot',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataproc::V1::Shared::UsageSnapshot'->new($_) } @$_ ] };

declare 'MapStringUsageSnapshot',
    as HashRef[UsageSnapshot()];

declare 'GkeClusterConfig',
    as InstanceOf['Google::Cloud::Dataproc::V1::Shared::GkeClusterConfig'];

coerce 'GkeClusterConfig',
    from HashRef, via { 'Google::Cloud::Dataproc::V1::Shared::GkeClusterConfig'->new($_) };

declare 'RepeatedGkeClusterConfig',
    as ArrayRef[GkeClusterConfig()];

coerce 'RepeatedGkeClusterConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataproc::V1::Shared::GkeClusterConfig'->new($_) } @$_ ] };

declare 'MapStringGkeClusterConfig',
    as HashRef[GkeClusterConfig()];

declare 'KubernetesClusterConfig',
    as InstanceOf['Google::Cloud::Dataproc::V1::Shared::KubernetesClusterConfig'];

coerce 'KubernetesClusterConfig',
    from HashRef, via { 'Google::Cloud::Dataproc::V1::Shared::KubernetesClusterConfig'->new($_) };

declare 'RepeatedKubernetesClusterConfig',
    as ArrayRef[KubernetesClusterConfig()];

coerce 'RepeatedKubernetesClusterConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataproc::V1::Shared::KubernetesClusterConfig'->new($_) } @$_ ] };

declare 'MapStringKubernetesClusterConfig',
    as HashRef[KubernetesClusterConfig()];

declare 'KubernetesSoftwareConfig',
    as InstanceOf['Google::Cloud::Dataproc::V1::Shared::KubernetesSoftwareConfig'];

coerce 'KubernetesSoftwareConfig',
    from HashRef, via { 'Google::Cloud::Dataproc::V1::Shared::KubernetesSoftwareConfig'->new($_) };

declare 'RepeatedKubernetesSoftwareConfig',
    as ArrayRef[KubernetesSoftwareConfig()];

coerce 'RepeatedKubernetesSoftwareConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataproc::V1::Shared::KubernetesSoftwareConfig'->new($_) } @$_ ] };

declare 'MapStringKubernetesSoftwareConfig',
    as HashRef[KubernetesSoftwareConfig()];

declare 'ComponentVersionEntry',
    as InstanceOf['Google::Cloud::Dataproc::V1::Shared::KubernetesSoftwareConfig::ComponentVersionEntry'];

coerce 'ComponentVersionEntry',
    from HashRef, via { 'Google::Cloud::Dataproc::V1::Shared::KubernetesSoftwareConfig::ComponentVersionEntry'->new($_) };

declare 'RepeatedComponentVersionEntry',
    as ArrayRef[ComponentVersionEntry()];

coerce 'RepeatedComponentVersionEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataproc::V1::Shared::KubernetesSoftwareConfig::ComponentVersionEntry'->new($_) } @$_ ] };

declare 'MapStringComponentVersionEntry',
    as HashRef[ComponentVersionEntry()];

declare 'PropertiesEntry',
    as InstanceOf['Google::Cloud::Dataproc::V1::Shared::KubernetesSoftwareConfig::PropertiesEntry'];

coerce 'PropertiesEntry',
    from HashRef, via { 'Google::Cloud::Dataproc::V1::Shared::KubernetesSoftwareConfig::PropertiesEntry'->new($_) };

declare 'RepeatedPropertiesEntry',
    as ArrayRef[PropertiesEntry()];

coerce 'RepeatedPropertiesEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataproc::V1::Shared::KubernetesSoftwareConfig::PropertiesEntry'->new($_) } @$_ ] };

declare 'MapStringPropertiesEntry',
    as HashRef[PropertiesEntry()];

declare 'GkeNodePoolTarget',
    as InstanceOf['Google::Cloud::Dataproc::V1::Shared::GkeNodePoolTarget'];

coerce 'GkeNodePoolTarget',
    from HashRef, via { 'Google::Cloud::Dataproc::V1::Shared::GkeNodePoolTarget'->new($_) };

declare 'RepeatedGkeNodePoolTarget',
    as ArrayRef[GkeNodePoolTarget()];

coerce 'RepeatedGkeNodePoolTarget',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataproc::V1::Shared::GkeNodePoolTarget'->new($_) } @$_ ] };

declare 'MapStringGkeNodePoolTarget',
    as HashRef[GkeNodePoolTarget()];

declare 'Role',
    as (Int | Str);

declare 'GkeNodePoolConfig',
    as InstanceOf['Google::Cloud::Dataproc::V1::Shared::GkeNodePoolConfig'];

coerce 'GkeNodePoolConfig',
    from HashRef, via { 'Google::Cloud::Dataproc::V1::Shared::GkeNodePoolConfig'->new($_) };

declare 'RepeatedGkeNodePoolConfig',
    as ArrayRef[GkeNodePoolConfig()];

coerce 'RepeatedGkeNodePoolConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataproc::V1::Shared::GkeNodePoolConfig'->new($_) } @$_ ] };

declare 'MapStringGkeNodePoolConfig',
    as HashRef[GkeNodePoolConfig()];

declare 'GkeNodeConfig',
    as InstanceOf['Google::Cloud::Dataproc::V1::Shared::GkeNodePoolConfig::GkeNodeConfig'];

coerce 'GkeNodeConfig',
    from HashRef, via { 'Google::Cloud::Dataproc::V1::Shared::GkeNodePoolConfig::GkeNodeConfig'->new($_) };

declare 'RepeatedGkeNodeConfig',
    as ArrayRef[GkeNodeConfig()];

coerce 'RepeatedGkeNodeConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataproc::V1::Shared::GkeNodePoolConfig::GkeNodeConfig'->new($_) } @$_ ] };

declare 'MapStringGkeNodeConfig',
    as HashRef[GkeNodeConfig()];

declare 'GkeNodePoolAcceleratorConfig',
    as InstanceOf['Google::Cloud::Dataproc::V1::Shared::GkeNodePoolConfig::GkeNodePoolAcceleratorConfig'];

coerce 'GkeNodePoolAcceleratorConfig',
    from HashRef, via { 'Google::Cloud::Dataproc::V1::Shared::GkeNodePoolConfig::GkeNodePoolAcceleratorConfig'->new($_) };

declare 'RepeatedGkeNodePoolAcceleratorConfig',
    as ArrayRef[GkeNodePoolAcceleratorConfig()];

coerce 'RepeatedGkeNodePoolAcceleratorConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataproc::V1::Shared::GkeNodePoolConfig::GkeNodePoolAcceleratorConfig'->new($_) } @$_ ] };

declare 'MapStringGkeNodePoolAcceleratorConfig',
    as HashRef[GkeNodePoolAcceleratorConfig()];

declare 'GkeNodePoolAutoscalingConfig',
    as InstanceOf['Google::Cloud::Dataproc::V1::Shared::GkeNodePoolConfig::GkeNodePoolAutoscalingConfig'];

coerce 'GkeNodePoolAutoscalingConfig',
    from HashRef, via { 'Google::Cloud::Dataproc::V1::Shared::GkeNodePoolConfig::GkeNodePoolAutoscalingConfig'->new($_) };

declare 'RepeatedGkeNodePoolAutoscalingConfig',
    as ArrayRef[GkeNodePoolAutoscalingConfig()];

coerce 'RepeatedGkeNodePoolAutoscalingConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataproc::V1::Shared::GkeNodePoolConfig::GkeNodePoolAutoscalingConfig'->new($_) } @$_ ] };

declare 'MapStringGkeNodePoolAutoscalingConfig',
    as HashRef[GkeNodePoolAutoscalingConfig()];

declare 'AuthenticationConfig',
    as InstanceOf['Google::Cloud::Dataproc::V1::Shared::AuthenticationConfig'];

coerce 'AuthenticationConfig',
    from HashRef, via { 'Google::Cloud::Dataproc::V1::Shared::AuthenticationConfig'->new($_) };

declare 'RepeatedAuthenticationConfig',
    as ArrayRef[AuthenticationConfig()];

coerce 'RepeatedAuthenticationConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataproc::V1::Shared::AuthenticationConfig'->new($_) } @$_ ] };

declare 'MapStringAuthenticationConfig',
    as HashRef[AuthenticationConfig()];

declare 'AuthenticationType',
    as (Int | Str);

declare 'AutotuningConfig',
    as InstanceOf['Google::Cloud::Dataproc::V1::Shared::AutotuningConfig'];

coerce 'AutotuningConfig',
    from HashRef, via { 'Google::Cloud::Dataproc::V1::Shared::AutotuningConfig'->new($_) };

declare 'RepeatedAutotuningConfig',
    as ArrayRef[AutotuningConfig()];

coerce 'RepeatedAutotuningConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataproc::V1::Shared::AutotuningConfig'->new($_) } @$_ ] };

declare 'MapStringAutotuningConfig',
    as HashRef[AutotuningConfig()];

declare 'Scenario',
    as (Int | Str);

declare 'RepositoryConfig',
    as InstanceOf['Google::Cloud::Dataproc::V1::Shared::RepositoryConfig'];

coerce 'RepositoryConfig',
    from HashRef, via { 'Google::Cloud::Dataproc::V1::Shared::RepositoryConfig'->new($_) };

declare 'RepeatedRepositoryConfig',
    as ArrayRef[RepositoryConfig()];

coerce 'RepeatedRepositoryConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataproc::V1::Shared::RepositoryConfig'->new($_) } @$_ ] };

declare 'MapStringRepositoryConfig',
    as HashRef[RepositoryConfig()];

declare 'PyPiRepositoryConfig',
    as InstanceOf['Google::Cloud::Dataproc::V1::Shared::PyPiRepositoryConfig'];

coerce 'PyPiRepositoryConfig',
    from HashRef, via { 'Google::Cloud::Dataproc::V1::Shared::PyPiRepositoryConfig'->new($_) };

declare 'RepeatedPyPiRepositoryConfig',
    as ArrayRef[PyPiRepositoryConfig()];

coerce 'RepeatedPyPiRepositoryConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataproc::V1::Shared::PyPiRepositoryConfig'->new($_) } @$_ ] };

declare 'MapStringPyPiRepositoryConfig',
    as HashRef[PyPiRepositoryConfig()];

1;

__END__

=head1 NAME

Google::Cloud::Dataproc::V1::Shared::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
