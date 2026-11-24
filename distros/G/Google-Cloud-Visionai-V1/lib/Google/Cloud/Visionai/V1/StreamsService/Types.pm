package Google::Cloud::Visionai::V1::StreamsService::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'ListClustersRequest',
    as InstanceOf['Google::Cloud::Visionai::V1::StreamsService::ListClustersRequest'];

coerce 'ListClustersRequest',
    from HashRef, via { 'Google::Cloud::Visionai::V1::StreamsService::ListClustersRequest'->new($_) };

declare 'RepeatedListClustersRequest',
    as ArrayRef[ListClustersRequest()];

coerce 'RepeatedListClustersRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::StreamsService::ListClustersRequest'->new($_) } @$_ ] };

declare 'MapStringListClustersRequest',
    as HashRef[ListClustersRequest()];

declare 'ListClustersResponse',
    as InstanceOf['Google::Cloud::Visionai::V1::StreamsService::ListClustersResponse'];

coerce 'ListClustersResponse',
    from HashRef, via { 'Google::Cloud::Visionai::V1::StreamsService::ListClustersResponse'->new($_) };

declare 'RepeatedListClustersResponse',
    as ArrayRef[ListClustersResponse()];

coerce 'RepeatedListClustersResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::StreamsService::ListClustersResponse'->new($_) } @$_ ] };

declare 'MapStringListClustersResponse',
    as HashRef[ListClustersResponse()];

declare 'GetClusterRequest',
    as InstanceOf['Google::Cloud::Visionai::V1::StreamsService::GetClusterRequest'];

coerce 'GetClusterRequest',
    from HashRef, via { 'Google::Cloud::Visionai::V1::StreamsService::GetClusterRequest'->new($_) };

declare 'RepeatedGetClusterRequest',
    as ArrayRef[GetClusterRequest()];

coerce 'RepeatedGetClusterRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::StreamsService::GetClusterRequest'->new($_) } @$_ ] };

declare 'MapStringGetClusterRequest',
    as HashRef[GetClusterRequest()];

declare 'CreateClusterRequest',
    as InstanceOf['Google::Cloud::Visionai::V1::StreamsService::CreateClusterRequest'];

coerce 'CreateClusterRequest',
    from HashRef, via { 'Google::Cloud::Visionai::V1::StreamsService::CreateClusterRequest'->new($_) };

declare 'RepeatedCreateClusterRequest',
    as ArrayRef[CreateClusterRequest()];

coerce 'RepeatedCreateClusterRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::StreamsService::CreateClusterRequest'->new($_) } @$_ ] };

declare 'MapStringCreateClusterRequest',
    as HashRef[CreateClusterRequest()];

declare 'UpdateClusterRequest',
    as InstanceOf['Google::Cloud::Visionai::V1::StreamsService::UpdateClusterRequest'];

coerce 'UpdateClusterRequest',
    from HashRef, via { 'Google::Cloud::Visionai::V1::StreamsService::UpdateClusterRequest'->new($_) };

declare 'RepeatedUpdateClusterRequest',
    as ArrayRef[UpdateClusterRequest()];

coerce 'RepeatedUpdateClusterRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::StreamsService::UpdateClusterRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateClusterRequest',
    as HashRef[UpdateClusterRequest()];

declare 'DeleteClusterRequest',
    as InstanceOf['Google::Cloud::Visionai::V1::StreamsService::DeleteClusterRequest'];

coerce 'DeleteClusterRequest',
    from HashRef, via { 'Google::Cloud::Visionai::V1::StreamsService::DeleteClusterRequest'->new($_) };

declare 'RepeatedDeleteClusterRequest',
    as ArrayRef[DeleteClusterRequest()];

coerce 'RepeatedDeleteClusterRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::StreamsService::DeleteClusterRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteClusterRequest',
    as HashRef[DeleteClusterRequest()];

declare 'ListStreamsRequest',
    as InstanceOf['Google::Cloud::Visionai::V1::StreamsService::ListStreamsRequest'];

coerce 'ListStreamsRequest',
    from HashRef, via { 'Google::Cloud::Visionai::V1::StreamsService::ListStreamsRequest'->new($_) };

declare 'RepeatedListStreamsRequest',
    as ArrayRef[ListStreamsRequest()];

coerce 'RepeatedListStreamsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::StreamsService::ListStreamsRequest'->new($_) } @$_ ] };

declare 'MapStringListStreamsRequest',
    as HashRef[ListStreamsRequest()];

declare 'ListStreamsResponse',
    as InstanceOf['Google::Cloud::Visionai::V1::StreamsService::ListStreamsResponse'];

