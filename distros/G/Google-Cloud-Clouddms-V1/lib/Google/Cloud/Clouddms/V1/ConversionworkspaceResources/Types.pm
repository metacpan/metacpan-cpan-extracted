package Google::Cloud::Clouddms::V1::ConversionworkspaceResources::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'ValuePresentInList',
    as (Int | Str);

declare 'DatabaseEntityType',
    as (Int | Str);

declare 'EntityNameTransformation',
    as (Int | Str);

declare 'BackgroundJobType',
    as (Int | Str);

declare 'ImportRulesFileFormat',
    as (Int | Str);

declare 'ValueComparison',
    as (Int | Str);

declare 'NumericFilterOption',
    as (Int | Str);

declare 'DatabaseEngineInfo',
    as InstanceOf['Google::Cloud::Clouddms::V1::ConversionworkspaceResources::DatabaseEngineInfo'];

coerce 'DatabaseEngineInfo',
    from HashRef, via { 'Google::Cloud::Clouddms::V1::ConversionworkspaceResources::DatabaseEngineInfo'->new($_) };

declare 'RepeatedDatabaseEngineInfo',
    as ArrayRef[DatabaseEngineInfo()];

coerce 'RepeatedDatabaseEngineInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Clouddms::V1::ConversionworkspaceResources::DatabaseEngineInfo'->new($_) } @$_ ] };

declare 'MapStringDatabaseEngineInfo',
    as HashRef[DatabaseEngineInfo()];

declare 'ConversionWorkspace',
    as InstanceOf['Google::Cloud::Clouddms::V1::ConversionworkspaceResources::ConversionWorkspace'];

coerce 'ConversionWorkspace',
    from HashRef, via { 'Google::Cloud::Clouddms::V1::ConversionworkspaceResources::ConversionWorkspace'->new($_) };

declare 'RepeatedConversionWorkspace',
    as ArrayRef[ConversionWorkspace()];

coerce 'RepeatedConversionWorkspace',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Clouddms::V1::ConversionworkspaceResources::ConversionWorkspace'->new($_) } @$_ ] };

declare 'MapStringConversionWorkspace',
    as HashRef[ConversionWorkspace()];

declare 'GlobalSettingsEntry',
    as InstanceOf['Google::Cloud::Clouddms::V1::ConversionworkspaceResources::ConversionWorkspace::GlobalSettingsEntry'];

coerce 'GlobalSettingsEntry',
    from HashRef, via { 'Google::Cloud::Clouddms::V1::ConversionworkspaceResources::ConversionWorkspace::GlobalSettingsEntry'->new($_) };

declare 'RepeatedGlobalSettingsEntry',
    as ArrayRef[GlobalSettingsEntry()];

coerce 'RepeatedGlobalSettingsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Clouddms::V1::ConversionworkspaceResources::ConversionWorkspace::GlobalSettingsEntry'->new($_) } @$_ ] };

declare 'MapStringGlobalSettingsEntry',
    as HashRef[GlobalSettingsEntry()];

declare 'BackgroundJobLogEntry',
    as InstanceOf['Google::Cloud::Clouddms::V1::ConversionworkspaceResources::BackgroundJobLogEntry'];

coerce 'BackgroundJobLogEntry',
    from HashRef, via { 'Google::Cloud::Clouddms::V1::ConversionworkspaceResources::BackgroundJobLogEntry'->new($_) };

declare 'RepeatedBackgroundJobLogEntry',
    as ArrayRef[BackgroundJobLogEntry()];

coerce 'RepeatedBackgroundJobLogEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Clouddms::V1::ConversionworkspaceResources::BackgroundJobLogEntry'->new($_) } @$_ ] };

declare 'MapStringBackgroundJobLogEntry',
    as HashRef[BackgroundJobLogEntry()];

declare 'JobCompletionState',
    as (Int | Str);

declare 'SeedJobDetails',
    as InstanceOf['Google::Cloud::Clouddms::V1::ConversionworkspaceResources::BackgroundJobLogEntry::SeedJobDetails'];

coerce 'SeedJobDetails',
    from HashRef, via { 'Google::Cloud::Clouddms::V1::ConversionworkspaceResources::BackgroundJobLogEntry::SeedJobDetails'->new($_) };

declare 'RepeatedSeedJobDetails',
    as ArrayRef[SeedJobDetails()];

coerce 'RepeatedSeedJobDetails',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Clouddms::V1::ConversionworkspaceResources::BackgroundJobLogEntry::SeedJobDetails'->new($_) } @$_ ] };

declare 'MapStringSeedJobDetails',
    as HashRef[SeedJobDetails()];

