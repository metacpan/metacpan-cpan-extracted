package Google::Spanner::Admin::Database::V1::Backup::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Backup',
    as InstanceOf['Google::Spanner::Admin::Database::V1::Backup::Backup'];

coerce 'Backup',
    from HashRef, via { 'Google::Spanner::Admin::Database::V1::Backup::Backup'->new($_) };

declare 'RepeatedBackup',
    as ArrayRef[Backup()];

coerce 'RepeatedBackup',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Admin::Database::V1::Backup::Backup'->new($_) } @$_ ] };

declare 'MapStringBackup',
    as HashRef[Backup()];

declare 'State',
    as (Int | Str);

declare 'CreateBackupRequest',
    as InstanceOf['Google::Spanner::Admin::Database::V1::Backup::CreateBackupRequest'];

coerce 'CreateBackupRequest',
    from HashRef, via { 'Google::Spanner::Admin::Database::V1::Backup::CreateBackupRequest'->new($_) };

declare 'RepeatedCreateBackupRequest',
    as ArrayRef[CreateBackupRequest()];

coerce 'RepeatedCreateBackupRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Admin::Database::V1::Backup::CreateBackupRequest'->new($_) } @$_ ] };

declare 'MapStringCreateBackupRequest',
    as HashRef[CreateBackupRequest()];

declare 'CreateBackupMetadata',
    as InstanceOf['Google::Spanner::Admin::Database::V1::Backup::CreateBackupMetadata'];

coerce 'CreateBackupMetadata',
    from HashRef, via { 'Google::Spanner::Admin::Database::V1::Backup::CreateBackupMetadata'->new($_) };

declare 'RepeatedCreateBackupMetadata',
    as ArrayRef[CreateBackupMetadata()];

coerce 'RepeatedCreateBackupMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Admin::Database::V1::Backup::CreateBackupMetadata'->new($_) } @$_ ] };

declare 'MapStringCreateBackupMetadata',
    as HashRef[CreateBackupMetadata()];

declare 'CopyBackupRequest',
    as InstanceOf['Google::Spanner::Admin::Database::V1::Backup::CopyBackupRequest'];

coerce 'CopyBackupRequest',
    from HashRef, via { 'Google::Spanner::Admin::Database::V1::Backup::CopyBackupRequest'->new($_) };

declare 'RepeatedCopyBackupRequest',
    as ArrayRef[CopyBackupRequest()];

coerce 'RepeatedCopyBackupRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Admin::Database::V1::Backup::CopyBackupRequest'->new($_) } @$_ ] };

declare 'MapStringCopyBackupRequest',
    as HashRef[CopyBackupRequest()];

declare 'CopyBackupMetadata',
    as InstanceOf['Google::Spanner::Admin::Database::V1::Backup::CopyBackupMetadata'];

coerce 'CopyBackupMetadata',
    from HashRef, via { 'Google::Spanner::Admin::Database::V1::Backup::CopyBackupMetadata'->new($_) };

declare 'RepeatedCopyBackupMetadata',
    as ArrayRef[CopyBackupMetadata()];

coerce 'RepeatedCopyBackupMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Admin::Database::V1::Backup::CopyBackupMetadata'->new($_) } @$_ ] };

declare 'MapStringCopyBackupMetadata',
    as HashRef[CopyBackupMetadata()];

declare 'UpdateBackupRequest',
    as InstanceOf['Google::Spanner::Admin::Database::V1::Backup::UpdateBackupRequest'];

coerce 'UpdateBackupRequest',
    from HashRef, via { 'Google::Spanner::Admin::Database::V1::Backup::UpdateBackupRequest'->new($_) };

declare 'RepeatedUpdateBackupRequest',
    as ArrayRef[UpdateBackupRequest()];

coerce 'RepeatedUpdateBackupRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Admin::Database::V1::Backup::UpdateBackupRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateBackupRequest',
    as HashRef[UpdateBackupRequest()];

declare 'GetBackupRequest',
    as InstanceOf['Google::Spanner::Admin::Database::V1::Backup::GetBackupRequest'];

