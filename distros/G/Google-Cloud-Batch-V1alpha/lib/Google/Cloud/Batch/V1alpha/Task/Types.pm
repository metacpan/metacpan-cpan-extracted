package Google::Cloud::Batch::V1alpha::Task::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'ComputeResource',
    as InstanceOf['Google::Cloud::Batch::V1alpha::Task::ComputeResource'];

coerce 'ComputeResource',
    from HashRef, via { 'Google::Cloud::Batch::V1alpha::Task::ComputeResource'->new($_) };

declare 'RepeatedComputeResource',
    as ArrayRef[ComputeResource()];

coerce 'RepeatedComputeResource',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Batch::V1alpha::Task::ComputeResource'->new($_) } @$_ ] };

declare 'MapStringComputeResource',
    as HashRef[ComputeResource()];

declare 'StatusEvent',
    as InstanceOf['Google::Cloud::Batch::V1alpha::Task::StatusEvent'];

coerce 'StatusEvent',
    from HashRef, via { 'Google::Cloud::Batch::V1alpha::Task::StatusEvent'->new($_) };

declare 'RepeatedStatusEvent',
    as ArrayRef[StatusEvent()];

coerce 'RepeatedStatusEvent',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Batch::V1alpha::Task::StatusEvent'->new($_) } @$_ ] };

declare 'MapStringStatusEvent',
    as HashRef[StatusEvent()];

declare 'TaskExecution',
    as InstanceOf['Google::Cloud::Batch::V1alpha::Task::TaskExecution'];

coerce 'TaskExecution',
    from HashRef, via { 'Google::Cloud::Batch::V1alpha::Task::TaskExecution'->new($_) };

declare 'RepeatedTaskExecution',
    as ArrayRef[TaskExecution()];

coerce 'RepeatedTaskExecution',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Batch::V1alpha::Task::TaskExecution'->new($_) } @$_ ] };

declare 'MapStringTaskExecution',
    as HashRef[TaskExecution()];

declare 'TaskStatus',
    as InstanceOf['Google::Cloud::Batch::V1alpha::Task::TaskStatus'];

coerce 'TaskStatus',
    from HashRef, via { 'Google::Cloud::Batch::V1alpha::Task::TaskStatus'->new($_) };

declare 'RepeatedTaskStatus',
    as ArrayRef[TaskStatus()];

coerce 'RepeatedTaskStatus',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Batch::V1alpha::Task::TaskStatus'->new($_) } @$_ ] };

declare 'MapStringTaskStatus',
    as HashRef[TaskStatus()];

declare 'State',
    as (Int | Str);

declare 'TaskResourceUsage',
    as InstanceOf['Google::Cloud::Batch::V1alpha::Task::TaskResourceUsage'];

coerce 'TaskResourceUsage',
    from HashRef, via { 'Google::Cloud::Batch::V1alpha::Task::TaskResourceUsage'->new($_) };

declare 'RepeatedTaskResourceUsage',
    as ArrayRef[TaskResourceUsage()];

coerce 'RepeatedTaskResourceUsage',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Batch::V1alpha::Task::TaskResourceUsage'->new($_) } @$_ ] };

declare 'MapStringTaskResourceUsage',
    as HashRef[TaskResourceUsage()];

declare 'Runnable',
    as InstanceOf['Google::Cloud::Batch::V1alpha::Task::Runnable'];

coerce 'Runnable',
    from HashRef, via { 'Google::Cloud::Batch::V1alpha::Task::Runnable'->new($_) };

declare 'RepeatedRunnable',
    as ArrayRef[Runnable()];

coerce 'RepeatedRunnable',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Batch::V1alpha::Task::Runnable'->new($_) } @$_ ] };

declare 'MapStringRunnable',
    as HashRef[Runnable()];

declare 'Container',
    as InstanceOf['Google::Cloud::Batch::V1alpha::Task::Runnable::Container'];

coerce 'Container',
    from HashRef, via { 'Google::Cloud::Batch::V1alpha::Task::Runnable::Container'->new($_) };

declare 'RepeatedContainer',
    as ArrayRef[Container()];

coerce 'RepeatedContainer',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Batch::V1alpha::Task::Runnable::Container'->new($_) } @$_ ] };

declare 'MapStringContainer',
    as HashRef[Container()];

declare 'Script',
    as InstanceOf['Google::Cloud::Batch::V1alpha::Task::Runnable::Script'];

coerce 'Script',
    from HashRef, via { 'Google::Cloud::Batch::V1alpha::Task::Runnable::Script'->new($_) };

declare 'RepeatedScript',
    as ArrayRef[Script()];

coerce 'RepeatedScript',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Batch::V1alpha::Task::Runnable::Script'->new($_) } @$_ ] };

declare 'MapStringScript',
    as HashRef[Script()];

declare 'Barrier',
    as InstanceOf['Google::Cloud::Batch::V1alpha::Task::Runnable::Barrier'];

coerce 'Barrier',
    from HashRef, via { 'Google::Cloud::Batch::V1alpha::Task::Runnable::Barrier'->new($_) };

declare 'RepeatedBarrier',
    as ArrayRef[Barrier()];

coerce 'RepeatedBarrier',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Batch::V1alpha::Task::Runnable::Barrier'->new($_) } @$_ ] };

