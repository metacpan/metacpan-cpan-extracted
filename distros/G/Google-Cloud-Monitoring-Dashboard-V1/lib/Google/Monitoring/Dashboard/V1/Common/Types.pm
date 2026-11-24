package Google::Monitoring::Dashboard::V1::Common::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Aggregation',
    as InstanceOf['Google::Monitoring::Dashboard::V1::Common::Aggregation'];

coerce 'Aggregation',
    from HashRef, via { 'Google::Monitoring::Dashboard::V1::Common::Aggregation'->new($_) };

declare 'RepeatedAggregation',
    as ArrayRef[Aggregation()];

coerce 'RepeatedAggregation',
    from ArrayRef[HashRef], via { [ map { 'Google::Monitoring::Dashboard::V1::Common::Aggregation'->new($_) } @$_ ] };

declare 'MapStringAggregation',
    as HashRef[Aggregation()];

declare 'Aligner',
    as (Int | Str);

declare 'Reducer',
    as (Int | Str);

declare 'PickTimeSeriesFilter',
    as InstanceOf['Google::Monitoring::Dashboard::V1::Common::PickTimeSeriesFilter'];

coerce 'PickTimeSeriesFilter',
    from HashRef, via { 'Google::Monitoring::Dashboard::V1::Common::PickTimeSeriesFilter'->new($_) };

declare 'RepeatedPickTimeSeriesFilter',
    as ArrayRef[PickTimeSeriesFilter()];

coerce 'RepeatedPickTimeSeriesFilter',
    from ArrayRef[HashRef], via { [ map { 'Google::Monitoring::Dashboard::V1::Common::PickTimeSeriesFilter'->new($_) } @$_ ] };

declare 'MapStringPickTimeSeriesFilter',
    as HashRef[PickTimeSeriesFilter()];

declare 'Method',
    as (Int | Str);

declare 'Direction',
    as (Int | Str);

declare 'StatisticalTimeSeriesFilter',
    as InstanceOf['Google::Monitoring::Dashboard::V1::Common::StatisticalTimeSeriesFilter'];

coerce 'StatisticalTimeSeriesFilter',
    from HashRef, via { 'Google::Monitoring::Dashboard::V1::Common::StatisticalTimeSeriesFilter'->new($_) };

declare 'RepeatedStatisticalTimeSeriesFilter',
    as ArrayRef[StatisticalTimeSeriesFilter()];

coerce 'RepeatedStatisticalTimeSeriesFilter',
    from ArrayRef[HashRef], via { [ map { 'Google::Monitoring::Dashboard::V1::Common::StatisticalTimeSeriesFilter'->new($_) } @$_ ] };

declare 'MapStringStatisticalTimeSeriesFilter',
    as HashRef[StatisticalTimeSeriesFilter()];

declare 'Method',
    as (Int | Str);

1;

__END__

=head1 NAME

Google::Monitoring::Dashboard::V1::Common::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
