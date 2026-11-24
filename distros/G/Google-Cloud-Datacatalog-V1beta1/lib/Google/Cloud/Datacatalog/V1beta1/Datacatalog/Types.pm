package Google::Cloud::Datacatalog::V1beta1::Datacatalog::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'EntryType',
    as (Int | Str);

declare 'SearchCatalogRequest',
    as InstanceOf['Google::Cloud::Datacatalog::V1beta1::Datacatalog::SearchCatalogRequest'];

coerce 'SearchCatalogRequest',
    from HashRef, via { 'Google::Cloud::Datacatalog::V1beta1::Datacatalog::SearchCatalogRequest'->new($_) };

declare 'RepeatedSearchCatalogRequest',
    as ArrayRef[SearchCatalogRequest()];

coerce 'RepeatedSearchCatalogRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datacatalog::V1beta1::Datacatalog::SearchCatalogRequest'->new($_) } @$_ ] };

declare 'MapStringSearchCatalogRequest',
    as HashRef[SearchCatalogRequest()];

declare 'Scope',
    as InstanceOf['Google::Cloud::Datacatalog::V1beta1::Datacatalog::SearchCatalogRequest::Scope'];

coerce 'Scope',
    from HashRef, via { 'Google::Cloud::Datacatalog::V1beta1::Datacatalog::SearchCatalogRequest::Scope'->new($_) };

declare 'RepeatedScope',
    as ArrayRef[Scope()];

coerce 'RepeatedScope',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datacatalog::V1beta1::Datacatalog::SearchCatalogRequest::Scope'->new($_) } @$_ ] };

declare 'MapStringScope',
    as HashRef[Scope()];

declare 'SearchCatalogResponse',
    as InstanceOf['Google::Cloud::Datacatalog::V1beta1::Datacatalog::SearchCatalogResponse'];

coerce 'SearchCatalogResponse',
    from HashRef, via { 'Google::Cloud::Datacatalog::V1beta1::Datacatalog::SearchCatalogResponse'->new($_) };

declare 'RepeatedSearchCatalogResponse',
    as ArrayRef[SearchCatalogResponse()];

coerce 'RepeatedSearchCatalogResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datacatalog::V1beta1::Datacatalog::SearchCatalogResponse'->new($_) } @$_ ] };

declare 'MapStringSearchCatalogResponse',
    as HashRef[SearchCatalogResponse()];

declare 'CreateEntryGroupRequest',
    as InstanceOf['Google::Cloud::Datacatalog::V1beta1::Datacatalog::CreateEntryGroupRequest'];

coerce 'CreateEntryGroupRequest',
    from HashRef, via { 'Google::Cloud::Datacatalog::V1beta1::Datacatalog::CreateEntryGroupRequest'->new($_) };

declare 'RepeatedCreateEntryGroupRequest',
    as ArrayRef[CreateEntryGroupRequest()];

coerce 'RepeatedCreateEntryGroupRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datacatalog::V1beta1::Datacatalog::CreateEntryGroupRequest'->new($_) } @$_ ] };

declare 'MapStringCreateEntryGroupRequest',
    as HashRef[CreateEntryGroupRequest()];

declare 'UpdateEntryGroupRequest',
    as InstanceOf['Google::Cloud::Datacatalog::V1beta1::Datacatalog::UpdateEntryGroupRequest'];

coerce 'UpdateEntryGroupRequest',
    from HashRef, via { 'Google::Cloud::Datacatalog::V1beta1::Datacatalog::UpdateEntryGroupRequest'->new($_) };

declare 'RepeatedUpdateEntryGroupRequest',
    as ArrayRef[UpdateEntryGroupRequest()];

coerce 'RepeatedUpdateEntryGroupRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datacatalog::V1beta1::Datacatalog::UpdateEntryGroupRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateEntryGroupRequest',
    as HashRef[UpdateEntryGroupRequest()];