declare 'ImportRulesJobDetails',
    as InstanceOf['Google::Cloud::Clouddms::V1::ConversionworkspaceResources::BackgroundJobLogEntry::ImportRulesJobDetails'];

coerce 'ImportRulesJobDetails',
    from HashRef, via { 'Google::Cloud::Clouddms::V1::ConversionworkspaceResources::BackgroundJobLogEntry::ImportRulesJobDetails'->new($_) };

declare 'RepeatedImportRulesJobDetails',
    as ArrayRef[ImportRulesJobDetails()];

coerce 'RepeatedImportRulesJobDetails',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Clouddms::V1::ConversionworkspaceResources::BackgroundJobLogEntry::ImportRulesJobDetails'->new($_) } @$_ ] };

declare 'MapStringImportRulesJobDetails',
    as HashRef[ImportRulesJobDetails()];

declare 'ConvertJobDetails',
    as InstanceOf['Google::Cloud::Clouddms::V1::ConversionworkspaceResources::BackgroundJobLogEntry::ConvertJobDetails'];

coerce 'ConvertJobDetails',
    from HashRef, via { 'Google::Cloud::Clouddms::V1::ConversionworkspaceResources::BackgroundJobLogEntry::ConvertJobDetails'->new($_) };

declare 'RepeatedConvertJobDetails',
    as ArrayRef[ConvertJobDetails()];

coerce 'RepeatedConvertJobDetails',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Clouddms::V1::ConversionworkspaceResources::BackgroundJobLogEntry::ConvertJobDetails'->new($_) } @$_ ] };

declare 'MapStringConvertJobDetails',
    as HashRef[ConvertJobDetails()];

declare 'ApplyJobDetails',
    as InstanceOf['Google::Cloud::Clouddms::V1::ConversionworkspaceResources::BackgroundJobLogEntry::ApplyJobDetails'];

coerce 'ApplyJobDetails',
    from HashRef, via { 'Google::Cloud::Clouddms::V1::ConversionworkspaceResources::BackgroundJobLogEntry::ApplyJobDetails'->new($_) };

declare 'RepeatedApplyJobDetails',
    as ArrayRef[ApplyJobDetails()];

coerce 'RepeatedApplyJobDetails',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Clouddms::V1::ConversionworkspaceResources::BackgroundJobLogEntry::ApplyJobDetails'->new($_) } @$_ ] };

declare 'MapStringApplyJobDetails',
    as HashRef[ApplyJobDetails()];

declare 'MappingRuleFilter',
    as InstanceOf['Google::Cloud::Clouddms::V1::ConversionworkspaceResources::MappingRuleFilter'];

coerce 'MappingRuleFilter',
    from HashRef, via { 'Google::Cloud::Clouddms::V1::ConversionworkspaceResources::MappingRuleFilter'->new($_) };

declare 'RepeatedMappingRuleFilter',
    as ArrayRef[MappingRuleFilter()];

coerce 'RepeatedMappingRuleFilter',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Clouddms::V1::ConversionworkspaceResources::MappingRuleFilter'->new($_) } @$_ ] };

declare 'MapStringMappingRuleFilter',
    as HashRef[MappingRuleFilter()];

declare 'MappingRule',
    as InstanceOf['Google::Cloud::Clouddms::V1::ConversionworkspaceResources::MappingRule'];

coerce 'MappingRule',
    from HashRef, via { 'Google::Cloud::Clouddms::V1::ConversionworkspaceResources::MappingRule'->new($_) };

declare 'RepeatedMappingRule',
    as ArrayRef[MappingRule()];

coerce 'RepeatedMappingRule',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Clouddms::V1::ConversionworkspaceResources::MappingRule'->new($_) } @$_ ] };

declare 'MapStringMappingRule',
    as HashRef[MappingRule()];

declare 'State',
    as (Int | Str);

declare 'SingleEntityRename',
    as InstanceOf['Google::Cloud::Clouddms::V1::ConversionworkspaceResources::SingleEntityRename'];

coerce 'SingleEntityRename',
    from HashRef, via { 'Google::Cloud::Clouddms::V1::ConversionworkspaceResources::SingleEntityRename'->new($_) };

declare 'RepeatedSingleEntityRename',
    as ArrayRef[SingleEntityRename()];

coerce 'RepeatedSingleEntityRename',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Clouddms::V1::ConversionworkspaceResources::SingleEntityRename'->new($_) } @$_ ] };

declare 'MapStringSingleEntityRename',
    as HashRef[SingleEntityRename()];

