package Google::Iam::V2::Policy::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Policy',
    as InstanceOf['Google::Iam::V2::Policy::Policy'];

coerce 'Policy',
    from HashRef, via { 'Google::Iam::V2::Policy::Policy'->new($_) };

declare 'RepeatedPolicy',
    as ArrayRef[Policy()];

coerce 'RepeatedPolicy',
    from ArrayRef[HashRef], via { [ map { 'Google::Iam::V2::Policy::Policy'->new($_) } @$_ ] };

declare 'MapStringPolicy',
    as HashRef[Policy()];

declare 'AnnotationsEntry',
    as InstanceOf['Google::Iam::V2::Policy::Policy::AnnotationsEntry'];

coerce 'AnnotationsEntry',
    from HashRef, via { 'Google::Iam::V2::Policy::Policy::AnnotationsEntry'->new($_) };

declare 'RepeatedAnnotationsEntry',
    as ArrayRef[AnnotationsEntry()];

coerce 'RepeatedAnnotationsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Iam::V2::Policy::Policy::AnnotationsEntry'->new($_) } @$_ ] };

declare 'MapStringAnnotationsEntry',
    as HashRef[AnnotationsEntry()];

declare 'PolicyRule',
    as InstanceOf['Google::Iam::V2::Policy::PolicyRule'];

coerce 'PolicyRule',
    from HashRef, via { 'Google::Iam::V2::Policy::PolicyRule'->new($_) };

declare 'RepeatedPolicyRule',
    as ArrayRef[PolicyRule()];

coerce 'RepeatedPolicyRule',
    from ArrayRef[HashRef], via { [ map { 'Google::Iam::V2::Policy::PolicyRule'->new($_) } @$_ ] };

declare 'MapStringPolicyRule',
    as HashRef[PolicyRule()];

declare 'ListPoliciesRequest',
    as InstanceOf['Google::Iam::V2::Policy::ListPoliciesRequest'];

coerce 'ListPoliciesRequest',
    from HashRef, via { 'Google::Iam::V2::Policy::ListPoliciesRequest'->new($_) };

declare 'RepeatedListPoliciesRequest',
    as ArrayRef[ListPoliciesRequest()];

coerce 'RepeatedListPoliciesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Iam::V2::Policy::ListPoliciesRequest'->new($_) } @$_ ] };

declare 'MapStringListPoliciesRequest',
    as HashRef[ListPoliciesRequest()];

declare 'ListPoliciesResponse',
    as InstanceOf['Google::Iam::V2::Policy::ListPoliciesResponse'];

coerce 'ListPoliciesResponse',
    from HashRef, via { 'Google::Iam::V2::Policy::ListPoliciesResponse'->new($_) };

declare 'RepeatedListPoliciesResponse',
    as ArrayRef[ListPoliciesResponse()];

coerce 'RepeatedListPoliciesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Iam::V2::Policy::ListPoliciesResponse'->new($_) } @$_ ] };

declare 'MapStringListPoliciesResponse',
    as HashRef[ListPoliciesResponse()];

declare 'GetPolicyRequest',
    as InstanceOf['Google::Iam::V2::Policy::GetPolicyRequest'];

coerce 'GetPolicyRequest',
    from HashRef, via { 'Google::Iam::V2::Policy::GetPolicyRequest'->new($_) };

declare 'RepeatedGetPolicyRequest',
    as ArrayRef[GetPolicyRequest()];

coerce 'RepeatedGetPolicyRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Iam::V2::Policy::GetPolicyRequest'->new($_) } @$_ ] };

declare 'MapStringGetPolicyRequest',
    as HashRef[GetPolicyRequest()];

declare 'CreatePolicyRequest',
    as InstanceOf['Google::Iam::V2::Policy::CreatePolicyRequest'];

coerce 'CreatePolicyRequest',
    from HashRef, via { 'Google::Iam::V2::Policy::CreatePolicyRequest'->new($_) };

declare 'RepeatedCreatePolicyRequest',
    as ArrayRef[CreatePolicyRequest()];

coerce 'RepeatedCreatePolicyRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Iam::V2::Policy::CreatePolicyRequest'->new($_) } @$_ ] };

declare 'MapStringCreatePolicyRequest',
    as HashRef[CreatePolicyRequest()];

declare 'UpdatePolicyRequest',
    as InstanceOf['Google::Iam::V2::Policy::UpdatePolicyRequest'];

coerce 'UpdatePolicyRequest',
    from HashRef, via { 'Google::Iam::V2::Policy::UpdatePolicyRequest'->new($_) };

declare 'RepeatedUpdatePolicyRequest',
    as ArrayRef[UpdatePolicyRequest()];

coerce 'RepeatedUpdatePolicyRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Iam::V2::Policy::UpdatePolicyRequest'->new($_) } @$_ ] };

declare 'MapStringUpdatePolicyRequest',
    as HashRef[UpdatePolicyRequest()];

declare 'DeletePolicyRequest',
    as InstanceOf['Google::Iam::V2::Policy::DeletePolicyRequest'];

coerce 'DeletePolicyRequest',
    from HashRef, via { 'Google::Iam::V2::Policy::DeletePolicyRequest'->new($_) };

declare 'RepeatedDeletePolicyRequest',
    as ArrayRef[DeletePolicyRequest()];

coerce 'RepeatedDeletePolicyRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Iam::V2::Policy::DeletePolicyRequest'->new($_) } @$_ ] };

declare 'MapStringDeletePolicyRequest',
    as HashRef[DeletePolicyRequest()];

declare 'PolicyOperationMetadata',
    as InstanceOf['Google::Iam::V2::Policy::PolicyOperationMetadata'];

coerce 'PolicyOperationMetadata',
    from HashRef, via { 'Google::Iam::V2::Policy::PolicyOperationMetadata'->new($_) };

declare 'RepeatedPolicyOperationMetadata',
    as ArrayRef[PolicyOperationMetadata()];

coerce 'RepeatedPolicyOperationMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Iam::V2::Policy::PolicyOperationMetadata'->new($_) } @$_ ] };

declare 'MapStringPolicyOperationMetadata',
    as HashRef[PolicyOperationMetadata()];

1;

__END__

=head1 NAME

Google::Iam::V2::Policy::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
