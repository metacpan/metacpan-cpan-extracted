package Google::Cloud::Automl::V1beta1::Translation::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'TranslationDatasetMetadata',
    as InstanceOf['Google::Cloud::Automl::V1beta1::Translation::TranslationDatasetMetadata'];

coerce 'TranslationDatasetMetadata',
    from HashRef, via { 'Google::Cloud::Automl::V1beta1::Translation::TranslationDatasetMetadata'->new($_) };

declare 'RepeatedTranslationDatasetMetadata',
    as ArrayRef[TranslationDatasetMetadata()];

coerce 'RepeatedTranslationDatasetMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Automl::V1beta1::Translation::TranslationDatasetMetadata'->new($_) } @$_ ] };

declare 'MapStringTranslationDatasetMetadata',
    as HashRef[TranslationDatasetMetadata()];

declare 'TranslationEvaluationMetrics',
    as InstanceOf['Google::Cloud::Automl::V1beta1::Translation::TranslationEvaluationMetrics'];

coerce 'TranslationEvaluationMetrics',
    from HashRef, via { 'Google::Cloud::Automl::V1beta1::Translation::TranslationEvaluationMetrics'->new($_) };

declare 'RepeatedTranslationEvaluationMetrics',
    as ArrayRef[TranslationEvaluationMetrics()];

coerce 'RepeatedTranslationEvaluationMetrics',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Automl::V1beta1::Translation::TranslationEvaluationMetrics'->new($_) } @$_ ] };

declare 'MapStringTranslationEvaluationMetrics',
    as HashRef[TranslationEvaluationMetrics()];

declare 'TranslationModelMetadata',
    as InstanceOf['Google::Cloud::Automl::V1beta1::Translation::TranslationModelMetadata'];

coerce 'TranslationModelMetadata',
    from HashRef, via { 'Google::Cloud::Automl::V1beta1::Translation::TranslationModelMetadata'->new($_) };

declare 'RepeatedTranslationModelMetadata',
    as ArrayRef[TranslationModelMetadata()];

coerce 'RepeatedTranslationModelMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Automl::V1beta1::Translation::TranslationModelMetadata'->new($_) } @$_ ] };

declare 'MapStringTranslationModelMetadata',
    as HashRef[TranslationModelMetadata()];

declare 'TranslationAnnotation',
    as InstanceOf['Google::Cloud::Automl::V1beta1::Translation::TranslationAnnotation'];

coerce 'TranslationAnnotation',
    from HashRef, via { 'Google::Cloud::Automl::V1beta1::Translation::TranslationAnnotation'->new($_) };

declare 'RepeatedTranslationAnnotation',
    as ArrayRef[TranslationAnnotation()];

coerce 'RepeatedTranslationAnnotation',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Automl::V1beta1::Translation::TranslationAnnotation'->new($_) } @$_ ] };

declare 'MapStringTranslationAnnotation',
    as HashRef[TranslationAnnotation()];

1;

__END__

=head1 NAME

Google::Cloud::Automl::V1beta1::Translation::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