declare 'MultiEntityRename',
    as InstanceOf['Google::Cloud::Clouddms::V1::ConversionworkspaceResources::MultiEntityRename'];

coerce 'MultiEntityRename',
    from HashRef, via { 'Google::Cloud::Clouddms::V1::ConversionworkspaceResources::MultiEntityRename'->new($_) };

declare 'RepeatedMultiEntityRename',
    as ArrayRef[MultiEntityRename()];

coerce 'RepeatedMultiEntityRename',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Clouddms::V1::ConversionworkspaceResources::MultiEntityRename'->new($_) } @$_ ] };

declare 'MapStringMultiEntityRename',
    as HashRef[MultiEntityRename()];

declare 'EntityMove',
    as InstanceOf['Google::Cloud::Clouddms::V1::ConversionworkspaceResources::EntityMove'];

coerce 'EntityMove',
    from HashRef, via { 'Google::Cloud::Clouddms::V1::ConversionworkspaceResources::EntityMove'->new($_) };

declare 'RepeatedEntityMove',
    as ArrayRef[EntityMove()];

coerce 'RepeatedEntityMove',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Clouddms::V1::ConversionworkspaceResources::EntityMove'->new($_) } @$_ ] };

declare 'MapStringEntityMove',
    as HashRef[EntityMove()];

declare 'SingleColumnChange',
    as InstanceOf['Google::Cloud::Clouddms::V1::ConversionworkspaceResources::SingleColumnChange'];

coerce 'SingleColumnChange',
    from HashRef, via { 'Google::Cloud::Clouddms::V1::ConversionworkspaceResources::SingleColumnChange'->new($_) };

declare 'RepeatedSingleColumnChange',
    as ArrayRef[SingleColumnChange()];

coerce 'RepeatedSingleColumnChange',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Clouddms::V1::ConversionworkspaceResources::SingleColumnChange'->new($_) } @$_ ] };

declare 'MapStringSingleColumnChange',
    as HashRef[SingleColumnChange()];

declare 'MultiColumnDatatypeChange',
    as InstanceOf['Google::Cloud::Clouddms::V1::ConversionworkspaceResources::MultiColumnDatatypeChange'];

coerce 'MultiColumnDatatypeChange',
    from HashRef, via { 'Google::Cloud::Clouddms::V1::ConversionworkspaceResources::MultiColumnDatatypeChange'->new($_) };

declare 'RepeatedMultiColumnDatatypeChange',
    as ArrayRef[MultiColumnDatatypeChange()];

coerce 'RepeatedMultiColumnDatatypeChange',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Clouddms::V1::ConversionworkspaceResources::MultiColumnDatatypeChange'->new($_) } @$_ ] };

declare 'MapStringMultiColumnDatatypeChange',
    as HashRef[MultiColumnDatatypeChange()];

declare 'SourceTextFilter',
    as InstanceOf['Google::Cloud::Clouddms::V1::ConversionworkspaceResources::SourceTextFilter'];

coerce 'SourceTextFilter',
    from HashRef, via { 'Google::Cloud::Clouddms::V1::ConversionworkspaceResources::SourceTextFilter'->new($_) };

declare 'RepeatedSourceTextFilter',
    as ArrayRef[SourceTextFilter()];

coerce 'RepeatedSourceTextFilter',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Clouddms::V1::ConversionworkspaceResources::SourceTextFilter'->new($_) } @$_ ] };

declare 'MapStringSourceTextFilter',
    as HashRef[SourceTextFilter()];

declare 'SourceNumericFilter',
    as InstanceOf['Google::Cloud::Clouddms::V1::ConversionworkspaceResources::SourceNumericFilter'];

coerce 'SourceNumericFilter',
    from HashRef, via { 'Google::Cloud::Clouddms::V1::ConversionworkspaceResources::SourceNumericFilter'->new($_) };

declare 'RepeatedSourceNumericFilter',
    as ArrayRef[SourceNumericFilter()];

coerce 'RepeatedSourceNumericFilter',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Clouddms::V1::ConversionworkspaceResources::SourceNumericFilter'->new($_) } @$_ ] };

declare 'MapStringSourceNumericFilter',
    as HashRef[SourceNumericFilter()];

declare 'ConditionalColumnSetValue',
    as InstanceOf['Google::Cloud::Clouddms::V1::ConversionworkspaceResources::ConditionalColumnSetValue'];

coerce 'ConditionalColumnSetValue',
    from HashRef, via { 'Google::Cloud::Clouddms::V1::ConversionworkspaceResources::ConditionalColumnSetValue'->new($_) };

declare 'RepeatedConditionalColumnSetValue',
    as ArrayRef[ConditionalColumnSetValue()];