coerce 'GetBackupRequest',
    from HashRef, via { 'Google::Spanner::Admin::Database::V1::Backup::GetBackupRequest'->new($_) };

declare 'RepeatedGetBackupRequest',
    as ArrayRef[GetBackupRequest()];

coerce 'RepeatedGetBackupRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Admin::Database::V1::Backup::GetBackupRequest'->new($_) } @$_ ] };

declare 'MapStringGetBackupRequest',
    as HashRef[GetBackupRequest()];

declare 'DeleteBackupRequest',
    as InstanceOf['Google::Spanner::Admin::Database::V1::Backup::DeleteBackupRequest'];

coerce 'DeleteBackupRequest',
    from HashRef, via { 'Google::Spanner::Admin::Database::V1::Backup::DeleteBackupRequest'->new($_) };

declare 'RepeatedDeleteBackupRequest',
    as ArrayRef[DeleteBackupRequest()];

coerce 'RepeatedDeleteBackupRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Admin::Database::V1::Backup::DeleteBackupRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteBackupRequest',
    as HashRef[DeleteBackupRequest()];

declare 'ListBackupsRequest',
    as InstanceOf['Google::Spanner::Admin::Database::V1::Backup::ListBackupsRequest'];

coerce 'ListBackupsRequest',
    from HashRef, via { 'Google::Spanner::Admin::Database::V1::Backup::ListBackupsRequest'->new($_) };

declare 'RepeatedListBackupsRequest',
    as ArrayRef[ListBackupsRequest()];

coerce 'RepeatedListBackupsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Admin::Database::V1::Backup::ListBackupsRequest'->new($_) } @$_ ] };

declare 'MapStringListBackupsRequest',
    as HashRef[ListBackupsRequest()];

declare 'ListBackupsResponse',
    as InstanceOf['Google::Spanner::Admin::Database::V1::Backup::ListBackupsResponse'];

coerce 'ListBackupsResponse',
    from HashRef, via { 'Google::Spanner::Admin::Database::V1::Backup::ListBackupsResponse'->new($_) };

declare 'RepeatedListBackupsResponse',
    as ArrayRef[ListBackupsResponse()];

coerce 'RepeatedListBackupsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Admin::Database::V1::Backup::ListBackupsResponse'->new($_) } @$_ ] };

declare 'MapStringListBackupsResponse',
    as HashRef[ListBackupsResponse()];

declare 'ListBackupOperationsRequest',
    as InstanceOf['Google::Spanner::Admin::Database::V1::Backup::ListBackupOperationsRequest'];

coerce 'ListBackupOperationsRequest',
    from HashRef, via { 'Google::Spanner::Admin::Database::V1::Backup::ListBackupOperationsRequest'->new($_) };

declare 'RepeatedListBackupOperationsRequest',
    as ArrayRef[ListBackupOperationsRequest()];

coerce 'RepeatedListBackupOperationsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Admin::Database::V1::Backup::ListBackupOperationsRequest'->new($_) } @$_ ] };

declare 'MapStringListBackupOperationsRequest',
    as HashRef[ListBackupOperationsRequest()];

declare 'ListBackupOperationsResponse',
    as InstanceOf['Google::Spanner::Admin::Database::V1::Backup::ListBackupOperationsResponse'];

coerce 'ListBackupOperationsResponse',
    from HashRef, via { 'Google::Spanner::Admin::Database::V1::Backup::ListBackupOperationsResponse'->new($_) };

declare 'RepeatedListBackupOperationsResponse',
    as ArrayRef[ListBackupOperationsResponse()];

coerce 'RepeatedListBackupOperationsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Admin::Database::V1::Backup::ListBackupOperationsResponse'->new($_) } @$_ ] };

declare 'MapStringListBackupOperationsResponse',
    as HashRef[ListBackupOperationsResponse()];

declare 'BackupInfo',
    as InstanceOf['Google::Spanner::Admin::Database::V1::Backup::BackupInfo'];

coerce 'BackupInfo',
    from HashRef, via { 'Google::Spanner::Admin::Database::V1::Backup::BackupInfo'->new($_) };

