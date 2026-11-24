package Google::Cloud::Saasplatform::Saasservicemgmt::V1::RolloutsService::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'ListRolloutsRequest',
    as InstanceOf['Google::Cloud::Saasplatform::Saasservicemgmt::V1::RolloutsService::ListRolloutsRequest'];

coerce 'ListRolloutsRequest',
    from HashRef, via { 'Google::Cloud::Saasplatform::Saasservicemgmt::V1::RolloutsService::ListRolloutsRequest'->new($_) };

declare 'RepeatedListRolloutsRequest',
    as ArrayRef[ListRolloutsRequest()];

coerce 'RepeatedListRolloutsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Saasplatform::Saasservicemgmt::V1::RolloutsService::ListRolloutsRequest'->new($_) } @$_ ] };

declare 'MapStringListRolloutsRequest',
    as HashRef[ListRolloutsRequest()];

declare 'ListRolloutsResponse',
    as InstanceOf['Google::Cloud::Saasplatform::Saasservicemgmt::V1::RolloutsService::ListRolloutsResponse'];

coerce 'ListRolloutsResponse',
    from HashRef, via { 'Google::Cloud::Saasplatform::Saasservicemgmt::V1::RolloutsService::ListRolloutsResponse'->new($_) };

declare 'RepeatedListRolloutsResponse',
    as ArrayRef[ListRolloutsResponse()];

coerce 'RepeatedListRolloutsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Saasplatform::Saasservicemgmt::V1::RolloutsService::ListRolloutsResponse'->new($_) } @$_ ] };

declare 'MapStringListRolloutsResponse',
    as HashRef[ListRolloutsResponse()];

declare 'GetRolloutRequest',
    as InstanceOf['Google::Cloud::Saasplatform::Saasservicemgmt::V1::RolloutsService::GetRolloutRequest'];

coerce 'GetRolloutRequest',
    from HashRef, via { 'Google::Cloud::Saasplatform::Saasservicemgmt::V1::RolloutsService::GetRolloutRequest'->new($_) };

declare 'RepeatedGetRolloutRequest',
    as ArrayRef[GetRolloutRequest()];

coerce 'RepeatedGetRolloutRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Saasplatform::Saasservicemgmt::V1::RolloutsService::GetRolloutRequest'->new($_) } @$_ ] };

declare 'MapStringGetRolloutRequest',
    as HashRef[GetRolloutRequest()];

declare 'CreateRolloutRequest',
    as InstanceOf['Google::Cloud::Saasplatform::Saasservicemgmt::V1::RolloutsService::CreateRolloutRequest'];

coerce 'CreateRolloutRequest',
    from HashRef, via { 'Google::Cloud::Saasplatform::Saasservicemgmt::V1::RolloutsService::CreateRolloutRequest'->new($_) };

declare 'RepeatedCreateRolloutRequest',
    as ArrayRef[CreateRolloutRequest()];

coerce 'RepeatedCreateRolloutRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Saasplatform::Saasservicemgmt::V1::RolloutsService::CreateRolloutRequest'->new($_) } @$_ ] };

declare 'MapStringCreateRolloutRequest',
    as HashRef[CreateRolloutRequest()];

declare 'UpdateRolloutRequest',
    as InstanceOf['Google::Cloud::Saasplatform::Saasservicemgmt::V1::RolloutsService::UpdateRolloutRequest'];

coerce 'UpdateRolloutRequest',
    from HashRef, via { 'Google::Cloud::Saasplatform::Saasservicemgmt::V1::RolloutsService::UpdateRolloutRequest'->new($_) };

declare 'RepeatedUpdateRolloutRequest',
    as ArrayRef[UpdateRolloutRequest()];

coerce 'RepeatedUpdateRolloutRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Saasplatform::Saasservicemgmt::V1::RolloutsService::UpdateRolloutRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateRolloutRequest',
    as HashRef[UpdateRolloutRequest()];

declare 'DeleteRolloutRequest',
    as InstanceOf['Google::Cloud::Saasplatform::Saasservicemgmt::V1::RolloutsService::DeleteRolloutRequest'];

coerce 'DeleteRolloutRequest',
    from HashRef, via { 'Google::Cloud::Saasplatform::Saasservicemgmt::V1::RolloutsService::DeleteRolloutRequest'->new($_) };

declare 'RepeatedDeleteRolloutRequest',
    as ArrayRef[DeleteRolloutRequest()];

coerce 'RepeatedDeleteRolloutRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Saasplatform::Saasservicemgmt::V1::RolloutsService::DeleteRolloutRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteRolloutRequest',
    as HashRef[DeleteRolloutRequest()];

declare 'ListRolloutKindsRequest',
    as InstanceOf['Google::Cloud::Saasplatform::Saasservicemgmt::V1::RolloutsService::ListRolloutKindsRequest'];

