package Google::Cloud::Integrations::V1alpha::LogEntries::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'ExecutionType',
    as (Int | Str);

declare 'ExecutionInfo',
    as InstanceOf['Google::Cloud::Integrations::V1alpha::LogEntries::ExecutionInfo'];

coerce 'ExecutionInfo',
    from HashRef, via { 'Google::Cloud::Integrations::V1alpha::LogEntries::ExecutionInfo'->new($_) };

declare 'RepeatedExecutionInfo',
    as ArrayRef[ExecutionInfo()];

coerce 'RepeatedExecutionInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Integrations::V1alpha::LogEntries::ExecutionInfo'->new($_) } @$_ ] };

declare 'MapStringExecutionInfo',
    as HashRef[ExecutionInfo()];

declare 'ExecutionMethod',
    as (Int | Str);

declare 'ReplayInfo',
    as InstanceOf['Google::Cloud::Integrations::V1alpha::LogEntries::ExecutionInfo::ReplayInfo'];

coerce 'ReplayInfo',
    from HashRef, via { 'Google::Cloud::Integrations::V1alpha::LogEntries::ExecutionInfo::ReplayInfo'->new($_) };

declare 'RepeatedReplayInfo',
    as ArrayRef[ReplayInfo()];

coerce 'RepeatedReplayInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Integrations::V1alpha::LogEntries::ExecutionInfo::ReplayInfo'->new($_) } @$_ ] };

declare 'MapStringReplayInfo',
    as HashRef[ReplayInfo()];

declare 'ReplayMode',
    as (Int | Str);

declare 'RequestParamsEntry',
    as InstanceOf['Google::Cloud::Integrations::V1alpha::LogEntries::ExecutionInfo::RequestParamsEntry'];

coerce 'RequestParamsEntry',
    from HashRef, via { 'Google::Cloud::Integrations::V1alpha::LogEntries::ExecutionInfo::RequestParamsEntry'->new($_) };

declare 'RepeatedRequestParamsEntry',
    as ArrayRef[RequestParamsEntry()];

coerce 'RepeatedRequestParamsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Integrations::V1alpha::LogEntries::ExecutionInfo::RequestParamsEntry'->new($_) } @$_ ] };

declare 'MapStringRequestParamsEntry',
    as HashRef[RequestParamsEntry()];

declare 'ResponseParamsEntry',
    as InstanceOf['Google::Cloud::Integrations::V1alpha::LogEntries::ExecutionInfo::ResponseParamsEntry'];

coerce 'ResponseParamsEntry',
    from HashRef, via { 'Google::Cloud::Integrations::V1alpha::LogEntries::ExecutionInfo::ResponseParamsEntry'->new($_) };

declare 'RepeatedResponseParamsEntry',
    as ArrayRef[ResponseParamsEntry()];

coerce 'RepeatedResponseParamsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Integrations::V1alpha::LogEntries::ExecutionInfo::ResponseParamsEntry'->new($_) } @$_ ] };

declare 'MapStringResponseParamsEntry',
    as HashRef[ResponseParamsEntry()];

declare 'IntegrationExecutionDetails',
    as InstanceOf['Google::Cloud::Integrations::V1alpha::LogEntries::IntegrationExecutionDetails'];

coerce 'IntegrationExecutionDetails',
    from HashRef, via { 'Google::Cloud::Integrations::V1alpha::LogEntries::IntegrationExecutionDetails'->new($_) };

declare 'RepeatedIntegrationExecutionDetails',
    as ArrayRef[IntegrationExecutionDetails()];

coerce 'RepeatedIntegrationExecutionDetails',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Integrations::V1alpha::LogEntries::IntegrationExecutionDetails'->new($_) } @$_ ] };

declare 'MapStringIntegrationExecutionDetails',
    as HashRef[IntegrationExecutionDetails()];

declare 'IntegrationExecutionState',
    as (Int | Str);

declare 'IntegrationExecutionSnapshot',
    as InstanceOf['Google::Cloud::Integrations::V1alpha::LogEntries::IntegrationExecutionSnapshot'];

coerce 'IntegrationExecutionSnapshot',
    from HashRef, via { 'Google::Cloud::Integrations::V1alpha::LogEntries::IntegrationExecutionSnapshot'->new($_) };

declare 'RepeatedIntegrationExecutionSnapshot',
    as ArrayRef[IntegrationExecutionSnapshot()];

coerce 'RepeatedIntegrationExecutionSnapshot',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Integrations::V1alpha::LogEntries::IntegrationExecutionSnapshot'->new($_) } @$_ ] };

