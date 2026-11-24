package Google::Cloud::Backupdr::V1::RestoreVerificationPlan::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'RestoreVerificationPlan',
    as InstanceOf['Google::Cloud::Backupdr::V1::RestoreVerificationPlan::RestoreVerificationPlan'];

coerce 'RestoreVerificationPlan',
    from HashRef, via { 'Google::Cloud::Backupdr::V1::RestoreVerificationPlan::RestoreVerificationPlan'->new($_) };

declare 'RepeatedRestoreVerificationPlan',
    as ArrayRef[RestoreVerificationPlan()];

coerce 'RepeatedRestoreVerificationPlan',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Backupdr::V1::RestoreVerificationPlan::RestoreVerificationPlan'->new($_) } @$_ ] };

declare 'MapStringRestoreVerificationPlan',
    as HashRef[RestoreVerificationPlan()];

declare 'State',
    as (Int | Str);

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Backupdr::V1::RestoreVerificationPlan::RestoreVerificationPlan::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Backupdr::V1::RestoreVerificationPlan::RestoreVerificationPlan::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Backupdr::V1::RestoreVerificationPlan::RestoreVerificationPlan::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'RestoreVerificationCleanupRule',
    as InstanceOf['Google::Cloud::Backupdr::V1::RestoreVerificationPlan::RestoreVerificationCleanupRule'];

coerce 'RestoreVerificationCleanupRule',
    from HashRef, via { 'Google::Cloud::Backupdr::V1::RestoreVerificationPlan::RestoreVerificationCleanupRule'->new($_) };

declare 'RepeatedRestoreVerificationCleanupRule',
    as ArrayRef[RestoreVerificationCleanupRule()];

coerce 'RepeatedRestoreVerificationCleanupRule',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Backupdr::V1::RestoreVerificationPlan::RestoreVerificationCleanupRule'->new($_) } @$_ ] };

declare 'MapStringRestoreVerificationCleanupRule',
    as HashRef[RestoreVerificationCleanupRule()];

declare 'CreateRestoreVerificationPlanRequest',
    as InstanceOf['Google::Cloud::Backupdr::V1::RestoreVerificationPlan::CreateRestoreVerificationPlanRequest'];

coerce 'CreateRestoreVerificationPlanRequest',
    from HashRef, via { 'Google::Cloud::Backupdr::V1::RestoreVerificationPlan::CreateRestoreVerificationPlanRequest'->new($_) };

declare 'RepeatedCreateRestoreVerificationPlanRequest',
    as ArrayRef[CreateRestoreVerificationPlanRequest()];

coerce 'RepeatedCreateRestoreVerificationPlanRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Backupdr::V1::RestoreVerificationPlan::CreateRestoreVerificationPlanRequest'->new($_) } @$_ ] };

declare 'MapStringCreateRestoreVerificationPlanRequest',
    as HashRef[CreateRestoreVerificationPlanRequest()];

declare 'GetRestoreVerificationPlanRequest',
    as InstanceOf['Google::Cloud::Backupdr::V1::RestoreVerificationPlan::GetRestoreVerificationPlanRequest'];

coerce 'GetRestoreVerificationPlanRequest',
    from HashRef, via { 'Google::Cloud::Backupdr::V1::RestoreVerificationPlan::GetRestoreVerificationPlanRequest'->new($_) };

declare 'RepeatedGetRestoreVerificationPlanRequest',
    as ArrayRef[GetRestoreVerificationPlanRequest()];

coerce 'RepeatedGetRestoreVerificationPlanRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Backupdr::V1::RestoreVerificationPlan::GetRestoreVerificationPlanRequest'->new($_) } @$_ ] };

declare 'MapStringGetRestoreVerificationPlanRequest',
    as HashRef[GetRestoreVerificationPlanRequest()];

declare 'ListRestoreVerificationPlansRequest',
    as InstanceOf['Google::Cloud::Backupdr::V1::RestoreVerificationPlan::ListRestoreVerificationPlansRequest'];

coerce 'ListRestoreVerificationPlansRequest',
    from HashRef, via { 'Google::Cloud::Backupdr::V1::RestoreVerificationPlan::ListRestoreVerificationPlansRequest'->new($_) };

declare 'RepeatedListRestoreVerificationPlansRequest',
    as ArrayRef[ListRestoreVerificationPlansRequest()];

coerce 'RepeatedListRestoreVerificationPlansRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Backupdr::V1::RestoreVerificationPlan::ListRestoreVerificationPlansRequest'->new($_) } @$_ ] };

declare 'MapStringListRestoreVerificationPlansRequest',
    as HashRef[ListRestoreVerificationPlansRequest()];

declare 'ListRestoreVerificationPlansResponse',
    as InstanceOf['Google::Cloud::Backupdr::V1::RestoreVerificationPlan::ListRestoreVerificationPlansResponse'];

coerce 'ListRestoreVerificationPlansResponse',
    from HashRef, via { 'Google::Cloud::Backupdr::V1::RestoreVerificationPlan::ListRestoreVerificationPlansResponse'->new($_) };

declare 'RepeatedListRestoreVerificationPlansResponse',
    as ArrayRef[ListRestoreVerificationPlansResponse()];

coerce 'RepeatedListRestoreVerificationPlansResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Backupdr::V1::RestoreVerificationPlan::ListRestoreVerificationPlansResponse'->new($_) } @$_ ] };

declare 'MapStringListRestoreVerificationPlansResponse',
    as HashRef[ListRestoreVerificationPlansResponse()];

declare 'DeleteRestoreVerificationPlanRequest',
    as InstanceOf['Google::Cloud::Backupdr::V1::RestoreVerificationPlan::DeleteRestoreVerificationPlanRequest'];

coerce 'DeleteRestoreVerificationPlanRequest',
    from HashRef, via { 'Google::Cloud::Backupdr::V1::RestoreVerificationPlan::DeleteRestoreVerificationPlanRequest'->new($_) };

declare 'RepeatedDeleteRestoreVerificationPlanRequest',
    as ArrayRef[DeleteRestoreVerificationPlanRequest()];

coerce 'RepeatedDeleteRestoreVerificationPlanRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Backupdr::V1::RestoreVerificationPlan::DeleteRestoreVerificationPlanRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteRestoreVerificationPlanRequest',
    as HashRef[DeleteRestoreVerificationPlanRequest()];

1;

__END__

=head1 NAME

Google::Cloud::Backupdr::V1::RestoreVerificationPlan::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
