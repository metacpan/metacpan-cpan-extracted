package Google::Cloud::Automl::V1beta1::DataStats::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'DataStats',
    as InstanceOf['Google::Cloud::Automl::V1beta1::DataStats::DataStats'];

coerce 'DataStats',
    from HashRef, via { 'Google::Cloud::Automl::V1beta1::DataStats::DataStats'->new($_) };

declare 'RepeatedDataStats',
    as ArrayRef[DataStats()];

coerce 'RepeatedDataStats',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Automl::V1beta1::DataStats::DataStats'->new($_) } @$_ ] };

declare 'MapStringDataStats',
    as HashRef[DataStats()];

declare 'Float64Stats',
    as InstanceOf['Google::Cloud::Automl::V1beta1::DataStats::Float64Stats'];

coerce 'Float64Stats',
    from HashRef, via { 'Google::Cloud::Automl::V1beta1::DataStats::Float64Stats'->new($_) };

declare 'RepeatedFloat64Stats',
    as ArrayRef[Float64Stats()];

coerce 'RepeatedFloat64Stats',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Automl::V1beta1::DataStats::Float64Stats'->new($_) } @$_ ] };

declare 'MapStringFloat64Stats',
    as HashRef[Float64Stats()];

declare 'HistogramBucket',
    as InstanceOf['Google::Cloud::Automl::V1beta1::DataStats::Float64Stats::HistogramBucket'];

coerce 'HistogramBucket',
    from HashRef, via { 'Google::Cloud::Automl::V1beta1::DataStats::Float64Stats::HistogramBucket'->new($_) };

declare 'RepeatedHistogramBucket',
    as ArrayRef[HistogramBucket()];

coerce 'RepeatedHistogramBucket',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Automl::V1beta1::DataStats::Float64Stats::HistogramBucket'->new($_) } @$_ ] };

declare 'MapStringHistogramBucket',
    as HashRef[HistogramBucket()];

declare 'StringStats',
    as InstanceOf['Google::Cloud::Automl::V1beta1::DataStats::StringStats'];

coerce 'StringStats',
    from HashRef, via { 'Google::Cloud::Automl::V1beta1::DataStats::StringStats'->new($_) };

declare 'RepeatedStringStats',
    as ArrayRef[StringStats()];

coerce 'RepeatedStringStats',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Automl::V1beta1::DataStats::StringStats'->new($_) } @$_ ] };

declare 'MapStringStringStats',
    as HashRef[StringStats()];

declare 'UnigramStats',
    as InstanceOf['Google::Cloud::Automl::V1beta1::DataStats::StringStats::UnigramStats'];

coerce 'UnigramStats',
    from HashRef, via { 'Google::Cloud::Automl::V1beta1::DataStats::StringStats::UnigramStats'->new($_) };

declare 'RepeatedUnigramStats',
    as ArrayRef[UnigramStats()];

coerce 'RepeatedUnigramStats',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Automl::V1beta1::DataStats::StringStats::UnigramStats'->new($_) } @$_ ] };

declare 'MapStringUnigramStats',
    as HashRef[UnigramStats()];

declare 'TimestampStats',
    as InstanceOf['Google::Cloud::Automl::V1beta1::DataStats::TimestampStats'];

coerce 'TimestampStats',
    from HashRef, via { 'Google::Cloud::Automl::V1beta1::DataStats::TimestampStats'->new($_) };

declare 'RepeatedTimestampStats',
    as ArrayRef[TimestampStats()];

coerce 'RepeatedTimestampStats',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Automl::V1beta1::DataStats::TimestampStats'->new($_) } @$_ ] };

declare 'MapStringTimestampStats',
    as HashRef[TimestampStats()];

declare 'GranularStats',
    as InstanceOf['Google::Cloud::Automl::V1beta1::DataStats::TimestampStats::GranularStats'];

coerce 'GranularStats',
    from HashRef, via { 'Google::Cloud::Automl::V1beta1::DataStats::TimestampStats::GranularStats'->new($_) };

declare 'RepeatedGranularStats',
    as ArrayRef[GranularStats()];

coerce 'RepeatedGranularStats',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Automl::V1beta1::DataStats::TimestampStats::GranularStats'->new($_) } @$_ ] };

declare 'MapStringGranularStats',
    as HashRef[GranularStats()];

declare 'BucketsEntry',
    as InstanceOf['Google::Cloud::Automl::V1beta1::DataStats::TimestampStats::GranularStats::BucketsEntry'];

coerce 'BucketsEntry',
    from HashRef, via { 'Google::Cloud::Automl::V1beta1::DataStats::TimestampStats::GranularStats::BucketsEntry'->new($_) };

declare 'RepeatedBucketsEntry',
    as ArrayRef[BucketsEntry()];

