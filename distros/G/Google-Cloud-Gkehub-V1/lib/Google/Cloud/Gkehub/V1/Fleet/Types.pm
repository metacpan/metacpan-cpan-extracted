package Google::Cloud::Gkehub::V1::Fleet::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Fleet',
    as InstanceOf['Google::Cloud::Gkehub::V1::Fleet::Fleet'];

coerce 'Fleet',
    from HashRef, via { 'Google::Cloud::Gkehub::V1::Fleet::Fleet'->new($_) };

declare 'RepeatedFleet',
    as ArrayRef[Fleet()];

coerce 'RepeatedFleet',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkehub::V1::Fleet::Fleet'->new($_) } @$_ ] };

declare 'MapStringFleet',
    as HashRef[Fleet()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Gkehub::V1::Fleet::Fleet::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Gkehub::V1::Fleet::Fleet::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkehub::V1::Fleet::Fleet::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'DefaultClusterConfig',
    as InstanceOf['Google::Cloud::Gkehub::V1::Fleet::DefaultClusterConfig'];

coerce 'DefaultClusterConfig',
    from HashRef, via { 'Google::Cloud::Gkehub::V1::Fleet::DefaultClusterConfig'->new($_) };

declare 'RepeatedDefaultClusterConfig',
    as ArrayRef[DefaultClusterConfig()];

coerce 'RepeatedDefaultClusterConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkehub::V1::Fleet::DefaultClusterConfig'->new($_) } @$_ ] };

declare 'MapStringDefaultClusterConfig',
    as HashRef[DefaultClusterConfig()];

declare 'SecurityPostureConfig',
    as InstanceOf['Google::Cloud::Gkehub::V1::Fleet::SecurityPostureConfig'];

coerce 'SecurityPostureConfig',
    from HashRef, via { 'Google::Cloud::Gkehub::V1::Fleet::SecurityPostureConfig'->new($_) };

declare 'RepeatedSecurityPostureConfig',
    as ArrayRef[SecurityPostureConfig()];

coerce 'RepeatedSecurityPostureConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkehub::V1::Fleet::SecurityPostureConfig'->new($_) } @$_ ] };

declare 'MapStringSecurityPostureConfig',
    as HashRef[SecurityPostureConfig()];

declare 'Mode',
    as (Int | Str);

declare 'VulnerabilityMode',
    as (Int | Str);

declare 'BinaryAuthorizationConfig',
    as InstanceOf['Google::Cloud::Gkehub::V1::Fleet::BinaryAuthorizationConfig'];

coerce 'BinaryAuthorizationConfig',
    from HashRef, via { 'Google::Cloud::Gkehub::V1::Fleet::BinaryAuthorizationConfig'->new($_) };

declare 'RepeatedBinaryAuthorizationConfig',
    as ArrayRef[BinaryAuthorizationConfig()];

coerce 'RepeatedBinaryAuthorizationConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkehub::V1::Fleet::BinaryAuthorizationConfig'->new($_) } @$_ ] };

declare 'MapStringBinaryAuthorizationConfig',
    as HashRef[BinaryAuthorizationConfig()];

declare 'EvaluationMode',
    as (Int | Str);

declare 'PolicyBinding',
    as InstanceOf['Google::Cloud::Gkehub::V1::Fleet::BinaryAuthorizationConfig::PolicyBinding'];

coerce 'PolicyBinding',
    from HashRef, via { 'Google::Cloud::Gkehub::V1::Fleet::BinaryAuthorizationConfig::PolicyBinding'->new($_) };

declare 'RepeatedPolicyBinding',
    as ArrayRef[PolicyBinding()];

coerce 'RepeatedPolicyBinding',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkehub::V1::Fleet::BinaryAuthorizationConfig::PolicyBinding'->new($_) } @$_ ] };

declare 'MapStringPolicyBinding',
    as HashRef[PolicyBinding()];

declare 'CompliancePostureConfig',
    as InstanceOf['Google::Cloud::Gkehub::V1::Fleet::CompliancePostureConfig'];

coerce 'CompliancePostureConfig',
    from HashRef, via { 'Google::Cloud::Gkehub::V1::Fleet::CompliancePostureConfig'->new($_) };

declare 'RepeatedCompliancePostureConfig',
    as ArrayRef[CompliancePostureConfig()];

coerce 'RepeatedCompliancePostureConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkehub::V1::Fleet::CompliancePostureConfig'->new($_) } @$_ ] };

declare 'MapStringCompliancePostureConfig',
    as HashRef[CompliancePostureConfig()];

declare 'Mode',
    as (Int | Str);

declare 'ComplianceStandard',
    as InstanceOf['Google::Cloud::Gkehub::V1::Fleet::CompliancePostureConfig::ComplianceStandard'];