declare 'GetEntryGroupRequest',
    as InstanceOf['Google::Cloud::Datacatalog::V1beta1::Datacatalog::GetEntryGroupRequest'];

coerce 'GetEntryGroupRequest',
    from HashRef, via { 'Google::Cloud::Datacatalog::V1beta1::Datacatalog::GetEntryGroupRequest'->new($_) };

declare 'RepeatedGetEntryGroupRequest',
    as ArrayRef[GetEntryGroupRequest()];

coerce 'RepeatedGetEntryGroupRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datacatalog::V1beta1::Datacatalog::GetEntryGroupRequest'->new($_) } @$_ ] };

declare 'MapStringGetEntryGroupRequest',
    as HashRef[GetEntryGroupRequest()];

declare 'DeleteEntryGroupRequest',
    as InstanceOf['Google::Cloud::Datacatalog::V1beta1::Datacatalog::DeleteEntryGroupRequest'];

coerce 'DeleteEntryGroupRequest',
    from HashRef, via { 'Google::Cloud::Datacatalog::V1beta1::Datacatalog::DeleteEntryGroupRequest'->new($_) };

declare 'RepeatedDeleteEntryGroupRequest',
    as ArrayRef[DeleteEntryGroupRequest()];

coerce 'RepeatedDeleteEntryGroupRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datacatalog::V1beta1::Datacatalog::DeleteEntryGroupRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteEntryGroupRequest',
    as HashRef[DeleteEntryGroupRequest()];

declare 'ListEntryGroupsRequest',
    as InstanceOf['Google::Cloud::Datacatalog::V1beta1::Datacatalog::ListEntryGroupsRequest'];

coerce 'ListEntryGroupsRequest',
    from HashRef, via { 'Google::Cloud::Datacatalog::V1beta1::Datacatalog::ListEntryGroupsRequest'->new($_) };

declare 'RepeatedListEntryGroupsRequest',
    as ArrayRef[ListEntryGroupsRequest()];

coerce 'RepeatedListEntryGroupsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datacatalog::V1beta1::Datacatalog::ListEntryGroupsRequest'->new($_) } @$_ ] };

declare 'MapStringListEntryGroupsRequest',
    as HashRef[ListEntryGroupsRequest()];

declare 'ListEntryGroupsResponse',
    as InstanceOf['Google::Cloud::Datacatalog::V1beta1::Datacatalog::ListEntryGroupsResponse'];

coerce 'ListEntryGroupsResponse',
    from HashRef, via { 'Google::Cloud::Datacatalog::V1beta1::Datacatalog::ListEntryGroupsResponse'->new($_) };

declare 'RepeatedListEntryGroupsResponse',
    as ArrayRef[ListEntryGroupsResponse()];

coerce 'RepeatedListEntryGroupsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datacatalog::V1beta1::Datacatalog::ListEntryGroupsResponse'->new($_) } @$_ ] };

declare 'MapStringListEntryGroupsResponse',
    as HashRef[ListEntryGroupsResponse()];

declare 'CreateEntryRequest',
    as InstanceOf['Google::Cloud::Datacatalog::V1beta1::Datacatalog::CreateEntryRequest'];

coerce 'CreateEntryRequest',
    from HashRef, via { 'Google::Cloud::Datacatalog::V1beta1::Datacatalog::CreateEntryRequest'->new($_) };

declare 'RepeatedCreateEntryRequest',
    as ArrayRef[CreateEntryRequest()];

coerce 'RepeatedCreateEntryRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datacatalog::V1beta1::Datacatalog::CreateEntryRequest'->new($_) } @$_ ] };

declare 'MapStringCreateEntryRequest',
    as HashRef[CreateEntryRequest()];

declare 'UpdateEntryRequest',
    as InstanceOf['Google::Cloud::Datacatalog::V1beta1::Datacatalog::UpdateEntryRequest'];

