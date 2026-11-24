package Google::Cloud::Orgpolicy::V2::Orgpolicy::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Policy',
    as InstanceOf['Google::Cloud::Orgpolicy::V2::Orgpolicy::Policy'];

coerce 'Policy',
    from HashRef, via { 'Google::Cloud::Orgpolicy::V2::Orgpolicy::Policy'->new($_) };

declare 'RepeatedPolicy',
    as ArrayRef[Policy()];

coerce 'RepeatedPolicy',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Orgpolicy::V2::Orgpolicy::Policy'->new($_) } @$_ ] };

declare 'MapStringPolicy',
    as HashRef[Policy()];

declare 'AlternatePolicySpec',
    as InstanceOf['Google::Cloud::Orgpolicy::V2::Orgpolicy::AlternatePolicySpec'];

coerce 'AlternatePolicySpec',
    from HashRef, via { 'Google::Cloud::Orgpolicy::V2::Orgpolicy::AlternatePolicySpec'->new($_) };

declare 'RepeatedAlternatePolicySpec',
    as ArrayRef[AlternatePolicySpec()];

coerce 'RepeatedAlternatePolicySpec',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Orgpolicy::V2::Orgpolicy::AlternatePolicySpec'->new($_) } @$_ ] };

declare 'MapStringAlternatePolicySpec',
    as HashRef[AlternatePolicySpec()];

declare 'PolicySpec',
    as InstanceOf['Google::Cloud::Orgpolicy::V2::Orgpolicy::PolicySpec'];

coerce 'PolicySpec',
    from HashRef, via { 'Google::Cloud::Orgpolicy::V2::Orgpolicy::PolicySpec'->new($_) };

declare 'RepeatedPolicySpec',
    as ArrayRef[PolicySpec()];

coerce 'RepeatedPolicySpec',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Orgpolicy::V2::Orgpolicy::PolicySpec'->new($_) } @$_ ] };

declare 'MapStringPolicySpec',
    as HashRef[PolicySpec()];

declare 'PolicyRule',
    as InstanceOf['Google::Cloud::Orgpolicy::V2::Orgpolicy::PolicySpec::PolicyRule'];

coerce 'PolicyRule',
    from HashRef, via { 'Google::Cloud::Orgpolicy::V2::Orgpolicy::PolicySpec::PolicyRule'->new($_) };

declare 'RepeatedPolicyRule',
    as ArrayRef[PolicyRule()];

coerce 'RepeatedPolicyRule',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Orgpolicy::V2::Orgpolicy::PolicySpec::PolicyRule'->new($_) } @$_ ] };

declare 'MapStringPolicyRule',
    as HashRef[PolicyRule()];

declare 'StringValues',
    as InstanceOf['Google::Cloud::Orgpolicy::V2::Orgpolicy::PolicySpec::PolicyRule::StringValues'];

coerce 'StringValues',
    from HashRef, via { 'Google::Cloud::Orgpolicy::V2::Orgpolicy::PolicySpec::PolicyRule::StringValues'->new($_) };

declare 'RepeatedStringValues',
    as ArrayRef[StringValues()];

coerce 'RepeatedStringValues',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Orgpolicy::V2::Orgpolicy::PolicySpec::PolicyRule::StringValues'->new($_) } @$_ ] };

declare 'MapStringStringValues',
    as HashRef[StringValues()];

declare 'ListConstraintsRequest',
    as InstanceOf['Google::Cloud::Orgpolicy::V2::Orgpolicy::ListConstraintsRequest'];

coerce 'ListConstraintsRequest',
    from HashRef, via { 'Google::Cloud::Orgpolicy::V2::Orgpolicy::ListConstraintsRequest'->new($_) };

declare 'RepeatedListConstraintsRequest',
    as ArrayRef[ListConstraintsRequest()];

coerce 'RepeatedListConstraintsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Orgpolicy::V2::Orgpolicy::ListConstraintsRequest'->new($_) } @$_ ] };

declare 'MapStringListConstraintsRequest',
    as HashRef[ListConstraintsRequest()];

declare 'ListConstraintsResponse',
    as InstanceOf['Google::Cloud::Orgpolicy::V2::Orgpolicy::ListConstraintsResponse'];

coerce 'ListConstraintsResponse',
    from HashRef, via { 'Google::Cloud::Orgpolicy::V2::Orgpolicy::ListConstraintsResponse'->new($_) };

declare 'RepeatedListConstraintsResponse',
    as ArrayRef[ListConstraintsResponse()];

coerce 'RepeatedListConstraintsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Orgpolicy::V2::Orgpolicy::ListConstraintsResponse'->new($_) } @$_ ] };

declare 'MapStringListConstraintsResponse',
    as HashRef[ListConstraintsResponse()];

declare 'ListPoliciesRequest',
    as InstanceOf['Google::Cloud::Orgpolicy::V2::Orgpolicy::ListPoliciesRequest'];

