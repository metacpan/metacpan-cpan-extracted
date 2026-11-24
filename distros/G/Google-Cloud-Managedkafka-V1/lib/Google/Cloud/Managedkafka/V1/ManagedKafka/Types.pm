package Google::Cloud::Managedkafka::V1::ManagedKafka::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'ListClustersRequest',
    as InstanceOf['Google::Cloud::Managedkafka::V1::ManagedKafka::ListClustersRequest'];

coerce 'ListClustersRequest',
    from HashRef, via { 'Google::Cloud::Managedkafka::V1::ManagedKafka::ListClustersRequest'->new($_) };

declare 'RepeatedListClustersRequest',
    as ArrayRef[ListClustersRequest()];

coerce 'RepeatedListClustersRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Managedkafka::V1::ManagedKafka::ListClustersRequest'->new($_) } @$_ ] };

declare 'MapStringListClustersRequest',
    as HashRef[ListClustersRequest()];

declare 'ListClustersResponse',
    as InstanceOf['Google::Cloud::Managedkafka::V1::ManagedKafka::ListClustersResponse'];

coerce 'ListClustersResponse',
    from HashRef, via { 'Google::Cloud::Managedkafka::V1::ManagedKafka::ListClustersResponse'->new($_) };

declare 'RepeatedListClustersResponse',
    as ArrayRef[ListClustersResponse()];

coerce 'RepeatedListClustersResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Managedkafka::V1::ManagedKafka::ListClustersResponse'->new($_) } @$_ ] };

declare 'MapStringListClustersResponse',
    as HashRef[ListClustersResponse()];

declare 'GetClusterRequest',
    as InstanceOf['Google::Cloud::Managedkafka::V1::ManagedKafka::GetClusterRequest'];

coerce 'GetClusterRequest',
    from HashRef, via { 'Google::Cloud::Managedkafka::V1::ManagedKafka::GetClusterRequest'->new($_) };

declare 'RepeatedGetClusterRequest',
    as ArrayRef[GetClusterRequest()];

coerce 'RepeatedGetClusterRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Managedkafka::V1::ManagedKafka::GetClusterRequest'->new($_) } @$_ ] };

declare 'MapStringGetClusterRequest',
    as HashRef[GetClusterRequest()];

declare 'CreateClusterRequest',
    as InstanceOf['Google::Cloud::Managedkafka::V1::ManagedKafka::CreateClusterRequest'];

coerce 'CreateClusterRequest',
    from HashRef, via { 'Google::Cloud::Managedkafka::V1::ManagedKafka::CreateClusterRequest'->new($_) };

declare 'RepeatedCreateClusterRequest',
    as ArrayRef[CreateClusterRequest()];

coerce 'RepeatedCreateClusterRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Managedkafka::V1::ManagedKafka::CreateClusterRequest'->new($_) } @$_ ] };

declare 'MapStringCreateClusterRequest',
    as HashRef[CreateClusterRequest()];

declare 'UpdateClusterRequest',
    as InstanceOf['Google::Cloud::Managedkafka::V1::ManagedKafka::UpdateClusterRequest'];

coerce 'UpdateClusterRequest',
    from HashRef, via { 'Google::Cloud::Managedkafka::V1::ManagedKafka::UpdateClusterRequest'->new($_) };

declare 'RepeatedUpdateClusterRequest',
    as ArrayRef[UpdateClusterRequest()];

coerce 'RepeatedUpdateClusterRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Managedkafka::V1::ManagedKafka::UpdateClusterRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateClusterRequest',
    as HashRef[UpdateClusterRequest()];

declare 'DeleteClusterRequest',
    as InstanceOf['Google::Cloud::Managedkafka::V1::ManagedKafka::DeleteClusterRequest'];

coerce 'DeleteClusterRequest',
    from HashRef, via { 'Google::Cloud::Managedkafka::V1::ManagedKafka::DeleteClusterRequest'->new($_) };

declare 'RepeatedDeleteClusterRequest',
    as ArrayRef[DeleteClusterRequest()];

coerce 'RepeatedDeleteClusterRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Managedkafka::V1::ManagedKafka::DeleteClusterRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteClusterRequest',
    as HashRef[DeleteClusterRequest()];

declare 'ListTopicsRequest',
    as InstanceOf['Google::Cloud::Managedkafka::V1::ManagedKafka::ListTopicsRequest'];

coerce 'ListTopicsRequest',
    from HashRef, via { 'Google::Cloud::Managedkafka::V1::ManagedKafka::ListTopicsRequest'->new($_) };

declare 'RepeatedListTopicsRequest',
    as ArrayRef[ListTopicsRequest()];