coerce 'ListStreamsResponse',
    from HashRef, via { 'Google::Cloud::Visionai::V1::StreamsService::ListStreamsResponse'->new($_) };

declare 'RepeatedListStreamsResponse',
    as ArrayRef[ListStreamsResponse()];

coerce 'RepeatedListStreamsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::StreamsService::ListStreamsResponse'->new($_) } @$_ ] };

declare 'MapStringListStreamsResponse',
    as HashRef[ListStreamsResponse()];

declare 'GetStreamRequest',
    as InstanceOf['Google::Cloud::Visionai::V1::StreamsService::GetStreamRequest'];

coerce 'GetStreamRequest',
    from HashRef, via { 'Google::Cloud::Visionai::V1::StreamsService::GetStreamRequest'->new($_) };

declare 'RepeatedGetStreamRequest',
    as ArrayRef[GetStreamRequest()];

coerce 'RepeatedGetStreamRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::StreamsService::GetStreamRequest'->new($_) } @$_ ] };

declare 'MapStringGetStreamRequest',
    as HashRef[GetStreamRequest()];

declare 'CreateStreamRequest',
    as InstanceOf['Google::Cloud::Visionai::V1::StreamsService::CreateStreamRequest'];

coerce 'CreateStreamRequest',
    from HashRef, via { 'Google::Cloud::Visionai::V1::StreamsService::CreateStreamRequest'->new($_) };

declare 'RepeatedCreateStreamRequest',
    as ArrayRef[CreateStreamRequest()];

coerce 'RepeatedCreateStreamRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::StreamsService::CreateStreamRequest'->new($_) } @$_ ] };

declare 'MapStringCreateStreamRequest',
    as HashRef[CreateStreamRequest()];

declare 'UpdateStreamRequest',
    as InstanceOf['Google::Cloud::Visionai::V1::StreamsService::UpdateStreamRequest'];

coerce 'UpdateStreamRequest',
    from HashRef, via { 'Google::Cloud::Visionai::V1::StreamsService::UpdateStreamRequest'->new($_) };

declare 'RepeatedUpdateStreamRequest',
    as ArrayRef[UpdateStreamRequest()];

coerce 'RepeatedUpdateStreamRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::StreamsService::UpdateStreamRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateStreamRequest',
    as HashRef[UpdateStreamRequest()];

declare 'DeleteStreamRequest',
    as InstanceOf['Google::Cloud::Visionai::V1::StreamsService::DeleteStreamRequest'];

coerce 'DeleteStreamRequest',
    from HashRef, via { 'Google::Cloud::Visionai::V1::StreamsService::DeleteStreamRequest'->new($_) };

declare 'RepeatedDeleteStreamRequest',
    as ArrayRef[DeleteStreamRequest()];

coerce 'RepeatedDeleteStreamRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::StreamsService::DeleteStreamRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteStreamRequest',
    as HashRef[DeleteStreamRequest()];

declare 'GetStreamThumbnailRequest',
    as InstanceOf['Google::Cloud::Visionai::V1::StreamsService::GetStreamThumbnailRequest'];

coerce 'GetStreamThumbnailRequest',
    from HashRef, via { 'Google::Cloud::Visionai::V1::StreamsService::GetStreamThumbnailRequest'->new($_) };

declare 'RepeatedGetStreamThumbnailRequest',
    as ArrayRef[GetStreamThumbnailRequest()];

coerce 'RepeatedGetStreamThumbnailRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::StreamsService::GetStreamThumbnailRequest'->new($_) } @$_ ] };

declare 'MapStringGetStreamThumbnailRequest',
    as HashRef[GetStreamThumbnailRequest()];

declare 'GetStreamThumbnailResponse',
    as InstanceOf['Google::Cloud::Visionai::V1::StreamsService::GetStreamThumbnailResponse'];

coerce 'GetStreamThumbnailResponse',
    from HashRef, via { 'Google::Cloud::Visionai::V1::StreamsService::GetStreamThumbnailResponse'->new($_) };

declare 'RepeatedGetStreamThumbnailResponse',
    as ArrayRef[GetStreamThumbnailResponse()];

coerce 'RepeatedGetStreamThumbnailResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::StreamsService::GetStreamThumbnailResponse'->new($_) } @$_ ] };

declare 'MapStringGetStreamThumbnailResponse',
    as HashRef[GetStreamThumbnailResponse()];

declare 'GenerateStreamHlsTokenRequest',
    as InstanceOf['Google::Cloud::Visionai::V1::StreamsService::GenerateStreamHlsTokenRequest'];

coerce 'GenerateStreamHlsTokenRequest',
    from HashRef, via { 'Google::Cloud::Visionai::V1::StreamsService::GenerateStreamHlsTokenRequest'->new($_) };