coerce 'RepeatedBucketsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Automl::V1beta1::DataStats::TimestampStats::GranularStats::BucketsEntry'->new($_) } @$_ ] };

declare 'MapStringBucketsEntry',
    as HashRef[BucketsEntry()];

declare 'GranularStatsEntry',
    as InstanceOf['Google::Cloud::Automl::V1beta1::DataStats::TimestampStats::GranularStatsEntry'];

coerce 'GranularStatsEntry',
    from HashRef, via { 'Google::Cloud::Automl::V1beta1::DataStats::TimestampStats::GranularStatsEntry'->new($_) };

declare 'RepeatedGranularStatsEntry',
    as ArrayRef[GranularStatsEntry()];

coerce 'RepeatedGranularStatsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Automl::V1beta1::DataStats::TimestampStats::GranularStatsEntry'->new($_) } @$_ ] };

declare 'MapStringGranularStatsEntry',
    as HashRef[GranularStatsEntry()];

declare 'ArrayStats',
    as InstanceOf['Google::Cloud::Automl::V1beta1::DataStats::ArrayStats'];

coerce 'ArrayStats',
    from HashRef, via { 'Google::Cloud::Automl::V1beta1::DataStats::ArrayStats'->new($_) };

declare 'RepeatedArrayStats',
    as ArrayRef[ArrayStats()];

coerce 'RepeatedArrayStats',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Automl::V1beta1::DataStats::ArrayStats'->new($_) } @$_ ] };

declare 'MapStringArrayStats',
    as HashRef[ArrayStats()];

declare 'StructStats',
    as InstanceOf['Google::Cloud::Automl::V1beta1::DataStats::StructStats'];

coerce 'StructStats',
    from HashRef, via { 'Google::Cloud::Automl::V1beta1::DataStats::StructStats'->new($_) };

declare 'RepeatedStructStats',
    as ArrayRef[StructStats()];

coerce 'RepeatedStructStats',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Automl::V1beta1::DataStats::StructStats'->new($_) } @$_ ] };

declare 'MapStringStructStats',
    as HashRef[StructStats()];

declare 'FieldStatsEntry',
    as InstanceOf['Google::Cloud::Automl::V1beta1::DataStats::StructStats::FieldStatsEntry'];

coerce 'FieldStatsEntry',
    from HashRef, via { 'Google::Cloud::Automl::V1beta1::DataStats::StructStats::FieldStatsEntry'->new($_) };

declare 'RepeatedFieldStatsEntry',
    as ArrayRef[FieldStatsEntry()];

coerce 'RepeatedFieldStatsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Automl::V1beta1::DataStats::StructStats::FieldStatsEntry'->new($_) } @$_ ] };

declare 'MapStringFieldStatsEntry',
    as HashRef[FieldStatsEntry()];

declare 'CategoryStats',
    as InstanceOf['Google::Cloud::Automl::V1beta1::DataStats::CategoryStats'];

coerce 'CategoryStats',
    from HashRef, via { 'Google::Cloud::Automl::V1beta1::DataStats::CategoryStats'->new($_) };

declare 'RepeatedCategoryStats',
    as ArrayRef[CategoryStats()];

coerce 'RepeatedCategoryStats',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Automl::V1beta1::DataStats::CategoryStats'->new($_) } @$_ ] };

declare 'MapStringCategoryStats',
    as HashRef[CategoryStats()];

declare 'SingleCategoryStats',
    as InstanceOf['Google::Cloud::Automl::V1beta1::DataStats::CategoryStats::SingleCategoryStats'];

coerce 'SingleCategoryStats',
    from HashRef, via { 'Google::Cloud::Automl::V1beta1::DataStats::CategoryStats::SingleCategoryStats'->new($_) };

declare 'RepeatedSingleCategoryStats',
    as ArrayRef[SingleCategoryStats()];

coerce 'RepeatedSingleCategoryStats',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Automl::V1beta1::DataStats::CategoryStats::SingleCategoryStats'->new($_) } @$_ ] };

declare 'MapStringSingleCategoryStats',
    as HashRef[SingleCategoryStats()];

declare 'CorrelationStats',
    as InstanceOf['Google::Cloud::Automl::V1beta1::DataStats::CorrelationStats'];

coerce 'CorrelationStats',
    from HashRef, via { 'Google::Cloud::Automl::V1beta1::DataStats::CorrelationStats'->new($_) };

declare 'RepeatedCorrelationStats',
    as ArrayRef[CorrelationStats()];

coerce 'RepeatedCorrelationStats',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Automl::V1beta1::DataStats::CorrelationStats'->new($_) } @$_ ] };

declare 'MapStringCorrelationStats',
    as HashRef[CorrelationStats()];

1;

__END__

=head1 NAME

Google::Cloud::Automl::V1beta1::DataStats::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
