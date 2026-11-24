package Google::Cloud::Integrations::V1alpha::TaskConfig::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'TaskConfig',
    as InstanceOf['Google::Cloud::Integrations::V1alpha::TaskConfig::TaskConfig'];

coerce 'TaskConfig',
    from HashRef, via { 'Google::Cloud::Integrations::V1alpha::TaskConfig::TaskConfig'->new($_) };

declare 'RepeatedTaskConfig',
    as ArrayRef[TaskConfig()];

coerce 'RepeatedTaskConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Integrations::V1alpha::TaskConfig::TaskConfig'->new($_) } @$_ ] };

declare 'MapStringTaskConfig',
    as HashRef[TaskConfig()];

declare 'NextTasksExecutionPolicy',
    as (Int | Str);

declare 'TaskExecutionStrategy',
    as (Int | Str);

declare 'ExternalTaskType',
    as (Int | Str);

declare 'ParametersEntry',
    as InstanceOf['Google::Cloud::Integrations::V1alpha::TaskConfig::TaskConfig::ParametersEntry'];

coerce 'ParametersEntry',
    from HashRef, via { 'Google::Cloud::Integrations::V1alpha::TaskConfig::TaskConfig::ParametersEntry'->new($_) };

declare 'RepeatedParametersEntry',
    as ArrayRef[ParametersEntry()];

coerce 'RepeatedParametersEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Integrations::V1alpha::TaskConfig::TaskConfig::ParametersEntry'->new($_) } @$_ ] };

declare 'MapStringParametersEntry',
    as HashRef[ParametersEntry()];

declare 'SuccessPolicy',
    as InstanceOf['Google::Cloud::Integrations::V1alpha::TaskConfig::SuccessPolicy'];

coerce 'SuccessPolicy',
    from HashRef, via { 'Google::Cloud::Integrations::V1alpha::TaskConfig::SuccessPolicy'->new($_) };

declare 'RepeatedSuccessPolicy',
    as ArrayRef[SuccessPolicy()];

coerce 'RepeatedSuccessPolicy',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Integrations::V1alpha::TaskConfig::SuccessPolicy'->new($_) } @$_ ] };

declare 'MapStringSuccessPolicy',
    as HashRef[SuccessPolicy()];

declare 'FinalState',
    as (Int | Str);

declare 'FailurePolicy',
    as InstanceOf['Google::Cloud::Integrations::V1alpha::TaskConfig::FailurePolicy'];

coerce 'FailurePolicy',
    from HashRef, via { 'Google::Cloud::Integrations::V1alpha::TaskConfig::FailurePolicy'->new($_) };

declare 'RepeatedFailurePolicy',
    as ArrayRef[FailurePolicy()];

coerce 'RepeatedFailurePolicy',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Integrations::V1alpha::TaskConfig::FailurePolicy'->new($_) } @$_ ] };

declare 'MapStringFailurePolicy',
    as HashRef[FailurePolicy()];

declare 'RetryStrategy',
    as (Int | Str);

declare 'NextTask',
    as InstanceOf['Google::Cloud::Integrations::V1alpha::TaskConfig::NextTask'];

coerce 'NextTask',
    from HashRef, via { 'Google::Cloud::Integrations::V1alpha::TaskConfig::NextTask'->new($_) };

declare 'RepeatedNextTask',
    as ArrayRef[NextTask()];

coerce 'RepeatedNextTask',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Integrations::V1alpha::TaskConfig::NextTask'->new($_) } @$_ ] };

declare 'MapStringNextTask',
    as HashRef[NextTask()];

declare 'ConditionalFailurePolicies',
    as InstanceOf['Google::Cloud::Integrations::V1alpha::TaskConfig::ConditionalFailurePolicies'];

coerce 'ConditionalFailurePolicies',
    from HashRef, via { 'Google::Cloud::Integrations::V1alpha::TaskConfig::ConditionalFailurePolicies'->new($_) };

declare 'RepeatedConditionalFailurePolicies',
    as ArrayRef[ConditionalFailurePolicies()];

coerce 'RepeatedConditionalFailurePolicies',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Integrations::V1alpha::TaskConfig::ConditionalFailurePolicies'->new($_) } @$_ ] };

declare 'MapStringConditionalFailurePolicies',
    as HashRef[ConditionalFailurePolicies()];

1;

__END__

=head1 NAME

Google::Cloud::Integrations::V1alpha::TaskConfig::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
