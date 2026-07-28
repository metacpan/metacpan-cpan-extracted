package Google::Cloud::Dataplex::V1::Logs::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'DiscoveryEvent',
    as InstanceOf['Google::Cloud::Dataplex::V1::Logs::DiscoveryEvent'];

coerce 'DiscoveryEvent',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Logs::DiscoveryEvent'->new($_) };

declare 'RepeatedDiscoveryEvent',
    as ArrayRef[DiscoveryEvent()];

coerce 'RepeatedDiscoveryEvent',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Logs::DiscoveryEvent'->new($_) } @$_ ] };

declare 'MapStringDiscoveryEvent',
    as HashRef[DiscoveryEvent()];

declare 'EventType',
    as (Int | Str);

declare 'EntityType',
    as (Int | Str);

declare 'TableType',
    as (Int | Str);

declare 'ConfigDetails',
    as InstanceOf['Google::Cloud::Dataplex::V1::Logs::DiscoveryEvent::ConfigDetails'];

coerce 'ConfigDetails',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Logs::DiscoveryEvent::ConfigDetails'->new($_) };

declare 'RepeatedConfigDetails',
    as ArrayRef[ConfigDetails()];

coerce 'RepeatedConfigDetails',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Logs::DiscoveryEvent::ConfigDetails'->new($_) } @$_ ] };

declare 'MapStringConfigDetails',
    as HashRef[ConfigDetails()];

declare 'ParametersEntry',
    as InstanceOf['Google::Cloud::Dataplex::V1::Logs::DiscoveryEvent::ConfigDetails::ParametersEntry'];

coerce 'ParametersEntry',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Logs::DiscoveryEvent::ConfigDetails::ParametersEntry'->new($_) };

declare 'RepeatedParametersEntry',
    as ArrayRef[ParametersEntry()];

coerce 'RepeatedParametersEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Logs::DiscoveryEvent::ConfigDetails::ParametersEntry'->new($_) } @$_ ] };

declare 'MapStringParametersEntry',
    as HashRef[ParametersEntry()];

declare 'EntityDetails',
    as InstanceOf['Google::Cloud::Dataplex::V1::Logs::DiscoveryEvent::EntityDetails'];

coerce 'EntityDetails',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Logs::DiscoveryEvent::EntityDetails'->new($_) };

declare 'RepeatedEntityDetails',
    as ArrayRef[EntityDetails()];

coerce 'RepeatedEntityDetails',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Logs::DiscoveryEvent::EntityDetails'->new($_) } @$_ ] };

declare 'MapStringEntityDetails',
    as HashRef[EntityDetails()];

declare 'TableDetails',
    as InstanceOf['Google::Cloud::Dataplex::V1::Logs::DiscoveryEvent::TableDetails'];

coerce 'TableDetails',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Logs::DiscoveryEvent::TableDetails'->new($_) };

declare 'RepeatedTableDetails',
    as ArrayRef[TableDetails()];

coerce 'RepeatedTableDetails',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Logs::DiscoveryEvent::TableDetails'->new($_) } @$_ ] };

declare 'MapStringTableDetails',
    as HashRef[TableDetails()];

declare 'PartitionDetails',
    as InstanceOf['Google::Cloud::Dataplex::V1::Logs::DiscoveryEvent::PartitionDetails'];

coerce 'PartitionDetails',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Logs::DiscoveryEvent::PartitionDetails'->new($_) };

declare 'RepeatedPartitionDetails',
    as ArrayRef[PartitionDetails()];

coerce 'RepeatedPartitionDetails',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Logs::DiscoveryEvent::PartitionDetails'->new($_) } @$_ ] };

declare 'MapStringPartitionDetails',
    as HashRef[PartitionDetails()];

declare 'ActionDetails',
    as InstanceOf['Google::Cloud::Dataplex::V1::Logs::DiscoveryEvent::ActionDetails'];

coerce 'ActionDetails',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Logs::DiscoveryEvent::ActionDetails'->new($_) };

