package Google::Cloud::Workflows::Executions::V1::Executions::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'ExecutionView',
    as (Int | Str);

declare 'Execution',
    as InstanceOf['Google::Cloud::Workflows::Executions::V1::Executions::Execution'];

coerce 'Execution',
    from HashRef, via { 'Google::Cloud::Workflows::Executions::V1::Executions::Execution'->new($_) };

declare 'RepeatedExecution',
    as ArrayRef[Execution()];

coerce 'RepeatedExecution',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Workflows::Executions::V1::Executions::Execution'->new($_) } @$_ ] };

declare 'MapStringExecution',
    as HashRef[Execution()];

declare 'State',
    as (Int | Str);

declare 'CallLogLevel',
    as (Int | Str);

declare 'StackTraceElement',
    as InstanceOf['Google::Cloud::Workflows::Executions::V1::Executions::Execution::StackTraceElement'];

coerce 'StackTraceElement',
    from HashRef, via { 'Google::Cloud::Workflows::Executions::V1::Executions::Execution::StackTraceElement'->new($_) };

declare 'RepeatedStackTraceElement',
    as ArrayRef[StackTraceElement()];

coerce 'RepeatedStackTraceElement',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Workflows::Executions::V1::Executions::Execution::StackTraceElement'->new($_) } @$_ ] };

declare 'MapStringStackTraceElement',
    as HashRef[StackTraceElement()];

declare 'Position',
    as InstanceOf['Google::Cloud::Workflows::Executions::V1::Executions::Execution::StackTraceElement::Position'];

coerce 'Position',
    from HashRef, via { 'Google::Cloud::Workflows::Executions::V1::Executions::Execution::StackTraceElement::Position'->new($_) };

declare 'RepeatedPosition',
    as ArrayRef[Position()];

coerce 'RepeatedPosition',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Workflows::Executions::V1::Executions::Execution::StackTraceElement::Position'->new($_) } @$_ ] };

declare 'MapStringPosition',
    as HashRef[Position()];

declare 'StackTrace',
    as InstanceOf['Google::Cloud::Workflows::Executions::V1::Executions::Execution::StackTrace'];

coerce 'StackTrace',
    from HashRef, via { 'Google::Cloud::Workflows::Executions::V1::Executions::Execution::StackTrace'->new($_) };

declare 'RepeatedStackTrace',
    as ArrayRef[StackTrace()];

coerce 'RepeatedStackTrace',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Workflows::Executions::V1::Executions::Execution::StackTrace'->new($_) } @$_ ] };

declare 'MapStringStackTrace',
    as HashRef[StackTrace()];

declare 'Error',
    as InstanceOf['Google::Cloud::Workflows::Executions::V1::Executions::Execution::Error'];

coerce 'Error',
    from HashRef, via { 'Google::Cloud::Workflows::Executions::V1::Executions::Execution::Error'->new($_) };

declare 'RepeatedError',
    as ArrayRef[Error()];

coerce 'RepeatedError',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Workflows::Executions::V1::Executions::Execution::Error'->new($_) } @$_ ] };

declare 'MapStringError',
    as HashRef[Error()];

declare 'Status',
    as InstanceOf['Google::Cloud::Workflows::Executions::V1::Executions::Execution::Status'];

coerce 'Status',
    from HashRef, via { 'Google::Cloud::Workflows::Executions::V1::Executions::Execution::Status'->new($_) };

declare 'RepeatedStatus',
    as ArrayRef[Status()];

coerce 'RepeatedStatus',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Workflows::Executions::V1::Executions::Execution::Status'->new($_) } @$_ ] };

declare 'MapStringStatus',
    as HashRef[Status()];

declare 'Step',
    as InstanceOf['Google::Cloud::Workflows::Executions::V1::Executions::Execution::Status::Step'];

coerce 'Step',
    from HashRef, via { 'Google::Cloud::Workflows::Executions::V1::Executions::Execution::Status::Step'->new($_) };

declare 'RepeatedStep',
    as ArrayRef[Step()];

coerce 'RepeatedStep',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Workflows::Executions::V1::Executions::Execution::Status::Step'->new($_) } @$_ ] };

declare 'MapStringStep',
    as HashRef[Step()];

