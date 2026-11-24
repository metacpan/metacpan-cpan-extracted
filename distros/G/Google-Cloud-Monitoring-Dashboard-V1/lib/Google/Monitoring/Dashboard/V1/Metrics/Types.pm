package Google::Monitoring::Dashboard::V1::Metrics::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'SparkChartType',
    as (Int | Str);

declare 'TimeSeriesQuery',
    as InstanceOf['Google::Monitoring::Dashboard::V1::Metrics::TimeSeriesQuery'];

coerce 'TimeSeriesQuery',
    from HashRef, via { 'Google::Monitoring::Dashboard::V1::Metrics::TimeSeriesQuery'->new($_) };

declare 'RepeatedTimeSeriesQuery',
    as ArrayRef[TimeSeriesQuery()];

coerce 'RepeatedTimeSeriesQuery',
    from ArrayRef[HashRef], via { [ map { 'Google::Monitoring::Dashboard::V1::Metrics::TimeSeriesQuery'->new($_) } @$_ ] };

declare 'MapStringTimeSeriesQuery',
    as HashRef[TimeSeriesQuery()];

declare 'TimeSeriesFilter',
    as InstanceOf['Google::Monitoring::Dashboard::V1::Metrics::TimeSeriesFilter'];

coerce 'TimeSeriesFilter',
    from HashRef, via { 'Google::Monitoring::Dashboard::V1::Metrics::TimeSeriesFilter'->new($_) };

declare 'RepeatedTimeSeriesFilter',
    as ArrayRef[TimeSeriesFilter()];

coerce 'RepeatedTimeSeriesFilter',
    from ArrayRef[HashRef], via { [ map { 'Google::Monitoring::Dashboard::V1::Metrics::TimeSeriesFilter'->new($_) } @$_ ] };

declare 'MapStringTimeSeriesFilter',
    as HashRef[TimeSeriesFilter()];

declare 'TimeSeriesFilterRatio',
    as InstanceOf['Google::Monitoring::Dashboard::V1::Metrics::TimeSeriesFilterRatio'];

coerce 'TimeSeriesFilterRatio',
    from HashRef, via { 'Google::Monitoring::Dashboard::V1::Metrics::TimeSeriesFilterRatio'->new($_) };

declare 'RepeatedTimeSeriesFilterRatio',
    as ArrayRef[TimeSeriesFilterRatio()];

coerce 'RepeatedTimeSeriesFilterRatio',
    from ArrayRef[HashRef], via { [ map { 'Google::Monitoring::Dashboard::V1::Metrics::TimeSeriesFilterRatio'->new($_) } @$_ ] };

declare 'MapStringTimeSeriesFilterRatio',
    as HashRef[TimeSeriesFilterRatio()];

declare 'RatioPart',
    as InstanceOf['Google::Monitoring::Dashboard::V1::Metrics::TimeSeriesFilterRatio::RatioPart'];

coerce 'RatioPart',
    from HashRef, via { 'Google::Monitoring::Dashboard::V1::Metrics::TimeSeriesFilterRatio::RatioPart'->new($_) };

declare 'RepeatedRatioPart',
    as ArrayRef[RatioPart()];

coerce 'RepeatedRatioPart',
    from ArrayRef[HashRef], via { [ map { 'Google::Monitoring::Dashboard::V1::Metrics::TimeSeriesFilterRatio::RatioPart'->new($_) } @$_ ] };

declare 'MapStringRatioPart',
    as HashRef[RatioPart()];

declare 'Threshold',
    as InstanceOf['Google::Monitoring::Dashboard::V1::Metrics::Threshold'];

coerce 'Threshold',
    from HashRef, via { 'Google::Monitoring::Dashboard::V1::Metrics::Threshold'->new($_) };

declare 'RepeatedThreshold',
    as ArrayRef[Threshold()];

coerce 'RepeatedThreshold',
    from ArrayRef[HashRef], via { [ map { 'Google::Monitoring::Dashboard::V1::Metrics::Threshold'->new($_) } @$_ ] };

declare 'MapStringThreshold',
    as HashRef[Threshold()];

declare 'Color',
    as (Int | Str);

declare 'Direction',
    as (Int | Str);

declare 'TargetAxis',
    as (Int | Str);

1;

__END__

=head1 NAME

Google::Monitoring::Dashboard::V1::Metrics::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