coerce 'ListPoliciesRequest',
    from HashRef, via { 'Google::Cloud::Orgpolicy::V2::Orgpolicy::ListPoliciesRequest'->new($_) };

declare 'RepeatedListPoliciesRequest',
    as ArrayRef[ListPoliciesRequest()];

coerce 'RepeatedListPoliciesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Orgpolicy::V2::Orgpolicy::ListPoliciesRequest'->new($_) } @$_ ] };

declare 'MapStringListPoliciesRequest',
    as HashRef[ListPoliciesRequest()];

declare 'ListPoliciesResponse',
    as InstanceOf['Google::Cloud::Orgpolicy::V2::Orgpolicy::ListPoliciesResponse'];

coerce 'ListPoliciesResponse',
    from HashRef, via { 'Google::Cloud::Orgpolicy::V2::Orgpolicy::ListPoliciesResponse'->new($_) };

declare 'RepeatedListPoliciesResponse',
    as ArrayRef[ListPoliciesResponse()];

coerce 'RepeatedListPoliciesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Orgpolicy::V2::Orgpolicy::ListPoliciesResponse'->new($_) } @$_ ] };

declare 'MapStringListPoliciesResponse',
    as HashRef[ListPoliciesResponse()];

declare 'GetPolicyRequest',
    as InstanceOf['Google::Cloud::Orgpolicy::V2::Orgpolicy::GetPolicyRequest'];

coerce 'GetPolicyRequest',
    from HashRef, via { 'Google::Cloud::Orgpolicy::V2::Orgpolicy::GetPolicyRequest'->new($_) };

declare 'RepeatedGetPolicyRequest',
    as ArrayRef[GetPolicyRequest()];

coerce 'RepeatedGetPolicyRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Orgpolicy::V2::Orgpolicy::GetPolicyRequest'->new($_) } @$_ ] };

declare 'MapStringGetPolicyRequest',
    as HashRef[GetPolicyRequest()];

declare 'GetEffectivePolicyRequest',
    as InstanceOf['Google::Cloud::Orgpolicy::V2::Orgpolicy::GetEffectivePolicyRequest'];

coerce 'GetEffectivePolicyRequest',
    from HashRef, via { 'Google::Cloud::Orgpolicy::V2::Orgpolicy::GetEffectivePolicyRequest'->new($_) };

declare 'RepeatedGetEffectivePolicyRequest',
    as ArrayRef[GetEffectivePolicyRequest()];

coerce 'RepeatedGetEffectivePolicyRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Orgpolicy::V2::Orgpolicy::GetEffectivePolicyRequest'->new($_) } @$_ ] };

declare 'MapStringGetEffectivePolicyRequest',
    as HashRef[GetEffectivePolicyRequest()];

declare 'CreatePolicyRequest',
    as InstanceOf['Google::Cloud::Orgpolicy::V2::Orgpolicy::CreatePolicyRequest'];

coerce 'CreatePolicyRequest',
    from HashRef, via { 'Google::Cloud::Orgpolicy::V2::Orgpolicy::CreatePolicyRequest'->new($_) };

declare 'RepeatedCreatePolicyRequest',
    as ArrayRef[CreatePolicyRequest()];

coerce 'RepeatedCreatePolicyRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Orgpolicy::V2::Orgpolicy::CreatePolicyRequest'->new($_) } @$_ ] };

declare 'MapStringCreatePolicyRequest',
    as HashRef[CreatePolicyRequest()];

declare 'UpdatePolicyRequest',
    as InstanceOf['Google::Cloud::Orgpolicy::V2::Orgpolicy::UpdatePolicyRequest'];

coerce 'UpdatePolicyRequest',
    from HashRef, via { 'Google::Cloud::Orgpolicy::V2::Orgpolicy::UpdatePolicyRequest'->new($_) };

declare 'RepeatedUpdatePolicyRequest',
    as ArrayRef[UpdatePolicyRequest()];

coerce 'RepeatedUpdatePolicyRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Orgpolicy::V2::Orgpolicy::UpdatePolicyRequest'->new($_) } @$_ ] };

declare 'MapStringUpdatePolicyRequest',
    as HashRef[UpdatePolicyRequest()];

declare 'DeletePolicyRequest',
    as InstanceOf['Google::Cloud::Orgpolicy::V2::Orgpolicy::DeletePolicyRequest'];

coerce 'DeletePolicyRequest',
    from HashRef, via { 'Google::Cloud::Orgpolicy::V2::Orgpolicy::DeletePolicyRequest'->new($_) };

declare 'RepeatedDeletePolicyRequest',
    as ArrayRef[DeletePolicyRequest()];

coerce 'RepeatedDeletePolicyRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Orgpolicy::V2::Orgpolicy::DeletePolicyRequest'->new($_) } @$_ ] };

