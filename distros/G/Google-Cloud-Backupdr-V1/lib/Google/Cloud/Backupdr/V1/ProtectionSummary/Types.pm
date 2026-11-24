package Google::Cloud::Backupdr::V1::ProtectionSummary::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'ListResourceBackupConfigsRequest',
    as InstanceOf['Google::Cloud::Backupdr::V1::ProtectionSummary::ListResourceBackupConfigsRequest'];

coerce 'ListResourceBackupConfigsRequest',
    from HashRef, via { 'Google::Cloud::Backupdr::V1::ProtectionSummary::ListResourceBackupConfigsRequest'->new($_) };

declare 'RepeatedListResourceBackupConfigsRequest',
    as ArrayRef[ListResourceBackupConfigsRequest()];

coerce 'RepeatedListResourceBackupConfigsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Backupdr::V1::ProtectionSummary::ListResourceBackupConfigsRequest'->new($_) } @$_ ] };

declare 'MapStringListResourceBackupConfigsRequest',
    as HashRef[ListResourceBackupConfigsRequest()];

declare 'ListResourceBackupConfigsResponse',
    as InstanceOf['Google::Cloud::Backupdr::V1::ProtectionSummary::ListResourceBackupConfigsResponse'];

coerce 'ListResourceBackupConfigsResponse',
    from HashRef, via { 'Google::Cloud::Backupdr::V1::ProtectionSummary::ListResourceBackupConfigsResponse'->new($_) };

declare 'RepeatedListResourceBackupConfigsResponse',
    as ArrayRef[ListResourceBackupConfigsResponse()];

coerce 'RepeatedListResourceBackupConfigsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Backupdr::V1::ProtectionSummary::ListResourceBackupConfigsResponse'->new($_) } @$_ ] };

declare 'MapStringListResourceBackupConfigsResponse',
    as HashRef[ListResourceBackupConfigsResponse()];

declare 'ResourceBackupConfig',
    as InstanceOf['Google::Cloud::Backupdr::V1::ProtectionSummary::ResourceBackupConfig'];

coerce 'ResourceBackupConfig',
    from HashRef, via { 'Google::Cloud::Backupdr::V1::ProtectionSummary::ResourceBackupConfig'->new($_) };

declare 'RepeatedResourceBackupConfig',
    as ArrayRef[ResourceBackupConfig()];

coerce 'RepeatedResourceBackupConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Backupdr::V1::ProtectionSummary::ResourceBackupConfig'->new($_) } @$_ ] };

declare 'MapStringResourceBackupConfig',
    as HashRef[ResourceBackupConfig()];

declare 'ResourceType',
    as (Int | Str);

declare 'TargetResourceLabelsEntry',
    as InstanceOf['Google::Cloud::Backupdr::V1::ProtectionSummary::ResourceBackupConfig::TargetResourceLabelsEntry'];

coerce 'TargetResourceLabelsEntry',
    from HashRef, via { 'Google::Cloud::Backupdr::V1::ProtectionSummary::ResourceBackupConfig::TargetResourceLabelsEntry'->new($_) };

declare 'RepeatedTargetResourceLabelsEntry',
    as ArrayRef[TargetResourceLabelsEntry()];

coerce 'RepeatedTargetResourceLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Backupdr::V1::ProtectionSummary::ResourceBackupConfig::TargetResourceLabelsEntry'->new($_) } @$_ ] };

declare 'MapStringTargetResourceLabelsEntry',
    as HashRef[TargetResourceLabelsEntry()];

declare 'BackupConfigDetails',
    as InstanceOf['Google::Cloud::Backupdr::V1::ProtectionSummary::BackupConfigDetails'];

coerce 'BackupConfigDetails',
    from HashRef, via { 'Google::Cloud::Backupdr::V1::ProtectionSummary::BackupConfigDetails'->new($_) };

declare 'RepeatedBackupConfigDetails',
    as ArrayRef[BackupConfigDetails()];

