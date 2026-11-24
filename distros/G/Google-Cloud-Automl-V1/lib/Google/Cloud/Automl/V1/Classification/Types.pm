package Google::Cloud::Automl::V1::Classification::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'ClassificationType',
    as (Int | Str);

declare 'ClassificationAnnotation',
    as InstanceOf['Google::Cloud::Automl::V1::Classification::ClassificationAnnotation'];

coerce 'ClassificationAnnotation',
    from HashRef, via { 'Google::Cloud::Automl::V1::Classification::ClassificationAnnotation'->new($_) };

declare 'RepeatedClassificationAnnotation',
    as ArrayRef[ClassificationAnnotation()];

coerce 'RepeatedClassificationAnnotation',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Automl::V1::Classification::ClassificationAnnotation'->new($_) } @$_ ] };

declare 'MapStringClassificationAnnotation',
    as HashRef[ClassificationAnnotation()];

declare 'ClassificationEvaluationMetrics',
    as InstanceOf['Google::Cloud::Automl::V1::Classification::ClassificationEvaluationMetrics'];

coerce 'ClassificationEvaluationMetrics',
    from HashRef, via { 'Google::Cloud::Automl::V1::Classification::ClassificationEvaluationMetrics'->new($_) };

declare 'RepeatedClassificationEvaluationMetrics',
    as ArrayRef[ClassificationEvaluationMetrics()];

coerce 'RepeatedClassificationEvaluationMetrics',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Automl::V1::Classification::ClassificationEvaluationMetrics'->new($_) } @$_ ] };

declare 'MapStringClassificationEvaluationMetrics',
    as HashRef[ClassificationEvaluationMetrics()];

declare 'ConfidenceMetricsEntry',
    as InstanceOf['Google::Cloud::Automl::V1::Classification::ClassificationEvaluationMetrics::ConfidenceMetricsEntry'];

coerce 'ConfidenceMetricsEntry',
    from HashRef, via { 'Google::Cloud::Automl::V1::Classification::ClassificationEvaluationMetrics::ConfidenceMetricsEntry'->new($_) };

declare 'RepeatedConfidenceMetricsEntry',
    as ArrayRef[ConfidenceMetricsEntry()];

coerce 'RepeatedConfidenceMetricsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Automl::V1::Classification::ClassificationEvaluationMetrics::ConfidenceMetricsEntry'->new($_) } @$_ ] };

declare 'MapStringConfidenceMetricsEntry',
    as HashRef[ConfidenceMetricsEntry()];

declare 'ConfusionMatrix',
    as InstanceOf['Google::Cloud::Automl::V1::Classification::ClassificationEvaluationMetrics::ConfusionMatrix'];

coerce 'ConfusionMatrix',
    from HashRef, via { 'Google::Cloud::Automl::V1::Classification::ClassificationEvaluationMetrics::ConfusionMatrix'->new($_) };

declare 'RepeatedConfusionMatrix',
    as ArrayRef[ConfusionMatrix()];

coerce 'RepeatedConfusionMatrix',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Automl::V1::Classification::ClassificationEvaluationMetrics::ConfusionMatrix'->new($_) } @$_ ] };

declare 'MapStringConfusionMatrix',
    as HashRef[ConfusionMatrix()];

declare 'Row',
    as InstanceOf['Google::Cloud::Automl::V1::Classification::ClassificationEvaluationMetrics::ConfusionMatrix::Row'];

coerce 'Row',
    from HashRef, via { 'Google::Cloud::Automl::V1::Classification::ClassificationEvaluationMetrics::ConfusionMatrix::Row'->new($_) };

declare 'RepeatedRow',
    as ArrayRef[Row()];

coerce 'RepeatedRow',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Automl::V1::Classification::ClassificationEvaluationMetrics::ConfusionMatrix::Row'->new($_) } @$_ ] };

declare 'MapStringRow',
    as HashRef[Row()];

1;

__END__

=head1 NAME

Google::Cloud::Automl::V1::Classification::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
