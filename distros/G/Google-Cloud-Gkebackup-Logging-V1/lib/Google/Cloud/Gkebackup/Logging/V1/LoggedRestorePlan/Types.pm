package Google::Cloud::Gkebackup::Logging::V1::LoggedRestorePlan::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'LoggedRestorePlan',
    as InstanceOf['Google::Cloud::Gkebackup::Logging::V1::LoggedRestorePlan::LoggedRestorePlan'];

coerce 'LoggedRestorePlan',
    from HashRef, via { 'Google::Cloud::Gkebackup::Logging::V1::LoggedRestorePlan::LoggedRestorePlan'->new($_) };

declare 'RepeatedLoggedRestorePlan',
    as ArrayRef[LoggedRestorePlan()];

coerce 'RepeatedLoggedRestorePlan',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkebackup::Logging::V1::LoggedRestorePlan::LoggedRestorePlan'->new($_) } @$_ ] };

declare 'MapStringLoggedRestorePlan',
    as HashRef[LoggedRestorePlan()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Gkebackup::Logging::V1::LoggedRestorePlan::LoggedRestorePlan::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Gkebackup::Logging::V1::LoggedRestorePlan::LoggedRestorePlan::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkebackup::Logging::V1::LoggedRestorePlan::LoggedRestorePlan::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'RestoreConfig',
    as InstanceOf['Google::Cloud::Gkebackup::Logging::V1::LoggedRestorePlan::RestoreConfig'];

coerce 'RestoreConfig',
    from HashRef, via { 'Google::Cloud::Gkebackup::Logging::V1::LoggedRestorePlan::RestoreConfig'->new($_) };

declare 'RepeatedRestoreConfig',
    as ArrayRef[RestoreConfig()];

coerce 'RepeatedRestoreConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkebackup::Logging::V1::LoggedRestorePlan::RestoreConfig'->new($_) } @$_ ] };

declare 'MapStringRestoreConfig',
    as HashRef[RestoreConfig()];

declare 'VolumeDataRestorePolicy',
    as (Int | Str);

declare 'ClusterResourceConflictPolicy',
    as (Int | Str);

declare 'NamespacedResourceRestoreMode',
    as (Int | Str);

declare 'GroupKind',
    as InstanceOf['Google::Cloud::Gkebackup::Logging::V1::LoggedRestorePlan::RestoreConfig::GroupKind'];

coerce 'GroupKind',
    from HashRef, via { 'Google::Cloud::Gkebackup::Logging::V1::LoggedRestorePlan::RestoreConfig::GroupKind'->new($_) };

declare 'RepeatedGroupKind',
    as ArrayRef[GroupKind()];

coerce 'RepeatedGroupKind',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkebackup::Logging::V1::LoggedRestorePlan::RestoreConfig::GroupKind'->new($_) } @$_ ] };

declare 'MapStringGroupKind',
    as HashRef[GroupKind()];

declare 'ClusterResourceRestoreScope',
    as InstanceOf['Google::Cloud::Gkebackup::Logging::V1::LoggedRestorePlan::RestoreConfig::ClusterResourceRestoreScope'];

coerce 'ClusterResourceRestoreScope',
    from HashRef, via { 'Google::Cloud::Gkebackup::Logging::V1::LoggedRestorePlan::RestoreConfig::ClusterResourceRestoreScope'->new($_) };

declare 'RepeatedClusterResourceRestoreScope',
    as ArrayRef[ClusterResourceRestoreScope()];

coerce 'RepeatedClusterResourceRestoreScope',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkebackup::Logging::V1::LoggedRestorePlan::RestoreConfig::ClusterResourceRestoreScope'->new($_) } @$_ ] };

declare 'MapStringClusterResourceRestoreScope',
    as HashRef[ClusterResourceRestoreScope()];

declare 'SubstitutionRule',
    as InstanceOf['Google::Cloud::Gkebackup::Logging::V1::LoggedRestorePlan::RestoreConfig::SubstitutionRule'];

coerce 'SubstitutionRule',
    from HashRef, via { 'Google::Cloud::Gkebackup::Logging::V1::LoggedRestorePlan::RestoreConfig::SubstitutionRule'->new($_) };

declare 'RepeatedSubstitutionRule',
    as ArrayRef[SubstitutionRule()];

coerce 'RepeatedSubstitutionRule',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkebackup::Logging::V1::LoggedRestorePlan::RestoreConfig::SubstitutionRule'->new($_) } @$_ ] };

declare 'MapStringSubstitutionRule',
    as HashRef[SubstitutionRule()];

declare 'TransformationRuleAction',
    as InstanceOf['Google::Cloud::Gkebackup::Logging::V1::LoggedRestorePlan::RestoreConfig::TransformationRuleAction'];

coerce 'TransformationRuleAction',
    from HashRef, via { 'Google::Cloud::Gkebackup::Logging::V1::LoggedRestorePlan::RestoreConfig::TransformationRuleAction'->new($_) };

declare 'RepeatedTransformationRuleAction',
    as ArrayRef[TransformationRuleAction()];

coerce 'RepeatedTransformationRuleAction',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkebackup::Logging::V1::LoggedRestorePlan::RestoreConfig::TransformationRuleAction'->new($_) } @$_ ] };

declare 'MapStringTransformationRuleAction',
    as HashRef[TransformationRuleAction()];

declare 'Op',
    as (Int | Str);

declare 'ResourceFilter',
    as InstanceOf['Google::Cloud::Gkebackup::Logging::V1::LoggedRestorePlan::RestoreConfig::ResourceFilter'];

coerce 'ResourceFilter',
    from HashRef, via { 'Google::Cloud::Gkebackup::Logging::V1::LoggedRestorePlan::RestoreConfig::ResourceFilter'->new($_) };

declare 'RepeatedResourceFilter',
    as ArrayRef[ResourceFilter()];

coerce 'RepeatedResourceFilter',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkebackup::Logging::V1::LoggedRestorePlan::RestoreConfig::ResourceFilter'->new($_) } @$_ ] };

declare 'MapStringResourceFilter',
    as HashRef[ResourceFilter()];

declare 'TransformationRule',
    as InstanceOf['Google::Cloud::Gkebackup::Logging::V1::LoggedRestorePlan::RestoreConfig::TransformationRule'];

coerce 'TransformationRule',
    from HashRef, via { 'Google::Cloud::Gkebackup::Logging::V1::LoggedRestorePlan::RestoreConfig::TransformationRule'->new($_) };

declare 'RepeatedTransformationRule',
    as ArrayRef[TransformationRule()];

coerce 'RepeatedTransformationRule',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkebackup::Logging::V1::LoggedRestorePlan::RestoreConfig::TransformationRule'->new($_) } @$_ ] };

declare 'MapStringTransformationRule',
    as HashRef[TransformationRule()];

1;

__END__

=head1 NAME

Google::Cloud::Gkebackup::Logging::V1::LoggedRestorePlan::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
