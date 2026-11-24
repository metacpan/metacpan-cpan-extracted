package Google::Cloud::Chronicle::V1::ReferenceList::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'ReferenceListSyntaxType',
    as (Int | Str);

declare 'ReferenceListView',
    as (Int | Str);

declare 'ScopeInfo',
    as InstanceOf['Google::Cloud::Chronicle::V1::ReferenceList::ScopeInfo'];

coerce 'ScopeInfo',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::ReferenceList::ScopeInfo'->new($_) };

declare 'RepeatedScopeInfo',
    as ArrayRef[ScopeInfo()];

coerce 'RepeatedScopeInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::ReferenceList::ScopeInfo'->new($_) } @$_ ] };

declare 'MapStringScopeInfo',
    as HashRef[ScopeInfo()];

declare 'ReferenceListScope',
    as InstanceOf['Google::Cloud::Chronicle::V1::ReferenceList::ReferenceListScope'];

coerce 'ReferenceListScope',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::ReferenceList::ReferenceListScope'->new($_) };

declare 'RepeatedReferenceListScope',
    as ArrayRef[ReferenceListScope()];

coerce 'RepeatedReferenceListScope',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::ReferenceList::ReferenceListScope'->new($_) } @$_ ] };

declare 'MapStringReferenceListScope',
    as HashRef[ReferenceListScope()];

declare 'GetReferenceListRequest',
    as InstanceOf['Google::Cloud::Chronicle::V1::ReferenceList::GetReferenceListRequest'];

coerce 'GetReferenceListRequest',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::ReferenceList::GetReferenceListRequest'->new($_) };

declare 'RepeatedGetReferenceListRequest',
    as ArrayRef[GetReferenceListRequest()];

coerce 'RepeatedGetReferenceListRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::ReferenceList::GetReferenceListRequest'->new($_) } @$_ ] };

declare 'MapStringGetReferenceListRequest',
    as HashRef[GetReferenceListRequest()];

declare 'ListReferenceListsRequest',
    as InstanceOf['Google::Cloud::Chronicle::V1::ReferenceList::ListReferenceListsRequest'];

coerce 'ListReferenceListsRequest',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::ReferenceList::ListReferenceListsRequest'->new($_) };

declare 'RepeatedListReferenceListsRequest',
    as ArrayRef[ListReferenceListsRequest()];

coerce 'RepeatedListReferenceListsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::ReferenceList::ListReferenceListsRequest'->new($_) } @$_ ] };

declare 'MapStringListReferenceListsRequest',
    as HashRef[ListReferenceListsRequest()];

declare 'ListReferenceListsResponse',
    as InstanceOf['Google::Cloud::Chronicle::V1::ReferenceList::ListReferenceListsResponse'];

coerce 'ListReferenceListsResponse',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::ReferenceList::ListReferenceListsResponse'->new($_) };

declare 'RepeatedListReferenceListsResponse',
    as ArrayRef[ListReferenceListsResponse()];

coerce 'RepeatedListReferenceListsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::ReferenceList::ListReferenceListsResponse'->new($_) } @$_ ] };

declare 'MapStringListReferenceListsResponse',
    as HashRef[ListReferenceListsResponse()];

declare 'CreateReferenceListRequest',
    as InstanceOf['Google::Cloud::Chronicle::V1::ReferenceList::CreateReferenceListRequest'];

coerce 'CreateReferenceListRequest',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::ReferenceList::CreateReferenceListRequest'->new($_) };

declare 'RepeatedCreateReferenceListRequest',
    as ArrayRef[CreateReferenceListRequest()];

coerce 'RepeatedCreateReferenceListRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::ReferenceList::CreateReferenceListRequest'->new($_) } @$_ ] };

declare 'MapStringCreateReferenceListRequest',
    as HashRef[CreateReferenceListRequest()];

declare 'UpdateReferenceListRequest',
    as InstanceOf['Google::Cloud::Chronicle::V1::ReferenceList::UpdateReferenceListRequest'];

coerce 'UpdateReferenceListRequest',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::ReferenceList::UpdateReferenceListRequest'->new($_) };

declare 'RepeatedUpdateReferenceListRequest',
    as ArrayRef[UpdateReferenceListRequest()];

coerce 'RepeatedUpdateReferenceListRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::ReferenceList::UpdateReferenceListRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateReferenceListRequest',
    as HashRef[UpdateReferenceListRequest()];

declare 'VerifyReferenceListRequest',
    as InstanceOf['Google::Cloud::Chronicle::V1::ReferenceList::VerifyReferenceListRequest'];

coerce 'VerifyReferenceListRequest',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::ReferenceList::VerifyReferenceListRequest'->new($_) };

declare 'RepeatedVerifyReferenceListRequest',
    as ArrayRef[VerifyReferenceListRequest()];

coerce 'RepeatedVerifyReferenceListRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::ReferenceList::VerifyReferenceListRequest'->new($_) } @$_ ] };

declare 'MapStringVerifyReferenceListRequest',
    as HashRef[VerifyReferenceListRequest()];

declare 'VerifyReferenceListResponse',
    as InstanceOf['Google::Cloud::Chronicle::V1::ReferenceList::VerifyReferenceListResponse'];

coerce 'VerifyReferenceListResponse',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::ReferenceList::VerifyReferenceListResponse'->new($_) };

declare 'RepeatedVerifyReferenceListResponse',
    as ArrayRef[VerifyReferenceListResponse()];

coerce 'RepeatedVerifyReferenceListResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::ReferenceList::VerifyReferenceListResponse'->new($_) } @$_ ] };

declare 'MapStringVerifyReferenceListResponse',
    as HashRef[VerifyReferenceListResponse()];

declare 'ReferenceList',
    as InstanceOf['Google::Cloud::Chronicle::V1::ReferenceList::ReferenceList'];

coerce 'ReferenceList',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::ReferenceList::ReferenceList'->new($_) };

declare 'RepeatedReferenceList',
    as ArrayRef[ReferenceList()];

coerce 'RepeatedReferenceList',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::ReferenceList::ReferenceList'->new($_) } @$_ ] };

declare 'MapStringReferenceList',
    as HashRef[ReferenceList()];

declare 'ReferenceListEntry',
    as InstanceOf['Google::Cloud::Chronicle::V1::ReferenceList::ReferenceListEntry'];

coerce 'ReferenceListEntry',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::ReferenceList::ReferenceListEntry'->new($_) };

declare 'RepeatedReferenceListEntry',
    as ArrayRef[ReferenceListEntry()];

coerce 'RepeatedReferenceListEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::ReferenceList::ReferenceListEntry'->new($_) } @$_ ] };

declare 'MapStringReferenceListEntry',
    as HashRef[ReferenceListEntry()];

declare 'ReferenceListError',
    as InstanceOf['Google::Cloud::Chronicle::V1::ReferenceList::ReferenceListError'];

coerce 'ReferenceListError',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::ReferenceList::ReferenceListError'->new($_) };

declare 'RepeatedReferenceListError',
    as ArrayRef[ReferenceListError()];

coerce 'RepeatedReferenceListError',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::ReferenceList::ReferenceListError'->new($_) } @$_ ] };

declare 'MapStringReferenceListError',
    as HashRef[ReferenceListError()];

1;

__END__

=head1 NAME

Google::Cloud::Chronicle::V1::ReferenceList::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