declare 'RepeatedActionDetails',
    as ArrayRef[ActionDetails()];

coerce 'RepeatedActionDetails',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Logs::DiscoveryEvent::ActionDetails'->new($_) } @$_ ] };

declare 'MapStringActionDetails',
    as HashRef[ActionDetails()];

declare 'JobEvent',
    as InstanceOf['Google::Cloud::Dataplex::V1::Logs::JobEvent'];

coerce 'JobEvent',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Logs::JobEvent'->new($_) };

declare 'RepeatedJobEvent',
    as ArrayRef[JobEvent()];

coerce 'RepeatedJobEvent',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Logs::JobEvent'->new($_) } @$_ ] };

declare 'MapStringJobEvent',
    as HashRef[JobEvent()];

declare 'Type',
    as (Int | Str);

declare 'State',
    as (Int | Str);

declare 'Service',
    as (Int | Str);

declare 'ExecutionTrigger',
    as (Int | Str);

declare 'SessionEvent',
    as InstanceOf['Google::Cloud::Dataplex::V1::Logs::SessionEvent'];

coerce 'SessionEvent',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Logs::SessionEvent'->new($_) };

declare 'RepeatedSessionEvent',
    as ArrayRef[SessionEvent()];

coerce 'RepeatedSessionEvent',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Logs::SessionEvent'->new($_) } @$_ ] };

declare 'MapStringSessionEvent',
    as HashRef[SessionEvent()];

declare 'EventType',
    as (Int | Str);

declare 'QueryDetail',
    as InstanceOf['Google::Cloud::Dataplex::V1::Logs::SessionEvent::QueryDetail'];

coerce 'QueryDetail',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Logs::SessionEvent::QueryDetail'->new($_) };

declare 'RepeatedQueryDetail',
    as ArrayRef[QueryDetail()];

coerce 'RepeatedQueryDetail',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Logs::SessionEvent::QueryDetail'->new($_) } @$_ ] };

declare 'MapStringQueryDetail',
    as HashRef[QueryDetail()];

declare 'Engine',
    as (Int | Str);

declare 'GovernanceEvent',
    as InstanceOf['Google::Cloud::Dataplex::V1::Logs::GovernanceEvent'];

coerce 'GovernanceEvent',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Logs::GovernanceEvent'->new($_) };

declare 'RepeatedGovernanceEvent',
    as ArrayRef[GovernanceEvent()];

coerce 'RepeatedGovernanceEvent',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Logs::GovernanceEvent'->new($_) } @$_ ] };

declare 'MapStringGovernanceEvent',
    as HashRef[GovernanceEvent()];

declare 'EventType',
    as (Int | Str);

declare 'Entity',
    as InstanceOf['Google::Cloud::Dataplex::V1::Logs::GovernanceEvent::Entity'];

coerce 'Entity',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Logs::GovernanceEvent::Entity'->new($_) };

declare 'RepeatedEntity',
    as ArrayRef[Entity()];

coerce 'RepeatedEntity',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Logs::GovernanceEvent::Entity'->new($_) } @$_ ] };

declare 'MapStringEntity',
    as HashRef[Entity()];

declare 'EntityType',
    as (Int | Str);

declare 'DataScanEvent',
    as InstanceOf['Google::Cloud::Dataplex::V1::Logs::DataScanEvent'];

coerce 'DataScanEvent',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Logs::DataScanEvent'->new($_) };

declare 'RepeatedDataScanEvent',
    as ArrayRef[DataScanEvent()];

coerce 'RepeatedDataScanEvent',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Logs::DataScanEvent'->new($_) } @$_ ] };

declare 'MapStringDataScanEvent',
    as HashRef[DataScanEvent()];

declare 'ScanType',
    as (Int | Str);

declare 'State',
    as (Int | Str);

declare 'Trigger',
    as (Int | Str);

declare 'Scope',
    as (Int | Str);

declare 'DataProfileResult',
    as InstanceOf['Google::Cloud::Dataplex::V1::Logs::DataScanEvent::DataProfileResult'];

