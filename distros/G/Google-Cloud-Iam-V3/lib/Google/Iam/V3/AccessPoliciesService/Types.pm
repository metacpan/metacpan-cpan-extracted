package Google::Iam::V3::AccessPoliciesService::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'CreateAccessPolicyRequest',
    as InstanceOf['Google::Iam::V3::AccessPoliciesService::CreateAccessPolicyRequest'];

coerce 'CreateAccessPolicyRequest',
    from HashRef, via { 'Google::Iam::V3::AccessPoliciesService::CreateAccessPolicyRequest'->new($_) };

declare 'RepeatedCreateAccessPolicyRequest',
    as ArrayRef[CreateAccessPolicyRequest()];

coerce 'RepeatedCreateAccessPolicyRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Iam::V3::AccessPoliciesService::CreateAccessPolicyRequest'->new($_) } @$_ ] };

declare 'MapStringCreateAccessPolicyRequest',
    as HashRef[CreateAccessPolicyRequest()];

declare 'GetAccessPolicyRequest',
    as InstanceOf['Google::Iam::V3::AccessPoliciesService::GetAccessPolicyRequest'];

coerce 'GetAccessPolicyRequest',
    from HashRef, via { 'Google::Iam::V3::AccessPoliciesService::GetAccessPolicyRequest'->new($_) };

declare 'RepeatedGetAccessPolicyRequest',
    as ArrayRef[GetAccessPolicyRequest()];

coerce 'RepeatedGetAccessPolicyRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Iam::V3::AccessPoliciesService::GetAccessPolicyRequest'->new($_) } @$_ ] };

declare 'MapStringGetAccessPolicyRequest',
    as HashRef[GetAccessPolicyRequest()];

declare 'UpdateAccessPolicyRequest',
    as InstanceOf['Google::Iam::V3::AccessPoliciesService::UpdateAccessPolicyRequest'];

coerce 'UpdateAccessPolicyRequest',
    from HashRef, via { 'Google::Iam::V3::AccessPoliciesService::UpdateAccessPolicyRequest'->new($_) };

declare 'RepeatedUpdateAccessPolicyRequest',
    as ArrayRef[UpdateAccessPolicyRequest()];

coerce 'RepeatedUpdateAccessPolicyRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Iam::V3::AccessPoliciesService::UpdateAccessPolicyRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateAccessPolicyRequest',
    as HashRef[UpdateAccessPolicyRequest()];

declare 'DeleteAccessPolicyRequest',
    as InstanceOf['Google::Iam::V3::AccessPoliciesService::DeleteAccessPolicyRequest'];

coerce 'DeleteAccessPolicyRequest',
    from HashRef, via { 'Google::Iam::V3::AccessPoliciesService::DeleteAccessPolicyRequest'->new($_) };

declare 'RepeatedDeleteAccessPolicyRequest',
    as ArrayRef[DeleteAccessPolicyRequest()];

coerce 'RepeatedDeleteAccessPolicyRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Iam::V3::AccessPoliciesService::DeleteAccessPolicyRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteAccessPolicyRequest',
    as HashRef[DeleteAccessPolicyRequest()];

declare 'ListAccessPoliciesRequest',
    as InstanceOf['Google::Iam::V3::AccessPoliciesService::ListAccessPoliciesRequest'];

coerce 'ListAccessPoliciesRequest',
    from HashRef, via { 'Google::Iam::V3::AccessPoliciesService::ListAccessPoliciesRequest'->new($_) };

declare 'RepeatedListAccessPoliciesRequest',
    as ArrayRef[ListAccessPoliciesRequest()];

coerce 'RepeatedListAccessPoliciesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Iam::V3::AccessPoliciesService::ListAccessPoliciesRequest'->new($_) } @$_ ] };

declare 'MapStringListAccessPoliciesRequest',
    as HashRef[ListAccessPoliciesRequest()];

declare 'ListAccessPoliciesResponse',
    as InstanceOf['Google::Iam::V3::AccessPoliciesService::ListAccessPoliciesResponse'];

coerce 'ListAccessPoliciesResponse',
    from HashRef, via { 'Google::Iam::V3::AccessPoliciesService::ListAccessPoliciesResponse'->new($_) };

declare 'RepeatedListAccessPoliciesResponse',
    as ArrayRef[ListAccessPoliciesResponse()];

coerce 'RepeatedListAccessPoliciesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Iam::V3::AccessPoliciesService::ListAccessPoliciesResponse'->new($_) } @$_ ] };

declare 'MapStringListAccessPoliciesResponse',
    as HashRef[ListAccessPoliciesResponse()];

declare 'SearchAccessPolicyBindingsRequest',
    as InstanceOf['Google::Iam::V3::AccessPoliciesService::SearchAccessPolicyBindingsRequest'];

coerce 'SearchAccessPolicyBindingsRequest',
    from HashRef, via { 'Google::Iam::V3::AccessPoliciesService::SearchAccessPolicyBindingsRequest'->new($_) };

declare 'RepeatedSearchAccessPolicyBindingsRequest',
    as ArrayRef[SearchAccessPolicyBindingsRequest()];

coerce 'RepeatedSearchAccessPolicyBindingsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Iam::V3::AccessPoliciesService::SearchAccessPolicyBindingsRequest'->new($_) } @$_ ] };

declare 'MapStringSearchAccessPolicyBindingsRequest',
    as HashRef[SearchAccessPolicyBindingsRequest()];

declare 'SearchAccessPolicyBindingsResponse',
    as InstanceOf['Google::Iam::V3::AccessPoliciesService::SearchAccessPolicyBindingsResponse'];

coerce 'SearchAccessPolicyBindingsResponse',
    from HashRef, via { 'Google::Iam::V3::AccessPoliciesService::SearchAccessPolicyBindingsResponse'->new($_) };

declare 'RepeatedSearchAccessPolicyBindingsResponse',
    as ArrayRef[SearchAccessPolicyBindingsResponse()];

coerce 'RepeatedSearchAccessPolicyBindingsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Iam::V3::AccessPoliciesService::SearchAccessPolicyBindingsResponse'->new($_) } @$_ ] };

declare 'MapStringSearchAccessPolicyBindingsResponse',
    as HashRef[SearchAccessPolicyBindingsResponse()];

1;

__END__

=head1 NAME

Google::Iam::V3::AccessPoliciesService::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
