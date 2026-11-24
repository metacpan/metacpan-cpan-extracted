package Google::Cloud::Datalabeling::V1beta1::Evaluation::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Evaluation',
    as InstanceOf['Google::Cloud::Datalabeling::V1beta1::Evaluation::Evaluation'];

coerce 'Evaluation',
    from HashRef, via { 'Google::Cloud::Datalabeling::V1beta1::Evaluation::Evaluation'->new($_) };

declare 'RepeatedEvaluation',
    as ArrayRef[Evaluation()];

coerce 'RepeatedEvaluation',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datalabeling::V1beta1::Evaluation::Evaluation'->new($_) } @$_ ] };

declare 'MapStringEvaluation',
    as HashRef[Evaluation()];

declare 'EvaluationConfig',
    as InstanceOf['Google::Cloud::Datalabeling::V1beta1::Evaluation::EvaluationConfig'];

coerce 'EvaluationConfig',
    from HashRef, via { 'Google::Cloud::Datalabeling::V1beta1::Evaluation::EvaluationConfig'->new($_) };

declare 'RepeatedEvaluationConfig',
    as ArrayRef[EvaluationConfig()];

coerce 'RepeatedEvaluationConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datalabeling::V1beta1::Evaluation::EvaluationConfig'->new($_) } @$_ ] };

declare 'MapStringEvaluationConfig',
    as HashRef[EvaluationConfig()];

declare 'BoundingBoxEvaluationOptions',
    as InstanceOf['Google::Cloud::Datalabeling::V1beta1::Evaluation::BoundingBoxEvaluationOptions'];

coerce 'BoundingBoxEvaluationOptions',
    from HashRef, via { 'Google::Cloud::Datalabeling::V1beta1::Evaluation::BoundingBoxEvaluationOptions'->new($_) };

declare 'RepeatedBoundingBoxEvaluationOptions',
    as ArrayRef[BoundingBoxEvaluationOptions()];

coerce 'RepeatedBoundingBoxEvaluationOptions',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datalabeling::V1beta1::Evaluation::BoundingBoxEvaluationOptions'->new($_) } @$_ ] };

declare 'MapStringBoundingBoxEvaluationOptions',
    as HashRef[BoundingBoxEvaluationOptions()];

declare 'EvaluationMetrics',
    as InstanceOf['Google::Cloud::Datalabeling::V1beta1::Evaluation::EvaluationMetrics'];

coerce 'EvaluationMetrics',
    from HashRef, via { 'Google::Cloud::Datalabeling::V1beta1::Evaluation::EvaluationMetrics'->new($_) };

declare 'RepeatedEvaluationMetrics',
    as ArrayRef[EvaluationMetrics()];

coerce 'RepeatedEvaluationMetrics',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datalabeling::V1beta1::Evaluation::EvaluationMetrics'->new($_) } @$_ ] };

declare 'MapStringEvaluationMetrics',
    as HashRef[EvaluationMetrics()];

declare 'ClassificationMetrics',
    as InstanceOf['Google::Cloud::Datalabeling::V1beta1::Evaluation::ClassificationMetrics'];

coerce 'ClassificationMetrics',
    from HashRef, via { 'Google::Cloud::Datalabeling::V1beta1::Evaluation::ClassificationMetrics'->new($_) };

declare 'RepeatedClassificationMetrics',
    as ArrayRef[ClassificationMetrics()];

coerce 'RepeatedClassificationMetrics',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datalabeling::V1beta1::Evaluation::ClassificationMetrics'->new($_) } @$_ ] };

declare 'MapStringClassificationMetrics',
    as HashRef[ClassificationMetrics()];

declare 'ObjectDetectionMetrics',
    as InstanceOf['Google::Cloud::Datalabeling::V1beta1::Evaluation::ObjectDetectionMetrics'];

coerce 'ObjectDetectionMetrics',
    from HashRef, via { 'Google::Cloud::Datalabeling::V1beta1::Evaluation::ObjectDetectionMetrics'->new($_) };

