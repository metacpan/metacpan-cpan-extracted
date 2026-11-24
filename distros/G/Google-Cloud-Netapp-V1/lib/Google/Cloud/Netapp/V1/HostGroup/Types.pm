package Google::Cloud::Netapp::V1::HostGroup::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'ListHostGroupsRequest',
    as InstanceOf['Google::Cloud::Netapp::V1::HostGroup::ListHostGroupsRequest'];

coerce 'ListHostGroupsRequest',
    from HashRef, via { 'Google::Cloud::Netapp::V1::HostGroup::ListHostGroupsRequest'->new($_) };

declare 'RepeatedListHostGroupsRequest',
    as ArrayRef[ListHostGroupsRequest()];

coerce 'RepeatedListHostGroupsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Netapp::V1::HostGroup::ListHostGroupsRequest'->new($_) } @$_ ] };

declare 'MapStringListHostGroupsRequest',
    as HashRef[ListHostGroupsRequest()];

declare 'ListHostGroupsResponse',
    as InstanceOf['Google::Cloud::Netapp::V1::HostGroup::ListHostGroupsResponse'];

coerce 'ListHostGroupsResponse',
    from HashRef, via { 'Google::Cloud::Netapp::V1::HostGroup::ListHostGroupsResponse'->new($_) };

declare 'RepeatedListHostGroupsResponse',
    as ArrayRef[ListHostGroupsResponse()];

coerce 'RepeatedListHostGroupsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Netapp::V1::HostGroup::ListHostGroupsResponse'->new($_) } @$_ ] };

declare 'MapStringListHostGroupsResponse',
    as HashRef[ListHostGroupsResponse()];

declare 'GetHostGroupRequest',
    as InstanceOf['Google::Cloud::Netapp::V1::HostGroup::GetHostGroupRequest'];

coerce 'GetHostGroupRequest',
    from HashRef, via { 'Google::Cloud::Netapp::V1::HostGroup::GetHostGroupRequest'->new($_) };

declare 'RepeatedGetHostGroupRequest',
    as ArrayRef[GetHostGroupRequest()];

coerce 'RepeatedGetHostGroupRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Netapp::V1::HostGroup::GetHostGroupRequest'->new($_) } @$_ ] };

declare 'MapStringGetHostGroupRequest',
    as HashRef[GetHostGroupRequest()];

declare 'CreateHostGroupRequest',
    as InstanceOf['Google::Cloud::Netapp::V1::HostGroup::CreateHostGroupRequest'];

coerce 'CreateHostGroupRequest',
    from HashRef, via { 'Google::Cloud::Netapp::V1::HostGroup::CreateHostGroupRequest'->new($_) };

declare 'RepeatedCreateHostGroupRequest',
    as ArrayRef[CreateHostGroupRequest()];

coerce 'RepeatedCreateHostGroupRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Netapp::V1::HostGroup::CreateHostGroupRequest'->new($_) } @$_ ] };

declare 'MapStringCreateHostGroupRequest',
    as HashRef[CreateHostGroupRequest()];

declare 'UpdateHostGroupRequest',
    as InstanceOf['Google::Cloud::Netapp::V1::HostGroup::UpdateHostGroupRequest'];

coerce 'UpdateHostGroupRequest',
    from HashRef, via { 'Google::Cloud::Netapp::V1::HostGroup::UpdateHostGroupRequest'->new($_) };

declare 'RepeatedUpdateHostGroupRequest',
    as ArrayRef[UpdateHostGroupRequest()];

coerce 'RepeatedUpdateHostGroupRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Netapp::V1::HostGroup::UpdateHostGroupRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateHostGroupRequest',
    as HashRef[UpdateHostGroupRequest()];

declare 'DeleteHostGroupRequest',
    as InstanceOf['Google::Cloud::Netapp::V1::HostGroup::DeleteHostGroupRequest'];

coerce 'DeleteHostGroupRequest',
    from HashRef, via { 'Google::Cloud::Netapp::V1::HostGroup::DeleteHostGroupRequest'->new($_) };

declare 'RepeatedDeleteHostGroupRequest',
    as ArrayRef[DeleteHostGroupRequest()];

coerce 'RepeatedDeleteHostGroupRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Netapp::V1::HostGroup::DeleteHostGroupRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteHostGroupRequest',
    as HashRef[DeleteHostGroupRequest()];

declare 'HostGroup',
    as InstanceOf['Google::Cloud::Netapp::V1::HostGroup::HostGroup'];

coerce 'HostGroup',
    from HashRef, via { 'Google::Cloud::Netapp::V1::HostGroup::HostGroup'->new($_) };

declare 'RepeatedHostGroup',
    as ArrayRef[HostGroup()];

coerce 'RepeatedHostGroup',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Netapp::V1::HostGroup::HostGroup'->new($_) } @$_ ] };

declare 'MapStringHostGroup',
    as HashRef[HostGroup()];

declare 'Type',
    as (Int | Str);

declare 'State',
    as (Int | Str);

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Netapp::V1::HostGroup::HostGroup::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Netapp::V1::HostGroup::HostGroup::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Netapp::V1::HostGroup::HostGroup::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

1;

__END__

=head1 NAME

Google::Cloud::Netapp::V1::HostGroup::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
