package Google::Bigtable::V2::RequestStats::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'ReadIterationStats',
    as InstanceOf['Google::Bigtable::V2::RequestStats::ReadIterationStats'];

coerce 'ReadIterationStats',
    from HashRef, via { 'Google::Bigtable::V2::RequestStats::ReadIterationStats'->new($_) };

declare 'RepeatedReadIterationStats',
    as ArrayRef[ReadIterationStats()];

coerce 'RepeatedReadIterationStats',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::V2::RequestStats::ReadIterationStats'->new($_) } @$_ ] };

declare 'MapStringReadIterationStats',
    as HashRef[ReadIterationStats()];

declare 'RequestLatencyStats',
    as InstanceOf['Google::Bigtable::V2::RequestStats::RequestLatencyStats'];

coerce 'RequestLatencyStats',
    from HashRef, via { 'Google::Bigtable::V2::RequestStats::RequestLatencyStats'->new($_) };

declare 'RepeatedRequestLatencyStats',
    as ArrayRef[RequestLatencyStats()];

coerce 'RepeatedRequestLatencyStats',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::V2::RequestStats::RequestLatencyStats'->new($_) } @$_ ] };

declare 'MapStringRequestLatencyStats',
    as HashRef[RequestLatencyStats()];

declare 'FullReadStatsView',
    as InstanceOf['Google::Bigtable::V2::RequestStats::FullReadStatsView'];

coerce 'FullReadStatsView',
    from HashRef, via { 'Google::Bigtable::V2::RequestStats::FullReadStatsView'->new($_) };

declare 'RepeatedFullReadStatsView',
    as ArrayRef[FullReadStatsView()];

coerce 'RepeatedFullReadStatsView',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::V2::RequestStats::FullReadStatsView'->new($_) } @$_ ] };

declare 'MapStringFullReadStatsView',
    as HashRef[FullReadStatsView()];

declare 'RequestStats',
    as InstanceOf['Google::Bigtable::V2::RequestStats::RequestStats'];

coerce 'RequestStats',
    from HashRef, via { 'Google::Bigtable::V2::RequestStats::RequestStats'->new($_) };

declare 'RepeatedRequestStats',
    as ArrayRef[RequestStats()];

coerce 'RepeatedRequestStats',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::V2::RequestStats::RequestStats'->new($_) } @$_ ] };

declare 'MapStringRequestStats',
    as HashRef[RequestStats()];

1;

__END__

=head1 NAME

Google::Bigtable::V2::RequestStats::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
