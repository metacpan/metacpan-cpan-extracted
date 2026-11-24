package Google::Cloud::Datalabeling::V1beta1::HumanAnnotationConfig::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'StringAggregationType',
    as (Int | Str);

declare 'HumanAnnotationConfig',
    as InstanceOf['Google::Cloud::Datalabeling::V1beta1::HumanAnnotationConfig::HumanAnnotationConfig'];

coerce 'HumanAnnotationConfig',
    from HashRef, via { 'Google::Cloud::Datalabeling::V1beta1::HumanAnnotationConfig::HumanAnnotationConfig'->new($_) };

declare 'RepeatedHumanAnnotationConfig',
    as ArrayRef[HumanAnnotationConfig()];

coerce 'RepeatedHumanAnnotationConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datalabeling::V1beta1::HumanAnnotationConfig::HumanAnnotationConfig'->new($_) } @$_ ] };

declare 'MapStringHumanAnnotationConfig',
    as HashRef[HumanAnnotationConfig()];

declare 'ImageClassificationConfig',
    as InstanceOf['Google::Cloud::Datalabeling::V1beta1::HumanAnnotationConfig::ImageClassificationConfig'];

coerce 'ImageClassificationConfig',
    from HashRef, via { 'Google::Cloud::Datalabeling::V1beta1::HumanAnnotationConfig::ImageClassificationConfig'->new($_) };

declare 'RepeatedImageClassificationConfig',
    as ArrayRef[ImageClassificationConfig()];

coerce 'RepeatedImageClassificationConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datalabeling::V1beta1::HumanAnnotationConfig::ImageClassificationConfig'->new($_) } @$_ ] };

declare 'MapStringImageClassificationConfig',
    as HashRef[ImageClassificationConfig()];

declare 'BoundingPolyConfig',
    as InstanceOf['Google::Cloud::Datalabeling::V1beta1::HumanAnnotationConfig::BoundingPolyConfig'];

coerce 'BoundingPolyConfig',
    from HashRef, via { 'Google::Cloud::Datalabeling::V1beta1::HumanAnnotationConfig::BoundingPolyConfig'->new($_) };

declare 'RepeatedBoundingPolyConfig',
    as ArrayRef[BoundingPolyConfig()];

coerce 'RepeatedBoundingPolyConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datalabeling::V1beta1::HumanAnnotationConfig::BoundingPolyConfig'->new($_) } @$_ ] };

declare 'MapStringBoundingPolyConfig',
    as HashRef[BoundingPolyConfig()];

declare 'PolylineConfig',
    as InstanceOf['Google::Cloud::Datalabeling::V1beta1::HumanAnnotationConfig::PolylineConfig'];

coerce 'PolylineConfig',
    from HashRef, via { 'Google::Cloud::Datalabeling::V1beta1::HumanAnnotationConfig::PolylineConfig'->new($_) };

declare 'RepeatedPolylineConfig',
    as ArrayRef[PolylineConfig()];

coerce 'RepeatedPolylineConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datalabeling::V1beta1::HumanAnnotationConfig::PolylineConfig'->new($_) } @$_ ] };

declare 'MapStringPolylineConfig',
    as HashRef[PolylineConfig()];

declare 'SegmentationConfig',
    as InstanceOf['Google::Cloud::Datalabeling::V1beta1::HumanAnnotationConfig::SegmentationConfig'];

coerce 'SegmentationConfig',
    from HashRef, via { 'Google::Cloud::Datalabeling::V1beta1::HumanAnnotationConfig::SegmentationConfig'->new($_) };

declare 'RepeatedSegmentationConfig',
    as ArrayRef[SegmentationConfig()];

coerce 'RepeatedSegmentationConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datalabeling::V1beta1::HumanAnnotationConfig::SegmentationConfig'->new($_) } @$_ ] };

declare 'MapStringSegmentationConfig',
    as HashRef[SegmentationConfig()];

declare 'VideoClassificationConfig',
    as InstanceOf['Google::Cloud::Datalabeling::V1beta1::HumanAnnotationConfig::VideoClassificationConfig'];

coerce 'VideoClassificationConfig',
    from HashRef, via { 'Google::Cloud::Datalabeling::V1beta1::HumanAnnotationConfig::VideoClassificationConfig'->new($_) };

declare 'RepeatedVideoClassificationConfig',
    as ArrayRef[VideoClassificationConfig()];

coerce 'RepeatedVideoClassificationConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datalabeling::V1beta1::HumanAnnotationConfig::VideoClassificationConfig'->new($_) } @$_ ] };

declare 'MapStringVideoClassificationConfig',
    as HashRef[VideoClassificationConfig()];

declare 'AnnotationSpecSetConfig',
    as InstanceOf['Google::Cloud::Datalabeling::V1beta1::HumanAnnotationConfig::VideoClassificationConfig::AnnotationSpecSetConfig'];

coerce 'AnnotationSpecSetConfig',
    from HashRef, via { 'Google::Cloud::Datalabeling::V1beta1::HumanAnnotationConfig::VideoClassificationConfig::AnnotationSpecSetConfig'->new($_) };

