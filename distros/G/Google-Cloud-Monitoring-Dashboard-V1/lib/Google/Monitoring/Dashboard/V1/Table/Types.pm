package Google::Monitoring::Dashboard::V1::Table::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'TimeSeriesTable',
    as InstanceOf['Google::Monitoring::Dashboard::V1::Table::TimeSeriesTable'];

coerce 'TimeSeriesTable',
    from HashRef, via { 'Google::Monitoring::Dashboard::V1::Table::TimeSeriesTable'->new($_) };

declare 'RepeatedTimeSeriesTable',
    as ArrayRef[TimeSeriesTable()];

coerce 'RepeatedTimeSeriesTable',
    from ArrayRef[HashRef], via { [ map { 'Google::Monitoring::Dashboard::V1::Table::TimeSeriesTable'->new($_) } @$_ ] };

declare 'MapStringTimeSeriesTable',
    as HashRef[TimeSeriesTable()];

declare 'MetricVisualization',
    as (Int | Str);

declare 'TableDataSet',
    as InstanceOf['Google::Monitoring::Dashboard::V1::Table::TimeSeriesTable::TableDataSet'];

coerce 'TableDataSet',
    from HashRef, via { 'Google::Monitoring::Dashboard::V1::Table::TimeSeriesTable::TableDataSet'->new($_) };

declare 'RepeatedTableDataSet',
    as ArrayRef[TableDataSet()];

coerce 'RepeatedTableDataSet',
    from ArrayRef[HashRef], via { [ map { 'Google::Monitoring::Dashboard::V1::Table::TimeSeriesTable::TableDataSet'->new($_) } @$_ ] };

declare 'MapStringTableDataSet',
    as HashRef[TableDataSet()];

declare 'ColumnSettings',
    as InstanceOf['Google::Monitoring::Dashboard::V1::Table::TimeSeriesTable::ColumnSettings'];

coerce 'ColumnSettings',
    from HashRef, via { 'Google::Monitoring::Dashboard::V1::Table::TimeSeriesTable::ColumnSettings'->new($_) };

declare 'RepeatedColumnSettings',
    as ArrayRef[ColumnSettings()];

coerce 'RepeatedColumnSettings',
    from ArrayRef[HashRef], via { [ map { 'Google::Monitoring::Dashboard::V1::Table::TimeSeriesTable::ColumnSettings'->new($_) } @$_ ] };

declare 'MapStringColumnSettings',
    as HashRef[ColumnSettings()];

1;

__END__

=head1 NAME

Google::Monitoring::Dashboard::V1::Table::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
