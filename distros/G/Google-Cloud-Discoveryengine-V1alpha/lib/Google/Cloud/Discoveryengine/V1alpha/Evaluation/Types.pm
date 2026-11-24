package Google::Cloud::Discoveryengine::V1alpha::Evaluation::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Evaluation',
    as InstanceOf['Google::Cloud::Discoveryengine::V1alpha::Evaluation::Evaluation'];

coerce 'Evaluation',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1alpha::Evaluation::Evaluation'->new($_) };

declare 'RepeatedEvaluation',
    as ArrayRef[Evaluation()];

coerce 'RepeatedEvaluation',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1alpha::Evaluation::Evaluation'->new($_) } @$_ ] };

declare 'MapStringEvaluation',
    as HashRef[Evaluation()];

declare 'State',
    as (Int | Str);

declare 'EvaluationSpec',
    as InstanceOf['Google::Cloud::Discoveryengine::V1alpha::Evaluation::Evaluation::EvaluationSpec'];

coerce 'EvaluationSpec',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1alpha::Evaluation::Evaluation::EvaluationSpec'->new($_) };

declare 'RepeatedEvaluationSpec',
    as ArrayRef[EvaluationSpec()];

coerce 'RepeatedEvaluationSpec',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1alpha::Evaluation::Evaluation::EvaluationSpec'->new($_) } @$_ ] };

declare 'MapStringEvaluationSpec',
    as HashRef[EvaluationSpec()];

declare 'QuerySetSpec',
    as InstanceOf['Google::Cloud::Discoveryengine::V1alpha::Evaluation::Evaluation::EvaluationSpec::QuerySetSpec'];

coerce 'QuerySetSpec',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1alpha::Evaluation::Evaluation::EvaluationSpec::QuerySetSpec'->new($_) };

declare 'RepeatedQuerySetSpec',
    as ArrayRef[QuerySetSpec()];

coerce 'RepeatedQuerySetSpec',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1alpha::Evaluation::Evaluation::EvaluationSpec::QuerySetSpec'->new($_) } @$_ ] };

declare 'MapStringQuerySetSpec',
    as HashRef[QuerySetSpec()];

declare 'QualityMetrics',
    as InstanceOf['Google::Cloud::Discoveryengine::V1alpha::Evaluation::QualityMetrics'];

coerce 'QualityMetrics',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1alpha::Evaluation::QualityMetrics'->new($_) };

declare 'RepeatedQualityMetrics',
    as ArrayRef[QualityMetrics()];

coerce 'RepeatedQualityMetrics',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1alpha::Evaluation::QualityMetrics'->new($_) } @$_ ] };

declare 'MapStringQualityMetrics',
    as HashRef[QualityMetrics()];

declare 'TopkMetrics',
    as InstanceOf['Google::Cloud::Discoveryengine::V1alpha::Evaluation::QualityMetrics::TopkMetrics'];

coerce 'TopkMetrics',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1alpha::Evaluation::QualityMetrics::TopkMetrics'->new($_) };

declare 'RepeatedTopkMetrics',
    as ArrayRef[TopkMetrics()];

coerce 'RepeatedTopkMetrics',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1alpha::Evaluation::QualityMetrics::TopkMetrics'->new($_) } @$_ ] };

declare 'MapStringTopkMetrics',
    as HashRef[TopkMetrics()];

1;

__END__

=head1 NAME

Google::Cloud::Discoveryengine::V1alpha::Evaluation::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