coerce 'DataProfileResult',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Logs::DataScanEvent::DataProfileResult'->new($_) };

declare 'RepeatedDataProfileResult',
    as ArrayRef[DataProfileResult()];

coerce 'RepeatedDataProfileResult',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Logs::DataScanEvent::DataProfileResult'->new($_) } @$_ ] };

declare 'MapStringDataProfileResult',
    as HashRef[DataProfileResult()];

declare 'DataQualityResult',
    as InstanceOf['Google::Cloud::Dataplex::V1::Logs::DataScanEvent::DataQualityResult'];

coerce 'DataQualityResult',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Logs::DataScanEvent::DataQualityResult'->new($_) };

declare 'RepeatedDataQualityResult',
    as ArrayRef[DataQualityResult()];

coerce 'RepeatedDataQualityResult',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Logs::DataScanEvent::DataQualityResult'->new($_) } @$_ ] };

declare 'MapStringDataQualityResult',
    as HashRef[DataQualityResult()];

declare 'DimensionPassedEntry',
    as InstanceOf['Google::Cloud::Dataplex::V1::Logs::DataScanEvent::DataQualityResult::DimensionPassedEntry'];

coerce 'DimensionPassedEntry',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Logs::DataScanEvent::DataQualityResult::DimensionPassedEntry'->new($_) };

declare 'RepeatedDimensionPassedEntry',
    as ArrayRef[DimensionPassedEntry()];

coerce 'RepeatedDimensionPassedEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Logs::DataScanEvent::DataQualityResult::DimensionPassedEntry'->new($_) } @$_ ] };

declare 'MapStringDimensionPassedEntry',
    as HashRef[DimensionPassedEntry()];

declare 'DimensionScoreEntry',
    as InstanceOf['Google::Cloud::Dataplex::V1::Logs::DataScanEvent::DataQualityResult::DimensionScoreEntry'];

coerce 'DimensionScoreEntry',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Logs::DataScanEvent::DataQualityResult::DimensionScoreEntry'->new($_) };

declare 'RepeatedDimensionScoreEntry',
    as ArrayRef[DimensionScoreEntry()];

coerce 'RepeatedDimensionScoreEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Logs::DataScanEvent::DataQualityResult::DimensionScoreEntry'->new($_) } @$_ ] };

declare 'MapStringDimensionScoreEntry',
    as HashRef[DimensionScoreEntry()];

declare 'ColumnScoreEntry',
    as InstanceOf['Google::Cloud::Dataplex::V1::Logs::DataScanEvent::DataQualityResult::ColumnScoreEntry'];

coerce 'ColumnScoreEntry',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Logs::DataScanEvent::DataQualityResult::ColumnScoreEntry'->new($_) };

declare 'RepeatedColumnScoreEntry',
    as ArrayRef[ColumnScoreEntry()];

coerce 'RepeatedColumnScoreEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Logs::DataScanEvent::DataQualityResult::ColumnScoreEntry'->new($_) } @$_ ] };

declare 'MapStringColumnScoreEntry',
    as HashRef[ColumnScoreEntry()];

declare 'DataProfileAppliedConfigs',
    as InstanceOf['Google::Cloud::Dataplex::V1::Logs::DataScanEvent::DataProfileAppliedConfigs'];

coerce 'DataProfileAppliedConfigs',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Logs::DataScanEvent::DataProfileAppliedConfigs'->new($_) };

declare 'RepeatedDataProfileAppliedConfigs',
    as ArrayRef[DataProfileAppliedConfigs()];

coerce 'RepeatedDataProfileAppliedConfigs',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Logs::DataScanEvent::DataProfileAppliedConfigs'->new($_) } @$_ ] };

declare 'MapStringDataProfileAppliedConfigs',
    as HashRef[DataProfileAppliedConfigs()];

declare 'DataQualityAppliedConfigs',
    as InstanceOf['Google::Cloud::Dataplex::V1::Logs::DataScanEvent::DataQualityAppliedConfigs'];

