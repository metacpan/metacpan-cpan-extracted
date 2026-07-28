package Google::Dataflow::V1beta3::Environment::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'JobType',
    as (Int | Str);

declare 'FlexResourceSchedulingGoal',
    as (Int | Str);

declare 'TeardownPolicy',
    as (Int | Str);

declare 'DefaultPackageSet',
    as (Int | Str);

declare 'AutoscalingAlgorithm',
    as (Int | Str);

declare 'WorkerIPAddressConfiguration',
    as (Int | Str);

declare 'ShuffleMode',
    as (Int | Str);

declare 'StreamingMode',
    as (Int | Str);

declare 'Environment',
    as InstanceOf['Google::Dataflow::V1beta3::Environment::Environment'];

coerce 'Environment',
    from HashRef, via { 'Google::Dataflow::V1beta3::Environment::Environment'->new($_) };

declare 'RepeatedEnvironment',
    as ArrayRef[Environment()];

coerce 'RepeatedEnvironment',
    from ArrayRef[HashRef], via { [ map { 'Google::Dataflow::V1beta3::Environment::Environment'->new($_) } @$_ ] };

declare 'MapStringEnvironment',
    as HashRef[Environment()];

declare 'Package',
    as InstanceOf['Google::Dataflow::V1beta3::Environment::Package'];

coerce 'Package',
    from HashRef, via { 'Google::Dataflow::V1beta3::Environment::Package'->new($_) };

declare 'RepeatedPackage',
    as ArrayRef[Package()];

coerce 'RepeatedPackage',
    from ArrayRef[HashRef], via { [ map { 'Google::Dataflow::V1beta3::Environment::Package'->new($_) } @$_ ] };

declare 'MapStringPackage',
    as HashRef[Package()];

declare 'Disk',
    as InstanceOf['Google::Dataflow::V1beta3::Environment::Disk'];

coerce 'Disk',
    from HashRef, via { 'Google::Dataflow::V1beta3::Environment::Disk'->new($_) };

declare 'RepeatedDisk',
    as ArrayRef[Disk()];

coerce 'RepeatedDisk',
    from ArrayRef[HashRef], via { [ map { 'Google::Dataflow::V1beta3::Environment::Disk'->new($_) } @$_ ] };

declare 'MapStringDisk',
    as HashRef[Disk()];

declare 'WorkerSettings',
    as InstanceOf['Google::Dataflow::V1beta3::Environment::WorkerSettings'];

coerce 'WorkerSettings',
    from HashRef, via { 'Google::Dataflow::V1beta3::Environment::WorkerSettings'->new($_) };

declare 'RepeatedWorkerSettings',
    as ArrayRef[WorkerSettings()];

coerce 'RepeatedWorkerSettings',
    from ArrayRef[HashRef], via { [ map { 'Google::Dataflow::V1beta3::Environment::WorkerSettings'->new($_) } @$_ ] };

declare 'MapStringWorkerSettings',
    as HashRef[WorkerSettings()];

declare 'TaskRunnerSettings',
    as InstanceOf['Google::Dataflow::V1beta3::Environment::TaskRunnerSettings'];

coerce 'TaskRunnerSettings',
    from HashRef, via { 'Google::Dataflow::V1beta3::Environment::TaskRunnerSettings'->new($_) };

declare 'RepeatedTaskRunnerSettings',
    as ArrayRef[TaskRunnerSettings()];

coerce 'RepeatedTaskRunnerSettings',
    from ArrayRef[HashRef], via { [ map { 'Google::Dataflow::V1beta3::Environment::TaskRunnerSettings'->new($_) } @$_ ] };

declare 'MapStringTaskRunnerSettings',
    as HashRef[TaskRunnerSettings()];

declare 'AutoscalingSettings',
    as InstanceOf['Google::Dataflow::V1beta3::Environment::AutoscalingSettings'];

coerce 'AutoscalingSettings',
    from HashRef, via { 'Google::Dataflow::V1beta3::Environment::AutoscalingSettings'->new($_) };

