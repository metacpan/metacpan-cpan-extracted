package Google::Monitoring::Dashboard::V1::Piechart::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'PieChart',
    as InstanceOf['Google::Monitoring::Dashboard::V1::Piechart::PieChart'];

coerce 'PieChart',
    from HashRef, via { 'Google::Monitoring::Dashboard::V1::Piechart::PieChart'->new($_) };

declare 'RepeatedPieChart',
    as ArrayRef[PieChart()];

coerce 'RepeatedPieChart',
    from ArrayRef[HashRef], via { [ map { 'Google::Monitoring::Dashboard::V1::Piechart::PieChart'->new($_) } @$_ ] };

declare 'MapStringPieChart',
    as HashRef[PieChart()];

declare 'PieChartType',
    as (Int | Str);

declare 'PieChartDataSet',
    as InstanceOf['Google::Monitoring::Dashboard::V1::Piechart::PieChart::PieChartDataSet'];

coerce 'PieChartDataSet',
    from HashRef, via { 'Google::Monitoring::Dashboard::V1::Piechart::PieChart::PieChartDataSet'->new($_) };

declare 'RepeatedPieChartDataSet',
    as ArrayRef[PieChartDataSet()];

coerce 'RepeatedPieChartDataSet',
    from ArrayRef[HashRef], via { [ map { 'Google::Monitoring::Dashboard::V1::Piechart::PieChart::PieChartDataSet'->new($_) } @$_ ] };

declare 'MapStringPieChartDataSet',
    as HashRef[PieChartDataSet()];

1;

__END__

=head1 NAME

Google::Monitoring::Dashboard::V1::Piechart::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
