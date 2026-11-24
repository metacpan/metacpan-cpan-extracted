package Google::Cloud::Backupdr::V1beta::Backupplan::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'BackupPlan',
    as InstanceOf['Google::Cloud::Backupdr::V1beta::Backupplan::BackupPlan'];

coerce 'BackupPlan',
    from HashRef, via { 'Google::Cloud::Backupdr::V1beta::Backupplan::BackupPlan'->new($_) };

declare 'RepeatedBackupPlan',
    as ArrayRef[BackupPlan()];

coerce 'RepeatedBackupPlan',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Backupdr::V1beta::Backupplan::BackupPlan'->new($_) } @$_ ] };

declare 'MapStringBackupPlan',
    as HashRef[BackupPlan()];

declare 'State',
    as (Int | Str);

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Backupdr::V1beta::Backupplan::BackupPlan::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Backupdr::V1beta::Backupplan::BackupPlan::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Backupdr::V1beta::Backupplan::BackupPlan::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'BackupRule',
    as InstanceOf['Google::Cloud::Backupdr::V1beta::Backupplan::BackupRule'];

coerce 'BackupRule',
    from HashRef, via { 'Google::Cloud::Backupdr::V1beta::Backupplan::BackupRule'->new($_) };

declare 'RepeatedBackupRule',
    as ArrayRef[BackupRule()];

coerce 'RepeatedBackupRule',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Backupdr::V1beta::Backupplan::BackupRule'->new($_) } @$_ ] };

declare 'MapStringBackupRule',
    as HashRef[BackupRule()];

declare 'StandardSchedule',
    as InstanceOf['Google::Cloud::Backupdr::V1beta::Backupplan::StandardSchedule'];

coerce 'StandardSchedule',
    from HashRef, via { 'Google::Cloud::Backupdr::V1beta::Backupplan::StandardSchedule'->new($_) };

declare 'RepeatedStandardSchedule',
    as ArrayRef[StandardSchedule()];

coerce 'RepeatedStandardSchedule',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Backupdr::V1beta::Backupplan::StandardSchedule'->new($_) } @$_ ] };

declare 'MapStringStandardSchedule',
    as HashRef[StandardSchedule()];

declare 'RecurrenceType',
    as (Int | Str);

declare 'BackupWindow',
    as InstanceOf['Google::Cloud::Backupdr::V1beta::Backupplan::BackupWindow'];

coerce 'BackupWindow',
    from HashRef, via { 'Google::Cloud::Backupdr::V1beta::Backupplan::BackupWindow'->new($_) };

declare 'RepeatedBackupWindow',
    as ArrayRef[BackupWindow()];

coerce 'RepeatedBackupWindow',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Backupdr::V1beta::Backupplan::BackupWindow'->new($_) } @$_ ] };

declare 'MapStringBackupWindow',
    as HashRef[BackupWindow()];

declare 'WeekDayOfMonth',
    as InstanceOf['Google::Cloud::Backupdr::V1beta::Backupplan::WeekDayOfMonth'];

coerce 'WeekDayOfMonth',
    from HashRef, via { 'Google::Cloud::Backupdr::V1beta::Backupplan::WeekDayOfMonth'->new($_) };

declare 'RepeatedWeekDayOfMonth',
    as ArrayRef[WeekDayOfMonth()];

coerce 'RepeatedWeekDayOfMonth',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Backupdr::V1beta::Backupplan::WeekDayOfMonth'->new($_) } @$_ ] };

declare 'MapStringWeekDayOfMonth',
    as HashRef[WeekDayOfMonth()];

declare 'WeekOfMonth',
    as (Int | Str);

declare 'CreateBackupPlanRequest',
    as InstanceOf['Google::Cloud::Backupdr::V1beta::Backupplan::CreateBackupPlanRequest'];

coerce 'CreateBackupPlanRequest',
    from HashRef, via { 'Google::Cloud::Backupdr::V1beta::Backupplan::CreateBackupPlanRequest'->new($_) };

declare 'RepeatedCreateBackupPlanRequest',
    as ArrayRef[CreateBackupPlanRequest()];

coerce 'RepeatedCreateBackupPlanRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Backupdr::V1beta::Backupplan::CreateBackupPlanRequest'->new($_) } @$_ ] };

