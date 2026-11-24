package Google::Cloud::Gkehub::Policycontroller::V1beta::Policycontroller::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'MembershipState',
    as InstanceOf['Google::Cloud::Gkehub::Policycontroller::V1beta::Policycontroller::MembershipState'];

coerce 'MembershipState',
    from HashRef, via { 'Google::Cloud::Gkehub::Policycontroller::V1beta::Policycontroller::MembershipState'->new($_) };

declare 'RepeatedMembershipState',
    as ArrayRef[MembershipState()];

coerce 'RepeatedMembershipState',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkehub::Policycontroller::V1beta::Policycontroller::MembershipState'->new($_) } @$_ ] };

declare 'MapStringMembershipState',
    as HashRef[MembershipState()];

declare 'LifecycleState',
    as (Int | Str);

declare 'ComponentStatesEntry',
    as InstanceOf['Google::Cloud::Gkehub::Policycontroller::V1beta::Policycontroller::MembershipState::ComponentStatesEntry'];

coerce 'ComponentStatesEntry',
    from HashRef, via { 'Google::Cloud::Gkehub::Policycontroller::V1beta::Policycontroller::MembershipState::ComponentStatesEntry'->new($_) };

declare 'RepeatedComponentStatesEntry',
    as ArrayRef[ComponentStatesEntry()];

coerce 'RepeatedComponentStatesEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkehub::Policycontroller::V1beta::Policycontroller::MembershipState::ComponentStatesEntry'->new($_) } @$_ ] };

declare 'MapStringComponentStatesEntry',
    as HashRef[ComponentStatesEntry()];

declare 'PolicyContentState',
    as InstanceOf['Google::Cloud::Gkehub::Policycontroller::V1beta::Policycontroller::PolicyContentState'];

coerce 'PolicyContentState',
    from HashRef, via { 'Google::Cloud::Gkehub::Policycontroller::V1beta::Policycontroller::PolicyContentState'->new($_) };

declare 'RepeatedPolicyContentState',
    as ArrayRef[PolicyContentState()];

coerce 'RepeatedPolicyContentState',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkehub::Policycontroller::V1beta::Policycontroller::PolicyContentState'->new($_) } @$_ ] };

declare 'MapStringPolicyContentState',
    as HashRef[PolicyContentState()];

declare 'BundleStatesEntry',
    as InstanceOf['Google::Cloud::Gkehub::Policycontroller::V1beta::Policycontroller::PolicyContentState::BundleStatesEntry'];

coerce 'BundleStatesEntry',
    from HashRef, via { 'Google::Cloud::Gkehub::Policycontroller::V1beta::Policycontroller::PolicyContentState::BundleStatesEntry'->new($_) };

declare 'RepeatedBundleStatesEntry',
    as ArrayRef[BundleStatesEntry()];

coerce 'RepeatedBundleStatesEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkehub::Policycontroller::V1beta::Policycontroller::PolicyContentState::BundleStatesEntry'->new($_) } @$_ ] };

declare 'MapStringBundleStatesEntry',
    as HashRef[BundleStatesEntry()];

declare 'MembershipSpec',
    as InstanceOf['Google::Cloud::Gkehub::Policycontroller::V1beta::Policycontroller::MembershipSpec'];

coerce 'MembershipSpec',
    from HashRef, via { 'Google::Cloud::Gkehub::Policycontroller::V1beta::Policycontroller::MembershipSpec'->new($_) };

declare 'RepeatedMembershipSpec',
    as ArrayRef[MembershipSpec()];

coerce 'RepeatedMembershipSpec',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkehub::Policycontroller::V1beta::Policycontroller::MembershipSpec'->new($_) } @$_ ] };

declare 'MapStringMembershipSpec',
    as HashRef[MembershipSpec()];

declare 'HubConfig',
    as InstanceOf['Google::Cloud::Gkehub::Policycontroller::V1beta::Policycontroller::HubConfig'];

coerce 'HubConfig',
    from HashRef, via { 'Google::Cloud::Gkehub::Policycontroller::V1beta::Policycontroller::HubConfig'->new($_) };

declare 'RepeatedHubConfig',
    as ArrayRef[HubConfig()];

coerce 'RepeatedHubConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkehub::Policycontroller::V1beta::Policycontroller::HubConfig'->new($_) } @$_ ] };