declare 'RepeatedAutoscalingSettings',
    as ArrayRef[AutoscalingSettings()];

coerce 'RepeatedAutoscalingSettings',
    from ArrayRef[HashRef], via { [ map { 'Google::Dataflow::V1beta3::Environment::AutoscalingSettings'->new($_) } @$_ ] };

declare 'MapStringAutoscalingSettings',
    as HashRef[AutoscalingSettings()];

declare 'SdkHarnessContainerImage',
    as InstanceOf['Google::Dataflow::V1beta3::Environment::SdkHarnessContainerImage'];

coerce 'SdkHarnessContainerImage',
    from HashRef, via { 'Google::Dataflow::V1beta3::Environment::SdkHarnessContainerImage'->new($_) };

declare 'RepeatedSdkHarnessContainerImage',
    as ArrayRef[SdkHarnessContainerImage()];

coerce 'RepeatedSdkHarnessContainerImage',
    from ArrayRef[HashRef], via { [ map { 'Google::Dataflow::V1beta3::Environment::SdkHarnessContainerImage'->new($_) } @$_ ] };

declare 'MapStringSdkHarnessContainerImage',
    as HashRef[SdkHarnessContainerImage()];

declare 'WorkerPool',
    as InstanceOf['Google::Dataflow::V1beta3::Environment::WorkerPool'];

coerce 'WorkerPool',
    from HashRef, via { 'Google::Dataflow::V1beta3::Environment::WorkerPool'->new($_) };

declare 'RepeatedWorkerPool',
    as ArrayRef[WorkerPool()];

coerce 'RepeatedWorkerPool',
    from ArrayRef[HashRef], via { [ map { 'Google::Dataflow::V1beta3::Environment::WorkerPool'->new($_) } @$_ ] };

declare 'MapStringWorkerPool',
    as HashRef[WorkerPool()];

declare 'MetadataEntry',
    as InstanceOf['Google::Dataflow::V1beta3::Environment::WorkerPool::MetadataEntry'];

coerce 'MetadataEntry',
    from HashRef, via { 'Google::Dataflow::V1beta3::Environment::WorkerPool::MetadataEntry'->new($_) };

declare 'RepeatedMetadataEntry',
    as ArrayRef[MetadataEntry()];

coerce 'RepeatedMetadataEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Dataflow::V1beta3::Environment::WorkerPool::MetadataEntry'->new($_) } @$_ ] };

declare 'MapStringMetadataEntry',
    as HashRef[MetadataEntry()];

declare 'DataSamplingConfig',
    as InstanceOf['Google::Dataflow::V1beta3::Environment::DataSamplingConfig'];

coerce 'DataSamplingConfig',
    from HashRef, via { 'Google::Dataflow::V1beta3::Environment::DataSamplingConfig'->new($_) };

declare 'RepeatedDataSamplingConfig',
    as ArrayRef[DataSamplingConfig()];

coerce 'RepeatedDataSamplingConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Dataflow::V1beta3::Environment::DataSamplingConfig'->new($_) } @$_ ] };

declare 'MapStringDataSamplingConfig',
    as HashRef[DataSamplingConfig()];

declare 'DataSamplingBehavior',
    as (Int | Str);

declare 'DebugOptions',
    as InstanceOf['Google::Dataflow::V1beta3::Environment::DebugOptions'];

coerce 'DebugOptions',
    from HashRef, via { 'Google::Dataflow::V1beta3::Environment::DebugOptions'->new($_) };

declare 'RepeatedDebugOptions',
    as ArrayRef[DebugOptions()];

coerce 'RepeatedDebugOptions',
    from ArrayRef[HashRef], via { [ map { 'Google::Dataflow::V1beta3::Environment::DebugOptions'->new($_) } @$_ ] };

declare 'MapStringDebugOptions',
    as HashRef[DebugOptions()];

1;

__END__

=head1 NAME

Google::Dataflow::V1beta3::Environment::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
