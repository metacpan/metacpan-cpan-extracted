package Google::Cloud::Workflows::Executions::V1beta::Executions::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'ExecutionView',
    as (Int | Str);

declare 'Execution',
    as InstanceOf['Google::Cloud::Workflows::Executions::V1beta::Executions::Execution'];

coerce 'Execution',
    from HashRef, via { 'Google::Cloud::Workflows::Executions::V1beta::Executions::Execution'->new($_) };

declare 'RepeatedExecution',
    as ArrayRef[Execution()];

coerce 'RepeatedExecution',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Workflows::Executions::V1beta::Executions::Execution'->new($_) } @$_ ] };

declare 'MapStringExecution',
    as HashRef[Execution()];

declare 'State',
    as (Int | Str);

declare 'Error',
    as InstanceOf['Google::Cloud::Workflows::Executions::V1beta::Executions::Execution::Error'];

coerce 'Error',
    from HashRef, via { 'Google::Cloud::Workflows::Executions::V1beta::Executions::Execution::Error'->new($_) };

declare 'RepeatedError',
    as ArrayRef[Error()];

coerce 'RepeatedError',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Workflows::Executions::V1beta::Executions::Execution::Error'->new($_) } @$_ ] };

declare 'MapStringError',
    as HashRef[Error()];

declare 'ListExecutionsRequest',
    as InstanceOf['Google::Cloud::Workflows::Executions::V1beta::Executions::ListExecutionsRequest'];

coerce 'ListExecutionsRequest',
    from HashRef, via { 'Google::Cloud::Workflows::Executions::V1beta::Executions::ListExecutionsRequest'->new($_) };

declare 'RepeatedListExecutionsRequest',
    as ArrayRef[ListExecutionsRequest()];

coerce 'RepeatedListExecutionsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Workflows::Executions::V1beta::Executions::ListExecutionsRequest'->new($_) } @$_ ] };

declare 'MapStringListExecutionsRequest',
    as HashRef[ListExecutionsRequest()];

declare 'ListExecutionsResponse',
    as InstanceOf['Google::Cloud::Workflows::Executions::V1beta::Executions::ListExecutionsResponse'];

coerce 'ListExecutionsResponse',
    from HashRef, via { 'Google::Cloud::Workflows::Executions::V1beta::Executions::ListExecutionsResponse'->new($_) };

declare 'RepeatedListExecutionsResponse',
    as ArrayRef[ListExecutionsResponse()];

coerce 'RepeatedListExecutionsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Workflows::Executions::V1beta::Executions::ListExecutionsResponse'->new($_) } @$_ ] };

declare 'MapStringListExecutionsResponse',
    as HashRef[ListExecutionsResponse()];

declare 'CreateExecutionRequest',
    as InstanceOf['Google::Cloud::Workflows::Executions::V1beta::Executions::CreateExecutionRequest'];

coerce 'CreateExecutionRequest',
    from HashRef, via { 'Google::Cloud::Workflows::Executions::V1beta::Executions::CreateExecutionRequest'->new($_) };

declare 'RepeatedCreateExecutionRequest',
    as ArrayRef[CreateExecutionRequest()];

coerce 'RepeatedCreateExecutionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Workflows::Executions::V1beta::Executions::CreateExecutionRequest'->new($_) } @$_ ] };

declare 'MapStringCreateExecutionRequest',
    as HashRef[CreateExecutionRequest()];

declare 'GetExecutionRequest',
    as InstanceOf['Google::Cloud::Workflows::Executions::V1beta::Executions::GetExecutionRequest'];

coerce 'GetExecutionRequest',
    from HashRef, via { 'Google::Cloud::Workflows::Executions::V1beta::Executions::GetExecutionRequest'->new($_) };

declare 'RepeatedGetExecutionRequest',
    as ArrayRef[GetExecutionRequest()];

coerce 'RepeatedGetExecutionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Workflows::Executions::V1beta::Executions::GetExecutionRequest'->new($_) } @$_ ] };

declare 'MapStringGetExecutionRequest',
    as HashRef[GetExecutionRequest()];

declare 'CancelExecutionRequest',
    as InstanceOf['Google::Cloud::Workflows::Executions::V1beta::Executions::CancelExecutionRequest'];

coerce 'CancelExecutionRequest',
    from HashRef, via { 'Google::Cloud::Workflows::Executions::V1beta::Executions::CancelExecutionRequest'->new($_) };

declare 'RepeatedCancelExecutionRequest',
    as ArrayRef[CancelExecutionRequest()];

coerce 'RepeatedCancelExecutionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Workflows::Executions::V1beta::Executions::CancelExecutionRequest'->new($_) } @$_ ] };

declare 'MapStringCancelExecutionRequest',
    as HashRef[CancelExecutionRequest()];

1;

__END__

=head1 NAME

Google::Cloud::Workflows::Executions::V1beta::Executions::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
