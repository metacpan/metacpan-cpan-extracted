package Google::Cloud::Backupdr::V1::RestoreTemplateCommon::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'BackupSelectionConfig',
    as InstanceOf['Google::Cloud::Backupdr::V1::RestoreTemplateCommon::BackupSelectionConfig'];

coerce 'BackupSelectionConfig',
    from HashRef, via { 'Google::Cloud::Backupdr::V1::RestoreTemplateCommon::BackupSelectionConfig'->new($_) };

declare 'RepeatedBackupSelectionConfig',
    as ArrayRef[BackupSelectionConfig()];

coerce 'RepeatedBackupSelectionConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Backupdr::V1::RestoreTemplateCommon::BackupSelectionConfig'->new($_) } @$_ ] };

declare 'MapStringBackupSelectionConfig',
    as HashRef[BackupSelectionConfig()];

declare 'PreRestoreConfig',
    as InstanceOf['Google::Cloud::Backupdr::V1::RestoreTemplateCommon::PreRestoreConfig'];

coerce 'PreRestoreConfig',
    from HashRef, via { 'Google::Cloud::Backupdr::V1::RestoreTemplateCommon::PreRestoreConfig'->new($_) };

declare 'RepeatedPreRestoreConfig',
    as ArrayRef[PreRestoreConfig()];

coerce 'RepeatedPreRestoreConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Backupdr::V1::RestoreTemplateCommon::PreRestoreConfig'->new($_) } @$_ ] };

declare 'MapStringPreRestoreConfig',
    as HashRef[PreRestoreConfig()];

declare 'PostRestoreConfig',
    as InstanceOf['Google::Cloud::Backupdr::V1::RestoreTemplateCommon::PostRestoreConfig'];

coerce 'PostRestoreConfig',
    from HashRef, via { 'Google::Cloud::Backupdr::V1::RestoreTemplateCommon::PostRestoreConfig'->new($_) };

declare 'RepeatedPostRestoreConfig',
    as ArrayRef[PostRestoreConfig()];

coerce 'RepeatedPostRestoreConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Backupdr::V1::RestoreTemplateCommon::PostRestoreConfig'->new($_) } @$_ ] };

declare 'MapStringPostRestoreConfig',
    as HashRef[PostRestoreConfig()];

declare 'VerificationConfig',
    as InstanceOf['Google::Cloud::Backupdr::V1::RestoreTemplateCommon::VerificationConfig'];

coerce 'VerificationConfig',
    from HashRef, via { 'Google::Cloud::Backupdr::V1::RestoreTemplateCommon::VerificationConfig'->new($_) };

declare 'RepeatedVerificationConfig',
    as ArrayRef[VerificationConfig()];

coerce 'RepeatedVerificationConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Backupdr::V1::RestoreTemplateCommon::VerificationConfig'->new($_) } @$_ ] };

declare 'MapStringVerificationConfig',
    as HashRef[VerificationConfig()];

1;

__END__

=head1 NAME

Google::Cloud::Backupdr::V1::RestoreTemplateCommon::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