coerce 'UpdateEntryRequest',
    from HashRef, via { 'Google::Cloud::Datacatalog::V1beta1::Datacatalog::UpdateEntryRequest'->new($_) };

declare 'RepeatedUpdateEntryRequest',
    as ArrayRef[UpdateEntryRequest()];

coerce 'RepeatedUpdateEntryRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datacatalog::V1beta1::Datacatalog::UpdateEntryRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateEntryRequest',
    as HashRef[UpdateEntryRequest()];

declare 'DeleteEntryRequest',
    as InstanceOf['Google::Cloud::Datacatalog::V1beta1::Datacatalog::DeleteEntryRequest'];

coerce 'DeleteEntryRequest',
    from HashRef, via { 'Google::Cloud::Datacatalog::V1beta1::Datacatalog::DeleteEntryRequest'->new($_) };

declare 'RepeatedDeleteEntryRequest',
    as ArrayRef[DeleteEntryRequest()];

coerce 'RepeatedDeleteEntryRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datacatalog::V1beta1::Datacatalog::DeleteEntryRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteEntryRequest',
    as HashRef[DeleteEntryRequest()];

declare 'GetEntryRequest',
    as InstanceOf['Google::Cloud::Datacatalog::V1beta1::Datacatalog::GetEntryRequest'];

coerce 'GetEntryRequest',
    from HashRef, via { 'Google::Cloud::Datacatalog::V1beta1::Datacatalog::GetEntryRequest'->new($_) };

declare 'RepeatedGetEntryRequest',
    as ArrayRef[GetEntryRequest()];

coerce 'RepeatedGetEntryRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datacatalog::V1beta1::Datacatalog::GetEntryRequest'->new($_) } @$_ ] };

declare 'MapStringGetEntryRequest',
    as HashRef[GetEntryRequest()];

declare 'LookupEntryRequest',
    as InstanceOf['Google::Cloud::Datacatalog::V1beta1::Datacatalog::LookupEntryRequest'];

coerce 'LookupEntryRequest',
    from HashRef, via { 'Google::Cloud::Datacatalog::V1beta1::Datacatalog::LookupEntryRequest'->new($_) };

declare 'RepeatedLookupEntryRequest',
    as ArrayRef[LookupEntryRequest()];

coerce 'RepeatedLookupEntryRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datacatalog::V1beta1::Datacatalog::LookupEntryRequest'->new($_) } @$_ ] };

declare 'MapStringLookupEntryRequest',
    as HashRef[LookupEntryRequest()];

declare 'Entry',
    as InstanceOf['Google::Cloud::Datacatalog::V1beta1::Datacatalog::Entry'];

coerce 'Entry',
    from HashRef, via { 'Google::Cloud::Datacatalog::V1beta1::Datacatalog::Entry'->new($_) };

declare 'RepeatedEntry',
    as ArrayRef[Entry()];

coerce 'RepeatedEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datacatalog::V1beta1::Datacatalog::Entry'->new($_) } @$_ ] };

declare 'MapStringEntry',
    as HashRef[Entry()];

declare 'EntryGroup',
    as InstanceOf['Google::Cloud::Datacatalog::V1beta1::Datacatalog::EntryGroup'];

coerce 'EntryGroup',
    from HashRef, via { 'Google::Cloud::Datacatalog::V1beta1::Datacatalog::EntryGroup'->new($_) };

declare 'RepeatedEntryGroup',
    as ArrayRef[EntryGroup()];

coerce 'RepeatedEntryGroup',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datacatalog::V1beta1::Datacatalog::EntryGroup'->new($_) } @$_ ] };

declare 'MapStringEntryGroup',
    as HashRef[EntryGroup()];

declare 'CreateTagTemplateRequest',
    as InstanceOf['Google::Cloud::Datacatalog::V1beta1::Datacatalog::CreateTagTemplateRequest'];

coerce 'CreateTagTemplateRequest',
    from HashRef, via { 'Google::Cloud::Datacatalog::V1beta1::Datacatalog::CreateTagTemplateRequest'->new($_) };

