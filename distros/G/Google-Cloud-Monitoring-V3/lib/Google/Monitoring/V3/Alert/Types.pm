package Google::Monitoring::V3::Alert::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'AlertPolicy',
    as InstanceOf['Google::Monitoring::V3::Alert::AlertPolicy'];

coerce 'AlertPolicy',
    from HashRef, via { 'Google::Monitoring::V3::Alert::AlertPolicy'->new($_) };

declare 'RepeatedAlertPolicy',
    as ArrayRef[AlertPolicy()];

coerce 'RepeatedAlertPolicy',
    from ArrayRef[HashRef], via { [ map { 'Google::Monitoring::V3::Alert::AlertPolicy'->new($_) } @$_ ] };

declare 'MapStringAlertPolicy',
    as HashRef[AlertPolicy()];

declare 'ConditionCombinerType',
    as (Int | Str);

declare 'Severity',
    as (Int | Str);

declare 'Documentation',
    as InstanceOf['Google::Monitoring::V3::Alert::AlertPolicy::Documentation'];

coerce 'Documentation',
    from HashRef, via { 'Google::Monitoring::V3::Alert::AlertPolicy::Documentation'->new($_) };

declare 'RepeatedDocumentation',
    as ArrayRef[Documentation()];

coerce 'RepeatedDocumentation',
    from ArrayRef[HashRef], via { [ map { 'Google::Monitoring::V3::Alert::AlertPolicy::Documentation'->new($_) } @$_ ] };

declare 'MapStringDocumentation',
    as HashRef[Documentation()];

declare 'Link',
    as InstanceOf['Google::Monitoring::V3::Alert::AlertPolicy::Documentation::Link'];

coerce 'Link',
    from HashRef, via { 'Google::Monitoring::V3::Alert::AlertPolicy::Documentation::Link'->new($_) };

declare 'RepeatedLink',
    as ArrayRef[Link()];

coerce 'RepeatedLink',
    from ArrayRef[HashRef], via { [ map { 'Google::Monitoring::V3::Alert::AlertPolicy::Documentation::Link'->new($_) } @$_ ] };

declare 'MapStringLink',
    as HashRef[Link()];

declare 'Condition',
    as InstanceOf['Google::Monitoring::V3::Alert::AlertPolicy::Condition'];

coerce 'Condition',
    from HashRef, via { 'Google::Monitoring::V3::Alert::AlertPolicy::Condition'->new($_) };

declare 'RepeatedCondition',
    as ArrayRef[Condition()];

coerce 'RepeatedCondition',
    from ArrayRef[HashRef], via { [ map { 'Google::Monitoring::V3::Alert::AlertPolicy::Condition'->new($_) } @$_ ] };

declare 'MapStringCondition',
    as HashRef[Condition()];

declare 'EvaluationMissingData',
    as (Int | Str);

declare 'Trigger',
    as InstanceOf['Google::Monitoring::V3::Alert::AlertPolicy::Condition::Trigger'];

coerce 'Trigger',
    from HashRef, via { 'Google::Monitoring::V3::Alert::AlertPolicy::Condition::Trigger'->new($_) };

declare 'RepeatedTrigger',
    as ArrayRef[Trigger()];

coerce 'RepeatedTrigger',
    from ArrayRef[HashRef], via { [ map { 'Google::Monitoring::V3::Alert::AlertPolicy::Condition::Trigger'->new($_) } @$_ ] };

declare 'MapStringTrigger',
    as HashRef[Trigger()];

declare 'MetricThreshold',
    as InstanceOf['Google::Monitoring::V3::Alert::AlertPolicy::Condition::MetricThreshold'];

coerce 'MetricThreshold',
    from HashRef, via { 'Google::Monitoring::V3::Alert::AlertPolicy::Condition::MetricThreshold'->new($_) };

declare 'RepeatedMetricThreshold',
    as ArrayRef[MetricThreshold()];

coerce 'RepeatedMetricThreshold',
    from ArrayRef[HashRef], via { [ map { 'Google::Monitoring::V3::Alert::AlertPolicy::Condition::MetricThreshold'->new($_) } @$_ ] };

declare 'MapStringMetricThreshold',
    as HashRef[MetricThreshold()];

