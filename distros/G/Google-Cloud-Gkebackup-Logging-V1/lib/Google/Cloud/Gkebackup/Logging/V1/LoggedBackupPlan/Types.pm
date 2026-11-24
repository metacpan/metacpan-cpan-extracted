package Google::Cloud::Gkebackup::Logging::V1::LoggedBackupPlan::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'LoggedBackupPlan',
    as InstanceOf['Google::Cloud::Gkebackup::Logging::V1::LoggedBackupPlan::LoggedBackupPlan'];

coerce 'LoggedBackupPlan',
    from HashRef, via { 'Google::Cloud::Gkebackup::Logging::V1::LoggedBackupPlan::LoggedBackupPlan'->new($_) };

declare 'RepeatedLoggedBackupPlan',
    as ArrayRef[LoggedBackupPlan()];

coerce 'RepeatedLoggedBackupPlan',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkebackup::Logging::V1::LoggedBackupPlan::LoggedBackupPlan'->new($_) } @$_ ] };

declare 'MapStringLoggedBackupPlan',
    as HashRef[LoggedBackupPlan()];

declare 'RetentionPolicy',
    as InstanceOf['Google::Cloud::Gkebackup::Logging::V1::LoggedBackupPlan::LoggedBackupPlan::RetentionPolicy'];

coerce 'RetentionPolicy',
    from HashRef, via { 'Google::Cloud::Gkebackup::Logging::V1::LoggedBackupPlan::LoggedBackupPlan::RetentionPolicy'->new($_) };

declare 'RepeatedRetentionPolicy',
    as ArrayRef[RetentionPolicy()];

coerce 'RepeatedRetentionPolicy',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkebackup::Logging::V1::LoggedBackupPlan::LoggedBackupPlan::RetentionPolicy'->new($_) } @$_ ] };

declare 'MapStringRetentionPolicy',
    as HashRef[RetentionPolicy()];

declare 'Schedule',
    as InstanceOf['Google::Cloud::Gkebackup::Logging::V1::LoggedBackupPlan::LoggedBackupPlan::Schedule'];

coerce 'Schedule',
    from HashRef, via { 'Google::Cloud::Gkebackup::Logging::V1::LoggedBackupPlan::LoggedBackupPlan::Schedule'->new($_) };

declare 'RepeatedSchedule',
    as ArrayRef[Schedule()];

coerce 'RepeatedSchedule',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkebackup::Logging::V1::LoggedBackupPlan::LoggedBackupPlan::Schedule'->new($_) } @$_ ] };

declare 'MapStringSchedule',
    as HashRef[Schedule()];

declare 'BackupConfig',
    as InstanceOf['Google::Cloud::Gkebackup::Logging::V1::LoggedBackupPlan::LoggedBackupPlan::BackupConfig'];

coerce 'BackupConfig',
    from HashRef, via { 'Google::Cloud::Gkebackup::Logging::V1::LoggedBackupPlan::LoggedBackupPlan::BackupConfig'->new($_) };

declare 'RepeatedBackupConfig',
    as ArrayRef[BackupConfig()];

coerce 'RepeatedBackupConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkebackup::Logging::V1::LoggedBackupPlan::LoggedBackupPlan::BackupConfig'->new($_) } @$_ ] };

declare 'MapStringBackupConfig',
    as HashRef[BackupConfig()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Gkebackup::Logging::V1::LoggedBackupPlan::LoggedBackupPlan::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Gkebackup::Logging::V1::LoggedBackupPlan::LoggedBackupPlan::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkebackup::Logging::V1::LoggedBackupPlan::LoggedBackupPlan::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

1;

__END__

=head1 NAME

Google::Cloud::Gkebackup::Logging::V1::LoggedBackupPlan::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
