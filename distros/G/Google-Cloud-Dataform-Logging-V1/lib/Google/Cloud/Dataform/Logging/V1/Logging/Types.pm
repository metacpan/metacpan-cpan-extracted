package Google::Cloud::Dataform::Logging::V1::Logging::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'WorkflowInvocationCompletionLogEntry',
    as InstanceOf['Google::Cloud::Dataform::Logging::V1::Logging::WorkflowInvocationCompletionLogEntry'];

coerce 'WorkflowInvocationCompletionLogEntry',
    from HashRef, via { 'Google::Cloud::Dataform::Logging::V1::Logging::WorkflowInvocationCompletionLogEntry'->new($_) };

declare 'RepeatedWorkflowInvocationCompletionLogEntry',
    as ArrayRef[WorkflowInvocationCompletionLogEntry()];

coerce 'RepeatedWorkflowInvocationCompletionLogEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataform::Logging::V1::Logging::WorkflowInvocationCompletionLogEntry'->new($_) } @$_ ] };

declare 'MapStringWorkflowInvocationCompletionLogEntry',
    as HashRef[WorkflowInvocationCompletionLogEntry()];

declare 'TerminalState',
    as (Int | Str);

declare 'ActAsDryRunResultLogEntry',
    as InstanceOf['Google::Cloud::Dataform::Logging::V1::Logging::ActAsDryRunResultLogEntry'];

coerce 'ActAsDryRunResultLogEntry',
    from HashRef, via { 'Google::Cloud::Dataform::Logging::V1::Logging::ActAsDryRunResultLogEntry'->new($_) };

declare 'RepeatedActAsDryRunResultLogEntry',
    as ArrayRef[ActAsDryRunResultLogEntry()];

coerce 'RepeatedActAsDryRunResultLogEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataform::Logging::V1::Logging::ActAsDryRunResultLogEntry'->new($_) } @$_ ] };

declare 'MapStringActAsDryRunResultLogEntry',
    as HashRef[ActAsDryRunResultLogEntry()];

declare 'CreateRepositoryContext',
    as InstanceOf['Google::Cloud::Dataform::Logging::V1::Logging::ActAsDryRunResultLogEntry::CreateRepositoryContext'];

coerce 'CreateRepositoryContext',
    from HashRef, via { 'Google::Cloud::Dataform::Logging::V1::Logging::ActAsDryRunResultLogEntry::CreateRepositoryContext'->new($_) };

declare 'RepeatedCreateRepositoryContext',
    as ArrayRef[CreateRepositoryContext()];

coerce 'RepeatedCreateRepositoryContext',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataform::Logging::V1::Logging::ActAsDryRunResultLogEntry::CreateRepositoryContext'->new($_) } @$_ ] };

declare 'MapStringCreateRepositoryContext',
    as HashRef[CreateRepositoryContext()];

declare 'UpdateRepositoryContext',
    as InstanceOf['Google::Cloud::Dataform::Logging::V1::Logging::ActAsDryRunResultLogEntry::UpdateRepositoryContext'];

coerce 'UpdateRepositoryContext',
    from HashRef, via { 'Google::Cloud::Dataform::Logging::V1::Logging::ActAsDryRunResultLogEntry::UpdateRepositoryContext'->new($_) };

declare 'RepeatedUpdateRepositoryContext',
    as ArrayRef[UpdateRepositoryContext()];

coerce 'RepeatedUpdateRepositoryContext',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataform::Logging::V1::Logging::ActAsDryRunResultLogEntry::UpdateRepositoryContext'->new($_) } @$_ ] };

declare 'MapStringUpdateRepositoryContext',
    as HashRef[UpdateRepositoryContext()];

declare 'UpdateReleaseConfigContext',
    as InstanceOf['Google::Cloud::Dataform::Logging::V1::Logging::ActAsDryRunResultLogEntry::UpdateReleaseConfigContext'];

coerce 'UpdateReleaseConfigContext',
    from HashRef, via { 'Google::Cloud::Dataform::Logging::V1::Logging::ActAsDryRunResultLogEntry::UpdateReleaseConfigContext'->new($_) };

declare 'RepeatedUpdateReleaseConfigContext',
    as ArrayRef[UpdateReleaseConfigContext()];

coerce 'RepeatedUpdateReleaseConfigContext',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataform::Logging::V1::Logging::ActAsDryRunResultLogEntry::UpdateReleaseConfigContext'->new($_) } @$_ ] };

declare 'MapStringUpdateReleaseConfigContext',
    as HashRef[UpdateReleaseConfigContext()];

declare 'CreateWorkflowConfigContext',
    as InstanceOf['Google::Cloud::Dataform::Logging::V1::Logging::ActAsDryRunResultLogEntry::CreateWorkflowConfigContext'];

coerce 'CreateWorkflowConfigContext',
    from HashRef, via { 'Google::Cloud::Dataform::Logging::V1::Logging::ActAsDryRunResultLogEntry::CreateWorkflowConfigContext'->new($_) };

declare 'RepeatedCreateWorkflowConfigContext',
    as ArrayRef[CreateWorkflowConfigContext()];

coerce 'RepeatedCreateWorkflowConfigContext',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataform::Logging::V1::Logging::ActAsDryRunResultLogEntry::CreateWorkflowConfigContext'->new($_) } @$_ ] };

declare 'MapStringCreateWorkflowConfigContext',
    as HashRef[CreateWorkflowConfigContext()];

declare 'UpdateWorkflowConfigContext',
    as InstanceOf['Google::Cloud::Dataform::Logging::V1::Logging::ActAsDryRunResultLogEntry::UpdateWorkflowConfigContext'];

coerce 'UpdateWorkflowConfigContext',
    from HashRef, via { 'Google::Cloud::Dataform::Logging::V1::Logging::ActAsDryRunResultLogEntry::UpdateWorkflowConfigContext'->new($_) };

declare 'RepeatedUpdateWorkflowConfigContext',
    as ArrayRef[UpdateWorkflowConfigContext()];

coerce 'RepeatedUpdateWorkflowConfigContext',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataform::Logging::V1::Logging::ActAsDryRunResultLogEntry::UpdateWorkflowConfigContext'->new($_) } @$_ ] };

declare 'MapStringUpdateWorkflowConfigContext',
    as HashRef[UpdateWorkflowConfigContext()];

declare 'CreateWorkflowInvocationContext',
    as InstanceOf['Google::Cloud::Dataform::Logging::V1::Logging::ActAsDryRunResultLogEntry::CreateWorkflowInvocationContext'];

coerce 'CreateWorkflowInvocationContext',
    from HashRef, via { 'Google::Cloud::Dataform::Logging::V1::Logging::ActAsDryRunResultLogEntry::CreateWorkflowInvocationContext'->new($_) };

declare 'RepeatedCreateWorkflowInvocationContext',
    as ArrayRef[CreateWorkflowInvocationContext()];

coerce 'RepeatedCreateWorkflowInvocationContext',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataform::Logging::V1::Logging::ActAsDryRunResultLogEntry::CreateWorkflowInvocationContext'->new($_) } @$_ ] };

declare 'MapStringCreateWorkflowInvocationContext',
    as HashRef[CreateWorkflowInvocationContext()];

1;

__END__

=head1 NAME

Google::Cloud::Dataform::Logging::V1::Logging::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
