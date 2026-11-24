package Google::Cloud::Databasecenter::V1beta::Signals::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'SignalStatus',
    as (Int | Str);

declare 'SignalSource',
    as (Int | Str);

declare 'IssueSeverity',
    as (Int | Str);

declare 'SignalType',
    as (Int | Str);

declare 'SignalTypeGroup',
    as InstanceOf['Google::Cloud::Databasecenter::V1beta::Signals::SignalTypeGroup'];

coerce 'SignalTypeGroup',
    from HashRef, via { 'Google::Cloud::Databasecenter::V1beta::Signals::SignalTypeGroup'->new($_) };

declare 'RepeatedSignalTypeGroup',
    as ArrayRef[SignalTypeGroup()];

coerce 'RepeatedSignalTypeGroup',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Databasecenter::V1beta::Signals::SignalTypeGroup'->new($_) } @$_ ] };

declare 'MapStringSignalTypeGroup',
    as HashRef[SignalTypeGroup()];

declare 'SignalFilter',
    as InstanceOf['Google::Cloud::Databasecenter::V1beta::Signals::SignalFilter'];

coerce 'SignalFilter',
    from HashRef, via { 'Google::Cloud::Databasecenter::V1beta::Signals::SignalFilter'->new($_) };

declare 'RepeatedSignalFilter',
    as ArrayRef[SignalFilter()];

coerce 'RepeatedSignalFilter',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Databasecenter::V1beta::Signals::SignalFilter'->new($_) } @$_ ] };

declare 'MapStringSignalFilter',
    as HashRef[SignalFilter()];

declare 'SignalGroup',
    as InstanceOf['Google::Cloud::Databasecenter::V1beta::Signals::SignalGroup'];

coerce 'SignalGroup',
    from HashRef, via { 'Google::Cloud::Databasecenter::V1beta::Signals::SignalGroup'->new($_) };

declare 'RepeatedSignalGroup',
    as ArrayRef[SignalGroup()];

coerce 'RepeatedSignalGroup',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Databasecenter::V1beta::Signals::SignalGroup'->new($_) } @$_ ] };

declare 'MapStringSignalGroup',
    as HashRef[SignalGroup()];

declare 'IssueCount',
    as InstanceOf['Google::Cloud::Databasecenter::V1beta::Signals::IssueCount'];

coerce 'IssueCount',
    from HashRef, via { 'Google::Cloud::Databasecenter::V1beta::Signals::IssueCount'->new($_) };

declare 'RepeatedIssueCount',
    as ArrayRef[IssueCount()];

coerce 'RepeatedIssueCount',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Databasecenter::V1beta::Signals::IssueCount'->new($_) } @$_ ] };

declare 'MapStringIssueCount',
    as HashRef[IssueCount()];

declare 'AdditionalDetail',
    as InstanceOf['Google::Cloud::Databasecenter::V1beta::Signals::AdditionalDetail'];

coerce 'AdditionalDetail',
    from HashRef, via { 'Google::Cloud::Databasecenter::V1beta::Signals::AdditionalDetail'->new($_) };

declare 'RepeatedAdditionalDetail',
    as ArrayRef[AdditionalDetail()];

coerce 'RepeatedAdditionalDetail',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Databasecenter::V1beta::Signals::AdditionalDetail'->new($_) } @$_ ] };

declare 'MapStringAdditionalDetail',
    as HashRef[AdditionalDetail()];

declare 'SubResource',
    as InstanceOf['Google::Cloud::Databasecenter::V1beta::Signals::SubResource'];

coerce 'SubResource',
    from HashRef, via { 'Google::Cloud::Databasecenter::V1beta::Signals::SubResource'->new($_) };

declare 'RepeatedSubResource',
    as ArrayRef[SubResource()];

coerce 'RepeatedSubResource',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Databasecenter::V1beta::Signals::SubResource'->new($_) } @$_ ] };

declare 'MapStringSubResource',
    as HashRef[SubResource()];

declare 'RetentionSettingsInfo',
    as InstanceOf['Google::Cloud::Databasecenter::V1beta::Signals::RetentionSettingsInfo'];