declare 'RepeatedCreateTagTemplateRequest',
    as ArrayRef[CreateTagTemplateRequest()];

coerce 'RepeatedCreateTagTemplateRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datacatalog::V1beta1::Datacatalog::CreateTagTemplateRequest'->new($_) } @$_ ] };

declare 'MapStringCreateTagTemplateRequest',
    as HashRef[CreateTagTemplateRequest()];

declare 'GetTagTemplateRequest',
    as InstanceOf['Google::Cloud::Datacatalog::V1beta1::Datacatalog::GetTagTemplateRequest'];

coerce 'GetTagTemplateRequest',
    from HashRef, via { 'Google::Cloud::Datacatalog::V1beta1::Datacatalog::GetTagTemplateRequest'->new($_) };

declare 'RepeatedGetTagTemplateRequest',
    as ArrayRef[GetTagTemplateRequest()];

coerce 'RepeatedGetTagTemplateRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datacatalog::V1beta1::Datacatalog::GetTagTemplateRequest'->new($_) } @$_ ] };

declare 'MapStringGetTagTemplateRequest',
    as HashRef[GetTagTemplateRequest()];

declare 'UpdateTagTemplateRequest',
    as InstanceOf['Google::Cloud::Datacatalog::V1beta1::Datacatalog::UpdateTagTemplateRequest'];

coerce 'UpdateTagTemplateRequest',
    from HashRef, via { 'Google::Cloud::Datacatalog::V1beta1::Datacatalog::UpdateTagTemplateRequest'->new($_) };

declare 'RepeatedUpdateTagTemplateRequest',
    as ArrayRef[UpdateTagTemplateRequest()];

coerce 'RepeatedUpdateTagTemplateRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datacatalog::V1beta1::Datacatalog::UpdateTagTemplateRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateTagTemplateRequest',
    as HashRef[UpdateTagTemplateRequest()];

declare 'DeleteTagTemplateRequest',
    as InstanceOf['Google::Cloud::Datacatalog::V1beta1::Datacatalog::DeleteTagTemplateRequest'];

coerce 'DeleteTagTemplateRequest',
    from HashRef, via { 'Google::Cloud::Datacatalog::V1beta1::Datacatalog::DeleteTagTemplateRequest'->new($_) };

declare 'RepeatedDeleteTagTemplateRequest',
    as ArrayRef[DeleteTagTemplateRequest()];

coerce 'RepeatedDeleteTagTemplateRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datacatalog::V1beta1::Datacatalog::DeleteTagTemplateRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteTagTemplateRequest',
    as HashRef[DeleteTagTemplateRequest()];

declare 'CreateTagRequest',
    as InstanceOf['Google::Cloud::Datacatalog::V1beta1::Datacatalog::CreateTagRequest'];

coerce 'CreateTagRequest',
    from HashRef, via { 'Google::Cloud::Datacatalog::V1beta1::Datacatalog::CreateTagRequest'->new($_) };

declare 'RepeatedCreateTagRequest',
    as ArrayRef[CreateTagRequest()];

coerce 'RepeatedCreateTagRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datacatalog::V1beta1::Datacatalog::CreateTagRequest'->new($_) } @$_ ] };

declare 'MapStringCreateTagRequest',
    as HashRef[CreateTagRequest()];

declare 'UpdateTagRequest',
    as InstanceOf['Google::Cloud::Datacatalog::V1beta1::Datacatalog::UpdateTagRequest'];

coerce 'UpdateTagRequest',
    from HashRef, via { 'Google::Cloud::Datacatalog::V1beta1::Datacatalog::UpdateTagRequest'->new($_) };

declare 'RepeatedUpdateTagRequest',
    as ArrayRef[UpdateTagRequest()];

coerce 'RepeatedUpdateTagRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datacatalog::V1beta1::Datacatalog::UpdateTagRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateTagRequest',
    as HashRef[UpdateTagRequest()];

declare 'DeleteTagRequest',
    as InstanceOf['Google::Cloud::Datacatalog::V1beta1::Datacatalog::DeleteTagRequest'];

coerce 'DeleteTagRequest',
    from HashRef, via { 'Google::Cloud::Datacatalog::V1beta1::Datacatalog::DeleteTagRequest'->new($_) };

declare 'RepeatedDeleteTagRequest',
    as ArrayRef[DeleteTagRequest()];

coerce 'RepeatedDeleteTagRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datacatalog::V1beta1::Datacatalog::DeleteTagRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteTagRequest',
    as HashRef[DeleteTagRequest()];

declare 'CreateTagTemplateFieldRequest',
    as InstanceOf['Google::Cloud::Datacatalog::V1beta1::Datacatalog::CreateTagTemplateFieldRequest'];

coerce 'CreateTagTemplateFieldRequest',
    from HashRef, via { 'Google::Cloud::Datacatalog::V1beta1::Datacatalog::CreateTagTemplateFieldRequest'->new($_) };

declare 'RepeatedCreateTagTemplateFieldRequest',
    as ArrayRef[CreateTagTemplateFieldRequest()];

coerce 'RepeatedCreateTagTemplateFieldRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datacatalog::V1beta1::Datacatalog::CreateTagTemplateFieldRequest'->new($_) } @$_ ] };

declare 'MapStringCreateTagTemplateFieldRequest',
    as HashRef[CreateTagTemplateFieldRequest()];

declare 'UpdateTagTemplateFieldRequest',
    as InstanceOf['Google::Cloud::Datacatalog::V1beta1::Datacatalog::UpdateTagTemplateFieldRequest'];

coerce 'UpdateTagTemplateFieldRequest',
    from HashRef, via { 'Google::Cloud::Datacatalog::V1beta1::Datacatalog::UpdateTagTemplateFieldRequest'->new($_) };

declare 'RepeatedUpdateTagTemplateFieldRequest',
    as ArrayRef[UpdateTagTemplateFieldRequest()];

coerce 'RepeatedUpdateTagTemplateFieldRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datacatalog::V1beta1::Datacatalog::UpdateTagTemplateFieldRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateTagTemplateFieldRequest',
    as HashRef[UpdateTagTemplateFieldRequest()];

declare 'RenameTagTemplateFieldRequest',
    as InstanceOf['Google::Cloud::Datacatalog::V1beta1::Datacatalog::RenameTagTemplateFieldRequest'];

coerce 'RenameTagTemplateFieldRequest',
    from HashRef, via { 'Google::Cloud::Datacatalog::V1beta1::Datacatalog::RenameTagTemplateFieldRequest'->new($_) };

declare 'RepeatedRenameTagTemplateFieldRequest',
    as ArrayRef[RenameTagTemplateFieldRequest()];

coerce 'RepeatedRenameTagTemplateFieldRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datacatalog::V1beta1::Datacatalog::RenameTagTemplateFieldRequest'->new($_) } @$_ ] };

declare 'MapStringRenameTagTemplateFieldRequest',
    as HashRef[RenameTagTemplateFieldRequest()];

declare 'RenameTagTemplateFieldEnumValueRequest',
    as InstanceOf['Google::Cloud::Datacatalog::V1beta1::Datacatalog::RenameTagTemplateFieldEnumValueRequest'];

coerce 'RenameTagTemplateFieldEnumValueRequest',
    from HashRef, via { 'Google::Cloud::Datacatalog::V1beta1::Datacatalog::RenameTagTemplateFieldEnumValueRequest'->new($_) };

declare 'RepeatedRenameTagTemplateFieldEnumValueRequest',
    as ArrayRef[RenameTagTemplateFieldEnumValueRequest()];

