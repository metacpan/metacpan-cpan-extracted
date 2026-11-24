package Google::Cloud::Automl::V1beta1::Detection::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'ImageObjectDetectionAnnotation',
    as InstanceOf['Google::Cloud::Automl::V1beta1::Detection::ImageObjectDetectionAnnotation'];

coerce 'ImageObjectDetectionAnnotation',
    from HashRef, via { 'Google::Cloud::Automl::V1beta1::Detection::ImageObjectDetectionAnnotation'->new($_) };

declare 'RepeatedImageObjectDetectionAnnotation',
    as ArrayRef[ImageObjectDetectionAnnotation()];

coerce 'RepeatedImageObjectDetectionAnnotation',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Automl::V1beta1::Detection::ImageObjectDetectionAnnotation'->new($_) } @$_ ] };

declare 'MapStringImageObjectDetectionAnnotation',
    as HashRef[ImageObjectDetectionAnnotation()];

declare 'VideoObjectTrackingAnnotation',
    as InstanceOf['Google::Cloud::Automl::V1beta1::Detection::VideoObjectTrackingAnnotation'];

coerce 'VideoObjectTrackingAnnotation',
    from HashRef, via { 'Google::Cloud::Automl::V1beta1::Detection::VideoObjectTrackingAnnotation'->new($_) };

declare 'RepeatedVideoObjectTrackingAnnotation',
    as ArrayRef[VideoObjectTrackingAnnotation()];

coerce 'RepeatedVideoObjectTrackingAnnotation',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Automl::V1beta1::Detection::VideoObjectTrackingAnnotation'->new($_) } @$_ ] };

declare 'MapStringVideoObjectTrackingAnnotation',
    as HashRef[VideoObjectTrackingAnnotation()];

declare 'BoundingBoxMetricsEntry',
    as InstanceOf['Google::Cloud::Automl::V1beta1::Detection::BoundingBoxMetricsEntry'];

coerce 'BoundingBoxMetricsEntry',
    from HashRef, via { 'Google::Cloud::Automl::V1beta1::Detection::BoundingBoxMetricsEntry'->new($_) };

declare 'RepeatedBoundingBoxMetricsEntry',
    as ArrayRef[BoundingBoxMetricsEntry()];

coerce 'RepeatedBoundingBoxMetricsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Automl::V1beta1::Detection::BoundingBoxMetricsEntry'->new($_) } @$_ ] };

declare 'MapStringBoundingBoxMetricsEntry',
    as HashRef[BoundingBoxMetricsEntry()];

declare 'ConfidenceMetricsEntry',
    as InstanceOf['Google::Cloud::Automl::V1beta1::Detection::BoundingBoxMetricsEntry::ConfidenceMetricsEntry'];

coerce 'ConfidenceMetricsEntry',
    from HashRef, via { 'Google::Cloud::Automl::V1beta1::Detection::BoundingBoxMetricsEntry::ConfidenceMetricsEntry'->new($_) };

declare 'RepeatedConfidenceMetricsEntry',
    as ArrayRef[ConfidenceMetricsEntry()];

coerce 'RepeatedConfidenceMetricsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Automl::V1beta1::Detection::BoundingBoxMetricsEntry::ConfidenceMetricsEntry'->new($_) } @$_ ] };

declare 'MapStringConfidenceMetricsEntry',
    as HashRef[ConfidenceMetricsEntry()];

declare 'ImageObjectDetectionEvaluationMetrics',
    as InstanceOf['Google::Cloud::Automl::V1beta1::Detection::ImageObjectDetectionEvaluationMetrics'];

coerce 'ImageObjectDetectionEvaluationMetrics',
    from HashRef, via { 'Google::Cloud::Automl::V1beta1::Detection::ImageObjectDetectionEvaluationMetrics'->new($_) };

declare 'RepeatedImageObjectDetectionEvaluationMetrics',
    as ArrayRef[ImageObjectDetectionEvaluationMetrics()];

coerce 'RepeatedImageObjectDetectionEvaluationMetrics',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Automl::V1beta1::Detection::ImageObjectDetectionEvaluationMetrics'->new($_) } @$_ ] };

declare 'MapStringImageObjectDetectionEvaluationMetrics',
    as HashRef[ImageObjectDetectionEvaluationMetrics()];

declare 'VideoObjectTrackingEvaluationMetrics',
    as InstanceOf['Google::Cloud::Automl::V1beta1::Detection::VideoObjectTrackingEvaluationMetrics'];

coerce 'VideoObjectTrackingEvaluationMetrics',
    from HashRef, via { 'Google::Cloud::Automl::V1beta1::Detection::VideoObjectTrackingEvaluationMetrics'->new($_) };

declare 'RepeatedVideoObjectTrackingEvaluationMetrics',
    as ArrayRef[VideoObjectTrackingEvaluationMetrics()];

coerce 'RepeatedVideoObjectTrackingEvaluationMetrics',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Automl::V1beta1::Detection::VideoObjectTrackingEvaluationMetrics'->new($_) } @$_ ] };

declare 'MapStringVideoObjectTrackingEvaluationMetrics',
    as HashRef[VideoObjectTrackingEvaluationMetrics()];

1;

__END__

=head1 NAME

Google::Cloud::Automl::V1beta1::Detection::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
