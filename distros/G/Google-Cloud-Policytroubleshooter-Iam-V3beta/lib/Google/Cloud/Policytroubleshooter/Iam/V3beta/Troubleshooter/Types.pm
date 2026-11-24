package Google::Cloud::Policytroubleshooter::Iam::V3beta::Troubleshooter::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'AllowAccessState',
    as (Int | Str);

declare 'DenyAccessState',
    as (Int | Str);

declare 'RolePermissionInclusionState',
    as (Int | Str);

declare 'PermissionPatternMatchingState',
    as (Int | Str);

declare 'MembershipMatchingState',
    as (Int | Str);

declare 'HeuristicRelevance',
    as (Int | Str);

declare 'TroubleshootIamPolicyRequest',
    as InstanceOf['Google::Cloud::Policytroubleshooter::Iam::V3beta::Troubleshooter::TroubleshootIamPolicyRequest'];

coerce 'TroubleshootIamPolicyRequest',
    from HashRef, via { 'Google::Cloud::Policytroubleshooter::Iam::V3beta::Troubleshooter::TroubleshootIamPolicyRequest'->new($_) };

declare 'RepeatedTroubleshootIamPolicyRequest',
    as ArrayRef[TroubleshootIamPolicyRequest()];

coerce 'RepeatedTroubleshootIamPolicyRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Policytroubleshooter::Iam::V3beta::Troubleshooter::TroubleshootIamPolicyRequest'->new($_) } @$_ ] };

declare 'MapStringTroubleshootIamPolicyRequest',
    as HashRef[TroubleshootIamPolicyRequest()];

declare 'TroubleshootIamPolicyResponse',
    as InstanceOf['Google::Cloud::Policytroubleshooter::Iam::V3beta::Troubleshooter::TroubleshootIamPolicyResponse'];

coerce 'TroubleshootIamPolicyResponse',
    from HashRef, via { 'Google::Cloud::Policytroubleshooter::Iam::V3beta::Troubleshooter::TroubleshootIamPolicyResponse'->new($_) };

declare 'RepeatedTroubleshootIamPolicyResponse',
    as ArrayRef[TroubleshootIamPolicyResponse()];

coerce 'RepeatedTroubleshootIamPolicyResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Policytroubleshooter::Iam::V3beta::Troubleshooter::TroubleshootIamPolicyResponse'->new($_) } @$_ ] };

declare 'MapStringTroubleshootIamPolicyResponse',
    as HashRef[TroubleshootIamPolicyResponse()];

declare 'OverallAccessState',
    as (Int | Str);

declare 'AccessTuple',
    as InstanceOf['Google::Cloud::Policytroubleshooter::Iam::V3beta::Troubleshooter::AccessTuple'];

coerce 'AccessTuple',
    from HashRef, via { 'Google::Cloud::Policytroubleshooter::Iam::V3beta::Troubleshooter::AccessTuple'->new($_) };

declare 'RepeatedAccessTuple',
    as ArrayRef[AccessTuple()];

coerce 'RepeatedAccessTuple',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Policytroubleshooter::Iam::V3beta::Troubleshooter::AccessTuple'->new($_) } @$_ ] };

declare 'MapStringAccessTuple',
    as HashRef[AccessTuple()];

declare 'ConditionContext',
    as InstanceOf['Google::Cloud::Policytroubleshooter::Iam::V3beta::Troubleshooter::ConditionContext'];

coerce 'ConditionContext',
    from HashRef, via { 'Google::Cloud::Policytroubleshooter::Iam::V3beta::Troubleshooter::ConditionContext'->new($_) };

declare 'RepeatedConditionContext',
    as ArrayRef[ConditionContext()];

coerce 'RepeatedConditionContext',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Policytroubleshooter::Iam::V3beta::Troubleshooter::ConditionContext'->new($_) } @$_ ] };

declare 'MapStringConditionContext',
    as HashRef[ConditionContext()];

declare 'Resource',
    as InstanceOf['Google::Cloud::Policytroubleshooter::Iam::V3beta::Troubleshooter::ConditionContext::Resource'];

coerce 'Resource',
    from HashRef, via { 'Google::Cloud::Policytroubleshooter::Iam::V3beta::Troubleshooter::ConditionContext::Resource'->new($_) };

