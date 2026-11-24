package Google::Cloud::Gkebackup::V1::BackupPlan::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'BackupPlan',
    as InstanceOf['Google::Cloud::Gkebackup::V1::BackupPlan::BackupPlan'];

coerce 'BackupPlan',
    from HashRef, via { 'Google::Cloud::Gkebackup::V1::BackupPlan::BackupPlan'->new($_) };

declare 'RepeatedBackupPlan',
    as ArrayRef[BackupPlan()];

coerce 'RepeatedBackupPlan',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkebackup::V1::BackupPlan::BackupPlan'->new($_) } @$_ ] };

declare 'MapStringBackupPlan',
    as HashRef[BackupPlan()];

declare 'State',
    as (Int | Str);

declare 'RetentionPolicy',
    as InstanceOf['Google::Cloud::Gkebackup::V1::BackupPlan::BackupPlan::RetentionPolicy'];

coerce 'RetentionPolicy',
    from HashRef, via { 'Google::Cloud::Gkebackup::V1::BackupPlan::BackupPlan::RetentionPolicy'->new($_) };

declare 'RepeatedRetentionPolicy',
    as ArrayRef[RetentionPolicy()];

coerce 'RepeatedRetentionPolicy',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkebackup::V1::BackupPlan::BackupPlan::RetentionPolicy'->new($_) } @$_ ] };

declare 'MapStringRetentionPolicy',
    as HashRef[RetentionPolicy()];

declare 'Schedule',
    as InstanceOf['Google::Cloud::Gkebackup::V1::BackupPlan::BackupPlan::Schedule'];

coerce 'Schedule',
    from HashRef, via { 'Google::Cloud::Gkebackup::V1::BackupPlan::BackupPlan::Schedule'->new($_) };

declare 'RepeatedSchedule',
    as ArrayRef[Schedule()];

coerce 'RepeatedSchedule',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkebackup::V1::BackupPlan::BackupPlan::Schedule'->new($_) } @$_ ] };

declare 'MapStringSchedule',
    as HashRef[Schedule()];

declare 'BackupConfig',
    as InstanceOf['Google::Cloud::Gkebackup::V1::BackupPlan::BackupPlan::BackupConfig'];

coerce 'BackupConfig',
    from HashRef, via { 'Google::Cloud::Gkebackup::V1::BackupPlan::BackupPlan::BackupConfig'->new($_) };

declare 'RepeatedBackupConfig',
    as ArrayRef[BackupConfig()];

coerce 'RepeatedBackupConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkebackup::V1::BackupPlan::BackupPlan::BackupConfig'->new($_) } @$_ ] };

declare 'MapStringBackupConfig',
    as HashRef[BackupConfig()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Gkebackup::V1::BackupPlan::BackupPlan::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Gkebackup::V1::BackupPlan::BackupPlan::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkebackup::V1::BackupPlan::BackupPlan::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'RpoConfig',
    as InstanceOf['Google::Cloud::Gkebackup::V1::BackupPlan::RpoConfig'];

coerce 'RpoConfig',
    from HashRef, via { 'Google::Cloud::Gkebackup::V1::BackupPlan::RpoConfig'->new($_) };

declare 'RepeatedRpoConfig',
    as ArrayRef[RpoConfig()];

coerce 'RepeatedRpoConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkebackup::V1::BackupPlan::RpoConfig'->new($_) } @$_ ] };

declare 'MapStringRpoConfig',
    as HashRef[RpoConfig()];

declare 'ExclusionWindow',
    as InstanceOf['Google::Cloud::Gkebackup::V1::BackupPlan::ExclusionWindow'];

coerce 'ExclusionWindow',
    from HashRef, via { 'Google::Cloud::Gkebackup::V1::BackupPlan::ExclusionWindow'->new($_) };

declare 'RepeatedExclusionWindow',
    as ArrayRef[ExclusionWindow()];

coerce 'RepeatedExclusionWindow',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkebackup::V1::BackupPlan::ExclusionWindow'->new($_) } @$_ ] };

declare 'MapStringExclusionWindow',
    as HashRef[ExclusionWindow()];

declare 'DayOfWeekList',
    as InstanceOf['Google::Cloud::Gkebackup::V1::BackupPlan::ExclusionWindow::DayOfWeekList'];

coerce 'DayOfWeekList',
    from HashRef, via { 'Google::Cloud::Gkebackup::V1::BackupPlan::ExclusionWindow::DayOfWeekList'->new($_) };

declare 'RepeatedDayOfWeekList',
    as ArrayRef[DayOfWeekList()];

coerce 'RepeatedDayOfWeekList',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkebackup::V1::BackupPlan::ExclusionWindow::DayOfWeekList'->new($_) } @$_ ] };

declare 'MapStringDayOfWeekList',
    as HashRef[DayOfWeekList()];

1;

__END__

=head1 NAME

Google::Cloud::Gkebackup::V1::BackupPlan::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
