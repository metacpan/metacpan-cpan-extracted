package Google::Cloud::Bigquery::Datatransfer::V1::Transfer::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'TransferType',
    as (Int | Str);

declare 'TransferState',
    as (Int | Str);

declare 'EmailPreferences',
    as InstanceOf['Google::Cloud::Bigquery::Datatransfer::V1::Transfer::EmailPreferences'];

coerce 'EmailPreferences',
    from HashRef, via { 'Google::Cloud::Bigquery::Datatransfer::V1::Transfer::EmailPreferences'->new($_) };

declare 'RepeatedEmailPreferences',
    as ArrayRef[EmailPreferences()];

coerce 'RepeatedEmailPreferences',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Datatransfer::V1::Transfer::EmailPreferences'->new($_) } @$_ ] };

declare 'MapStringEmailPreferences',
    as HashRef[EmailPreferences()];

declare 'ScheduleOptions',
    as InstanceOf['Google::Cloud::Bigquery::Datatransfer::V1::Transfer::ScheduleOptions'];

coerce 'ScheduleOptions',
    from HashRef, via { 'Google::Cloud::Bigquery::Datatransfer::V1::Transfer::ScheduleOptions'->new($_) };

declare 'RepeatedScheduleOptions',
    as ArrayRef[ScheduleOptions()];

coerce 'RepeatedScheduleOptions',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Datatransfer::V1::Transfer::ScheduleOptions'->new($_) } @$_ ] };

declare 'MapStringScheduleOptions',
    as HashRef[ScheduleOptions()];

declare 'ScheduleOptionsV2',
    as InstanceOf['Google::Cloud::Bigquery::Datatransfer::V1::Transfer::ScheduleOptionsV2'];

coerce 'ScheduleOptionsV2',
    from HashRef, via { 'Google::Cloud::Bigquery::Datatransfer::V1::Transfer::ScheduleOptionsV2'->new($_) };

declare 'RepeatedScheduleOptionsV2',
    as ArrayRef[ScheduleOptionsV2()];

coerce 'RepeatedScheduleOptionsV2',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Datatransfer::V1::Transfer::ScheduleOptionsV2'->new($_) } @$_ ] };

declare 'MapStringScheduleOptionsV2',
    as HashRef[ScheduleOptionsV2()];

declare 'TimeBasedSchedule',
    as InstanceOf['Google::Cloud::Bigquery::Datatransfer::V1::Transfer::TimeBasedSchedule'];

coerce 'TimeBasedSchedule',
    from HashRef, via { 'Google::Cloud::Bigquery::Datatransfer::V1::Transfer::TimeBasedSchedule'->new($_) };

declare 'RepeatedTimeBasedSchedule',
    as ArrayRef[TimeBasedSchedule()];

coerce 'RepeatedTimeBasedSchedule',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Datatransfer::V1::Transfer::TimeBasedSchedule'->new($_) } @$_ ] };

declare 'MapStringTimeBasedSchedule',
    as HashRef[TimeBasedSchedule()];

declare 'ManualSchedule',
    as InstanceOf['Google::Cloud::Bigquery::Datatransfer::V1::Transfer::ManualSchedule'];

coerce 'ManualSchedule',
    from HashRef, via { 'Google::Cloud::Bigquery::Datatransfer::V1::Transfer::ManualSchedule'->new($_) };

declare 'RepeatedManualSchedule',
    as ArrayRef[ManualSchedule()];

coerce 'RepeatedManualSchedule',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Datatransfer::V1::Transfer::ManualSchedule'->new($_) } @$_ ] };

declare 'MapStringManualSchedule',
    as HashRef[ManualSchedule()];

declare 'EventDrivenSchedule',
    as InstanceOf['Google::Cloud::Bigquery::Datatransfer::V1::Transfer::EventDrivenSchedule'];

coerce 'EventDrivenSchedule',
    from HashRef, via { 'Google::Cloud::Bigquery::Datatransfer::V1::Transfer::EventDrivenSchedule'->new($_) };

declare 'RepeatedEventDrivenSchedule',
    as ArrayRef[EventDrivenSchedule()];

coerce 'RepeatedEventDrivenSchedule',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Datatransfer::V1::Transfer::EventDrivenSchedule'->new($_) } @$_ ] };

declare 'MapStringEventDrivenSchedule',
    as HashRef[EventDrivenSchedule()];

declare 'UserInfo',
    as InstanceOf['Google::Cloud::Bigquery::Datatransfer::V1::Transfer::UserInfo'];

coerce 'UserInfo',
    from HashRef, via { 'Google::Cloud::Bigquery::Datatransfer::V1::Transfer::UserInfo'->new($_) };

declare 'RepeatedUserInfo',
    as ArrayRef[UserInfo()];

coerce 'RepeatedUserInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Datatransfer::V1::Transfer::UserInfo'->new($_) } @$_ ] };

declare 'MapStringUserInfo',
    as HashRef[UserInfo()];

declare 'TransferConfig',
    as InstanceOf['Google::Cloud::Bigquery::Datatransfer::V1::Transfer::TransferConfig'];

coerce 'TransferConfig',
    from HashRef, via { 'Google::Cloud::Bigquery::Datatransfer::V1::Transfer::TransferConfig'->new($_) };

declare 'RepeatedTransferConfig',
    as ArrayRef[TransferConfig()];

coerce 'RepeatedTransferConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Datatransfer::V1::Transfer::TransferConfig'->new($_) } @$_ ] };

declare 'MapStringTransferConfig',
    as HashRef[TransferConfig()];

declare 'EncryptionConfiguration',
    as InstanceOf['Google::Cloud::Bigquery::Datatransfer::V1::Transfer::EncryptionConfiguration'];

coerce 'EncryptionConfiguration',
    from HashRef, via { 'Google::Cloud::Bigquery::Datatransfer::V1::Transfer::EncryptionConfiguration'->new($_) };

declare 'RepeatedEncryptionConfiguration',
    as ArrayRef[EncryptionConfiguration()];

coerce 'RepeatedEncryptionConfiguration',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Datatransfer::V1::Transfer::EncryptionConfiguration'->new($_) } @$_ ] };

declare 'MapStringEncryptionConfiguration',
    as HashRef[EncryptionConfiguration()];

declare 'TransferRun',
    as InstanceOf['Google::Cloud::Bigquery::Datatransfer::V1::Transfer::TransferRun'];

coerce 'TransferRun',
    from HashRef, via { 'Google::Cloud::Bigquery::Datatransfer::V1::Transfer::TransferRun'->new($_) };

declare 'RepeatedTransferRun',
    as ArrayRef[TransferRun()];

coerce 'RepeatedTransferRun',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Datatransfer::V1::Transfer::TransferRun'->new($_) } @$_ ] };

declare 'MapStringTransferRun',
    as HashRef[TransferRun()];

declare 'TransferMessage',
    as InstanceOf['Google::Cloud::Bigquery::Datatransfer::V1::Transfer::TransferMessage'];

coerce 'TransferMessage',
    from HashRef, via { 'Google::Cloud::Bigquery::Datatransfer::V1::Transfer::TransferMessage'->new($_) };

declare 'RepeatedTransferMessage',
    as ArrayRef[TransferMessage()];

coerce 'RepeatedTransferMessage',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Datatransfer::V1::Transfer::TransferMessage'->new($_) } @$_ ] };

declare 'MapStringTransferMessage',
    as HashRef[TransferMessage()];

declare 'MessageSeverity',
    as (Int | Str);

1;

__END__

=head1 NAME

Google::Cloud::Bigquery::Datatransfer::V1::Transfer::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
