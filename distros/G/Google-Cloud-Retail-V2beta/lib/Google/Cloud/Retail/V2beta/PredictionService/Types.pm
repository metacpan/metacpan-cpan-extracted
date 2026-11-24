package Google::Cloud::Retail::V2beta::PredictionService::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'PredictRequest',
    as InstanceOf['Google::Cloud::Retail::V2beta::PredictionService::PredictRequest'];

coerce 'PredictRequest',
    from HashRef, via { 'Google::Cloud::Retail::V2beta::PredictionService::PredictRequest'->new($_) };

declare 'RepeatedPredictRequest',
    as ArrayRef[PredictRequest()];

coerce 'RepeatedPredictRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Retail::V2beta::PredictionService::PredictRequest'->new($_) } @$_ ] };

declare 'MapStringPredictRequest',
    as HashRef[PredictRequest()];

declare 'ParamsEntry',
    as InstanceOf['Google::Cloud::Retail::V2beta::PredictionService::PredictRequest::ParamsEntry'];

coerce 'ParamsEntry',
    from HashRef, via { 'Google::Cloud::Retail::V2beta::PredictionService::PredictRequest::ParamsEntry'->new($_) };

declare 'RepeatedParamsEntry',
    as ArrayRef[ParamsEntry()];

coerce 'RepeatedParamsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Retail::V2beta::PredictionService::PredictRequest::ParamsEntry'->new($_) } @$_ ] };

declare 'MapStringParamsEntry',
    as HashRef[ParamsEntry()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Retail::V2beta::PredictionService::PredictRequest::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Retail::V2beta::PredictionService::PredictRequest::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Retail::V2beta::PredictionService::PredictRequest::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'PredictResponse',
    as InstanceOf['Google::Cloud::Retail::V2beta::PredictionService::PredictResponse'];

coerce 'PredictResponse',
    from HashRef, via { 'Google::Cloud::Retail::V2beta::PredictionService::PredictResponse'->new($_) };

declare 'RepeatedPredictResponse',
    as ArrayRef[PredictResponse()];

coerce 'RepeatedPredictResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Retail::V2beta::PredictionService::PredictResponse'->new($_) } @$_ ] };

declare 'MapStringPredictResponse',
    as HashRef[PredictResponse()];

declare 'PredictionResult',
    as InstanceOf['Google::Cloud::Retail::V2beta::PredictionService::PredictResponse::PredictionResult'];

coerce 'PredictionResult',
    from HashRef, via { 'Google::Cloud::Retail::V2beta::PredictionService::PredictResponse::PredictionResult'->new($_) };

declare 'RepeatedPredictionResult',
    as ArrayRef[PredictionResult()];

coerce 'RepeatedPredictionResult',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Retail::V2beta::PredictionService::PredictResponse::PredictionResult'->new($_) } @$_ ] };

declare 'MapStringPredictionResult',
    as HashRef[PredictionResult()];

declare 'MetadataEntry',
    as InstanceOf['Google::Cloud::Retail::V2beta::PredictionService::PredictResponse::PredictionResult::MetadataEntry'];

coerce 'MetadataEntry',
    from HashRef, via { 'Google::Cloud::Retail::V2beta::PredictionService::PredictResponse::PredictionResult::MetadataEntry'->new($_) };

declare 'RepeatedMetadataEntry',
    as ArrayRef[MetadataEntry()];

coerce 'RepeatedMetadataEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Retail::V2beta::PredictionService::PredictResponse::PredictionResult::MetadataEntry'->new($_) } @$_ ] };

declare 'MapStringMetadataEntry',
    as HashRef[MetadataEntry()];

1;

__END__

=head1 NAME

Google::Cloud::Retail::V2beta::PredictionService::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
