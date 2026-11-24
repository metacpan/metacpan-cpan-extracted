package Google::Cloud::Datalabeling::V1beta1::Annotation::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'AnnotationSource',
    as (Int | Str);

declare 'AnnotationSentiment',
    as (Int | Str);

declare 'AnnotationType',
    as (Int | Str);

declare 'Annotation',
    as InstanceOf['Google::Cloud::Datalabeling::V1beta1::Annotation::Annotation'];

coerce 'Annotation',
    from HashRef, via { 'Google::Cloud::Datalabeling::V1beta1::Annotation::Annotation'->new($_) };

declare 'RepeatedAnnotation',
    as ArrayRef[Annotation()];

coerce 'RepeatedAnnotation',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datalabeling::V1beta1::Annotation::Annotation'->new($_) } @$_ ] };

declare 'MapStringAnnotation',
    as HashRef[Annotation()];

declare 'AnnotationValue',
    as InstanceOf['Google::Cloud::Datalabeling::V1beta1::Annotation::AnnotationValue'];

coerce 'AnnotationValue',
    from HashRef, via { 'Google::Cloud::Datalabeling::V1beta1::Annotation::AnnotationValue'->new($_) };

declare 'RepeatedAnnotationValue',
    as ArrayRef[AnnotationValue()];

coerce 'RepeatedAnnotationValue',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datalabeling::V1beta1::Annotation::AnnotationValue'->new($_) } @$_ ] };

declare 'MapStringAnnotationValue',
    as HashRef[AnnotationValue()];

declare 'ImageClassificationAnnotation',
    as InstanceOf['Google::Cloud::Datalabeling::V1beta1::Annotation::ImageClassificationAnnotation'];

coerce 'ImageClassificationAnnotation',
    from HashRef, via { 'Google::Cloud::Datalabeling::V1beta1::Annotation::ImageClassificationAnnotation'->new($_) };

declare 'RepeatedImageClassificationAnnotation',
    as ArrayRef[ImageClassificationAnnotation()];

coerce 'RepeatedImageClassificationAnnotation',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datalabeling::V1beta1::Annotation::ImageClassificationAnnotation'->new($_) } @$_ ] };

declare 'MapStringImageClassificationAnnotation',
    as HashRef[ImageClassificationAnnotation()];

declare 'Vertex',
    as InstanceOf['Google::Cloud::Datalabeling::V1beta1::Annotation::Vertex'];

coerce 'Vertex',
    from HashRef, via { 'Google::Cloud::Datalabeling::V1beta1::Annotation::Vertex'->new($_) };

declare 'RepeatedVertex',
    as ArrayRef[Vertex()];

coerce 'RepeatedVertex',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datalabeling::V1beta1::Annotation::Vertex'->new($_) } @$_ ] };

declare 'MapStringVertex',
    as HashRef[Vertex()];

declare 'NormalizedVertex',
    as InstanceOf['Google::Cloud::Datalabeling::V1beta1::Annotation::NormalizedVertex'];

coerce 'NormalizedVertex',
    from HashRef, via { 'Google::Cloud::Datalabeling::V1beta1::Annotation::NormalizedVertex'->new($_) };

declare 'RepeatedNormalizedVertex',
    as ArrayRef[NormalizedVertex()];

coerce 'RepeatedNormalizedVertex',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datalabeling::V1beta1::Annotation::NormalizedVertex'->new($_) } @$_ ] };

declare 'MapStringNormalizedVertex',
    as HashRef[NormalizedVertex()];

declare 'BoundingPoly',
    as InstanceOf['Google::Cloud::Datalabeling::V1beta1::Annotation::BoundingPoly'];

coerce 'BoundingPoly',
    from HashRef, via { 'Google::Cloud::Datalabeling::V1beta1::Annotation::BoundingPoly'->new($_) };

declare 'RepeatedBoundingPoly',
    as ArrayRef[BoundingPoly()];

coerce 'RepeatedBoundingPoly',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datalabeling::V1beta1::Annotation::BoundingPoly'->new($_) } @$_ ] };

declare 'MapStringBoundingPoly',
    as HashRef[BoundingPoly()];

