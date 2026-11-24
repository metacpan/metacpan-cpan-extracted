package Google::Cloud::Gkehub::Configmanagement::V1beta::Configmanagement::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'DeploymentState',
    as (Int | Str);

declare 'MembershipState',
    as InstanceOf['Google::Cloud::Gkehub::Configmanagement::V1beta::Configmanagement::MembershipState'];

coerce 'MembershipState',
    from HashRef, via { 'Google::Cloud::Gkehub::Configmanagement::V1beta::Configmanagement::MembershipState'->new($_) };

declare 'RepeatedMembershipState',
    as ArrayRef[MembershipState()];

coerce 'RepeatedMembershipState',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkehub::Configmanagement::V1beta::Configmanagement::MembershipState'->new($_) } @$_ ] };

declare 'MapStringMembershipState',
    as HashRef[MembershipState()];

declare 'MembershipSpec',
    as InstanceOf['Google::Cloud::Gkehub::Configmanagement::V1beta::Configmanagement::MembershipSpec'];

coerce 'MembershipSpec',
    from HashRef, via { 'Google::Cloud::Gkehub::Configmanagement::V1beta::Configmanagement::MembershipSpec'->new($_) };

declare 'RepeatedMembershipSpec',
    as ArrayRef[MembershipSpec()];

coerce 'RepeatedMembershipSpec',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkehub::Configmanagement::V1beta::Configmanagement::MembershipSpec'->new($_) } @$_ ] };

declare 'MapStringMembershipSpec',
    as HashRef[MembershipSpec()];

declare 'Management',
    as (Int | Str);

declare 'ConfigSync',
    as InstanceOf['Google::Cloud::Gkehub::Configmanagement::V1beta::Configmanagement::ConfigSync'];

coerce 'ConfigSync',
    from HashRef, via { 'Google::Cloud::Gkehub::Configmanagement::V1beta::Configmanagement::ConfigSync'->new($_) };

declare 'RepeatedConfigSync',
    as ArrayRef[ConfigSync()];

coerce 'RepeatedConfigSync',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkehub::Configmanagement::V1beta::Configmanagement::ConfigSync'->new($_) } @$_ ] };

declare 'MapStringConfigSync',
    as HashRef[ConfigSync()];

declare 'DeploymentOverride',
    as InstanceOf['Google::Cloud::Gkehub::Configmanagement::V1beta::Configmanagement::DeploymentOverride'];

coerce 'DeploymentOverride',
    from HashRef, via { 'Google::Cloud::Gkehub::Configmanagement::V1beta::Configmanagement::DeploymentOverride'->new($_) };

declare 'RepeatedDeploymentOverride',
    as ArrayRef[DeploymentOverride()];

coerce 'RepeatedDeploymentOverride',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkehub::Configmanagement::V1beta::Configmanagement::DeploymentOverride'->new($_) } @$_ ] };

declare 'MapStringDeploymentOverride',
    as HashRef[DeploymentOverride()];

declare 'ContainerOverride',
    as InstanceOf['Google::Cloud::Gkehub::Configmanagement::V1beta::Configmanagement::ContainerOverride'];

coerce 'ContainerOverride',
    from HashRef, via { 'Google::Cloud::Gkehub::Configmanagement::V1beta::Configmanagement::ContainerOverride'->new($_) };

declare 'RepeatedContainerOverride',
    as ArrayRef[ContainerOverride()];

coerce 'RepeatedContainerOverride',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkehub::Configmanagement::V1beta::Configmanagement::ContainerOverride'->new($_) } @$_ ] };

declare 'MapStringContainerOverride',
    as HashRef[ContainerOverride()];

declare 'GitConfig',
    as InstanceOf['Google::Cloud::Gkehub::Configmanagement::V1beta::Configmanagement::GitConfig'];

coerce 'GitConfig',
    from HashRef, via { 'Google::Cloud::Gkehub::Configmanagement::V1beta::Configmanagement::GitConfig'->new($_) };

declare 'RepeatedGitConfig',
    as ArrayRef[GitConfig()];

coerce 'RepeatedGitConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkehub::Configmanagement::V1beta::Configmanagement::GitConfig'->new($_) } @$_ ] };

declare 'MapStringGitConfig',
    as HashRef[GitConfig()];

declare 'OciConfig',
    as InstanceOf['Google::Cloud::Gkehub::Configmanagement::V1beta::Configmanagement::OciConfig'];

