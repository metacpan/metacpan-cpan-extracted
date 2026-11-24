package Google::Cloud::Documentai::V1::Evaluation::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'EvaluationReference',
    as InstanceOf['Google::Cloud::Documentai::V1::Evaluation::EvaluationReference'];

coerce 'EvaluationReference',
    from HashRef, via { 'Google::Cloud::Documentai::V1::Evaluation::EvaluationReference'->new($_) };

declare 'RepeatedEvaluationReference',
    as ArrayRef[EvaluationReference()];

coerce 'RepeatedEvaluationReference',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Documentai::V1::Evaluation::EvaluationReference'->new($_) } @$_ ] };

declare 'MapStringEvaluationReference',
    as HashRef[EvaluationReference()];

declare 'Evaluation',
    as InstanceOf['Google::Cloud::Documentai::V1::Evaluation::Evaluation'];

coerce 'Evaluation',
    from HashRef, via { 'Google::Cloud::Documentai::V1::Evaluation::Evaluation'->new($_) };

declare 'RepeatedEvaluation',
    as ArrayRef[Evaluation()];

coerce 'RepeatedEvaluation',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Documentai::V1::Evaluation::Evaluation'->new($_) } @$_ ] };

declare 'MapStringEvaluation',
    as HashRef[Evaluation()];

declare 'Counters',
    as InstanceOf['Google::Cloud::Documentai::V1::Evaluation::Evaluation::Counters'];

coerce 'Counters',
    from HashRef, via { 'Google::Cloud::Documentai::V1::Evaluation::Evaluation::Counters'->new($_) };

declare 'RepeatedCounters',
    as ArrayRef[Counters()];

coerce 'RepeatedCounters',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Documentai::V1::Evaluation::Evaluation::Counters'->new($_) } @$_ ] };

declare 'MapStringCounters',
    as HashRef[Counters()];

declare 'Metrics',
    as InstanceOf['Google::Cloud::Documentai::V1::Evaluation::Evaluation::Metrics'];

coerce 'Metrics',
    from HashRef, via { 'Google::Cloud::Documentai::V1::Evaluation::Evaluation::Metrics'->new($_) };

declare 'RepeatedMetrics',
    as ArrayRef[Metrics()];

coerce 'RepeatedMetrics',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Documentai::V1::Evaluation::Evaluation::Metrics'->new($_) } @$_ ] };

declare 'MapStringMetrics',
    as HashRef[Metrics()];

declare 'ConfidenceLevelMetrics',
    as InstanceOf['Google::Cloud::Documentai::V1::Evaluation::Evaluation::ConfidenceLevelMetrics'];

coerce 'ConfidenceLevelMetrics',
    from HashRef, via { 'Google::Cloud::Documentai::V1::Evaluation::Evaluation::ConfidenceLevelMetrics'->new($_) };

declare 'RepeatedConfidenceLevelMetrics',
    as ArrayRef[ConfidenceLevelMetrics()];

coerce 'RepeatedConfidenceLevelMetrics',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Documentai::V1::Evaluation::Evaluation::ConfidenceLevelMetrics'->new($_) } @$_ ] };

declare 'MapStringConfidenceLevelMetrics',
    as HashRef[ConfidenceLevelMetrics()];

declare 'MultiConfidenceMetrics',
    as InstanceOf['Google::Cloud::Documentai::V1::Evaluation::Evaluation::MultiConfidenceMetrics'];

coerce 'MultiConfidenceMetrics',
    from HashRef, via { 'Google::Cloud::Documentai::V1::Evaluation::Evaluation::MultiConfidenceMetrics'->new($_) };

declare 'RepeatedMultiConfidenceMetrics',
    as ArrayRef[MultiConfidenceMetrics()];

coerce 'RepeatedMultiConfidenceMetrics',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Documentai::V1::Evaluation::Evaluation::MultiConfidenceMetrics'->new($_) } @$_ ] };

declare 'MapStringMultiConfidenceMetrics',
    as HashRef[MultiConfidenceMetrics()];

declare 'MetricsType',
    as (Int | Str);

declare 'EntityMetricsEntry',
    as InstanceOf['Google::Cloud::Documentai::V1::Evaluation::Evaluation::EntityMetricsEntry'];

coerce 'EntityMetricsEntry',
    from HashRef, via { 'Google::Cloud::Documentai::V1::Evaluation::Evaluation::EntityMetricsEntry'->new($_) };

declare 'RepeatedEntityMetricsEntry',
    as ArrayRef[EntityMetricsEntry()];

coerce 'RepeatedEntityMetricsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Documentai::V1::Evaluation::Evaluation::EntityMetricsEntry'->new($_) } @$_ ] };

declare 'MapStringEntityMetricsEntry',
    as HashRef[EntityMetricsEntry()];

1;

__END__

=head1 NAME

Google::Cloud::Documentai::V1::Evaluation::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