declare 'ForecastOptions',
    as InstanceOf['Google::Monitoring::V3::Alert::AlertPolicy::Condition::MetricThreshold::ForecastOptions'];

coerce 'ForecastOptions',
    from HashRef, via { 'Google::Monitoring::V3::Alert::AlertPolicy::Condition::MetricThreshold::ForecastOptions'->new($_) };

declare 'RepeatedForecastOptions',
    as ArrayRef[ForecastOptions()];

coerce 'RepeatedForecastOptions',
    from ArrayRef[HashRef], via { [ map { 'Google::Monitoring::V3::Alert::AlertPolicy::Condition::MetricThreshold::ForecastOptions'->new($_) } @$_ ] };

declare 'MapStringForecastOptions',
    as HashRef[ForecastOptions()];

declare 'MetricAbsence',
    as InstanceOf['Google::Monitoring::V3::Alert::AlertPolicy::Condition::MetricAbsence'];

coerce 'MetricAbsence',
    from HashRef, via { 'Google::Monitoring::V3::Alert::AlertPolicy::Condition::MetricAbsence'->new($_) };

declare 'RepeatedMetricAbsence',
    as ArrayRef[MetricAbsence()];

coerce 'RepeatedMetricAbsence',
    from ArrayRef[HashRef], via { [ map { 'Google::Monitoring::V3::Alert::AlertPolicy::Condition::MetricAbsence'->new($_) } @$_ ] };

declare 'MapStringMetricAbsence',
    as HashRef[MetricAbsence()];

declare 'LogMatch',
    as InstanceOf['Google::Monitoring::V3::Alert::AlertPolicy::Condition::LogMatch'];

coerce 'LogMatch',
    from HashRef, via { 'Google::Monitoring::V3::Alert::AlertPolicy::Condition::LogMatch'->new($_) };

declare 'RepeatedLogMatch',
    as ArrayRef[LogMatch()];

coerce 'RepeatedLogMatch',
    from ArrayRef[HashRef], via { [ map { 'Google::Monitoring::V3::Alert::AlertPolicy::Condition::LogMatch'->new($_) } @$_ ] };

declare 'MapStringLogMatch',
    as HashRef[LogMatch()];

declare 'LabelExtractorsEntry',
    as InstanceOf['Google::Monitoring::V3::Alert::AlertPolicy::Condition::LogMatch::LabelExtractorsEntry'];

coerce 'LabelExtractorsEntry',
    from HashRef, via { 'Google::Monitoring::V3::Alert::AlertPolicy::Condition::LogMatch::LabelExtractorsEntry'->new($_) };

declare 'RepeatedLabelExtractorsEntry',
    as ArrayRef[LabelExtractorsEntry()];

coerce 'RepeatedLabelExtractorsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Monitoring::V3::Alert::AlertPolicy::Condition::LogMatch::LabelExtractorsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelExtractorsEntry',
    as HashRef[LabelExtractorsEntry()];

declare 'MonitoringQueryLanguageCondition',
    as InstanceOf['Google::Monitoring::V3::Alert::AlertPolicy::Condition::MonitoringQueryLanguageCondition'];

coerce 'MonitoringQueryLanguageCondition',
    from HashRef, via { 'Google::Monitoring::V3::Alert::AlertPolicy::Condition::MonitoringQueryLanguageCondition'->new($_) };

declare 'RepeatedMonitoringQueryLanguageCondition',
    as ArrayRef[MonitoringQueryLanguageCondition()];

coerce 'RepeatedMonitoringQueryLanguageCondition',
    from ArrayRef[HashRef], via { [ map { 'Google::Monitoring::V3::Alert::AlertPolicy::Condition::MonitoringQueryLanguageCondition'->new($_) } @$_ ] };

declare 'MapStringMonitoringQueryLanguageCondition',
    as HashRef[MonitoringQueryLanguageCondition()];

declare 'PrometheusQueryLanguageCondition',
    as InstanceOf['Google::Monitoring::V3::Alert::AlertPolicy::Condition::PrometheusQueryLanguageCondition'];

coerce 'PrometheusQueryLanguageCondition',
    from HashRef, via { 'Google::Monitoring::V3::Alert::AlertPolicy::Condition::PrometheusQueryLanguageCondition'->new($_) };

