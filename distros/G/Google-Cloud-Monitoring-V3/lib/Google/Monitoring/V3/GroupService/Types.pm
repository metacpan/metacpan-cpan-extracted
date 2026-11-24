package Google::Monitoring::V3::GroupService::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'ListGroupsRequest',
    as InstanceOf['Google::Monitoring::V3::GroupService::ListGroupsRequest'];

coerce 'ListGroupsRequest',
    from HashRef, via { 'Google::Monitoring::V3::GroupService::ListGroupsRequest'->new($_) };

declare 'RepeatedListGroupsRequest',
    as ArrayRef[ListGroupsRequest()];

coerce 'RepeatedListGroupsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Monitoring::V3::GroupService::ListGroupsRequest'->new($_) } @$_ ] };

declare 'MapStringListGroupsRequest',
    as HashRef[ListGroupsRequest()];

declare 'ListGroupsResponse',
    as InstanceOf['Google::Monitoring::V3::GroupService::ListGroupsResponse'];

coerce 'ListGroupsResponse',
    from HashRef, via { 'Google::Monitoring::V3::GroupService::ListGroupsResponse'->new($_) };

declare 'RepeatedListGroupsResponse',
    as ArrayRef[ListGroupsResponse()];

coerce 'RepeatedListGroupsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Monitoring::V3::GroupService::ListGroupsResponse'->new($_) } @$_ ] };

declare 'MapStringListGroupsResponse',
    as HashRef[ListGroupsResponse()];

declare 'GetGroupRequest',
    as InstanceOf['Google::Monitoring::V3::GroupService::GetGroupRequest'];

coerce 'GetGroupRequest',
    from HashRef, via { 'Google::Monitoring::V3::GroupService::GetGroupRequest'->new($_) };

declare 'RepeatedGetGroupRequest',
    as ArrayRef[GetGroupRequest()];

coerce 'RepeatedGetGroupRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Monitoring::V3::GroupService::GetGroupRequest'->new($_) } @$_ ] };

declare 'MapStringGetGroupRequest',
    as HashRef[GetGroupRequest()];

declare 'CreateGroupRequest',
    as InstanceOf['Google::Monitoring::V3::GroupService::CreateGroupRequest'];

coerce 'CreateGroupRequest',
    from HashRef, via { 'Google::Monitoring::V3::GroupService::CreateGroupRequest'->new($_) };

declare 'RepeatedCreateGroupRequest',
    as ArrayRef[CreateGroupRequest()];

coerce 'RepeatedCreateGroupRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Monitoring::V3::GroupService::CreateGroupRequest'->new($_) } @$_ ] };

declare 'MapStringCreateGroupRequest',
    as HashRef[CreateGroupRequest()];

declare 'UpdateGroupRequest',
    as InstanceOf['Google::Monitoring::V3::GroupService::UpdateGroupRequest'];

coerce 'UpdateGroupRequest',
    from HashRef, via { 'Google::Monitoring::V3::GroupService::UpdateGroupRequest'->new($_) };

declare 'RepeatedUpdateGroupRequest',
    as ArrayRef[UpdateGroupRequest()];

coerce 'RepeatedUpdateGroupRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Monitoring::V3::GroupService::UpdateGroupRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateGroupRequest',
    as HashRef[UpdateGroupRequest()];

declare 'DeleteGroupRequest',
    as InstanceOf['Google::Monitoring::V3::GroupService::DeleteGroupRequest'];

coerce 'DeleteGroupRequest',
    from HashRef, via { 'Google::Monitoring::V3::GroupService::DeleteGroupRequest'->new($_) };

declare 'RepeatedDeleteGroupRequest',
    as ArrayRef[DeleteGroupRequest()];

coerce 'RepeatedDeleteGroupRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Monitoring::V3::GroupService::DeleteGroupRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteGroupRequest',
    as HashRef[DeleteGroupRequest()];

declare 'ListGroupMembersRequest',
    as InstanceOf['Google::Monitoring::V3::GroupService::ListGroupMembersRequest'];

coerce 'ListGroupMembersRequest',
    from HashRef, via { 'Google::Monitoring::V3::GroupService::ListGroupMembersRequest'->new($_) };

declare 'RepeatedListGroupMembersRequest',
    as ArrayRef[ListGroupMembersRequest()];

coerce 'RepeatedListGroupMembersRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Monitoring::V3::GroupService::ListGroupMembersRequest'->new($_) } @$_ ] };

declare 'MapStringListGroupMembersRequest',
    as HashRef[ListGroupMembersRequest()];

declare 'ListGroupMembersResponse',
    as InstanceOf['Google::Monitoring::V3::GroupService::ListGroupMembersResponse'];

coerce 'ListGroupMembersResponse',
    from HashRef, via { 'Google::Monitoring::V3::GroupService::ListGroupMembersResponse'->new($_) };

declare 'RepeatedListGroupMembersResponse',
    as ArrayRef[ListGroupMembersResponse()];

coerce 'RepeatedListGroupMembersResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Monitoring::V3::GroupService::ListGroupMembersResponse'->new($_) } @$_ ] };

declare 'MapStringListGroupMembersResponse',
    as HashRef[ListGroupMembersResponse()];

1;

__END__

=head1 NAME

Google::Monitoring::V3::GroupService::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