coerce 'OciConfig',
    from HashRef, via { 'Google::Cloud::Gkehub::Configmanagement::V1beta::Configmanagement::OciConfig'->new($_) };

declare 'RepeatedOciConfig',
    as ArrayRef[OciConfig()];

coerce 'RepeatedOciConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkehub::Configmanagement::V1beta::Configmanagement::OciConfig'->new($_) } @$_ ] };

declare 'MapStringOciConfig',
    as HashRef[OciConfig()];

declare 'PolicyController',
    as InstanceOf['Google::Cloud::Gkehub::Configmanagement::V1beta::Configmanagement::PolicyController'];

coerce 'PolicyController',
    from HashRef, via { 'Google::Cloud::Gkehub::Configmanagement::V1beta::Configmanagement::PolicyController'->new($_) };

declare 'RepeatedPolicyController',
    as ArrayRef[PolicyController()];

coerce 'RepeatedPolicyController',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkehub::Configmanagement::V1beta::Configmanagement::PolicyController'->new($_) } @$_ ] };

declare 'MapStringPolicyController',
    as HashRef[PolicyController()];

declare 'PolicyControllerMonitoring',
    as InstanceOf['Google::Cloud::Gkehub::Configmanagement::V1beta::Configmanagement::PolicyControllerMonitoring'];

coerce 'PolicyControllerMonitoring',
    from HashRef, via { 'Google::Cloud::Gkehub::Configmanagement::V1beta::Configmanagement::PolicyControllerMonitoring'->new($_) };

declare 'RepeatedPolicyControllerMonitoring',
    as ArrayRef[PolicyControllerMonitoring()];

coerce 'RepeatedPolicyControllerMonitoring',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkehub::Configmanagement::V1beta::Configmanagement::PolicyControllerMonitoring'->new($_) } @$_ ] };

declare 'MapStringPolicyControllerMonitoring',
    as HashRef[PolicyControllerMonitoring()];

declare 'MonitoringBackend',
    as (Int | Str);

declare 'BinauthzConfig',
    as InstanceOf['Google::Cloud::Gkehub::Configmanagement::V1beta::Configmanagement::BinauthzConfig'];

coerce 'BinauthzConfig',
    from HashRef, via { 'Google::Cloud::Gkehub::Configmanagement::V1beta::Configmanagement::BinauthzConfig'->new($_) };

declare 'RepeatedBinauthzConfig',
    as ArrayRef[BinauthzConfig()];

coerce 'RepeatedBinauthzConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkehub::Configmanagement::V1beta::Configmanagement::BinauthzConfig'->new($_) } @$_ ] };

declare 'MapStringBinauthzConfig',
    as HashRef[BinauthzConfig()];

declare 'HierarchyControllerConfig',
    as InstanceOf['Google::Cloud::Gkehub::Configmanagement::V1beta::Configmanagement::HierarchyControllerConfig'];

coerce 'HierarchyControllerConfig',
    from HashRef, via { 'Google::Cloud::Gkehub::Configmanagement::V1beta::Configmanagement::HierarchyControllerConfig'->new($_) };

declare 'RepeatedHierarchyControllerConfig',
    as ArrayRef[HierarchyControllerConfig()];

coerce 'RepeatedHierarchyControllerConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkehub::Configmanagement::V1beta::Configmanagement::HierarchyControllerConfig'->new($_) } @$_ ] };

declare 'MapStringHierarchyControllerConfig',
    as HashRef[HierarchyControllerConfig()];

declare 'HierarchyControllerDeploymentState',
    as InstanceOf['Google::Cloud::Gkehub::Configmanagement::V1beta::Configmanagement::HierarchyControllerDeploymentState'];

coerce 'HierarchyControllerDeploymentState',
    from HashRef, via { 'Google::Cloud::Gkehub::Configmanagement::V1beta::Configmanagement::HierarchyControllerDeploymentState'->new($_) };

declare 'RepeatedHierarchyControllerDeploymentState',
    as ArrayRef[HierarchyControllerDeploymentState()];

coerce 'RepeatedHierarchyControllerDeploymentState',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkehub::Configmanagement::V1beta::Configmanagement::HierarchyControllerDeploymentState'->new($_) } @$_ ] };

declare 'MapStringHierarchyControllerDeploymentState',
    as HashRef[HierarchyControllerDeploymentState()];

