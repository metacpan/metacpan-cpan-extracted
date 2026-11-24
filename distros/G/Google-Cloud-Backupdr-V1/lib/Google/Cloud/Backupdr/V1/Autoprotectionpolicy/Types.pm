package Google::Cloud::Backupdr::V1::Autoprotectionpolicy::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'AutoProtectionPolicy',
    as InstanceOf['Google::Cloud::Backupdr::V1::Autoprotectionpolicy::AutoProtectionPolicy'];

coerce 'AutoProtectionPolicy',
    from HashRef, via { 'Google::Cloud::Backupdr::V1::Autoprotectionpolicy::AutoProtectionPolicy'->new($_) };

declare 'RepeatedAutoProtectionPolicy',
    as ArrayRef[AutoProtectionPolicy()];

coerce 'RepeatedAutoProtectionPolicy',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Backupdr::V1::Autoprotectionpolicy::AutoProtectionPolicy'->new($_) } @$_ ] };

declare 'MapStringAutoProtectionPolicy',
    as HashRef[AutoProtectionPolicy()];

declare 'State',
    as (Int | Str);

declare 'BackupPlanDetail',
    as InstanceOf['Google::Cloud::Backupdr::V1::Autoprotectionpolicy::BackupPlanDetail'];

coerce 'BackupPlanDetail',
    from HashRef, via { 'Google::Cloud::Backupdr::V1::Autoprotectionpolicy::BackupPlanDetail'->new($_) };

declare 'RepeatedBackupPlanDetail',
    as ArrayRef[BackupPlanDetail()];

coerce 'RepeatedBackupPlanDetail',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Backupdr::V1::Autoprotectionpolicy::BackupPlanDetail'->new($_) } @$_ ] };

declare 'MapStringBackupPlanDetail',
    as HashRef[BackupPlanDetail()];

declare 'Criteria',
    as InstanceOf['Google::Cloud::Backupdr::V1::Autoprotectionpolicy::Criteria'];

coerce 'Criteria',
    from HashRef, via { 'Google::Cloud::Backupdr::V1::Autoprotectionpolicy::Criteria'->new($_) };

declare 'RepeatedCriteria',
    as ArrayRef[Criteria()];

coerce 'RepeatedCriteria',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Backupdr::V1::Autoprotectionpolicy::Criteria'->new($_) } @$_ ] };

declare 'MapStringCriteria',
    as HashRef[Criteria()];

declare 'MatchingCondition',
    as InstanceOf['Google::Cloud::Backupdr::V1::Autoprotectionpolicy::MatchingCondition'];

coerce 'MatchingCondition',
    from HashRef, via { 'Google::Cloud::Backupdr::V1::Autoprotectionpolicy::MatchingCondition'->new($_) };

declare 'RepeatedMatchingCondition',
    as ArrayRef[MatchingCondition()];

coerce 'RepeatedMatchingCondition',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Backupdr::V1::Autoprotectionpolicy::MatchingCondition'->new($_) } @$_ ] };

declare 'MapStringMatchingCondition',
    as HashRef[MatchingCondition()];

declare 'PolicyEvaluationSummary',
    as InstanceOf['Google::Cloud::Backupdr::V1::Autoprotectionpolicy::PolicyEvaluationSummary'];

coerce 'PolicyEvaluationSummary',
    from HashRef, via { 'Google::Cloud::Backupdr::V1::Autoprotectionpolicy::PolicyEvaluationSummary'->new($_) };

declare 'RepeatedPolicyEvaluationSummary',
    as ArrayRef[PolicyEvaluationSummary()];

coerce 'RepeatedPolicyEvaluationSummary',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Backupdr::V1::Autoprotectionpolicy::PolicyEvaluationSummary'->new($_) } @$_ ] };

declare 'MapStringPolicyEvaluationSummary',
    as HashRef[PolicyEvaluationSummary()];

declare 'BindingSummary',
    as InstanceOf['Google::Cloud::Backupdr::V1::Autoprotectionpolicy::BindingSummary'];

coerce 'BindingSummary',
    from HashRef, via { 'Google::Cloud::Backupdr::V1::Autoprotectionpolicy::BindingSummary'->new($_) };

declare 'RepeatedBindingSummary',
    as ArrayRef[BindingSummary()];

coerce 'RepeatedBindingSummary',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Backupdr::V1::Autoprotectionpolicy::BindingSummary'->new($_) } @$_ ] };

declare 'MapStringBindingSummary',
    as HashRef[BindingSummary()];

declare 'KeyValuePair',
    as InstanceOf['Google::Cloud::Backupdr::V1::Autoprotectionpolicy::KeyValuePair'];

coerce 'KeyValuePair',
    from HashRef, via { 'Google::Cloud::Backupdr::V1::Autoprotectionpolicy::KeyValuePair'->new($_) };

declare 'RepeatedKeyValuePair',
    as ArrayRef[KeyValuePair()];

coerce 'RepeatedKeyValuePair',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Backupdr::V1::Autoprotectionpolicy::KeyValuePair'->new($_) } @$_ ] };

declare 'MapStringKeyValuePair',
    as HashRef[KeyValuePair()];

declare 'CreateAutoProtectionPolicyRequest',
    as InstanceOf['Google::Cloud::Backupdr::V1::Autoprotectionpolicy::CreateAutoProtectionPolicyRequest'];

