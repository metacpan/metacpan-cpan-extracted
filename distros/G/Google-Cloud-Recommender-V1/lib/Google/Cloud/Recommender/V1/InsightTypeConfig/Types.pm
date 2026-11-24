package Google::Cloud::Recommender::V1::InsightTypeConfig::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'InsightTypeConfig',
    as InstanceOf['Google::Cloud::Recommender::V1::InsightTypeConfig::InsightTypeConfig'];

coerce 'InsightTypeConfig',
    from HashRef, via { 'Google::Cloud::Recommender::V1::InsightTypeConfig::InsightTypeConfig'->new($_) };

declare 'RepeatedInsightTypeConfig',
    as ArrayRef[InsightTypeConfig()];

coerce 'RepeatedInsightTypeConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Recommender::V1::InsightTypeConfig::InsightTypeConfig'->new($_) } @$_ ] };

declare 'MapStringInsightTypeConfig',
    as HashRef[InsightTypeConfig()];

declare 'AnnotationsEntry',
    as InstanceOf['Google::Cloud::Recommender::V1::InsightTypeConfig::InsightTypeConfig::AnnotationsEntry'];

coerce 'AnnotationsEntry',
    from HashRef, via { 'Google::Cloud::Recommender::V1::InsightTypeConfig::InsightTypeConfig::AnnotationsEntry'->new($_) };

declare 'RepeatedAnnotationsEntry',
    as ArrayRef[AnnotationsEntry()];

coerce 'RepeatedAnnotationsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Recommender::V1::InsightTypeConfig::InsightTypeConfig::AnnotationsEntry'->new($_) } @$_ ] };

declare 'MapStringAnnotationsEntry',
    as HashRef[AnnotationsEntry()];

declare 'InsightTypeGenerationConfig',
    as InstanceOf['Google::Cloud::Recommender::V1::InsightTypeConfig::InsightTypeGenerationConfig'];

coerce 'InsightTypeGenerationConfig',
    from HashRef, via { 'Google::Cloud::Recommender::V1::InsightTypeConfig::InsightTypeGenerationConfig'->new($_) };

declare 'RepeatedInsightTypeGenerationConfig',
    as ArrayRef[InsightTypeGenerationConfig()];

coerce 'RepeatedInsightTypeGenerationConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Recommender::V1::InsightTypeConfig::InsightTypeGenerationConfig'->new($_) } @$_ ] };

declare 'MapStringInsightTypeGenerationConfig',
    as HashRef[InsightTypeGenerationConfig()];

1;

__END__

=head1 NAME

Google::Cloud::Recommender::V1::InsightTypeConfig::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
