package Google::Cloud::Automl::V1::PredictionService::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'PredictRequest',
    as InstanceOf['Google::Cloud::Automl::V1::PredictionService::PredictRequest'];

coerce 'PredictRequest',
    from HashRef, via { 'Google::Cloud::Automl::V1::PredictionService::PredictRequest'->new($_) };

declare 'RepeatedPredictRequest',
    as ArrayRef[PredictRequest()];

coerce 'RepeatedPredictRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Automl::V1::PredictionService::PredictRequest'->new($_) } @$_ ] };

declare 'MapStringPredictRequest',
    as HashRef[PredictRequest()];

declare 'ParamsEntry',
    as InstanceOf['Google::Cloud::Automl::V1::PredictionService::PredictRequest::ParamsEntry'];

coerce 'ParamsEntry',
    from HashRef, via { 'Google::Cloud::Automl::V1::PredictionService::PredictRequest::ParamsEntry'->new($_) };

declare 'RepeatedParamsEntry',
    as ArrayRef[ParamsEntry()];

coerce 'RepeatedParamsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Automl::V1::PredictionService::PredictRequest::ParamsEntry'->new($_) } @$_ ] };

declare 'MapStringParamsEntry',
    as HashRef[ParamsEntry()];

declare 'PredictResponse',
    as InstanceOf['Google::Cloud::Automl::V1::PredictionService::PredictResponse'];

coerce 'PredictResponse',
    from HashRef, via { 'Google::Cloud::Automl::V1::PredictionService::PredictResponse'->new($_) };

declare 'RepeatedPredictResponse',
    as ArrayRef[PredictResponse()];

coerce 'RepeatedPredictResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Automl::V1::PredictionService::PredictResponse'->new($_) } @$_ ] };

declare 'MapStringPredictResponse',
    as HashRef[PredictResponse()];

declare 'MetadataEntry',
    as InstanceOf['Google::Cloud::Automl::V1::PredictionService::PredictResponse::MetadataEntry'];

coerce 'MetadataEntry',
    from HashRef, via { 'Google::Cloud::Automl::V1::PredictionService::PredictResponse::MetadataEntry'->new($_) };

declare 'RepeatedMetadataEntry',
    as ArrayRef[MetadataEntry()];

coerce 'RepeatedMetadataEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Automl::V1::PredictionService::PredictResponse::MetadataEntry'->new($_) } @$_ ] };

declare 'MapStringMetadataEntry',
    as HashRef[MetadataEntry()];

declare 'BatchPredictRequest',
    as InstanceOf['Google::Cloud::Automl::V1::PredictionService::BatchPredictRequest'];

coerce 'BatchPredictRequest',
    from HashRef, via { 'Google::Cloud::Automl::V1::PredictionService::BatchPredictRequest'->new($_) };

declare 'RepeatedBatchPredictRequest',
    as ArrayRef[BatchPredictRequest()];

coerce 'RepeatedBatchPredictRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Automl::V1::PredictionService::BatchPredictRequest'->new($_) } @$_ ] };

declare 'MapStringBatchPredictRequest',
    as HashRef[BatchPredictRequest()];

declare 'ParamsEntry',
    as InstanceOf['Google::Cloud::Automl::V1::PredictionService::BatchPredictRequest::ParamsEntry'];

coerce 'ParamsEntry',
    from HashRef, via { 'Google::Cloud::Automl::V1::PredictionService::BatchPredictRequest::ParamsEntry'->new($_) };

declare 'RepeatedParamsEntry',
    as ArrayRef[ParamsEntry()];

coerce 'RepeatedParamsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Automl::V1::PredictionService::BatchPredictRequest::ParamsEntry'->new($_) } @$_ ] };

declare 'MapStringParamsEntry',
    as HashRef[ParamsEntry()];

declare 'BatchPredictResult',
    as InstanceOf['Google::Cloud::Automl::V1::PredictionService::BatchPredictResult'];

coerce 'BatchPredictResult',
    from HashRef, via { 'Google::Cloud::Automl::V1::PredictionService::BatchPredictResult'->new($_) };

declare 'RepeatedBatchPredictResult',
    as ArrayRef[BatchPredictResult()];

coerce 'RepeatedBatchPredictResult',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Automl::V1::PredictionService::BatchPredictResult'->new($_) } @$_ ] };

declare 'MapStringBatchPredictResult',
    as HashRef[BatchPredictResult()];

declare 'MetadataEntry',
    as InstanceOf['Google::Cloud::Automl::V1::PredictionService::BatchPredictResult::MetadataEntry'];

coerce 'MetadataEntry',
    from HashRef, via { 'Google::Cloud::Automl::V1::PredictionService::BatchPredictResult::MetadataEntry'->new($_) };

declare 'RepeatedMetadataEntry',
    as ArrayRef[MetadataEntry()];

coerce 'RepeatedMetadataEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Automl::V1::PredictionService::BatchPredictResult::MetadataEntry'->new($_) } @$_ ] };

declare 'MapStringMetadataEntry',
    as HashRef[MetadataEntry()];

1;

__END__

=head1 NAME

Google::Cloud::Automl::V1::PredictionService::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