coerce 'RepeatedConditionalColumnSetValue',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Clouddms::V1::ConversionworkspaceResources::ConditionalColumnSetValue'->new($_) } @$_ ] };

declare 'MapStringConditionalColumnSetValue',
    as HashRef[ConditionalColumnSetValue()];

declare 'ValueTransformation',
    as InstanceOf['Google::Cloud::Clouddms::V1::ConversionworkspaceResources::ValueTransformation'];

coerce 'ValueTransformation',
    from HashRef, via { 'Google::Cloud::Clouddms::V1::ConversionworkspaceResources::ValueTransformation'->new($_) };

declare 'RepeatedValueTransformation',
    as ArrayRef[ValueTransformation()];

coerce 'RepeatedValueTransformation',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Clouddms::V1::ConversionworkspaceResources::ValueTransformation'->new($_) } @$_ ] };

declare 'MapStringValueTransformation',
    as HashRef[ValueTransformation()];

declare 'ConvertRowIdToColumn',
    as InstanceOf['Google::Cloud::Clouddms::V1::ConversionworkspaceResources::ConvertRowIdToColumn'];

coerce 'ConvertRowIdToColumn',
    from HashRef, via { 'Google::Cloud::Clouddms::V1::ConversionworkspaceResources::ConvertRowIdToColumn'->new($_) };

declare 'RepeatedConvertRowIdToColumn',
    as ArrayRef[ConvertRowIdToColumn()];

coerce 'RepeatedConvertRowIdToColumn',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Clouddms::V1::ConversionworkspaceResources::ConvertRowIdToColumn'->new($_) } @$_ ] };

declare 'MapStringConvertRowIdToColumn',
    as HashRef[ConvertRowIdToColumn()];

declare 'SetTablePrimaryKey',
    as InstanceOf['Google::Cloud::Clouddms::V1::ConversionworkspaceResources::SetTablePrimaryKey'];

coerce 'SetTablePrimaryKey',
    from HashRef, via { 'Google::Cloud::Clouddms::V1::ConversionworkspaceResources::SetTablePrimaryKey'->new($_) };

declare 'RepeatedSetTablePrimaryKey',
    as ArrayRef[SetTablePrimaryKey()];

coerce 'RepeatedSetTablePrimaryKey',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Clouddms::V1::ConversionworkspaceResources::SetTablePrimaryKey'->new($_) } @$_ ] };

declare 'MapStringSetTablePrimaryKey',
    as HashRef[SetTablePrimaryKey()];

declare 'SinglePackageChange',
    as InstanceOf['Google::Cloud::Clouddms::V1::ConversionworkspaceResources::SinglePackageChange'];

coerce 'SinglePackageChange',
    from HashRef, via { 'Google::Cloud::Clouddms::V1::ConversionworkspaceResources::SinglePackageChange'->new($_) };

declare 'RepeatedSinglePackageChange',
    as ArrayRef[SinglePackageChange()];

coerce 'RepeatedSinglePackageChange',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Clouddms::V1::ConversionworkspaceResources::SinglePackageChange'->new($_) } @$_ ] };

declare 'MapStringSinglePackageChange',
    as HashRef[SinglePackageChange()];

declare 'SourceSqlChange',
    as InstanceOf['Google::Cloud::Clouddms::V1::ConversionworkspaceResources::SourceSqlChange'];

coerce 'SourceSqlChange',
    from HashRef, via { 'Google::Cloud::Clouddms::V1::ConversionworkspaceResources::SourceSqlChange'->new($_) };

declare 'RepeatedSourceSqlChange',
    as ArrayRef[SourceSqlChange()];

coerce 'RepeatedSourceSqlChange',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Clouddms::V1::ConversionworkspaceResources::SourceSqlChange'->new($_) } @$_ ] };

declare 'MapStringSourceSqlChange',
    as HashRef[SourceSqlChange()];

declare 'FilterTableColumns',
    as InstanceOf['Google::Cloud::Clouddms::V1::ConversionworkspaceResources::FilterTableColumns'];

coerce 'FilterTableColumns',
    from HashRef, via { 'Google::Cloud::Clouddms::V1::ConversionworkspaceResources::FilterTableColumns'->new($_) };

declare 'RepeatedFilterTableColumns',
    as ArrayRef[FilterTableColumns()];

coerce 'RepeatedFilterTableColumns',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Clouddms::V1::ConversionworkspaceResources::FilterTableColumns'->new($_) } @$_ ] };

declare 'MapStringFilterTableColumns',
    as HashRef[FilterTableColumns()];

