package Google::Cloud::Dataproc::V1::NodeGroups::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'CreateNodeGroupRequest',
    as InstanceOf['Google::Cloud::Dataproc::V1::NodeGroups::CreateNodeGroupRequest'];

coerce 'CreateNodeGroupRequest',
    from HashRef, via { 'Google::Cloud::Dataproc::V1::NodeGroups::CreateNodeGroupRequest'->new($_) };

declare 'RepeatedCreateNodeGroupRequest',
    as ArrayRef[CreateNodeGroupRequest()];

coerce 'RepeatedCreateNodeGroupRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataproc::V1::NodeGroups::CreateNodeGroupRequest'->new($_) } @$_ ] };

declare 'MapStringCreateNodeGroupRequest',
    as HashRef[CreateNodeGroupRequest()];

declare 'ResizeNodeGroupRequest',
    as InstanceOf['Google::Cloud::Dataproc::V1::NodeGroups::ResizeNodeGroupRequest'];

coerce 'ResizeNodeGroupRequest',
    from HashRef, via { 'Google::Cloud::Dataproc::V1::NodeGroups::ResizeNodeGroupRequest'->new($_) };

declare 'RepeatedResizeNodeGroupRequest',
    as ArrayRef[ResizeNodeGroupRequest()];

coerce 'RepeatedResizeNodeGroupRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataproc::V1::NodeGroups::ResizeNodeGroupRequest'->new($_) } @$_ ] };

declare 'MapStringResizeNodeGroupRequest',
    as HashRef[ResizeNodeGroupRequest()];

declare 'GetNodeGroupRequest',
    as InstanceOf['Google::Cloud::Dataproc::V1::NodeGroups::GetNodeGroupRequest'];

coerce 'GetNodeGroupRequest',
    from HashRef, via { 'Google::Cloud::Dataproc::V1::NodeGroups::GetNodeGroupRequest'->new($_) };

declare 'RepeatedGetNodeGroupRequest',
    as ArrayRef[GetNodeGroupRequest()];

coerce 'RepeatedGetNodeGroupRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataproc::V1::NodeGroups::GetNodeGroupRequest'->new($_) } @$_ ] };

declare 'MapStringGetNodeGroupRequest',
    as HashRef[GetNodeGroupRequest()];

1;

__END__

=head1 NAME

Google::Cloud::Dataproc::V1::NodeGroups::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