coerce 'CreateAutoProtectionPolicyRequest',
    from HashRef, via { 'Google::Cloud::Backupdr::V1::Autoprotectionpolicy::CreateAutoProtectionPolicyRequest'->new($_) };

declare 'RepeatedCreateAutoProtectionPolicyRequest',
    as ArrayRef[CreateAutoProtectionPolicyRequest()];

coerce 'RepeatedCreateAutoProtectionPolicyRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Backupdr::V1::Autoprotectionpolicy::CreateAutoProtectionPolicyRequest'->new($_) } @$_ ] };

declare 'MapStringCreateAutoProtectionPolicyRequest',
    as HashRef[CreateAutoProtectionPolicyRequest()];

declare 'GetAutoProtectionPolicyRequest',
    as InstanceOf['Google::Cloud::Backupdr::V1::Autoprotectionpolicy::GetAutoProtectionPolicyRequest'];

coerce 'GetAutoProtectionPolicyRequest',
    from HashRef, via { 'Google::Cloud::Backupdr::V1::Autoprotectionpolicy::GetAutoProtectionPolicyRequest'->new($_) };

declare 'RepeatedGetAutoProtectionPolicyRequest',
    as ArrayRef[GetAutoProtectionPolicyRequest()];

coerce 'RepeatedGetAutoProtectionPolicyRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Backupdr::V1::Autoprotectionpolicy::GetAutoProtectionPolicyRequest'->new($_) } @$_ ] };

declare 'MapStringGetAutoProtectionPolicyRequest',
    as HashRef[GetAutoProtectionPolicyRequest()];

declare 'UpdateAutoProtectionPolicyRequest',
    as InstanceOf['Google::Cloud::Backupdr::V1::Autoprotectionpolicy::UpdateAutoProtectionPolicyRequest'];

coerce 'UpdateAutoProtectionPolicyRequest',
    from HashRef, via { 'Google::Cloud::Backupdr::V1::Autoprotectionpolicy::UpdateAutoProtectionPolicyRequest'->new($_) };

declare 'RepeatedUpdateAutoProtectionPolicyRequest',
    as ArrayRef[UpdateAutoProtectionPolicyRequest()];

coerce 'RepeatedUpdateAutoProtectionPolicyRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Backupdr::V1::Autoprotectionpolicy::UpdateAutoProtectionPolicyRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateAutoProtectionPolicyRequest',
    as HashRef[UpdateAutoProtectionPolicyRequest()];

declare 'DeleteAutoProtectionPolicyRequest',
    as InstanceOf['Google::Cloud::Backupdr::V1::Autoprotectionpolicy::DeleteAutoProtectionPolicyRequest'];

coerce 'DeleteAutoProtectionPolicyRequest',
    from HashRef, via { 'Google::Cloud::Backupdr::V1::Autoprotectionpolicy::DeleteAutoProtectionPolicyRequest'->new($_) };

declare 'RepeatedDeleteAutoProtectionPolicyRequest',
    as ArrayRef[DeleteAutoProtectionPolicyRequest()];

coerce 'RepeatedDeleteAutoProtectionPolicyRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Backupdr::V1::Autoprotectionpolicy::DeleteAutoProtectionPolicyRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteAutoProtectionPolicyRequest',
    as HashRef[DeleteAutoProtectionPolicyRequest()];

declare 'ListAutoProtectionPoliciesRequest',
    as InstanceOf['Google::Cloud::Backupdr::V1::Autoprotectionpolicy::ListAutoProtectionPoliciesRequest'];

coerce 'ListAutoProtectionPoliciesRequest',
    from HashRef, via { 'Google::Cloud::Backupdr::V1::Autoprotectionpolicy::ListAutoProtectionPoliciesRequest'->new($_) };

declare 'RepeatedListAutoProtectionPoliciesRequest',
    as ArrayRef[ListAutoProtectionPoliciesRequest()];

coerce 'RepeatedListAutoProtectionPoliciesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Backupdr::V1::Autoprotectionpolicy::ListAutoProtectionPoliciesRequest'->new($_) } @$_ ] };

declare 'MapStringListAutoProtectionPoliciesRequest',
    as HashRef[ListAutoProtectionPoliciesRequest()];

declare 'ListAutoProtectionPoliciesResponse',
    as InstanceOf['Google::Cloud::Backupdr::V1::Autoprotectionpolicy::ListAutoProtectionPoliciesResponse'];

coerce 'ListAutoProtectionPoliciesResponse',
    from HashRef, via { 'Google::Cloud::Backupdr::V1::Autoprotectionpolicy::ListAutoProtectionPoliciesResponse'->new($_) };

declare 'RepeatedListAutoProtectionPoliciesResponse',
    as ArrayRef[ListAutoProtectionPoliciesResponse()];

coerce 'RepeatedListAutoProtectionPoliciesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Backupdr::V1::Autoprotectionpolicy::ListAutoProtectionPoliciesResponse'->new($_) } @$_ ] };

declare 'MapStringListAutoProtectionPoliciesResponse',
    as HashRef[ListAutoProtectionPoliciesResponse()];

1;

__END__

=head1 NAME

Google::Cloud::Backupdr::V1::Autoprotectionpolicy::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
