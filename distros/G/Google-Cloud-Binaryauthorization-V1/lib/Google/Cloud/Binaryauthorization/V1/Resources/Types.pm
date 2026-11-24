package Google::Cloud::Binaryauthorization::V1::Resources::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Policy',
    as InstanceOf['Google::Cloud::Binaryauthorization::V1::Resources::Policy'];

coerce 'Policy',
    from HashRef, via { 'Google::Cloud::Binaryauthorization::V1::Resources::Policy'->new($_) };

declare 'RepeatedPolicy',
    as ArrayRef[Policy()];

coerce 'RepeatedPolicy',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Binaryauthorization::V1::Resources::Policy'->new($_) } @$_ ] };

declare 'MapStringPolicy',
    as HashRef[Policy()];

declare 'GlobalPolicyEvaluationMode',
    as (Int | Str);

declare 'ClusterAdmissionRulesEntry',
    as InstanceOf['Google::Cloud::Binaryauthorization::V1::Resources::Policy::ClusterAdmissionRulesEntry'];

coerce 'ClusterAdmissionRulesEntry',
    from HashRef, via { 'Google::Cloud::Binaryauthorization::V1::Resources::Policy::ClusterAdmissionRulesEntry'->new($_) };

declare 'RepeatedClusterAdmissionRulesEntry',
    as ArrayRef[ClusterAdmissionRulesEntry()];

coerce 'RepeatedClusterAdmissionRulesEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Binaryauthorization::V1::Resources::Policy::ClusterAdmissionRulesEntry'->new($_) } @$_ ] };

declare 'MapStringClusterAdmissionRulesEntry',
    as HashRef[ClusterAdmissionRulesEntry()];

declare 'KubernetesNamespaceAdmissionRulesEntry',
    as InstanceOf['Google::Cloud::Binaryauthorization::V1::Resources::Policy::KubernetesNamespaceAdmissionRulesEntry'];

coerce 'KubernetesNamespaceAdmissionRulesEntry',
    from HashRef, via { 'Google::Cloud::Binaryauthorization::V1::Resources::Policy::KubernetesNamespaceAdmissionRulesEntry'->new($_) };

declare 'RepeatedKubernetesNamespaceAdmissionRulesEntry',
    as ArrayRef[KubernetesNamespaceAdmissionRulesEntry()];

coerce 'RepeatedKubernetesNamespaceAdmissionRulesEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Binaryauthorization::V1::Resources::Policy::KubernetesNamespaceAdmissionRulesEntry'->new($_) } @$_ ] };

declare 'MapStringKubernetesNamespaceAdmissionRulesEntry',
    as HashRef[KubernetesNamespaceAdmissionRulesEntry()];

declare 'KubernetesServiceAccountAdmissionRulesEntry',
    as InstanceOf['Google::Cloud::Binaryauthorization::V1::Resources::Policy::KubernetesServiceAccountAdmissionRulesEntry'];

coerce 'KubernetesServiceAccountAdmissionRulesEntry',
    from HashRef, via { 'Google::Cloud::Binaryauthorization::V1::Resources::Policy::KubernetesServiceAccountAdmissionRulesEntry'->new($_) };

declare 'RepeatedKubernetesServiceAccountAdmissionRulesEntry',
    as ArrayRef[KubernetesServiceAccountAdmissionRulesEntry()];

coerce 'RepeatedKubernetesServiceAccountAdmissionRulesEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Binaryauthorization::V1::Resources::Policy::KubernetesServiceAccountAdmissionRulesEntry'->new($_) } @$_ ] };

declare 'MapStringKubernetesServiceAccountAdmissionRulesEntry',
    as HashRef[KubernetesServiceAccountAdmissionRulesEntry()];

declare 'IstioServiceIdentityAdmissionRulesEntry',
    as InstanceOf['Google::Cloud::Binaryauthorization::V1::Resources::Policy::IstioServiceIdentityAdmissionRulesEntry'];

coerce 'IstioServiceIdentityAdmissionRulesEntry',
    from HashRef, via { 'Google::Cloud::Binaryauthorization::V1::Resources::Policy::IstioServiceIdentityAdmissionRulesEntry'->new($_) };

declare 'RepeatedIstioServiceIdentityAdmissionRulesEntry',
    as ArrayRef[IstioServiceIdentityAdmissionRulesEntry()];

coerce 'RepeatedIstioServiceIdentityAdmissionRulesEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Binaryauthorization::V1::Resources::Policy::IstioServiceIdentityAdmissionRulesEntry'->new($_) } @$_ ] };

