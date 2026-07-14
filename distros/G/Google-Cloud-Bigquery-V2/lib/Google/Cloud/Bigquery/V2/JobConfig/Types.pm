package Google::Cloud::Bigquery::V2::JobConfig::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'DestinationTableProperties',
    as InstanceOf['Google::Cloud::Bigquery::V2::JobConfig::DestinationTableProperties'];

coerce 'DestinationTableProperties',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::JobConfig::DestinationTableProperties'->new($_) };

declare 'RepeatedDestinationTableProperties',
    as ArrayRef[DestinationTableProperties()];

coerce 'RepeatedDestinationTableProperties',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::JobConfig::DestinationTableProperties'->new($_) } @$_ ] };

declare 'MapStringDestinationTableProperties',
    as HashRef[DestinationTableProperties()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Bigquery::V2::JobConfig::DestinationTableProperties::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::JobConfig::DestinationTableProperties::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::JobConfig::DestinationTableProperties::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'ConnectionProperty',
    as InstanceOf['Google::Cloud::Bigquery::V2::JobConfig::ConnectionProperty'];

coerce 'ConnectionProperty',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::JobConfig::ConnectionProperty'->new($_) };

declare 'RepeatedConnectionProperty',
    as ArrayRef[ConnectionProperty()];

coerce 'RepeatedConnectionProperty',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::JobConfig::ConnectionProperty'->new($_) } @$_ ] };

declare 'MapStringConnectionProperty',
    as HashRef[ConnectionProperty()];

declare 'JobConfigurationQuery',
    as InstanceOf['Google::Cloud::Bigquery::V2::JobConfig::JobConfigurationQuery'];

coerce 'JobConfigurationQuery',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::JobConfig::JobConfigurationQuery'->new($_) };

declare 'RepeatedJobConfigurationQuery',
    as ArrayRef[JobConfigurationQuery()];

coerce 'RepeatedJobConfigurationQuery',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::JobConfig::JobConfigurationQuery'->new($_) } @$_ ] };

declare 'MapStringJobConfigurationQuery',
    as HashRef[JobConfigurationQuery()];

declare 'ExternalTableDefinitionsEntry',
    as InstanceOf['Google::Cloud::Bigquery::V2::JobConfig::JobConfigurationQuery::ExternalTableDefinitionsEntry'];

coerce 'ExternalTableDefinitionsEntry',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::JobConfig::JobConfigurationQuery::ExternalTableDefinitionsEntry'->new($_) };

declare 'RepeatedExternalTableDefinitionsEntry',
    as ArrayRef[ExternalTableDefinitionsEntry()];

coerce 'RepeatedExternalTableDefinitionsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::JobConfig::JobConfigurationQuery::ExternalTableDefinitionsEntry'->new($_) } @$_ ] };

declare 'MapStringExternalTableDefinitionsEntry',
    as HashRef[ExternalTableDefinitionsEntry()];

declare 'ScriptOptions',
    as InstanceOf['Google::Cloud::Bigquery::V2::JobConfig::ScriptOptions'];

coerce 'ScriptOptions',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::JobConfig::ScriptOptions'->new($_) };

declare 'RepeatedScriptOptions',
    as ArrayRef[ScriptOptions()];

coerce 'RepeatedScriptOptions',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::JobConfig::ScriptOptions'->new($_) } @$_ ] };

declare 'MapStringScriptOptions',
    as HashRef[ScriptOptions()];

declare 'KeyResultStatementKind',
    as (Int | Str);

declare 'JobConfigurationLoad',
    as InstanceOf['Google::Cloud::Bigquery::V2::JobConfig::JobConfigurationLoad'];

coerce 'JobConfigurationLoad',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::JobConfig::JobConfigurationLoad'->new($_) };

declare 'RepeatedJobConfigurationLoad',
    as ArrayRef[JobConfigurationLoad()];

coerce 'RepeatedJobConfigurationLoad',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::JobConfig::JobConfigurationLoad'->new($_) } @$_ ] };

declare 'MapStringJobConfigurationLoad',
    as HashRef[JobConfigurationLoad()];

declare 'ColumnNameCharacterMap',
    as (Int | Str);

declare 'SourceColumnMatch',
    as (Int | Str);

declare 'JobConfigurationTableCopy',
    as InstanceOf['Google::Cloud::Bigquery::V2::JobConfig::JobConfigurationTableCopy'];

coerce 'JobConfigurationTableCopy',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::JobConfig::JobConfigurationTableCopy'->new($_) };

declare 'RepeatedJobConfigurationTableCopy',
    as ArrayRef[JobConfigurationTableCopy()];

coerce 'RepeatedJobConfigurationTableCopy',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::JobConfig::JobConfigurationTableCopy'->new($_) } @$_ ] };

declare 'MapStringJobConfigurationTableCopy',
    as HashRef[JobConfigurationTableCopy()];

declare 'OperationType',
    as (Int | Str);

declare 'JobConfigurationExtract',
    as InstanceOf['Google::Cloud::Bigquery::V2::JobConfig::JobConfigurationExtract'];

coerce 'JobConfigurationExtract',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::JobConfig::JobConfigurationExtract'->new($_) };

declare 'RepeatedJobConfigurationExtract',
    as ArrayRef[JobConfigurationExtract()];

coerce 'RepeatedJobConfigurationExtract',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::JobConfig::JobConfigurationExtract'->new($_) } @$_ ] };

declare 'MapStringJobConfigurationExtract',
    as HashRef[JobConfigurationExtract()];

declare 'ModelExtractOptions',
    as InstanceOf['Google::Cloud::Bigquery::V2::JobConfig::JobConfigurationExtract::ModelExtractOptions'];

coerce 'ModelExtractOptions',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::JobConfig::JobConfigurationExtract::ModelExtractOptions'->new($_) };

declare 'RepeatedModelExtractOptions',
    as ArrayRef[ModelExtractOptions()];

coerce 'RepeatedModelExtractOptions',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::JobConfig::JobConfigurationExtract::ModelExtractOptions'->new($_) } @$_ ] };

declare 'MapStringModelExtractOptions',
    as HashRef[ModelExtractOptions()];

declare 'JobConfiguration',
    as InstanceOf['Google::Cloud::Bigquery::V2::JobConfig::JobConfiguration'];

coerce 'JobConfiguration',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::JobConfig::JobConfiguration'->new($_) };

declare 'RepeatedJobConfiguration',
    as ArrayRef[JobConfiguration()];

coerce 'RepeatedJobConfiguration',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::JobConfig::JobConfiguration'->new($_) } @$_ ] };

declare 'MapStringJobConfiguration',
    as HashRef[JobConfiguration()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Bigquery::V2::JobConfig::JobConfiguration::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::JobConfig::JobConfiguration::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::JobConfig::JobConfiguration::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

1;
