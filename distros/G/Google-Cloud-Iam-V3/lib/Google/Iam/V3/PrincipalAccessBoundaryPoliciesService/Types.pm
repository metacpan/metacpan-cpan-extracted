package Google::Iam::V3::PrincipalAccessBoundaryPoliciesService::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'CreatePrincipalAccessBoundaryPolicyRequest',
    as InstanceOf['Google::Iam::V3::PrincipalAccessBoundaryPoliciesService::CreatePrincipalAccessBoundaryPolicyRequest'];

coerce 'CreatePrincipalAccessBoundaryPolicyRequest',
    from HashRef, via { 'Google::Iam::V3::PrincipalAccessBoundaryPoliciesService::CreatePrincipalAccessBoundaryPolicyRequest'->new($_) };

declare 'RepeatedCreatePrincipalAccessBoundaryPolicyRequest',
    as ArrayRef[CreatePrincipalAccessBoundaryPolicyRequest()];

coerce 'RepeatedCreatePrincipalAccessBoundaryPolicyRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Iam::V3::PrincipalAccessBoundaryPoliciesService::CreatePrincipalAccessBoundaryPolicyRequest'->new($_) } @$_ ] };

declare 'MapStringCreatePrincipalAccessBoundaryPolicyRequest',
    as HashRef[CreatePrincipalAccessBoundaryPolicyRequest()];

declare 'GetPrincipalAccessBoundaryPolicyRequest',
    as InstanceOf['Google::Iam::V3::PrincipalAccessBoundaryPoliciesService::GetPrincipalAccessBoundaryPolicyRequest'];

coerce 'GetPrincipalAccessBoundaryPolicyRequest',
    from HashRef, via { 'Google::Iam::V3::PrincipalAccessBoundaryPoliciesService::GetPrincipalAccessBoundaryPolicyRequest'->new($_) };

declare 'RepeatedGetPrincipalAccessBoundaryPolicyRequest',
    as ArrayRef[GetPrincipalAccessBoundaryPolicyRequest()];

coerce 'RepeatedGetPrincipalAccessBoundaryPolicyRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Iam::V3::PrincipalAccessBoundaryPoliciesService::GetPrincipalAccessBoundaryPolicyRequest'->new($_) } @$_ ] };

declare 'MapStringGetPrincipalAccessBoundaryPolicyRequest',
    as HashRef[GetPrincipalAccessBoundaryPolicyRequest()];

declare 'UpdatePrincipalAccessBoundaryPolicyRequest',
    as InstanceOf['Google::Iam::V3::PrincipalAccessBoundaryPoliciesService::UpdatePrincipalAccessBoundaryPolicyRequest'];

coerce 'UpdatePrincipalAccessBoundaryPolicyRequest',
    from HashRef, via { 'Google::Iam::V3::PrincipalAccessBoundaryPoliciesService::UpdatePrincipalAccessBoundaryPolicyRequest'->new($_) };

declare 'RepeatedUpdatePrincipalAccessBoundaryPolicyRequest',
    as ArrayRef[UpdatePrincipalAccessBoundaryPolicyRequest()];

coerce 'RepeatedUpdatePrincipalAccessBoundaryPolicyRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Iam::V3::PrincipalAccessBoundaryPoliciesService::UpdatePrincipalAccessBoundaryPolicyRequest'->new($_) } @$_ ] };

declare 'MapStringUpdatePrincipalAccessBoundaryPolicyRequest',
    as HashRef[UpdatePrincipalAccessBoundaryPolicyRequest()];

declare 'DeletePrincipalAccessBoundaryPolicyRequest',
    as InstanceOf['Google::Iam::V3::PrincipalAccessBoundaryPoliciesService::DeletePrincipalAccessBoundaryPolicyRequest'];

coerce 'DeletePrincipalAccessBoundaryPolicyRequest',
    from HashRef, via { 'Google::Iam::V3::PrincipalAccessBoundaryPoliciesService::DeletePrincipalAccessBoundaryPolicyRequest'->new($_) };

declare 'RepeatedDeletePrincipalAccessBoundaryPolicyRequest',
    as ArrayRef[DeletePrincipalAccessBoundaryPolicyRequest()];

coerce 'RepeatedDeletePrincipalAccessBoundaryPolicyRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Iam::V3::PrincipalAccessBoundaryPoliciesService::DeletePrincipalAccessBoundaryPolicyRequest'->new($_) } @$_ ] };

declare 'MapStringDeletePrincipalAccessBoundaryPolicyRequest',
    as HashRef[DeletePrincipalAccessBoundaryPolicyRequest()];

