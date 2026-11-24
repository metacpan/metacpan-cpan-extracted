package Google::Cloud::Recommender::V1beta1::RecommenderService::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'ListInsightsRequest',
    as InstanceOf['Google::Cloud::Recommender::V1beta1::RecommenderService::ListInsightsRequest'];

coerce 'ListInsightsRequest',
    from HashRef, via { 'Google::Cloud::Recommender::V1beta1::RecommenderService::ListInsightsRequest'->new($_) };

declare 'RepeatedListInsightsRequest',
    as ArrayRef[ListInsightsRequest()];

coerce 'RepeatedListInsightsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Recommender::V1beta1::RecommenderService::ListInsightsRequest'->new($_) } @$_ ] };

declare 'MapStringListInsightsRequest',
    as HashRef[ListInsightsRequest()];

declare 'ListInsightsResponse',
    as InstanceOf['Google::Cloud::Recommender::V1beta1::RecommenderService::ListInsightsResponse'];

coerce 'ListInsightsResponse',
    from HashRef, via { 'Google::Cloud::Recommender::V1beta1::RecommenderService::ListInsightsResponse'->new($_) };

declare 'RepeatedListInsightsResponse',
    as ArrayRef[ListInsightsResponse()];

coerce 'RepeatedListInsightsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Recommender::V1beta1::RecommenderService::ListInsightsResponse'->new($_) } @$_ ] };

declare 'MapStringListInsightsResponse',
    as HashRef[ListInsightsResponse()];

declare 'GetInsightRequest',
    as InstanceOf['Google::Cloud::Recommender::V1beta1::RecommenderService::GetInsightRequest'];

coerce 'GetInsightRequest',
    from HashRef, via { 'Google::Cloud::Recommender::V1beta1::RecommenderService::GetInsightRequest'->new($_) };

declare 'RepeatedGetInsightRequest',
    as ArrayRef[GetInsightRequest()];

coerce 'RepeatedGetInsightRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Recommender::V1beta1::RecommenderService::GetInsightRequest'->new($_) } @$_ ] };

declare 'MapStringGetInsightRequest',
    as HashRef[GetInsightRequest()];

declare 'MarkInsightAcceptedRequest',
    as InstanceOf['Google::Cloud::Recommender::V1beta1::RecommenderService::MarkInsightAcceptedRequest'];

coerce 'MarkInsightAcceptedRequest',
    from HashRef, via { 'Google::Cloud::Recommender::V1beta1::RecommenderService::MarkInsightAcceptedRequest'->new($_) };

declare 'RepeatedMarkInsightAcceptedRequest',
    as ArrayRef[MarkInsightAcceptedRequest()];

coerce 'RepeatedMarkInsightAcceptedRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Recommender::V1beta1::RecommenderService::MarkInsightAcceptedRequest'->new($_) } @$_ ] };

declare 'MapStringMarkInsightAcceptedRequest',
    as HashRef[MarkInsightAcceptedRequest()];

declare 'StateMetadataEntry',
    as InstanceOf['Google::Cloud::Recommender::V1beta1::RecommenderService::MarkInsightAcceptedRequest::StateMetadataEntry'];

coerce 'StateMetadataEntry',
    from HashRef, via { 'Google::Cloud::Recommender::V1beta1::RecommenderService::MarkInsightAcceptedRequest::StateMetadataEntry'->new($_) };

declare 'RepeatedStateMetadataEntry',
    as ArrayRef[StateMetadataEntry()];

coerce 'RepeatedStateMetadataEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Recommender::V1beta1::RecommenderService::MarkInsightAcceptedRequest::StateMetadataEntry'->new($_) } @$_ ] };

declare 'MapStringStateMetadataEntry',
    as HashRef[StateMetadataEntry()];

declare 'ListRecommendationsRequest',
    as InstanceOf['Google::Cloud::Recommender::V1beta1::RecommenderService::ListRecommendationsRequest'];

coerce 'ListRecommendationsRequest',
    from HashRef, via { 'Google::Cloud::Recommender::V1beta1::RecommenderService::ListRecommendationsRequest'->new($_) };

declare 'RepeatedListRecommendationsRequest',
    as ArrayRef[ListRecommendationsRequest()];

coerce 'RepeatedListRecommendationsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Recommender::V1beta1::RecommenderService::ListRecommendationsRequest'->new($_) } @$_ ] };

declare 'MapStringListRecommendationsRequest',
    as HashRef[ListRecommendationsRequest()];

declare 'ListRecommendationsResponse',
    as InstanceOf['Google::Cloud::Recommender::V1beta1::RecommenderService::ListRecommendationsResponse'];

coerce 'ListRecommendationsResponse',
    from HashRef, via { 'Google::Cloud::Recommender::V1beta1::RecommenderService::ListRecommendationsResponse'->new($_) };

declare 'RepeatedListRecommendationsResponse',
    as ArrayRef[ListRecommendationsResponse()];

coerce 'RepeatedListRecommendationsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Recommender::V1beta1::RecommenderService::ListRecommendationsResponse'->new($_) } @$_ ] };

declare 'MapStringListRecommendationsResponse',
    as HashRef[ListRecommendationsResponse()];

declare 'GetRecommendationRequest',
    as InstanceOf['Google::Cloud::Recommender::V1beta1::RecommenderService::GetRecommendationRequest'];

coerce 'GetRecommendationRequest',
    from HashRef, via { 'Google::Cloud::Recommender::V1beta1::RecommenderService::GetRecommendationRequest'->new($_) };

declare 'RepeatedGetRecommendationRequest',
    as ArrayRef[GetRecommendationRequest()];

coerce 'RepeatedGetRecommendationRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Recommender::V1beta1::RecommenderService::GetRecommendationRequest'->new($_) } @$_ ] };

declare 'MapStringGetRecommendationRequest',
    as HashRef[GetRecommendationRequest()];

declare 'MarkRecommendationClaimedRequest',
    as InstanceOf['Google::Cloud::Recommender::V1beta1::RecommenderService::MarkRecommendationClaimedRequest'];

coerce 'MarkRecommendationClaimedRequest',
    from HashRef, via { 'Google::Cloud::Recommender::V1beta1::RecommenderService::MarkRecommendationClaimedRequest'->new($_) };

declare 'RepeatedMarkRecommendationClaimedRequest',
    as ArrayRef[MarkRecommendationClaimedRequest()];

coerce 'RepeatedMarkRecommendationClaimedRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Recommender::V1beta1::RecommenderService::MarkRecommendationClaimedRequest'->new($_) } @$_ ] };

declare 'MapStringMarkRecommendationClaimedRequest',
    as HashRef[MarkRecommendationClaimedRequest()];

declare 'StateMetadataEntry',
    as InstanceOf['Google::Cloud::Recommender::V1beta1::RecommenderService::MarkRecommendationClaimedRequest::StateMetadataEntry'];

coerce 'StateMetadataEntry',
    from HashRef, via { 'Google::Cloud::Recommender::V1beta1::RecommenderService::MarkRecommendationClaimedRequest::StateMetadataEntry'->new($_) };

declare 'RepeatedStateMetadataEntry',
    as ArrayRef[StateMetadataEntry()];

coerce 'RepeatedStateMetadataEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Recommender::V1beta1::RecommenderService::MarkRecommendationClaimedRequest::StateMetadataEntry'->new($_) } @$_ ] };

declare 'MapStringStateMetadataEntry',
    as HashRef[StateMetadataEntry()];

declare 'MarkRecommendationSucceededRequest',
    as InstanceOf['Google::Cloud::Recommender::V1beta1::RecommenderService::MarkRecommendationSucceededRequest'];

coerce 'MarkRecommendationSucceededRequest',
    from HashRef, via { 'Google::Cloud::Recommender::V1beta1::RecommenderService::MarkRecommendationSucceededRequest'->new($_) };

declare 'RepeatedMarkRecommendationSucceededRequest',
    as ArrayRef[MarkRecommendationSucceededRequest()];

coerce 'RepeatedMarkRecommendationSucceededRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Recommender::V1beta1::RecommenderService::MarkRecommendationSucceededRequest'->new($_) } @$_ ] };

declare 'MapStringMarkRecommendationSucceededRequest',
    as HashRef[MarkRecommendationSucceededRequest()];

