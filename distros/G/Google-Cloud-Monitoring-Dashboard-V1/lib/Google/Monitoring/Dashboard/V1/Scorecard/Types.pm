package Google::Monitoring::Dashboard::V1::Scorecard::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Scorecard',
    as InstanceOf['Google::Monitoring::Dashboard::V1::Scorecard::Scorecard'];

coerce 'Scorecard',
    from HashRef, via { 'Google::Monitoring::Dashboard::V1::Scorecard::Scorecard'->new($_) };

declare 'RepeatedScorecard',
    as ArrayRef[Scorecard()];

coerce 'RepeatedScorecard',
    from ArrayRef[HashRef], via { [ map { 'Google::Monitoring::Dashboard::V1::Scorecard::Scorecard'->new($_) } @$_ ] };

declare 'MapStringScorecard',
    as HashRef[Scorecard()];

declare 'GaugeView',
    as InstanceOf['Google::Monitoring::Dashboard::V1::Scorecard::Scorecard::GaugeView'];

coerce 'GaugeView',
    from HashRef, via { 'Google::Monitoring::Dashboard::V1::Scorecard::Scorecard::GaugeView'->new($_) };

declare 'RepeatedGaugeView',
    as ArrayRef[GaugeView()];

coerce 'RepeatedGaugeView',
    from ArrayRef[HashRef], via { [ map { 'Google::Monitoring::Dashboard::V1::Scorecard::Scorecard::GaugeView'->new($_) } @$_ ] };

declare 'MapStringGaugeView',
    as HashRef[GaugeView()];

declare 'SparkChartView',
    as InstanceOf['Google::Monitoring::Dashboard::V1::Scorecard::Scorecard::SparkChartView'];

coerce 'SparkChartView',
    from HashRef, via { 'Google::Monitoring::Dashboard::V1::Scorecard::Scorecard::SparkChartView'->new($_) };

declare 'RepeatedSparkChartView',
    as ArrayRef[SparkChartView()];

coerce 'RepeatedSparkChartView',
    from ArrayRef[HashRef], via { [ map { 'Google::Monitoring::Dashboard::V1::Scorecard::Scorecard::SparkChartView'->new($_) } @$_ ] };

declare 'MapStringSparkChartView',
    as HashRef[SparkChartView()];

1;

__END__

=head1 NAME

Google::Monitoring::Dashboard::V1::Scorecard::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