declare 'RepeatedResource',
    as ArrayRef[Resource()];

coerce 'RepeatedResource',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Policytroubleshooter::Iam::V3beta::Troubleshooter::ConditionContext::Resource'->new($_) } @$_ ] };

declare 'MapStringResource',
    as HashRef[Resource()];

declare 'Peer',
    as InstanceOf['Google::Cloud::Policytroubleshooter::Iam::V3beta::Troubleshooter::ConditionContext::Peer'];

coerce 'Peer',
    from HashRef, via { 'Google::Cloud::Policytroubleshooter::Iam::V3beta::Troubleshooter::ConditionContext::Peer'->new($_) };

declare 'RepeatedPeer',
    as ArrayRef[Peer()];

coerce 'RepeatedPeer',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Policytroubleshooter::Iam::V3beta::Troubleshooter::ConditionContext::Peer'->new($_) } @$_ ] };

declare 'MapStringPeer',
    as HashRef[Peer()];

declare 'Request',
    as InstanceOf['Google::Cloud::Policytroubleshooter::Iam::V3beta::Troubleshooter::ConditionContext::Request'];

coerce 'Request',
    from HashRef, via { 'Google::Cloud::Policytroubleshooter::Iam::V3beta::Troubleshooter::ConditionContext::Request'->new($_) };

declare 'RepeatedRequest',
    as ArrayRef[Request()];

coerce 'RepeatedRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Policytroubleshooter::Iam::V3beta::Troubleshooter::ConditionContext::Request'->new($_) } @$_ ] };

declare 'MapStringRequest',
    as HashRef[Request()];

declare 'EffectiveTag',
    as InstanceOf['Google::Cloud::Policytroubleshooter::Iam::V3beta::Troubleshooter::ConditionContext::EffectiveTag'];

coerce 'EffectiveTag',
    from HashRef, via { 'Google::Cloud::Policytroubleshooter::Iam::V3beta::Troubleshooter::ConditionContext::EffectiveTag'->new($_) };

declare 'RepeatedEffectiveTag',
    as ArrayRef[EffectiveTag()];

coerce 'RepeatedEffectiveTag',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Policytroubleshooter::Iam::V3beta::Troubleshooter::ConditionContext::EffectiveTag'->new($_) } @$_ ] };

declare 'MapStringEffectiveTag',
    as HashRef[EffectiveTag()];

declare 'AllowPolicyExplanation',
    as InstanceOf['Google::Cloud::Policytroubleshooter::Iam::V3beta::Troubleshooter::AllowPolicyExplanation'];

coerce 'AllowPolicyExplanation',
    from HashRef, via { 'Google::Cloud::Policytroubleshooter::Iam::V3beta::Troubleshooter::AllowPolicyExplanation'->new($_) };

declare 'RepeatedAllowPolicyExplanation',
    as ArrayRef[AllowPolicyExplanation()];

coerce 'RepeatedAllowPolicyExplanation',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Policytroubleshooter::Iam::V3beta::Troubleshooter::AllowPolicyExplanation'->new($_) } @$_ ] };

declare 'MapStringAllowPolicyExplanation',
    as HashRef[AllowPolicyExplanation()];

declare 'ExplainedAllowPolicy',
    as InstanceOf['Google::Cloud::Policytroubleshooter::Iam::V3beta::Troubleshooter::ExplainedAllowPolicy'];

coerce 'ExplainedAllowPolicy',
    from HashRef, via { 'Google::Cloud::Policytroubleshooter::Iam::V3beta::Troubleshooter::ExplainedAllowPolicy'->new($_) };

declare 'RepeatedExplainedAllowPolicy',
    as ArrayRef[ExplainedAllowPolicy()];

coerce 'RepeatedExplainedAllowPolicy',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Policytroubleshooter::Iam::V3beta::Troubleshooter::ExplainedAllowPolicy'->new($_) } @$_ ] };

declare 'MapStringExplainedAllowPolicy',
    as HashRef[ExplainedAllowPolicy()];

declare 'AllowBindingExplanation',
    as InstanceOf['Google::Cloud::Policytroubleshooter::Iam::V3beta::Troubleshooter::AllowBindingExplanation'];

