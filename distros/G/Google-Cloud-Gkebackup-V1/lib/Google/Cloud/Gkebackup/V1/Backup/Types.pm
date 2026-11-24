package Google::Cloud::Gkebackup::V1::Backup::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Backup',
    as InstanceOf['Google::Cloud::Gkebackup::V1::Backup::Backup'];

coerce 'Backup',
    from HashRef, via { 'Google::Cloud::Gkebackup::V1::Backup::Backup'->new($_) };

declare 'RepeatedBackup',
    as ArrayRef[Backup()];

coerce 'RepeatedBackup',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkebackup::V1::Backup::Backup'->new($_) } @$_ ] };

declare 'MapStringBackup',
    as HashRef[Backup()];

declare 'State',
    as (Int | Str);

declare 'ClusterMetadata',
    as InstanceOf['Google::Cloud::Gkebackup::V1::Backup::Backup::ClusterMetadata'];

coerce 'ClusterMetadata',
    from HashRef, via { 'Google::Cloud::Gkebackup::V1::Backup::Backup::ClusterMetadata'->new($_) };

declare 'RepeatedClusterMetadata',
    as ArrayRef[ClusterMetadata()];

coerce 'RepeatedClusterMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkebackup::V1::Backup::Backup::ClusterMetadata'->new($_) } @$_ ] };

declare 'MapStringClusterMetadata',
    as HashRef[ClusterMetadata()];

declare 'BackupCrdVersionsEntry',
    as InstanceOf['Google::Cloud::Gkebackup::V1::Backup::Backup::ClusterMetadata::BackupCrdVersionsEntry'];

coerce 'BackupCrdVersionsEntry',
    from HashRef, via { 'Google::Cloud::Gkebackup::V1::Backup::Backup::ClusterMetadata::BackupCrdVersionsEntry'->new($_) };

declare 'RepeatedBackupCrdVersionsEntry',
    as ArrayRef[BackupCrdVersionsEntry()];

coerce 'RepeatedBackupCrdVersionsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkebackup::V1::Backup::Backup::ClusterMetadata::BackupCrdVersionsEntry'->new($_) } @$_ ] };

declare 'MapStringBackupCrdVersionsEntry',
    as HashRef[BackupCrdVersionsEntry()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Gkebackup::V1::Backup::Backup::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Gkebackup::V1::Backup::Backup::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkebackup::V1::Backup::Backup::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

1;

__END__

=head1 NAME

Google::Cloud::Gkebackup::V1::Backup::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