declare 'HierarchyControllerVersion',
    as InstanceOf['Google::Cloud::Gkehub::Configmanagement::V1beta::Configmanagement::HierarchyControllerVersion'];

coerce 'HierarchyControllerVersion',
    from HashRef, via { 'Google::Cloud::Gkehub::Configmanagement::V1beta::Configmanagement::HierarchyControllerVersion'->new($_) };

declare 'RepeatedHierarchyControllerVersion',
    as ArrayRef[HierarchyControllerVersion()];

coerce 'RepeatedHierarchyControllerVersion',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkehub::Configmanagement::V1beta::Configmanagement::HierarchyControllerVersion'->new($_) } @$_ ] };

declare 'MapStringHierarchyControllerVersion',
    as HashRef[HierarchyControllerVersion()];

declare 'HierarchyControllerState',
    as InstanceOf['Google::Cloud::Gkehub::Configmanagement::V1beta::Configmanagement::HierarchyControllerState'];

coerce 'HierarchyControllerState',
    from HashRef, via { 'Google::Cloud::Gkehub::Configmanagement::V1beta::Configmanagement::HierarchyControllerState'->new($_) };

declare 'RepeatedHierarchyControllerState',
    as ArrayRef[HierarchyControllerState()];

coerce 'RepeatedHierarchyControllerState',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkehub::Configmanagement::V1beta::Configmanagement::HierarchyControllerState'->new($_) } @$_ ] };

declare 'MapStringHierarchyControllerState',
    as HashRef[HierarchyControllerState()];

declare 'OperatorState',
    as InstanceOf['Google::Cloud::Gkehub::Configmanagement::V1beta::Configmanagement::OperatorState'];

coerce 'OperatorState',
    from HashRef, via { 'Google::Cloud::Gkehub::Configmanagement::V1beta::Configmanagement::OperatorState'->new($_) };

declare 'RepeatedOperatorState',
    as ArrayRef[OperatorState()];

coerce 'RepeatedOperatorState',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkehub::Configmanagement::V1beta::Configmanagement::OperatorState'->new($_) } @$_ ] };

declare 'MapStringOperatorState',
    as HashRef[OperatorState()];

declare 'InstallError',
    as InstanceOf['Google::Cloud::Gkehub::Configmanagement::V1beta::Configmanagement::InstallError'];

coerce 'InstallError',
    from HashRef, via { 'Google::Cloud::Gkehub::Configmanagement::V1beta::Configmanagement::InstallError'->new($_) };

declare 'RepeatedInstallError',
    as ArrayRef[InstallError()];

coerce 'RepeatedInstallError',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkehub::Configmanagement::V1beta::Configmanagement::InstallError'->new($_) } @$_ ] };

declare 'MapStringInstallError',
    as HashRef[InstallError()];

declare 'ConfigSyncState',
    as InstanceOf['Google::Cloud::Gkehub::Configmanagement::V1beta::Configmanagement::ConfigSyncState'];

coerce 'ConfigSyncState',
    from HashRef, via { 'Google::Cloud::Gkehub::Configmanagement::V1beta::Configmanagement::ConfigSyncState'->new($_) };

declare 'RepeatedConfigSyncState',
    as ArrayRef[ConfigSyncState()];

coerce 'RepeatedConfigSyncState',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkehub::Configmanagement::V1beta::Configmanagement::ConfigSyncState'->new($_) } @$_ ] };

declare 'MapStringConfigSyncState',
    as HashRef[ConfigSyncState()];

declare 'CRDState',
    as (Int | Str);

declare 'State',
    as (Int | Str);

declare 'StopSyncingState',
    as (Int | Str);

declare 'ConfigSyncError',
    as InstanceOf['Google::Cloud::Gkehub::Configmanagement::V1beta::Configmanagement::ConfigSyncError'];

coerce 'ConfigSyncError',
    from HashRef, via { 'Google::Cloud::Gkehub::Configmanagement::V1beta::Configmanagement::ConfigSyncError'->new($_) };

declare 'RepeatedConfigSyncError',
    as ArrayRef[ConfigSyncError()];

coerce 'RepeatedConfigSyncError',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkehub::Configmanagement::V1beta::Configmanagement::ConfigSyncError'->new($_) } @$_ ] };

declare 'MapStringConfigSyncError',
    as HashRef[ConfigSyncError()];