declare 'StateMetadataEntry',
    as InstanceOf['Google::Cloud::Recommender::V1beta1::RecommenderService::MarkRecommendationSucceededRequest::StateMetadataEntry'];

coerce 'StateMetadataEntry',
    from HashRef, via { 'Google::Cloud::Recommender::V1beta1::RecommenderService::MarkRecommendationSucceededRequest::StateMetadataEntry'->new($_) };

declare 'RepeatedStateMetadataEntry',
    as ArrayRef[StateMetadataEntry()];

coerce 'RepeatedStateMetadataEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Recommender::V1beta1::RecommenderService::MarkRecommendationSucceededRequest::StateMetadataEntry'->new($_) } @$_ ] };

declare 'MapStringStateMetadataEntry',
    as HashRef[StateMetadataEntry()];

declare 'MarkRecommendationFailedRequest',
    as InstanceOf['Google::Cloud::Recommender::V1beta1::RecommenderService::MarkRecommendationFailedRequest'];

coerce 'MarkRecommendationFailedRequest',
    from HashRef, via { 'Google::Cloud::Recommender::V1beta1::RecommenderService::MarkRecommendationFailedRequest'->new($_) };

declare 'RepeatedMarkRecommendationFailedRequest',
    as ArrayRef[MarkRecommendationFailedRequest()];

coerce 'RepeatedMarkRecommendationFailedRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Recommender::V1beta1::RecommenderService::MarkRecommendationFailedRequest'->new($_) } @$_ ] };

declare 'MapStringMarkRecommendationFailedRequest',
    as HashRef[MarkRecommendationFailedRequest()];

declare 'StateMetadataEntry',
    as InstanceOf['Google::Cloud::Recommender::V1beta1::RecommenderService::MarkRecommendationFailedRequest::StateMetadataEntry'];

coerce 'StateMetadataEntry',
    from HashRef, via { 'Google::Cloud::Recommender::V1beta1::RecommenderService::MarkRecommendationFailedRequest::StateMetadataEntry'->new($_) };

declare 'RepeatedStateMetadataEntry',
    as ArrayRef[StateMetadataEntry()];

coerce 'RepeatedStateMetadataEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Recommender::V1beta1::RecommenderService::MarkRecommendationFailedRequest::StateMetadataEntry'->new($_) } @$_ ] };

declare 'MapStringStateMetadataEntry',
    as HashRef[StateMetadataEntry()];

declare 'GetRecommenderConfigRequest',
    as InstanceOf['Google::Cloud::Recommender::V1beta1::RecommenderService::GetRecommenderConfigRequest'];

coerce 'GetRecommenderConfigRequest',
    from HashRef, via { 'Google::Cloud::Recommender::V1beta1::RecommenderService::GetRecommenderConfigRequest'->new($_) };

declare 'RepeatedGetRecommenderConfigRequest',
    as ArrayRef[GetRecommenderConfigRequest()];

coerce 'RepeatedGetRecommenderConfigRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Recommender::V1beta1::RecommenderService::GetRecommenderConfigRequest'->new($_) } @$_ ] };

declare 'MapStringGetRecommenderConfigRequest',
    as HashRef[GetRecommenderConfigRequest()];

declare 'UpdateRecommenderConfigRequest',
    as InstanceOf['Google::Cloud::Recommender::V1beta1::RecommenderService::UpdateRecommenderConfigRequest'];

coerce 'UpdateRecommenderConfigRequest',
    from HashRef, via { 'Google::Cloud::Recommender::V1beta1::RecommenderService::UpdateRecommenderConfigRequest'->new($_) };

declare 'RepeatedUpdateRecommenderConfigRequest',
    as ArrayRef[UpdateRecommenderConfigRequest()];

coerce 'RepeatedUpdateRecommenderConfigRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Recommender::V1beta1::RecommenderService::UpdateRecommenderConfigRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateRecommenderConfigRequest',
    as HashRef[UpdateRecommenderConfigRequest()];

declare 'GetInsightTypeConfigRequest',
    as InstanceOf['Google::Cloud::Recommender::V1beta1::RecommenderService::GetInsightTypeConfigRequest'];

coerce 'GetInsightTypeConfigRequest',
    from HashRef, via { 'Google::Cloud::Recommender::V1beta1::RecommenderService::GetInsightTypeConfigRequest'->new($_) };