coerce 'DataQualityAppliedConfigs',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Logs::DataScanEvent::DataQualityAppliedConfigs'->new($_) };

declare 'RepeatedDataQualityAppliedConfigs',
    as ArrayRef[DataQualityAppliedConfigs()];

coerce 'RepeatedDataQualityAppliedConfigs',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Logs::DataScanEvent::DataQualityAppliedConfigs'->new($_) } @$_ ] };

declare 'MapStringDataQualityAppliedConfigs',
    as HashRef[DataQualityAppliedConfigs()];

declare 'PostScanActionsResult',
    as InstanceOf['Google::Cloud::Dataplex::V1::Logs::DataScanEvent::PostScanActionsResult'];

coerce 'PostScanActionsResult',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Logs::DataScanEvent::PostScanActionsResult'->new($_) };

declare 'RepeatedPostScanActionsResult',
    as ArrayRef[PostScanActionsResult()];

coerce 'RepeatedPostScanActionsResult',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Logs::DataScanEvent::PostScanActionsResult'->new($_) } @$_ ] };

declare 'MapStringPostScanActionsResult',
    as HashRef[PostScanActionsResult()];

declare 'BigQueryExportResult',
    as InstanceOf['Google::Cloud::Dataplex::V1::Logs::DataScanEvent::PostScanActionsResult::BigQueryExportResult'];

coerce 'BigQueryExportResult',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Logs::DataScanEvent::PostScanActionsResult::BigQueryExportResult'->new($_) };

declare 'RepeatedBigQueryExportResult',
    as ArrayRef[BigQueryExportResult()];

coerce 'RepeatedBigQueryExportResult',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Logs::DataScanEvent::PostScanActionsResult::BigQueryExportResult'->new($_) } @$_ ] };

declare 'MapStringBigQueryExportResult',
    as HashRef[BigQueryExportResult()];

declare 'State',
    as (Int | Str);

declare 'DataQualityScanRuleResult',
    as InstanceOf['Google::Cloud::Dataplex::V1::Logs::DataQualityScanRuleResult'];

coerce 'DataQualityScanRuleResult',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Logs::DataQualityScanRuleResult'->new($_) };

declare 'RepeatedDataQualityScanRuleResult',
    as ArrayRef[DataQualityScanRuleResult()];

coerce 'RepeatedDataQualityScanRuleResult',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Logs::DataQualityScanRuleResult'->new($_) } @$_ ] };

declare 'MapStringDataQualityScanRuleResult',
    as HashRef[DataQualityScanRuleResult()];

declare 'RuleType',
    as (Int | Str);

declare 'EvaluationType',
    as (Int | Str);

declare 'Result',
    as (Int | Str);

declare 'BusinessGlossaryEvent',
    as InstanceOf['Google::Cloud::Dataplex::V1::Logs::BusinessGlossaryEvent'];

coerce 'BusinessGlossaryEvent',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Logs::BusinessGlossaryEvent'->new($_) };

declare 'RepeatedBusinessGlossaryEvent',
    as ArrayRef[BusinessGlossaryEvent()];

coerce 'RepeatedBusinessGlossaryEvent',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Logs::BusinessGlossaryEvent'->new($_) } @$_ ] };

declare 'MapStringBusinessGlossaryEvent',
    as HashRef[BusinessGlossaryEvent()];

declare 'EventType',
    as (Int | Str);

declare 'EntryLinkEvent',
    as InstanceOf['Google::Cloud::Dataplex::V1::Logs::EntryLinkEvent'];

coerce 'EntryLinkEvent',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Logs::EntryLinkEvent'->new($_) };

declare 'RepeatedEntryLinkEvent',
    as ArrayRef[EntryLinkEvent()];

coerce 'RepeatedEntryLinkEvent',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Logs::EntryLinkEvent'->new($_) } @$_ ] };

declare 'MapStringEntryLinkEvent',
    as HashRef[EntryLinkEvent()];

declare 'EventType',
    as (Int | Str);

1;

__END__

=head1 NAME

Google::Cloud::Dataplex::V1::Logs::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