declare 'StateError',
    as InstanceOf['Google::Cloud::Workflows::Executions::V1::Executions::Execution::StateError'];

coerce 'StateError',
    from HashRef, via { 'Google::Cloud::Workflows::Executions::V1::Executions::Execution::StateError'->new($_) };

declare 'RepeatedStateError',
    as ArrayRef[StateError()];

coerce 'RepeatedStateError',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Workflows::Executions::V1::Executions::Execution::StateError'->new($_) } @$_ ] };

declare 'MapStringStateError',
    as HashRef[StateError()];

declare 'Type',
    as (Int | Str);

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Workflows::Executions::V1::Executions::Execution::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Workflows::Executions::V1::Executions::Execution::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Workflows::Executions::V1::Executions::Execution::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'ListExecutionsRequest',
    as InstanceOf['Google::Cloud::Workflows::Executions::V1::Executions::ListExecutionsRequest'];

coerce 'ListExecutionsRequest',
    from HashRef, via { 'Google::Cloud::Workflows::Executions::V1::Executions::ListExecutionsRequest'->new($_) };

declare 'RepeatedListExecutionsRequest',
    as ArrayRef[ListExecutionsRequest()];

coerce 'RepeatedListExecutionsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Workflows::Executions::V1::Executions::ListExecutionsRequest'->new($_) } @$_ ] };

declare 'MapStringListExecutionsRequest',
    as HashRef[ListExecutionsRequest()];

declare 'ListExecutionsResponse',
    as InstanceOf['Google::Cloud::Workflows::Executions::V1::Executions::ListExecutionsResponse'];

coerce 'ListExecutionsResponse',
    from HashRef, via { 'Google::Cloud::Workflows::Executions::V1::Executions::ListExecutionsResponse'->new($_) };

declare 'RepeatedListExecutionsResponse',
    as ArrayRef[ListExecutionsResponse()];

coerce 'RepeatedListExecutionsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Workflows::Executions::V1::Executions::ListExecutionsResponse'->new($_) } @$_ ] };

declare 'MapStringListExecutionsResponse',
    as HashRef[ListExecutionsResponse()];

declare 'CreateExecutionRequest',
    as InstanceOf['Google::Cloud::Workflows::Executions::V1::Executions::CreateExecutionRequest'];

coerce 'CreateExecutionRequest',
    from HashRef, via { 'Google::Cloud::Workflows::Executions::V1::Executions::CreateExecutionRequest'->new($_) };

declare 'RepeatedCreateExecutionRequest',
    as ArrayRef[CreateExecutionRequest()];

coerce 'RepeatedCreateExecutionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Workflows::Executions::V1::Executions::CreateExecutionRequest'->new($_) } @$_ ] };

declare 'MapStringCreateExecutionRequest',
    as HashRef[CreateExecutionRequest()];

declare 'GetExecutionRequest',
    as InstanceOf['Google::Cloud::Workflows::Executions::V1::Executions::GetExecutionRequest'];

coerce 'GetExecutionRequest',
    from HashRef, via { 'Google::Cloud::Workflows::Executions::V1::Executions::GetExecutionRequest'->new($_) };

declare 'RepeatedGetExecutionRequest',
    as ArrayRef[GetExecutionRequest()];

coerce 'RepeatedGetExecutionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Workflows::Executions::V1::Executions::GetExecutionRequest'->new($_) } @$_ ] };

declare 'MapStringGetExecutionRequest',
    as HashRef[GetExecutionRequest()];

declare 'CancelExecutionRequest',
    as InstanceOf['Google::Cloud::Workflows::Executions::V1::Executions::CancelExecutionRequest'];

coerce 'CancelExecutionRequest',
    from HashRef, via { 'Google::Cloud::Workflows::Executions::V1::Executions::CancelExecutionRequest'->new($_) };

declare 'RepeatedCancelExecutionRequest',
    as ArrayRef[CancelExecutionRequest()];

coerce 'RepeatedCancelExecutionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Workflows::Executions::V1::Executions::CancelExecutionRequest'->new($_) } @$_ ] };

declare 'MapStringCancelExecutionRequest',
    as HashRef[CancelExecutionRequest()];

1;

__END__

=head1 NAME

Google::Cloud::Workflows::Executions::V1::Executions::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
