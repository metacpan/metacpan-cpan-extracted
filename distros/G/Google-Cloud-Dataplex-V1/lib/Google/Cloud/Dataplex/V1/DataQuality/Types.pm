package Google::Cloud::Dataplex::V1::DataQuality::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'DataQualitySpec',
    as InstanceOf['Google::Cloud::Dataplex::V1::DataQuality::DataQualitySpec'];

coerce 'DataQualitySpec',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::DataQuality::DataQualitySpec'->new($_) };

declare 'RepeatedDataQualitySpec',
    as ArrayRef[DataQualitySpec()];

coerce 'RepeatedDataQualitySpec',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::DataQuality::DataQualitySpec'->new($_) } @$_ ] };

declare 'MapStringDataQualitySpec',
    as HashRef[DataQualitySpec()];

declare 'PostScanActions',
    as InstanceOf['Google::Cloud::Dataplex::V1::DataQuality::DataQualitySpec::PostScanActions'];

coerce 'PostScanActions',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::DataQuality::DataQualitySpec::PostScanActions'->new($_) };

declare 'RepeatedPostScanActions',
    as ArrayRef[PostScanActions()];

coerce 'RepeatedPostScanActions',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::DataQuality::DataQualitySpec::PostScanActions'->new($_) } @$_ ] };

declare 'MapStringPostScanActions',
    as HashRef[PostScanActions()];

declare 'BigQueryExport',
    as InstanceOf['Google::Cloud::Dataplex::V1::DataQuality::DataQualitySpec::PostScanActions::BigQueryExport'];

coerce 'BigQueryExport',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::DataQuality::DataQualitySpec::PostScanActions::BigQueryExport'->new($_) };

declare 'RepeatedBigQueryExport',
    as ArrayRef[BigQueryExport()];

coerce 'RepeatedBigQueryExport',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::DataQuality::DataQualitySpec::PostScanActions::BigQueryExport'->new($_) } @$_ ] };

declare 'MapStringBigQueryExport',
    as HashRef[BigQueryExport()];

declare 'Recipients',
    as InstanceOf['Google::Cloud::Dataplex::V1::DataQuality::DataQualitySpec::PostScanActions::Recipients'];

coerce 'Recipients',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::DataQuality::DataQualitySpec::PostScanActions::Recipients'->new($_) };

declare 'RepeatedRecipients',
    as ArrayRef[Recipients()];

coerce 'RepeatedRecipients',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::DataQuality::DataQualitySpec::PostScanActions::Recipients'->new($_) } @$_ ] };

declare 'MapStringRecipients',
    as HashRef[Recipients()];

declare 'ScoreThresholdTrigger',
    as InstanceOf['Google::Cloud::Dataplex::V1::DataQuality::DataQualitySpec::PostScanActions::ScoreThresholdTrigger'];

coerce 'ScoreThresholdTrigger',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::DataQuality::DataQualitySpec::PostScanActions::ScoreThresholdTrigger'->new($_) };

declare 'RepeatedScoreThresholdTrigger',
    as ArrayRef[ScoreThresholdTrigger()];

coerce 'RepeatedScoreThresholdTrigger',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::DataQuality::DataQualitySpec::PostScanActions::ScoreThresholdTrigger'->new($_) } @$_ ] };

declare 'MapStringScoreThresholdTrigger',
    as HashRef[ScoreThresholdTrigger()];

declare 'JobFailureTrigger',
    as InstanceOf['Google::Cloud::Dataplex::V1::DataQuality::DataQualitySpec::PostScanActions::JobFailureTrigger'];

coerce 'JobFailureTrigger',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::DataQuality::DataQualitySpec::PostScanActions::JobFailureTrigger'->new($_) };

declare 'RepeatedJobFailureTrigger',
    as ArrayRef[JobFailureTrigger()];

coerce 'RepeatedJobFailureTrigger',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::DataQuality::DataQualitySpec::PostScanActions::JobFailureTrigger'->new($_) } @$_ ] };