declare 'ValueListFilter',
    as InstanceOf['Google::Cloud::Clouddms::V1::ConversionworkspaceResources::ValueListFilter'];

coerce 'ValueListFilter',
    from HashRef, via { 'Google::Cloud::Clouddms::V1::ConversionworkspaceResources::ValueListFilter'->new($_) };

declare 'RepeatedValueListFilter',
    as ArrayRef[ValueListFilter()];

coerce 'RepeatedValueListFilter',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Clouddms::V1::ConversionworkspaceResources::ValueListFilter'->new($_) } @$_ ] };

declare 'MapStringValueListFilter',
    as HashRef[ValueListFilter()];

declare 'IntComparisonFilter',
    as InstanceOf['Google::Cloud::Clouddms::V1::ConversionworkspaceResources::IntComparisonFilter'];

coerce 'IntComparisonFilter',
    from HashRef, via { 'Google::Cloud::Clouddms::V1::ConversionworkspaceResources::IntComparisonFilter'->new($_) };

declare 'RepeatedIntComparisonFilter',
    as ArrayRef[IntComparisonFilter()];

coerce 'RepeatedIntComparisonFilter',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Clouddms::V1::ConversionworkspaceResources::IntComparisonFilter'->new($_) } @$_ ] };

declare 'MapStringIntComparisonFilter',
    as HashRef[IntComparisonFilter()];

declare 'DoubleComparisonFilter',
    as InstanceOf['Google::Cloud::Clouddms::V1::ConversionworkspaceResources::DoubleComparisonFilter'];

coerce 'DoubleComparisonFilter',
    from HashRef, via { 'Google::Cloud::Clouddms::V1::ConversionworkspaceResources::DoubleComparisonFilter'->new($_) };

declare 'RepeatedDoubleComparisonFilter',
    as ArrayRef[DoubleComparisonFilter()];

coerce 'RepeatedDoubleComparisonFilter',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Clouddms::V1::ConversionworkspaceResources::DoubleComparisonFilter'->new($_) } @$_ ] };

declare 'MapStringDoubleComparisonFilter',
    as HashRef[DoubleComparisonFilter()];

declare 'AssignSpecificValue',
    as InstanceOf['Google::Cloud::Clouddms::V1::ConversionworkspaceResources::AssignSpecificValue'];

coerce 'AssignSpecificValue',
    from HashRef, via { 'Google::Cloud::Clouddms::V1::ConversionworkspaceResources::AssignSpecificValue'->new($_) };

declare 'RepeatedAssignSpecificValue',
    as ArrayRef[AssignSpecificValue()];

coerce 'RepeatedAssignSpecificValue',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Clouddms::V1::ConversionworkspaceResources::AssignSpecificValue'->new($_) } @$_ ] };

declare 'MapStringAssignSpecificValue',
    as HashRef[AssignSpecificValue()];

declare 'ApplyHash',
    as InstanceOf['Google::Cloud::Clouddms::V1::ConversionworkspaceResources::ApplyHash'];

coerce 'ApplyHash',
    from HashRef, via { 'Google::Cloud::Clouddms::V1::ConversionworkspaceResources::ApplyHash'->new($_) };

declare 'RepeatedApplyHash',
    as ArrayRef[ApplyHash()];

coerce 'RepeatedApplyHash',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Clouddms::V1::ConversionworkspaceResources::ApplyHash'->new($_) } @$_ ] };

declare 'MapStringApplyHash',
    as HashRef[ApplyHash()];

declare 'RoundToScale',
    as InstanceOf['Google::Cloud::Clouddms::V1::ConversionworkspaceResources::RoundToScale'];

coerce 'RoundToScale',
    from HashRef, via { 'Google::Cloud::Clouddms::V1::ConversionworkspaceResources::RoundToScale'->new($_) };

declare 'RepeatedRoundToScale',
    as ArrayRef[RoundToScale()];

coerce 'RepeatedRoundToScale',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Clouddms::V1::ConversionworkspaceResources::RoundToScale'->new($_) } @$_ ] };

declare 'MapStringRoundToScale',
    as HashRef[RoundToScale()];

declare 'DatabaseEntity',
    as InstanceOf['Google::Cloud::Clouddms::V1::ConversionworkspaceResources::DatabaseEntity'];

coerce 'DatabaseEntity',
    from HashRef, via { 'Google::Cloud::Clouddms::V1::ConversionworkspaceResources::DatabaseEntity'->new($_) };

declare 'RepeatedDatabaseEntity',
    as ArrayRef[DatabaseEntity()];

