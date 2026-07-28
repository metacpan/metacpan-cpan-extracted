package Google::Cloud::Bigquery::V2::GenAiStats::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'GenAiFunctionErrorStats',
    as InstanceOf['Google::Cloud::Bigquery::V2::GenAiStats::GenAiFunctionErrorStats'];

coerce 'GenAiFunctionErrorStats',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::GenAiStats::GenAiFunctionErrorStats'->new($_) };

declare 'RepeatedGenAiFunctionErrorStats',
    as ArrayRef[GenAiFunctionErrorStats()];

coerce 'RepeatedGenAiFunctionErrorStats',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::GenAiStats::GenAiFunctionErrorStats'->new($_) } @$_ ] };

declare 'MapStringGenAiFunctionErrorStats',
    as HashRef[GenAiFunctionErrorStats()];

declare 'GenAiFunctionCostOptimizationStats',
    as InstanceOf['Google::Cloud::Bigquery::V2::GenAiStats::GenAiFunctionCostOptimizationStats'];

coerce 'GenAiFunctionCostOptimizationStats',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::GenAiStats::GenAiFunctionCostOptimizationStats'->new($_) };

declare 'RepeatedGenAiFunctionCostOptimizationStats',
    as ArrayRef[GenAiFunctionCostOptimizationStats()];

coerce 'RepeatedGenAiFunctionCostOptimizationStats',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::GenAiStats::GenAiFunctionCostOptimizationStats'->new($_) } @$_ ] };

declare 'MapStringGenAiFunctionCostOptimizationStats',
    as HashRef[GenAiFunctionCostOptimizationStats()];

declare 'GenAiFunctionCacheStats',
    as InstanceOf['Google::Cloud::Bigquery::V2::GenAiStats::GenAiFunctionCacheStats'];

coerce 'GenAiFunctionCacheStats',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::GenAiStats::GenAiFunctionCacheStats'->new($_) };

declare 'RepeatedGenAiFunctionCacheStats',
    as ArrayRef[GenAiFunctionCacheStats()];

coerce 'RepeatedGenAiFunctionCacheStats',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::GenAiStats::GenAiFunctionCacheStats'->new($_) } @$_ ] };

declare 'MapStringGenAiFunctionCacheStats',
    as HashRef[GenAiFunctionCacheStats()];

declare 'GenAiFunctionStats',
    as InstanceOf['Google::Cloud::Bigquery::V2::GenAiStats::GenAiFunctionStats'];

coerce 'GenAiFunctionStats',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::GenAiStats::GenAiFunctionStats'->new($_) };

declare 'RepeatedGenAiFunctionStats',
    as ArrayRef[GenAiFunctionStats()];

coerce 'RepeatedGenAiFunctionStats',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::GenAiStats::GenAiFunctionStats'->new($_) } @$_ ] };

declare 'MapStringGenAiFunctionStats',
    as HashRef[GenAiFunctionStats()];

declare 'GenAiErrorStats',
    as InstanceOf['Google::Cloud::Bigquery::V2::GenAiStats::GenAiErrorStats'];

coerce 'GenAiErrorStats',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::GenAiStats::GenAiErrorStats'->new($_) };

declare 'RepeatedGenAiErrorStats',
    as ArrayRef[GenAiErrorStats()];

coerce 'RepeatedGenAiErrorStats',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::GenAiStats::GenAiErrorStats'->new($_) } @$_ ] };

declare 'MapStringGenAiErrorStats',
    as HashRef[GenAiErrorStats()];

declare 'GenAiStats',
    as InstanceOf['Google::Cloud::Bigquery::V2::GenAiStats::GenAiStats'];

coerce 'GenAiStats',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::GenAiStats::GenAiStats'->new($_) };

declare 'RepeatedGenAiStats',
    as ArrayRef[GenAiStats()];

coerce 'RepeatedGenAiStats',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::GenAiStats::GenAiStats'->new($_) } @$_ ] };

declare 'MapStringGenAiStats',
    as HashRef[GenAiStats()];

1;

__END__

=head1 NAME

Google::Cloud::Bigquery::V2::GenAiStats::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
