package Google::Cloud::Dialogflow::Cx::V3beta1::TransitionRouteGroup::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'TransitionRouteGroup',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3beta1::TransitionRouteGroup::TransitionRouteGroup'];

coerce 'TransitionRouteGroup',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3beta1::TransitionRouteGroup::TransitionRouteGroup'->new($_) };

declare 'RepeatedTransitionRouteGroup',
    as ArrayRef[TransitionRouteGroup()];

coerce 'RepeatedTransitionRouteGroup',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3beta1::TransitionRouteGroup::TransitionRouteGroup'->new($_) } @$_ ] };

declare 'MapStringTransitionRouteGroup',
    as HashRef[TransitionRouteGroup()];

declare 'ListTransitionRouteGroupsRequest',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3beta1::TransitionRouteGroup::ListTransitionRouteGroupsRequest'];

coerce 'ListTransitionRouteGroupsRequest',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3beta1::TransitionRouteGroup::ListTransitionRouteGroupsRequest'->new($_) };

declare 'RepeatedListTransitionRouteGroupsRequest',
    as ArrayRef[ListTransitionRouteGroupsRequest()];

coerce 'RepeatedListTransitionRouteGroupsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3beta1::TransitionRouteGroup::ListTransitionRouteGroupsRequest'->new($_) } @$_ ] };

declare 'MapStringListTransitionRouteGroupsRequest',
    as HashRef[ListTransitionRouteGroupsRequest()];

declare 'ListTransitionRouteGroupsResponse',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3beta1::TransitionRouteGroup::ListTransitionRouteGroupsResponse'];

coerce 'ListTransitionRouteGroupsResponse',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3beta1::TransitionRouteGroup::ListTransitionRouteGroupsResponse'->new($_) };

declare 'RepeatedListTransitionRouteGroupsResponse',
    as ArrayRef[ListTransitionRouteGroupsResponse()];

coerce 'RepeatedListTransitionRouteGroupsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3beta1::TransitionRouteGroup::ListTransitionRouteGroupsResponse'->new($_) } @$_ ] };

declare 'MapStringListTransitionRouteGroupsResponse',
    as HashRef[ListTransitionRouteGroupsResponse()];

declare 'GetTransitionRouteGroupRequest',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3beta1::TransitionRouteGroup::GetTransitionRouteGroupRequest'];

coerce 'GetTransitionRouteGroupRequest',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3beta1::TransitionRouteGroup::GetTransitionRouteGroupRequest'->new($_) };

declare 'RepeatedGetTransitionRouteGroupRequest',
    as ArrayRef[GetTransitionRouteGroupRequest()];

coerce 'RepeatedGetTransitionRouteGroupRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3beta1::TransitionRouteGroup::GetTransitionRouteGroupRequest'->new($_) } @$_ ] };

declare 'MapStringGetTransitionRouteGroupRequest',
    as HashRef[GetTransitionRouteGroupRequest()];

declare 'CreateTransitionRouteGroupRequest',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3beta1::TransitionRouteGroup::CreateTransitionRouteGroupRequest'];

coerce 'CreateTransitionRouteGroupRequest',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3beta1::TransitionRouteGroup::CreateTransitionRouteGroupRequest'->new($_) };

declare 'RepeatedCreateTransitionRouteGroupRequest',
    as ArrayRef[CreateTransitionRouteGroupRequest()];

coerce 'RepeatedCreateTransitionRouteGroupRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3beta1::TransitionRouteGroup::CreateTransitionRouteGroupRequest'->new($_) } @$_ ] };

declare 'MapStringCreateTransitionRouteGroupRequest',
    as HashRef[CreateTransitionRouteGroupRequest()];

declare 'UpdateTransitionRouteGroupRequest',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3beta1::TransitionRouteGroup::UpdateTransitionRouteGroupRequest'];

coerce 'UpdateTransitionRouteGroupRequest',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3beta1::TransitionRouteGroup::UpdateTransitionRouteGroupRequest'->new($_) };

declare 'RepeatedUpdateTransitionRouteGroupRequest',
    as ArrayRef[UpdateTransitionRouteGroupRequest()];

coerce 'RepeatedUpdateTransitionRouteGroupRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3beta1::TransitionRouteGroup::UpdateTransitionRouteGroupRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateTransitionRouteGroupRequest',
    as HashRef[UpdateTransitionRouteGroupRequest()];

declare 'DeleteTransitionRouteGroupRequest',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3beta1::TransitionRouteGroup::DeleteTransitionRouteGroupRequest'];

coerce 'DeleteTransitionRouteGroupRequest',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3beta1::TransitionRouteGroup::DeleteTransitionRouteGroupRequest'->new($_) };

declare 'RepeatedDeleteTransitionRouteGroupRequest',
    as ArrayRef[DeleteTransitionRouteGroupRequest()];

coerce 'RepeatedDeleteTransitionRouteGroupRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3beta1::TransitionRouteGroup::DeleteTransitionRouteGroupRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteTransitionRouteGroupRequest',
    as HashRef[DeleteTransitionRouteGroupRequest()];

1;

__END__

=head1 NAME

Google::Cloud::Dialogflow::Cx::V3beta1::TransitionRouteGroup::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