declare 'MapStringJobFailureTrigger',
    as HashRef[JobFailureTrigger()];

declare 'JobEndTrigger',
    as InstanceOf['Google::Cloud::Dataplex::V1::DataQuality::DataQualitySpec::PostScanActions::JobEndTrigger'];

coerce 'JobEndTrigger',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::DataQuality::DataQualitySpec::PostScanActions::JobEndTrigger'->new($_) };

declare 'RepeatedJobEndTrigger',
    as ArrayRef[JobEndTrigger()];

coerce 'RepeatedJobEndTrigger',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::DataQuality::DataQualitySpec::PostScanActions::JobEndTrigger'->new($_) } @$_ ] };

declare 'MapStringJobEndTrigger',
    as HashRef[JobEndTrigger()];

declare 'NotificationReport',
    as InstanceOf['Google::Cloud::Dataplex::V1::DataQuality::DataQualitySpec::PostScanActions::NotificationReport'];

coerce 'NotificationReport',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::DataQuality::DataQualitySpec::PostScanActions::NotificationReport'->new($_) };

declare 'RepeatedNotificationReport',
    as ArrayRef[NotificationReport()];

coerce 'RepeatedNotificationReport',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::DataQuality::DataQualitySpec::PostScanActions::NotificationReport'->new($_) } @$_ ] };

declare 'MapStringNotificationReport',
    as HashRef[NotificationReport()];

declare 'DataQualityResult',
    as InstanceOf['Google::Cloud::Dataplex::V1::DataQuality::DataQualityResult'];

coerce 'DataQualityResult',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::DataQuality::DataQualityResult'->new($_) };

declare 'RepeatedDataQualityResult',
    as ArrayRef[DataQualityResult()];

coerce 'RepeatedDataQualityResult',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::DataQuality::DataQualityResult'->new($_) } @$_ ] };

declare 'MapStringDataQualityResult',
    as HashRef[DataQualityResult()];

declare 'PostScanActionsResult',
    as InstanceOf['Google::Cloud::Dataplex::V1::DataQuality::DataQualityResult::PostScanActionsResult'];

coerce 'PostScanActionsResult',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::DataQuality::DataQualityResult::PostScanActionsResult'->new($_) };

declare 'RepeatedPostScanActionsResult',
    as ArrayRef[PostScanActionsResult()];

coerce 'RepeatedPostScanActionsResult',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::DataQuality::DataQualityResult::PostScanActionsResult'->new($_) } @$_ ] };

declare 'MapStringPostScanActionsResult',
    as HashRef[PostScanActionsResult()];

declare 'BigQueryExportResult',
    as InstanceOf['Google::Cloud::Dataplex::V1::DataQuality::DataQualityResult::PostScanActionsResult::BigQueryExportResult'];

coerce 'BigQueryExportResult',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::DataQuality::DataQualityResult::PostScanActionsResult::BigQueryExportResult'->new($_) };

declare 'RepeatedBigQueryExportResult',
    as ArrayRef[BigQueryExportResult()];

coerce 'RepeatedBigQueryExportResult',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::DataQuality::DataQualityResult::PostScanActionsResult::BigQueryExportResult'->new($_) } @$_ ] };

declare 'MapStringBigQueryExportResult',
    as HashRef[BigQueryExportResult()];

declare 'State',
    as (Int | Str);

declare 'AnomalyDetectionGeneratedAssets',
    as InstanceOf['Google::Cloud::Dataplex::V1::DataQuality::DataQualityResult::AnomalyDetectionGeneratedAssets'];

coerce 'AnomalyDetectionGeneratedAssets',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::DataQuality::DataQualityResult::AnomalyDetectionGeneratedAssets'->new($_) };

declare 'RepeatedAnomalyDetectionGeneratedAssets',
    as ArrayRef[AnomalyDetectionGeneratedAssets()];

