package Google::Cloud::Discoveryengine::V1beta::RecommendationService::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'RecommendRequest',
    as InstanceOf['Google::Cloud::Discoveryengine::V1beta::RecommendationService::RecommendRequest'];

coerce 'RecommendRequest',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1beta::RecommendationService::RecommendRequest'->new($_) };

declare 'RepeatedRecommendRequest',
    as ArrayRef[RecommendRequest()];

coerce 'RepeatedRecommendRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1beta::RecommendationService::RecommendRequest'->new($_) } @$_ ] };

declare 'MapStringRecommendRequest',
    as HashRef[RecommendRequest()];

declare 'ParamsEntry',
    as InstanceOf['Google::Cloud::Discoveryengine::V1beta::RecommendationService::RecommendRequest::ParamsEntry'];

coerce 'ParamsEntry',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1beta::RecommendationService::RecommendRequest::ParamsEntry'->new($_) };

declare 'RepeatedParamsEntry',
    as ArrayRef[ParamsEntry()];

coerce 'RepeatedParamsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1beta::RecommendationService::RecommendRequest::ParamsEntry'->new($_) } @$_ ] };

declare 'MapStringParamsEntry',
    as HashRef[ParamsEntry()];

declare 'UserLabelsEntry',
    as InstanceOf['Google::Cloud::Discoveryengine::V1beta::RecommendationService::RecommendRequest::UserLabelsEntry'];

coerce 'UserLabelsEntry',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1beta::RecommendationService::RecommendRequest::UserLabelsEntry'->new($_) };

declare 'RepeatedUserLabelsEntry',
    as ArrayRef[UserLabelsEntry()];

coerce 'RepeatedUserLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1beta::RecommendationService::RecommendRequest::UserLabelsEntry'->new($_) } @$_ ] };

declare 'MapStringUserLabelsEntry',
    as HashRef[UserLabelsEntry()];

declare 'RecommendResponse',
    as InstanceOf['Google::Cloud::Discoveryengine::V1beta::RecommendationService::RecommendResponse'];

coerce 'RecommendResponse',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1beta::RecommendationService::RecommendResponse'->new($_) };

declare 'RepeatedRecommendResponse',
    as ArrayRef[RecommendResponse()];

coerce 'RepeatedRecommendResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1beta::RecommendationService::RecommendResponse'->new($_) } @$_ ] };

declare 'MapStringRecommendResponse',
    as HashRef[RecommendResponse()];

declare 'RecommendationResult',
    as InstanceOf['Google::Cloud::Discoveryengine::V1beta::RecommendationService::RecommendResponse::RecommendationResult'];

coerce 'RecommendationResult',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1beta::RecommendationService::RecommendResponse::RecommendationResult'->new($_) };

declare 'RepeatedRecommendationResult',
    as ArrayRef[RecommendationResult()];

coerce 'RepeatedRecommendationResult',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1beta::RecommendationService::RecommendResponse::RecommendationResult'->new($_) } @$_ ] };

declare 'MapStringRecommendationResult',
    as HashRef[RecommendationResult()];

declare 'MetadataEntry',
    as InstanceOf['Google::Cloud::Discoveryengine::V1beta::RecommendationService::RecommendResponse::RecommendationResult::MetadataEntry'];

coerce 'MetadataEntry',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1beta::RecommendationService::RecommendResponse::RecommendationResult::MetadataEntry'->new($_) };

declare 'RepeatedMetadataEntry',
    as ArrayRef[MetadataEntry()];

coerce 'RepeatedMetadataEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1beta::RecommendationService::RecommendResponse::RecommendationResult::MetadataEntry'->new($_) } @$_ ] };

declare 'MapStringMetadataEntry',
    as HashRef[MetadataEntry()];

1;

__END__

=head1 NAME

Google::Cloud::Discoveryengine::V1beta::RecommendationService::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