declare 'MapStringCreateBackupPlanRequest',
    as HashRef[CreateBackupPlanRequest()];

declare 'ListBackupPlansRequest',
    as InstanceOf['Google::Cloud::Backupdr::V1beta::Backupplan::ListBackupPlansRequest'];

coerce 'ListBackupPlansRequest',
    from HashRef, via { 'Google::Cloud::Backupdr::V1beta::Backupplan::ListBackupPlansRequest'->new($_) };

declare 'RepeatedListBackupPlansRequest',
    as ArrayRef[ListBackupPlansRequest()];

coerce 'RepeatedListBackupPlansRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Backupdr::V1beta::Backupplan::ListBackupPlansRequest'->new($_) } @$_ ] };

declare 'MapStringListBackupPlansRequest',
    as HashRef[ListBackupPlansRequest()];

declare 'ListBackupPlansResponse',
    as InstanceOf['Google::Cloud::Backupdr::V1beta::Backupplan::ListBackupPlansResponse'];

coerce 'ListBackupPlansResponse',
    from HashRef, via { 'Google::Cloud::Backupdr::V1beta::Backupplan::ListBackupPlansResponse'->new($_) };

declare 'RepeatedListBackupPlansResponse',
    as ArrayRef[ListBackupPlansResponse()];

coerce 'RepeatedListBackupPlansResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Backupdr::V1beta::Backupplan::ListBackupPlansResponse'->new($_) } @$_ ] };

declare 'MapStringListBackupPlansResponse',
    as HashRef[ListBackupPlansResponse()];

declare 'GetBackupPlanRequest',
    as InstanceOf['Google::Cloud::Backupdr::V1beta::Backupplan::GetBackupPlanRequest'];

coerce 'GetBackupPlanRequest',
    from HashRef, via { 'Google::Cloud::Backupdr::V1beta::Backupplan::GetBackupPlanRequest'->new($_) };

declare 'RepeatedGetBackupPlanRequest',
    as ArrayRef[GetBackupPlanRequest()];

coerce 'RepeatedGetBackupPlanRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Backupdr::V1beta::Backupplan::GetBackupPlanRequest'->new($_) } @$_ ] };

declare 'MapStringGetBackupPlanRequest',
    as HashRef[GetBackupPlanRequest()];

declare 'DeleteBackupPlanRequest',
    as InstanceOf['Google::Cloud::Backupdr::V1beta::Backupplan::DeleteBackupPlanRequest'];

coerce 'DeleteBackupPlanRequest',
    from HashRef, via { 'Google::Cloud::Backupdr::V1beta::Backupplan::DeleteBackupPlanRequest'->new($_) };

declare 'RepeatedDeleteBackupPlanRequest',
    as ArrayRef[DeleteBackupPlanRequest()];

coerce 'RepeatedDeleteBackupPlanRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Backupdr::V1beta::Backupplan::DeleteBackupPlanRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteBackupPlanRequest',
    as HashRef[DeleteBackupPlanRequest()];

declare 'UpdateBackupPlanRequest',
    as InstanceOf['Google::Cloud::Backupdr::V1beta::Backupplan::UpdateBackupPlanRequest'];

coerce 'UpdateBackupPlanRequest',
    from HashRef, via { 'Google::Cloud::Backupdr::V1beta::Backupplan::UpdateBackupPlanRequest'->new($_) };

declare 'RepeatedUpdateBackupPlanRequest',
    as ArrayRef[UpdateBackupPlanRequest()];

coerce 'RepeatedUpdateBackupPlanRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Backupdr::V1beta::Backupplan::UpdateBackupPlanRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateBackupPlanRequest',
    as HashRef[UpdateBackupPlanRequest()];

declare 'BackupPlanRevision',
    as InstanceOf['Google::Cloud::Backupdr::V1beta::Backupplan::BackupPlanRevision'];

coerce 'BackupPlanRevision',
    from HashRef, via { 'Google::Cloud::Backupdr::V1beta::Backupplan::BackupPlanRevision'->new($_) };

declare 'RepeatedBackupPlanRevision',
    as ArrayRef[BackupPlanRevision()];

coerce 'RepeatedBackupPlanRevision',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Backupdr::V1beta::Backupplan::BackupPlanRevision'->new($_) } @$_ ] };

declare 'MapStringBackupPlanRevision',
    as HashRef[BackupPlanRevision()];