coerce 'RepeatedAnomalyDetectionGeneratedAssets',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::DataQuality::DataQualityResult::AnomalyDetectionGeneratedAssets'->new($_) } @$_ ] };

declare 'MapStringAnomalyDetectionGeneratedAssets',
    as HashRef[AnomalyDetectionGeneratedAssets()];

declare 'DataQualityRuleResult',
    as InstanceOf['Google::Cloud::Dataplex::V1::DataQuality::DataQualityRuleResult'];

coerce 'DataQualityRuleResult',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::DataQuality::DataQualityRuleResult'->new($_) };

declare 'RepeatedDataQualityRuleResult',
    as ArrayRef[DataQualityRuleResult()];

coerce 'RepeatedDataQualityRuleResult',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::DataQuality::DataQualityRuleResult'->new($_) } @$_ ] };

declare 'MapStringDataQualityRuleResult',
    as HashRef[DataQualityRuleResult()];

declare 'DebugQueryResult',
    as InstanceOf['Google::Cloud::Dataplex::V1::DataQuality::DataQualityRuleResult::DebugQueryResult'];

coerce 'DebugQueryResult',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::DataQuality::DataQualityRuleResult::DebugQueryResult'->new($_) };

declare 'RepeatedDebugQueryResult',
    as ArrayRef[DebugQueryResult()];

coerce 'RepeatedDebugQueryResult',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::DataQuality::DataQualityRuleResult::DebugQueryResult'->new($_) } @$_ ] };

declare 'MapStringDebugQueryResult',
    as HashRef[DebugQueryResult()];

declare 'DebugQueryResultSet',
    as InstanceOf['Google::Cloud::Dataplex::V1::DataQuality::DataQualityRuleResult::DebugQueryResultSet'];

coerce 'DebugQueryResultSet',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::DataQuality::DataQualityRuleResult::DebugQueryResultSet'->new($_) };

declare 'RepeatedDebugQueryResultSet',
    as ArrayRef[DebugQueryResultSet()];

coerce 'RepeatedDebugQueryResultSet',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::DataQuality::DataQualityRuleResult::DebugQueryResultSet'->new($_) } @$_ ] };

declare 'MapStringDebugQueryResultSet',
    as HashRef[DebugQueryResultSet()];

declare 'DataQualityDimensionResult',
    as InstanceOf['Google::Cloud::Dataplex::V1::DataQuality::DataQualityDimensionResult'];

coerce 'DataQualityDimensionResult',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::DataQuality::DataQualityDimensionResult'->new($_) };

declare 'RepeatedDataQualityDimensionResult',
    as ArrayRef[DataQualityDimensionResult()];

coerce 'RepeatedDataQualityDimensionResult',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::DataQuality::DataQualityDimensionResult'->new($_) } @$_ ] };

declare 'MapStringDataQualityDimensionResult',
    as HashRef[DataQualityDimensionResult()];

declare 'DataQualityDimension',
    as InstanceOf['Google::Cloud::Dataplex::V1::DataQuality::DataQualityDimension'];

coerce 'DataQualityDimension',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::DataQuality::DataQualityDimension'->new($_) };

declare 'RepeatedDataQualityDimension',
    as ArrayRef[DataQualityDimension()];

coerce 'RepeatedDataQualityDimension',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::DataQuality::DataQualityDimension'->new($_) } @$_ ] };

declare 'MapStringDataQualityDimension',
    as HashRef[DataQualityDimension()];

declare 'DataQualityRule',
    as InstanceOf['Google::Cloud::Dataplex::V1::DataQuality::DataQualityRule'];

coerce 'DataQualityRule',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::DataQuality::DataQualityRule'->new($_) };

declare 'RepeatedDataQualityRule',
    as ArrayRef[DataQualityRule()];

coerce 'RepeatedDataQualityRule',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::DataQuality::DataQualityRule'->new($_) } @$_ ] };

declare 'MapStringDataQualityRule',
    as HashRef[DataQualityRule()];