coerce 'ComplianceStandard',
    from HashRef, via { 'Google::Cloud::Gkehub::V1::Fleet::CompliancePostureConfig::ComplianceStandard'->new($_) };

declare 'RepeatedComplianceStandard',
    as ArrayRef[ComplianceStandard()];

coerce 'RepeatedComplianceStandard',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkehub::V1::Fleet::CompliancePostureConfig::ComplianceStandard'->new($_) } @$_ ] };

declare 'MapStringComplianceStandard',
    as HashRef[ComplianceStandard()];

declare 'FleetLifecycleState',
    as InstanceOf['Google::Cloud::Gkehub::V1::Fleet::FleetLifecycleState'];

coerce 'FleetLifecycleState',
    from HashRef, via { 'Google::Cloud::Gkehub::V1::Fleet::FleetLifecycleState'->new($_) };

declare 'RepeatedFleetLifecycleState',
    as ArrayRef[FleetLifecycleState()];

coerce 'RepeatedFleetLifecycleState',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkehub::V1::Fleet::FleetLifecycleState'->new($_) } @$_ ] };

declare 'MapStringFleetLifecycleState',
    as HashRef[FleetLifecycleState()];

declare 'Code',
    as (Int | Str);

declare 'Namespace',
    as InstanceOf['Google::Cloud::Gkehub::V1::Fleet::Namespace'];

coerce 'Namespace',
    from HashRef, via { 'Google::Cloud::Gkehub::V1::Fleet::Namespace'->new($_) };

declare 'RepeatedNamespace',
    as ArrayRef[Namespace()];

coerce 'RepeatedNamespace',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkehub::V1::Fleet::Namespace'->new($_) } @$_ ] };

declare 'MapStringNamespace',
    as HashRef[Namespace()];

declare 'NamespaceLabelsEntry',
    as InstanceOf['Google::Cloud::Gkehub::V1::Fleet::Namespace::NamespaceLabelsEntry'];

coerce 'NamespaceLabelsEntry',
    from HashRef, via { 'Google::Cloud::Gkehub::V1::Fleet::Namespace::NamespaceLabelsEntry'->new($_) };

declare 'RepeatedNamespaceLabelsEntry',
    as ArrayRef[NamespaceLabelsEntry()];

coerce 'RepeatedNamespaceLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkehub::V1::Fleet::Namespace::NamespaceLabelsEntry'->new($_) } @$_ ] };

declare 'MapStringNamespaceLabelsEntry',
    as HashRef[NamespaceLabelsEntry()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Gkehub::V1::Fleet::Namespace::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Gkehub::V1::Fleet::Namespace::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkehub::V1::Fleet::Namespace::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'NamespaceLifecycleState',
    as InstanceOf['Google::Cloud::Gkehub::V1::Fleet::NamespaceLifecycleState'];

coerce 'NamespaceLifecycleState',
    from HashRef, via { 'Google::Cloud::Gkehub::V1::Fleet::NamespaceLifecycleState'->new($_) };

declare 'RepeatedNamespaceLifecycleState',
    as ArrayRef[NamespaceLifecycleState()];

coerce 'RepeatedNamespaceLifecycleState',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkehub::V1::Fleet::NamespaceLifecycleState'->new($_) } @$_ ] };

declare 'MapStringNamespaceLifecycleState',
    as HashRef[NamespaceLifecycleState()];

declare 'Code',
    as (Int | Str);

declare 'RBACRoleBinding',
    as InstanceOf['Google::Cloud::Gkehub::V1::Fleet::RBACRoleBinding'];

coerce 'RBACRoleBinding',
    from HashRef, via { 'Google::Cloud::Gkehub::V1::Fleet::RBACRoleBinding'->new($_) };

declare 'RepeatedRBACRoleBinding',
    as ArrayRef[RBACRoleBinding()];

coerce 'RepeatedRBACRoleBinding',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkehub::V1::Fleet::RBACRoleBinding'->new($_) } @$_ ] };

declare 'MapStringRBACRoleBinding',
    as HashRef[RBACRoleBinding()];

declare 'Role',
    as InstanceOf['Google::Cloud::Gkehub::V1::Fleet::RBACRoleBinding::Role'];

coerce 'Role',
    from HashRef, via { 'Google::Cloud::Gkehub::V1::Fleet::RBACRoleBinding::Role'->new($_) };

declare 'RepeatedRole',
    as ArrayRef[Role()];

coerce 'RepeatedRole',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkehub::V1::Fleet::RBACRoleBinding::Role'->new($_) } @$_ ] };

declare 'MapStringRole',
    as HashRef[Role()];

declare 'PredefinedRoles',
    as (Int | Str);

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Gkehub::V1::Fleet::RBACRoleBinding::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Gkehub::V1::Fleet::RBACRoleBinding::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkehub::V1::Fleet::RBACRoleBinding::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'RBACRoleBindingLifecycleState',
    as InstanceOf['Google::Cloud::Gkehub::V1::Fleet::RBACRoleBindingLifecycleState'];

coerce 'RBACRoleBindingLifecycleState',
    from HashRef, via { 'Google::Cloud::Gkehub::V1::Fleet::RBACRoleBindingLifecycleState'->new($_) };

declare 'RepeatedRBACRoleBindingLifecycleState',
    as ArrayRef[RBACRoleBindingLifecycleState()];

coerce 'RepeatedRBACRoleBindingLifecycleState',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkehub::V1::Fleet::RBACRoleBindingLifecycleState'->new($_) } @$_ ] };

declare 'MapStringRBACRoleBindingLifecycleState',
    as HashRef[RBACRoleBindingLifecycleState()];

declare 'Code',
    as (Int | Str);

declare 'Scope',
    as InstanceOf['Google::Cloud::Gkehub::V1::Fleet::Scope'];

coerce 'Scope',
    from HashRef, via { 'Google::Cloud::Gkehub::V1::Fleet::Scope'->new($_) };

declare 'RepeatedScope',
    as ArrayRef[Scope()];

coerce 'RepeatedScope',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkehub::V1::Fleet::Scope'->new($_) } @$_ ] };

declare 'MapStringScope',
    as HashRef[Scope()];

declare 'NamespaceLabelsEntry',
    as InstanceOf['Google::Cloud::Gkehub::V1::Fleet::Scope::NamespaceLabelsEntry'];

coerce 'NamespaceLabelsEntry',
    from HashRef, via { 'Google::Cloud::Gkehub::V1::Fleet::Scope::NamespaceLabelsEntry'->new($_) };

declare 'RepeatedNamespaceLabelsEntry',
    as ArrayRef[NamespaceLabelsEntry()];

coerce 'RepeatedNamespaceLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkehub::V1::Fleet::Scope::NamespaceLabelsEntry'->new($_) } @$_ ] };