declare 'State',
    as (Int | Str);

declare 'GetBackupPlanRevisionRequest',
    as InstanceOf['Google::Cloud::Backupdr::V1beta::Backupplan::GetBackupPlanRevisionRequest'];

coerce 'GetBackupPlanRevisionRequest',
    from HashRef, via { 'Google::Cloud::Backupdr::V1beta::Backupplan::GetBackupPlanRevisionRequest'->new($_) };

declare 'RepeatedGetBackupPlanRevisionRequest',
    as ArrayRef[GetBackupPlanRevisionRequest()];

coerce 'RepeatedGetBackupPlanRevisionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Backupdr::V1beta::Backupplan::GetBackupPlanRevisionRequest'->new($_) } @$_ ] };

declare 'MapStringGetBackupPlanRevisionRequest',
    as HashRef[GetBackupPlanRevisionRequest()];

declare 'ListBackupPlanRevisionsRequest',
    as InstanceOf['Google::Cloud::Backupdr::V1beta::Backupplan::ListBackupPlanRevisionsRequest'];

coerce 'ListBackupPlanRevisionsRequest',
    from HashRef, via { 'Google::Cloud::Backupdr::V1beta::Backupplan::ListBackupPlanRevisionsRequest'->new($_) };

declare 'RepeatedListBackupPlanRevisionsRequest',
    as ArrayRef[ListBackupPlanRevisionsRequest()];

coerce 'RepeatedListBackupPlanRevisionsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Backupdr::V1beta::Backupplan::ListBackupPlanRevisionsRequest'->new($_) } @$_ ] };

declare 'MapStringListBackupPlanRevisionsRequest',
    as HashRef[ListBackupPlanRevisionsRequest()];

declare 'ListBackupPlanRevisionsResponse',
    as InstanceOf['Google::Cloud::Backupdr::V1beta::Backupplan::ListBackupPlanRevisionsResponse'];

coerce 'ListBackupPlanRevisionsResponse',
    from HashRef, via { 'Google::Cloud::Backupdr::V1beta::Backupplan::ListBackupPlanRevisionsResponse'->new($_) };

declare 'RepeatedListBackupPlanRevisionsResponse',
    as ArrayRef[ListBackupPlanRevisionsResponse()];

coerce 'RepeatedListBackupPlanRevisionsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Backupdr::V1beta::Backupplan::ListBackupPlanRevisionsResponse'->new($_) } @$_ ] };

declare 'MapStringListBackupPlanRevisionsResponse',
    as HashRef[ListBackupPlanRevisionsResponse()];

declare 'DiskBackupPlanProperties',
    as InstanceOf['Google::Cloud::Backupdr::V1beta::Backupplan::DiskBackupPlanProperties'];

coerce 'DiskBackupPlanProperties',
    from HashRef, via { 'Google::Cloud::Backupdr::V1beta::Backupplan::DiskBackupPlanProperties'->new($_) };

declare 'RepeatedDiskBackupPlanProperties',
    as ArrayRef[DiskBackupPlanProperties()];

coerce 'RepeatedDiskBackupPlanProperties',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Backupdr::V1beta::Backupplan::DiskBackupPlanProperties'->new($_) } @$_ ] };

declare 'MapStringDiskBackupPlanProperties',
    as HashRef[DiskBackupPlanProperties()];

declare 'ComputeInstanceBackupPlanProperties',
    as InstanceOf['Google::Cloud::Backupdr::V1beta::Backupplan::ComputeInstanceBackupPlanProperties'];

coerce 'ComputeInstanceBackupPlanProperties',
    from HashRef, via { 'Google::Cloud::Backupdr::V1beta::Backupplan::ComputeInstanceBackupPlanProperties'->new($_) };

declare 'RepeatedComputeInstanceBackupPlanProperties',
    as ArrayRef[ComputeInstanceBackupPlanProperties()];

coerce 'RepeatedComputeInstanceBackupPlanProperties',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Backupdr::V1beta::Backupplan::ComputeInstanceBackupPlanProperties'->new($_) } @$_ ] };

declare 'MapStringComputeInstanceBackupPlanProperties',
    as HashRef[ComputeInstanceBackupPlanProperties()];

1;

__END__

=head1 NAME

Google::Cloud::Backupdr::V1beta::Backupplan::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
