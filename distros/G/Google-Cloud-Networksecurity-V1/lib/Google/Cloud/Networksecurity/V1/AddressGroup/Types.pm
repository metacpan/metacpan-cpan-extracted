package Google::Cloud::Networksecurity::V1::AddressGroup::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'AddressGroup',
    as InstanceOf['Google::Cloud::Networksecurity::V1::AddressGroup::AddressGroup'];

coerce 'AddressGroup',
    from HashRef, via { 'Google::Cloud::Networksecurity::V1::AddressGroup::AddressGroup'->new($_) };

declare 'RepeatedAddressGroup',
    as ArrayRef[AddressGroup()];

coerce 'RepeatedAddressGroup',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networksecurity::V1::AddressGroup::AddressGroup'->new($_) } @$_ ] };

declare 'MapStringAddressGroup',
    as HashRef[AddressGroup()];

declare 'Type',
    as (Int | Str);

declare 'Purpose',
    as (Int | Str);

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Networksecurity::V1::AddressGroup::AddressGroup::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Networksecurity::V1::AddressGroup::AddressGroup::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networksecurity::V1::AddressGroup::AddressGroup::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'ListAddressGroupsRequest',
    as InstanceOf['Google::Cloud::Networksecurity::V1::AddressGroup::ListAddressGroupsRequest'];

coerce 'ListAddressGroupsRequest',
    from HashRef, via { 'Google::Cloud::Networksecurity::V1::AddressGroup::ListAddressGroupsRequest'->new($_) };

declare 'RepeatedListAddressGroupsRequest',
    as ArrayRef[ListAddressGroupsRequest()];

coerce 'RepeatedListAddressGroupsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networksecurity::V1::AddressGroup::ListAddressGroupsRequest'->new($_) } @$_ ] };

declare 'MapStringListAddressGroupsRequest',
    as HashRef[ListAddressGroupsRequest()];

declare 'ListAddressGroupsResponse',
    as InstanceOf['Google::Cloud::Networksecurity::V1::AddressGroup::ListAddressGroupsResponse'];

coerce 'ListAddressGroupsResponse',
    from HashRef, via { 'Google::Cloud::Networksecurity::V1::AddressGroup::ListAddressGroupsResponse'->new($_) };

declare 'RepeatedListAddressGroupsResponse',
    as ArrayRef[ListAddressGroupsResponse()];

coerce 'RepeatedListAddressGroupsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networksecurity::V1::AddressGroup::ListAddressGroupsResponse'->new($_) } @$_ ] };

declare 'MapStringListAddressGroupsResponse',
    as HashRef[ListAddressGroupsResponse()];

declare 'GetAddressGroupRequest',
    as InstanceOf['Google::Cloud::Networksecurity::V1::AddressGroup::GetAddressGroupRequest'];

coerce 'GetAddressGroupRequest',
    from HashRef, via { 'Google::Cloud::Networksecurity::V1::AddressGroup::GetAddressGroupRequest'->new($_) };

declare 'RepeatedGetAddressGroupRequest',
    as ArrayRef[GetAddressGroupRequest()];

coerce 'RepeatedGetAddressGroupRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networksecurity::V1::AddressGroup::GetAddressGroupRequest'->new($_) } @$_ ] };

declare 'MapStringGetAddressGroupRequest',
    as HashRef[GetAddressGroupRequest()];

declare 'CreateAddressGroupRequest',
    as InstanceOf['Google::Cloud::Networksecurity::V1::AddressGroup::CreateAddressGroupRequest'];

coerce 'CreateAddressGroupRequest',
    from HashRef, via { 'Google::Cloud::Networksecurity::V1::AddressGroup::CreateAddressGroupRequest'->new($_) };

declare 'RepeatedCreateAddressGroupRequest',
    as ArrayRef[CreateAddressGroupRequest()];

coerce 'RepeatedCreateAddressGroupRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networksecurity::V1::AddressGroup::CreateAddressGroupRequest'->new($_) } @$_ ] };

declare 'MapStringCreateAddressGroupRequest',
    as HashRef[CreateAddressGroupRequest()];

declare 'UpdateAddressGroupRequest',
    as InstanceOf['Google::Cloud::Networksecurity::V1::AddressGroup::UpdateAddressGroupRequest'];

coerce 'UpdateAddressGroupRequest',
    from HashRef, via { 'Google::Cloud::Networksecurity::V1::AddressGroup::UpdateAddressGroupRequest'->new($_) };

declare 'RepeatedUpdateAddressGroupRequest',
    as ArrayRef[UpdateAddressGroupRequest()];

coerce 'RepeatedUpdateAddressGroupRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networksecurity::V1::AddressGroup::UpdateAddressGroupRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateAddressGroupRequest',
    as HashRef[UpdateAddressGroupRequest()];

declare 'DeleteAddressGroupRequest',
    as InstanceOf['Google::Cloud::Networksecurity::V1::AddressGroup::DeleteAddressGroupRequest'];

coerce 'DeleteAddressGroupRequest',
    from HashRef, via { 'Google::Cloud::Networksecurity::V1::AddressGroup::DeleteAddressGroupRequest'->new($_) };

declare 'RepeatedDeleteAddressGroupRequest',
    as ArrayRef[DeleteAddressGroupRequest()];

coerce 'RepeatedDeleteAddressGroupRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networksecurity::V1::AddressGroup::DeleteAddressGroupRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteAddressGroupRequest',
    as HashRef[DeleteAddressGroupRequest()];

declare 'AddAddressGroupItemsRequest',
    as InstanceOf['Google::Cloud::Networksecurity::V1::AddressGroup::AddAddressGroupItemsRequest'];

coerce 'AddAddressGroupItemsRequest',
    from HashRef, via { 'Google::Cloud::Networksecurity::V1::AddressGroup::AddAddressGroupItemsRequest'->new($_) };

declare 'RepeatedAddAddressGroupItemsRequest',
    as ArrayRef[AddAddressGroupItemsRequest()];

coerce 'RepeatedAddAddressGroupItemsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networksecurity::V1::AddressGroup::AddAddressGroupItemsRequest'->new($_) } @$_ ] };

declare 'MapStringAddAddressGroupItemsRequest',
    as HashRef[AddAddressGroupItemsRequest()];

declare 'RemoveAddressGroupItemsRequest',
    as InstanceOf['Google::Cloud::Networksecurity::V1::AddressGroup::RemoveAddressGroupItemsRequest'];

coerce 'RemoveAddressGroupItemsRequest',
    from HashRef, via { 'Google::Cloud::Networksecurity::V1::AddressGroup::RemoveAddressGroupItemsRequest'->new($_) };

declare 'RepeatedRemoveAddressGroupItemsRequest',
    as ArrayRef[RemoveAddressGroupItemsRequest()];

coerce 'RepeatedRemoveAddressGroupItemsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networksecurity::V1::AddressGroup::RemoveAddressGroupItemsRequest'->new($_) } @$_ ] };

declare 'MapStringRemoveAddressGroupItemsRequest',
    as HashRef[RemoveAddressGroupItemsRequest()];

declare 'CloneAddressGroupItemsRequest',
    as InstanceOf['Google::Cloud::Networksecurity::V1::AddressGroup::CloneAddressGroupItemsRequest'];

coerce 'CloneAddressGroupItemsRequest',
    from HashRef, via { 'Google::Cloud::Networksecurity::V1::AddressGroup::CloneAddressGroupItemsRequest'->new($_) };

declare 'RepeatedCloneAddressGroupItemsRequest',
    as ArrayRef[CloneAddressGroupItemsRequest()];

coerce 'RepeatedCloneAddressGroupItemsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networksecurity::V1::AddressGroup::CloneAddressGroupItemsRequest'->new($_) } @$_ ] };

declare 'MapStringCloneAddressGroupItemsRequest',
    as HashRef[CloneAddressGroupItemsRequest()];

declare 'ListAddressGroupReferencesRequest',
    as InstanceOf['Google::Cloud::Networksecurity::V1::AddressGroup::ListAddressGroupReferencesRequest'];

coerce 'ListAddressGroupReferencesRequest',
    from HashRef, via { 'Google::Cloud::Networksecurity::V1::AddressGroup::ListAddressGroupReferencesRequest'->new($_) };

declare 'RepeatedListAddressGroupReferencesRequest',
    as ArrayRef[ListAddressGroupReferencesRequest()];

coerce 'RepeatedListAddressGroupReferencesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networksecurity::V1::AddressGroup::ListAddressGroupReferencesRequest'->new($_) } @$_ ] };

declare 'MapStringListAddressGroupReferencesRequest',
    as HashRef[ListAddressGroupReferencesRequest()];

declare 'ListAddressGroupReferencesResponse',
    as InstanceOf['Google::Cloud::Networksecurity::V1::AddressGroup::ListAddressGroupReferencesResponse'];

coerce 'ListAddressGroupReferencesResponse',
    from HashRef, via { 'Google::Cloud::Networksecurity::V1::AddressGroup::ListAddressGroupReferencesResponse'->new($_) };

declare 'RepeatedListAddressGroupReferencesResponse',
    as ArrayRef[ListAddressGroupReferencesResponse()];

coerce 'RepeatedListAddressGroupReferencesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networksecurity::V1::AddressGroup::ListAddressGroupReferencesResponse'->new($_) } @$_ ] };

declare 'MapStringListAddressGroupReferencesResponse',
    as HashRef[ListAddressGroupReferencesResponse()];

declare 'AddressGroupReference',
    as InstanceOf['Google::Cloud::Networksecurity::V1::AddressGroup::ListAddressGroupReferencesResponse::AddressGroupReference'];

coerce 'AddressGroupReference',
    from HashRef, via { 'Google::Cloud::Networksecurity::V1::AddressGroup::ListAddressGroupReferencesResponse::AddressGroupReference'->new($_) };

declare 'RepeatedAddressGroupReference',
    as ArrayRef[AddressGroupReference()];

coerce 'RepeatedAddressGroupReference',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networksecurity::V1::AddressGroup::ListAddressGroupReferencesResponse::AddressGroupReference'->new($_) } @$_ ] };

declare 'MapStringAddressGroupReference',
    as HashRef[AddressGroupReference()];

1;

__END__

=head1 NAME

Google::Cloud::Networksecurity::V1::AddressGroup::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