declare 'ListPrincipalAccessBoundaryPoliciesRequest',
    as InstanceOf['Google::Iam::V3::PrincipalAccessBoundaryPoliciesService::ListPrincipalAccessBoundaryPoliciesRequest'];

coerce 'ListPrincipalAccessBoundaryPoliciesRequest',
    from HashRef, via { 'Google::Iam::V3::PrincipalAccessBoundaryPoliciesService::ListPrincipalAccessBoundaryPoliciesRequest'->new($_) };

declare 'RepeatedListPrincipalAccessBoundaryPoliciesRequest',
    as ArrayRef[ListPrincipalAccessBoundaryPoliciesRequest()];

coerce 'RepeatedListPrincipalAccessBoundaryPoliciesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Iam::V3::PrincipalAccessBoundaryPoliciesService::ListPrincipalAccessBoundaryPoliciesRequest'->new($_) } @$_ ] };

declare 'MapStringListPrincipalAccessBoundaryPoliciesRequest',
    as HashRef[ListPrincipalAccessBoundaryPoliciesRequest()];

declare 'ListPrincipalAccessBoundaryPoliciesResponse',
    as InstanceOf['Google::Iam::V3::PrincipalAccessBoundaryPoliciesService::ListPrincipalAccessBoundaryPoliciesResponse'];

coerce 'ListPrincipalAccessBoundaryPoliciesResponse',
    from HashRef, via { 'Google::Iam::V3::PrincipalAccessBoundaryPoliciesService::ListPrincipalAccessBoundaryPoliciesResponse'->new($_) };

declare 'RepeatedListPrincipalAccessBoundaryPoliciesResponse',
    as ArrayRef[ListPrincipalAccessBoundaryPoliciesResponse()];

coerce 'RepeatedListPrincipalAccessBoundaryPoliciesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Iam::V3::PrincipalAccessBoundaryPoliciesService::ListPrincipalAccessBoundaryPoliciesResponse'->new($_) } @$_ ] };

declare 'MapStringListPrincipalAccessBoundaryPoliciesResponse',
    as HashRef[ListPrincipalAccessBoundaryPoliciesResponse()];

declare 'SearchPrincipalAccessBoundaryPolicyBindingsRequest',
    as InstanceOf['Google::Iam::V3::PrincipalAccessBoundaryPoliciesService::SearchPrincipalAccessBoundaryPolicyBindingsRequest'];

coerce 'SearchPrincipalAccessBoundaryPolicyBindingsRequest',
    from HashRef, via { 'Google::Iam::V3::PrincipalAccessBoundaryPoliciesService::SearchPrincipalAccessBoundaryPolicyBindingsRequest'->new($_) };

declare 'RepeatedSearchPrincipalAccessBoundaryPolicyBindingsRequest',
    as ArrayRef[SearchPrincipalAccessBoundaryPolicyBindingsRequest()];

coerce 'RepeatedSearchPrincipalAccessBoundaryPolicyBindingsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Iam::V3::PrincipalAccessBoundaryPoliciesService::SearchPrincipalAccessBoundaryPolicyBindingsRequest'->new($_) } @$_ ] };

declare 'MapStringSearchPrincipalAccessBoundaryPolicyBindingsRequest',
    as HashRef[SearchPrincipalAccessBoundaryPolicyBindingsRequest()];

declare 'SearchPrincipalAccessBoundaryPolicyBindingsResponse',
    as InstanceOf['Google::Iam::V3::PrincipalAccessBoundaryPoliciesService::SearchPrincipalAccessBoundaryPolicyBindingsResponse'];

coerce 'SearchPrincipalAccessBoundaryPolicyBindingsResponse',
    from HashRef, via { 'Google::Iam::V3::PrincipalAccessBoundaryPoliciesService::SearchPrincipalAccessBoundaryPolicyBindingsResponse'->new($_) };

declare 'RepeatedSearchPrincipalAccessBoundaryPolicyBindingsResponse',
    as ArrayRef[SearchPrincipalAccessBoundaryPolicyBindingsResponse()];

coerce 'RepeatedSearchPrincipalAccessBoundaryPolicyBindingsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Iam::V3::PrincipalAccessBoundaryPoliciesService::SearchPrincipalAccessBoundaryPolicyBindingsResponse'->new($_) } @$_ ] };

declare 'MapStringSearchPrincipalAccessBoundaryPolicyBindingsResponse',
    as HashRef[SearchPrincipalAccessBoundaryPolicyBindingsResponse()];

1;

__END__

=head1 NAME

Google::Iam::V3::PrincipalAccessBoundaryPoliciesService::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