declare 'ConfigSyncVersion',
    as InstanceOf['Google::Cloud::Gkehub::Configmanagement::V1beta::Configmanagement::ConfigSyncVersion'];

coerce 'ConfigSyncVersion',
    from HashRef, via { 'Google::Cloud::Gkehub::Configmanagement::V1beta::Configmanagement::ConfigSyncVersion'->new($_) };

declare 'RepeatedConfigSyncVersion',
    as ArrayRef[ConfigSyncVersion()];

coerce 'RepeatedConfigSyncVersion',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkehub::Configmanagement::V1beta::Configmanagement::ConfigSyncVersion'->new($_) } @$_ ] };

declare 'MapStringConfigSyncVersion',
    as HashRef[ConfigSyncVersion()];

declare 'ConfigSyncDeploymentState',
    as InstanceOf['Google::Cloud::Gkehub::Configmanagement::V1beta::Configmanagement::ConfigSyncDeploymentState'];

coerce 'ConfigSyncDeploymentState',
    from HashRef, via { 'Google::Cloud::Gkehub::Configmanagement::V1beta::Configmanagement::ConfigSyncDeploymentState'->new($_) };

declare 'RepeatedConfigSyncDeploymentState',
    as ArrayRef[ConfigSyncDeploymentState()];

coerce 'RepeatedConfigSyncDeploymentState',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkehub::Configmanagement::V1beta::Configmanagement::ConfigSyncDeploymentState'->new($_) } @$_ ] };

declare 'MapStringConfigSyncDeploymentState',
    as HashRef[ConfigSyncDeploymentState()];

declare 'SyncState',
    as InstanceOf['Google::Cloud::Gkehub::Configmanagement::V1beta::Configmanagement::SyncState'];

coerce 'SyncState',
    from HashRef, via { 'Google::Cloud::Gkehub::Configmanagement::V1beta::Configmanagement::SyncState'->new($_) };

declare 'RepeatedSyncState',
    as ArrayRef[SyncState()];

coerce 'RepeatedSyncState',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkehub::Configmanagement::V1beta::Configmanagement::SyncState'->new($_) } @$_ ] };

declare 'MapStringSyncState',
    as HashRef[SyncState()];

declare 'SyncCode',
    as (Int | Str);

declare 'SyncError',
    as InstanceOf['Google::Cloud::Gkehub::Configmanagement::V1beta::Configmanagement::SyncError'];

coerce 'SyncError',
    from HashRef, via { 'Google::Cloud::Gkehub::Configmanagement::V1beta::Configmanagement::SyncError'->new($_) };

declare 'RepeatedSyncError',
    as ArrayRef[SyncError()];

coerce 'RepeatedSyncError',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkehub::Configmanagement::V1beta::Configmanagement::SyncError'->new($_) } @$_ ] };

declare 'MapStringSyncError',
    as HashRef[SyncError()];

declare 'ErrorResource',
    as InstanceOf['Google::Cloud::Gkehub::Configmanagement::V1beta::Configmanagement::ErrorResource'];

coerce 'ErrorResource',
    from HashRef, via { 'Google::Cloud::Gkehub::Configmanagement::V1beta::Configmanagement::ErrorResource'->new($_) };

declare 'RepeatedErrorResource',
    as ArrayRef[ErrorResource()];

coerce 'RepeatedErrorResource',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkehub::Configmanagement::V1beta::Configmanagement::ErrorResource'->new($_) } @$_ ] };

declare 'MapStringErrorResource',
    as HashRef[ErrorResource()];

declare 'GroupVersionKind',
    as InstanceOf['Google::Cloud::Gkehub::Configmanagement::V1beta::Configmanagement::GroupVersionKind'];

coerce 'GroupVersionKind',
    from HashRef, via { 'Google::Cloud::Gkehub::Configmanagement::V1beta::Configmanagement::GroupVersionKind'->new($_) };

declare 'RepeatedGroupVersionKind',
    as ArrayRef[GroupVersionKind()];

coerce 'RepeatedGroupVersionKind',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkehub::Configmanagement::V1beta::Configmanagement::GroupVersionKind'->new($_) } @$_ ] };

declare 'MapStringGroupVersionKind',
    as HashRef[GroupVersionKind()];

declare 'PolicyControllerState',
    as InstanceOf['Google::Cloud::Gkehub::Configmanagement::V1beta::Configmanagement::PolicyControllerState'];

