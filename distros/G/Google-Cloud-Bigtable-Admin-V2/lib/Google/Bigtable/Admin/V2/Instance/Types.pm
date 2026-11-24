package Google::Bigtable::Admin::V2::Instance::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Instance',
    as InstanceOf['Google::Bigtable::Admin::V2::Instance::Instance'];

coerce 'Instance',
    from HashRef, via { 'Google::Bigtable::Admin::V2::Instance::Instance'->new($_) };

declare 'RepeatedInstance',
    as ArrayRef[Instance()];

coerce 'RepeatedInstance',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::Admin::V2::Instance::Instance'->new($_) } @$_ ] };

declare 'MapStringInstance',
    as HashRef[Instance()];

declare 'State',
    as (Int | Str);

declare 'Type',
    as (Int | Str);

declare 'Edition',
    as (Int | Str);

declare 'LabelsEntry',
    as InstanceOf['Google::Bigtable::Admin::V2::Instance::Instance::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Bigtable::Admin::V2::Instance::Instance::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::Admin::V2::Instance::Instance::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'TagsEntry',
    as InstanceOf['Google::Bigtable::Admin::V2::Instance::Instance::TagsEntry'];

coerce 'TagsEntry',
    from HashRef, via { 'Google::Bigtable::Admin::V2::Instance::Instance::TagsEntry'->new($_) };

declare 'RepeatedTagsEntry',
    as ArrayRef[TagsEntry()];

coerce 'RepeatedTagsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::Admin::V2::Instance::Instance::TagsEntry'->new($_) } @$_ ] };

declare 'MapStringTagsEntry',
    as HashRef[TagsEntry()];

declare 'AutoscalingTargets',
    as InstanceOf['Google::Bigtable::Admin::V2::Instance::AutoscalingTargets'];

coerce 'AutoscalingTargets',
    from HashRef, via { 'Google::Bigtable::Admin::V2::Instance::AutoscalingTargets'->new($_) };

declare 'RepeatedAutoscalingTargets',
    as ArrayRef[AutoscalingTargets()];

coerce 'RepeatedAutoscalingTargets',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::Admin::V2::Instance::AutoscalingTargets'->new($_) } @$_ ] };

declare 'MapStringAutoscalingTargets',
    as HashRef[AutoscalingTargets()];

declare 'AutoscalingLimits',
    as InstanceOf['Google::Bigtable::Admin::V2::Instance::AutoscalingLimits'];

coerce 'AutoscalingLimits',
    from HashRef, via { 'Google::Bigtable::Admin::V2::Instance::AutoscalingLimits'->new($_) };

declare 'RepeatedAutoscalingLimits',
    as ArrayRef[AutoscalingLimits()];

coerce 'RepeatedAutoscalingLimits',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::Admin::V2::Instance::AutoscalingLimits'->new($_) } @$_ ] };

declare 'MapStringAutoscalingLimits',
    as HashRef[AutoscalingLimits()];

declare 'Cluster',
    as InstanceOf['Google::Bigtable::Admin::V2::Instance::Cluster'];

coerce 'Cluster',
    from HashRef, via { 'Google::Bigtable::Admin::V2::Instance::Cluster'->new($_) };

declare 'RepeatedCluster',
    as ArrayRef[Cluster()];

coerce 'RepeatedCluster',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::Admin::V2::Instance::Cluster'->new($_) } @$_ ] };

declare 'MapStringCluster',
    as HashRef[Cluster()];

declare 'State',
    as (Int | Str);

declare 'NodeScalingFactor',
    as (Int | Str);

declare 'ClusterAutoscalingConfig',
    as InstanceOf['Google::Bigtable::Admin::V2::Instance::Cluster::ClusterAutoscalingConfig'];

coerce 'ClusterAutoscalingConfig',
    from HashRef, via { 'Google::Bigtable::Admin::V2::Instance::Cluster::ClusterAutoscalingConfig'->new($_) };

declare 'RepeatedClusterAutoscalingConfig',
    as ArrayRef[ClusterAutoscalingConfig()];

coerce 'RepeatedClusterAutoscalingConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::Admin::V2::Instance::Cluster::ClusterAutoscalingConfig'->new($_) } @$_ ] };

declare 'MapStringClusterAutoscalingConfig',
    as HashRef[ClusterAutoscalingConfig()];

declare 'ClusterConfig',
    as InstanceOf['Google::Bigtable::Admin::V2::Instance::Cluster::ClusterConfig'];

coerce 'ClusterConfig',
    from HashRef, via { 'Google::Bigtable::Admin::V2::Instance::Cluster::ClusterConfig'->new($_) };