coerce 'RepeatedDatabaseEntity',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Clouddms::V1::ConversionworkspaceResources::DatabaseEntity'->new($_) } @$_ ] };

declare 'MapStringDatabaseEntity',
    as HashRef[DatabaseEntity()];

declare 'TreeType',
    as (Int | Str);

declare 'DatabaseInstanceEntity',
    as InstanceOf['Google::Cloud::Clouddms::V1::ConversionworkspaceResources::DatabaseInstanceEntity'];

coerce 'DatabaseInstanceEntity',
    from HashRef, via { 'Google::Cloud::Clouddms::V1::ConversionworkspaceResources::DatabaseInstanceEntity'->new($_) };

declare 'RepeatedDatabaseInstanceEntity',
    as ArrayRef[DatabaseInstanceEntity()];

coerce 'RepeatedDatabaseInstanceEntity',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Clouddms::V1::ConversionworkspaceResources::DatabaseInstanceEntity'->new($_) } @$_ ] };

declare 'MapStringDatabaseInstanceEntity',
    as HashRef[DatabaseInstanceEntity()];

declare 'SchemaEntity',
    as InstanceOf['Google::Cloud::Clouddms::V1::ConversionworkspaceResources::SchemaEntity'];

coerce 'SchemaEntity',
    from HashRef, via { 'Google::Cloud::Clouddms::V1::ConversionworkspaceResources::SchemaEntity'->new($_) };

declare 'RepeatedSchemaEntity',
    as ArrayRef[SchemaEntity()];

coerce 'RepeatedSchemaEntity',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Clouddms::V1::ConversionworkspaceResources::SchemaEntity'->new($_) } @$_ ] };

declare 'MapStringSchemaEntity',
    as HashRef[SchemaEntity()];

declare 'TableEntity',
    as InstanceOf['Google::Cloud::Clouddms::V1::ConversionworkspaceResources::TableEntity'];

coerce 'TableEntity',
    from HashRef, via { 'Google::Cloud::Clouddms::V1::ConversionworkspaceResources::TableEntity'->new($_) };

declare 'RepeatedTableEntity',
    as ArrayRef[TableEntity()];

coerce 'RepeatedTableEntity',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Clouddms::V1::ConversionworkspaceResources::TableEntity'->new($_) } @$_ ] };

declare 'MapStringTableEntity',
    as HashRef[TableEntity()];

declare 'ColumnEntity',
    as InstanceOf['Google::Cloud::Clouddms::V1::ConversionworkspaceResources::ColumnEntity'];

coerce 'ColumnEntity',
    from HashRef, via { 'Google::Cloud::Clouddms::V1::ConversionworkspaceResources::ColumnEntity'->new($_) };

declare 'RepeatedColumnEntity',
    as ArrayRef[ColumnEntity()];

coerce 'RepeatedColumnEntity',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Clouddms::V1::ConversionworkspaceResources::ColumnEntity'->new($_) } @$_ ] };

declare 'MapStringColumnEntity',
    as HashRef[ColumnEntity()];

declare 'ConstraintEntity',
    as InstanceOf['Google::Cloud::Clouddms::V1::ConversionworkspaceResources::ConstraintEntity'];

coerce 'ConstraintEntity',
    from HashRef, via { 'Google::Cloud::Clouddms::V1::ConversionworkspaceResources::ConstraintEntity'->new($_) };

declare 'RepeatedConstraintEntity',
    as ArrayRef[ConstraintEntity()];

coerce 'RepeatedConstraintEntity',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Clouddms::V1::ConversionworkspaceResources::ConstraintEntity'->new($_) } @$_ ] };

declare 'MapStringConstraintEntity',
    as HashRef[ConstraintEntity()];

declare 'IndexEntity',
    as InstanceOf['Google::Cloud::Clouddms::V1::ConversionworkspaceResources::IndexEntity'];

coerce 'IndexEntity',
    from HashRef, via { 'Google::Cloud::Clouddms::V1::ConversionworkspaceResources::IndexEntity'->new($_) };

declare 'RepeatedIndexEntity',
    as ArrayRef[IndexEntity()];

coerce 'RepeatedIndexEntity',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Clouddms::V1::ConversionworkspaceResources::IndexEntity'->new($_) } @$_ ] };

declare 'MapStringIndexEntity',
    as HashRef[IndexEntity()];

declare 'TriggerEntity',
    as InstanceOf['Google::Cloud::Clouddms::V1::ConversionworkspaceResources::TriggerEntity'];

coerce 'TriggerEntity',
    from HashRef, via { 'Google::Cloud::Clouddms::V1::ConversionworkspaceResources::TriggerEntity'->new($_) };

