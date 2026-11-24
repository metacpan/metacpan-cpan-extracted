package Google::Cloud::Datastream::V1::Datastream::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'DiscoverConnectionProfileRequest',
    as InstanceOf['Google::Cloud::Datastream::V1::Datastream::DiscoverConnectionProfileRequest'];

coerce 'DiscoverConnectionProfileRequest',
    from HashRef, via { 'Google::Cloud::Datastream::V1::Datastream::DiscoverConnectionProfileRequest'->new($_) };

declare 'RepeatedDiscoverConnectionProfileRequest',
    as ArrayRef[DiscoverConnectionProfileRequest()];

coerce 'RepeatedDiscoverConnectionProfileRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datastream::V1::Datastream::DiscoverConnectionProfileRequest'->new($_) } @$_ ] };

declare 'MapStringDiscoverConnectionProfileRequest',
    as HashRef[DiscoverConnectionProfileRequest()];

declare 'DiscoverConnectionProfileResponse',
    as InstanceOf['Google::Cloud::Datastream::V1::Datastream::DiscoverConnectionProfileResponse'];

coerce 'DiscoverConnectionProfileResponse',
    from HashRef, via { 'Google::Cloud::Datastream::V1::Datastream::DiscoverConnectionProfileResponse'->new($_) };

declare 'RepeatedDiscoverConnectionProfileResponse',
    as ArrayRef[DiscoverConnectionProfileResponse()];

coerce 'RepeatedDiscoverConnectionProfileResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datastream::V1::Datastream::DiscoverConnectionProfileResponse'->new($_) } @$_ ] };

declare 'MapStringDiscoverConnectionProfileResponse',
    as HashRef[DiscoverConnectionProfileResponse()];

declare 'FetchStaticIpsRequest',
    as InstanceOf['Google::Cloud::Datastream::V1::Datastream::FetchStaticIpsRequest'];

coerce 'FetchStaticIpsRequest',
    from HashRef, via { 'Google::Cloud::Datastream::V1::Datastream::FetchStaticIpsRequest'->new($_) };

declare 'RepeatedFetchStaticIpsRequest',
    as ArrayRef[FetchStaticIpsRequest()];

coerce 'RepeatedFetchStaticIpsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datastream::V1::Datastream::FetchStaticIpsRequest'->new($_) } @$_ ] };

declare 'MapStringFetchStaticIpsRequest',
    as HashRef[FetchStaticIpsRequest()];

declare 'FetchStaticIpsResponse',
    as InstanceOf['Google::Cloud::Datastream::V1::Datastream::FetchStaticIpsResponse'];

coerce 'FetchStaticIpsResponse',
    from HashRef, via { 'Google::Cloud::Datastream::V1::Datastream::FetchStaticIpsResponse'->new($_) };

declare 'RepeatedFetchStaticIpsResponse',
    as ArrayRef[FetchStaticIpsResponse()];

coerce 'RepeatedFetchStaticIpsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datastream::V1::Datastream::FetchStaticIpsResponse'->new($_) } @$_ ] };

declare 'MapStringFetchStaticIpsResponse',
    as HashRef[FetchStaticIpsResponse()];

declare 'ListConnectionProfilesRequest',
    as InstanceOf['Google::Cloud::Datastream::V1::Datastream::ListConnectionProfilesRequest'];

coerce 'ListConnectionProfilesRequest',
    from HashRef, via { 'Google::Cloud::Datastream::V1::Datastream::ListConnectionProfilesRequest'->new($_) };

declare 'RepeatedListConnectionProfilesRequest',
    as ArrayRef[ListConnectionProfilesRequest()];

coerce 'RepeatedListConnectionProfilesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datastream::V1::Datastream::ListConnectionProfilesRequest'->new($_) } @$_ ] };

declare 'MapStringListConnectionProfilesRequest',
    as HashRef[ListConnectionProfilesRequest()];

declare 'ListConnectionProfilesResponse',
    as InstanceOf['Google::Cloud::Datastream::V1::Datastream::ListConnectionProfilesResponse'];

coerce 'ListConnectionProfilesResponse',
    from HashRef, via { 'Google::Cloud::Datastream::V1::Datastream::ListConnectionProfilesResponse'->new($_) };