declare 'RepeatedClusterConfig',
    as ArrayRef[ClusterConfig()];

coerce 'RepeatedClusterConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::Admin::V2::Instance::Cluster::ClusterConfig'->new($_) } @$_ ] };

declare 'MapStringClusterConfig',
    as HashRef[ClusterConfig()];

declare 'EncryptionConfig',
    as InstanceOf['Google::Bigtable::Admin::V2::Instance::Cluster::EncryptionConfig'];

coerce 'EncryptionConfig',
    from HashRef, via { 'Google::Bigtable::Admin::V2::Instance::Cluster::EncryptionConfig'->new($_) };

declare 'RepeatedEncryptionConfig',
    as ArrayRef[EncryptionConfig()];

coerce 'RepeatedEncryptionConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::Admin::V2::Instance::Cluster::EncryptionConfig'->new($_) } @$_ ] };

declare 'MapStringEncryptionConfig',
    as HashRef[EncryptionConfig()];

declare 'MemoryLayer',
    as InstanceOf['Google::Bigtable::Admin::V2::Instance::MemoryLayer'];

coerce 'MemoryLayer',
    from HashRef, via { 'Google::Bigtable::Admin::V2::Instance::MemoryLayer'->new($_) };

declare 'RepeatedMemoryLayer',
    as ArrayRef[MemoryLayer()];

coerce 'RepeatedMemoryLayer',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::Admin::V2::Instance::MemoryLayer'->new($_) } @$_ ] };

declare 'MapStringMemoryLayer',
    as HashRef[MemoryLayer()];

declare 'State',
    as (Int | Str);

declare 'MemoryConfig',
    as InstanceOf['Google::Bigtable::Admin::V2::Instance::MemoryLayer::MemoryConfig'];

coerce 'MemoryConfig',
    from HashRef, via { 'Google::Bigtable::Admin::V2::Instance::MemoryLayer::MemoryConfig'->new($_) };

declare 'RepeatedMemoryConfig',
    as ArrayRef[MemoryConfig()];

coerce 'RepeatedMemoryConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::Admin::V2::Instance::MemoryLayer::MemoryConfig'->new($_) } @$_ ] };

declare 'MapStringMemoryConfig',
    as HashRef[MemoryConfig()];

declare 'AppProfile',
    as InstanceOf['Google::Bigtable::Admin::V2::Instance::AppProfile'];

coerce 'AppProfile',
    from HashRef, via { 'Google::Bigtable::Admin::V2::Instance::AppProfile'->new($_) };

declare 'RepeatedAppProfile',
    as ArrayRef[AppProfile()];

coerce 'RepeatedAppProfile',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::Admin::V2::Instance::AppProfile'->new($_) } @$_ ] };

declare 'MapStringAppProfile',
    as HashRef[AppProfile()];

declare 'Priority',
    as (Int | Str);

declare 'MultiClusterRoutingUseAny',
    as InstanceOf['Google::Bigtable::Admin::V2::Instance::AppProfile::MultiClusterRoutingUseAny'];

coerce 'MultiClusterRoutingUseAny',
    from HashRef, via { 'Google::Bigtable::Admin::V2::Instance::AppProfile::MultiClusterRoutingUseAny'->new($_) };

declare 'RepeatedMultiClusterRoutingUseAny',
    as ArrayRef[MultiClusterRoutingUseAny()];

coerce 'RepeatedMultiClusterRoutingUseAny',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::Admin::V2::Instance::AppProfile::MultiClusterRoutingUseAny'->new($_) } @$_ ] };

declare 'MapStringMultiClusterRoutingUseAny',
    as HashRef[MultiClusterRoutingUseAny()];

declare 'RowAffinity',
    as InstanceOf['Google::Bigtable::Admin::V2::Instance::AppProfile::MultiClusterRoutingUseAny::RowAffinity'];

coerce 'RowAffinity',
    from HashRef, via { 'Google::Bigtable::Admin::V2::Instance::AppProfile::MultiClusterRoutingUseAny::RowAffinity'->new($_) };

declare 'RepeatedRowAffinity',
    as ArrayRef[RowAffinity()];

coerce 'RepeatedRowAffinity',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::Admin::V2::Instance::AppProfile::MultiClusterRoutingUseAny::RowAffinity'->new($_) } @$_ ] };

declare 'MapStringRowAffinity',
    as HashRef[RowAffinity()];

declare 'SingleClusterRouting',
    as InstanceOf['Google::Bigtable::Admin::V2::Instance::AppProfile::SingleClusterRouting'];