declare 'MapStringIstioServiceIdentityAdmissionRulesEntry',
    as HashRef[IstioServiceIdentityAdmissionRulesEntry()];

declare 'AdmissionWhitelistPattern',
    as InstanceOf['Google::Cloud::Binaryauthorization::V1::Resources::AdmissionWhitelistPattern'];

coerce 'AdmissionWhitelistPattern',
    from HashRef, via { 'Google::Cloud::Binaryauthorization::V1::Resources::AdmissionWhitelistPattern'->new($_) };

declare 'RepeatedAdmissionWhitelistPattern',
    as ArrayRef[AdmissionWhitelistPattern()];

coerce 'RepeatedAdmissionWhitelistPattern',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Binaryauthorization::V1::Resources::AdmissionWhitelistPattern'->new($_) } @$_ ] };

declare 'MapStringAdmissionWhitelistPattern',
    as HashRef[AdmissionWhitelistPattern()];

declare 'AdmissionRule',
    as InstanceOf['Google::Cloud::Binaryauthorization::V1::Resources::AdmissionRule'];

coerce 'AdmissionRule',
    from HashRef, via { 'Google::Cloud::Binaryauthorization::V1::Resources::AdmissionRule'->new($_) };

declare 'RepeatedAdmissionRule',
    as ArrayRef[AdmissionRule()];

coerce 'RepeatedAdmissionRule',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Binaryauthorization::V1::Resources::AdmissionRule'->new($_) } @$_ ] };

declare 'MapStringAdmissionRule',
    as HashRef[AdmissionRule()];

declare 'EvaluationMode',
    as (Int | Str);

declare 'EnforcementMode',
    as (Int | Str);

declare 'Attestor',
    as InstanceOf['Google::Cloud::Binaryauthorization::V1::Resources::Attestor'];

coerce 'Attestor',
    from HashRef, via { 'Google::Cloud::Binaryauthorization::V1::Resources::Attestor'->new($_) };

declare 'RepeatedAttestor',
    as ArrayRef[Attestor()];

coerce 'RepeatedAttestor',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Binaryauthorization::V1::Resources::Attestor'->new($_) } @$_ ] };

declare 'MapStringAttestor',
    as HashRef[Attestor()];

declare 'UserOwnedGrafeasNote',
    as InstanceOf['Google::Cloud::Binaryauthorization::V1::Resources::UserOwnedGrafeasNote'];

coerce 'UserOwnedGrafeasNote',
    from HashRef, via { 'Google::Cloud::Binaryauthorization::V1::Resources::UserOwnedGrafeasNote'->new($_) };

declare 'RepeatedUserOwnedGrafeasNote',
    as ArrayRef[UserOwnedGrafeasNote()];

coerce 'RepeatedUserOwnedGrafeasNote',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Binaryauthorization::V1::Resources::UserOwnedGrafeasNote'->new($_) } @$_ ] };

declare 'MapStringUserOwnedGrafeasNote',
    as HashRef[UserOwnedGrafeasNote()];

declare 'PkixPublicKey',
    as InstanceOf['Google::Cloud::Binaryauthorization::V1::Resources::PkixPublicKey'];

coerce 'PkixPublicKey',
    from HashRef, via { 'Google::Cloud::Binaryauthorization::V1::Resources::PkixPublicKey'->new($_) };

declare 'RepeatedPkixPublicKey',
    as ArrayRef[PkixPublicKey()];

coerce 'RepeatedPkixPublicKey',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Binaryauthorization::V1::Resources::PkixPublicKey'->new($_) } @$_ ] };

declare 'MapStringPkixPublicKey',
    as HashRef[PkixPublicKey()];

declare 'SignatureAlgorithm',
    as (Int | Str);

declare 'AttestorPublicKey',
    as InstanceOf['Google::Cloud::Binaryauthorization::V1::Resources::AttestorPublicKey'];

coerce 'AttestorPublicKey',
    from HashRef, via { 'Google::Cloud::Binaryauthorization::V1::Resources::AttestorPublicKey'->new($_) };

declare 'RepeatedAttestorPublicKey',
    as ArrayRef[AttestorPublicKey()];

coerce 'RepeatedAttestorPublicKey',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Binaryauthorization::V1::Resources::AttestorPublicKey'->new($_) } @$_ ] };

declare 'MapStringAttestorPublicKey',
    as HashRef[AttestorPublicKey()];

1;

__END__

=head1 NAME

Google::Cloud::Binaryauthorization::V1::Resources::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
