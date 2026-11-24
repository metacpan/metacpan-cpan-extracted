package Google::Cloud::Recommender::V1beta1::Recommendation::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Recommendation',
    as InstanceOf['Google::Cloud::Recommender::V1beta1::Recommendation::Recommendation'];

coerce 'Recommendation',
    from HashRef, via { 'Google::Cloud::Recommender::V1beta1::Recommendation::Recommendation'->new($_) };

declare 'RepeatedRecommendation',
    as ArrayRef[Recommendation()];

coerce 'RepeatedRecommendation',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Recommender::V1beta1::Recommendation::Recommendation'->new($_) } @$_ ] };

declare 'MapStringRecommendation',
    as HashRef[Recommendation()];

declare 'Priority',
    as (Int | Str);

declare 'InsightReference',
    as InstanceOf['Google::Cloud::Recommender::V1beta1::Recommendation::Recommendation::InsightReference'];

coerce 'InsightReference',
    from HashRef, via { 'Google::Cloud::Recommender::V1beta1::Recommendation::Recommendation::InsightReference'->new($_) };

declare 'RepeatedInsightReference',
    as ArrayRef[InsightReference()];

coerce 'RepeatedInsightReference',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Recommender::V1beta1::Recommendation::Recommendation::InsightReference'->new($_) } @$_ ] };

declare 'MapStringInsightReference',
    as HashRef[InsightReference()];

declare 'RecommendationContent',
    as InstanceOf['Google::Cloud::Recommender::V1beta1::Recommendation::RecommendationContent'];

coerce 'RecommendationContent',
    from HashRef, via { 'Google::Cloud::Recommender::V1beta1::Recommendation::RecommendationContent'->new($_) };

declare 'RepeatedRecommendationContent',
    as ArrayRef[RecommendationContent()];

coerce 'RepeatedRecommendationContent',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Recommender::V1beta1::Recommendation::RecommendationContent'->new($_) } @$_ ] };

declare 'MapStringRecommendationContent',
    as HashRef[RecommendationContent()];

declare 'OperationGroup',
    as InstanceOf['Google::Cloud::Recommender::V1beta1::Recommendation::OperationGroup'];

coerce 'OperationGroup',
    from HashRef, via { 'Google::Cloud::Recommender::V1beta1::Recommendation::OperationGroup'->new($_) };

declare 'RepeatedOperationGroup',
    as ArrayRef[OperationGroup()];

coerce 'RepeatedOperationGroup',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Recommender::V1beta1::Recommendation::OperationGroup'->new($_) } @$_ ] };

declare 'MapStringOperationGroup',
    as HashRef[OperationGroup()];

declare 'Operation',
    as InstanceOf['Google::Cloud::Recommender::V1beta1::Recommendation::Operation'];

coerce 'Operation',
    from HashRef, via { 'Google::Cloud::Recommender::V1beta1::Recommendation::Operation'->new($_) };

declare 'RepeatedOperation',
    as ArrayRef[Operation()];

coerce 'RepeatedOperation',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Recommender::V1beta1::Recommendation::Operation'->new($_) } @$_ ] };

declare 'MapStringOperation',
    as HashRef[Operation()];

declare 'PathFiltersEntry',
    as InstanceOf['Google::Cloud::Recommender::V1beta1::Recommendation::Operation::PathFiltersEntry'];

coerce 'PathFiltersEntry',
    from HashRef, via { 'Google::Cloud::Recommender::V1beta1::Recommendation::Operation::PathFiltersEntry'->new($_) };

declare 'RepeatedPathFiltersEntry',
    as ArrayRef[PathFiltersEntry()];

coerce 'RepeatedPathFiltersEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Recommender::V1beta1::Recommendation::Operation::PathFiltersEntry'->new($_) } @$_ ] };

declare 'MapStringPathFiltersEntry',
    as HashRef[PathFiltersEntry()];

declare 'PathValueMatchersEntry',
    as InstanceOf['Google::Cloud::Recommender::V1beta1::Recommendation::Operation::PathValueMatchersEntry'];

coerce 'PathValueMatchersEntry',
    from HashRef, via { 'Google::Cloud::Recommender::V1beta1::Recommendation::Operation::PathValueMatchersEntry'->new($_) };

declare 'RepeatedPathValueMatchersEntry',
    as ArrayRef[PathValueMatchersEntry()];

coerce 'RepeatedPathValueMatchersEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Recommender::V1beta1::Recommendation::Operation::PathValueMatchersEntry'->new($_) } @$_ ] };

declare 'MapStringPathValueMatchersEntry',
    as HashRef[PathValueMatchersEntry()];

declare 'ValueMatcher',
    as InstanceOf['Google::Cloud::Recommender::V1beta1::Recommendation::ValueMatcher'];

coerce 'ValueMatcher',
    from HashRef, via { 'Google::Cloud::Recommender::V1beta1::Recommendation::ValueMatcher'->new($_) };