declare 'MapStringHubConfig',
    as HashRef[HubConfig()];

declare 'InstallSpec',
    as (Int | Str);

declare 'DeploymentConfigsEntry',
    as InstanceOf['Google::Cloud::Gkehub::Policycontroller::V1beta::Policycontroller::HubConfig::DeploymentConfigsEntry'];

coerce 'DeploymentConfigsEntry',
    from HashRef, via { 'Google::Cloud::Gkehub::Policycontroller::V1beta::Policycontroller::HubConfig::DeploymentConfigsEntry'->new($_) };

declare 'RepeatedDeploymentConfigsEntry',
    as ArrayRef[DeploymentConfigsEntry()];

coerce 'RepeatedDeploymentConfigsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkehub::Policycontroller::V1beta::Policycontroller::HubConfig::DeploymentConfigsEntry'->new($_) } @$_ ] };

declare 'MapStringDeploymentConfigsEntry',
    as HashRef[DeploymentConfigsEntry()];

declare 'PolicyControllerDeploymentConfig',
    as InstanceOf['Google::Cloud::Gkehub::Policycontroller::V1beta::Policycontroller::PolicyControllerDeploymentConfig'];

coerce 'PolicyControllerDeploymentConfig',
    from HashRef, via { 'Google::Cloud::Gkehub::Policycontroller::V1beta::Policycontroller::PolicyControllerDeploymentConfig'->new($_) };

declare 'RepeatedPolicyControllerDeploymentConfig',
    as ArrayRef[PolicyControllerDeploymentConfig()];

coerce 'RepeatedPolicyControllerDeploymentConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkehub::Policycontroller::V1beta::Policycontroller::PolicyControllerDeploymentConfig'->new($_) } @$_ ] };

declare 'MapStringPolicyControllerDeploymentConfig',
    as HashRef[PolicyControllerDeploymentConfig()];

declare 'Affinity',
    as (Int | Str);

declare 'Toleration',
    as InstanceOf['Google::Cloud::Gkehub::Policycontroller::V1beta::Policycontroller::PolicyControllerDeploymentConfig::Toleration'];

coerce 'Toleration',
    from HashRef, via { 'Google::Cloud::Gkehub::Policycontroller::V1beta::Policycontroller::PolicyControllerDeploymentConfig::Toleration'->new($_) };

declare 'RepeatedToleration',
    as ArrayRef[Toleration()];

coerce 'RepeatedToleration',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkehub::Policycontroller::V1beta::Policycontroller::PolicyControllerDeploymentConfig::Toleration'->new($_) } @$_ ] };

declare 'MapStringToleration',
    as HashRef[Toleration()];

declare 'ResourceRequirements',
    as InstanceOf['Google::Cloud::Gkehub::Policycontroller::V1beta::Policycontroller::ResourceRequirements'];

coerce 'ResourceRequirements',
    from HashRef, via { 'Google::Cloud::Gkehub::Policycontroller::V1beta::Policycontroller::ResourceRequirements'->new($_) };

declare 'RepeatedResourceRequirements',
    as ArrayRef[ResourceRequirements()];

coerce 'RepeatedResourceRequirements',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkehub::Policycontroller::V1beta::Policycontroller::ResourceRequirements'->new($_) } @$_ ] };

declare 'MapStringResourceRequirements',
    as HashRef[ResourceRequirements()];

declare 'ResourceList',
    as InstanceOf['Google::Cloud::Gkehub::Policycontroller::V1beta::Policycontroller::ResourceList'];

coerce 'ResourceList',
    from HashRef, via { 'Google::Cloud::Gkehub::Policycontroller::V1beta::Policycontroller::ResourceList'->new($_) };

declare 'RepeatedResourceList',
    as ArrayRef[ResourceList()];

coerce 'RepeatedResourceList',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkehub::Policycontroller::V1beta::Policycontroller::ResourceList'->new($_) } @$_ ] };

declare 'MapStringResourceList',
    as HashRef[ResourceList()];

declare 'TemplateLibraryConfig',
    as InstanceOf['Google::Cloud::Gkehub::Policycontroller::V1beta::Policycontroller::TemplateLibraryConfig'];

coerce 'TemplateLibraryConfig',
    from HashRef, via { 'Google::Cloud::Gkehub::Policycontroller::V1beta::Policycontroller::TemplateLibraryConfig'->new($_) };