declare 'RepeatedGenerateStreamHlsTokenRequest',
    as ArrayRef[GenerateStreamHlsTokenRequest()];

coerce 'RepeatedGenerateStreamHlsTokenRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::StreamsService::GenerateStreamHlsTokenRequest'->new($_) } @$_ ] };

declare 'MapStringGenerateStreamHlsTokenRequest',
    as HashRef[GenerateStreamHlsTokenRequest()];

declare 'GenerateStreamHlsTokenResponse',
    as InstanceOf['Google::Cloud::Visionai::V1::StreamsService::GenerateStreamHlsTokenResponse'];

coerce 'GenerateStreamHlsTokenResponse',
    from HashRef, via { 'Google::Cloud::Visionai::V1::StreamsService::GenerateStreamHlsTokenResponse'->new($_) };

declare 'RepeatedGenerateStreamHlsTokenResponse',
    as ArrayRef[GenerateStreamHlsTokenResponse()];

coerce 'RepeatedGenerateStreamHlsTokenResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::StreamsService::GenerateStreamHlsTokenResponse'->new($_) } @$_ ] };

declare 'MapStringGenerateStreamHlsTokenResponse',
    as HashRef[GenerateStreamHlsTokenResponse()];

declare 'ListEventsRequest',
    as InstanceOf['Google::Cloud::Visionai::V1::StreamsService::ListEventsRequest'];

coerce 'ListEventsRequest',
    from HashRef, via { 'Google::Cloud::Visionai::V1::StreamsService::ListEventsRequest'->new($_) };

declare 'RepeatedListEventsRequest',
    as ArrayRef[ListEventsRequest()];

coerce 'RepeatedListEventsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::StreamsService::ListEventsRequest'->new($_) } @$_ ] };

declare 'MapStringListEventsRequest',
    as HashRef[ListEventsRequest()];

declare 'ListEventsResponse',
    as InstanceOf['Google::Cloud::Visionai::V1::StreamsService::ListEventsResponse'];

coerce 'ListEventsResponse',
    from HashRef, via { 'Google::Cloud::Visionai::V1::StreamsService::ListEventsResponse'->new($_) };

declare 'RepeatedListEventsResponse',
    as ArrayRef[ListEventsResponse()];

coerce 'RepeatedListEventsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::StreamsService::ListEventsResponse'->new($_) } @$_ ] };

declare 'MapStringListEventsResponse',
    as HashRef[ListEventsResponse()];

declare 'GetEventRequest',
    as InstanceOf['Google::Cloud::Visionai::V1::StreamsService::GetEventRequest'];

coerce 'GetEventRequest',
    from HashRef, via { 'Google::Cloud::Visionai::V1::StreamsService::GetEventRequest'->new($_) };

declare 'RepeatedGetEventRequest',
    as ArrayRef[GetEventRequest()];

coerce 'RepeatedGetEventRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::StreamsService::GetEventRequest'->new($_) } @$_ ] };

declare 'MapStringGetEventRequest',
    as HashRef[GetEventRequest()];

declare 'CreateEventRequest',
    as InstanceOf['Google::Cloud::Visionai::V1::StreamsService::CreateEventRequest'];

coerce 'CreateEventRequest',
    from HashRef, via { 'Google::Cloud::Visionai::V1::StreamsService::CreateEventRequest'->new($_) };

declare 'RepeatedCreateEventRequest',
    as ArrayRef[CreateEventRequest()];

coerce 'RepeatedCreateEventRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::StreamsService::CreateEventRequest'->new($_) } @$_ ] };

declare 'MapStringCreateEventRequest',
    as HashRef[CreateEventRequest()];

declare 'UpdateEventRequest',
    as InstanceOf['Google::Cloud::Visionai::V1::StreamsService::UpdateEventRequest'];

coerce 'UpdateEventRequest',
    from HashRef, via { 'Google::Cloud::Visionai::V1::StreamsService::UpdateEventRequest'->new($_) };

declare 'RepeatedUpdateEventRequest',
    as ArrayRef[UpdateEventRequest()];

coerce 'RepeatedUpdateEventRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::StreamsService::UpdateEventRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateEventRequest',
    as HashRef[UpdateEventRequest()];

declare 'DeleteEventRequest',
    as InstanceOf['Google::Cloud::Visionai::V1::StreamsService::DeleteEventRequest'];

coerce 'DeleteEventRequest',
    from HashRef, via { 'Google::Cloud::Visionai::V1::StreamsService::DeleteEventRequest'->new($_) };

declare 'RepeatedDeleteEventRequest',
    as ArrayRef[DeleteEventRequest()];

coerce 'RepeatedDeleteEventRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::StreamsService::DeleteEventRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteEventRequest',
    as HashRef[DeleteEventRequest()];

declare 'ListSeriesRequest',
    as InstanceOf['Google::Cloud::Visionai::V1::StreamsService::ListSeriesRequest'];

coerce 'ListSeriesRequest',
    from HashRef, via { 'Google::Cloud::Visionai::V1::StreamsService::ListSeriesRequest'->new($_) };

declare 'RepeatedListSeriesRequest',
    as ArrayRef[ListSeriesRequest()];

coerce 'RepeatedListSeriesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::StreamsService::ListSeriesRequest'->new($_) } @$_ ] };

declare 'MapStringListSeriesRequest',
    as HashRef[ListSeriesRequest()];

declare 'ListSeriesResponse',
    as InstanceOf['Google::Cloud::Visionai::V1::StreamsService::ListSeriesResponse'];

coerce 'ListSeriesResponse',
    from HashRef, via { 'Google::Cloud::Visionai::V1::StreamsService::ListSeriesResponse'->new($_) };

declare 'RepeatedListSeriesResponse',
    as ArrayRef[ListSeriesResponse()];

coerce 'RepeatedListSeriesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::StreamsService::ListSeriesResponse'->new($_) } @$_ ] };

declare 'MapStringListSeriesResponse',
    as HashRef[ListSeriesResponse()];

declare 'GetSeriesRequest',
    as InstanceOf['Google::Cloud::Visionai::V1::StreamsService::GetSeriesRequest'];

coerce 'GetSeriesRequest',
    from HashRef, via { 'Google::Cloud::Visionai::V1::StreamsService::GetSeriesRequest'->new($_) };

declare 'RepeatedGetSeriesRequest',
    as ArrayRef[GetSeriesRequest()];

coerce 'RepeatedGetSeriesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::StreamsService::GetSeriesRequest'->new($_) } @$_ ] };

declare 'MapStringGetSeriesRequest',
    as HashRef[GetSeriesRequest()];

declare 'CreateSeriesRequest',
    as InstanceOf['Google::Cloud::Visionai::V1::StreamsService::CreateSeriesRequest'];

coerce 'CreateSeriesRequest',
    from HashRef, via { 'Google::Cloud::Visionai::V1::StreamsService::CreateSeriesRequest'->new($_) };

declare 'RepeatedCreateSeriesRequest',
    as ArrayRef[CreateSeriesRequest()];

coerce 'RepeatedCreateSeriesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::StreamsService::CreateSeriesRequest'->new($_) } @$_ ] };

declare 'MapStringCreateSeriesRequest',
    as HashRef[CreateSeriesRequest()];

declare 'UpdateSeriesRequest',
    as InstanceOf['Google::Cloud::Visionai::V1::StreamsService::UpdateSeriesRequest'];

coerce 'UpdateSeriesRequest',
    from HashRef, via { 'Google::Cloud::Visionai::V1::StreamsService::UpdateSeriesRequest'->new($_) };

declare 'RepeatedUpdateSeriesRequest',
    as ArrayRef[UpdateSeriesRequest()];

coerce 'RepeatedUpdateSeriesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::StreamsService::UpdateSeriesRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateSeriesRequest',
    as HashRef[UpdateSeriesRequest()];

declare 'DeleteSeriesRequest',
    as InstanceOf['Google::Cloud::Visionai::V1::StreamsService::DeleteSeriesRequest'];

coerce 'DeleteSeriesRequest',
    from HashRef, via { 'Google::Cloud::Visionai::V1::StreamsService::DeleteSeriesRequest'->new($_) };

declare 'RepeatedDeleteSeriesRequest',
    as ArrayRef[DeleteSeriesRequest()];

coerce 'RepeatedDeleteSeriesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::StreamsService::DeleteSeriesRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteSeriesRequest',
    as HashRef[DeleteSeriesRequest()];

declare 'MaterializeChannelRequest',
    as InstanceOf['Google::Cloud::Visionai::V1::StreamsService::MaterializeChannelRequest'];

coerce 'MaterializeChannelRequest',
    from HashRef, via { 'Google::Cloud::Visionai::V1::StreamsService::MaterializeChannelRequest'->new($_) };

declare 'RepeatedMaterializeChannelRequest',
    as ArrayRef[MaterializeChannelRequest()];

coerce 'RepeatedMaterializeChannelRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::StreamsService::MaterializeChannelRequest'->new($_) } @$_ ] };

declare 'MapStringMaterializeChannelRequest',
    as HashRef[MaterializeChannelRequest()];

1;

__END__

=head1 NAME

Google::Cloud::Visionai::V1::StreamsService::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