declare 'RangeExpectation',
    as InstanceOf['Google::Cloud::Dataplex::V1::DataQuality::DataQualityRule::RangeExpectation'];

coerce 'RangeExpectation',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::DataQuality::DataQualityRule::RangeExpectation'->new($_) };

declare 'RepeatedRangeExpectation',
    as ArrayRef[RangeExpectation()];

coerce 'RepeatedRangeExpectation',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::DataQuality::DataQualityRule::RangeExpectation'->new($_) } @$_ ] };

declare 'MapStringRangeExpectation',
    as HashRef[RangeExpectation()];

declare 'NonNullExpectation',
    as InstanceOf['Google::Cloud::Dataplex::V1::DataQuality::DataQualityRule::NonNullExpectation'];

coerce 'NonNullExpectation',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::DataQuality::DataQualityRule::NonNullExpectation'->new($_) };

declare 'RepeatedNonNullExpectation',
    as ArrayRef[NonNullExpectation()];

coerce 'RepeatedNonNullExpectation',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::DataQuality::DataQualityRule::NonNullExpectation'->new($_) } @$_ ] };

declare 'MapStringNonNullExpectation',
    as HashRef[NonNullExpectation()];

declare 'SetExpectation',
    as InstanceOf['Google::Cloud::Dataplex::V1::DataQuality::DataQualityRule::SetExpectation'];

coerce 'SetExpectation',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::DataQuality::DataQualityRule::SetExpectation'->new($_) };

declare 'RepeatedSetExpectation',
    as ArrayRef[SetExpectation()];

coerce 'RepeatedSetExpectation',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::DataQuality::DataQualityRule::SetExpectation'->new($_) } @$_ ] };

declare 'MapStringSetExpectation',
    as HashRef[SetExpectation()];

declare 'RegexExpectation',
    as InstanceOf['Google::Cloud::Dataplex::V1::DataQuality::DataQualityRule::RegexExpectation'];

coerce 'RegexExpectation',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::DataQuality::DataQualityRule::RegexExpectation'->new($_) };

declare 'RepeatedRegexExpectation',
    as ArrayRef[RegexExpectation()];

coerce 'RepeatedRegexExpectation',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::DataQuality::DataQualityRule::RegexExpectation'->new($_) } @$_ ] };

declare 'MapStringRegexExpectation',
    as HashRef[RegexExpectation()];

declare 'UniquenessExpectation',
    as InstanceOf['Google::Cloud::Dataplex::V1::DataQuality::DataQualityRule::UniquenessExpectation'];

coerce 'UniquenessExpectation',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::DataQuality::DataQualityRule::UniquenessExpectation'->new($_) };

declare 'RepeatedUniquenessExpectation',
    as ArrayRef[UniquenessExpectation()];

coerce 'RepeatedUniquenessExpectation',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::DataQuality::DataQualityRule::UniquenessExpectation'->new($_) } @$_ ] };

declare 'MapStringUniquenessExpectation',
    as HashRef[UniquenessExpectation()];

declare 'StatisticRangeExpectation',
    as InstanceOf['Google::Cloud::Dataplex::V1::DataQuality::DataQualityRule::StatisticRangeExpectation'];

coerce 'StatisticRangeExpectation',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::DataQuality::DataQualityRule::StatisticRangeExpectation'->new($_) };

declare 'RepeatedStatisticRangeExpectation',
    as ArrayRef[StatisticRangeExpectation()];

coerce 'RepeatedStatisticRangeExpectation',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::DataQuality::DataQualityRule::StatisticRangeExpectation'->new($_) } @$_ ] };

declare 'MapStringStatisticRangeExpectation',
    as HashRef[StatisticRangeExpectation()];

declare 'ColumnStatistic',
    as (Int | Str);

declare 'RowConditionExpectation',
    as InstanceOf['Google::Cloud::Dataplex::V1::DataQuality::DataQualityRule::RowConditionExpectation'];