coerce 'SingleClusterRouting',
    from HashRef, via { 'Google::Bigtable::Admin::V2::Instance::AppProfile::SingleClusterRouting'->new($_) };

declare 'RepeatedSingleClusterRouting',
    as ArrayRef[SingleClusterRouting()];

coerce 'RepeatedSingleClusterRouting',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::Admin::V2::Instance::AppProfile::SingleClusterRouting'->new($_) } @$_ ] };

declare 'MapStringSingleClusterRouting',
    as HashRef[SingleClusterRouting()];

declare 'StandardIsolation',
    as InstanceOf['Google::Bigtable::Admin::V2::Instance::AppProfile::StandardIsolation'];

coerce 'StandardIsolation',
    from HashRef, via { 'Google::Bigtable::Admin::V2::Instance::AppProfile::StandardIsolation'->new($_) };

declare 'RepeatedStandardIsolation',
    as ArrayRef[StandardIsolation()];

coerce 'RepeatedStandardIsolation',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::Admin::V2::Instance::AppProfile::StandardIsolation'->new($_) } @$_ ] };

declare 'MapStringStandardIsolation',
    as HashRef[StandardIsolation()];

declare 'MemoryConfig',
    as InstanceOf['Google::Bigtable::Admin::V2::Instance::AppProfile::StandardIsolation::MemoryConfig'];

coerce 'MemoryConfig',
    from HashRef, via { 'Google::Bigtable::Admin::V2::Instance::AppProfile::StandardIsolation::MemoryConfig'->new($_) };

declare 'RepeatedMemoryConfig',
    as ArrayRef[MemoryConfig()];

coerce 'RepeatedMemoryConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::Admin::V2::Instance::AppProfile::StandardIsolation::MemoryConfig'->new($_) } @$_ ] };

declare 'MapStringMemoryConfig',
    as HashRef[MemoryConfig()];

declare 'DataBoostIsolationReadOnly',
    as InstanceOf['Google::Bigtable::Admin::V2::Instance::AppProfile::DataBoostIsolationReadOnly'];

coerce 'DataBoostIsolationReadOnly',
    from HashRef, via { 'Google::Bigtable::Admin::V2::Instance::AppProfile::DataBoostIsolationReadOnly'->new($_) };

declare 'RepeatedDataBoostIsolationReadOnly',
    as ArrayRef[DataBoostIsolationReadOnly()];

coerce 'RepeatedDataBoostIsolationReadOnly',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::Admin::V2::Instance::AppProfile::DataBoostIsolationReadOnly'->new($_) } @$_ ] };

declare 'MapStringDataBoostIsolationReadOnly',
    as HashRef[DataBoostIsolationReadOnly()];

declare 'ComputeBillingOwner',
    as (Int | Str);

declare 'HotTablet',
    as InstanceOf['Google::Bigtable::Admin::V2::Instance::HotTablet'];

coerce 'HotTablet',
    from HashRef, via { 'Google::Bigtable::Admin::V2::Instance::HotTablet'->new($_) };

declare 'RepeatedHotTablet',
    as ArrayRef[HotTablet()];

coerce 'RepeatedHotTablet',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::Admin::V2::Instance::HotTablet'->new($_) } @$_ ] };

declare 'MapStringHotTablet',
    as HashRef[HotTablet()];

declare 'LogicalView',
    as InstanceOf['Google::Bigtable::Admin::V2::Instance::LogicalView'];

coerce 'LogicalView',
    from HashRef, via { 'Google::Bigtable::Admin::V2::Instance::LogicalView'->new($_) };

declare 'RepeatedLogicalView',
    as ArrayRef[LogicalView()];

coerce 'RepeatedLogicalView',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::Admin::V2::Instance::LogicalView'->new($_) } @$_ ] };

declare 'MapStringLogicalView',
    as HashRef[LogicalView()];

declare 'MaterializedView',
    as InstanceOf['Google::Bigtable::Admin::V2::Instance::MaterializedView'];

coerce 'MaterializedView',
    from HashRef, via { 'Google::Bigtable::Admin::V2::Instance::MaterializedView'->new($_) };

declare 'RepeatedMaterializedView',
    as ArrayRef[MaterializedView()];

coerce 'RepeatedMaterializedView',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::Admin::V2::Instance::MaterializedView'->new($_) } @$_ ] };

declare 'MapStringMaterializedView',
    as HashRef[MaterializedView()];

1;

__END__

=head1 NAME

Google::Bigtable::Admin::V2::Instance::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
