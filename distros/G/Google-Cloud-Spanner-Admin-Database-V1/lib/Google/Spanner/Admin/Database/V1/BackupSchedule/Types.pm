package Google::Spanner::Admin::Database::V1::BackupSchedule::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'BackupScheduleSpec',
    as InstanceOf['Google::Spanner::Admin::Database::V1::BackupSchedule::BackupScheduleSpec'];

coerce 'BackupScheduleSpec',
    from HashRef, via { 'Google::Spanner::Admin::Database::V1::BackupSchedule::BackupScheduleSpec'->new($_) };

declare 'RepeatedBackupScheduleSpec',
    as ArrayRef[BackupScheduleSpec()];

coerce 'RepeatedBackupScheduleSpec',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Admin::Database::V1::BackupSchedule::BackupScheduleSpec'->new($_) } @$_ ] };

declare 'MapStringBackupScheduleSpec',
    as HashRef[BackupScheduleSpec()];

declare 'BackupSchedule',
    as InstanceOf['Google::Spanner::Admin::Database::V1::BackupSchedule::BackupSchedule'];

coerce 'BackupSchedule',
    from HashRef, via { 'Google::Spanner::Admin::Database::V1::BackupSchedule::BackupSchedule'->new($_) };

declare 'RepeatedBackupSchedule',
    as ArrayRef[BackupSchedule()];

coerce 'RepeatedBackupSchedule',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Admin::Database::V1::BackupSchedule::BackupSchedule'->new($_) } @$_ ] };

declare 'MapStringBackupSchedule',
    as HashRef[BackupSchedule()];

declare 'CrontabSpec',
    as InstanceOf['Google::Spanner::Admin::Database::V1::BackupSchedule::CrontabSpec'];

coerce 'CrontabSpec',
    from HashRef, via { 'Google::Spanner::Admin::Database::V1::BackupSchedule::CrontabSpec'->new($_) };

declare 'RepeatedCrontabSpec',
    as ArrayRef[CrontabSpec()];

coerce 'RepeatedCrontabSpec',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Admin::Database::V1::BackupSchedule::CrontabSpec'->new($_) } @$_ ] };

declare 'MapStringCrontabSpec',
    as HashRef[CrontabSpec()];

declare 'CreateBackupScheduleRequest',
    as InstanceOf['Google::Spanner::Admin::Database::V1::BackupSchedule::CreateBackupScheduleRequest'];

coerce 'CreateBackupScheduleRequest',
    from HashRef, via { 'Google::Spanner::Admin::Database::V1::BackupSchedule::CreateBackupScheduleRequest'->new($_) };

declare 'RepeatedCreateBackupScheduleRequest',
    as ArrayRef[CreateBackupScheduleRequest()];

coerce 'RepeatedCreateBackupScheduleRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Admin::Database::V1::BackupSchedule::CreateBackupScheduleRequest'->new($_) } @$_ ] };

declare 'MapStringCreateBackupScheduleRequest',
    as HashRef[CreateBackupScheduleRequest()];

declare 'GetBackupScheduleRequest',
    as InstanceOf['Google::Spanner::Admin::Database::V1::BackupSchedule::GetBackupScheduleRequest'];

coerce 'GetBackupScheduleRequest',
    from HashRef, via { 'Google::Spanner::Admin::Database::V1::BackupSchedule::GetBackupScheduleRequest'->new($_) };

declare 'RepeatedGetBackupScheduleRequest',
    as ArrayRef[GetBackupScheduleRequest()];

coerce 'RepeatedGetBackupScheduleRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Admin::Database::V1::BackupSchedule::GetBackupScheduleRequest'->new($_) } @$_ ] };

declare 'MapStringGetBackupScheduleRequest',
    as HashRef[GetBackupScheduleRequest()];

declare 'DeleteBackupScheduleRequest',
    as InstanceOf['Google::Spanner::Admin::Database::V1::BackupSchedule::DeleteBackupScheduleRequest'];

coerce 'DeleteBackupScheduleRequest',
    from HashRef, via { 'Google::Spanner::Admin::Database::V1::BackupSchedule::DeleteBackupScheduleRequest'->new($_) };

declare 'RepeatedDeleteBackupScheduleRequest',
    as ArrayRef[DeleteBackupScheduleRequest()];

coerce 'RepeatedDeleteBackupScheduleRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Admin::Database::V1::BackupSchedule::DeleteBackupScheduleRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteBackupScheduleRequest',
    as HashRef[DeleteBackupScheduleRequest()];

declare 'ListBackupSchedulesRequest',
    as InstanceOf['Google::Spanner::Admin::Database::V1::BackupSchedule::ListBackupSchedulesRequest'];

coerce 'ListBackupSchedulesRequest',
    from HashRef, via { 'Google::Spanner::Admin::Database::V1::BackupSchedule::ListBackupSchedulesRequest'->new($_) };

declare 'RepeatedListBackupSchedulesRequest',
    as ArrayRef[ListBackupSchedulesRequest()];

coerce 'RepeatedListBackupSchedulesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Admin::Database::V1::BackupSchedule::ListBackupSchedulesRequest'->new($_) } @$_ ] };

declare 'MapStringListBackupSchedulesRequest',
    as HashRef[ListBackupSchedulesRequest()];

declare 'ListBackupSchedulesResponse',
    as InstanceOf['Google::Spanner::Admin::Database::V1::BackupSchedule::ListBackupSchedulesResponse'];

coerce 'ListBackupSchedulesResponse',
    from HashRef, via { 'Google::Spanner::Admin::Database::V1::BackupSchedule::ListBackupSchedulesResponse'->new($_) };

declare 'RepeatedListBackupSchedulesResponse',
    as ArrayRef[ListBackupSchedulesResponse()];

coerce 'RepeatedListBackupSchedulesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Admin::Database::V1::BackupSchedule::ListBackupSchedulesResponse'->new($_) } @$_ ] };

declare 'MapStringListBackupSchedulesResponse',
    as HashRef[ListBackupSchedulesResponse()];

declare 'UpdateBackupScheduleRequest',
    as InstanceOf['Google::Spanner::Admin::Database::V1::BackupSchedule::UpdateBackupScheduleRequest'];

coerce 'UpdateBackupScheduleRequest',
    from HashRef, via { 'Google::Spanner::Admin::Database::V1::BackupSchedule::UpdateBackupScheduleRequest'->new($_) };

declare 'RepeatedUpdateBackupScheduleRequest',
    as ArrayRef[UpdateBackupScheduleRequest()];

coerce 'RepeatedUpdateBackupScheduleRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Admin::Database::V1::BackupSchedule::UpdateBackupScheduleRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateBackupScheduleRequest',
    as HashRef[UpdateBackupScheduleRequest()];

1;

__END__

=head1 NAME

Google::Spanner::Admin::Database::V1::BackupSchedule::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
