package Google::Cloud::Netapp::V1::Backup::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Backup',
    as InstanceOf['Google::Cloud::Netapp::V1::Backup::Backup'];

coerce 'Backup',
    from HashRef, via { 'Google::Cloud::Netapp::V1::Backup::Backup'->new($_) };

declare 'RepeatedBackup',
    as ArrayRef[Backup()];

coerce 'RepeatedBackup',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Netapp::V1::Backup::Backup'->new($_) } @$_ ] };

declare 'MapStringBackup',
    as HashRef[Backup()];

declare 'State',
    as (Int | Str);

declare 'Type',
    as (Int | Str);

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Netapp::V1::Backup::Backup::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Netapp::V1::Backup::Backup::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Netapp::V1::Backup::Backup::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'ListBackupsRequest',
    as InstanceOf['Google::Cloud::Netapp::V1::Backup::ListBackupsRequest'];

coerce 'ListBackupsRequest',
    from HashRef, via { 'Google::Cloud::Netapp::V1::Backup::ListBackupsRequest'->new($_) };

declare 'RepeatedListBackupsRequest',
    as ArrayRef[ListBackupsRequest()];

coerce 'RepeatedListBackupsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Netapp::V1::Backup::ListBackupsRequest'->new($_) } @$_ ] };

declare 'MapStringListBackupsRequest',
    as HashRef[ListBackupsRequest()];

declare 'ListBackupsResponse',
    as InstanceOf['Google::Cloud::Netapp::V1::Backup::ListBackupsResponse'];

coerce 'ListBackupsResponse',
    from HashRef, via { 'Google::Cloud::Netapp::V1::Backup::ListBackupsResponse'->new($_) };

declare 'RepeatedListBackupsResponse',
    as ArrayRef[ListBackupsResponse()];

coerce 'RepeatedListBackupsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Netapp::V1::Backup::ListBackupsResponse'->new($_) } @$_ ] };

declare 'MapStringListBackupsResponse',
    as HashRef[ListBackupsResponse()];

declare 'GetBackupRequest',
    as InstanceOf['Google::Cloud::Netapp::V1::Backup::GetBackupRequest'];

coerce 'GetBackupRequest',
    from HashRef, via { 'Google::Cloud::Netapp::V1::Backup::GetBackupRequest'->new($_) };

declare 'RepeatedGetBackupRequest',
    as ArrayRef[GetBackupRequest()];

coerce 'RepeatedGetBackupRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Netapp::V1::Backup::GetBackupRequest'->new($_) } @$_ ] };

declare 'MapStringGetBackupRequest',
    as HashRef[GetBackupRequest()];

declare 'CreateBackupRequest',
    as InstanceOf['Google::Cloud::Netapp::V1::Backup::CreateBackupRequest'];

coerce 'CreateBackupRequest',
    from HashRef, via { 'Google::Cloud::Netapp::V1::Backup::CreateBackupRequest'->new($_) };

declare 'RepeatedCreateBackupRequest',
    as ArrayRef[CreateBackupRequest()];

coerce 'RepeatedCreateBackupRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Netapp::V1::Backup::CreateBackupRequest'->new($_) } @$_ ] };

declare 'MapStringCreateBackupRequest',
    as HashRef[CreateBackupRequest()];

declare 'DeleteBackupRequest',
    as InstanceOf['Google::Cloud::Netapp::V1::Backup::DeleteBackupRequest'];

coerce 'DeleteBackupRequest',
    from HashRef, via { 'Google::Cloud::Netapp::V1::Backup::DeleteBackupRequest'->new($_) };

declare 'RepeatedDeleteBackupRequest',
    as ArrayRef[DeleteBackupRequest()];

coerce 'RepeatedDeleteBackupRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Netapp::V1::Backup::DeleteBackupRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteBackupRequest',
    as HashRef[DeleteBackupRequest()];

declare 'UpdateBackupRequest',
    as InstanceOf['Google::Cloud::Netapp::V1::Backup::UpdateBackupRequest'];

coerce 'UpdateBackupRequest',
    from HashRef, via { 'Google::Cloud::Netapp::V1::Backup::UpdateBackupRequest'->new($_) };

declare 'RepeatedUpdateBackupRequest',
    as ArrayRef[UpdateBackupRequest()];

coerce 'RepeatedUpdateBackupRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Netapp::V1::Backup::UpdateBackupRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateBackupRequest',
    as HashRef[UpdateBackupRequest()];

declare 'OntapSource',
    as InstanceOf['Google::Cloud::Netapp::V1::Backup::OntapSource'];

coerce 'OntapSource',
    from HashRef, via { 'Google::Cloud::Netapp::V1::Backup::OntapSource'->new($_) };

declare 'RepeatedOntapSource',
    as ArrayRef[OntapSource()];

coerce 'RepeatedOntapSource',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Netapp::V1::Backup::OntapSource'->new($_) } @$_ ] };

declare 'MapStringOntapSource',
    as HashRef[OntapSource()];

1;

__END__

=head1 NAME

Google::Cloud::Netapp::V1::Backup::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
