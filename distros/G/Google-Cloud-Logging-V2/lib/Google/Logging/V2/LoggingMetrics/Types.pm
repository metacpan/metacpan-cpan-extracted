package Google::Logging::V2::LoggingMetrics::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'LogMetric',
    as InstanceOf['Google::Logging::V2::LoggingMetrics::LogMetric'];

coerce 'LogMetric',
    from HashRef, via { 'Google::Logging::V2::LoggingMetrics::LogMetric'->new($_) };

declare 'RepeatedLogMetric',
    as ArrayRef[LogMetric()];

coerce 'RepeatedLogMetric',
    from ArrayRef[HashRef], via { [ map { 'Google::Logging::V2::LoggingMetrics::LogMetric'->new($_) } @$_ ] };

declare 'MapStringLogMetric',
    as HashRef[LogMetric()];

declare 'ApiVersion',
    as (Int | Str);

declare 'LabelExtractorsEntry',
    as InstanceOf['Google::Logging::V2::LoggingMetrics::LogMetric::LabelExtractorsEntry'];

coerce 'LabelExtractorsEntry',
    from HashRef, via { 'Google::Logging::V2::LoggingMetrics::LogMetric::LabelExtractorsEntry'->new($_) };

declare 'RepeatedLabelExtractorsEntry',
    as ArrayRef[LabelExtractorsEntry()];

coerce 'RepeatedLabelExtractorsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Logging::V2::LoggingMetrics::LogMetric::LabelExtractorsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelExtractorsEntry',
    as HashRef[LabelExtractorsEntry()];

declare 'ListLogMetricsRequest',
    as InstanceOf['Google::Logging::V2::LoggingMetrics::ListLogMetricsRequest'];

coerce 'ListLogMetricsRequest',
    from HashRef, via { 'Google::Logging::V2::LoggingMetrics::ListLogMetricsRequest'->new($_) };

declare 'RepeatedListLogMetricsRequest',
    as ArrayRef[ListLogMetricsRequest()];

coerce 'RepeatedListLogMetricsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Logging::V2::LoggingMetrics::ListLogMetricsRequest'->new($_) } @$_ ] };

declare 'MapStringListLogMetricsRequest',
    as HashRef[ListLogMetricsRequest()];

declare 'ListLogMetricsResponse',
    as InstanceOf['Google::Logging::V2::LoggingMetrics::ListLogMetricsResponse'];

coerce 'ListLogMetricsResponse',
    from HashRef, via { 'Google::Logging::V2::LoggingMetrics::ListLogMetricsResponse'->new($_) };

declare 'RepeatedListLogMetricsResponse',
    as ArrayRef[ListLogMetricsResponse()];

coerce 'RepeatedListLogMetricsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Logging::V2::LoggingMetrics::ListLogMetricsResponse'->new($_) } @$_ ] };

declare 'MapStringListLogMetricsResponse',
    as HashRef[ListLogMetricsResponse()];

declare 'GetLogMetricRequest',
    as InstanceOf['Google::Logging::V2::LoggingMetrics::GetLogMetricRequest'];

coerce 'GetLogMetricRequest',
    from HashRef, via { 'Google::Logging::V2::LoggingMetrics::GetLogMetricRequest'->new($_) };

declare 'RepeatedGetLogMetricRequest',
    as ArrayRef[GetLogMetricRequest()];

coerce 'RepeatedGetLogMetricRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Logging::V2::LoggingMetrics::GetLogMetricRequest'->new($_) } @$_ ] };

declare 'MapStringGetLogMetricRequest',
    as HashRef[GetLogMetricRequest()];

declare 'CreateLogMetricRequest',
    as InstanceOf['Google::Logging::V2::LoggingMetrics::CreateLogMetricRequest'];

coerce 'CreateLogMetricRequest',
    from HashRef, via { 'Google::Logging::V2::LoggingMetrics::CreateLogMetricRequest'->new($_) };

declare 'RepeatedCreateLogMetricRequest',
    as ArrayRef[CreateLogMetricRequest()];

coerce 'RepeatedCreateLogMetricRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Logging::V2::LoggingMetrics::CreateLogMetricRequest'->new($_) } @$_ ] };

declare 'MapStringCreateLogMetricRequest',
    as HashRef[CreateLogMetricRequest()];

declare 'UpdateLogMetricRequest',
    as InstanceOf['Google::Logging::V2::LoggingMetrics::UpdateLogMetricRequest'];

coerce 'UpdateLogMetricRequest',
    from HashRef, via { 'Google::Logging::V2::LoggingMetrics::UpdateLogMetricRequest'->new($_) };

declare 'RepeatedUpdateLogMetricRequest',
    as ArrayRef[UpdateLogMetricRequest()];

coerce 'RepeatedUpdateLogMetricRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Logging::V2::LoggingMetrics::UpdateLogMetricRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateLogMetricRequest',
    as HashRef[UpdateLogMetricRequest()];

declare 'DeleteLogMetricRequest',
    as InstanceOf['Google::Logging::V2::LoggingMetrics::DeleteLogMetricRequest'];

coerce 'DeleteLogMetricRequest',
    from HashRef, via { 'Google::Logging::V2::LoggingMetrics::DeleteLogMetricRequest'->new($_) };

declare 'RepeatedDeleteLogMetricRequest',
    as ArrayRef[DeleteLogMetricRequest()];

coerce 'RepeatedDeleteLogMetricRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Logging::V2::LoggingMetrics::DeleteLogMetricRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteLogMetricRequest',
    as HashRef[DeleteLogMetricRequest()];

1;

__END__

=head1 NAME

Google::Logging::V2::LoggingMetrics::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