coerce 'ListRolloutKindsRequest',
    from HashRef, via { 'Google::Cloud::Saasplatform::Saasservicemgmt::V1::RolloutsService::ListRolloutKindsRequest'->new($_) };

declare 'RepeatedListRolloutKindsRequest',
    as ArrayRef[ListRolloutKindsRequest()];

coerce 'RepeatedListRolloutKindsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Saasplatform::Saasservicemgmt::V1::RolloutsService::ListRolloutKindsRequest'->new($_) } @$_ ] };

declare 'MapStringListRolloutKindsRequest',
    as HashRef[ListRolloutKindsRequest()];

declare 'ListRolloutKindsResponse',
    as InstanceOf['Google::Cloud::Saasplatform::Saasservicemgmt::V1::RolloutsService::ListRolloutKindsResponse'];

coerce 'ListRolloutKindsResponse',
    from HashRef, via { 'Google::Cloud::Saasplatform::Saasservicemgmt::V1::RolloutsService::ListRolloutKindsResponse'->new($_) };

declare 'RepeatedListRolloutKindsResponse',
    as ArrayRef[ListRolloutKindsResponse()];

coerce 'RepeatedListRolloutKindsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Saasplatform::Saasservicemgmt::V1::RolloutsService::ListRolloutKindsResponse'->new($_) } @$_ ] };

declare 'MapStringListRolloutKindsResponse',
    as HashRef[ListRolloutKindsResponse()];

declare 'GetRolloutKindRequest',
    as InstanceOf['Google::Cloud::Saasplatform::Saasservicemgmt::V1::RolloutsService::GetRolloutKindRequest'];

coerce 'GetRolloutKindRequest',
    from HashRef, via { 'Google::Cloud::Saasplatform::Saasservicemgmt::V1::RolloutsService::GetRolloutKindRequest'->new($_) };

declare 'RepeatedGetRolloutKindRequest',
    as ArrayRef[GetRolloutKindRequest()];

coerce 'RepeatedGetRolloutKindRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Saasplatform::Saasservicemgmt::V1::RolloutsService::GetRolloutKindRequest'->new($_) } @$_ ] };

declare 'MapStringGetRolloutKindRequest',
    as HashRef[GetRolloutKindRequest()];

declare 'CreateRolloutKindRequest',
    as InstanceOf['Google::Cloud::Saasplatform::Saasservicemgmt::V1::RolloutsService::CreateRolloutKindRequest'];

coerce 'CreateRolloutKindRequest',
    from HashRef, via { 'Google::Cloud::Saasplatform::Saasservicemgmt::V1::RolloutsService::CreateRolloutKindRequest'->new($_) };

declare 'RepeatedCreateRolloutKindRequest',
    as ArrayRef[CreateRolloutKindRequest()];

coerce 'RepeatedCreateRolloutKindRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Saasplatform::Saasservicemgmt::V1::RolloutsService::CreateRolloutKindRequest'->new($_) } @$_ ] };

declare 'MapStringCreateRolloutKindRequest',
    as HashRef[CreateRolloutKindRequest()];

declare 'UpdateRolloutKindRequest',
    as InstanceOf['Google::Cloud::Saasplatform::Saasservicemgmt::V1::RolloutsService::UpdateRolloutKindRequest'];

coerce 'UpdateRolloutKindRequest',
    from HashRef, via { 'Google::Cloud::Saasplatform::Saasservicemgmt::V1::RolloutsService::UpdateRolloutKindRequest'->new($_) };

declare 'RepeatedUpdateRolloutKindRequest',
    as ArrayRef[UpdateRolloutKindRequest()];

coerce 'RepeatedUpdateRolloutKindRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Saasplatform::Saasservicemgmt::V1::RolloutsService::UpdateRolloutKindRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateRolloutKindRequest',
    as HashRef[UpdateRolloutKindRequest()];

declare 'DeleteRolloutKindRequest',
    as InstanceOf['Google::Cloud::Saasplatform::Saasservicemgmt::V1::RolloutsService::DeleteRolloutKindRequest'];

coerce 'DeleteRolloutKindRequest',
    from HashRef, via { 'Google::Cloud::Saasplatform::Saasservicemgmt::V1::RolloutsService::DeleteRolloutKindRequest'->new($_) };

declare 'RepeatedDeleteRolloutKindRequest',
    as ArrayRef[DeleteRolloutKindRequest()];

coerce 'RepeatedDeleteRolloutKindRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Saasplatform::Saasservicemgmt::V1::RolloutsService::DeleteRolloutKindRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteRolloutKindRequest',
    as HashRef[DeleteRolloutKindRequest()];

1;

__END__

=head1 NAME

Google::Cloud::Saasplatform::Saasservicemgmt::V1::RolloutsService::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