coerce 'AllowBindingExplanation',
    from HashRef, via { 'Google::Cloud::Policytroubleshooter::Iam::V3beta::Troubleshooter::AllowBindingExplanation'->new($_) };

declare 'RepeatedAllowBindingExplanation',
    as ArrayRef[AllowBindingExplanation()];

coerce 'RepeatedAllowBindingExplanation',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Policytroubleshooter::Iam::V3beta::Troubleshooter::AllowBindingExplanation'->new($_) } @$_ ] };

declare 'MapStringAllowBindingExplanation',
    as HashRef[AllowBindingExplanation()];

declare 'AnnotatedAllowMembership',
    as InstanceOf['Google::Cloud::Policytroubleshooter::Iam::V3beta::Troubleshooter::AllowBindingExplanation::AnnotatedAllowMembership'];

coerce 'AnnotatedAllowMembership',
    from HashRef, via { 'Google::Cloud::Policytroubleshooter::Iam::V3beta::Troubleshooter::AllowBindingExplanation::AnnotatedAllowMembership'->new($_) };

declare 'RepeatedAnnotatedAllowMembership',
    as ArrayRef[AnnotatedAllowMembership()];

coerce 'RepeatedAnnotatedAllowMembership',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Policytroubleshooter::Iam::V3beta::Troubleshooter::AllowBindingExplanation::AnnotatedAllowMembership'->new($_) } @$_ ] };

declare 'MapStringAnnotatedAllowMembership',
    as HashRef[AnnotatedAllowMembership()];

declare 'MembershipsEntry',
    as InstanceOf['Google::Cloud::Policytroubleshooter::Iam::V3beta::Troubleshooter::AllowBindingExplanation::MembershipsEntry'];

coerce 'MembershipsEntry',
    from HashRef, via { 'Google::Cloud::Policytroubleshooter::Iam::V3beta::Troubleshooter::AllowBindingExplanation::MembershipsEntry'->new($_) };

declare 'RepeatedMembershipsEntry',
    as ArrayRef[MembershipsEntry()];

coerce 'RepeatedMembershipsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Policytroubleshooter::Iam::V3beta::Troubleshooter::AllowBindingExplanation::MembershipsEntry'->new($_) } @$_ ] };

declare 'MapStringMembershipsEntry',
    as HashRef[MembershipsEntry()];

declare 'DenyPolicyExplanation',
    as InstanceOf['Google::Cloud::Policytroubleshooter::Iam::V3beta::Troubleshooter::DenyPolicyExplanation'];

coerce 'DenyPolicyExplanation',
    from HashRef, via { 'Google::Cloud::Policytroubleshooter::Iam::V3beta::Troubleshooter::DenyPolicyExplanation'->new($_) };

declare 'RepeatedDenyPolicyExplanation',
    as ArrayRef[DenyPolicyExplanation()];

coerce 'RepeatedDenyPolicyExplanation',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Policytroubleshooter::Iam::V3beta::Troubleshooter::DenyPolicyExplanation'->new($_) } @$_ ] };

declare 'MapStringDenyPolicyExplanation',
    as HashRef[DenyPolicyExplanation()];

declare 'ExplainedDenyResource',
    as InstanceOf['Google::Cloud::Policytroubleshooter::Iam::V3beta::Troubleshooter::ExplainedDenyResource'];

coerce 'ExplainedDenyResource',
    from HashRef, via { 'Google::Cloud::Policytroubleshooter::Iam::V3beta::Troubleshooter::ExplainedDenyResource'->new($_) };

declare 'RepeatedExplainedDenyResource',
    as ArrayRef[ExplainedDenyResource()];

coerce 'RepeatedExplainedDenyResource',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Policytroubleshooter::Iam::V3beta::Troubleshooter::ExplainedDenyResource'->new($_) } @$_ ] };

declare 'MapStringExplainedDenyResource',
    as HashRef[ExplainedDenyResource()];

declare 'ExplainedDenyPolicy',
    as InstanceOf['Google::Cloud::Policytroubleshooter::Iam::V3beta::Troubleshooter::ExplainedDenyPolicy'];

coerce 'ExplainedDenyPolicy',
    from HashRef, via { 'Google::Cloud::Policytroubleshooter::Iam::V3beta::Troubleshooter::ExplainedDenyPolicy'->new($_) };

