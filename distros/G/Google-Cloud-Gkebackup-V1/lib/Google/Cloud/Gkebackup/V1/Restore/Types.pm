package Google::Cloud::Gkebackup::V1::Restore::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Restore',
    as InstanceOf['Google::Cloud::Gkebackup::V1::Restore::Restore'];

coerce 'Restore',
    from HashRef, via { 'Google::Cloud::Gkebackup::V1::Restore::Restore'->new($_) };

declare 'RepeatedRestore',
    as ArrayRef[Restore()];

coerce 'RepeatedRestore',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkebackup::V1::Restore::Restore'->new($_) } @$_ ] };

declare 'MapStringRestore',
    as HashRef[Restore()];

declare 'State',
    as (Int | Str);

declare 'Filter',
    as InstanceOf['Google::Cloud::Gkebackup::V1::Restore::Restore::Filter'];

coerce 'Filter',
    from HashRef, via { 'Google::Cloud::Gkebackup::V1::Restore::Restore::Filter'->new($_) };

declare 'RepeatedFilter',
    as ArrayRef[Filter()];

coerce 'RepeatedFilter',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkebackup::V1::Restore::Restore::Filter'->new($_) } @$_ ] };

declare 'MapStringFilter',
    as HashRef[Filter()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Gkebackup::V1::Restore::Restore::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Gkebackup::V1::Restore::Restore::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkebackup::V1::Restore::Restore::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'RestoreConfig',
    as InstanceOf['Google::Cloud::Gkebackup::V1::Restore::RestoreConfig'];

coerce 'RestoreConfig',
    from HashRef, via { 'Google::Cloud::Gkebackup::V1::Restore::RestoreConfig'->new($_) };

declare 'RepeatedRestoreConfig',
    as ArrayRef[RestoreConfig()];

coerce 'RepeatedRestoreConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkebackup::V1::Restore::RestoreConfig'->new($_) } @$_ ] };

declare 'MapStringRestoreConfig',
    as HashRef[RestoreConfig()];

declare 'VolumeDataRestorePolicy',
    as (Int | Str);

declare 'ClusterResourceConflictPolicy',
    as (Int | Str);

declare 'NamespacedResourceRestoreMode',
    as (Int | Str);

declare 'GroupKind',
    as InstanceOf['Google::Cloud::Gkebackup::V1::Restore::RestoreConfig::GroupKind'];

coerce 'GroupKind',
    from HashRef, via { 'Google::Cloud::Gkebackup::V1::Restore::RestoreConfig::GroupKind'->new($_) };

declare 'RepeatedGroupKind',
    as ArrayRef[GroupKind()];

coerce 'RepeatedGroupKind',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkebackup::V1::Restore::RestoreConfig::GroupKind'->new($_) } @$_ ] };

declare 'MapStringGroupKind',
    as HashRef[GroupKind()];

declare 'ClusterResourceRestoreScope',
    as InstanceOf['Google::Cloud::Gkebackup::V1::Restore::RestoreConfig::ClusterResourceRestoreScope'];

coerce 'ClusterResourceRestoreScope',
    from HashRef, via { 'Google::Cloud::Gkebackup::V1::Restore::RestoreConfig::ClusterResourceRestoreScope'->new($_) };

declare 'RepeatedClusterResourceRestoreScope',
    as ArrayRef[ClusterResourceRestoreScope()];

coerce 'RepeatedClusterResourceRestoreScope',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkebackup::V1::Restore::RestoreConfig::ClusterResourceRestoreScope'->new($_) } @$_ ] };

declare 'MapStringClusterResourceRestoreScope',
    as HashRef[ClusterResourceRestoreScope()];

declare 'SubstitutionRule',
    as InstanceOf['Google::Cloud::Gkebackup::V1::Restore::RestoreConfig::SubstitutionRule'];

coerce 'SubstitutionRule',
    from HashRef, via { 'Google::Cloud::Gkebackup::V1::Restore::RestoreConfig::SubstitutionRule'->new($_) };

declare 'RepeatedSubstitutionRule',
    as ArrayRef[SubstitutionRule()];

coerce 'RepeatedSubstitutionRule',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkebackup::V1::Restore::RestoreConfig::SubstitutionRule'->new($_) } @$_ ] };

declare 'MapStringSubstitutionRule',
    as HashRef[SubstitutionRule()];

declare 'TransformationRuleAction',
    as InstanceOf['Google::Cloud::Gkebackup::V1::Restore::RestoreConfig::TransformationRuleAction'];

coerce 'TransformationRuleAction',
    from HashRef, via { 'Google::Cloud::Gkebackup::V1::Restore::RestoreConfig::TransformationRuleAction'->new($_) };

declare 'RepeatedTransformationRuleAction',
    as ArrayRef[TransformationRuleAction()];

coerce 'RepeatedTransformationRuleAction',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkebackup::V1::Restore::RestoreConfig::TransformationRuleAction'->new($_) } @$_ ] };

declare 'MapStringTransformationRuleAction',
    as HashRef[TransformationRuleAction()];

declare 'Op',
    as (Int | Str);

declare 'ResourceFilter',
    as InstanceOf['Google::Cloud::Gkebackup::V1::Restore::RestoreConfig::ResourceFilter'];

