package Google::Cloud::Osconfig::Agentendpoint::V1beta::Tasks::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'TaskDirective',
    as (Int | Str);

declare 'TaskType',
    as (Int | Str);

declare 'Task',
    as InstanceOf['Google::Cloud::Osconfig::Agentendpoint::V1beta::Tasks::Task'];

coerce 'Task',
    from HashRef, via { 'Google::Cloud::Osconfig::Agentendpoint::V1beta::Tasks::Task'->new($_) };

declare 'RepeatedTask',
    as ArrayRef[Task()];

coerce 'RepeatedTask',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Osconfig::Agentendpoint::V1beta::Tasks::Task'->new($_) } @$_ ] };

declare 'MapStringTask',
    as HashRef[Task()];

declare 'ServiceLabelsEntry',
    as InstanceOf['Google::Cloud::Osconfig::Agentendpoint::V1beta::Tasks::Task::ServiceLabelsEntry'];

coerce 'ServiceLabelsEntry',
    from HashRef, via { 'Google::Cloud::Osconfig::Agentendpoint::V1beta::Tasks::Task::ServiceLabelsEntry'->new($_) };

declare 'RepeatedServiceLabelsEntry',
    as ArrayRef[ServiceLabelsEntry()];

coerce 'RepeatedServiceLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Osconfig::Agentendpoint::V1beta::Tasks::Task::ServiceLabelsEntry'->new($_) } @$_ ] };

declare 'MapStringServiceLabelsEntry',
    as HashRef[ServiceLabelsEntry()];

declare 'ApplyPatchesTask',
    as InstanceOf['Google::Cloud::Osconfig::Agentendpoint::V1beta::Tasks::ApplyPatchesTask'];

coerce 'ApplyPatchesTask',
    from HashRef, via { 'Google::Cloud::Osconfig::Agentendpoint::V1beta::Tasks::ApplyPatchesTask'->new($_) };

declare 'RepeatedApplyPatchesTask',
    as ArrayRef[ApplyPatchesTask()];

coerce 'RepeatedApplyPatchesTask',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Osconfig::Agentendpoint::V1beta::Tasks::ApplyPatchesTask'->new($_) } @$_ ] };

declare 'MapStringApplyPatchesTask',
    as HashRef[ApplyPatchesTask()];

declare 'ApplyPatchesTaskProgress',
    as InstanceOf['Google::Cloud::Osconfig::Agentendpoint::V1beta::Tasks::ApplyPatchesTaskProgress'];

coerce 'ApplyPatchesTaskProgress',
    from HashRef, via { 'Google::Cloud::Osconfig::Agentendpoint::V1beta::Tasks::ApplyPatchesTaskProgress'->new($_) };

declare 'RepeatedApplyPatchesTaskProgress',
    as ArrayRef[ApplyPatchesTaskProgress()];

coerce 'RepeatedApplyPatchesTaskProgress',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Osconfig::Agentendpoint::V1beta::Tasks::ApplyPatchesTaskProgress'->new($_) } @$_ ] };

declare 'MapStringApplyPatchesTaskProgress',
    as HashRef[ApplyPatchesTaskProgress()];

declare 'State',
    as (Int | Str);

declare 'ApplyPatchesTaskOutput',
    as InstanceOf['Google::Cloud::Osconfig::Agentendpoint::V1beta::Tasks::ApplyPatchesTaskOutput'];

coerce 'ApplyPatchesTaskOutput',
    from HashRef, via { 'Google::Cloud::Osconfig::Agentendpoint::V1beta::Tasks::ApplyPatchesTaskOutput'->new($_) };

declare 'RepeatedApplyPatchesTaskOutput',
    as ArrayRef[ApplyPatchesTaskOutput()];

coerce 'RepeatedApplyPatchesTaskOutput',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Osconfig::Agentendpoint::V1beta::Tasks::ApplyPatchesTaskOutput'->new($_) } @$_ ] };

declare 'MapStringApplyPatchesTaskOutput',
    as HashRef[ApplyPatchesTaskOutput()];

declare 'State',
    as (Int | Str);

declare 'ExecStepTask',
    as InstanceOf['Google::Cloud::Osconfig::Agentendpoint::V1beta::Tasks::ExecStepTask'];

coerce 'ExecStepTask',
    from HashRef, via { 'Google::Cloud::Osconfig::Agentendpoint::V1beta::Tasks::ExecStepTask'->new($_) };

declare 'RepeatedExecStepTask',
    as ArrayRef[ExecStepTask()];

coerce 'RepeatedExecStepTask',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Osconfig::Agentendpoint::V1beta::Tasks::ExecStepTask'->new($_) } @$_ ] };

declare 'MapStringExecStepTask',
    as HashRef[ExecStepTask()];

declare 'ExecStepTaskProgress',
    as InstanceOf['Google::Cloud::Osconfig::Agentendpoint::V1beta::Tasks::ExecStepTaskProgress'];

coerce 'ExecStepTaskProgress',
    from HashRef, via { 'Google::Cloud::Osconfig::Agentendpoint::V1beta::Tasks::ExecStepTaskProgress'->new($_) };

declare 'RepeatedExecStepTaskProgress',
    as ArrayRef[ExecStepTaskProgress()];

coerce 'RepeatedExecStepTaskProgress',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Osconfig::Agentendpoint::V1beta::Tasks::ExecStepTaskProgress'->new($_) } @$_ ] };

declare 'MapStringExecStepTaskProgress',
    as HashRef[ExecStepTaskProgress()];

declare 'State',
    as (Int | Str);

declare 'ExecStepTaskOutput',
    as InstanceOf['Google::Cloud::Osconfig::Agentendpoint::V1beta::Tasks::ExecStepTaskOutput'];

coerce 'ExecStepTaskOutput',
    from HashRef, via { 'Google::Cloud::Osconfig::Agentendpoint::V1beta::Tasks::ExecStepTaskOutput'->new($_) };

declare 'RepeatedExecStepTaskOutput',
    as ArrayRef[ExecStepTaskOutput()];

coerce 'RepeatedExecStepTaskOutput',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Osconfig::Agentendpoint::V1beta::Tasks::ExecStepTaskOutput'->new($_) } @$_ ] };

declare 'MapStringExecStepTaskOutput',
    as HashRef[ExecStepTaskOutput()];

declare 'State',
    as (Int | Str);

1;

__END__

=head1 NAME

Google::Cloud::Osconfig::Agentendpoint::V1beta::Tasks::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
