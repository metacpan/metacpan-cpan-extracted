package Google::Cloud::Automl::V1beta1::TextSentiment::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'TextSentimentAnnotation',
    as InstanceOf['Google::Cloud::Automl::V1beta1::TextSentiment::TextSentimentAnnotation'];

coerce 'TextSentimentAnnotation',
    from HashRef, via { 'Google::Cloud::Automl::V1beta1::TextSentiment::TextSentimentAnnotation'->new($_) };

declare 'RepeatedTextSentimentAnnotation',
    as ArrayRef[TextSentimentAnnotation()];

coerce 'RepeatedTextSentimentAnnotation',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Automl::V1beta1::TextSentiment::TextSentimentAnnotation'->new($_) } @$_ ] };

declare 'MapStringTextSentimentAnnotation',
    as HashRef[TextSentimentAnnotation()];

declare 'TextSentimentEvaluationMetrics',
    as InstanceOf['Google::Cloud::Automl::V1beta1::TextSentiment::TextSentimentEvaluationMetrics'];

coerce 'TextSentimentEvaluationMetrics',
    from HashRef, via { 'Google::Cloud::Automl::V1beta1::TextSentiment::TextSentimentEvaluationMetrics'->new($_) };

declare 'RepeatedTextSentimentEvaluationMetrics',
    as ArrayRef[TextSentimentEvaluationMetrics()];

coerce 'RepeatedTextSentimentEvaluationMetrics',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Automl::V1beta1::TextSentiment::TextSentimentEvaluationMetrics'->new($_) } @$_ ] };

declare 'MapStringTextSentimentEvaluationMetrics',
    as HashRef[TextSentimentEvaluationMetrics()];

1;

__END__

=head1 NAME

Google::Cloud::Automl::V1beta1::TextSentiment::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
