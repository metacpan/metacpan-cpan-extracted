package Google::Cloud::Networksecurity::V1::UrlList::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'UrlList',
    as InstanceOf['Google::Cloud::Networksecurity::V1::UrlList::UrlList'];

coerce 'UrlList',
    from HashRef, via { 'Google::Cloud::Networksecurity::V1::UrlList::UrlList'->new($_) };

declare 'RepeatedUrlList',
    as ArrayRef[UrlList()];

coerce 'RepeatedUrlList',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networksecurity::V1::UrlList::UrlList'->new($_) } @$_ ] };

declare 'MapStringUrlList',
    as HashRef[UrlList()];

declare 'ListUrlListsRequest',
    as InstanceOf['Google::Cloud::Networksecurity::V1::UrlList::ListUrlListsRequest'];

coerce 'ListUrlListsRequest',
    from HashRef, via { 'Google::Cloud::Networksecurity::V1::UrlList::ListUrlListsRequest'->new($_) };

declare 'RepeatedListUrlListsRequest',
    as ArrayRef[ListUrlListsRequest()];

coerce 'RepeatedListUrlListsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networksecurity::V1::UrlList::ListUrlListsRequest'->new($_) } @$_ ] };

declare 'MapStringListUrlListsRequest',
    as HashRef[ListUrlListsRequest()];

declare 'ListUrlListsResponse',
    as InstanceOf['Google::Cloud::Networksecurity::V1::UrlList::ListUrlListsResponse'];

coerce 'ListUrlListsResponse',
    from HashRef, via { 'Google::Cloud::Networksecurity::V1::UrlList::ListUrlListsResponse'->new($_) };

declare 'RepeatedListUrlListsResponse',
    as ArrayRef[ListUrlListsResponse()];

coerce 'RepeatedListUrlListsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networksecurity::V1::UrlList::ListUrlListsResponse'->new($_) } @$_ ] };

declare 'MapStringListUrlListsResponse',
    as HashRef[ListUrlListsResponse()];

declare 'GetUrlListRequest',
    as InstanceOf['Google::Cloud::Networksecurity::V1::UrlList::GetUrlListRequest'];

coerce 'GetUrlListRequest',
    from HashRef, via { 'Google::Cloud::Networksecurity::V1::UrlList::GetUrlListRequest'->new($_) };

declare 'RepeatedGetUrlListRequest',
    as ArrayRef[GetUrlListRequest()];

coerce 'RepeatedGetUrlListRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networksecurity::V1::UrlList::GetUrlListRequest'->new($_) } @$_ ] };

declare 'MapStringGetUrlListRequest',
    as HashRef[GetUrlListRequest()];

declare 'CreateUrlListRequest',
    as InstanceOf['Google::Cloud::Networksecurity::V1::UrlList::CreateUrlListRequest'];

coerce 'CreateUrlListRequest',
    from HashRef, via { 'Google::Cloud::Networksecurity::V1::UrlList::CreateUrlListRequest'->new($_) };

declare 'RepeatedCreateUrlListRequest',
    as ArrayRef[CreateUrlListRequest()];

coerce 'RepeatedCreateUrlListRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networksecurity::V1::UrlList::CreateUrlListRequest'->new($_) } @$_ ] };

declare 'MapStringCreateUrlListRequest',
    as HashRef[CreateUrlListRequest()];

declare 'UpdateUrlListRequest',
    as InstanceOf['Google::Cloud::Networksecurity::V1::UrlList::UpdateUrlListRequest'];

coerce 'UpdateUrlListRequest',
    from HashRef, via { 'Google::Cloud::Networksecurity::V1::UrlList::UpdateUrlListRequest'->new($_) };

declare 'RepeatedUpdateUrlListRequest',
    as ArrayRef[UpdateUrlListRequest()];

coerce 'RepeatedUpdateUrlListRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networksecurity::V1::UrlList::UpdateUrlListRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateUrlListRequest',
    as HashRef[UpdateUrlListRequest()];

declare 'DeleteUrlListRequest',
    as InstanceOf['Google::Cloud::Networksecurity::V1::UrlList::DeleteUrlListRequest'];

coerce 'DeleteUrlListRequest',
    from HashRef, via { 'Google::Cloud::Networksecurity::V1::UrlList::DeleteUrlListRequest'->new($_) };

declare 'RepeatedDeleteUrlListRequest',
    as ArrayRef[DeleteUrlListRequest()];

coerce 'RepeatedDeleteUrlListRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networksecurity::V1::UrlList::DeleteUrlListRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteUrlListRequest',
    as HashRef[DeleteUrlListRequest()];

1;

__END__

=head1 NAME

Google::Cloud::Networksecurity::V1::UrlList::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