declare 'RepeatedTemplateLibraryConfig',
    as ArrayRef[TemplateLibraryConfig()];

coerce 'RepeatedTemplateLibraryConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkehub::Policycontroller::V1beta::Policycontroller::TemplateLibraryConfig'->new($_) } @$_ ] };

declare 'MapStringTemplateLibraryConfig',
    as HashRef[TemplateLibraryConfig()];

declare 'Installation',
    as (Int | Str);

declare 'MonitoringConfig',
    as InstanceOf['Google::Cloud::Gkehub::Policycontroller::V1beta::Policycontroller::MonitoringConfig'];

coerce 'MonitoringConfig',
    from HashRef, via { 'Google::Cloud::Gkehub::Policycontroller::V1beta::Policycontroller::MonitoringConfig'->new($_) };

declare 'RepeatedMonitoringConfig',
    as ArrayRef[MonitoringConfig()];

coerce 'RepeatedMonitoringConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkehub::Policycontroller::V1beta::Policycontroller::MonitoringConfig'->new($_) } @$_ ] };

declare 'MapStringMonitoringConfig',
    as HashRef[MonitoringConfig()];

declare 'MonitoringBackend',
    as (Int | Str);

declare 'OnClusterState',
    as InstanceOf['Google::Cloud::Gkehub::Policycontroller::V1beta::Policycontroller::OnClusterState'];

coerce 'OnClusterState',
    from HashRef, via { 'Google::Cloud::Gkehub::Policycontroller::V1beta::Policycontroller::OnClusterState'->new($_) };

declare 'RepeatedOnClusterState',
    as ArrayRef[OnClusterState()];

coerce 'RepeatedOnClusterState',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkehub::Policycontroller::V1beta::Policycontroller::OnClusterState'->new($_) } @$_ ] };

declare 'MapStringOnClusterState',
    as HashRef[OnClusterState()];

declare 'BundleInstallSpec',
    as InstanceOf['Google::Cloud::Gkehub::Policycontroller::V1beta::Policycontroller::BundleInstallSpec'];

coerce 'BundleInstallSpec',
    from HashRef, via { 'Google::Cloud::Gkehub::Policycontroller::V1beta::Policycontroller::BundleInstallSpec'->new($_) };

declare 'RepeatedBundleInstallSpec',
    as ArrayRef[BundleInstallSpec()];

coerce 'RepeatedBundleInstallSpec',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkehub::Policycontroller::V1beta::Policycontroller::BundleInstallSpec'->new($_) } @$_ ] };

declare 'MapStringBundleInstallSpec',
    as HashRef[BundleInstallSpec()];

declare 'PolicyContentSpec',
    as InstanceOf['Google::Cloud::Gkehub::Policycontroller::V1beta::Policycontroller::PolicyContentSpec'];

coerce 'PolicyContentSpec',
    from HashRef, via { 'Google::Cloud::Gkehub::Policycontroller::V1beta::Policycontroller::PolicyContentSpec'->new($_) };

declare 'RepeatedPolicyContentSpec',
    as ArrayRef[PolicyContentSpec()];

coerce 'RepeatedPolicyContentSpec',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkehub::Policycontroller::V1beta::Policycontroller::PolicyContentSpec'->new($_) } @$_ ] };

declare 'MapStringPolicyContentSpec',
    as HashRef[PolicyContentSpec()];

declare 'BundlesEntry',
    as InstanceOf['Google::Cloud::Gkehub::Policycontroller::V1beta::Policycontroller::PolicyContentSpec::BundlesEntry'];

coerce 'BundlesEntry',
    from HashRef, via { 'Google::Cloud::Gkehub::Policycontroller::V1beta::Policycontroller::PolicyContentSpec::BundlesEntry'->new($_) };

declare 'RepeatedBundlesEntry',
    as ArrayRef[BundlesEntry()];

coerce 'RepeatedBundlesEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkehub::Policycontroller::V1beta::Policycontroller::PolicyContentSpec::BundlesEntry'->new($_) } @$_ ] };

declare 'MapStringBundlesEntry',
    as HashRef[BundlesEntry()];

1;

__END__

=head1 NAME

Google::Cloud::Gkehub::Policycontroller::V1beta::Policycontroller::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