coerce 'RowConditionExpectation',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::DataQuality::DataQualityRule::RowConditionExpectation'->new($_) };

declare 'RepeatedRowConditionExpectation',
    as ArrayRef[RowConditionExpectation()];

coerce 'RepeatedRowConditionExpectation',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::DataQuality::DataQualityRule::RowConditionExpectation'->new($_) } @$_ ] };

declare 'MapStringRowConditionExpectation',
    as HashRef[RowConditionExpectation()];

declare 'TableConditionExpectation',
    as InstanceOf['Google::Cloud::Dataplex::V1::DataQuality::DataQualityRule::TableConditionExpectation'];

coerce 'TableConditionExpectation',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::DataQuality::DataQualityRule::TableConditionExpectation'->new($_) };

declare 'RepeatedTableConditionExpectation',
    as ArrayRef[TableConditionExpectation()];

coerce 'RepeatedTableConditionExpectation',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::DataQuality::DataQualityRule::TableConditionExpectation'->new($_) } @$_ ] };

declare 'MapStringTableConditionExpectation',
    as HashRef[TableConditionExpectation()];

declare 'SqlAssertion',
    as InstanceOf['Google::Cloud::Dataplex::V1::DataQuality::DataQualityRule::SqlAssertion'];

coerce 'SqlAssertion',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::DataQuality::DataQualityRule::SqlAssertion'->new($_) };

declare 'RepeatedSqlAssertion',
    as ArrayRef[SqlAssertion()];

coerce 'RepeatedSqlAssertion',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::DataQuality::DataQualityRule::SqlAssertion'->new($_) } @$_ ] };

declare 'MapStringSqlAssertion',
    as HashRef[SqlAssertion()];

declare 'TemplateReference',
    as InstanceOf['Google::Cloud::Dataplex::V1::DataQuality::DataQualityRule::TemplateReference'];

coerce 'TemplateReference',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::DataQuality::DataQualityRule::TemplateReference'->new($_) };

declare 'RepeatedTemplateReference',
    as ArrayRef[TemplateReference()];

coerce 'RepeatedTemplateReference',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::DataQuality::DataQualityRule::TemplateReference'->new($_) } @$_ ] };

declare 'MapStringTemplateReference',
    as HashRef[TemplateReference()];

declare 'ParameterValue',
    as InstanceOf['Google::Cloud::Dataplex::V1::DataQuality::DataQualityRule::TemplateReference::ParameterValue'];

coerce 'ParameterValue',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::DataQuality::DataQualityRule::TemplateReference::ParameterValue'->new($_) };

declare 'RepeatedParameterValue',
    as ArrayRef[ParameterValue()];

coerce 'RepeatedParameterValue',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::DataQuality::DataQualityRule::TemplateReference::ParameterValue'->new($_) } @$_ ] };

declare 'MapStringParameterValue',
    as HashRef[ParameterValue()];

declare 'ValuesEntry',
    as InstanceOf['Google::Cloud::Dataplex::V1::DataQuality::DataQualityRule::TemplateReference::ValuesEntry'];

coerce 'ValuesEntry',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::DataQuality::DataQualityRule::TemplateReference::ValuesEntry'->new($_) };

declare 'RepeatedValuesEntry',
    as ArrayRef[ValuesEntry()];

coerce 'RepeatedValuesEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::DataQuality::DataQualityRule::TemplateReference::ValuesEntry'->new($_) } @$_ ] };

declare 'MapStringValuesEntry',
    as HashRef[ValuesEntry()];

declare 'RuleSource',
    as InstanceOf['Google::Cloud::Dataplex::V1::DataQuality::DataQualityRule::RuleSource'];

coerce 'RuleSource',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::DataQuality::DataQualityRule::RuleSource'->new($_) };

declare 'RepeatedRuleSource',
    as ArrayRef[RuleSource()];

coerce 'RepeatedRuleSource',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::DataQuality::DataQualityRule::RuleSource'->new($_) } @$_ ] };

