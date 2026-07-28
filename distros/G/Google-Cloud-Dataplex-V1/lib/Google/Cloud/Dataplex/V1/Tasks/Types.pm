package Google::Cloud::Dataplex::V1::Tasks::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Task',
    as InstanceOf['Google::Cloud::Dataplex::V1::Tasks::Task'];

coerce 'Task',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Tasks::Task'->new($_) };

declare 'RepeatedTask',
    as ArrayRef[Task()];

coerce 'RepeatedTask',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Tasks::Task'->new($_) } @$_ ] };

declare 'MapStringTask',
    as HashRef[Task()];

declare 'InfrastructureSpec',
    as InstanceOf['Google::Cloud::Dataplex::V1::Tasks::Task::InfrastructureSpec'];

coerce 'InfrastructureSpec',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Tasks::Task::InfrastructureSpec'->new($_) };

declare 'RepeatedInfrastructureSpec',
    as ArrayRef[InfrastructureSpec()];

coerce 'RepeatedInfrastructureSpec',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Tasks::Task::InfrastructureSpec'->new($_) } @$_ ] };

declare 'MapStringInfrastructureSpec',
    as HashRef[InfrastructureSpec()];

declare 'BatchComputeResources',
    as InstanceOf['Google::Cloud::Dataplex::V1::Tasks::Task::InfrastructureSpec::BatchComputeResources'];

coerce 'BatchComputeResources',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Tasks::Task::InfrastructureSpec::BatchComputeResources'->new($_) };

declare 'RepeatedBatchComputeResources',
    as ArrayRef[BatchComputeResources()];

coerce 'RepeatedBatchComputeResources',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Tasks::Task::InfrastructureSpec::BatchComputeResources'->new($_) } @$_ ] };

declare 'MapStringBatchComputeResources',
    as HashRef[BatchComputeResources()];

declare 'ContainerImageRuntime',
    as InstanceOf['Google::Cloud::Dataplex::V1::Tasks::Task::InfrastructureSpec::ContainerImageRuntime'];

coerce 'ContainerImageRuntime',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Tasks::Task::InfrastructureSpec::ContainerImageRuntime'->new($_) };

declare 'RepeatedContainerImageRuntime',
    as ArrayRef[ContainerImageRuntime()];

coerce 'RepeatedContainerImageRuntime',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Tasks::Task::InfrastructureSpec::ContainerImageRuntime'->new($_) } @$_ ] };

declare 'MapStringContainerImageRuntime',
    as HashRef[ContainerImageRuntime()];

declare 'PropertiesEntry',
    as InstanceOf['Google::Cloud::Dataplex::V1::Tasks::Task::InfrastructureSpec::ContainerImageRuntime::PropertiesEntry'];

coerce 'PropertiesEntry',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Tasks::Task::InfrastructureSpec::ContainerImageRuntime::PropertiesEntry'->new($_) };

declare 'RepeatedPropertiesEntry',
    as ArrayRef[PropertiesEntry()];

coerce 'RepeatedPropertiesEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Tasks::Task::InfrastructureSpec::ContainerImageRuntime::PropertiesEntry'->new($_) } @$_ ] };

declare 'MapStringPropertiesEntry',
    as HashRef[PropertiesEntry()];

declare 'VpcNetwork',
    as InstanceOf['Google::Cloud::Dataplex::V1::Tasks::Task::InfrastructureSpec::VpcNetwork'];

coerce 'VpcNetwork',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Tasks::Task::InfrastructureSpec::VpcNetwork'->new($_) };

declare 'RepeatedVpcNetwork',
    as ArrayRef[VpcNetwork()];

coerce 'RepeatedVpcNetwork',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Tasks::Task::InfrastructureSpec::VpcNetwork'->new($_) } @$_ ] };

declare 'MapStringVpcNetwork',
    as HashRef[VpcNetwork()];

declare 'TriggerSpec',
    as InstanceOf['Google::Cloud::Dataplex::V1::Tasks::Task::TriggerSpec'];

coerce 'TriggerSpec',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Tasks::Task::TriggerSpec'->new($_) };

