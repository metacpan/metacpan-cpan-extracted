package Google::Iam::V3::PolicyBindingsService::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'CreatePolicyBindingRequest',
    as InstanceOf['Google::Iam::V3::PolicyBindingsService::CreatePolicyBindingRequest'];

coerce 'CreatePolicyBindingRequest',
    from HashRef, via { 'Google::Iam::V3::PolicyBindingsService::CreatePolicyBindingRequest'->new($_) };

declare 'RepeatedCreatePolicyBindingRequest',
    as ArrayRef[CreatePolicyBindingRequest()];

coerce 'RepeatedCreatePolicyBindingRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Iam::V3::PolicyBindingsService::CreatePolicyBindingRequest'->new($_) } @$_ ] };

declare 'MapStringCreatePolicyBindingRequest',
    as HashRef[CreatePolicyBindingRequest()];

declare 'GetPolicyBindingRequest',
    as InstanceOf['Google::Iam::V3::PolicyBindingsService::GetPolicyBindingRequest'];

coerce 'GetPolicyBindingRequest',
    from HashRef, via { 'Google::Iam::V3::PolicyBindingsService::GetPolicyBindingRequest'->new($_) };

declare 'RepeatedGetPolicyBindingRequest',
    as ArrayRef[GetPolicyBindingRequest()];

coerce 'RepeatedGetPolicyBindingRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Iam::V3::PolicyBindingsService::GetPolicyBindingRequest'->new($_) } @$_ ] };

declare 'MapStringGetPolicyBindingRequest',
    as HashRef[GetPolicyBindingRequest()];

declare 'UpdatePolicyBindingRequest',
    as InstanceOf['Google::Iam::V3::PolicyBindingsService::UpdatePolicyBindingRequest'];

coerce 'UpdatePolicyBindingRequest',
    from HashRef, via { 'Google::Iam::V3::PolicyBindingsService::UpdatePolicyBindingRequest'->new($_) };

declare 'RepeatedUpdatePolicyBindingRequest',
    as ArrayRef[UpdatePolicyBindingRequest()];

coerce 'RepeatedUpdatePolicyBindingRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Iam::V3::PolicyBindingsService::UpdatePolicyBindingRequest'->new($_) } @$_ ] };

declare 'MapStringUpdatePolicyBindingRequest',
    as HashRef[UpdatePolicyBindingRequest()];

declare 'DeletePolicyBindingRequest',
    as InstanceOf['Google::Iam::V3::PolicyBindingsService::DeletePolicyBindingRequest'];

coerce 'DeletePolicyBindingRequest',
    from HashRef, via { 'Google::Iam::V3::PolicyBindingsService::DeletePolicyBindingRequest'->new($_) };

declare 'RepeatedDeletePolicyBindingRequest',
    as ArrayRef[DeletePolicyBindingRequest()];

coerce 'RepeatedDeletePolicyBindingRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Iam::V3::PolicyBindingsService::DeletePolicyBindingRequest'->new($_) } @$_ ] };

declare 'MapStringDeletePolicyBindingRequest',
    as HashRef[DeletePolicyBindingRequest()];

declare 'ListPolicyBindingsRequest',
    as InstanceOf['Google::Iam::V3::PolicyBindingsService::ListPolicyBindingsRequest'];

coerce 'ListPolicyBindingsRequest',
    from HashRef, via { 'Google::Iam::V3::PolicyBindingsService::ListPolicyBindingsRequest'->new($_) };

declare 'RepeatedListPolicyBindingsRequest',
    as ArrayRef[ListPolicyBindingsRequest()];

coerce 'RepeatedListPolicyBindingsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Iam::V3::PolicyBindingsService::ListPolicyBindingsRequest'->new($_) } @$_ ] };

declare 'MapStringListPolicyBindingsRequest',
    as HashRef[ListPolicyBindingsRequest()];

declare 'ListPolicyBindingsResponse',
    as InstanceOf['Google::Iam::V3::PolicyBindingsService::ListPolicyBindingsResponse'];

coerce 'ListPolicyBindingsResponse',
    from HashRef, via { 'Google::Iam::V3::PolicyBindingsService::ListPolicyBindingsResponse'->new($_) };

declare 'RepeatedListPolicyBindingsResponse',
    as ArrayRef[ListPolicyBindingsResponse()];

coerce 'RepeatedListPolicyBindingsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Iam::V3::PolicyBindingsService::ListPolicyBindingsResponse'->new($_) } @$_ ] };

declare 'MapStringListPolicyBindingsResponse',
    as HashRef[ListPolicyBindingsResponse()];

declare 'SearchTargetPolicyBindingsRequest',
    as InstanceOf['Google::Iam::V3::PolicyBindingsService::SearchTargetPolicyBindingsRequest'];

coerce 'SearchTargetPolicyBindingsRequest',
    from HashRef, via { 'Google::Iam::V3::PolicyBindingsService::SearchTargetPolicyBindingsRequest'->new($_) };

declare 'RepeatedSearchTargetPolicyBindingsRequest',
    as ArrayRef[SearchTargetPolicyBindingsRequest()];

coerce 'RepeatedSearchTargetPolicyBindingsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Iam::V3::PolicyBindingsService::SearchTargetPolicyBindingsRequest'->new($_) } @$_ ] };

declare 'MapStringSearchTargetPolicyBindingsRequest',
    as HashRef[SearchTargetPolicyBindingsRequest()];

declare 'SearchTargetPolicyBindingsResponse',
    as InstanceOf['Google::Iam::V3::PolicyBindingsService::SearchTargetPolicyBindingsResponse'];

coerce 'SearchTargetPolicyBindingsResponse',
    from HashRef, via { 'Google::Iam::V3::PolicyBindingsService::SearchTargetPolicyBindingsResponse'->new($_) };

declare 'RepeatedSearchTargetPolicyBindingsResponse',
    as ArrayRef[SearchTargetPolicyBindingsResponse()];

coerce 'RepeatedSearchTargetPolicyBindingsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Iam::V3::PolicyBindingsService::SearchTargetPolicyBindingsResponse'->new($_) } @$_ ] };

declare 'MapStringSearchTargetPolicyBindingsResponse',
    as HashRef[SearchTargetPolicyBindingsResponse()];

1;

__END__

=head1 NAME

Google::Iam::V3::PolicyBindingsService::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