coerce 'RepeatedBackupConfigDetails',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Backupdr::V1::ProtectionSummary::BackupConfigDetails'->new($_) } @$_ ] };

declare 'MapStringBackupConfigDetails',
    as HashRef[BackupConfigDetails()];

declare 'Type',
    as (Int | Str);

declare 'State',
    as (Int | Str);

declare 'PitrSettings',
    as InstanceOf['Google::Cloud::Backupdr::V1::ProtectionSummary::PitrSettings'];

coerce 'PitrSettings',
    from HashRef, via { 'Google::Cloud::Backupdr::V1::ProtectionSummary::PitrSettings'->new($_) };

declare 'RepeatedPitrSettings',
    as ArrayRef[PitrSettings()];

coerce 'RepeatedPitrSettings',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Backupdr::V1::ProtectionSummary::PitrSettings'->new($_) } @$_ ] };

declare 'MapStringPitrSettings',
    as HashRef[PitrSettings()];

declare 'BackupDrTemplateConfig',
    as InstanceOf['Google::Cloud::Backupdr::V1::ProtectionSummary::BackupDrTemplateConfig'];

coerce 'BackupDrTemplateConfig',
    from HashRef, via { 'Google::Cloud::Backupdr::V1::ProtectionSummary::BackupDrTemplateConfig'->new($_) };

declare 'RepeatedBackupDrTemplateConfig',
    as ArrayRef[BackupDrTemplateConfig()];

coerce 'RepeatedBackupDrTemplateConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Backupdr::V1::ProtectionSummary::BackupDrTemplateConfig'->new($_) } @$_ ] };

declare 'MapStringBackupDrTemplateConfig',
    as HashRef[BackupDrTemplateConfig()];

declare 'BackupDrPlanConfig',
    as InstanceOf['Google::Cloud::Backupdr::V1::ProtectionSummary::BackupDrPlanConfig'];

coerce 'BackupDrPlanConfig',
    from HashRef, via { 'Google::Cloud::Backupdr::V1::ProtectionSummary::BackupDrPlanConfig'->new($_) };

declare 'RepeatedBackupDrPlanConfig',
    as ArrayRef[BackupDrPlanConfig()];

coerce 'RepeatedBackupDrPlanConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Backupdr::V1::ProtectionSummary::BackupDrPlanConfig'->new($_) } @$_ ] };

declare 'MapStringBackupDrPlanConfig',
    as HashRef[BackupDrPlanConfig()];

declare 'BackupDrPlanRule',
    as InstanceOf['Google::Cloud::Backupdr::V1::ProtectionSummary::BackupDrPlanRule'];

coerce 'BackupDrPlanRule',
    from HashRef, via { 'Google::Cloud::Backupdr::V1::ProtectionSummary::BackupDrPlanRule'->new($_) };

declare 'RepeatedBackupDrPlanRule',
    as ArrayRef[BackupDrPlanRule()];

coerce 'RepeatedBackupDrPlanRule',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Backupdr::V1::ProtectionSummary::BackupDrPlanRule'->new($_) } @$_ ] };

declare 'MapStringBackupDrPlanRule',
    as HashRef[BackupDrPlanRule()];

declare 'BackupLocation',
    as InstanceOf['Google::Cloud::Backupdr::V1::ProtectionSummary::BackupLocation'];

coerce 'BackupLocation',
    from HashRef, via { 'Google::Cloud::Backupdr::V1::ProtectionSummary::BackupLocation'->new($_) };

declare 'RepeatedBackupLocation',
    as ArrayRef[BackupLocation()];

coerce 'RepeatedBackupLocation',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Backupdr::V1::ProtectionSummary::BackupLocation'->new($_) } @$_ ] };

declare 'MapStringBackupLocation',
    as HashRef[BackupLocation()];

declare 'Type',
    as (Int | Str);

1;

__END__

=head1 NAME

Google::Cloud::Backupdr::V1::ProtectionSummary::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