declare 'RepeatedListConnectionProfilesResponse',
    as ArrayRef[ListConnectionProfilesResponse()];

coerce 'RepeatedListConnectionProfilesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datastream::V1::Datastream::ListConnectionProfilesResponse'->new($_) } @$_ ] };

declare 'MapStringListConnectionProfilesResponse',
    as HashRef[ListConnectionProfilesResponse()];

declare 'GetConnectionProfileRequest',
    as InstanceOf['Google::Cloud::Datastream::V1::Datastream::GetConnectionProfileRequest'];

coerce 'GetConnectionProfileRequest',
    from HashRef, via { 'Google::Cloud::Datastream::V1::Datastream::GetConnectionProfileRequest'->new($_) };

declare 'RepeatedGetConnectionProfileRequest',
    as ArrayRef[GetConnectionProfileRequest()];

coerce 'RepeatedGetConnectionProfileRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datastream::V1::Datastream::GetConnectionProfileRequest'->new($_) } @$_ ] };

declare 'MapStringGetConnectionProfileRequest',
    as HashRef[GetConnectionProfileRequest()];

declare 'CreateConnectionProfileRequest',
    as InstanceOf['Google::Cloud::Datastream::V1::Datastream::CreateConnectionProfileRequest'];

coerce 'CreateConnectionProfileRequest',
    from HashRef, via { 'Google::Cloud::Datastream::V1::Datastream::CreateConnectionProfileRequest'->new($_) };

declare 'RepeatedCreateConnectionProfileRequest',
    as ArrayRef[CreateConnectionProfileRequest()];

coerce 'RepeatedCreateConnectionProfileRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datastream::V1::Datastream::CreateConnectionProfileRequest'->new($_) } @$_ ] };

declare 'MapStringCreateConnectionProfileRequest',
    as HashRef[CreateConnectionProfileRequest()];

declare 'UpdateConnectionProfileRequest',
    as InstanceOf['Google::Cloud::Datastream::V1::Datastream::UpdateConnectionProfileRequest'];

coerce 'UpdateConnectionProfileRequest',
    from HashRef, via { 'Google::Cloud::Datastream::V1::Datastream::UpdateConnectionProfileRequest'->new($_) };

declare 'RepeatedUpdateConnectionProfileRequest',
    as ArrayRef[UpdateConnectionProfileRequest()];

coerce 'RepeatedUpdateConnectionProfileRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datastream::V1::Datastream::UpdateConnectionProfileRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateConnectionProfileRequest',
    as HashRef[UpdateConnectionProfileRequest()];

declare 'DeleteConnectionProfileRequest',
    as InstanceOf['Google::Cloud::Datastream::V1::Datastream::DeleteConnectionProfileRequest'];

coerce 'DeleteConnectionProfileRequest',
    from HashRef, via { 'Google::Cloud::Datastream::V1::Datastream::DeleteConnectionProfileRequest'->new($_) };

declare 'RepeatedDeleteConnectionProfileRequest',
    as ArrayRef[DeleteConnectionProfileRequest()];

coerce 'RepeatedDeleteConnectionProfileRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datastream::V1::Datastream::DeleteConnectionProfileRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteConnectionProfileRequest',
    as HashRef[DeleteConnectionProfileRequest()];

declare 'ListStreamsRequest',
    as InstanceOf['Google::Cloud::Datastream::V1::Datastream::ListStreamsRequest'];

coerce 'ListStreamsRequest',
    from HashRef, via { 'Google::Cloud::Datastream::V1::Datastream::ListStreamsRequest'->new($_) };

declare 'RepeatedListStreamsRequest',
    as ArrayRef[ListStreamsRequest()];

coerce 'RepeatedListStreamsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datastream::V1::Datastream::ListStreamsRequest'->new($_) } @$_ ] };

declare 'MapStringListStreamsRequest',
    as HashRef[ListStreamsRequest()];

declare 'ListStreamsResponse',
    as InstanceOf['Google::Cloud::Datastream::V1::Datastream::ListStreamsResponse'];

coerce 'ListStreamsResponse',
    from HashRef, via { 'Google::Cloud::Datastream::V1::Datastream::ListStreamsResponse'->new($_) };

