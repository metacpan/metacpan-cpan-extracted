package Google::Cloud::Discoveryengine::V1beta::SearchTuningService::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'ListCustomModelsRequest',
    as InstanceOf['Google::Cloud::Discoveryengine::V1beta::SearchTuningService::ListCustomModelsRequest'];

coerce 'ListCustomModelsRequest',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1beta::SearchTuningService::ListCustomModelsRequest'->new($_) };

declare 'RepeatedListCustomModelsRequest',
    as ArrayRef[ListCustomModelsRequest()];

coerce 'RepeatedListCustomModelsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1beta::SearchTuningService::ListCustomModelsRequest'->new($_) } @$_ ] };

declare 'MapStringListCustomModelsRequest',
    as HashRef[ListCustomModelsRequest()];

declare 'ListCustomModelsResponse',
    as InstanceOf['Google::Cloud::Discoveryengine::V1beta::SearchTuningService::ListCustomModelsResponse'];

coerce 'ListCustomModelsResponse',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1beta::SearchTuningService::ListCustomModelsResponse'->new($_) };

declare 'RepeatedListCustomModelsResponse',
    as ArrayRef[ListCustomModelsResponse()];

coerce 'RepeatedListCustomModelsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1beta::SearchTuningService::ListCustomModelsResponse'->new($_) } @$_ ] };

declare 'MapStringListCustomModelsResponse',
    as HashRef[ListCustomModelsResponse()];

declare 'TrainCustomModelRequest',
    as InstanceOf['Google::Cloud::Discoveryengine::V1beta::SearchTuningService::TrainCustomModelRequest'];

coerce 'TrainCustomModelRequest',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1beta::SearchTuningService::TrainCustomModelRequest'->new($_) };

declare 'RepeatedTrainCustomModelRequest',
    as ArrayRef[TrainCustomModelRequest()];

coerce 'RepeatedTrainCustomModelRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1beta::SearchTuningService::TrainCustomModelRequest'->new($_) } @$_ ] };

declare 'MapStringTrainCustomModelRequest',
    as HashRef[TrainCustomModelRequest()];

declare 'GcsTrainingInput',
    as InstanceOf['Google::Cloud::Discoveryengine::V1beta::SearchTuningService::TrainCustomModelRequest::GcsTrainingInput'];

coerce 'GcsTrainingInput',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1beta::SearchTuningService::TrainCustomModelRequest::GcsTrainingInput'->new($_) };

declare 'RepeatedGcsTrainingInput',
    as ArrayRef[GcsTrainingInput()];

coerce 'RepeatedGcsTrainingInput',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1beta::SearchTuningService::TrainCustomModelRequest::GcsTrainingInput'->new($_) } @$_ ] };

declare 'MapStringGcsTrainingInput',
    as HashRef[GcsTrainingInput()];

declare 'TrainCustomModelResponse',
    as InstanceOf['Google::Cloud::Discoveryengine::V1beta::SearchTuningService::TrainCustomModelResponse'];

coerce 'TrainCustomModelResponse',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1beta::SearchTuningService::TrainCustomModelResponse'->new($_) };

declare 'RepeatedTrainCustomModelResponse',
    as ArrayRef[TrainCustomModelResponse()];

coerce 'RepeatedTrainCustomModelResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1beta::SearchTuningService::TrainCustomModelResponse'->new($_) } @$_ ] };

declare 'MapStringTrainCustomModelResponse',
    as HashRef[TrainCustomModelResponse()];

declare 'MetricsEntry',
    as InstanceOf['Google::Cloud::Discoveryengine::V1beta::SearchTuningService::TrainCustomModelResponse::MetricsEntry'];

coerce 'MetricsEntry',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1beta::SearchTuningService::TrainCustomModelResponse::MetricsEntry'->new($_) };

declare 'RepeatedMetricsEntry',
    as ArrayRef[MetricsEntry()];

coerce 'RepeatedMetricsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1beta::SearchTuningService::TrainCustomModelResponse::MetricsEntry'->new($_) } @$_ ] };

declare 'MapStringMetricsEntry',
    as HashRef[MetricsEntry()];

declare 'TrainCustomModelMetadata',
    as InstanceOf['Google::Cloud::Discoveryengine::V1beta::SearchTuningService::TrainCustomModelMetadata'];

coerce 'TrainCustomModelMetadata',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1beta::SearchTuningService::TrainCustomModelMetadata'->new($_) };

declare 'RepeatedTrainCustomModelMetadata',
    as ArrayRef[TrainCustomModelMetadata()];

coerce 'RepeatedTrainCustomModelMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1beta::SearchTuningService::TrainCustomModelMetadata'->new($_) } @$_ ] };

declare 'MapStringTrainCustomModelMetadata',
    as HashRef[TrainCustomModelMetadata()];

1;

__END__

=head1 NAME

Google::Cloud::Discoveryengine::V1beta::SearchTuningService::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