coerce 'RetentionSettingsInfo',
    from HashRef, via { 'Google::Cloud::Databasecenter::V1beta::Signals::RetentionSettingsInfo'->new($_) };

declare 'RepeatedRetentionSettingsInfo',
    as ArrayRef[RetentionSettingsInfo()];

coerce 'RepeatedRetentionSettingsInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Databasecenter::V1beta::Signals::RetentionSettingsInfo'->new($_) } @$_ ] };

declare 'MapStringRetentionSettingsInfo',
    as HashRef[RetentionSettingsInfo()];

declare 'AutomatedBackupPolicyInfo',
    as InstanceOf['Google::Cloud::Databasecenter::V1beta::Signals::AutomatedBackupPolicyInfo'];

coerce 'AutomatedBackupPolicyInfo',
    from HashRef, via { 'Google::Cloud::Databasecenter::V1beta::Signals::AutomatedBackupPolicyInfo'->new($_) };

declare 'RepeatedAutomatedBackupPolicyInfo',
    as ArrayRef[AutomatedBackupPolicyInfo()];

coerce 'RepeatedAutomatedBackupPolicyInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Databasecenter::V1beta::Signals::AutomatedBackupPolicyInfo'->new($_) } @$_ ] };

declare 'MapStringAutomatedBackupPolicyInfo',
    as HashRef[AutomatedBackupPolicyInfo()];

declare 'DeletionProtectionInfo',
    as InstanceOf['Google::Cloud::Databasecenter::V1beta::Signals::DeletionProtectionInfo'];

coerce 'DeletionProtectionInfo',
    from HashRef, via { 'Google::Cloud::Databasecenter::V1beta::Signals::DeletionProtectionInfo'->new($_) };

declare 'RepeatedDeletionProtectionInfo',
    as ArrayRef[DeletionProtectionInfo()];

coerce 'RepeatedDeletionProtectionInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Databasecenter::V1beta::Signals::DeletionProtectionInfo'->new($_) } @$_ ] };

declare 'MapStringDeletionProtectionInfo',
    as HashRef[DeletionProtectionInfo()];

declare 'ResourceSuspensionInfo',
    as InstanceOf['Google::Cloud::Databasecenter::V1beta::Signals::ResourceSuspensionInfo'];

coerce 'ResourceSuspensionInfo',
    from HashRef, via { 'Google::Cloud::Databasecenter::V1beta::Signals::ResourceSuspensionInfo'->new($_) };

declare 'RepeatedResourceSuspensionInfo',
    as ArrayRef[ResourceSuspensionInfo()];

coerce 'RepeatedResourceSuspensionInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Databasecenter::V1beta::Signals::ResourceSuspensionInfo'->new($_) } @$_ ] };

declare 'MapStringResourceSuspensionInfo',
    as HashRef[ResourceSuspensionInfo()];

declare 'BackupRunInfo',
    as InstanceOf['Google::Cloud::Databasecenter::V1beta::Signals::BackupRunInfo'];

coerce 'BackupRunInfo',
    from HashRef, via { 'Google::Cloud::Databasecenter::V1beta::Signals::BackupRunInfo'->new($_) };

declare 'RepeatedBackupRunInfo',
    as ArrayRef[BackupRunInfo()];

coerce 'RepeatedBackupRunInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Databasecenter::V1beta::Signals::BackupRunInfo'->new($_) } @$_ ] };

declare 'MapStringBackupRunInfo',
    as HashRef[BackupRunInfo()];

declare 'State',
    as (Int | Str);

declare 'InefficientQueryInfo',
    as InstanceOf['Google::Cloud::Databasecenter::V1beta::Signals::InefficientQueryInfo'];

coerce 'InefficientQueryInfo',
    from HashRef, via { 'Google::Cloud::Databasecenter::V1beta::Signals::InefficientQueryInfo'->new($_) };

declare 'RepeatedInefficientQueryInfo',
    as ArrayRef[InefficientQueryInfo()];

coerce 'RepeatedInefficientQueryInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Databasecenter::V1beta::Signals::InefficientQueryInfo'->new($_) } @$_ ] };

declare 'MapStringInefficientQueryInfo',
    as HashRef[InefficientQueryInfo()];

