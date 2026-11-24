package Google::Cloud::Backupdr::V1beta::BackupvaultDisk::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'DiskTargetEnvironment',
    as InstanceOf['Google::Cloud::Backupdr::V1beta::BackupvaultDisk::DiskTargetEnvironment'];

coerce 'DiskTargetEnvironment',
    from HashRef, via { 'Google::Cloud::Backupdr::V1beta::BackupvaultDisk::DiskTargetEnvironment'->new($_) };

declare 'RepeatedDiskTargetEnvironment',
    as ArrayRef[DiskTargetEnvironment()];

coerce 'RepeatedDiskTargetEnvironment',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Backupdr::V1beta::BackupvaultDisk::DiskTargetEnvironment'->new($_) } @$_ ] };

declare 'MapStringDiskTargetEnvironment',
    as HashRef[DiskTargetEnvironment()];

declare 'RegionDiskTargetEnvironment',
    as InstanceOf['Google::Cloud::Backupdr::V1beta::BackupvaultDisk::RegionDiskTargetEnvironment'];

coerce 'RegionDiskTargetEnvironment',
    from HashRef, via { 'Google::Cloud::Backupdr::V1beta::BackupvaultDisk::RegionDiskTargetEnvironment'->new($_) };

declare 'RepeatedRegionDiskTargetEnvironment',
    as ArrayRef[RegionDiskTargetEnvironment()];

coerce 'RepeatedRegionDiskTargetEnvironment',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Backupdr::V1beta::BackupvaultDisk::RegionDiskTargetEnvironment'->new($_) } @$_ ] };

declare 'MapStringRegionDiskTargetEnvironment',
    as HashRef[RegionDiskTargetEnvironment()];

declare 'DiskRestoreProperties',
    as InstanceOf['Google::Cloud::Backupdr::V1beta::BackupvaultDisk::DiskRestoreProperties'];

coerce 'DiskRestoreProperties',
    from HashRef, via { 'Google::Cloud::Backupdr::V1beta::BackupvaultDisk::DiskRestoreProperties'->new($_) };

declare 'RepeatedDiskRestoreProperties',
    as ArrayRef[DiskRestoreProperties()];

coerce 'RepeatedDiskRestoreProperties',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Backupdr::V1beta::BackupvaultDisk::DiskRestoreProperties'->new($_) } @$_ ] };

declare 'MapStringDiskRestoreProperties',
    as HashRef[DiskRestoreProperties()];

declare 'AccessMode',
    as (Int | Str);

declare 'Architecture',
    as (Int | Str);

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Backupdr::V1beta::BackupvaultDisk::DiskRestoreProperties::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Backupdr::V1beta::BackupvaultDisk::DiskRestoreProperties::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Backupdr::V1beta::BackupvaultDisk::DiskRestoreProperties::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'ResourceManagerTagsEntry',
    as InstanceOf['Google::Cloud::Backupdr::V1beta::BackupvaultDisk::DiskRestoreProperties::ResourceManagerTagsEntry'];

coerce 'ResourceManagerTagsEntry',
    from HashRef, via { 'Google::Cloud::Backupdr::V1beta::BackupvaultDisk::DiskRestoreProperties::ResourceManagerTagsEntry'->new($_) };

declare 'RepeatedResourceManagerTagsEntry',
    as ArrayRef[ResourceManagerTagsEntry()];

coerce 'RepeatedResourceManagerTagsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Backupdr::V1beta::BackupvaultDisk::DiskRestoreProperties::ResourceManagerTagsEntry'->new($_) } @$_ ] };

declare 'MapStringResourceManagerTagsEntry',
    as HashRef[ResourceManagerTagsEntry()];

declare 'RestoreDiskFromInstanceOptions',
    as InstanceOf['Google::Cloud::Backupdr::V1beta::BackupvaultDisk::RestoreDiskFromInstanceOptions'];

coerce 'RestoreDiskFromInstanceOptions',
    from HashRef, via { 'Google::Cloud::Backupdr::V1beta::BackupvaultDisk::RestoreDiskFromInstanceOptions'->new($_) };

declare 'RepeatedRestoreDiskFromInstanceOptions',
    as ArrayRef[RestoreDiskFromInstanceOptions()];

coerce 'RepeatedRestoreDiskFromInstanceOptions',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Backupdr::V1beta::BackupvaultDisk::RestoreDiskFromInstanceOptions'->new($_) } @$_ ] };

declare 'MapStringRestoreDiskFromInstanceOptions',
    as HashRef[RestoreDiskFromInstanceOptions()];

declare 'DiskBackupProperties',
    as InstanceOf['Google::Cloud::Backupdr::V1beta::BackupvaultDisk::DiskBackupProperties'];

coerce 'DiskBackupProperties',
    from HashRef, via { 'Google::Cloud::Backupdr::V1beta::BackupvaultDisk::DiskBackupProperties'->new($_) };

declare 'RepeatedDiskBackupProperties',
    as ArrayRef[DiskBackupProperties()];

coerce 'RepeatedDiskBackupProperties',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Backupdr::V1beta::BackupvaultDisk::DiskBackupProperties'->new($_) } @$_ ] };

declare 'MapStringDiskBackupProperties',
    as HashRef[DiskBackupProperties()];

declare 'Architecture',
    as (Int | Str);

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Backupdr::V1beta::BackupvaultDisk::DiskBackupProperties::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Backupdr::V1beta::BackupvaultDisk::DiskBackupProperties::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Backupdr::V1beta::BackupvaultDisk::DiskBackupProperties::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'DiskDataSourceProperties',
    as InstanceOf['Google::Cloud::Backupdr::V1beta::BackupvaultDisk::DiskDataSourceProperties'];

coerce 'DiskDataSourceProperties',
    from HashRef, via { 'Google::Cloud::Backupdr::V1beta::BackupvaultDisk::DiskDataSourceProperties'->new($_) };

declare 'RepeatedDiskDataSourceProperties',
    as ArrayRef[DiskDataSourceProperties()];

coerce 'RepeatedDiskDataSourceProperties',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Backupdr::V1beta::BackupvaultDisk::DiskDataSourceProperties'->new($_) } @$_ ] };

declare 'MapStringDiskDataSourceProperties',
    as HashRef[DiskDataSourceProperties()];

1;

__END__

=head1 NAME

Google::Cloud::Backupdr::V1beta::BackupvaultDisk::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