declare 'RepeatedPrometheusQueryLanguageCondition',
    as ArrayRef[PrometheusQueryLanguageCondition()];

coerce 'RepeatedPrometheusQueryLanguageCondition',
    from ArrayRef[HashRef], via { [ map { 'Google::Monitoring::V3::Alert::AlertPolicy::Condition::PrometheusQueryLanguageCondition'->new($_) } @$_ ] };

declare 'MapStringPrometheusQueryLanguageCondition',
    as HashRef[PrometheusQueryLanguageCondition()];

declare 'LabelsEntry',
    as InstanceOf['Google::Monitoring::V3::Alert::AlertPolicy::Condition::PrometheusQueryLanguageCondition::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Monitoring::V3::Alert::AlertPolicy::Condition::PrometheusQueryLanguageCondition::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Monitoring::V3::Alert::AlertPolicy::Condition::PrometheusQueryLanguageCondition::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'SqlCondition',
    as InstanceOf['Google::Monitoring::V3::Alert::AlertPolicy::Condition::SqlCondition'];

coerce 'SqlCondition',
    from HashRef, via { 'Google::Monitoring::V3::Alert::AlertPolicy::Condition::SqlCondition'->new($_) };

declare 'RepeatedSqlCondition',
    as ArrayRef[SqlCondition()];

coerce 'RepeatedSqlCondition',
    from ArrayRef[HashRef], via { [ map { 'Google::Monitoring::V3::Alert::AlertPolicy::Condition::SqlCondition'->new($_) } @$_ ] };

declare 'MapStringSqlCondition',
    as HashRef[SqlCondition()];

declare 'Minutes',
    as InstanceOf['Google::Monitoring::V3::Alert::AlertPolicy::Condition::SqlCondition::Minutes'];

coerce 'Minutes',
    from HashRef, via { 'Google::Monitoring::V3::Alert::AlertPolicy::Condition::SqlCondition::Minutes'->new($_) };

declare 'RepeatedMinutes',
    as ArrayRef[Minutes()];

coerce 'RepeatedMinutes',
    from ArrayRef[HashRef], via { [ map { 'Google::Monitoring::V3::Alert::AlertPolicy::Condition::SqlCondition::Minutes'->new($_) } @$_ ] };

declare 'MapStringMinutes',
    as HashRef[Minutes()];

declare 'Hourly',
    as InstanceOf['Google::Monitoring::V3::Alert::AlertPolicy::Condition::SqlCondition::Hourly'];

coerce 'Hourly',
    from HashRef, via { 'Google::Monitoring::V3::Alert::AlertPolicy::Condition::SqlCondition::Hourly'->new($_) };

declare 'RepeatedHourly',
    as ArrayRef[Hourly()];

coerce 'RepeatedHourly',
    from ArrayRef[HashRef], via { [ map { 'Google::Monitoring::V3::Alert::AlertPolicy::Condition::SqlCondition::Hourly'->new($_) } @$_ ] };

declare 'MapStringHourly',
    as HashRef[Hourly()];

declare 'Daily',
    as InstanceOf['Google::Monitoring::V3::Alert::AlertPolicy::Condition::SqlCondition::Daily'];

coerce 'Daily',
    from HashRef, via { 'Google::Monitoring::V3::Alert::AlertPolicy::Condition::SqlCondition::Daily'->new($_) };

declare 'RepeatedDaily',
    as ArrayRef[Daily()];

coerce 'RepeatedDaily',
    from ArrayRef[HashRef], via { [ map { 'Google::Monitoring::V3::Alert::AlertPolicy::Condition::SqlCondition::Daily'->new($_) } @$_ ] };

declare 'MapStringDaily',
    as HashRef[Daily()];

declare 'RowCountTest',
    as InstanceOf['Google::Monitoring::V3::Alert::AlertPolicy::Condition::SqlCondition::RowCountTest'];

coerce 'RowCountTest',
    from HashRef, via { 'Google::Monitoring::V3::Alert::AlertPolicy::Condition::SqlCondition::RowCountTest'->new($_) };

declare 'RepeatedRowCountTest',
    as ArrayRef[RowCountTest()];

coerce 'RepeatedRowCountTest',
    from ArrayRef[HashRef], via { [ map { 'Google::Monitoring::V3::Alert::AlertPolicy::Condition::SqlCondition::RowCountTest'->new($_) } @$_ ] };

declare 'MapStringRowCountTest',
    as HashRef[RowCountTest()];

declare 'BooleanTest',
    as InstanceOf['Google::Monitoring::V3::Alert::AlertPolicy::Condition::SqlCondition::BooleanTest'];

coerce 'BooleanTest',
    from HashRef, via { 'Google::Monitoring::V3::Alert::AlertPolicy::Condition::SqlCondition::BooleanTest'->new($_) };

declare 'RepeatedBooleanTest',
    as ArrayRef[BooleanTest()];

coerce 'RepeatedBooleanTest',
    from ArrayRef[HashRef], via { [ map { 'Google::Monitoring::V3::Alert::AlertPolicy::Condition::SqlCondition::BooleanTest'->new($_) } @$_ ] };

declare 'MapStringBooleanTest',
    as HashRef[BooleanTest()];

declare 'AlertStrategy',
    as InstanceOf['Google::Monitoring::V3::Alert::AlertPolicy::AlertStrategy'];

coerce 'AlertStrategy',
    from HashRef, via { 'Google::Monitoring::V3::Alert::AlertPolicy::AlertStrategy'->new($_) };

declare 'RepeatedAlertStrategy',
    as ArrayRef[AlertStrategy()];

coerce 'RepeatedAlertStrategy',
    from ArrayRef[HashRef], via { [ map { 'Google::Monitoring::V3::Alert::AlertPolicy::AlertStrategy'->new($_) } @$_ ] };

declare 'MapStringAlertStrategy',
    as HashRef[AlertStrategy()];

declare 'NotificationPrompt',
    as (Int | Str);

declare 'NotificationRateLimit',
    as InstanceOf['Google::Monitoring::V3::Alert::AlertPolicy::AlertStrategy::NotificationRateLimit'];

coerce 'NotificationRateLimit',
    from HashRef, via { 'Google::Monitoring::V3::Alert::AlertPolicy::AlertStrategy::NotificationRateLimit'->new($_) };

declare 'RepeatedNotificationRateLimit',
    as ArrayRef[NotificationRateLimit()];

coerce 'RepeatedNotificationRateLimit',
    from ArrayRef[HashRef], via { [ map { 'Google::Monitoring::V3::Alert::AlertPolicy::AlertStrategy::NotificationRateLimit'->new($_) } @$_ ] };

declare 'MapStringNotificationRateLimit',
    as HashRef[NotificationRateLimit()];

declare 'NotificationChannelStrategy',
    as InstanceOf['Google::Monitoring::V3::Alert::AlertPolicy::AlertStrategy::NotificationChannelStrategy'];

coerce 'NotificationChannelStrategy',
    from HashRef, via { 'Google::Monitoring::V3::Alert::AlertPolicy::AlertStrategy::NotificationChannelStrategy'->new($_) };

declare 'RepeatedNotificationChannelStrategy',
    as ArrayRef[NotificationChannelStrategy()];

coerce 'RepeatedNotificationChannelStrategy',
    from ArrayRef[HashRef], via { [ map { 'Google::Monitoring::V3::Alert::AlertPolicy::AlertStrategy::NotificationChannelStrategy'->new($_) } @$_ ] };

declare 'MapStringNotificationChannelStrategy',
    as HashRef[NotificationChannelStrategy()];

declare 'UserLabelsEntry',
    as InstanceOf['Google::Monitoring::V3::Alert::AlertPolicy::UserLabelsEntry'];

coerce 'UserLabelsEntry',
    from HashRef, via { 'Google::Monitoring::V3::Alert::AlertPolicy::UserLabelsEntry'->new($_) };

declare 'RepeatedUserLabelsEntry',
    as ArrayRef[UserLabelsEntry()];

coerce 'RepeatedUserLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Monitoring::V3::Alert::AlertPolicy::UserLabelsEntry'->new($_) } @$_ ] };

declare 'MapStringUserLabelsEntry',
    as HashRef[UserLabelsEntry()];

1;

__END__

=head1 NAME

Google::Monitoring::V3::Alert::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
