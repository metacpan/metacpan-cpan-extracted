package Google::Monitoring::Dashboard::V1::Xychart::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'XyChart',
    as InstanceOf['Google::Monitoring::Dashboard::V1::Xychart::XyChart'];

coerce 'XyChart',
    from HashRef, via { 'Google::Monitoring::Dashboard::V1::Xychart::XyChart'->new($_) };

declare 'RepeatedXyChart',
    as ArrayRef[XyChart()];

coerce 'RepeatedXyChart',
    from ArrayRef[HashRef], via { [ map { 'Google::Monitoring::Dashboard::V1::Xychart::XyChart'->new($_) } @$_ ] };

declare 'MapStringXyChart',
    as HashRef[XyChart()];

declare 'DataSet',
    as InstanceOf['Google::Monitoring::Dashboard::V1::Xychart::XyChart::DataSet'];

coerce 'DataSet',
    from HashRef, via { 'Google::Monitoring::Dashboard::V1::Xychart::XyChart::DataSet'->new($_) };

declare 'RepeatedDataSet',
    as ArrayRef[DataSet()];

coerce 'RepeatedDataSet',
    from ArrayRef[HashRef], via { [ map { 'Google::Monitoring::Dashboard::V1::Xychart::XyChart::DataSet'->new($_) } @$_ ] };

declare 'MapStringDataSet',
    as HashRef[DataSet()];

declare 'PlotType',
    as (Int | Str);

declare 'TargetAxis',
    as (Int | Str);

declare 'Axis',
    as InstanceOf['Google::Monitoring::Dashboard::V1::Xychart::XyChart::Axis'];

coerce 'Axis',
    from HashRef, via { 'Google::Monitoring::Dashboard::V1::Xychart::XyChart::Axis'->new($_) };

declare 'RepeatedAxis',
    as ArrayRef[Axis()];

coerce 'RepeatedAxis',
    from ArrayRef[HashRef], via { [ map { 'Google::Monitoring::Dashboard::V1::Xychart::XyChart::Axis'->new($_) } @$_ ] };

declare 'MapStringAxis',
    as HashRef[Axis()];

declare 'Scale',
    as (Int | Str);

declare 'ChartOptions',
    as InstanceOf['Google::Monitoring::Dashboard::V1::Xychart::ChartOptions'];

coerce 'ChartOptions',
    from HashRef, via { 'Google::Monitoring::Dashboard::V1::Xychart::ChartOptions'->new($_) };

declare 'RepeatedChartOptions',
    as ArrayRef[ChartOptions()];

coerce 'RepeatedChartOptions',
    from ArrayRef[HashRef], via { [ map { 'Google::Monitoring::Dashboard::V1::Xychart::ChartOptions'->new($_) } @$_ ] };

declare 'MapStringChartOptions',
    as HashRef[ChartOptions()];

declare 'Mode',
    as (Int | Str);

1;

__END__

=head1 NAME

Google::Monitoring::Dashboard::V1::Xychart::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