declare 'NormalizedBoundingPoly',
    as InstanceOf['Google::Cloud::Datalabeling::V1beta1::Annotation::NormalizedBoundingPoly'];

coerce 'NormalizedBoundingPoly',
    from HashRef, via { 'Google::Cloud::Datalabeling::V1beta1::Annotation::NormalizedBoundingPoly'->new($_) };

declare 'RepeatedNormalizedBoundingPoly',
    as ArrayRef[NormalizedBoundingPoly()];

coerce 'RepeatedNormalizedBoundingPoly',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datalabeling::V1beta1::Annotation::NormalizedBoundingPoly'->new($_) } @$_ ] };

declare 'MapStringNormalizedBoundingPoly',
    as HashRef[NormalizedBoundingPoly()];

declare 'ImageBoundingPolyAnnotation',
    as InstanceOf['Google::Cloud::Datalabeling::V1beta1::Annotation::ImageBoundingPolyAnnotation'];

coerce 'ImageBoundingPolyAnnotation',
    from HashRef, via { 'Google::Cloud::Datalabeling::V1beta1::Annotation::ImageBoundingPolyAnnotation'->new($_) };

declare 'RepeatedImageBoundingPolyAnnotation',
    as ArrayRef[ImageBoundingPolyAnnotation()];

coerce 'RepeatedImageBoundingPolyAnnotation',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datalabeling::V1beta1::Annotation::ImageBoundingPolyAnnotation'->new($_) } @$_ ] };

declare 'MapStringImageBoundingPolyAnnotation',
    as HashRef[ImageBoundingPolyAnnotation()];

declare 'Polyline',
    as InstanceOf['Google::Cloud::Datalabeling::V1beta1::Annotation::Polyline'];

coerce 'Polyline',
    from HashRef, via { 'Google::Cloud::Datalabeling::V1beta1::Annotation::Polyline'->new($_) };

declare 'RepeatedPolyline',
    as ArrayRef[Polyline()];

coerce 'RepeatedPolyline',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datalabeling::V1beta1::Annotation::Polyline'->new($_) } @$_ ] };

declare 'MapStringPolyline',
    as HashRef[Polyline()];

declare 'NormalizedPolyline',
    as InstanceOf['Google::Cloud::Datalabeling::V1beta1::Annotation::NormalizedPolyline'];

coerce 'NormalizedPolyline',
    from HashRef, via { 'Google::Cloud::Datalabeling::V1beta1::Annotation::NormalizedPolyline'->new($_) };

declare 'RepeatedNormalizedPolyline',
    as ArrayRef[NormalizedPolyline()];

coerce 'RepeatedNormalizedPolyline',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datalabeling::V1beta1::Annotation::NormalizedPolyline'->new($_) } @$_ ] };

declare 'MapStringNormalizedPolyline',
    as HashRef[NormalizedPolyline()];

declare 'ImagePolylineAnnotation',
    as InstanceOf['Google::Cloud::Datalabeling::V1beta1::Annotation::ImagePolylineAnnotation'];

coerce 'ImagePolylineAnnotation',
    from HashRef, via { 'Google::Cloud::Datalabeling::V1beta1::Annotation::ImagePolylineAnnotation'->new($_) };

declare 'RepeatedImagePolylineAnnotation',
    as ArrayRef[ImagePolylineAnnotation()];

coerce 'RepeatedImagePolylineAnnotation',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datalabeling::V1beta1::Annotation::ImagePolylineAnnotation'->new($_) } @$_ ] };

declare 'MapStringImagePolylineAnnotation',
    as HashRef[ImagePolylineAnnotation()];

declare 'ImageSegmentationAnnotation',
    as InstanceOf['Google::Cloud::Datalabeling::V1beta1::Annotation::ImageSegmentationAnnotation'];

coerce 'ImageSegmentationAnnotation',
    from HashRef, via { 'Google::Cloud::Datalabeling::V1beta1::Annotation::ImageSegmentationAnnotation'->new($_) };

declare 'RepeatedImageSegmentationAnnotation',
    as ArrayRef[ImageSegmentationAnnotation()];

coerce 'RepeatedImageSegmentationAnnotation',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datalabeling::V1beta1::Annotation::ImageSegmentationAnnotation'->new($_) } @$_ ] };