coerce 'RepeatedListTopicsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Managedkafka::V1::ManagedKafka::ListTopicsRequest'->new($_) } @$_ ] };

declare 'MapStringListTopicsRequest',
    as HashRef[ListTopicsRequest()];

declare 'ListTopicsResponse',
    as InstanceOf['Google::Cloud::Managedkafka::V1::ManagedKafka::ListTopicsResponse'];

coerce 'ListTopicsResponse',
    from HashRef, via { 'Google::Cloud::Managedkafka::V1::ManagedKafka::ListTopicsResponse'->new($_) };

declare 'RepeatedListTopicsResponse',
    as ArrayRef[ListTopicsResponse()];

coerce 'RepeatedListTopicsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Managedkafka::V1::ManagedKafka::ListTopicsResponse'->new($_) } @$_ ] };

declare 'MapStringListTopicsResponse',
    as HashRef[ListTopicsResponse()];

declare 'GetTopicRequest',
    as InstanceOf['Google::Cloud::Managedkafka::V1::ManagedKafka::GetTopicRequest'];

coerce 'GetTopicRequest',
    from HashRef, via { 'Google::Cloud::Managedkafka::V1::ManagedKafka::GetTopicRequest'->new($_) };

declare 'RepeatedGetTopicRequest',
    as ArrayRef[GetTopicRequest()];

coerce 'RepeatedGetTopicRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Managedkafka::V1::ManagedKafka::GetTopicRequest'->new($_) } @$_ ] };

declare 'MapStringGetTopicRequest',
    as HashRef[GetTopicRequest()];

declare 'CreateTopicRequest',
    as InstanceOf['Google::Cloud::Managedkafka::V1::ManagedKafka::CreateTopicRequest'];

coerce 'CreateTopicRequest',
    from HashRef, via { 'Google::Cloud::Managedkafka::V1::ManagedKafka::CreateTopicRequest'->new($_) };

declare 'RepeatedCreateTopicRequest',
    as ArrayRef[CreateTopicRequest()];

coerce 'RepeatedCreateTopicRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Managedkafka::V1::ManagedKafka::CreateTopicRequest'->new($_) } @$_ ] };

declare 'MapStringCreateTopicRequest',
    as HashRef[CreateTopicRequest()];

declare 'UpdateTopicRequest',
    as InstanceOf['Google::Cloud::Managedkafka::V1::ManagedKafka::UpdateTopicRequest'];

coerce 'UpdateTopicRequest',
    from HashRef, via { 'Google::Cloud::Managedkafka::V1::ManagedKafka::UpdateTopicRequest'->new($_) };

declare 'RepeatedUpdateTopicRequest',
    as ArrayRef[UpdateTopicRequest()];

coerce 'RepeatedUpdateTopicRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Managedkafka::V1::ManagedKafka::UpdateTopicRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateTopicRequest',
    as HashRef[UpdateTopicRequest()];

declare 'DeleteTopicRequest',
    as InstanceOf['Google::Cloud::Managedkafka::V1::ManagedKafka::DeleteTopicRequest'];

coerce 'DeleteTopicRequest',
    from HashRef, via { 'Google::Cloud::Managedkafka::V1::ManagedKafka::DeleteTopicRequest'->new($_) };

declare 'RepeatedDeleteTopicRequest',
    as ArrayRef[DeleteTopicRequest()];

coerce 'RepeatedDeleteTopicRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Managedkafka::V1::ManagedKafka::DeleteTopicRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteTopicRequest',
    as HashRef[DeleteTopicRequest()];

declare 'ListConsumerGroupsRequest',
    as InstanceOf['Google::Cloud::Managedkafka::V1::ManagedKafka::ListConsumerGroupsRequest'];

coerce 'ListConsumerGroupsRequest',
    from HashRef, via { 'Google::Cloud::Managedkafka::V1::ManagedKafka::ListConsumerGroupsRequest'->new($_) };

declare 'RepeatedListConsumerGroupsRequest',
    as ArrayRef[ListConsumerGroupsRequest()];

coerce 'RepeatedListConsumerGroupsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Managedkafka::V1::ManagedKafka::ListConsumerGroupsRequest'->new($_) } @$_ ] };

declare 'MapStringListConsumerGroupsRequest',
    as HashRef[ListConsumerGroupsRequest()];

declare 'ListConsumerGroupsResponse',
    as InstanceOf['Google::Cloud::Managedkafka::V1::ManagedKafka::ListConsumerGroupsResponse'];

coerce 'ListConsumerGroupsResponse',
    from HashRef, via { 'Google::Cloud::Managedkafka::V1::ManagedKafka::ListConsumerGroupsResponse'->new($_) };

declare 'RepeatedListConsumerGroupsResponse',
    as ArrayRef[ListConsumerGroupsResponse()];

coerce 'RepeatedListConsumerGroupsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Managedkafka::V1::ManagedKafka::ListConsumerGroupsResponse'->new($_) } @$_ ] };

declare 'MapStringListConsumerGroupsResponse',
    as HashRef[ListConsumerGroupsResponse()];

declare 'GetConsumerGroupRequest',
    as InstanceOf['Google::Cloud::Managedkafka::V1::ManagedKafka::GetConsumerGroupRequest'];

coerce 'GetConsumerGroupRequest',
    from HashRef, via { 'Google::Cloud::Managedkafka::V1::ManagedKafka::GetConsumerGroupRequest'->new($_) };

declare 'RepeatedGetConsumerGroupRequest',
    as ArrayRef[GetConsumerGroupRequest()];

coerce 'RepeatedGetConsumerGroupRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Managedkafka::V1::ManagedKafka::GetConsumerGroupRequest'->new($_) } @$_ ] };

declare 'MapStringGetConsumerGroupRequest',
    as HashRef[GetConsumerGroupRequest()];

declare 'UpdateConsumerGroupRequest',
    as InstanceOf['Google::Cloud::Managedkafka::V1::ManagedKafka::UpdateConsumerGroupRequest'];

coerce 'UpdateConsumerGroupRequest',
    from HashRef, via { 'Google::Cloud::Managedkafka::V1::ManagedKafka::UpdateConsumerGroupRequest'->new($_) };

declare 'RepeatedUpdateConsumerGroupRequest',
    as ArrayRef[UpdateConsumerGroupRequest()];

coerce 'RepeatedUpdateConsumerGroupRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Managedkafka::V1::ManagedKafka::UpdateConsumerGroupRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateConsumerGroupRequest',
    as HashRef[UpdateConsumerGroupRequest()];

declare 'DeleteConsumerGroupRequest',
    as InstanceOf['Google::Cloud::Managedkafka::V1::ManagedKafka::DeleteConsumerGroupRequest'];

coerce 'DeleteConsumerGroupRequest',
    from HashRef, via { 'Google::Cloud::Managedkafka::V1::ManagedKafka::DeleteConsumerGroupRequest'->new($_) };

declare 'RepeatedDeleteConsumerGroupRequest',
    as ArrayRef[DeleteConsumerGroupRequest()];

coerce 'RepeatedDeleteConsumerGroupRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Managedkafka::V1::ManagedKafka::DeleteConsumerGroupRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteConsumerGroupRequest',
    as HashRef[DeleteConsumerGroupRequest()];

declare 'ListAclsRequest',
    as InstanceOf['Google::Cloud::Managedkafka::V1::ManagedKafka::ListAclsRequest'];

coerce 'ListAclsRequest',
    from HashRef, via { 'Google::Cloud::Managedkafka::V1::ManagedKafka::ListAclsRequest'->new($_) };

declare 'RepeatedListAclsRequest',
    as ArrayRef[ListAclsRequest()];

coerce 'RepeatedListAclsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Managedkafka::V1::ManagedKafka::ListAclsRequest'->new($_) } @$_ ] };

declare 'MapStringListAclsRequest',
    as HashRef[ListAclsRequest()];

declare 'ListAclsResponse',
    as InstanceOf['Google::Cloud::Managedkafka::V1::ManagedKafka::ListAclsResponse'];

coerce 'ListAclsResponse',
    from HashRef, via { 'Google::Cloud::Managedkafka::V1::ManagedKafka::ListAclsResponse'->new($_) };

declare 'RepeatedListAclsResponse',
    as ArrayRef[ListAclsResponse()];

coerce 'RepeatedListAclsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Managedkafka::V1::ManagedKafka::ListAclsResponse'->new($_) } @$_ ] };

declare 'MapStringListAclsResponse',
    as HashRef[ListAclsResponse()];

declare 'GetAclRequest',
    as InstanceOf['Google::Cloud::Managedkafka::V1::ManagedKafka::GetAclRequest'];

coerce 'GetAclRequest',
    from HashRef, via { 'Google::Cloud::Managedkafka::V1::ManagedKafka::GetAclRequest'->new($_) };

declare 'RepeatedGetAclRequest',
    as ArrayRef[GetAclRequest()];

coerce 'RepeatedGetAclRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Managedkafka::V1::ManagedKafka::GetAclRequest'->new($_) } @$_ ] };

declare 'MapStringGetAclRequest',
    as HashRef[GetAclRequest()];

declare 'CreateAclRequest',
    as InstanceOf['Google::Cloud::Managedkafka::V1::ManagedKafka::CreateAclRequest'];