declare 'RepeatedExplainedDenyPolicy',
    as ArrayRef[ExplainedDenyPolicy()];

coerce 'RepeatedExplainedDenyPolicy',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Policytroubleshooter::Iam::V3beta::Troubleshooter::ExplainedDenyPolicy'->new($_) } @$_ ] };

declare 'MapStringExplainedDenyPolicy',
    as HashRef[ExplainedDenyPolicy()];

declare 'DenyRuleExplanation',
    as InstanceOf['Google::Cloud::Policytroubleshooter::Iam::V3beta::Troubleshooter::DenyRuleExplanation'];

coerce 'DenyRuleExplanation',
    from HashRef, via { 'Google::Cloud::Policytroubleshooter::Iam::V3beta::Troubleshooter::DenyRuleExplanation'->new($_) };

declare 'RepeatedDenyRuleExplanation',
    as ArrayRef[DenyRuleExplanation()];

coerce 'RepeatedDenyRuleExplanation',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Policytroubleshooter::Iam::V3beta::Troubleshooter::DenyRuleExplanation'->new($_) } @$_ ] };

declare 'MapStringDenyRuleExplanation',
    as HashRef[DenyRuleExplanation()];

declare 'AnnotatedPermissionMatching',
    as InstanceOf['Google::Cloud::Policytroubleshooter::Iam::V3beta::Troubleshooter::DenyRuleExplanation::AnnotatedPermissionMatching'];

coerce 'AnnotatedPermissionMatching',
    from HashRef, via { 'Google::Cloud::Policytroubleshooter::Iam::V3beta::Troubleshooter::DenyRuleExplanation::AnnotatedPermissionMatching'->new($_) };

declare 'RepeatedAnnotatedPermissionMatching',
    as ArrayRef[AnnotatedPermissionMatching()];

coerce 'RepeatedAnnotatedPermissionMatching',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Policytroubleshooter::Iam::V3beta::Troubleshooter::DenyRuleExplanation::AnnotatedPermissionMatching'->new($_) } @$_ ] };

declare 'MapStringAnnotatedPermissionMatching',
    as HashRef[AnnotatedPermissionMatching()];

declare 'AnnotatedDenyPrincipalMatching',
    as InstanceOf['Google::Cloud::Policytroubleshooter::Iam::V3beta::Troubleshooter::DenyRuleExplanation::AnnotatedDenyPrincipalMatching'];

coerce 'AnnotatedDenyPrincipalMatching',
    from HashRef, via { 'Google::Cloud::Policytroubleshooter::Iam::V3beta::Troubleshooter::DenyRuleExplanation::AnnotatedDenyPrincipalMatching'->new($_) };

declare 'RepeatedAnnotatedDenyPrincipalMatching',
    as ArrayRef[AnnotatedDenyPrincipalMatching()];

coerce 'RepeatedAnnotatedDenyPrincipalMatching',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Policytroubleshooter::Iam::V3beta::Troubleshooter::DenyRuleExplanation::AnnotatedDenyPrincipalMatching'->new($_) } @$_ ] };

declare 'MapStringAnnotatedDenyPrincipalMatching',
    as HashRef[AnnotatedDenyPrincipalMatching()];

declare 'DeniedPermissionsEntry',
    as InstanceOf['Google::Cloud::Policytroubleshooter::Iam::V3beta::Troubleshooter::DenyRuleExplanation::DeniedPermissionsEntry'];

coerce 'DeniedPermissionsEntry',
    from HashRef, via { 'Google::Cloud::Policytroubleshooter::Iam::V3beta::Troubleshooter::DenyRuleExplanation::DeniedPermissionsEntry'->new($_) };

declare 'RepeatedDeniedPermissionsEntry',
    as ArrayRef[DeniedPermissionsEntry()];

coerce 'RepeatedDeniedPermissionsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Policytroubleshooter::Iam::V3beta::Troubleshooter::DenyRuleExplanation::DeniedPermissionsEntry'->new($_) } @$_ ] };

declare 'MapStringDeniedPermissionsEntry',
    as HashRef[DeniedPermissionsEntry()];

declare 'ExceptionPermissionsEntry',
    as InstanceOf['Google::Cloud::Policytroubleshooter::Iam::V3beta::Troubleshooter::DenyRuleExplanation::ExceptionPermissionsEntry'];

