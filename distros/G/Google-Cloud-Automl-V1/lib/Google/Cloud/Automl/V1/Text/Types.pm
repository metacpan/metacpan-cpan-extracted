package Google::Cloud::Automl::V1::Text::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'TextClassificationDatasetMetadata',
    as InstanceOf['Google::Cloud::Automl::V1::Text::TextClassificationDatasetMetadata'];

coerce 'TextClassificationDatasetMetadata',
    from HashRef, via { 'Google::Cloud::Automl::V1::Text::TextClassificationDatasetMetadata'->new($_) };

declare 'RepeatedTextClassificationDatasetMetadata',
    as ArrayRef[TextClassificationDatasetMetadata()];

coerce 'RepeatedTextClassificationDatasetMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Automl::V1::Text::TextClassificationDatasetMetadata'->new($_) } @$_ ] };

declare 'MapStringTextClassificationDatasetMetadata',
    as HashRef[TextClassificationDatasetMetadata()];

declare 'TextClassificationModelMetadata',
    as InstanceOf['Google::Cloud::Automl::V1::Text::TextClassificationModelMetadata'];

coerce 'TextClassificationModelMetadata',
    from HashRef, via { 'Google::Cloud::Automl::V1::Text::TextClassificationModelMetadata'->new($_) };

declare 'RepeatedTextClassificationModelMetadata',
    as ArrayRef[TextClassificationModelMetadata()];

coerce 'RepeatedTextClassificationModelMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Automl::V1::Text::TextClassificationModelMetadata'->new($_) } @$_ ] };

declare 'MapStringTextClassificationModelMetadata',
    as HashRef[TextClassificationModelMetadata()];

declare 'TextExtractionDatasetMetadata',
    as InstanceOf['Google::Cloud::Automl::V1::Text::TextExtractionDatasetMetadata'];

coerce 'TextExtractionDatasetMetadata',
    from HashRef, via { 'Google::Cloud::Automl::V1::Text::TextExtractionDatasetMetadata'->new($_) };

declare 'RepeatedTextExtractionDatasetMetadata',
    as ArrayRef[TextExtractionDatasetMetadata()];

coerce 'RepeatedTextExtractionDatasetMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Automl::V1::Text::TextExtractionDatasetMetadata'->new($_) } @$_ ] };

declare 'MapStringTextExtractionDatasetMetadata',
    as HashRef[TextExtractionDatasetMetadata()];

declare 'TextExtractionModelMetadata',
    as InstanceOf['Google::Cloud::Automl::V1::Text::TextExtractionModelMetadata'];

coerce 'TextExtractionModelMetadata',
    from HashRef, via { 'Google::Cloud::Automl::V1::Text::TextExtractionModelMetadata'->new($_) };

declare 'RepeatedTextExtractionModelMetadata',
    as ArrayRef[TextExtractionModelMetadata()];

coerce 'RepeatedTextExtractionModelMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Automl::V1::Text::TextExtractionModelMetadata'->new($_) } @$_ ] };

declare 'MapStringTextExtractionModelMetadata',
    as HashRef[TextExtractionModelMetadata()];

declare 'TextSentimentDatasetMetadata',
    as InstanceOf['Google::Cloud::Automl::V1::Text::TextSentimentDatasetMetadata'];

coerce 'TextSentimentDatasetMetadata',
    from HashRef, via { 'Google::Cloud::Automl::V1::Text::TextSentimentDatasetMetadata'->new($_) };

declare 'RepeatedTextSentimentDatasetMetadata',
    as ArrayRef[TextSentimentDatasetMetadata()];

coerce 'RepeatedTextSentimentDatasetMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Automl::V1::Text::TextSentimentDatasetMetadata'->new($_) } @$_ ] };

declare 'MapStringTextSentimentDatasetMetadata',
    as HashRef[TextSentimentDatasetMetadata()];

declare 'TextSentimentModelMetadata',
    as InstanceOf['Google::Cloud::Automl::V1::Text::TextSentimentModelMetadata'];

coerce 'TextSentimentModelMetadata',
    from HashRef, via { 'Google::Cloud::Automl::V1::Text::TextSentimentModelMetadata'->new($_) };

declare 'RepeatedTextSentimentModelMetadata',
    as ArrayRef[TextSentimentModelMetadata()];

coerce 'RepeatedTextSentimentModelMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Automl::V1::Text::TextSentimentModelMetadata'->new($_) } @$_ ] };

declare 'MapStringTextSentimentModelMetadata',
    as HashRef[TextSentimentModelMetadata()];

1;

__END__

=head1 NAME

Google::Cloud::Automl::V1::Text::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