declare 'RepeatedTriggerSpec',
    as ArrayRef[TriggerSpec()];

coerce 'RepeatedTriggerSpec',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Tasks::Task::TriggerSpec'->new($_) } @$_ ] };

declare 'MapStringTriggerSpec',
    as HashRef[TriggerSpec()];

declare 'Type',
    as (Int | Str);

declare 'ExecutionSpec',
    as InstanceOf['Google::Cloud::Dataplex::V1::Tasks::Task::ExecutionSpec'];

coerce 'ExecutionSpec',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Tasks::Task::ExecutionSpec'->new($_) };

declare 'RepeatedExecutionSpec',
    as ArrayRef[ExecutionSpec()];

coerce 'RepeatedExecutionSpec',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Tasks::Task::ExecutionSpec'->new($_) } @$_ ] };

declare 'MapStringExecutionSpec',
    as HashRef[ExecutionSpec()];

declare 'ArgsEntry',
    as InstanceOf['Google::Cloud::Dataplex::V1::Tasks::Task::ExecutionSpec::ArgsEntry'];

coerce 'ArgsEntry',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Tasks::Task::ExecutionSpec::ArgsEntry'->new($_) };

declare 'RepeatedArgsEntry',
    as ArrayRef[ArgsEntry()];

coerce 'RepeatedArgsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Tasks::Task::ExecutionSpec::ArgsEntry'->new($_) } @$_ ] };

declare 'MapStringArgsEntry',
    as HashRef[ArgsEntry()];

declare 'SparkTaskConfig',
    as InstanceOf['Google::Cloud::Dataplex::V1::Tasks::Task::SparkTaskConfig'];

coerce 'SparkTaskConfig',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Tasks::Task::SparkTaskConfig'->new($_) };

declare 'RepeatedSparkTaskConfig',
    as ArrayRef[SparkTaskConfig()];

coerce 'RepeatedSparkTaskConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Tasks::Task::SparkTaskConfig'->new($_) } @$_ ] };

declare 'MapStringSparkTaskConfig',
    as HashRef[SparkTaskConfig()];

declare 'NotebookTaskConfig',
    as InstanceOf['Google::Cloud::Dataplex::V1::Tasks::Task::NotebookTaskConfig'];

coerce 'NotebookTaskConfig',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Tasks::Task::NotebookTaskConfig'->new($_) };

declare 'RepeatedNotebookTaskConfig',
    as ArrayRef[NotebookTaskConfig()];

coerce 'RepeatedNotebookTaskConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Tasks::Task::NotebookTaskConfig'->new($_) } @$_ ] };

declare 'MapStringNotebookTaskConfig',
    as HashRef[NotebookTaskConfig()];

declare 'ExecutionStatus',
    as InstanceOf['Google::Cloud::Dataplex::V1::Tasks::Task::ExecutionStatus'];

coerce 'ExecutionStatus',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Tasks::Task::ExecutionStatus'->new($_) };

declare 'RepeatedExecutionStatus',
    as ArrayRef[ExecutionStatus()];

coerce 'RepeatedExecutionStatus',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Tasks::Task::ExecutionStatus'->new($_) } @$_ ] };

declare 'MapStringExecutionStatus',
    as HashRef[ExecutionStatus()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Dataplex::V1::Tasks::Task::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Tasks::Task::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Tasks::Task::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'Job',
    as InstanceOf['Google::Cloud::Dataplex::V1::Tasks::Job'];

coerce 'Job',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Tasks::Job'->new($_) };

declare 'RepeatedJob',
    as ArrayRef[Job()];

coerce 'RepeatedJob',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Tasks::Job'->new($_) } @$_ ] };

declare 'MapStringJob',
    as HashRef[Job()];

declare 'Service',
    as (Int | Str);

declare 'State',
    as (Int | Str);

declare 'Trigger',
    as (Int | Str);

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Dataplex::V1::Tasks::Job::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Tasks::Job::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Tasks::Job::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

1;

__END__

=head1 NAME

Google::Cloud::Dataplex::V1::Tasks::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