coerce 'ResourceFilter',
    from HashRef, via { 'Google::Cloud::Gkebackup::V1::Restore::RestoreConfig::ResourceFilter'->new($_) };

declare 'RepeatedResourceFilter',
    as ArrayRef[ResourceFilter()];

coerce 'RepeatedResourceFilter',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkebackup::V1::Restore::RestoreConfig::ResourceFilter'->new($_) } @$_ ] };

declare 'MapStringResourceFilter',
    as HashRef[ResourceFilter()];

declare 'TransformationRule',
    as InstanceOf['Google::Cloud::Gkebackup::V1::Restore::RestoreConfig::TransformationRule'];

coerce 'TransformationRule',
    from HashRef, via { 'Google::Cloud::Gkebackup::V1::Restore::RestoreConfig::TransformationRule'->new($_) };

declare 'RepeatedTransformationRule',
    as ArrayRef[TransformationRule()];

coerce 'RepeatedTransformationRule',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkebackup::V1::Restore::RestoreConfig::TransformationRule'->new($_) } @$_ ] };

declare 'MapStringTransformationRule',
    as HashRef[TransformationRule()];

declare 'VolumeDataRestorePolicyBinding',
    as InstanceOf['Google::Cloud::Gkebackup::V1::Restore::RestoreConfig::VolumeDataRestorePolicyBinding'];

coerce 'VolumeDataRestorePolicyBinding',
    from HashRef, via { 'Google::Cloud::Gkebackup::V1::Restore::RestoreConfig::VolumeDataRestorePolicyBinding'->new($_) };

declare 'RepeatedVolumeDataRestorePolicyBinding',
    as ArrayRef[VolumeDataRestorePolicyBinding()];

coerce 'RepeatedVolumeDataRestorePolicyBinding',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkebackup::V1::Restore::RestoreConfig::VolumeDataRestorePolicyBinding'->new($_) } @$_ ] };

declare 'MapStringVolumeDataRestorePolicyBinding',
    as HashRef[VolumeDataRestorePolicyBinding()];

declare 'RestoreOrder',
    as InstanceOf['Google::Cloud::Gkebackup::V1::Restore::RestoreConfig::RestoreOrder'];

coerce 'RestoreOrder',
    from HashRef, via { 'Google::Cloud::Gkebackup::V1::Restore::RestoreConfig::RestoreOrder'->new($_) };

declare 'RepeatedRestoreOrder',
    as ArrayRef[RestoreOrder()];

coerce 'RepeatedRestoreOrder',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkebackup::V1::Restore::RestoreConfig::RestoreOrder'->new($_) } @$_ ] };

declare 'MapStringRestoreOrder',
    as HashRef[RestoreOrder()];

declare 'GroupKindDependency',
    as InstanceOf['Google::Cloud::Gkebackup::V1::Restore::RestoreConfig::RestoreOrder::GroupKindDependency'];

coerce 'GroupKindDependency',
    from HashRef, via { 'Google::Cloud::Gkebackup::V1::Restore::RestoreConfig::RestoreOrder::GroupKindDependency'->new($_) };

declare 'RepeatedGroupKindDependency',
    as ArrayRef[GroupKindDependency()];

coerce 'RepeatedGroupKindDependency',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkebackup::V1::Restore::RestoreConfig::RestoreOrder::GroupKindDependency'->new($_) } @$_ ] };

declare 'MapStringGroupKindDependency',
    as HashRef[GroupKindDependency()];

declare 'ResourceSelector',
    as InstanceOf['Google::Cloud::Gkebackup::V1::Restore::ResourceSelector'];

coerce 'ResourceSelector',
    from HashRef, via { 'Google::Cloud::Gkebackup::V1::Restore::ResourceSelector'->new($_) };

declare 'RepeatedResourceSelector',
    as ArrayRef[ResourceSelector()];

coerce 'RepeatedResourceSelector',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkebackup::V1::Restore::ResourceSelector'->new($_) } @$_ ] };

declare 'MapStringResourceSelector',
    as HashRef[ResourceSelector()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Gkebackup::V1::Restore::ResourceSelector::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Gkebackup::V1::Restore::ResourceSelector::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkebackup::V1::Restore::ResourceSelector::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'VolumeDataRestorePolicyOverride',
    as InstanceOf['Google::Cloud::Gkebackup::V1::Restore::VolumeDataRestorePolicyOverride'];

coerce 'VolumeDataRestorePolicyOverride',
    from HashRef, via { 'Google::Cloud::Gkebackup::V1::Restore::VolumeDataRestorePolicyOverride'->new($_) };

declare 'RepeatedVolumeDataRestorePolicyOverride',
    as ArrayRef[VolumeDataRestorePolicyOverride()];

coerce 'RepeatedVolumeDataRestorePolicyOverride',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkebackup::V1::Restore::VolumeDataRestorePolicyOverride'->new($_) } @$_ ] };

declare 'MapStringVolumeDataRestorePolicyOverride',
    as HashRef[VolumeDataRestorePolicyOverride()];

1;

__END__

=head1 NAME

Google::Cloud::Gkebackup::V1::Restore::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
