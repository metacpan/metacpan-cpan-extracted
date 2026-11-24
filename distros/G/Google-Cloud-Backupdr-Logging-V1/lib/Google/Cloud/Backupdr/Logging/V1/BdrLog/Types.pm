package Google::Cloud::Backupdr::Logging::V1::BdrLog::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'BDRBackupRestoreJobLog',
    as InstanceOf['Google::Cloud::Backupdr::Logging::V1::BdrLog::BDRBackupRestoreJobLog'];

coerce 'BDRBackupRestoreJobLog',
    from HashRef, via { 'Google::Cloud::Backupdr::Logging::V1::BdrLog::BDRBackupRestoreJobLog'->new($_) };

declare 'RepeatedBDRBackupRestoreJobLog',
    as ArrayRef[BDRBackupRestoreJobLog()];

coerce 'RepeatedBDRBackupRestoreJobLog',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Backupdr::Logging::V1::BdrLog::BDRBackupRestoreJobLog'->new($_) } @$_ ] };

declare 'MapStringBDRBackupRestoreJobLog',
    as HashRef[BDRBackupRestoreJobLog()];

declare 'BDRProtectedResourceLog',
    as InstanceOf['Google::Cloud::Backupdr::Logging::V1::BdrLog::BDRProtectedResourceLog'];

coerce 'BDRProtectedResourceLog',
    from HashRef, via { 'Google::Cloud::Backupdr::Logging::V1::BdrLog::BDRProtectedResourceLog'->new($_) };

declare 'RepeatedBDRProtectedResourceLog',
    as ArrayRef[BDRProtectedResourceLog()];

coerce 'RepeatedBDRProtectedResourceLog',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Backupdr::Logging::V1::BdrLog::BDRProtectedResourceLog'->new($_) } @$_ ] };

declare 'MapStringBDRProtectedResourceLog',
    as HashRef[BDRProtectedResourceLog()];

declare 'BackupRuleDetail',
    as InstanceOf['Google::Cloud::Backupdr::Logging::V1::BdrLog::BackupRuleDetail'];

coerce 'BackupRuleDetail',
    from HashRef, via { 'Google::Cloud::Backupdr::Logging::V1::BdrLog::BackupRuleDetail'->new($_) };

declare 'RepeatedBackupRuleDetail',
    as ArrayRef[BackupRuleDetail()];

coerce 'RepeatedBackupRuleDetail',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Backupdr::Logging::V1::BdrLog::BackupRuleDetail'->new($_) } @$_ ] };

declare 'MapStringBackupRuleDetail',
    as HashRef[BackupRuleDetail()];

declare 'BDRBackupVaultDetailsLog',
    as InstanceOf['Google::Cloud::Backupdr::Logging::V1::BdrLog::BDRBackupVaultDetailsLog'];

coerce 'BDRBackupVaultDetailsLog',
    from HashRef, via { 'Google::Cloud::Backupdr::Logging::V1::BdrLog::BDRBackupVaultDetailsLog'->new($_) };

declare 'RepeatedBDRBackupVaultDetailsLog',
    as ArrayRef[BDRBackupVaultDetailsLog()];

coerce 'RepeatedBDRBackupVaultDetailsLog',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Backupdr::Logging::V1::BdrLog::BDRBackupVaultDetailsLog'->new($_) } @$_ ] };

declare 'MapStringBDRBackupVaultDetailsLog',
    as HashRef[BDRBackupVaultDetailsLog()];

declare 'BDRBackupPlanJobLog',
    as InstanceOf['Google::Cloud::Backupdr::Logging::V1::BdrLog::BDRBackupPlanJobLog'];

coerce 'BDRBackupPlanJobLog',
    from HashRef, via { 'Google::Cloud::Backupdr::Logging::V1::BdrLog::BDRBackupPlanJobLog'->new($_) };

declare 'RepeatedBDRBackupPlanJobLog',
    as ArrayRef[BDRBackupPlanJobLog()];

coerce 'RepeatedBDRBackupPlanJobLog',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Backupdr::Logging::V1::BdrLog::BDRBackupPlanJobLog'->new($_) } @$_ ] };

declare 'MapStringBDRBackupPlanJobLog',
    as HashRef[BDRBackupPlanJobLog()];

declare 'BDRBackupPlanAssociationJobLog',
    as InstanceOf['Google::Cloud::Backupdr::Logging::V1::BdrLog::BDRBackupPlanAssociationJobLog'];

coerce 'BDRBackupPlanAssociationJobLog',
    from HashRef, via { 'Google::Cloud::Backupdr::Logging::V1::BdrLog::BDRBackupPlanAssociationJobLog'->new($_) };

declare 'RepeatedBDRBackupPlanAssociationJobLog',
    as ArrayRef[BDRBackupPlanAssociationJobLog()];

coerce 'RepeatedBDRBackupPlanAssociationJobLog',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Backupdr::Logging::V1::BdrLog::BDRBackupPlanAssociationJobLog'->new($_) } @$_ ] };

declare 'MapStringBDRBackupPlanAssociationJobLog',
    as HashRef[BDRBackupPlanAssociationJobLog()];

declare 'BDRLienEventLog',
    as InstanceOf['Google::Cloud::Backupdr::Logging::V1::BdrLog::BDRLienEventLog'];

coerce 'BDRLienEventLog',
    from HashRef, via { 'Google::Cloud::Backupdr::Logging::V1::BdrLog::BDRLienEventLog'->new($_) };

declare 'RepeatedBDRLienEventLog',
    as ArrayRef[BDRLienEventLog()];

coerce 'RepeatedBDRLienEventLog',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Backupdr::Logging::V1::BdrLog::BDRLienEventLog'->new($_) } @$_ ] };

declare 'MapStringBDRLienEventLog',
    as HashRef[BDRLienEventLog()];

1;

__END__

=head1 NAME

Google::Cloud::Backupdr::Logging::V1::BdrLog::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
