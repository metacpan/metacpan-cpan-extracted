package Google::Cloud::Backupdr::V1beta::RestoreTemplateExecution::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'PhaseState',
    as (Int | Str);

declare 'RestoreTemplateExecution',
    as InstanceOf['Google::Cloud::Backupdr::V1beta::RestoreTemplateExecution::RestoreTemplateExecution'];

coerce 'RestoreTemplateExecution',
    from HashRef, via { 'Google::Cloud::Backupdr::V1beta::RestoreTemplateExecution::RestoreTemplateExecution'->new($_) };

declare 'RepeatedRestoreTemplateExecution',
    as ArrayRef[RestoreTemplateExecution()];

coerce 'RepeatedRestoreTemplateExecution',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Backupdr::V1beta::RestoreTemplateExecution::RestoreTemplateExecution'->new($_) } @$_ ] };

declare 'MapStringRestoreTemplateExecution',
    as HashRef[RestoreTemplateExecution()];

declare 'ExecutionType',
    as (Int | Str);

declare 'ExecutionPhase',
    as (Int | Str);

declare 'ExecutionState',
    as (Int | Str);

declare 'PreparePhaseInfo',
    as InstanceOf['Google::Cloud::Backupdr::V1beta::RestoreTemplateExecution::PreparePhaseInfo'];

coerce 'PreparePhaseInfo',
    from HashRef, via { 'Google::Cloud::Backupdr::V1beta::RestoreTemplateExecution::PreparePhaseInfo'->new($_) };

declare 'RepeatedPreparePhaseInfo',
    as ArrayRef[PreparePhaseInfo()];

coerce 'RepeatedPreparePhaseInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Backupdr::V1beta::RestoreTemplateExecution::PreparePhaseInfo'->new($_) } @$_ ] };

declare 'MapStringPreparePhaseInfo',
    as HashRef[PreparePhaseInfo()];

declare 'PreRestorePhaseInfo',
    as InstanceOf['Google::Cloud::Backupdr::V1beta::RestoreTemplateExecution::PreRestorePhaseInfo'];

coerce 'PreRestorePhaseInfo',
    from HashRef, via { 'Google::Cloud::Backupdr::V1beta::RestoreTemplateExecution::PreRestorePhaseInfo'->new($_) };

declare 'RepeatedPreRestorePhaseInfo',
    as ArrayRef[PreRestorePhaseInfo()];

coerce 'RepeatedPreRestorePhaseInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Backupdr::V1beta::RestoreTemplateExecution::PreRestorePhaseInfo'->new($_) } @$_ ] };

declare 'MapStringPreRestorePhaseInfo',
    as HashRef[PreRestorePhaseInfo()];

declare 'RestorePhaseInfo',
    as InstanceOf['Google::Cloud::Backupdr::V1beta::RestoreTemplateExecution::RestorePhaseInfo'];

coerce 'RestorePhaseInfo',
    from HashRef, via { 'Google::Cloud::Backupdr::V1beta::RestoreTemplateExecution::RestorePhaseInfo'->new($_) };

declare 'RepeatedRestorePhaseInfo',
    as ArrayRef[RestorePhaseInfo()];

coerce 'RepeatedRestorePhaseInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Backupdr::V1beta::RestoreTemplateExecution::RestorePhaseInfo'->new($_) } @$_ ] };

declare 'MapStringRestorePhaseInfo',
    as HashRef[RestorePhaseInfo()];

declare 'PostRestorePhaseInfo',
    as InstanceOf['Google::Cloud::Backupdr::V1beta::RestoreTemplateExecution::PostRestorePhaseInfo'];

coerce 'PostRestorePhaseInfo',
    from HashRef, via { 'Google::Cloud::Backupdr::V1beta::RestoreTemplateExecution::PostRestorePhaseInfo'->new($_) };

declare 'RepeatedPostRestorePhaseInfo',
    as ArrayRef[PostRestorePhaseInfo()];

coerce 'RepeatedPostRestorePhaseInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Backupdr::V1beta::RestoreTemplateExecution::PostRestorePhaseInfo'->new($_) } @$_ ] };

declare 'MapStringPostRestorePhaseInfo',
    as HashRef[PostRestorePhaseInfo()];

declare 'VerificationPhaseInfo',
    as InstanceOf['Google::Cloud::Backupdr::V1beta::RestoreTemplateExecution::VerificationPhaseInfo'];

coerce 'VerificationPhaseInfo',
    from HashRef, via { 'Google::Cloud::Backupdr::V1beta::RestoreTemplateExecution::VerificationPhaseInfo'->new($_) };

declare 'RepeatedVerificationPhaseInfo',
    as ArrayRef[VerificationPhaseInfo()];

coerce 'RepeatedVerificationPhaseInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Backupdr::V1beta::RestoreTemplateExecution::VerificationPhaseInfo'->new($_) } @$_ ] };

declare 'MapStringVerificationPhaseInfo',
    as HashRef[VerificationPhaseInfo()];

declare 'CleanupPhaseInfo',
    as InstanceOf['Google::Cloud::Backupdr::V1beta::RestoreTemplateExecution::CleanupPhaseInfo'];

coerce 'CleanupPhaseInfo',
    from HashRef, via { 'Google::Cloud::Backupdr::V1beta::RestoreTemplateExecution::CleanupPhaseInfo'->new($_) };

declare 'RepeatedCleanupPhaseInfo',
    as ArrayRef[CleanupPhaseInfo()];

coerce 'RepeatedCleanupPhaseInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Backupdr::V1beta::RestoreTemplateExecution::CleanupPhaseInfo'->new($_) } @$_ ] };

declare 'MapStringCleanupPhaseInfo',
    as HashRef[CleanupPhaseInfo()];

declare 'GetRestoreTemplateExecutionRequest',
    as InstanceOf['Google::Cloud::Backupdr::V1beta::RestoreTemplateExecution::GetRestoreTemplateExecutionRequest'];

coerce 'GetRestoreTemplateExecutionRequest',
    from HashRef, via { 'Google::Cloud::Backupdr::V1beta::RestoreTemplateExecution::GetRestoreTemplateExecutionRequest'->new($_) };

declare 'RepeatedGetRestoreTemplateExecutionRequest',
    as ArrayRef[GetRestoreTemplateExecutionRequest()];

coerce 'RepeatedGetRestoreTemplateExecutionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Backupdr::V1beta::RestoreTemplateExecution::GetRestoreTemplateExecutionRequest'->new($_) } @$_ ] };

declare 'MapStringGetRestoreTemplateExecutionRequest',
    as HashRef[GetRestoreTemplateExecutionRequest()];

declare 'TriggerRestoreCleanupRequest',
    as InstanceOf['Google::Cloud::Backupdr::V1beta::RestoreTemplateExecution::TriggerRestoreCleanupRequest'];

coerce 'TriggerRestoreCleanupRequest',
    from HashRef, via { 'Google::Cloud::Backupdr::V1beta::RestoreTemplateExecution::TriggerRestoreCleanupRequest'->new($_) };

declare 'RepeatedTriggerRestoreCleanupRequest',
    as ArrayRef[TriggerRestoreCleanupRequest()];

coerce 'RepeatedTriggerRestoreCleanupRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Backupdr::V1beta::RestoreTemplateExecution::TriggerRestoreCleanupRequest'->new($_) } @$_ ] };

declare 'MapStringTriggerRestoreCleanupRequest',
    as HashRef[TriggerRestoreCleanupRequest()];

declare 'ListRestoreTemplateExecutionsRequest',
    as InstanceOf['Google::Cloud::Backupdr::V1beta::RestoreTemplateExecution::ListRestoreTemplateExecutionsRequest'];

coerce 'ListRestoreTemplateExecutionsRequest',
    from HashRef, via { 'Google::Cloud::Backupdr::V1beta::RestoreTemplateExecution::ListRestoreTemplateExecutionsRequest'->new($_) };

declare 'RepeatedListRestoreTemplateExecutionsRequest',
    as ArrayRef[ListRestoreTemplateExecutionsRequest()];

coerce 'RepeatedListRestoreTemplateExecutionsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Backupdr::V1beta::RestoreTemplateExecution::ListRestoreTemplateExecutionsRequest'->new($_) } @$_ ] };

declare 'MapStringListRestoreTemplateExecutionsRequest',
    as HashRef[ListRestoreTemplateExecutionsRequest()];

declare 'ListRestoreTemplateExecutionsResponse',
    as InstanceOf['Google::Cloud::Backupdr::V1beta::RestoreTemplateExecution::ListRestoreTemplateExecutionsResponse'];

coerce 'ListRestoreTemplateExecutionsResponse',
    from HashRef, via { 'Google::Cloud::Backupdr::V1beta::RestoreTemplateExecution::ListRestoreTemplateExecutionsResponse'->new($_) };

declare 'RepeatedListRestoreTemplateExecutionsResponse',
    as ArrayRef[ListRestoreTemplateExecutionsResponse()];

coerce 'RepeatedListRestoreTemplateExecutionsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Backupdr::V1beta::RestoreTemplateExecution::ListRestoreTemplateExecutionsResponse'->new($_) } @$_ ] };

declare 'MapStringListRestoreTemplateExecutionsResponse',
    as HashRef[ListRestoreTemplateExecutionsResponse()];

1;

__END__

=head1 NAME

Google::Cloud::Backupdr::V1beta::RestoreTemplateExecution::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
