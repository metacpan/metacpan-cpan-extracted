package Google::Monitoring::V3::Metric::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Point',
    as InstanceOf['Google::Monitoring::V3::Metric::Point'];

coerce 'Point',
    from HashRef, via { 'Google::Monitoring::V3::Metric::Point'->new($_) };

declare 'RepeatedPoint',
    as ArrayRef[Point()];

coerce 'RepeatedPoint',
    from ArrayRef[HashRef], via { [ map { 'Google::Monitoring::V3::Metric::Point'->new($_) } @$_ ] };

declare 'MapStringPoint',
    as HashRef[Point()];

declare 'TimeSeries',
    as InstanceOf['Google::Monitoring::V3::Metric::TimeSeries'];

coerce 'TimeSeries',
    from HashRef, via { 'Google::Monitoring::V3::Metric::TimeSeries'->new($_) };

declare 'RepeatedTimeSeries',
    as ArrayRef[TimeSeries()];

coerce 'RepeatedTimeSeries',
    from ArrayRef[HashRef], via { [ map { 'Google::Monitoring::V3::Metric::TimeSeries'->new($_) } @$_ ] };

declare 'MapStringTimeSeries',
    as HashRef[TimeSeries()];

declare 'TimeSeriesDescriptor',
    as InstanceOf['Google::Monitoring::V3::Metric::TimeSeriesDescriptor'];

coerce 'TimeSeriesDescriptor',
    from HashRef, via { 'Google::Monitoring::V3::Metric::TimeSeriesDescriptor'->new($_) };

declare 'RepeatedTimeSeriesDescriptor',
    as ArrayRef[TimeSeriesDescriptor()];

coerce 'RepeatedTimeSeriesDescriptor',
    from ArrayRef[HashRef], via { [ map { 'Google::Monitoring::V3::Metric::TimeSeriesDescriptor'->new($_) } @$_ ] };

declare 'MapStringTimeSeriesDescriptor',
    as HashRef[TimeSeriesDescriptor()];

declare 'ValueDescriptor',
    as InstanceOf['Google::Monitoring::V3::Metric::TimeSeriesDescriptor::ValueDescriptor'];

coerce 'ValueDescriptor',
    from HashRef, via { 'Google::Monitoring::V3::Metric::TimeSeriesDescriptor::ValueDescriptor'->new($_) };

declare 'RepeatedValueDescriptor',
    as ArrayRef[ValueDescriptor()];

coerce 'RepeatedValueDescriptor',
    from ArrayRef[HashRef], via { [ map { 'Google::Monitoring::V3::Metric::TimeSeriesDescriptor::ValueDescriptor'->new($_) } @$_ ] };

declare 'MapStringValueDescriptor',
    as HashRef[ValueDescriptor()];

declare 'TimeSeriesData',
    as InstanceOf['Google::Monitoring::V3::Metric::TimeSeriesData'];

coerce 'TimeSeriesData',
    from HashRef, via { 'Google::Monitoring::V3::Metric::TimeSeriesData'->new($_) };

declare 'RepeatedTimeSeriesData',
    as ArrayRef[TimeSeriesData()];

coerce 'RepeatedTimeSeriesData',
    from ArrayRef[HashRef], via { [ map { 'Google::Monitoring::V3::Metric::TimeSeriesData'->new($_) } @$_ ] };

declare 'MapStringTimeSeriesData',
    as HashRef[TimeSeriesData()];

declare 'PointData',
    as InstanceOf['Google::Monitoring::V3::Metric::TimeSeriesData::PointData'];

coerce 'PointData',
    from HashRef, via { 'Google::Monitoring::V3::Metric::TimeSeriesData::PointData'->new($_) };

declare 'RepeatedPointData',
    as ArrayRef[PointData()];

coerce 'RepeatedPointData',
    from ArrayRef[HashRef], via { [ map { 'Google::Monitoring::V3::Metric::TimeSeriesData::PointData'->new($_) } @$_ ] };

declare 'MapStringPointData',
    as HashRef[PointData()];

declare 'LabelValue',
    as InstanceOf['Google::Monitoring::V3::Metric::LabelValue'];

coerce 'LabelValue',
    from HashRef, via { 'Google::Monitoring::V3::Metric::LabelValue'->new($_) };

declare 'RepeatedLabelValue',
    as ArrayRef[LabelValue()];

coerce 'RepeatedLabelValue',
    from ArrayRef[HashRef], via { [ map { 'Google::Monitoring::V3::Metric::LabelValue'->new($_) } @$_ ] };

declare 'MapStringLabelValue',
    as HashRef[LabelValue()];

declare 'QueryError',
    as InstanceOf['Google::Monitoring::V3::Metric::QueryError'];

coerce 'QueryError',
    from HashRef, via { 'Google::Monitoring::V3::Metric::QueryError'->new($_) };

declare 'RepeatedQueryError',
    as ArrayRef[QueryError()];

coerce 'RepeatedQueryError',
    from ArrayRef[HashRef], via { [ map { 'Google::Monitoring::V3::Metric::QueryError'->new($_) } @$_ ] };

declare 'MapStringQueryError',
    as HashRef[QueryError()];

declare 'TextLocator',
    as InstanceOf['Google::Monitoring::V3::Metric::TextLocator'];

coerce 'TextLocator',
    from HashRef, via { 'Google::Monitoring::V3::Metric::TextLocator'->new($_) };

declare 'RepeatedTextLocator',
    as ArrayRef[TextLocator()];

coerce 'RepeatedTextLocator',
    from ArrayRef[HashRef], via { [ map { 'Google::Monitoring::V3::Metric::TextLocator'->new($_) } @$_ ] };

declare 'MapStringTextLocator',
    as HashRef[TextLocator()];

declare 'Position',
    as InstanceOf['Google::Monitoring::V3::Metric::TextLocator::Position'];

coerce 'Position',
    from HashRef, via { 'Google::Monitoring::V3::Metric::TextLocator::Position'->new($_) };

declare 'RepeatedPosition',
    as ArrayRef[Position()];

coerce 'RepeatedPosition',
    from ArrayRef[HashRef], via { [ map { 'Google::Monitoring::V3::Metric::TextLocator::Position'->new($_) } @$_ ] };

declare 'MapStringPosition',
    as HashRef[Position()];

1;

__END__

=head1 NAME

Google::Monitoring::V3::Metric::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