declare 'MapStringRuleSource',
    as HashRef[RuleSource()];

declare 'RulePathElement',
    as InstanceOf['Google::Cloud::Dataplex::V1::DataQuality::DataQualityRule::RuleSource::RulePathElement'];

coerce 'RulePathElement',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::DataQuality::DataQualityRule::RuleSource::RulePathElement'->new($_) };

declare 'RepeatedRulePathElement',
    as ArrayRef[RulePathElement()];

coerce 'RepeatedRulePathElement',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::DataQuality::DataQualityRule::RuleSource::RulePathElement'->new($_) } @$_ ] };

declare 'MapStringRulePathElement',
    as HashRef[RulePathElement()];

declare 'EntrySource',
    as InstanceOf['Google::Cloud::Dataplex::V1::DataQuality::DataQualityRule::RuleSource::RulePathElement::EntrySource'];

coerce 'EntrySource',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::DataQuality::DataQualityRule::RuleSource::RulePathElement::EntrySource'->new($_) };

declare 'RepeatedEntrySource',
    as ArrayRef[EntrySource()];

coerce 'RepeatedEntrySource',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::DataQuality::DataQualityRule::RuleSource::RulePathElement::EntrySource'->new($_) } @$_ ] };

declare 'MapStringEntrySource',
    as HashRef[EntrySource()];

declare 'EntryLinkSource',
    as InstanceOf['Google::Cloud::Dataplex::V1::DataQuality::DataQualityRule::RuleSource::RulePathElement::EntryLinkSource'];

coerce 'EntryLinkSource',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::DataQuality::DataQualityRule::RuleSource::RulePathElement::EntryLinkSource'->new($_) };

declare 'RepeatedEntryLinkSource',
    as ArrayRef[EntryLinkSource()];

coerce 'RepeatedEntryLinkSource',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::DataQuality::DataQualityRule::RuleSource::RulePathElement::EntryLinkSource'->new($_) } @$_ ] };

declare 'MapStringEntryLinkSource',
    as HashRef[EntryLinkSource()];

declare 'DebugQuery',
    as InstanceOf['Google::Cloud::Dataplex::V1::DataQuality::DataQualityRule::DebugQuery'];

coerce 'DebugQuery',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::DataQuality::DataQualityRule::DebugQuery'->new($_) };

declare 'RepeatedDebugQuery',
    as ArrayRef[DebugQuery()];

coerce 'RepeatedDebugQuery',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::DataQuality::DataQualityRule::DebugQuery'->new($_) } @$_ ] };

declare 'MapStringDebugQuery',
    as HashRef[DebugQuery()];

declare 'AttributesEntry',
    as InstanceOf['Google::Cloud::Dataplex::V1::DataQuality::DataQualityRule::AttributesEntry'];

coerce 'AttributesEntry',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::DataQuality::DataQualityRule::AttributesEntry'->new($_) };

declare 'RepeatedAttributesEntry',
    as ArrayRef[AttributesEntry()];

coerce 'RepeatedAttributesEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::DataQuality::DataQualityRule::AttributesEntry'->new($_) } @$_ ] };

declare 'MapStringAttributesEntry',
    as HashRef[AttributesEntry()];

declare 'DataQualityColumnResult',
    as InstanceOf['Google::Cloud::Dataplex::V1::DataQuality::DataQualityColumnResult'];

coerce 'DataQualityColumnResult',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::DataQuality::DataQualityColumnResult'->new($_) };

declare 'RepeatedDataQualityColumnResult',
    as ArrayRef[DataQualityColumnResult()];

coerce 'RepeatedDataQualityColumnResult',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::DataQuality::DataQualityColumnResult'->new($_) } @$_ ] };

declare 'MapStringDataQualityColumnResult',
    as HashRef[DataQualityColumnResult()];

1;

__END__

=head1 NAME

Google::Cloud::Dataplex::V1::DataQuality::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