declare 'RepeatedTriggerEntity',
    as ArrayRef[TriggerEntity()];

coerce 'RepeatedTriggerEntity',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Clouddms::V1::ConversionworkspaceResources::TriggerEntity'->new($_) } @$_ ] };

declare 'MapStringTriggerEntity',
    as HashRef[TriggerEntity()];

declare 'ViewEntity',
    as InstanceOf['Google::Cloud::Clouddms::V1::ConversionworkspaceResources::ViewEntity'];

coerce 'ViewEntity',
    from HashRef, via { 'Google::Cloud::Clouddms::V1::ConversionworkspaceResources::ViewEntity'->new($_) };

declare 'RepeatedViewEntity',
    as ArrayRef[ViewEntity()];

coerce 'RepeatedViewEntity',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Clouddms::V1::ConversionworkspaceResources::ViewEntity'->new($_) } @$_ ] };

declare 'MapStringViewEntity',
    as HashRef[ViewEntity()];

declare 'SequenceEntity',
    as InstanceOf['Google::Cloud::Clouddms::V1::ConversionworkspaceResources::SequenceEntity'];

coerce 'SequenceEntity',
    from HashRef, via { 'Google::Cloud::Clouddms::V1::ConversionworkspaceResources::SequenceEntity'->new($_) };

declare 'RepeatedSequenceEntity',
    as ArrayRef[SequenceEntity()];

coerce 'RepeatedSequenceEntity',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Clouddms::V1::ConversionworkspaceResources::SequenceEntity'->new($_) } @$_ ] };

declare 'MapStringSequenceEntity',
    as HashRef[SequenceEntity()];

declare 'StoredProcedureEntity',
    as InstanceOf['Google::Cloud::Clouddms::V1::ConversionworkspaceResources::StoredProcedureEntity'];

coerce 'StoredProcedureEntity',
    from HashRef, via { 'Google::Cloud::Clouddms::V1::ConversionworkspaceResources::StoredProcedureEntity'->new($_) };

declare 'RepeatedStoredProcedureEntity',
    as ArrayRef[StoredProcedureEntity()];

coerce 'RepeatedStoredProcedureEntity',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Clouddms::V1::ConversionworkspaceResources::StoredProcedureEntity'->new($_) } @$_ ] };

declare 'MapStringStoredProcedureEntity',
    as HashRef[StoredProcedureEntity()];

declare 'FunctionEntity',
    as InstanceOf['Google::Cloud::Clouddms::V1::ConversionworkspaceResources::FunctionEntity'];

coerce 'FunctionEntity',
    from HashRef, via { 'Google::Cloud::Clouddms::V1::ConversionworkspaceResources::FunctionEntity'->new($_) };

declare 'RepeatedFunctionEntity',
    as ArrayRef[FunctionEntity()];

coerce 'RepeatedFunctionEntity',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Clouddms::V1::ConversionworkspaceResources::FunctionEntity'->new($_) } @$_ ] };

declare 'MapStringFunctionEntity',
    as HashRef[FunctionEntity()];

declare 'MaterializedViewEntity',
    as InstanceOf['Google::Cloud::Clouddms::V1::ConversionworkspaceResources::MaterializedViewEntity'];

coerce 'MaterializedViewEntity',
    from HashRef, via { 'Google::Cloud::Clouddms::V1::ConversionworkspaceResources::MaterializedViewEntity'->new($_) };

declare 'RepeatedMaterializedViewEntity',
    as ArrayRef[MaterializedViewEntity()];

coerce 'RepeatedMaterializedViewEntity',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Clouddms::V1::ConversionworkspaceResources::MaterializedViewEntity'->new($_) } @$_ ] };

declare 'MapStringMaterializedViewEntity',
    as HashRef[MaterializedViewEntity()];

declare 'SynonymEntity',
    as InstanceOf['Google::Cloud::Clouddms::V1::ConversionworkspaceResources::SynonymEntity'];

coerce 'SynonymEntity',
    from HashRef, via { 'Google::Cloud::Clouddms::V1::ConversionworkspaceResources::SynonymEntity'->new($_) };

declare 'RepeatedSynonymEntity',
    as ArrayRef[SynonymEntity()];

coerce 'RepeatedSynonymEntity',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Clouddms::V1::ConversionworkspaceResources::SynonymEntity'->new($_) } @$_ ] };

declare 'MapStringSynonymEntity',
    as HashRef[SynonymEntity()];

declare 'PackageEntity',
    as InstanceOf['Google::Cloud::Clouddms::V1::ConversionworkspaceResources::PackageEntity'];