declare 'MapStringImageSegmentationAnnotation',
    as HashRef[ImageSegmentationAnnotation()];

declare 'AnnotationColorsEntry',
    as InstanceOf['Google::Cloud::Datalabeling::V1beta1::Annotation::ImageSegmentationAnnotation::AnnotationColorsEntry'];

coerce 'AnnotationColorsEntry',
    from HashRef, via { 'Google::Cloud::Datalabeling::V1beta1::Annotation::ImageSegmentationAnnotation::AnnotationColorsEntry'->new($_) };

declare 'RepeatedAnnotationColorsEntry',
    as ArrayRef[AnnotationColorsEntry()];

coerce 'RepeatedAnnotationColorsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datalabeling::V1beta1::Annotation::ImageSegmentationAnnotation::AnnotationColorsEntry'->new($_) } @$_ ] };

declare 'MapStringAnnotationColorsEntry',
    as HashRef[AnnotationColorsEntry()];

declare 'TextClassificationAnnotation',
    as InstanceOf['Google::Cloud::Datalabeling::V1beta1::Annotation::TextClassificationAnnotation'];

coerce 'TextClassificationAnnotation',
    from HashRef, via { 'Google::Cloud::Datalabeling::V1beta1::Annotation::TextClassificationAnnotation'->new($_) };

declare 'RepeatedTextClassificationAnnotation',
    as ArrayRef[TextClassificationAnnotation()];

coerce 'RepeatedTextClassificationAnnotation',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datalabeling::V1beta1::Annotation::TextClassificationAnnotation'->new($_) } @$_ ] };

declare 'MapStringTextClassificationAnnotation',
    as HashRef[TextClassificationAnnotation()];

declare 'TextEntityExtractionAnnotation',
    as InstanceOf['Google::Cloud::Datalabeling::V1beta1::Annotation::TextEntityExtractionAnnotation'];

coerce 'TextEntityExtractionAnnotation',
    from HashRef, via { 'Google::Cloud::Datalabeling::V1beta1::Annotation::TextEntityExtractionAnnotation'->new($_) };

declare 'RepeatedTextEntityExtractionAnnotation',
    as ArrayRef[TextEntityExtractionAnnotation()];

coerce 'RepeatedTextEntityExtractionAnnotation',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datalabeling::V1beta1::Annotation::TextEntityExtractionAnnotation'->new($_) } @$_ ] };

declare 'MapStringTextEntityExtractionAnnotation',
    as HashRef[TextEntityExtractionAnnotation()];

declare 'SequentialSegment',
    as InstanceOf['Google::Cloud::Datalabeling::V1beta1::Annotation::SequentialSegment'];

coerce 'SequentialSegment',
    from HashRef, via { 'Google::Cloud::Datalabeling::V1beta1::Annotation::SequentialSegment'->new($_) };

declare 'RepeatedSequentialSegment',
    as ArrayRef[SequentialSegment()];

coerce 'RepeatedSequentialSegment',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datalabeling::V1beta1::Annotation::SequentialSegment'->new($_) } @$_ ] };

declare 'MapStringSequentialSegment',
    as HashRef[SequentialSegment()];

declare 'TimeSegment',
    as InstanceOf['Google::Cloud::Datalabeling::V1beta1::Annotation::TimeSegment'];

coerce 'TimeSegment',
    from HashRef, via { 'Google::Cloud::Datalabeling::V1beta1::Annotation::TimeSegment'->new($_) };

declare 'RepeatedTimeSegment',
    as ArrayRef[TimeSegment()];

coerce 'RepeatedTimeSegment',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datalabeling::V1beta1::Annotation::TimeSegment'->new($_) } @$_ ] };

declare 'MapStringTimeSegment',
    as HashRef[TimeSegment()];

declare 'VideoClassificationAnnotation',
    as InstanceOf['Google::Cloud::Datalabeling::V1beta1::Annotation::VideoClassificationAnnotation'];

coerce 'VideoClassificationAnnotation',
    from HashRef, via { 'Google::Cloud::Datalabeling::V1beta1::Annotation::VideoClassificationAnnotation'->new($_) };