declare 'RepeatedBackupInfo',
    as ArrayRef[BackupInfo()];

coerce 'RepeatedBackupInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Admin::Database::V1::Backup::BackupInfo'->new($_) } @$_ ] };

declare 'MapStringBackupInfo',
    as HashRef[BackupInfo()];

declare 'CreateBackupEncryptionConfig',
    as InstanceOf['Google::Spanner::Admin::Database::V1::Backup::CreateBackupEncryptionConfig'];

coerce 'CreateBackupEncryptionConfig',
    from HashRef, via { 'Google::Spanner::Admin::Database::V1::Backup::CreateBackupEncryptionConfig'->new($_) };

declare 'RepeatedCreateBackupEncryptionConfig',
    as ArrayRef[CreateBackupEncryptionConfig()];

coerce 'RepeatedCreateBackupEncryptionConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Admin::Database::V1::Backup::CreateBackupEncryptionConfig'->new($_) } @$_ ] };

declare 'MapStringCreateBackupEncryptionConfig',
    as HashRef[CreateBackupEncryptionConfig()];

declare 'EncryptionType',
    as (Int | Str);

declare 'CopyBackupEncryptionConfig',
    as InstanceOf['Google::Spanner::Admin::Database::V1::Backup::CopyBackupEncryptionConfig'];

coerce 'CopyBackupEncryptionConfig',
    from HashRef, via { 'Google::Spanner::Admin::Database::V1::Backup::CopyBackupEncryptionConfig'->new($_) };

declare 'RepeatedCopyBackupEncryptionConfig',
    as ArrayRef[CopyBackupEncryptionConfig()];

coerce 'RepeatedCopyBackupEncryptionConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Admin::Database::V1::Backup::CopyBackupEncryptionConfig'->new($_) } @$_ ] };

declare 'MapStringCopyBackupEncryptionConfig',
    as HashRef[CopyBackupEncryptionConfig()];

declare 'EncryptionType',
    as (Int | Str);

declare 'FullBackupSpec',
    as InstanceOf['Google::Spanner::Admin::Database::V1::Backup::FullBackupSpec'];

coerce 'FullBackupSpec',
    from HashRef, via { 'Google::Spanner::Admin::Database::V1::Backup::FullBackupSpec'->new($_) };

declare 'RepeatedFullBackupSpec',
    as ArrayRef[FullBackupSpec()];

coerce 'RepeatedFullBackupSpec',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Admin::Database::V1::Backup::FullBackupSpec'->new($_) } @$_ ] };

declare 'MapStringFullBackupSpec',
    as HashRef[FullBackupSpec()];

declare 'IncrementalBackupSpec',
    as InstanceOf['Google::Spanner::Admin::Database::V1::Backup::IncrementalBackupSpec'];

coerce 'IncrementalBackupSpec',
    from HashRef, via { 'Google::Spanner::Admin::Database::V1::Backup::IncrementalBackupSpec'->new($_) };

declare 'RepeatedIncrementalBackupSpec',
    as ArrayRef[IncrementalBackupSpec()];

coerce 'RepeatedIncrementalBackupSpec',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Admin::Database::V1::Backup::IncrementalBackupSpec'->new($_) } @$_ ] };

declare 'MapStringIncrementalBackupSpec',
    as HashRef[IncrementalBackupSpec()];

declare 'BackupInstancePartition',
    as InstanceOf['Google::Spanner::Admin::Database::V1::Backup::BackupInstancePartition'];

coerce 'BackupInstancePartition',
    from HashRef, via { 'Google::Spanner::Admin::Database::V1::Backup::BackupInstancePartition'->new($_) };

declare 'RepeatedBackupInstancePartition',
    as ArrayRef[BackupInstancePartition()];

coerce 'RepeatedBackupInstancePartition',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Admin::Database::V1::Backup::BackupInstancePartition'->new($_) } @$_ ] };

declare 'MapStringBackupInstancePartition',
    as HashRef[BackupInstancePartition()];

1;

__END__

=head1 NAME

Google::Spanner::Admin::Database::V1::Backup::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