coerce 'PolicyControllerState',
    from HashRef, via { 'Google::Cloud::Gkehub::Configmanagement::V1beta::Configmanagement::PolicyControllerState'->new($_) };

declare 'RepeatedPolicyControllerState',
    as ArrayRef[PolicyControllerState()];

coerce 'RepeatedPolicyControllerState',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkehub::Configmanagement::V1beta::Configmanagement::PolicyControllerState'->new($_) } @$_ ] };

declare 'MapStringPolicyControllerState',
    as HashRef[PolicyControllerState()];

declare 'PolicyControllerVersion',
    as InstanceOf['Google::Cloud::Gkehub::Configmanagement::V1beta::Configmanagement::PolicyControllerVersion'];

coerce 'PolicyControllerVersion',
    from HashRef, via { 'Google::Cloud::Gkehub::Configmanagement::V1beta::Configmanagement::PolicyControllerVersion'->new($_) };

declare 'RepeatedPolicyControllerVersion',
    as ArrayRef[PolicyControllerVersion()];

coerce 'RepeatedPolicyControllerVersion',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkehub::Configmanagement::V1beta::Configmanagement::PolicyControllerVersion'->new($_) } @$_ ] };

declare 'MapStringPolicyControllerVersion',
    as HashRef[PolicyControllerVersion()];

declare 'PolicyControllerMigration',
    as InstanceOf['Google::Cloud::Gkehub::Configmanagement::V1beta::Configmanagement::PolicyControllerMigration'];

coerce 'PolicyControllerMigration',
    from HashRef, via { 'Google::Cloud::Gkehub::Configmanagement::V1beta::Configmanagement::PolicyControllerMigration'->new($_) };

declare 'RepeatedPolicyControllerMigration',
    as ArrayRef[PolicyControllerMigration()];

coerce 'RepeatedPolicyControllerMigration',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkehub::Configmanagement::V1beta::Configmanagement::PolicyControllerMigration'->new($_) } @$_ ] };

declare 'MapStringPolicyControllerMigration',
    as HashRef[PolicyControllerMigration()];

declare 'Stage',
    as (Int | Str);

declare 'BinauthzState',
    as InstanceOf['Google::Cloud::Gkehub::Configmanagement::V1beta::Configmanagement::BinauthzState'];

coerce 'BinauthzState',
    from HashRef, via { 'Google::Cloud::Gkehub::Configmanagement::V1beta::Configmanagement::BinauthzState'->new($_) };

declare 'RepeatedBinauthzState',
    as ArrayRef[BinauthzState()];

coerce 'RepeatedBinauthzState',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkehub::Configmanagement::V1beta::Configmanagement::BinauthzState'->new($_) } @$_ ] };

declare 'MapStringBinauthzState',
    as HashRef[BinauthzState()];

declare 'BinauthzVersion',
    as InstanceOf['Google::Cloud::Gkehub::Configmanagement::V1beta::Configmanagement::BinauthzVersion'];

coerce 'BinauthzVersion',
    from HashRef, via { 'Google::Cloud::Gkehub::Configmanagement::V1beta::Configmanagement::BinauthzVersion'->new($_) };

declare 'RepeatedBinauthzVersion',
    as ArrayRef[BinauthzVersion()];

coerce 'RepeatedBinauthzVersion',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkehub::Configmanagement::V1beta::Configmanagement::BinauthzVersion'->new($_) } @$_ ] };

declare 'MapStringBinauthzVersion',
    as HashRef[BinauthzVersion()];

declare 'GatekeeperDeploymentState',
    as InstanceOf['Google::Cloud::Gkehub::Configmanagement::V1beta::Configmanagement::GatekeeperDeploymentState'];

coerce 'GatekeeperDeploymentState',
    from HashRef, via { 'Google::Cloud::Gkehub::Configmanagement::V1beta::Configmanagement::GatekeeperDeploymentState'->new($_) };

declare 'RepeatedGatekeeperDeploymentState',
    as ArrayRef[GatekeeperDeploymentState()];

coerce 'RepeatedGatekeeperDeploymentState',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkehub::Configmanagement::V1beta::Configmanagement::GatekeeperDeploymentState'->new($_) } @$_ ] };

declare 'MapStringGatekeeperDeploymentState',
    as HashRef[GatekeeperDeploymentState()];

1;

__END__

=head1 NAME

Google::Cloud::Gkehub::Configmanagement::V1beta::Configmanagement::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
