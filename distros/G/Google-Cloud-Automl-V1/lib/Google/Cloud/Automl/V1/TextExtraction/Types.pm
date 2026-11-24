package Google::Cloud::Automl::V1::TextExtraction::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'TextExtractionAnnotation',
    as InstanceOf['Google::Cloud::Automl::V1::TextExtraction::TextExtractionAnnotation'];

coerce 'TextExtractionAnnotation',
    from HashRef, via { 'Google::Cloud::Automl::V1::TextExtraction::TextExtractionAnnotation'->new($_) };

declare 'RepeatedTextExtractionAnnotation',
    as ArrayRef[TextExtractionAnnotation()];

coerce 'RepeatedTextExtractionAnnotation',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Automl::V1::TextExtraction::TextExtractionAnnotation'->new($_) } @$_ ] };

declare 'MapStringTextExtractionAnnotation',
    as HashRef[TextExtractionAnnotation()];

declare 'TextExtractionEvaluationMetrics',
    as InstanceOf['Google::Cloud::Automl::V1::TextExtraction::TextExtractionEvaluationMetrics'];

coerce 'TextExtractionEvaluationMetrics',
    from HashRef, via { 'Google::Cloud::Automl::V1::TextExtraction::TextExtractionEvaluationMetrics'->new($_) };

declare 'RepeatedTextExtractionEvaluationMetrics',
    as ArrayRef[TextExtractionEvaluationMetrics()];

coerce 'RepeatedTextExtractionEvaluationMetrics',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Automl::V1::TextExtraction::TextExtractionEvaluationMetrics'->new($_) } @$_ ] };

declare 'MapStringTextExtractionEvaluationMetrics',
    as HashRef[TextExtractionEvaluationMetrics()];

declare 'ConfidenceMetricsEntry',
    as InstanceOf['Google::Cloud::Automl::V1::TextExtraction::TextExtractionEvaluationMetrics::ConfidenceMetricsEntry'];

coerce 'ConfidenceMetricsEntry',
    from HashRef, via { 'Google::Cloud::Automl::V1::TextExtraction::TextExtractionEvaluationMetrics::ConfidenceMetricsEntry'->new($_) };

declare 'RepeatedConfidenceMetricsEntry',
    as ArrayRef[ConfidenceMetricsEntry()];

coerce 'RepeatedConfidenceMetricsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Automl::V1::TextExtraction::TextExtractionEvaluationMetrics::ConfidenceMetricsEntry'->new($_) } @$_ ] };

declare 'MapStringConfidenceMetricsEntry',
    as HashRef[ConfidenceMetricsEntry()];

1;

__END__

=head1 NAME

Google::Cloud::Automl::V1::TextExtraction::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
