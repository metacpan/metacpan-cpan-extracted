package Google::Cloud::Recommender::V1beta1::RecommenderConfig::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'RecommenderConfig',
    as InstanceOf['Google::Cloud::Recommender::V1beta1::RecommenderConfig::RecommenderConfig'];

coerce 'RecommenderConfig',
    from HashRef, via { 'Google::Cloud::Recommender::V1beta1::RecommenderConfig::RecommenderConfig'->new($_) };

declare 'RepeatedRecommenderConfig',
    as ArrayRef[RecommenderConfig()];

coerce 'RepeatedRecommenderConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Recommender::V1beta1::RecommenderConfig::RecommenderConfig'->new($_) } @$_ ] };

declare 'MapStringRecommenderConfig',
    as HashRef[RecommenderConfig()];

declare 'AnnotationsEntry',
    as InstanceOf['Google::Cloud::Recommender::V1beta1::RecommenderConfig::RecommenderConfig::AnnotationsEntry'];

coerce 'AnnotationsEntry',
    from HashRef, via { 'Google::Cloud::Recommender::V1beta1::RecommenderConfig::RecommenderConfig::AnnotationsEntry'->new($_) };

declare 'RepeatedAnnotationsEntry',
    as ArrayRef[AnnotationsEntry()];

coerce 'RepeatedAnnotationsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Recommender::V1beta1::RecommenderConfig::RecommenderConfig::AnnotationsEntry'->new($_) } @$_ ] };

declare 'MapStringAnnotationsEntry',
    as HashRef[AnnotationsEntry()];

declare 'RecommenderGenerationConfig',
    as InstanceOf['Google::Cloud::Recommender::V1beta1::RecommenderConfig::RecommenderGenerationConfig'];

coerce 'RecommenderGenerationConfig',
    from HashRef, via { 'Google::Cloud::Recommender::V1beta1::RecommenderConfig::RecommenderGenerationConfig'->new($_) };

declare 'RepeatedRecommenderGenerationConfig',
    as ArrayRef[RecommenderGenerationConfig()];

coerce 'RepeatedRecommenderGenerationConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Recommender::V1beta1::RecommenderConfig::RecommenderGenerationConfig'->new($_) } @$_ ] };

declare 'MapStringRecommenderGenerationConfig',
    as HashRef[RecommenderGenerationConfig()];

1;

__END__

=head1 NAME

Google::Cloud::Recommender::V1beta1::RecommenderConfig::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