declare 'RepeatedObjectDetectionMetrics',
    as ArrayRef[ObjectDetectionMetrics()];

coerce 'RepeatedObjectDetectionMetrics',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datalabeling::V1beta1::Evaluation::ObjectDetectionMetrics'->new($_) } @$_ ] };

declare 'MapStringObjectDetectionMetrics',
    as HashRef[ObjectDetectionMetrics()];

declare 'PrCurve',
    as InstanceOf['Google::Cloud::Datalabeling::V1beta1::Evaluation::PrCurve'];

coerce 'PrCurve',
    from HashRef, via { 'Google::Cloud::Datalabeling::V1beta1::Evaluation::PrCurve'->new($_) };

declare 'RepeatedPrCurve',
    as ArrayRef[PrCurve()];

coerce 'RepeatedPrCurve',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datalabeling::V1beta1::Evaluation::PrCurve'->new($_) } @$_ ] };

declare 'MapStringPrCurve',
    as HashRef[PrCurve()];

declare 'ConfidenceMetricsEntry',
    as InstanceOf['Google::Cloud::Datalabeling::V1beta1::Evaluation::PrCurve::ConfidenceMetricsEntry'];

coerce 'ConfidenceMetricsEntry',
    from HashRef, via { 'Google::Cloud::Datalabeling::V1beta1::Evaluation::PrCurve::ConfidenceMetricsEntry'->new($_) };

declare 'RepeatedConfidenceMetricsEntry',
    as ArrayRef[ConfidenceMetricsEntry()];

coerce 'RepeatedConfidenceMetricsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datalabeling::V1beta1::Evaluation::PrCurve::ConfidenceMetricsEntry'->new($_) } @$_ ] };

declare 'MapStringConfidenceMetricsEntry',
    as HashRef[ConfidenceMetricsEntry()];

declare 'ConfusionMatrix',
    as InstanceOf['Google::Cloud::Datalabeling::V1beta1::Evaluation::ConfusionMatrix'];

coerce 'ConfusionMatrix',
    from HashRef, via { 'Google::Cloud::Datalabeling::V1beta1::Evaluation::ConfusionMatrix'->new($_) };

declare 'RepeatedConfusionMatrix',
    as ArrayRef[ConfusionMatrix()];

coerce 'RepeatedConfusionMatrix',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datalabeling::V1beta1::Evaluation::ConfusionMatrix'->new($_) } @$_ ] };

declare 'MapStringConfusionMatrix',
    as HashRef[ConfusionMatrix()];

declare 'ConfusionMatrixEntry',
    as InstanceOf['Google::Cloud::Datalabeling::V1beta1::Evaluation::ConfusionMatrix::ConfusionMatrixEntry'];

coerce 'ConfusionMatrixEntry',
    from HashRef, via { 'Google::Cloud::Datalabeling::V1beta1::Evaluation::ConfusionMatrix::ConfusionMatrixEntry'->new($_) };

declare 'RepeatedConfusionMatrixEntry',
    as ArrayRef[ConfusionMatrixEntry()];

coerce 'RepeatedConfusionMatrixEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datalabeling::V1beta1::Evaluation::ConfusionMatrix::ConfusionMatrixEntry'->new($_) } @$_ ] };

declare 'MapStringConfusionMatrixEntry',
    as HashRef[ConfusionMatrixEntry()];

declare 'Row',
    as InstanceOf['Google::Cloud::Datalabeling::V1beta1::Evaluation::ConfusionMatrix::Row'];

coerce 'Row',
    from HashRef, via { 'Google::Cloud::Datalabeling::V1beta1::Evaluation::ConfusionMatrix::Row'->new($_) };

declare 'RepeatedRow',
    as ArrayRef[Row()];

coerce 'RepeatedRow',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datalabeling::V1beta1::Evaluation::ConfusionMatrix::Row'->new($_) } @$_ ] };

declare 'MapStringRow',
    as HashRef[Row()];

1;

__END__

=head1 NAME

Google::Cloud::Datalabeling::V1beta1::Evaluation::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
