package Google::Cloud::Backupdr::Logging::V1::Reportlog::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'BackupRecoveryJobReportLog',
    as InstanceOf['Google::Cloud::Backupdr::Logging::V1::Reportlog::BackupRecoveryJobReportLog'];

coerce 'BackupRecoveryJobReportLog',
    from HashRef, via { 'Google::Cloud::Backupdr::Logging::V1::Reportlog::BackupRecoveryJobReportLog'->new($_) };

declare 'RepeatedBackupRecoveryJobReportLog',
    as ArrayRef[BackupRecoveryJobReportLog()];

coerce 'RepeatedBackupRecoveryJobReportLog',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Backupdr::Logging::V1::Reportlog::BackupRecoveryJobReportLog'->new($_) } @$_ ] };

declare 'MapStringBackupRecoveryJobReportLog',
    as HashRef[BackupRecoveryJobReportLog()];

declare 'UnprotectedResourceReportLog',
    as InstanceOf['Google::Cloud::Backupdr::Logging::V1::Reportlog::UnprotectedResourceReportLog'];

coerce 'UnprotectedResourceReportLog',
    from HashRef, via { 'Google::Cloud::Backupdr::Logging::V1::Reportlog::UnprotectedResourceReportLog'->new($_) };

declare 'RepeatedUnprotectedResourceReportLog',
    as ArrayRef[UnprotectedResourceReportLog()];

coerce 'RepeatedUnprotectedResourceReportLog',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Backupdr::Logging::V1::Reportlog::UnprotectedResourceReportLog'->new($_) } @$_ ] };

declare 'MapStringUnprotectedResourceReportLog',
    as HashRef[UnprotectedResourceReportLog()];

declare 'DailyScheduleComplianceReportLog',
    as InstanceOf['Google::Cloud::Backupdr::Logging::V1::Reportlog::DailyScheduleComplianceReportLog'];

coerce 'DailyScheduleComplianceReportLog',
    from HashRef, via { 'Google::Cloud::Backupdr::Logging::V1::Reportlog::DailyScheduleComplianceReportLog'->new($_) };

declare 'RepeatedDailyScheduleComplianceReportLog',
    as ArrayRef[DailyScheduleComplianceReportLog()];

coerce 'RepeatedDailyScheduleComplianceReportLog',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Backupdr::Logging::V1::Reportlog::DailyScheduleComplianceReportLog'->new($_) } @$_ ] };

declare 'MapStringDailyScheduleComplianceReportLog',
    as HashRef[DailyScheduleComplianceReportLog()];

declare 'BackupStorageUtilizationReportLog',
    as InstanceOf['Google::Cloud::Backupdr::Logging::V1::Reportlog::BackupStorageUtilizationReportLog'];

coerce 'BackupStorageUtilizationReportLog',
    from HashRef, via { 'Google::Cloud::Backupdr::Logging::V1::Reportlog::BackupStorageUtilizationReportLog'->new($_) };

declare 'RepeatedBackupStorageUtilizationReportLog',
    as ArrayRef[BackupStorageUtilizationReportLog()];

coerce 'RepeatedBackupStorageUtilizationReportLog',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Backupdr::Logging::V1::Reportlog::BackupStorageUtilizationReportLog'->new($_) } @$_ ] };

declare 'MapStringBackupStorageUtilizationReportLog',
    as HashRef[BackupStorageUtilizationReportLog()];

declare 'ProtectedResource',
    as InstanceOf['Google::Cloud::Backupdr::Logging::V1::Reportlog::ProtectedResource'];

coerce 'ProtectedResource',
    from HashRef, via { 'Google::Cloud::Backupdr::Logging::V1::Reportlog::ProtectedResource'->new($_) };

declare 'RepeatedProtectedResource',
    as ArrayRef[ProtectedResource()];

coerce 'RepeatedProtectedResource',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Backupdr::Logging::V1::Reportlog::ProtectedResource'->new($_) } @$_ ] };

declare 'MapStringProtectedResource',
    as HashRef[ProtectedResource()];

declare 'MountedImage',
    as InstanceOf['Google::Cloud::Backupdr::Logging::V1::Reportlog::MountedImage'];

coerce 'MountedImage',
    from HashRef, via { 'Google::Cloud::Backupdr::Logging::V1::Reportlog::MountedImage'->new($_) };

declare 'RepeatedMountedImage',
    as ArrayRef[MountedImage()];

coerce 'RepeatedMountedImage',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Backupdr::Logging::V1::Reportlog::MountedImage'->new($_) } @$_ ] };

declare 'MapStringMountedImage',
    as HashRef[MountedImage()];

declare 'ConnectorVersionReportLog',
    as InstanceOf['Google::Cloud::Backupdr::Logging::V1::Reportlog::ConnectorVersionReportLog'];

coerce 'ConnectorVersionReportLog',
    from HashRef, via { 'Google::Cloud::Backupdr::Logging::V1::Reportlog::ConnectorVersionReportLog'->new($_) };

declare 'RepeatedConnectorVersionReportLog',
    as ArrayRef[ConnectorVersionReportLog()];

coerce 'RepeatedConnectorVersionReportLog',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Backupdr::Logging::V1::Reportlog::ConnectorVersionReportLog'->new($_) } @$_ ] };

declare 'MapStringConnectorVersionReportLog',
    as HashRef[ConnectorVersionReportLog()];

1;

__END__

=head1 NAME

Google::Cloud::Backupdr::Logging::V1::Reportlog::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