declare 'RepeatedListStreamsResponse',
    as ArrayRef[ListStreamsResponse()];

coerce 'RepeatedListStreamsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datastream::V1::Datastream::ListStreamsResponse'->new($_) } @$_ ] };

declare 'MapStringListStreamsResponse',
    as HashRef[ListStreamsResponse()];

declare 'GetStreamRequest',
    as InstanceOf['Google::Cloud::Datastream::V1::Datastream::GetStreamRequest'];

coerce 'GetStreamRequest',
    from HashRef, via { 'Google::Cloud::Datastream::V1::Datastream::GetStreamRequest'->new($_) };

declare 'RepeatedGetStreamRequest',
    as ArrayRef[GetStreamRequest()];

coerce 'RepeatedGetStreamRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datastream::V1::Datastream::GetStreamRequest'->new($_) } @$_ ] };

declare 'MapStringGetStreamRequest',
    as HashRef[GetStreamRequest()];

declare 'CreateStreamRequest',
    as InstanceOf['Google::Cloud::Datastream::V1::Datastream::CreateStreamRequest'];

coerce 'CreateStreamRequest',
    from HashRef, via { 'Google::Cloud::Datastream::V1::Datastream::CreateStreamRequest'->new($_) };

declare 'RepeatedCreateStreamRequest',
    as ArrayRef[CreateStreamRequest()];

coerce 'RepeatedCreateStreamRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datastream::V1::Datastream::CreateStreamRequest'->new($_) } @$_ ] };

declare 'MapStringCreateStreamRequest',
    as HashRef[CreateStreamRequest()];

declare 'UpdateStreamRequest',
    as InstanceOf['Google::Cloud::Datastream::V1::Datastream::UpdateStreamRequest'];

coerce 'UpdateStreamRequest',
    from HashRef, via { 'Google::Cloud::Datastream::V1::Datastream::UpdateStreamRequest'->new($_) };

declare 'RepeatedUpdateStreamRequest',
    as ArrayRef[UpdateStreamRequest()];

coerce 'RepeatedUpdateStreamRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datastream::V1::Datastream::UpdateStreamRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateStreamRequest',
    as HashRef[UpdateStreamRequest()];

declare 'DeleteStreamRequest',
    as InstanceOf['Google::Cloud::Datastream::V1::Datastream::DeleteStreamRequest'];

coerce 'DeleteStreamRequest',
    from HashRef, via { 'Google::Cloud::Datastream::V1::Datastream::DeleteStreamRequest'->new($_) };

declare 'RepeatedDeleteStreamRequest',
    as ArrayRef[DeleteStreamRequest()];

coerce 'RepeatedDeleteStreamRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datastream::V1::Datastream::DeleteStreamRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteStreamRequest',
    as HashRef[DeleteStreamRequest()];

declare 'RunStreamRequest',
    as InstanceOf['Google::Cloud::Datastream::V1::Datastream::RunStreamRequest'];

coerce 'RunStreamRequest',
    from HashRef, via { 'Google::Cloud::Datastream::V1::Datastream::RunStreamRequest'->new($_) };

declare 'RepeatedRunStreamRequest',
    as ArrayRef[RunStreamRequest()];

coerce 'RepeatedRunStreamRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datastream::V1::Datastream::RunStreamRequest'->new($_) } @$_ ] };

declare 'MapStringRunStreamRequest',
    as HashRef[RunStreamRequest()];

declare 'GetStreamObjectRequest',
    as InstanceOf['Google::Cloud::Datastream::V1::Datastream::GetStreamObjectRequest'];

coerce 'GetStreamObjectRequest',
    from HashRef, via { 'Google::Cloud::Datastream::V1::Datastream::GetStreamObjectRequest'->new($_) };

declare 'RepeatedGetStreamObjectRequest',
    as ArrayRef[GetStreamObjectRequest()];

coerce 'RepeatedGetStreamObjectRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datastream::V1::Datastream::GetStreamObjectRequest'->new($_) } @$_ ] };

declare 'MapStringGetStreamObjectRequest',
    as HashRef[GetStreamObjectRequest()];

