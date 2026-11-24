package Google::Firestore::Admin::V1::Schedule::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'BackupSchedule',
    as InstanceOf['Google::Firestore::Admin::V1::Schedule::BackupSchedule'];

coerce 'BackupSchedule',
    from HashRef, via { 'Google::Firestore::Admin::V1::Schedule::BackupSchedule'->new($_) };

declare 'RepeatedBackupSchedule',
    as ArrayRef[BackupSchedule()];

coerce 'RepeatedBackupSchedule',
    from ArrayRef[HashRef], via { [ map { 'Google::Firestore::Admin::V1::Schedule::BackupSchedule'->new($_) } @$_ ] };

declare 'MapStringBackupSchedule',
    as HashRef[BackupSchedule()];

declare 'DailyRecurrence',
    as InstanceOf['Google::Firestore::Admin::V1::Schedule::DailyRecurrence'];

coerce 'DailyRecurrence',
    from HashRef, via { 'Google::Firestore::Admin::V1::Schedule::DailyRecurrence'->new($_) };

declare 'RepeatedDailyRecurrence',
    as ArrayRef[DailyRecurrence()];

coerce 'RepeatedDailyRecurrence',
    from ArrayRef[HashRef], via { [ map { 'Google::Firestore::Admin::V1::Schedule::DailyRecurrence'->new($_) } @$_ ] };

declare 'MapStringDailyRecurrence',
    as HashRef[DailyRecurrence()];

declare 'WeeklyRecurrence',
    as InstanceOf['Google::Firestore::Admin::V1::Schedule::WeeklyRecurrence'];

coerce 'WeeklyRecurrence',
    from HashRef, via { 'Google::Firestore::Admin::V1::Schedule::WeeklyRecurrence'->new($_) };

declare 'RepeatedWeeklyRecurrence',
    as ArrayRef[WeeklyRecurrence()];

coerce 'RepeatedWeeklyRecurrence',
    from ArrayRef[HashRef], via { [ map { 'Google::Firestore::Admin::V1::Schedule::WeeklyRecurrence'->new($_) } @$_ ] };

declare 'MapStringWeeklyRecurrence',
    as HashRef[WeeklyRecurrence()];

1;

__END__

=head1 NAME

Google::Firestore::Admin::V1::Schedule::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
