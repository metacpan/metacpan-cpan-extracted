package Google::Cloud::Gkebackup::Logging::V1::Logging::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'ChangeType',
    as (Int | Str);

declare 'BackupPlanChange',
    as InstanceOf['Google::Cloud::Gkebackup::Logging::V1::Logging::BackupPlanChange'];

coerce 'BackupPlanChange',
    from HashRef, via { 'Google::Cloud::Gkebackup::Logging::V1::Logging::BackupPlanChange'->new($_) };

declare 'RepeatedBackupPlanChange',
    as ArrayRef[BackupPlanChange()];

coerce 'RepeatedBackupPlanChange',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkebackup::Logging::V1::Logging::BackupPlanChange'->new($_) } @$_ ] };

declare 'MapStringBackupPlanChange',
    as HashRef[BackupPlanChange()];

declare 'BackupChange',
    as InstanceOf['Google::Cloud::Gkebackup::Logging::V1::Logging::BackupChange'];

coerce 'BackupChange',
    from HashRef, via { 'Google::Cloud::Gkebackup::Logging::V1::Logging::BackupChange'->new($_) };

declare 'RepeatedBackupChange',
    as ArrayRef[BackupChange()];

coerce 'RepeatedBackupChange',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkebackup::Logging::V1::Logging::BackupChange'->new($_) } @$_ ] };

declare 'MapStringBackupChange',
    as HashRef[BackupChange()];

declare 'RestorePlanChange',
    as InstanceOf['Google::Cloud::Gkebackup::Logging::V1::Logging::RestorePlanChange'];

coerce 'RestorePlanChange',
    from HashRef, via { 'Google::Cloud::Gkebackup::Logging::V1::Logging::RestorePlanChange'->new($_) };

declare 'RepeatedRestorePlanChange',
    as ArrayRef[RestorePlanChange()];

coerce 'RepeatedRestorePlanChange',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkebackup::Logging::V1::Logging::RestorePlanChange'->new($_) } @$_ ] };

declare 'MapStringRestorePlanChange',
    as HashRef[RestorePlanChange()];

declare 'RestoreChange',
    as InstanceOf['Google::Cloud::Gkebackup::Logging::V1::Logging::RestoreChange'];

coerce 'RestoreChange',
    from HashRef, via { 'Google::Cloud::Gkebackup::Logging::V1::Logging::RestoreChange'->new($_) };

declare 'RepeatedRestoreChange',
    as ArrayRef[RestoreChange()];

coerce 'RepeatedRestoreChange',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkebackup::Logging::V1::Logging::RestoreChange'->new($_) } @$_ ] };

declare 'MapStringRestoreChange',
    as HashRef[RestoreChange()];

declare 'BackupChannelChange',
    as InstanceOf['Google::Cloud::Gkebackup::Logging::V1::Logging::BackupChannelChange'];

coerce 'BackupChannelChange',
    from HashRef, via { 'Google::Cloud::Gkebackup::Logging::V1::Logging::BackupChannelChange'->new($_) };

declare 'RepeatedBackupChannelChange',
    as ArrayRef[BackupChannelChange()];

coerce 'RepeatedBackupChannelChange',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkebackup::Logging::V1::Logging::BackupChannelChange'->new($_) } @$_ ] };

declare 'MapStringBackupChannelChange',
    as HashRef[BackupChannelChange()];

declare 'RestoreChannelChange',
    as InstanceOf['Google::Cloud::Gkebackup::Logging::V1::Logging::RestoreChannelChange'];

coerce 'RestoreChannelChange',
    from HashRef, via { 'Google::Cloud::Gkebackup::Logging::V1::Logging::RestoreChannelChange'->new($_) };

declare 'RepeatedRestoreChannelChange',
    as ArrayRef[RestoreChannelChange()];

coerce 'RepeatedRestoreChannelChange',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkebackup::Logging::V1::Logging::RestoreChannelChange'->new($_) } @$_ ] };

declare 'MapStringRestoreChannelChange',
    as HashRef[RestoreChannelChange()];

1;

__END__

=head1 NAME

Google::Cloud::Gkebackup::Logging::V1::Logging::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