coerce 'PackageEntity',
    from HashRef, via { 'Google::Cloud::Clouddms::V1::ConversionworkspaceResources::PackageEntity'->new($_) };

declare 'RepeatedPackageEntity',
    as ArrayRef[PackageEntity()];

coerce 'RepeatedPackageEntity',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Clouddms::V1::ConversionworkspaceResources::PackageEntity'->new($_) } @$_ ] };

declare 'MapStringPackageEntity',
    as HashRef[PackageEntity()];

declare 'UDTEntity',
    as InstanceOf['Google::Cloud::Clouddms::V1::ConversionworkspaceResources::UDTEntity'];

coerce 'UDTEntity',
    from HashRef, via { 'Google::Cloud::Clouddms::V1::ConversionworkspaceResources::UDTEntity'->new($_) };

declare 'RepeatedUDTEntity',
    as ArrayRef[UDTEntity()];

coerce 'RepeatedUDTEntity',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Clouddms::V1::ConversionworkspaceResources::UDTEntity'->new($_) } @$_ ] };

declare 'MapStringUDTEntity',
    as HashRef[UDTEntity()];

declare 'EntityMapping',
    as InstanceOf['Google::Cloud::Clouddms::V1::ConversionworkspaceResources::EntityMapping'];

coerce 'EntityMapping',
    from HashRef, via { 'Google::Cloud::Clouddms::V1::ConversionworkspaceResources::EntityMapping'->new($_) };

declare 'RepeatedEntityMapping',
    as ArrayRef[EntityMapping()];

coerce 'RepeatedEntityMapping',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Clouddms::V1::ConversionworkspaceResources::EntityMapping'->new($_) } @$_ ] };

declare 'MapStringEntityMapping',
    as HashRef[EntityMapping()];

declare 'EntityMappingLogEntry',
    as InstanceOf['Google::Cloud::Clouddms::V1::ConversionworkspaceResources::EntityMappingLogEntry'];

coerce 'EntityMappingLogEntry',
    from HashRef, via { 'Google::Cloud::Clouddms::V1::ConversionworkspaceResources::EntityMappingLogEntry'->new($_) };

declare 'RepeatedEntityMappingLogEntry',
    as ArrayRef[EntityMappingLogEntry()];

coerce 'RepeatedEntityMappingLogEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Clouddms::V1::ConversionworkspaceResources::EntityMappingLogEntry'->new($_) } @$_ ] };

declare 'MapStringEntityMappingLogEntry',
    as HashRef[EntityMappingLogEntry()];

declare 'EntityDdl',
    as InstanceOf['Google::Cloud::Clouddms::V1::ConversionworkspaceResources::EntityDdl'];

coerce 'EntityDdl',
    from HashRef, via { 'Google::Cloud::Clouddms::V1::ConversionworkspaceResources::EntityDdl'->new($_) };

declare 'RepeatedEntityDdl',
    as ArrayRef[EntityDdl()];

coerce 'RepeatedEntityDdl',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Clouddms::V1::ConversionworkspaceResources::EntityDdl'->new($_) } @$_ ] };

declare 'MapStringEntityDdl',
    as HashRef[EntityDdl()];

declare 'EntityIssue',
    as InstanceOf['Google::Cloud::Clouddms::V1::ConversionworkspaceResources::EntityIssue'];

coerce 'EntityIssue',
    from HashRef, via { 'Google::Cloud::Clouddms::V1::ConversionworkspaceResources::EntityIssue'->new($_) };

declare 'RepeatedEntityIssue',
    as ArrayRef[EntityIssue()];

coerce 'RepeatedEntityIssue',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Clouddms::V1::ConversionworkspaceResources::EntityIssue'->new($_) } @$_ ] };

declare 'MapStringEntityIssue',
    as HashRef[EntityIssue()];

declare 'IssueType',
    as (Int | Str);

declare 'IssueSeverity',
    as (Int | Str);

declare 'Position',
    as InstanceOf['Google::Cloud::Clouddms::V1::ConversionworkspaceResources::EntityIssue::Position'];

coerce 'Position',
    from HashRef, via { 'Google::Cloud::Clouddms::V1::ConversionworkspaceResources::EntityIssue::Position'->new($_) };

declare 'RepeatedPosition',
    as ArrayRef[Position()];

coerce 'RepeatedPosition',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Clouddms::V1::ConversionworkspaceResources::EntityIssue::Position'->new($_) } @$_ ] };

declare 'MapStringPosition',
    as HashRef[Position()];

1;

__END__

=head1 NAME

Google::Cloud::Clouddms::V1::ConversionworkspaceResources::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