declare 'RepeatedVideoClassificationAnnotation',
    as ArrayRef[VideoClassificationAnnotation()];

coerce 'RepeatedVideoClassificationAnnotation',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datalabeling::V1beta1::Annotation::VideoClassificationAnnotation'->new($_) } @$_ ] };

declare 'MapStringVideoClassificationAnnotation',
    as HashRef[VideoClassificationAnnotation()];

declare 'ObjectTrackingFrame',
    as InstanceOf['Google::Cloud::Datalabeling::V1beta1::Annotation::ObjectTrackingFrame'];

coerce 'ObjectTrackingFrame',
    from HashRef, via { 'Google::Cloud::Datalabeling::V1beta1::Annotation::ObjectTrackingFrame'->new($_) };

declare 'RepeatedObjectTrackingFrame',
    as ArrayRef[ObjectTrackingFrame()];

coerce 'RepeatedObjectTrackingFrame',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datalabeling::V1beta1::Annotation::ObjectTrackingFrame'->new($_) } @$_ ] };

declare 'MapStringObjectTrackingFrame',
    as HashRef[ObjectTrackingFrame()];

declare 'VideoObjectTrackingAnnotation',
    as InstanceOf['Google::Cloud::Datalabeling::V1beta1::Annotation::VideoObjectTrackingAnnotation'];

coerce 'VideoObjectTrackingAnnotation',
    from HashRef, via { 'Google::Cloud::Datalabeling::V1beta1::Annotation::VideoObjectTrackingAnnotation'->new($_) };

declare 'RepeatedVideoObjectTrackingAnnotation',
    as ArrayRef[VideoObjectTrackingAnnotation()];

coerce 'RepeatedVideoObjectTrackingAnnotation',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datalabeling::V1beta1::Annotation::VideoObjectTrackingAnnotation'->new($_) } @$_ ] };

declare 'MapStringVideoObjectTrackingAnnotation',
    as HashRef[VideoObjectTrackingAnnotation()];

declare 'VideoEventAnnotation',
    as InstanceOf['Google::Cloud::Datalabeling::V1beta1::Annotation::VideoEventAnnotation'];

coerce 'VideoEventAnnotation',
    from HashRef, via { 'Google::Cloud::Datalabeling::V1beta1::Annotation::VideoEventAnnotation'->new($_) };

declare 'RepeatedVideoEventAnnotation',
    as ArrayRef[VideoEventAnnotation()];

coerce 'RepeatedVideoEventAnnotation',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datalabeling::V1beta1::Annotation::VideoEventAnnotation'->new($_) } @$_ ] };

declare 'MapStringVideoEventAnnotation',
    as HashRef[VideoEventAnnotation()];

declare 'AnnotationMetadata',
    as InstanceOf['Google::Cloud::Datalabeling::V1beta1::Annotation::AnnotationMetadata'];

coerce 'AnnotationMetadata',
    from HashRef, via { 'Google::Cloud::Datalabeling::V1beta1::Annotation::AnnotationMetadata'->new($_) };

declare 'RepeatedAnnotationMetadata',
    as ArrayRef[AnnotationMetadata()];

coerce 'RepeatedAnnotationMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datalabeling::V1beta1::Annotation::AnnotationMetadata'->new($_) } @$_ ] };

declare 'MapStringAnnotationMetadata',
    as HashRef[AnnotationMetadata()];

declare 'OperatorMetadata',
    as InstanceOf['Google::Cloud::Datalabeling::V1beta1::Annotation::OperatorMetadata'];

coerce 'OperatorMetadata',
    from HashRef, via { 'Google::Cloud::Datalabeling::V1beta1::Annotation::OperatorMetadata'->new($_) };

declare 'RepeatedOperatorMetadata',
    as ArrayRef[OperatorMetadata()];

coerce 'RepeatedOperatorMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datalabeling::V1beta1::Annotation::OperatorMetadata'->new($_) } @$_ ] };

declare 'MapStringOperatorMetadata',
    as HashRef[OperatorMetadata()];

1;

__END__

=head1 NAME

Google::Cloud::Datalabeling::V1beta1::Annotation::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