coerce 'CreateAclRequest',
    from HashRef, via { 'Google::Cloud::Managedkafka::V1::ManagedKafka::CreateAclRequest'->new($_) };

declare 'RepeatedCreateAclRequest',
    as ArrayRef[CreateAclRequest()];

coerce 'RepeatedCreateAclRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Managedkafka::V1::ManagedKafka::CreateAclRequest'->new($_) } @$_ ] };

declare 'MapStringCreateAclRequest',
    as HashRef[CreateAclRequest()];

declare 'UpdateAclRequest',
    as InstanceOf['Google::Cloud::Managedkafka::V1::ManagedKafka::UpdateAclRequest'];

coerce 'UpdateAclRequest',
    from HashRef, via { 'Google::Cloud::Managedkafka::V1::ManagedKafka::UpdateAclRequest'->new($_) };

declare 'RepeatedUpdateAclRequest',
    as ArrayRef[UpdateAclRequest()];

coerce 'RepeatedUpdateAclRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Managedkafka::V1::ManagedKafka::UpdateAclRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateAclRequest',
    as HashRef[UpdateAclRequest()];

declare 'DeleteAclRequest',
    as InstanceOf['Google::Cloud::Managedkafka::V1::ManagedKafka::DeleteAclRequest'];

coerce 'DeleteAclRequest',
    from HashRef, via { 'Google::Cloud::Managedkafka::V1::ManagedKafka::DeleteAclRequest'->new($_) };

declare 'RepeatedDeleteAclRequest',
    as ArrayRef[DeleteAclRequest()];

coerce 'RepeatedDeleteAclRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Managedkafka::V1::ManagedKafka::DeleteAclRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteAclRequest',
    as HashRef[DeleteAclRequest()];

declare 'AddAclEntryRequest',
    as InstanceOf['Google::Cloud::Managedkafka::V1::ManagedKafka::AddAclEntryRequest'];

coerce 'AddAclEntryRequest',
    from HashRef, via { 'Google::Cloud::Managedkafka::V1::ManagedKafka::AddAclEntryRequest'->new($_) };

declare 'RepeatedAddAclEntryRequest',
    as ArrayRef[AddAclEntryRequest()];

coerce 'RepeatedAddAclEntryRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Managedkafka::V1::ManagedKafka::AddAclEntryRequest'->new($_) } @$_ ] };

declare 'MapStringAddAclEntryRequest',
    as HashRef[AddAclEntryRequest()];

declare 'AddAclEntryResponse',
    as InstanceOf['Google::Cloud::Managedkafka::V1::ManagedKafka::AddAclEntryResponse'];

coerce 'AddAclEntryResponse',
    from HashRef, via { 'Google::Cloud::Managedkafka::V1::ManagedKafka::AddAclEntryResponse'->new($_) };

declare 'RepeatedAddAclEntryResponse',
    as ArrayRef[AddAclEntryResponse()];

coerce 'RepeatedAddAclEntryResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Managedkafka::V1::ManagedKafka::AddAclEntryResponse'->new($_) } @$_ ] };

declare 'MapStringAddAclEntryResponse',
    as HashRef[AddAclEntryResponse()];

declare 'RemoveAclEntryRequest',
    as InstanceOf['Google::Cloud::Managedkafka::V1::ManagedKafka::RemoveAclEntryRequest'];

coerce 'RemoveAclEntryRequest',
    from HashRef, via { 'Google::Cloud::Managedkafka::V1::ManagedKafka::RemoveAclEntryRequest'->new($_) };

declare 'RepeatedRemoveAclEntryRequest',
    as ArrayRef[RemoveAclEntryRequest()];

coerce 'RepeatedRemoveAclEntryRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Managedkafka::V1::ManagedKafka::RemoveAclEntryRequest'->new($_) } @$_ ] };

declare 'MapStringRemoveAclEntryRequest',
    as HashRef[RemoveAclEntryRequest()];

declare 'RemoveAclEntryResponse',
    as InstanceOf['Google::Cloud::Managedkafka::V1::ManagedKafka::RemoveAclEntryResponse'];

coerce 'RemoveAclEntryResponse',
    from HashRef, via { 'Google::Cloud::Managedkafka::V1::ManagedKafka::RemoveAclEntryResponse'->new($_) };

declare 'RepeatedRemoveAclEntryResponse',
    as ArrayRef[RemoveAclEntryResponse()];

coerce 'RepeatedRemoveAclEntryResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Managedkafka::V1::ManagedKafka::RemoveAclEntryResponse'->new($_) } @$_ ] };

declare 'MapStringRemoveAclEntryResponse',
    as HashRef[RemoveAclEntryResponse()];

1;

__END__

=head1 NAME

Google::Cloud::Managedkafka::V1::ManagedKafka::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