declare 'RepeatedValueMatcher',
    as ArrayRef[ValueMatcher()];

coerce 'RepeatedValueMatcher',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Recommender::V1beta1::Recommendation::ValueMatcher'->new($_) } @$_ ] };

declare 'MapStringValueMatcher',
    as HashRef[ValueMatcher()];

declare 'CostProjection',
    as InstanceOf['Google::Cloud::Recommender::V1beta1::Recommendation::CostProjection'];

coerce 'CostProjection',
    from HashRef, via { 'Google::Cloud::Recommender::V1beta1::Recommendation::CostProjection'->new($_) };

declare 'RepeatedCostProjection',
    as ArrayRef[CostProjection()];

coerce 'RepeatedCostProjection',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Recommender::V1beta1::Recommendation::CostProjection'->new($_) } @$_ ] };

declare 'MapStringCostProjection',
    as HashRef[CostProjection()];

declare 'SecurityProjection',
    as InstanceOf['Google::Cloud::Recommender::V1beta1::Recommendation::SecurityProjection'];

coerce 'SecurityProjection',
    from HashRef, via { 'Google::Cloud::Recommender::V1beta1::Recommendation::SecurityProjection'->new($_) };

declare 'RepeatedSecurityProjection',
    as ArrayRef[SecurityProjection()];

coerce 'RepeatedSecurityProjection',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Recommender::V1beta1::Recommendation::SecurityProjection'->new($_) } @$_ ] };

declare 'MapStringSecurityProjection',
    as HashRef[SecurityProjection()];

declare 'SustainabilityProjection',
    as InstanceOf['Google::Cloud::Recommender::V1beta1::Recommendation::SustainabilityProjection'];

coerce 'SustainabilityProjection',
    from HashRef, via { 'Google::Cloud::Recommender::V1beta1::Recommendation::SustainabilityProjection'->new($_) };

declare 'RepeatedSustainabilityProjection',
    as ArrayRef[SustainabilityProjection()];

coerce 'RepeatedSustainabilityProjection',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Recommender::V1beta1::Recommendation::SustainabilityProjection'->new($_) } @$_ ] };

declare 'MapStringSustainabilityProjection',
    as HashRef[SustainabilityProjection()];

declare 'Impact',
    as InstanceOf['Google::Cloud::Recommender::V1beta1::Recommendation::Impact'];

coerce 'Impact',
    from HashRef, via { 'Google::Cloud::Recommender::V1beta1::Recommendation::Impact'->new($_) };

declare 'RepeatedImpact',
    as ArrayRef[Impact()];

coerce 'RepeatedImpact',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Recommender::V1beta1::Recommendation::Impact'->new($_) } @$_ ] };

declare 'MapStringImpact',
    as HashRef[Impact()];

declare 'Category',
    as (Int | Str);

declare 'RecommendationStateInfo',
    as InstanceOf['Google::Cloud::Recommender::V1beta1::Recommendation::RecommendationStateInfo'];

coerce 'RecommendationStateInfo',
    from HashRef, via { 'Google::Cloud::Recommender::V1beta1::Recommendation::RecommendationStateInfo'->new($_) };

declare 'RepeatedRecommendationStateInfo',
    as ArrayRef[RecommendationStateInfo()];

coerce 'RepeatedRecommendationStateInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Recommender::V1beta1::Recommendation::RecommendationStateInfo'->new($_) } @$_ ] };

declare 'MapStringRecommendationStateInfo',
    as HashRef[RecommendationStateInfo()];

declare 'State',
    as (Int | Str);

declare 'StateMetadataEntry',
    as InstanceOf['Google::Cloud::Recommender::V1beta1::Recommendation::RecommendationStateInfo::StateMetadataEntry'];

coerce 'StateMetadataEntry',
    from HashRef, via { 'Google::Cloud::Recommender::V1beta1::Recommendation::RecommendationStateInfo::StateMetadataEntry'->new($_) };

declare 'RepeatedStateMetadataEntry',
    as ArrayRef[StateMetadataEntry()];

coerce 'RepeatedStateMetadataEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Recommender::V1beta1::Recommendation::RecommendationStateInfo::StateMetadataEntry'->new($_) } @$_ ] };

declare 'MapStringStateMetadataEntry',
    as HashRef[StateMetadataEntry()];

declare 'RecommenderType',
    as InstanceOf['Google::Cloud::Recommender::V1beta1::Recommendation::RecommenderType'];

coerce 'RecommenderType',
    from HashRef, via { 'Google::Cloud::Recommender::V1beta1::Recommendation::RecommenderType'->new($_) };

declare 'RepeatedRecommenderType',
    as ArrayRef[RecommenderType()];

coerce 'RepeatedRecommenderType',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Recommender::V1beta1::Recommendation::RecommenderType'->new($_) } @$_ ] };

declare 'MapStringRecommenderType',
    as HashRef[RecommenderType()];

1;

__END__

=head1 NAME

Google::Cloud::Recommender::V1beta1::Recommendation::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