declare 'MapStringDeletePolicyRequest',
    as HashRef[DeletePolicyRequest()];

declare 'CreateCustomConstraintRequest',
    as InstanceOf['Google::Cloud::Orgpolicy::V2::Orgpolicy::CreateCustomConstraintRequest'];

coerce 'CreateCustomConstraintRequest',
    from HashRef, via { 'Google::Cloud::Orgpolicy::V2::Orgpolicy::CreateCustomConstraintRequest'->new($_) };

declare 'RepeatedCreateCustomConstraintRequest',
    as ArrayRef[CreateCustomConstraintRequest()];

coerce 'RepeatedCreateCustomConstraintRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Orgpolicy::V2::Orgpolicy::CreateCustomConstraintRequest'->new($_) } @$_ ] };

declare 'MapStringCreateCustomConstraintRequest',
    as HashRef[CreateCustomConstraintRequest()];

declare 'GetCustomConstraintRequest',
    as InstanceOf['Google::Cloud::Orgpolicy::V2::Orgpolicy::GetCustomConstraintRequest'];

coerce 'GetCustomConstraintRequest',
    from HashRef, via { 'Google::Cloud::Orgpolicy::V2::Orgpolicy::GetCustomConstraintRequest'->new($_) };

declare 'RepeatedGetCustomConstraintRequest',
    as ArrayRef[GetCustomConstraintRequest()];

coerce 'RepeatedGetCustomConstraintRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Orgpolicy::V2::Orgpolicy::GetCustomConstraintRequest'->new($_) } @$_ ] };

declare 'MapStringGetCustomConstraintRequest',
    as HashRef[GetCustomConstraintRequest()];

declare 'ListCustomConstraintsRequest',
    as InstanceOf['Google::Cloud::Orgpolicy::V2::Orgpolicy::ListCustomConstraintsRequest'];

coerce 'ListCustomConstraintsRequest',
    from HashRef, via { 'Google::Cloud::Orgpolicy::V2::Orgpolicy::ListCustomConstraintsRequest'->new($_) };

declare 'RepeatedListCustomConstraintsRequest',
    as ArrayRef[ListCustomConstraintsRequest()];

coerce 'RepeatedListCustomConstraintsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Orgpolicy::V2::Orgpolicy::ListCustomConstraintsRequest'->new($_) } @$_ ] };

declare 'MapStringListCustomConstraintsRequest',
    as HashRef[ListCustomConstraintsRequest()];

declare 'ListCustomConstraintsResponse',
    as InstanceOf['Google::Cloud::Orgpolicy::V2::Orgpolicy::ListCustomConstraintsResponse'];

coerce 'ListCustomConstraintsResponse',
    from HashRef, via { 'Google::Cloud::Orgpolicy::V2::Orgpolicy::ListCustomConstraintsResponse'->new($_) };

declare 'RepeatedListCustomConstraintsResponse',
    as ArrayRef[ListCustomConstraintsResponse()];

coerce 'RepeatedListCustomConstraintsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Orgpolicy::V2::Orgpolicy::ListCustomConstraintsResponse'->new($_) } @$_ ] };

declare 'MapStringListCustomConstraintsResponse',
    as HashRef[ListCustomConstraintsResponse()];

declare 'UpdateCustomConstraintRequest',
    as InstanceOf['Google::Cloud::Orgpolicy::V2::Orgpolicy::UpdateCustomConstraintRequest'];

coerce 'UpdateCustomConstraintRequest',
    from HashRef, via { 'Google::Cloud::Orgpolicy::V2::Orgpolicy::UpdateCustomConstraintRequest'->new($_) };

declare 'RepeatedUpdateCustomConstraintRequest',
    as ArrayRef[UpdateCustomConstraintRequest()];

coerce 'RepeatedUpdateCustomConstraintRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Orgpolicy::V2::Orgpolicy::UpdateCustomConstraintRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateCustomConstraintRequest',
    as HashRef[UpdateCustomConstraintRequest()];

declare 'DeleteCustomConstraintRequest',
    as InstanceOf['Google::Cloud::Orgpolicy::V2::Orgpolicy::DeleteCustomConstraintRequest'];

coerce 'DeleteCustomConstraintRequest',
    from HashRef, via { 'Google::Cloud::Orgpolicy::V2::Orgpolicy::DeleteCustomConstraintRequest'->new($_) };

declare 'RepeatedDeleteCustomConstraintRequest',
    as ArrayRef[DeleteCustomConstraintRequest()];

coerce 'RepeatedDeleteCustomConstraintRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Orgpolicy::V2::Orgpolicy::DeleteCustomConstraintRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteCustomConstraintRequest',
    as HashRef[DeleteCustomConstraintRequest()];

1;

__END__

=head1 NAME

Google::Cloud::Orgpolicy::V2::Orgpolicy::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
