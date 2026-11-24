package Google::Cloud::Automl::V1beta1::Regression::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'RegressionEvaluationMetrics',
    as InstanceOf['Google::Cloud::Automl::V1beta1::Regression::RegressionEvaluationMetrics'];

coerce 'RegressionEvaluationMetrics',
    from HashRef, via { 'Google::Cloud::Automl::V1beta1::Regression::RegressionEvaluationMetrics'->new($_) };

declare 'RepeatedRegressionEvaluationMetrics',
    as ArrayRef[RegressionEvaluationMetrics()];

coerce 'RepeatedRegressionEvaluationMetrics',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Automl::V1beta1::Regression::RegressionEvaluationMetrics'->new($_) } @$_ ] };

declare 'MapStringRegressionEvaluationMetrics',
    as HashRef[RegressionEvaluationMetrics()];

1;

__END__

=head1 NAME

Google::Cloud::Automl::V1beta1::Regression::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