declare 'MapStringIntegrationExecutionSnapshot',
    as HashRef[IntegrationExecutionSnapshot()];

declare 'IntegrationExecutionSnapshotMetadata',
    as InstanceOf['Google::Cloud::Integrations::V1alpha::LogEntries::IntegrationExecutionSnapshot::IntegrationExecutionSnapshotMetadata'];

coerce 'IntegrationExecutionSnapshotMetadata',
    from HashRef, via { 'Google::Cloud::Integrations::V1alpha::LogEntries::IntegrationExecutionSnapshot::IntegrationExecutionSnapshotMetadata'->new($_) };

declare 'RepeatedIntegrationExecutionSnapshotMetadata',
    as ArrayRef[IntegrationExecutionSnapshotMetadata()];

coerce 'RepeatedIntegrationExecutionSnapshotMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Integrations::V1alpha::LogEntries::IntegrationExecutionSnapshot::IntegrationExecutionSnapshotMetadata'->new($_) } @$_ ] };

declare 'MapStringIntegrationExecutionSnapshotMetadata',
    as HashRef[IntegrationExecutionSnapshotMetadata()];

declare 'ExecutionParamsEntry',
    as InstanceOf['Google::Cloud::Integrations::V1alpha::LogEntries::IntegrationExecutionSnapshot::ExecutionParamsEntry'];

coerce 'ExecutionParamsEntry',
    from HashRef, via { 'Google::Cloud::Integrations::V1alpha::LogEntries::IntegrationExecutionSnapshot::ExecutionParamsEntry'->new($_) };

declare 'RepeatedExecutionParamsEntry',
    as ArrayRef[ExecutionParamsEntry()];

coerce 'RepeatedExecutionParamsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Integrations::V1alpha::LogEntries::IntegrationExecutionSnapshot::ExecutionParamsEntry'->new($_) } @$_ ] };

declare 'MapStringExecutionParamsEntry',
    as HashRef[ExecutionParamsEntry()];

declare 'TaskExecutionDetails',
    as InstanceOf['Google::Cloud::Integrations::V1alpha::LogEntries::TaskExecutionDetails'];

coerce 'TaskExecutionDetails',
    from HashRef, via { 'Google::Cloud::Integrations::V1alpha::LogEntries::TaskExecutionDetails'->new($_) };

declare 'RepeatedTaskExecutionDetails',
    as ArrayRef[TaskExecutionDetails()];

coerce 'RepeatedTaskExecutionDetails',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Integrations::V1alpha::LogEntries::TaskExecutionDetails'->new($_) } @$_ ] };

declare 'MapStringTaskExecutionDetails',
    as HashRef[TaskExecutionDetails()];

declare 'TaskExecutionState',
    as (Int | Str);

declare 'AttemptStats',
    as InstanceOf['Google::Cloud::Integrations::V1alpha::LogEntries::AttemptStats'];

coerce 'AttemptStats',
    from HashRef, via { 'Google::Cloud::Integrations::V1alpha::LogEntries::AttemptStats'->new($_) };

declare 'RepeatedAttemptStats',
    as ArrayRef[AttemptStats()];

coerce 'RepeatedAttemptStats',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Integrations::V1alpha::LogEntries::AttemptStats'->new($_) } @$_ ] };

declare 'MapStringAttemptStats',
    as HashRef[AttemptStats()];

declare 'ErrorDetail',
    as InstanceOf['Google::Cloud::Integrations::V1alpha::LogEntries::ErrorDetail'];

coerce 'ErrorDetail',
    from HashRef, via { 'Google::Cloud::Integrations::V1alpha::LogEntries::ErrorDetail'->new($_) };

declare 'RepeatedErrorDetail',
    as ArrayRef[ErrorDetail()];

coerce 'RepeatedErrorDetail',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Integrations::V1alpha::LogEntries::ErrorDetail'->new($_) } @$_ ] };

declare 'MapStringErrorDetail',
    as HashRef[ErrorDetail()];

declare 'ConditionResult',
    as InstanceOf['Google::Cloud::Integrations::V1alpha::LogEntries::ConditionResult'];

coerce 'ConditionResult',
    from HashRef, via { 'Google::Cloud::Integrations::V1alpha::LogEntries::ConditionResult'->new($_) };

declare 'RepeatedConditionResult',
    as ArrayRef[ConditionResult()];

coerce 'RepeatedConditionResult',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Integrations::V1alpha::LogEntries::ConditionResult'->new($_) } @$_ ] };

declare 'MapStringConditionResult',
    as HashRef[ConditionResult()];

1;

__END__

=head1 NAME

Google::Cloud::Integrations::V1alpha::LogEntries::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