declare 'LookupStreamObjectRequest',
    as InstanceOf['Google::Cloud::Datastream::V1::Datastream::LookupStreamObjectRequest'];

coerce 'LookupStreamObjectRequest',
    from HashRef, via { 'Google::Cloud::Datastream::V1::Datastream::LookupStreamObjectRequest'->new($_) };

declare 'RepeatedLookupStreamObjectRequest',
    as ArrayRef[LookupStreamObjectRequest()];

coerce 'RepeatedLookupStreamObjectRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datastream::V1::Datastream::LookupStreamObjectRequest'->new($_) } @$_ ] };

declare 'MapStringLookupStreamObjectRequest',
    as HashRef[LookupStreamObjectRequest()];

declare 'StartBackfillJobRequest',
    as InstanceOf['Google::Cloud::Datastream::V1::Datastream::StartBackfillJobRequest'];

coerce 'StartBackfillJobRequest',
    from HashRef, via { 'Google::Cloud::Datastream::V1::Datastream::StartBackfillJobRequest'->new($_) };

declare 'RepeatedStartBackfillJobRequest',
    as ArrayRef[StartBackfillJobRequest()];

coerce 'RepeatedStartBackfillJobRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datastream::V1::Datastream::StartBackfillJobRequest'->new($_) } @$_ ] };

declare 'MapStringStartBackfillJobRequest',
    as HashRef[StartBackfillJobRequest()];

declare 'StartBackfillJobResponse',
    as InstanceOf['Google::Cloud::Datastream::V1::Datastream::StartBackfillJobResponse'];

coerce 'StartBackfillJobResponse',
    from HashRef, via { 'Google::Cloud::Datastream::V1::Datastream::StartBackfillJobResponse'->new($_) };

declare 'RepeatedStartBackfillJobResponse',
    as ArrayRef[StartBackfillJobResponse()];

coerce 'RepeatedStartBackfillJobResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datastream::V1::Datastream::StartBackfillJobResponse'->new($_) } @$_ ] };

declare 'MapStringStartBackfillJobResponse',
    as HashRef[StartBackfillJobResponse()];

declare 'StopBackfillJobRequest',
    as InstanceOf['Google::Cloud::Datastream::V1::Datastream::StopBackfillJobRequest'];

coerce 'StopBackfillJobRequest',
    from HashRef, via { 'Google::Cloud::Datastream::V1::Datastream::StopBackfillJobRequest'->new($_) };

declare 'RepeatedStopBackfillJobRequest',
    as ArrayRef[StopBackfillJobRequest()];

coerce 'RepeatedStopBackfillJobRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datastream::V1::Datastream::StopBackfillJobRequest'->new($_) } @$_ ] };

declare 'MapStringStopBackfillJobRequest',
    as HashRef[StopBackfillJobRequest()];

declare 'StopBackfillJobResponse',
    as InstanceOf['Google::Cloud::Datastream::V1::Datastream::StopBackfillJobResponse'];

coerce 'StopBackfillJobResponse',
    from HashRef, via { 'Google::Cloud::Datastream::V1::Datastream::StopBackfillJobResponse'->new($_) };

declare 'RepeatedStopBackfillJobResponse',
    as ArrayRef[StopBackfillJobResponse()];

coerce 'RepeatedStopBackfillJobResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datastream::V1::Datastream::StopBackfillJobResponse'->new($_) } @$_ ] };

declare 'MapStringStopBackfillJobResponse',
    as HashRef[StopBackfillJobResponse()];

declare 'ListStreamObjectsRequest',
    as InstanceOf['Google::Cloud::Datastream::V1::Datastream::ListStreamObjectsRequest'];

coerce 'ListStreamObjectsRequest',
    from HashRef, via { 'Google::Cloud::Datastream::V1::Datastream::ListStreamObjectsRequest'->new($_) };

declare 'RepeatedListStreamObjectsRequest',
    as ArrayRef[ListStreamObjectsRequest()];

coerce 'RepeatedListStreamObjectsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datastream::V1::Datastream::ListStreamObjectsRequest'->new($_) } @$_ ] };

declare 'MapStringListStreamObjectsRequest',
    as HashRef[ListStreamObjectsRequest()];