declare 'MapStringBarrier',
    as HashRef[Barrier()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Batch::V1alpha::Task::Runnable::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Batch::V1alpha::Task::Runnable::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Batch::V1alpha::Task::Runnable::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'TaskSpec',
    as InstanceOf['Google::Cloud::Batch::V1alpha::Task::TaskSpec'];

coerce 'TaskSpec',
    from HashRef, via { 'Google::Cloud::Batch::V1alpha::Task::TaskSpec'->new($_) };

declare 'RepeatedTaskSpec',
    as ArrayRef[TaskSpec()];

coerce 'RepeatedTaskSpec',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Batch::V1alpha::Task::TaskSpec'->new($_) } @$_ ] };

declare 'MapStringTaskSpec',
    as HashRef[TaskSpec()];

declare 'EnvironmentsEntry',
    as InstanceOf['Google::Cloud::Batch::V1alpha::Task::TaskSpec::EnvironmentsEntry'];

coerce 'EnvironmentsEntry',
    from HashRef, via { 'Google::Cloud::Batch::V1alpha::Task::TaskSpec::EnvironmentsEntry'->new($_) };

declare 'RepeatedEnvironmentsEntry',
    as ArrayRef[EnvironmentsEntry()];

coerce 'RepeatedEnvironmentsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Batch::V1alpha::Task::TaskSpec::EnvironmentsEntry'->new($_) } @$_ ] };

declare 'MapStringEnvironmentsEntry',
    as HashRef[EnvironmentsEntry()];

declare 'LifecyclePolicy',
    as InstanceOf['Google::Cloud::Batch::V1alpha::Task::LifecyclePolicy'];

coerce 'LifecyclePolicy',
    from HashRef, via { 'Google::Cloud::Batch::V1alpha::Task::LifecyclePolicy'->new($_) };

declare 'RepeatedLifecyclePolicy',
    as ArrayRef[LifecyclePolicy()];

coerce 'RepeatedLifecyclePolicy',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Batch::V1alpha::Task::LifecyclePolicy'->new($_) } @$_ ] };

declare 'MapStringLifecyclePolicy',
    as HashRef[LifecyclePolicy()];

declare 'Action',
    as (Int | Str);

declare 'ActionCondition',
    as InstanceOf['Google::Cloud::Batch::V1alpha::Task::LifecyclePolicy::ActionCondition'];

coerce 'ActionCondition',
    from HashRef, via { 'Google::Cloud::Batch::V1alpha::Task::LifecyclePolicy::ActionCondition'->new($_) };

declare 'RepeatedActionCondition',
    as ArrayRef[ActionCondition()];

coerce 'RepeatedActionCondition',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Batch::V1alpha::Task::LifecyclePolicy::ActionCondition'->new($_) } @$_ ] };

declare 'MapStringActionCondition',
    as HashRef[ActionCondition()];

declare 'Task',
    as InstanceOf['Google::Cloud::Batch::V1alpha::Task::Task'];

coerce 'Task',
    from HashRef, via { 'Google::Cloud::Batch::V1alpha::Task::Task'->new($_) };

declare 'RepeatedTask',
    as ArrayRef[Task()];

coerce 'RepeatedTask',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Batch::V1alpha::Task::Task'->new($_) } @$_ ] };

declare 'MapStringTask',
    as HashRef[Task()];

declare 'Environment',
    as InstanceOf['Google::Cloud::Batch::V1alpha::Task::Environment'];

coerce 'Environment',
    from HashRef, via { 'Google::Cloud::Batch::V1alpha::Task::Environment'->new($_) };

declare 'RepeatedEnvironment',
    as ArrayRef[Environment()];

coerce 'RepeatedEnvironment',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Batch::V1alpha::Task::Environment'->new($_) } @$_ ] };

declare 'MapStringEnvironment',
    as HashRef[Environment()];

declare 'KMSEnvMap',
    as InstanceOf['Google::Cloud::Batch::V1alpha::Task::Environment::KMSEnvMap'];

coerce 'KMSEnvMap',
    from HashRef, via { 'Google::Cloud::Batch::V1alpha::Task::Environment::KMSEnvMap'->new($_) };

declare 'RepeatedKMSEnvMap',
    as ArrayRef[KMSEnvMap()];

coerce 'RepeatedKMSEnvMap',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Batch::V1alpha::Task::Environment::KMSEnvMap'->new($_) } @$_ ] };

declare 'MapStringKMSEnvMap',
    as HashRef[KMSEnvMap()];

declare 'VariablesEntry',
    as InstanceOf['Google::Cloud::Batch::V1alpha::Task::Environment::VariablesEntry'];

coerce 'VariablesEntry',
    from HashRef, via { 'Google::Cloud::Batch::V1alpha::Task::Environment::VariablesEntry'->new($_) };

declare 'RepeatedVariablesEntry',
    as ArrayRef[VariablesEntry()];

coerce 'RepeatedVariablesEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Batch::V1alpha::Task::Environment::VariablesEntry'->new($_) } @$_ ] };

declare 'MapStringVariablesEntry',
    as HashRef[VariablesEntry()];

declare 'SecretVariablesEntry',
    as InstanceOf['Google::Cloud::Batch::V1alpha::Task::Environment::SecretVariablesEntry'];

coerce 'SecretVariablesEntry',
    from HashRef, via { 'Google::Cloud::Batch::V1alpha::Task::Environment::SecretVariablesEntry'->new($_) };

declare 'RepeatedSecretVariablesEntry',
    as ArrayRef[SecretVariablesEntry()];

coerce 'RepeatedSecretVariablesEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Batch::V1alpha::Task::Environment::SecretVariablesEntry'->new($_) } @$_ ] };

declare 'MapStringSecretVariablesEntry',
    as HashRef[SecretVariablesEntry()];

1;

__END__

=head1 NAME

Google::Cloud::Batch::V1alpha::Task::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