declare 'MapStringNamespaceLabelsEntry',
    as HashRef[NamespaceLabelsEntry()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Gkehub::V1::Fleet::Scope::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Gkehub::V1::Fleet::Scope::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkehub::V1::Fleet::Scope::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'ScopeLifecycleState',
    as InstanceOf['Google::Cloud::Gkehub::V1::Fleet::ScopeLifecycleState'];

coerce 'ScopeLifecycleState',
    from HashRef, via { 'Google::Cloud::Gkehub::V1::Fleet::ScopeLifecycleState'->new($_) };

declare 'RepeatedScopeLifecycleState',
    as ArrayRef[ScopeLifecycleState()];

coerce 'RepeatedScopeLifecycleState',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkehub::V1::Fleet::ScopeLifecycleState'->new($_) } @$_ ] };

declare 'MapStringScopeLifecycleState',
    as HashRef[ScopeLifecycleState()];

declare 'Code',
    as (Int | Str);

declare 'MembershipBinding',
    as InstanceOf['Google::Cloud::Gkehub::V1::Fleet::MembershipBinding'];

coerce 'MembershipBinding',
    from HashRef, via { 'Google::Cloud::Gkehub::V1::Fleet::MembershipBinding'->new($_) };

declare 'RepeatedMembershipBinding',
    as ArrayRef[MembershipBinding()];

coerce 'RepeatedMembershipBinding',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkehub::V1::Fleet::MembershipBinding'->new($_) } @$_ ] };

declare 'MapStringMembershipBinding',
    as HashRef[MembershipBinding()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Gkehub::V1::Fleet::MembershipBinding::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Gkehub::V1::Fleet::MembershipBinding::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkehub::V1::Fleet::MembershipBinding::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'MembershipBindingLifecycleState',
    as InstanceOf['Google::Cloud::Gkehub::V1::Fleet::MembershipBindingLifecycleState'];

coerce 'MembershipBindingLifecycleState',
    from HashRef, via { 'Google::Cloud::Gkehub::V1::Fleet::MembershipBindingLifecycleState'->new($_) };

declare 'RepeatedMembershipBindingLifecycleState',
    as ArrayRef[MembershipBindingLifecycleState()];

coerce 'RepeatedMembershipBindingLifecycleState',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkehub::V1::Fleet::MembershipBindingLifecycleState'->new($_) } @$_ ] };

declare 'MapStringMembershipBindingLifecycleState',
    as HashRef[MembershipBindingLifecycleState()];

declare 'Code',
    as (Int | Str);

1;

__END__

=head1 NAME

Google::Cloud::Gkehub::V1::Fleet::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