declare 'SCCInfo',
    as InstanceOf['Google::Cloud::Databasecenter::V1beta::Signals::SCCInfo'];

coerce 'SCCInfo',
    from HashRef, via { 'Google::Cloud::Databasecenter::V1beta::Signals::SCCInfo'->new($_) };

declare 'RepeatedSCCInfo',
    as ArrayRef[SCCInfo()];

coerce 'RepeatedSCCInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Databasecenter::V1beta::Signals::SCCInfo'->new($_) } @$_ ] };

declare 'MapStringSCCInfo',
    as HashRef[SCCInfo()];

declare 'RecommendationInfo',
    as InstanceOf['Google::Cloud::Databasecenter::V1beta::Signals::RecommendationInfo'];

coerce 'RecommendationInfo',
    from HashRef, via { 'Google::Cloud::Databasecenter::V1beta::Signals::RecommendationInfo'->new($_) };

declare 'RepeatedRecommendationInfo',
    as ArrayRef[RecommendationInfo()];

coerce 'RepeatedRecommendationInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Databasecenter::V1beta::Signals::RecommendationInfo'->new($_) } @$_ ] };

declare 'MapStringRecommendationInfo',
    as HashRef[RecommendationInfo()];

declare 'RegulatoryStandard',
    as InstanceOf['Google::Cloud::Databasecenter::V1beta::Signals::RegulatoryStandard'];

coerce 'RegulatoryStandard',
    from HashRef, via { 'Google::Cloud::Databasecenter::V1beta::Signals::RegulatoryStandard'->new($_) };

declare 'RepeatedRegulatoryStandard',
    as ArrayRef[RegulatoryStandard()];

coerce 'RepeatedRegulatoryStandard',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Databasecenter::V1beta::Signals::RegulatoryStandard'->new($_) } @$_ ] };

declare 'MapStringRegulatoryStandard',
    as HashRef[RegulatoryStandard()];

declare 'OutdatedMinorVersionInfo',
    as InstanceOf['Google::Cloud::Databasecenter::V1beta::Signals::OutdatedMinorVersionInfo'];

coerce 'OutdatedMinorVersionInfo',
    from HashRef, via { 'Google::Cloud::Databasecenter::V1beta::Signals::OutdatedMinorVersionInfo'->new($_) };

declare 'RepeatedOutdatedMinorVersionInfo',
    as ArrayRef[OutdatedMinorVersionInfo()];

coerce 'RepeatedOutdatedMinorVersionInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Databasecenter::V1beta::Signals::OutdatedMinorVersionInfo'->new($_) } @$_ ] };

declare 'MapStringOutdatedMinorVersionInfo',
    as HashRef[OutdatedMinorVersionInfo()];

declare 'MaintenanceRecommendationInfo',
    as InstanceOf['Google::Cloud::Databasecenter::V1beta::Signals::MaintenanceRecommendationInfo'];

coerce 'MaintenanceRecommendationInfo',
    from HashRef, via { 'Google::Cloud::Databasecenter::V1beta::Signals::MaintenanceRecommendationInfo'->new($_) };

declare 'RepeatedMaintenanceRecommendationInfo',
    as ArrayRef[MaintenanceRecommendationInfo()];

coerce 'RepeatedMaintenanceRecommendationInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Databasecenter::V1beta::Signals::MaintenanceRecommendationInfo'->new($_) } @$_ ] };

declare 'MapStringMaintenanceRecommendationInfo',
    as HashRef[MaintenanceRecommendationInfo()];

declare 'Signal',
    as InstanceOf['Google::Cloud::Databasecenter::V1beta::Signals::Signal'];

coerce 'Signal',
    from HashRef, via { 'Google::Cloud::Databasecenter::V1beta::Signals::Signal'->new($_) };

declare 'RepeatedSignal',
    as ArrayRef[Signal()];

coerce 'RepeatedSignal',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Databasecenter::V1beta::Signals::Signal'->new($_) } @$_ ] };

declare 'MapStringSignal',
    as HashRef[Signal()];

1;

__END__

=head1 NAME

Google::Cloud::Databasecenter::V1beta::Signals::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