coerce 'ExceptionPermissionsEntry',
    from HashRef, via { 'Google::Cloud::Policytroubleshooter::Iam::V3beta::Troubleshooter::DenyRuleExplanation::ExceptionPermissionsEntry'->new($_) };

declare 'RepeatedExceptionPermissionsEntry',
    as ArrayRef[ExceptionPermissionsEntry()];

coerce 'RepeatedExceptionPermissionsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Policytroubleshooter::Iam::V3beta::Troubleshooter::DenyRuleExplanation::ExceptionPermissionsEntry'->new($_) } @$_ ] };

declare 'MapStringExceptionPermissionsEntry',
    as HashRef[ExceptionPermissionsEntry()];

declare 'DeniedPrincipalsEntry',
    as InstanceOf['Google::Cloud::Policytroubleshooter::Iam::V3beta::Troubleshooter::DenyRuleExplanation::DeniedPrincipalsEntry'];

coerce 'DeniedPrincipalsEntry',
    from HashRef, via { 'Google::Cloud::Policytroubleshooter::Iam::V3beta::Troubleshooter::DenyRuleExplanation::DeniedPrincipalsEntry'->new($_) };

declare 'RepeatedDeniedPrincipalsEntry',
    as ArrayRef[DeniedPrincipalsEntry()];

coerce 'RepeatedDeniedPrincipalsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Policytroubleshooter::Iam::V3beta::Troubleshooter::DenyRuleExplanation::DeniedPrincipalsEntry'->new($_) } @$_ ] };

declare 'MapStringDeniedPrincipalsEntry',
    as HashRef[DeniedPrincipalsEntry()];

declare 'ExceptionPrincipalsEntry',
    as InstanceOf['Google::Cloud::Policytroubleshooter::Iam::V3beta::Troubleshooter::DenyRuleExplanation::ExceptionPrincipalsEntry'];

coerce 'ExceptionPrincipalsEntry',
    from HashRef, via { 'Google::Cloud::Policytroubleshooter::Iam::V3beta::Troubleshooter::DenyRuleExplanation::ExceptionPrincipalsEntry'->new($_) };

declare 'RepeatedExceptionPrincipalsEntry',
    as ArrayRef[ExceptionPrincipalsEntry()];

coerce 'RepeatedExceptionPrincipalsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Policytroubleshooter::Iam::V3beta::Troubleshooter::DenyRuleExplanation::ExceptionPrincipalsEntry'->new($_) } @$_ ] };

declare 'MapStringExceptionPrincipalsEntry',
    as HashRef[ExceptionPrincipalsEntry()];

declare 'ConditionExplanation',
    as InstanceOf['Google::Cloud::Policytroubleshooter::Iam::V3beta::Troubleshooter::ConditionExplanation'];

coerce 'ConditionExplanation',
    from HashRef, via { 'Google::Cloud::Policytroubleshooter::Iam::V3beta::Troubleshooter::ConditionExplanation'->new($_) };

declare 'RepeatedConditionExplanation',
    as ArrayRef[ConditionExplanation()];

coerce 'RepeatedConditionExplanation',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Policytroubleshooter::Iam::V3beta::Troubleshooter::ConditionExplanation'->new($_) } @$_ ] };

declare 'MapStringConditionExplanation',
    as HashRef[ConditionExplanation()];

declare 'EvaluationState',
    as InstanceOf['Google::Cloud::Policytroubleshooter::Iam::V3beta::Troubleshooter::ConditionExplanation::EvaluationState'];

coerce 'EvaluationState',
    from HashRef, via { 'Google::Cloud::Policytroubleshooter::Iam::V3beta::Troubleshooter::ConditionExplanation::EvaluationState'->new($_) };

declare 'RepeatedEvaluationState',
    as ArrayRef[EvaluationState()];

coerce 'RepeatedEvaluationState',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Policytroubleshooter::Iam::V3beta::Troubleshooter::ConditionExplanation::EvaluationState'->new($_) } @$_ ] };

declare 'MapStringEvaluationState',
    as HashRef[EvaluationState()];

1;

__END__

=head1 NAME

Google::Cloud::Policytroubleshooter::Iam::V3beta::Troubleshooter::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