declare 'ListStreamObjectsResponse',
    as InstanceOf['Google::Cloud::Datastream::V1::Datastream::ListStreamObjectsResponse'];

coerce 'ListStreamObjectsResponse',
    from HashRef, via { 'Google::Cloud::Datastream::V1::Datastream::ListStreamObjectsResponse'->new($_) };

declare 'RepeatedListStreamObjectsResponse',
    as ArrayRef[ListStreamObjectsResponse()];

coerce 'RepeatedListStreamObjectsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datastream::V1::Datastream::ListStreamObjectsResponse'->new($_) } @$_ ] };

declare 'MapStringListStreamObjectsResponse',
    as HashRef[ListStreamObjectsResponse()];

declare 'OperationMetadata',
    as InstanceOf['Google::Cloud::Datastream::V1::Datastream::OperationMetadata'];

coerce 'OperationMetadata',
    from HashRef, via { 'Google::Cloud::Datastream::V1::Datastream::OperationMetadata'->new($_) };

declare 'RepeatedOperationMetadata',
    as ArrayRef[OperationMetadata()];

coerce 'RepeatedOperationMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datastream::V1::Datastream::OperationMetadata'->new($_) } @$_ ] };

declare 'MapStringOperationMetadata',
    as HashRef[OperationMetadata()];

declare 'CreatePrivateConnectionRequest',
    as InstanceOf['Google::Cloud::Datastream::V1::Datastream::CreatePrivateConnectionRequest'];

coerce 'CreatePrivateConnectionRequest',
    from HashRef, via { 'Google::Cloud::Datastream::V1::Datastream::CreatePrivateConnectionRequest'->new($_) };

declare 'RepeatedCreatePrivateConnectionRequest',
    as ArrayRef[CreatePrivateConnectionRequest()];

coerce 'RepeatedCreatePrivateConnectionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datastream::V1::Datastream::CreatePrivateConnectionRequest'->new($_) } @$_ ] };

declare 'MapStringCreatePrivateConnectionRequest',
    as HashRef[CreatePrivateConnectionRequest()];

declare 'ListPrivateConnectionsRequest',
    as InstanceOf['Google::Cloud::Datastream::V1::Datastream::ListPrivateConnectionsRequest'];

coerce 'ListPrivateConnectionsRequest',
    from HashRef, via { 'Google::Cloud::Datastream::V1::Datastream::ListPrivateConnectionsRequest'->new($_) };

declare 'RepeatedListPrivateConnectionsRequest',
    as ArrayRef[ListPrivateConnectionsRequest()];

coerce 'RepeatedListPrivateConnectionsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datastream::V1::Datastream::ListPrivateConnectionsRequest'->new($_) } @$_ ] };

declare 'MapStringListPrivateConnectionsRequest',
    as HashRef[ListPrivateConnectionsRequest()];

declare 'ListPrivateConnectionsResponse',
    as InstanceOf['Google::Cloud::Datastream::V1::Datastream::ListPrivateConnectionsResponse'];

coerce 'ListPrivateConnectionsResponse',
    from HashRef, via { 'Google::Cloud::Datastream::V1::Datastream::ListPrivateConnectionsResponse'->new($_) };

declare 'RepeatedListPrivateConnectionsResponse',
    as ArrayRef[ListPrivateConnectionsResponse()];

coerce 'RepeatedListPrivateConnectionsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datastream::V1::Datastream::ListPrivateConnectionsResponse'->new($_) } @$_ ] };

declare 'MapStringListPrivateConnectionsResponse',
    as HashRef[ListPrivateConnectionsResponse()];

declare 'DeletePrivateConnectionRequest',
    as InstanceOf['Google::Cloud::Datastream::V1::Datastream::DeletePrivateConnectionRequest'];

coerce 'DeletePrivateConnectionRequest',
    from HashRef, via { 'Google::Cloud::Datastream::V1::Datastream::DeletePrivateConnectionRequest'->new($_) };

declare 'RepeatedDeletePrivateConnectionRequest',
    as ArrayRef[DeletePrivateConnectionRequest()];

coerce 'RepeatedDeletePrivateConnectionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datastream::V1::Datastream::DeletePrivateConnectionRequest'->new($_) } @$_ ] };

declare 'MapStringDeletePrivateConnectionRequest',
    as HashRef[DeletePrivateConnectionRequest()];

declare 'GetPrivateConnectionRequest',
    as InstanceOf['Google::Cloud::Datastream::V1::Datastream::GetPrivateConnectionRequest'];

coerce 'GetPrivateConnectionRequest',
    from HashRef, via { 'Google::Cloud::Datastream::V1::Datastream::GetPrivateConnectionRequest'->new($_) };

declare 'RepeatedGetPrivateConnectionRequest',
    as ArrayRef[GetPrivateConnectionRequest()];

coerce 'RepeatedGetPrivateConnectionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datastream::V1::Datastream::GetPrivateConnectionRequest'->new($_) } @$_ ] };

declare 'MapStringGetPrivateConnectionRequest',
    as HashRef[GetPrivateConnectionRequest()];

declare 'CreateRouteRequest',
    as InstanceOf['Google::Cloud::Datastream::V1::Datastream::CreateRouteRequest'];

coerce 'CreateRouteRequest',
    from HashRef, via { 'Google::Cloud::Datastream::V1::Datastream::CreateRouteRequest'->new($_) };

declare 'RepeatedCreateRouteRequest',
    as ArrayRef[CreateRouteRequest()];

coerce 'RepeatedCreateRouteRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datastream::V1::Datastream::CreateRouteRequest'->new($_) } @$_ ] };

declare 'MapStringCreateRouteRequest',
    as HashRef[CreateRouteRequest()];

declare 'ListRoutesRequest',
    as InstanceOf['Google::Cloud::Datastream::V1::Datastream::ListRoutesRequest'];

coerce 'ListRoutesRequest',
    from HashRef, via { 'Google::Cloud::Datastream::V1::Datastream::ListRoutesRequest'->new($_) };

declare 'RepeatedListRoutesRequest',
    as ArrayRef[ListRoutesRequest()];

coerce 'RepeatedListRoutesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datastream::V1::Datastream::ListRoutesRequest'->new($_) } @$_ ] };

declare 'MapStringListRoutesRequest',
    as HashRef[ListRoutesRequest()];

declare 'ListRoutesResponse',
    as InstanceOf['Google::Cloud::Datastream::V1::Datastream::ListRoutesResponse'];

coerce 'ListRoutesResponse',
    from HashRef, via { 'Google::Cloud::Datastream::V1::Datastream::ListRoutesResponse'->new($_) };

declare 'RepeatedListRoutesResponse',
    as ArrayRef[ListRoutesResponse()];

coerce 'RepeatedListRoutesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datastream::V1::Datastream::ListRoutesResponse'->new($_) } @$_ ] };

declare 'MapStringListRoutesResponse',
    as HashRef[ListRoutesResponse()];

declare 'DeleteRouteRequest',
    as InstanceOf['Google::Cloud::Datastream::V1::Datastream::DeleteRouteRequest'];

coerce 'DeleteRouteRequest',
    from HashRef, via { 'Google::Cloud::Datastream::V1::Datastream::DeleteRouteRequest'->new($_) };

declare 'RepeatedDeleteRouteRequest',
    as ArrayRef[DeleteRouteRequest()];

coerce 'RepeatedDeleteRouteRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datastream::V1::Datastream::DeleteRouteRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteRouteRequest',
    as HashRef[DeleteRouteRequest()];

declare 'GetRouteRequest',
    as InstanceOf['Google::Cloud::Datastream::V1::Datastream::GetRouteRequest'];

coerce 'GetRouteRequest',
    from HashRef, via { 'Google::Cloud::Datastream::V1::Datastream::GetRouteRequest'->new($_) };

declare 'RepeatedGetRouteRequest',
    as ArrayRef[GetRouteRequest()];

coerce 'RepeatedGetRouteRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datastream::V1::Datastream::GetRouteRequest'->new($_) } @$_ ] };

declare 'MapStringGetRouteRequest',
    as HashRef[GetRouteRequest()];

1;

__END__

=head1 NAME

Google::Cloud::Datastream::V1::Datastream::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