declare 'RepeatedGetInsightTypeConfigRequest',
    as ArrayRef[GetInsightTypeConfigRequest()];

coerce 'RepeatedGetInsightTypeConfigRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Recommender::V1beta1::RecommenderService::GetInsightTypeConfigRequest'->new($_) } @$_ ] };

declare 'MapStringGetInsightTypeConfigRequest',
    as HashRef[GetInsightTypeConfigRequest()];

declare 'UpdateInsightTypeConfigRequest',
    as InstanceOf['Google::Cloud::Recommender::V1beta1::RecommenderService::UpdateInsightTypeConfigRequest'];

coerce 'UpdateInsightTypeConfigRequest',
    from HashRef, via { 'Google::Cloud::Recommender::V1beta1::RecommenderService::UpdateInsightTypeConfigRequest'->new($_) };

declare 'RepeatedUpdateInsightTypeConfigRequest',
    as ArrayRef[UpdateInsightTypeConfigRequest()];

coerce 'RepeatedUpdateInsightTypeConfigRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Recommender::V1beta1::RecommenderService::UpdateInsightTypeConfigRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateInsightTypeConfigRequest',
    as HashRef[UpdateInsightTypeConfigRequest()];

declare 'ListRecommendersRequest',
    as InstanceOf['Google::Cloud::Recommender::V1beta1::RecommenderService::ListRecommendersRequest'];

coerce 'ListRecommendersRequest',
    from HashRef, via { 'Google::Cloud::Recommender::V1beta1::RecommenderService::ListRecommendersRequest'->new($_) };

declare 'RepeatedListRecommendersRequest',
    as ArrayRef[ListRecommendersRequest()];

coerce 'RepeatedListRecommendersRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Recommender::V1beta1::RecommenderService::ListRecommendersRequest'->new($_) } @$_ ] };

declare 'MapStringListRecommendersRequest',
    as HashRef[ListRecommendersRequest()];

declare 'ListRecommendersResponse',
    as InstanceOf['Google::Cloud::Recommender::V1beta1::RecommenderService::ListRecommendersResponse'];

coerce 'ListRecommendersResponse',
    from HashRef, via { 'Google::Cloud::Recommender::V1beta1::RecommenderService::ListRecommendersResponse'->new($_) };

declare 'RepeatedListRecommendersResponse',
    as ArrayRef[ListRecommendersResponse()];

coerce 'RepeatedListRecommendersResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Recommender::V1beta1::RecommenderService::ListRecommendersResponse'->new($_) } @$_ ] };

declare 'MapStringListRecommendersResponse',
    as HashRef[ListRecommendersResponse()];

declare 'ListInsightTypesRequest',
    as InstanceOf['Google::Cloud::Recommender::V1beta1::RecommenderService::ListInsightTypesRequest'];

coerce 'ListInsightTypesRequest',
    from HashRef, via { 'Google::Cloud::Recommender::V1beta1::RecommenderService::ListInsightTypesRequest'->new($_) };

declare 'RepeatedListInsightTypesRequest',
    as ArrayRef[ListInsightTypesRequest()];

coerce 'RepeatedListInsightTypesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Recommender::V1beta1::RecommenderService::ListInsightTypesRequest'->new($_) } @$_ ] };

declare 'MapStringListInsightTypesRequest',
    as HashRef[ListInsightTypesRequest()];

declare 'ListInsightTypesResponse',
    as InstanceOf['Google::Cloud::Recommender::V1beta1::RecommenderService::ListInsightTypesResponse'];

coerce 'ListInsightTypesResponse',
    from HashRef, via { 'Google::Cloud::Recommender::V1beta1::RecommenderService::ListInsightTypesResponse'->new($_) };

declare 'RepeatedListInsightTypesResponse',
    as ArrayRef[ListInsightTypesResponse()];

coerce 'RepeatedListInsightTypesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Recommender::V1beta1::RecommenderService::ListInsightTypesResponse'->new($_) } @$_ ] };

declare 'MapStringListInsightTypesResponse',
    as HashRef[ListInsightTypesResponse()];

1;

__END__

=head1 NAME

Google::Cloud::Recommender::V1beta1::RecommenderService::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