coerce 'RepeatedRenameTagTemplateFieldEnumValueRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datacatalog::V1beta1::Datacatalog::RenameTagTemplateFieldEnumValueRequest'->new($_) } @$_ ] };

declare 'MapStringRenameTagTemplateFieldEnumValueRequest',
    as HashRef[RenameTagTemplateFieldEnumValueRequest()];

declare 'DeleteTagTemplateFieldRequest',
    as InstanceOf['Google::Cloud::Datacatalog::V1beta1::Datacatalog::DeleteTagTemplateFieldRequest'];

coerce 'DeleteTagTemplateFieldRequest',
    from HashRef, via { 'Google::Cloud::Datacatalog::V1beta1::Datacatalog::DeleteTagTemplateFieldRequest'->new($_) };

declare 'RepeatedDeleteTagTemplateFieldRequest',
    as ArrayRef[DeleteTagTemplateFieldRequest()];

coerce 'RepeatedDeleteTagTemplateFieldRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datacatalog::V1beta1::Datacatalog::DeleteTagTemplateFieldRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteTagTemplateFieldRequest',
    as HashRef[DeleteTagTemplateFieldRequest()];

declare 'ListTagsRequest',
    as InstanceOf['Google::Cloud::Datacatalog::V1beta1::Datacatalog::ListTagsRequest'];

coerce 'ListTagsRequest',
    from HashRef, via { 'Google::Cloud::Datacatalog::V1beta1::Datacatalog::ListTagsRequest'->new($_) };

declare 'RepeatedListTagsRequest',
    as ArrayRef[ListTagsRequest()];

coerce 'RepeatedListTagsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datacatalog::V1beta1::Datacatalog::ListTagsRequest'->new($_) } @$_ ] };

declare 'MapStringListTagsRequest',
    as HashRef[ListTagsRequest()];

declare 'ListTagsResponse',
    as InstanceOf['Google::Cloud::Datacatalog::V1beta1::Datacatalog::ListTagsResponse'];

coerce 'ListTagsResponse',
    from HashRef, via { 'Google::Cloud::Datacatalog::V1beta1::Datacatalog::ListTagsResponse'->new($_) };

declare 'RepeatedListTagsResponse',
    as ArrayRef[ListTagsResponse()];

coerce 'RepeatedListTagsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datacatalog::V1beta1::Datacatalog::ListTagsResponse'->new($_) } @$_ ] };

declare 'MapStringListTagsResponse',
    as HashRef[ListTagsResponse()];

declare 'ListEntriesRequest',
    as InstanceOf['Google::Cloud::Datacatalog::V1beta1::Datacatalog::ListEntriesRequest'];

coerce 'ListEntriesRequest',
    from HashRef, via { 'Google::Cloud::Datacatalog::V1beta1::Datacatalog::ListEntriesRequest'->new($_) };

declare 'RepeatedListEntriesRequest',
    as ArrayRef[ListEntriesRequest()];

coerce 'RepeatedListEntriesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datacatalog::V1beta1::Datacatalog::ListEntriesRequest'->new($_) } @$_ ] };

declare 'MapStringListEntriesRequest',
    as HashRef[ListEntriesRequest()];

declare 'ListEntriesResponse',
    as InstanceOf['Google::Cloud::Datacatalog::V1beta1::Datacatalog::ListEntriesResponse'];

coerce 'ListEntriesResponse',
    from HashRef, via { 'Google::Cloud::Datacatalog::V1beta1::Datacatalog::ListEntriesResponse'->new($_) };

declare 'RepeatedListEntriesResponse',
    as ArrayRef[ListEntriesResponse()];

coerce 'RepeatedListEntriesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datacatalog::V1beta1::Datacatalog::ListEntriesResponse'->new($_) } @$_ ] };

declare 'MapStringListEntriesResponse',
    as HashRef[ListEntriesResponse()];

1;

__END__

=head1 NAME

Google::Cloud::Datacatalog::V1beta1::Datacatalog::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
