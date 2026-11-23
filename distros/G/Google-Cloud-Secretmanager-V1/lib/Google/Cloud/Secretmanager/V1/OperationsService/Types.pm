package Google::Cloud::Secretmanager::V1::OperationsService::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'ListBackupsRequest',
    as InstanceOf['Google::Cloud::Secretmanager::V1::OperationsService::ListBackupsRequest'];

coerce 'ListBackupsRequest',
    from HashRef, via { 'Google::Cloud::Secretmanager::V1::OperationsService::ListBackupsRequest'->new($_) };

declare 'RepeatedListBackupsRequest',
    as ArrayRef[ListBackupsRequest()];

coerce 'RepeatedListBackupsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Secretmanager::V1::OperationsService::ListBackupsRequest'->new($_) } @$_ ] };

declare 'MapStringListBackupsRequest',
    as HashRef[ListBackupsRequest()];

declare 'ListBackupsResponse',
    as InstanceOf['Google::Cloud::Secretmanager::V1::OperationsService::ListBackupsResponse'];

coerce 'ListBackupsResponse',
    from HashRef, via { 'Google::Cloud::Secretmanager::V1::OperationsService::ListBackupsResponse'->new($_) };

declare 'RepeatedListBackupsResponse',
    as ArrayRef[ListBackupsResponse()];

coerce 'RepeatedListBackupsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Secretmanager::V1::OperationsService::ListBackupsResponse'->new($_) } @$_ ] };

declare 'MapStringListBackupsResponse',
    as HashRef[ListBackupsResponse()];

declare 'GetBackupRequest',
    as InstanceOf['Google::Cloud::Secretmanager::V1::OperationsService::GetBackupRequest'];

coerce 'GetBackupRequest',
    from HashRef, via { 'Google::Cloud::Secretmanager::V1::OperationsService::GetBackupRequest'->new($_) };

declare 'RepeatedGetBackupRequest',
    as ArrayRef[GetBackupRequest()];

coerce 'RepeatedGetBackupRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Secretmanager::V1::OperationsService::GetBackupRequest'->new($_) } @$_ ] };

declare 'MapStringGetBackupRequest',
    as HashRef[GetBackupRequest()];

declare 'CreateBackupRequest',
    as InstanceOf['Google::Cloud::Secretmanager::V1::OperationsService::CreateBackupRequest'];

coerce 'CreateBackupRequest',
    from HashRef, via { 'Google::Cloud::Secretmanager::V1::OperationsService::CreateBackupRequest'->new($_) };

declare 'RepeatedCreateBackupRequest',
    as ArrayRef[CreateBackupRequest()];

coerce 'RepeatedCreateBackupRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Secretmanager::V1::OperationsService::CreateBackupRequest'->new($_) } @$_ ] };

declare 'MapStringCreateBackupRequest',
    as HashRef[CreateBackupRequest()];

declare 'UpdateBackupRequest',
    as InstanceOf['Google::Cloud::Secretmanager::V1::OperationsService::UpdateBackupRequest'];

coerce 'UpdateBackupRequest',
    from HashRef, via { 'Google::Cloud::Secretmanager::V1::OperationsService::UpdateBackupRequest'->new($_) };

declare 'RepeatedUpdateBackupRequest',
    as ArrayRef[UpdateBackupRequest()];

coerce 'RepeatedUpdateBackupRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Secretmanager::V1::OperationsService::UpdateBackupRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateBackupRequest',
    as HashRef[UpdateBackupRequest()];

declare 'DeleteBackupRequest',
    as InstanceOf['Google::Cloud::Secretmanager::V1::OperationsService::DeleteBackupRequest'];

coerce 'DeleteBackupRequest',
    from HashRef, via { 'Google::Cloud::Secretmanager::V1::OperationsService::DeleteBackupRequest'->new($_) };

declare 'RepeatedDeleteBackupRequest',
    as ArrayRef[DeleteBackupRequest()];

coerce 'RepeatedDeleteBackupRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Secretmanager::V1::OperationsService::DeleteBackupRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteBackupRequest',
    as HashRef[DeleteBackupRequest()];

declare 'RestoreBackupRequest',
    as InstanceOf['Google::Cloud::Secretmanager::V1::OperationsService::RestoreBackupRequest'];

coerce 'RestoreBackupRequest',
    from HashRef, via { 'Google::Cloud::Secretmanager::V1::OperationsService::RestoreBackupRequest'->new($_) };

declare 'RepeatedRestoreBackupRequest',
    as ArrayRef[RestoreBackupRequest()];

coerce 'RepeatedRestoreBackupRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Secretmanager::V1::OperationsService::RestoreBackupRequest'->new($_) } @$_ ] };

declare 'MapStringRestoreBackupRequest',
    as HashRef[RestoreBackupRequest()];

declare 'OperationMetadata',
    as InstanceOf['Google::Cloud::Secretmanager::V1::OperationsService::OperationMetadata'];

coerce 'OperationMetadata',
    from HashRef, via { 'Google::Cloud::Secretmanager::V1::OperationsService::OperationMetadata'->new($_) };

declare 'RepeatedOperationMetadata',
    as ArrayRef[OperationMetadata()];

coerce 'RepeatedOperationMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Secretmanager::V1::OperationsService::OperationMetadata'->new($_) } @$_ ] };

declare 'MapStringOperationMetadata',
    as HashRef[OperationMetadata()];

declare 'Progress',
    as InstanceOf['Google::Cloud::Secretmanager::V1::OperationsService::OperationMetadata::Progress'];

coerce 'Progress',
    from HashRef, via { 'Google::Cloud::Secretmanager::V1::OperationsService::OperationMetadata::Progress'->new($_) };

declare 'RepeatedProgress',
    as ArrayRef[Progress()];

coerce 'RepeatedProgress',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Secretmanager::V1::OperationsService::OperationMetadata::Progress'->new($_) } @$_ ] };

declare 'MapStringProgress',
    as HashRef[Progress()];

declare 'Backup',
    as InstanceOf['Google::Cloud::Secretmanager::V1::OperationsService::Backup'];

coerce 'Backup',
    from HashRef, via { 'Google::Cloud::Secretmanager::V1::OperationsService::Backup'->new($_) };

declare 'RepeatedBackup',
    as ArrayRef[Backup()];

coerce 'RepeatedBackup',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Secretmanager::V1::OperationsService::Backup'->new($_) } @$_ ] };

declare 'MapStringBackup',
    as HashRef[Backup()];

declare 'State',
    as (Int | Str);

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Secretmanager::V1::OperationsService::Backup::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Secretmanager::V1::OperationsService::Backup::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Secretmanager::V1::OperationsService::Backup::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

1;

__END__

=head1 NAME

Google::Cloud::Secretmanager::V1::OperationsService::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
