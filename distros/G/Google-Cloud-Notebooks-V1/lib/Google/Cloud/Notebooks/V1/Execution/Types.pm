package Google::Cloud::Notebooks::V1::Execution::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'ExecutionTemplate',
    as InstanceOf['Google::Cloud::Notebooks::V1::Execution::ExecutionTemplate'];

coerce 'ExecutionTemplate',
    from HashRef, via { 'Google::Cloud::Notebooks::V1::Execution::ExecutionTemplate'->new($_) };

declare 'RepeatedExecutionTemplate',
    as ArrayRef[ExecutionTemplate()];

coerce 'RepeatedExecutionTemplate',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Notebooks::V1::Execution::ExecutionTemplate'->new($_) } @$_ ] };

declare 'MapStringExecutionTemplate',
    as HashRef[ExecutionTemplate()];

declare 'ScaleTier',
    as (Int | Str);

declare 'SchedulerAcceleratorType',
    as (Int | Str);

declare 'JobType',
    as (Int | Str);

declare 'SchedulerAcceleratorConfig',
    as InstanceOf['Google::Cloud::Notebooks::V1::Execution::ExecutionTemplate::SchedulerAcceleratorConfig'];

coerce 'SchedulerAcceleratorConfig',
    from HashRef, via { 'Google::Cloud::Notebooks::V1::Execution::ExecutionTemplate::SchedulerAcceleratorConfig'->new($_) };

declare 'RepeatedSchedulerAcceleratorConfig',
    as ArrayRef[SchedulerAcceleratorConfig()];

coerce 'RepeatedSchedulerAcceleratorConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Notebooks::V1::Execution::ExecutionTemplate::SchedulerAcceleratorConfig'->new($_) } @$_ ] };

declare 'MapStringSchedulerAcceleratorConfig',
    as HashRef[SchedulerAcceleratorConfig()];

declare 'DataprocParameters',
    as InstanceOf['Google::Cloud::Notebooks::V1::Execution::ExecutionTemplate::DataprocParameters'];

coerce 'DataprocParameters',
    from HashRef, via { 'Google::Cloud::Notebooks::V1::Execution::ExecutionTemplate::DataprocParameters'->new($_) };

declare 'RepeatedDataprocParameters',
    as ArrayRef[DataprocParameters()];

coerce 'RepeatedDataprocParameters',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Notebooks::V1::Execution::ExecutionTemplate::DataprocParameters'->new($_) } @$_ ] };

declare 'MapStringDataprocParameters',
    as HashRef[DataprocParameters()];

declare 'VertexAIParameters',
    as InstanceOf['Google::Cloud::Notebooks::V1::Execution::ExecutionTemplate::VertexAIParameters'];

coerce 'VertexAIParameters',
    from HashRef, via { 'Google::Cloud::Notebooks::V1::Execution::ExecutionTemplate::VertexAIParameters'->new($_) };

declare 'RepeatedVertexAIParameters',
    as ArrayRef[VertexAIParameters()];

coerce 'RepeatedVertexAIParameters',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Notebooks::V1::Execution::ExecutionTemplate::VertexAIParameters'->new($_) } @$_ ] };

declare 'MapStringVertexAIParameters',
    as HashRef[VertexAIParameters()];

declare 'EnvEntry',
    as InstanceOf['Google::Cloud::Notebooks::V1::Execution::ExecutionTemplate::VertexAIParameters::EnvEntry'];

coerce 'EnvEntry',
    from HashRef, via { 'Google::Cloud::Notebooks::V1::Execution::ExecutionTemplate::VertexAIParameters::EnvEntry'->new($_) };

declare 'RepeatedEnvEntry',
    as ArrayRef[EnvEntry()];

coerce 'RepeatedEnvEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Notebooks::V1::Execution::ExecutionTemplate::VertexAIParameters::EnvEntry'->new($_) } @$_ ] };

declare 'MapStringEnvEntry',
    as HashRef[EnvEntry()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Notebooks::V1::Execution::ExecutionTemplate::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Notebooks::V1::Execution::ExecutionTemplate::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Notebooks::V1::Execution::ExecutionTemplate::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'Execution',
    as InstanceOf['Google::Cloud::Notebooks::V1::Execution::Execution'];

coerce 'Execution',
    from HashRef, via { 'Google::Cloud::Notebooks::V1::Execution::Execution'->new($_) };

declare 'RepeatedExecution',
    as ArrayRef[Execution()];

coerce 'RepeatedExecution',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Notebooks::V1::Execution::Execution'->new($_) } @$_ ] };

declare 'MapStringExecution',
    as HashRef[Execution()];

declare 'State',
    as (Int | Str);

1;

__END__

=head1 NAME

Google::Cloud::Notebooks::V1::Execution::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