declare 'RepeatedAnnotationSpecSetConfig',
    as ArrayRef[AnnotationSpecSetConfig()];

coerce 'RepeatedAnnotationSpecSetConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datalabeling::V1beta1::HumanAnnotationConfig::VideoClassificationConfig::AnnotationSpecSetConfig'->new($_) } @$_ ] };

declare 'MapStringAnnotationSpecSetConfig',
    as HashRef[AnnotationSpecSetConfig()];

declare 'ObjectDetectionConfig',
    as InstanceOf['Google::Cloud::Datalabeling::V1beta1::HumanAnnotationConfig::ObjectDetectionConfig'];

coerce 'ObjectDetectionConfig',
    from HashRef, via { 'Google::Cloud::Datalabeling::V1beta1::HumanAnnotationConfig::ObjectDetectionConfig'->new($_) };

declare 'RepeatedObjectDetectionConfig',
    as ArrayRef[ObjectDetectionConfig()];

coerce 'RepeatedObjectDetectionConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datalabeling::V1beta1::HumanAnnotationConfig::ObjectDetectionConfig'->new($_) } @$_ ] };

declare 'MapStringObjectDetectionConfig',
    as HashRef[ObjectDetectionConfig()];

declare 'ObjectTrackingConfig',
    as InstanceOf['Google::Cloud::Datalabeling::V1beta1::HumanAnnotationConfig::ObjectTrackingConfig'];

coerce 'ObjectTrackingConfig',
    from HashRef, via { 'Google::Cloud::Datalabeling::V1beta1::HumanAnnotationConfig::ObjectTrackingConfig'->new($_) };

declare 'RepeatedObjectTrackingConfig',
    as ArrayRef[ObjectTrackingConfig()];

coerce 'RepeatedObjectTrackingConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datalabeling::V1beta1::HumanAnnotationConfig::ObjectTrackingConfig'->new($_) } @$_ ] };

declare 'MapStringObjectTrackingConfig',
    as HashRef[ObjectTrackingConfig()];

declare 'EventConfig',
    as InstanceOf['Google::Cloud::Datalabeling::V1beta1::HumanAnnotationConfig::EventConfig'];

coerce 'EventConfig',
    from HashRef, via { 'Google::Cloud::Datalabeling::V1beta1::HumanAnnotationConfig::EventConfig'->new($_) };

declare 'RepeatedEventConfig',
    as ArrayRef[EventConfig()];

coerce 'RepeatedEventConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datalabeling::V1beta1::HumanAnnotationConfig::EventConfig'->new($_) } @$_ ] };

declare 'MapStringEventConfig',
    as HashRef[EventConfig()];

declare 'TextClassificationConfig',
    as InstanceOf['Google::Cloud::Datalabeling::V1beta1::HumanAnnotationConfig::TextClassificationConfig'];

coerce 'TextClassificationConfig',
    from HashRef, via { 'Google::Cloud::Datalabeling::V1beta1::HumanAnnotationConfig::TextClassificationConfig'->new($_) };

declare 'RepeatedTextClassificationConfig',
    as ArrayRef[TextClassificationConfig()];

coerce 'RepeatedTextClassificationConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datalabeling::V1beta1::HumanAnnotationConfig::TextClassificationConfig'->new($_) } @$_ ] };

declare 'MapStringTextClassificationConfig',
    as HashRef[TextClassificationConfig()];

declare 'SentimentConfig',
    as InstanceOf['Google::Cloud::Datalabeling::V1beta1::HumanAnnotationConfig::SentimentConfig'];

coerce 'SentimentConfig',
    from HashRef, via { 'Google::Cloud::Datalabeling::V1beta1::HumanAnnotationConfig::SentimentConfig'->new($_) };

declare 'RepeatedSentimentConfig',
    as ArrayRef[SentimentConfig()];

coerce 'RepeatedSentimentConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datalabeling::V1beta1::HumanAnnotationConfig::SentimentConfig'->new($_) } @$_ ] };

declare 'MapStringSentimentConfig',
    as HashRef[SentimentConfig()];

declare 'TextEntityExtractionConfig',
    as InstanceOf['Google::Cloud::Datalabeling::V1beta1::HumanAnnotationConfig::TextEntityExtractionConfig'];

coerce 'TextEntityExtractionConfig',
    from HashRef, via { 'Google::Cloud::Datalabeling::V1beta1::HumanAnnotationConfig::TextEntityExtractionConfig'->new($_) };

declare 'RepeatedTextEntityExtractionConfig',
    as ArrayRef[TextEntityExtractionConfig()];

coerce 'RepeatedTextEntityExtractionConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datalabeling::V1beta1::HumanAnnotationConfig::TextEntityExtractionConfig'->new($_) } @$_ ] };

declare 'MapStringTextEntityExtractionConfig',
    as HashRef[TextEntityExtractionConfig()];

1;

__END__

=head1 NAME

Google::Cloud::Datalabeling::V1beta1::HumanAnnotationConfig::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
