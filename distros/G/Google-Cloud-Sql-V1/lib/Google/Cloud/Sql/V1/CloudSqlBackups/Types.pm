package Google::Cloud::Sql::V1::CloudSqlBackups::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'CreateBackupRequest',
    as InstanceOf['Google::Cloud::Sql::V1::CloudSqlBackups::CreateBackupRequest'];

coerce 'CreateBackupRequest',
    from HashRef, via { 'Google::Cloud::Sql::V1::CloudSqlBackups::CreateBackupRequest'->new($_) };

declare 'RepeatedCreateBackupRequest',
    as ArrayRef[CreateBackupRequest()];

coerce 'RepeatedCreateBackupRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1::CloudSqlBackups::CreateBackupRequest'->new($_) } @$_ ] };

declare 'MapStringCreateBackupRequest',
    as HashRef[CreateBackupRequest()];

declare 'GetBackupRequest',
    as InstanceOf['Google::Cloud::Sql::V1::CloudSqlBackups::GetBackupRequest'];

coerce 'GetBackupRequest',
    from HashRef, via { 'Google::Cloud::Sql::V1::CloudSqlBackups::GetBackupRequest'->new($_) };

declare 'RepeatedGetBackupRequest',
    as ArrayRef[GetBackupRequest()];

coerce 'RepeatedGetBackupRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1::CloudSqlBackups::GetBackupRequest'->new($_) } @$_ ] };

declare 'MapStringGetBackupRequest',
    as HashRef[GetBackupRequest()];

declare 'ListBackupsRequest',
    as InstanceOf['Google::Cloud::Sql::V1::CloudSqlBackups::ListBackupsRequest'];

coerce 'ListBackupsRequest',
    from HashRef, via { 'Google::Cloud::Sql::V1::CloudSqlBackups::ListBackupsRequest'->new($_) };

declare 'RepeatedListBackupsRequest',
    as ArrayRef[ListBackupsRequest()];

coerce 'RepeatedListBackupsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1::CloudSqlBackups::ListBackupsRequest'->new($_) } @$_ ] };

declare 'MapStringListBackupsRequest',
    as HashRef[ListBackupsRequest()];

declare 'ListBackupsResponse',
    as InstanceOf['Google::Cloud::Sql::V1::CloudSqlBackups::ListBackupsResponse'];

coerce 'ListBackupsResponse',
    from HashRef, via { 'Google::Cloud::Sql::V1::CloudSqlBackups::ListBackupsResponse'->new($_) };

declare 'RepeatedListBackupsResponse',
    as ArrayRef[ListBackupsResponse()];

coerce 'RepeatedListBackupsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1::CloudSqlBackups::ListBackupsResponse'->new($_) } @$_ ] };

declare 'MapStringListBackupsResponse',
    as HashRef[ListBackupsResponse()];

declare 'UpdateBackupRequest',
    as InstanceOf['Google::Cloud::Sql::V1::CloudSqlBackups::UpdateBackupRequest'];

coerce 'UpdateBackupRequest',
    from HashRef, via { 'Google::Cloud::Sql::V1::CloudSqlBackups::UpdateBackupRequest'->new($_) };

declare 'RepeatedUpdateBackupRequest',
    as ArrayRef[UpdateBackupRequest()];

coerce 'RepeatedUpdateBackupRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1::CloudSqlBackups::UpdateBackupRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateBackupRequest',
    as HashRef[UpdateBackupRequest()];

declare 'DeleteBackupRequest',
    as InstanceOf['Google::Cloud::Sql::V1::CloudSqlBackups::DeleteBackupRequest'];

coerce 'DeleteBackupRequest',
    from HashRef, via { 'Google::Cloud::Sql::V1::CloudSqlBackups::DeleteBackupRequest'->new($_) };

declare 'RepeatedDeleteBackupRequest',
    as ArrayRef[DeleteBackupRequest()];

coerce 'RepeatedDeleteBackupRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1::CloudSqlBackups::DeleteBackupRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteBackupRequest',
    as HashRef[DeleteBackupRequest()];

declare 'Backup',
    as InstanceOf['Google::Cloud::Sql::V1::CloudSqlBackups::Backup'];

coerce 'Backup',
    from HashRef, via { 'Google::Cloud::Sql::V1::CloudSqlBackups::Backup'->new($_) };

declare 'RepeatedBackup',
    as ArrayRef[Backup()];

coerce 'RepeatedBackup',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1::CloudSqlBackups::Backup'->new($_) } @$_ ] };

declare 'MapStringBackup',
    as HashRef[Backup()];

declare 'SqlBackupType',
    as (Int | Str);

declare 'SqlBackupState',
    as (Int | Str);

1;

__END__

=head1 NAME

Google::Cloud::Sql::V1::CloudSqlBackups::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
