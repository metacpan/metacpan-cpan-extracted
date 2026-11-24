package Google::Cloud::Recommender::V1::Insight::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Insight',
    as InstanceOf['Google::Cloud::Recommender::V1::Insight::Insight'];

coerce 'Insight',
    from HashRef, via { 'Google::Cloud::Recommender::V1::Insight::Insight'->new($_) };

declare 'RepeatedInsight',
    as ArrayRef[Insight()];

coerce 'RepeatedInsight',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Recommender::V1::Insight::Insight'->new($_) } @$_ ] };

declare 'MapStringInsight',
    as HashRef[Insight()];

declare 'Category',
    as (Int | Str);

declare 'Severity',
    as (Int | Str);

declare 'RecommendationReference',
    as InstanceOf['Google::Cloud::Recommender::V1::Insight::Insight::RecommendationReference'];

coerce 'RecommendationReference',
    from HashRef, via { 'Google::Cloud::Recommender::V1::Insight::Insight::RecommendationReference'->new($_) };

declare 'RepeatedRecommendationReference',
    as ArrayRef[RecommendationReference()];

coerce 'RepeatedRecommendationReference',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Recommender::V1::Insight::Insight::RecommendationReference'->new($_) } @$_ ] };

declare 'MapStringRecommendationReference',
    as HashRef[RecommendationReference()];

declare 'InsightStateInfo',
    as InstanceOf['Google::Cloud::Recommender::V1::Insight::InsightStateInfo'];

coerce 'InsightStateInfo',
    from HashRef, via { 'Google::Cloud::Recommender::V1::Insight::InsightStateInfo'->new($_) };

declare 'RepeatedInsightStateInfo',
    as ArrayRef[InsightStateInfo()];

coerce 'RepeatedInsightStateInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Recommender::V1::Insight::InsightStateInfo'->new($_) } @$_ ] };

declare 'MapStringInsightStateInfo',
    as HashRef[InsightStateInfo()];

declare 'State',
    as (Int | Str);

declare 'StateMetadataEntry',
    as InstanceOf['Google::Cloud::Recommender::V1::Insight::InsightStateInfo::StateMetadataEntry'];

coerce 'StateMetadataEntry',
    from HashRef, via { 'Google::Cloud::Recommender::V1::Insight::InsightStateInfo::StateMetadataEntry'->new($_) };

declare 'RepeatedStateMetadataEntry',
    as ArrayRef[StateMetadataEntry()];

coerce 'RepeatedStateMetadataEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Recommender::V1::Insight::InsightStateInfo::StateMetadataEntry'->new($_) } @$_ ] };

declare 'MapStringStateMetadataEntry',
    as HashRef[StateMetadataEntry()];

1;

__END__

=head1 NAME

Google::Cloud::Recommender::V1::Insight::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
