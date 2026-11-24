package Google::Cloud::Bigquery::Migration::V2::TranslationConfig::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'TranslationConfigDetails',
    as InstanceOf['Google::Cloud::Bigquery::Migration::V2::TranslationConfig::TranslationConfigDetails'];

coerce 'TranslationConfigDetails',
    from HashRef, via { 'Google::Cloud::Bigquery::Migration::V2::TranslationConfig::TranslationConfigDetails'->new($_) };

declare 'RepeatedTranslationConfigDetails',
    as ArrayRef[TranslationConfigDetails()];

coerce 'RepeatedTranslationConfigDetails',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Migration::V2::TranslationConfig::TranslationConfigDetails'->new($_) } @$_ ] };

declare 'MapStringTranslationConfigDetails',
    as HashRef[TranslationConfigDetails()];

declare 'Dialect',
    as InstanceOf['Google::Cloud::Bigquery::Migration::V2::TranslationConfig::Dialect'];

coerce 'Dialect',
    from HashRef, via { 'Google::Cloud::Bigquery::Migration::V2::TranslationConfig::Dialect'->new($_) };

declare 'RepeatedDialect',
    as ArrayRef[Dialect()];

coerce 'RepeatedDialect',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Migration::V2::TranslationConfig::Dialect'->new($_) } @$_ ] };

declare 'MapStringDialect',
    as HashRef[Dialect()];

declare 'BigQueryDialect',
    as InstanceOf['Google::Cloud::Bigquery::Migration::V2::TranslationConfig::BigQueryDialect'];

coerce 'BigQueryDialect',
    from HashRef, via { 'Google::Cloud::Bigquery::Migration::V2::TranslationConfig::BigQueryDialect'->new($_) };

declare 'RepeatedBigQueryDialect',
    as ArrayRef[BigQueryDialect()];

coerce 'RepeatedBigQueryDialect',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Migration::V2::TranslationConfig::BigQueryDialect'->new($_) } @$_ ] };

declare 'MapStringBigQueryDialect',
    as HashRef[BigQueryDialect()];

declare 'HiveQLDialect',
    as InstanceOf['Google::Cloud::Bigquery::Migration::V2::TranslationConfig::HiveQLDialect'];

coerce 'HiveQLDialect',
    from HashRef, via { 'Google::Cloud::Bigquery::Migration::V2::TranslationConfig::HiveQLDialect'->new($_) };

declare 'RepeatedHiveQLDialect',
    as ArrayRef[HiveQLDialect()];

coerce 'RepeatedHiveQLDialect',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Migration::V2::TranslationConfig::HiveQLDialect'->new($_) } @$_ ] };

declare 'MapStringHiveQLDialect',
    as HashRef[HiveQLDialect()];

declare 'RedshiftDialect',
    as InstanceOf['Google::Cloud::Bigquery::Migration::V2::TranslationConfig::RedshiftDialect'];

coerce 'RedshiftDialect',
    from HashRef, via { 'Google::Cloud::Bigquery::Migration::V2::TranslationConfig::RedshiftDialect'->new($_) };

declare 'RepeatedRedshiftDialect',
    as ArrayRef[RedshiftDialect()];

coerce 'RepeatedRedshiftDialect',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Migration::V2::TranslationConfig::RedshiftDialect'->new($_) } @$_ ] };

declare 'MapStringRedshiftDialect',
    as HashRef[RedshiftDialect()];

declare 'TeradataDialect',
    as InstanceOf['Google::Cloud::Bigquery::Migration::V2::TranslationConfig::TeradataDialect'];

coerce 'TeradataDialect',
    from HashRef, via { 'Google::Cloud::Bigquery::Migration::V2::TranslationConfig::TeradataDialect'->new($_) };

declare 'RepeatedTeradataDialect',
    as ArrayRef[TeradataDialect()];

coerce 'RepeatedTeradataDialect',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Migration::V2::TranslationConfig::TeradataDialect'->new($_) } @$_ ] };

declare 'MapStringTeradataDialect',
    as HashRef[TeradataDialect()];

declare 'Mode',
    as (Int | Str);

declare 'OracleDialect',
    as InstanceOf['Google::Cloud::Bigquery::Migration::V2::TranslationConfig::OracleDialect'];

coerce 'OracleDialect',
    from HashRef, via { 'Google::Cloud::Bigquery::Migration::V2::TranslationConfig::OracleDialect'->new($_) };

declare 'RepeatedOracleDialect',
    as ArrayRef[OracleDialect()];

coerce 'RepeatedOracleDialect',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Migration::V2::TranslationConfig::OracleDialect'->new($_) } @$_ ] };

declare 'MapStringOracleDialect',
    as HashRef[OracleDialect()];

declare 'SparkSQLDialect',
    as InstanceOf['Google::Cloud::Bigquery::Migration::V2::TranslationConfig::SparkSQLDialect'];

coerce 'SparkSQLDialect',
    from HashRef, via { 'Google::Cloud::Bigquery::Migration::V2::TranslationConfig::SparkSQLDialect'->new($_) };

declare 'RepeatedSparkSQLDialect',
    as ArrayRef[SparkSQLDialect()];

coerce 'RepeatedSparkSQLDialect',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Migration::V2::TranslationConfig::SparkSQLDialect'->new($_) } @$_ ] };

declare 'MapStringSparkSQLDialect',
    as HashRef[SparkSQLDialect()];

declare 'SnowflakeDialect',
    as InstanceOf['Google::Cloud::Bigquery::Migration::V2::TranslationConfig::SnowflakeDialect'];

coerce 'SnowflakeDialect',
    from HashRef, via { 'Google::Cloud::Bigquery::Migration::V2::TranslationConfig::SnowflakeDialect'->new($_) };

declare 'RepeatedSnowflakeDialect',
    as ArrayRef[SnowflakeDialect()];

coerce 'RepeatedSnowflakeDialect',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Migration::V2::TranslationConfig::SnowflakeDialect'->new($_) } @$_ ] };

declare 'MapStringSnowflakeDialect',
    as HashRef[SnowflakeDialect()];

declare 'NetezzaDialect',
    as InstanceOf['Google::Cloud::Bigquery::Migration::V2::TranslationConfig::NetezzaDialect'];

coerce 'NetezzaDialect',
    from HashRef, via { 'Google::Cloud::Bigquery::Migration::V2::TranslationConfig::NetezzaDialect'->new($_) };

declare 'RepeatedNetezzaDialect',
    as ArrayRef[NetezzaDialect()];

coerce 'RepeatedNetezzaDialect',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Migration::V2::TranslationConfig::NetezzaDialect'->new($_) } @$_ ] };

declare 'MapStringNetezzaDialect',
    as HashRef[NetezzaDialect()];

declare 'AzureSynapseDialect',
    as InstanceOf['Google::Cloud::Bigquery::Migration::V2::TranslationConfig::AzureSynapseDialect'];

coerce 'AzureSynapseDialect',
    from HashRef, via { 'Google::Cloud::Bigquery::Migration::V2::TranslationConfig::AzureSynapseDialect'->new($_) };

declare 'RepeatedAzureSynapseDialect',
    as ArrayRef[AzureSynapseDialect()];

coerce 'RepeatedAzureSynapseDialect',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Migration::V2::TranslationConfig::AzureSynapseDialect'->new($_) } @$_ ] };

declare 'MapStringAzureSynapseDialect',
    as HashRef[AzureSynapseDialect()];

declare 'VerticaDialect',
    as InstanceOf['Google::Cloud::Bigquery::Migration::V2::TranslationConfig::VerticaDialect'];

coerce 'VerticaDialect',
    from HashRef, via { 'Google::Cloud::Bigquery::Migration::V2::TranslationConfig::VerticaDialect'->new($_) };

declare 'RepeatedVerticaDialect',
    as ArrayRef[VerticaDialect()];

coerce 'RepeatedVerticaDialect',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Migration::V2::TranslationConfig::VerticaDialect'->new($_) } @$_ ] };

declare 'MapStringVerticaDialect',
    as HashRef[VerticaDialect()];

declare 'SQLServerDialect',
    as InstanceOf['Google::Cloud::Bigquery::Migration::V2::TranslationConfig::SQLServerDialect'];

coerce 'SQLServerDialect',
    from HashRef, via { 'Google::Cloud::Bigquery::Migration::V2::TranslationConfig::SQLServerDialect'->new($_) };

declare 'RepeatedSQLServerDialect',
    as ArrayRef[SQLServerDialect()];

coerce 'RepeatedSQLServerDialect',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Migration::V2::TranslationConfig::SQLServerDialect'->new($_) } @$_ ] };

declare 'MapStringSQLServerDialect',
    as HashRef[SQLServerDialect()];

declare 'PostgresqlDialect',
    as InstanceOf['Google::Cloud::Bigquery::Migration::V2::TranslationConfig::PostgresqlDialect'];

coerce 'PostgresqlDialect',
    from HashRef, via { 'Google::Cloud::Bigquery::Migration::V2::TranslationConfig::PostgresqlDialect'->new($_) };

declare 'RepeatedPostgresqlDialect',
    as ArrayRef[PostgresqlDialect()];

coerce 'RepeatedPostgresqlDialect',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Migration::V2::TranslationConfig::PostgresqlDialect'->new($_) } @$_ ] };

declare 'MapStringPostgresqlDialect',
    as HashRef[PostgresqlDialect()];

declare 'PrestoDialect',
    as InstanceOf['Google::Cloud::Bigquery::Migration::V2::TranslationConfig::PrestoDialect'];

coerce 'PrestoDialect',
    from HashRef, via { 'Google::Cloud::Bigquery::Migration::V2::TranslationConfig::PrestoDialect'->new($_) };

declare 'RepeatedPrestoDialect',
    as ArrayRef[PrestoDialect()];

coerce 'RepeatedPrestoDialect',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Migration::V2::TranslationConfig::PrestoDialect'->new($_) } @$_ ] };

declare 'MapStringPrestoDialect',
    as HashRef[PrestoDialect()];

declare 'MySQLDialect',
    as InstanceOf['Google::Cloud::Bigquery::Migration::V2::TranslationConfig::MySQLDialect'];

coerce 'MySQLDialect',
    from HashRef, via { 'Google::Cloud::Bigquery::Migration::V2::TranslationConfig::MySQLDialect'->new($_) };

declare 'RepeatedMySQLDialect',
    as ArrayRef[MySQLDialect()];

coerce 'RepeatedMySQLDialect',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Migration::V2::TranslationConfig::MySQLDialect'->new($_) } @$_ ] };

declare 'MapStringMySQLDialect',
    as HashRef[MySQLDialect()];

declare 'DB2Dialect',
    as InstanceOf['Google::Cloud::Bigquery::Migration::V2::TranslationConfig::DB2Dialect'];

coerce 'DB2Dialect',
    from HashRef, via { 'Google::Cloud::Bigquery::Migration::V2::TranslationConfig::DB2Dialect'->new($_) };

declare 'RepeatedDB2Dialect',
    as ArrayRef[DB2Dialect()];

coerce 'RepeatedDB2Dialect',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Migration::V2::TranslationConfig::DB2Dialect'->new($_) } @$_ ] };

declare 'MapStringDB2Dialect',
    as HashRef[DB2Dialect()];

declare 'SQLiteDialect',
    as InstanceOf['Google::Cloud::Bigquery::Migration::V2::TranslationConfig::SQLiteDialect'];

coerce 'SQLiteDialect',
    from HashRef, via { 'Google::Cloud::Bigquery::Migration::V2::TranslationConfig::SQLiteDialect'->new($_) };

declare 'RepeatedSQLiteDialect',
    as ArrayRef[SQLiteDialect()];

coerce 'RepeatedSQLiteDialect',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Migration::V2::TranslationConfig::SQLiteDialect'->new($_) } @$_ ] };

declare 'MapStringSQLiteDialect',
    as HashRef[SQLiteDialect()];

declare 'GreenplumDialect',
    as InstanceOf['Google::Cloud::Bigquery::Migration::V2::TranslationConfig::GreenplumDialect'];

coerce 'GreenplumDialect',
    from HashRef, via { 'Google::Cloud::Bigquery::Migration::V2::TranslationConfig::GreenplumDialect'->new($_) };

declare 'RepeatedGreenplumDialect',
    as ArrayRef[GreenplumDialect()];

coerce 'RepeatedGreenplumDialect',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Migration::V2::TranslationConfig::GreenplumDialect'->new($_) } @$_ ] };

declare 'MapStringGreenplumDialect',
    as HashRef[GreenplumDialect()];

declare 'ObjectNameMappingList',
    as InstanceOf['Google::Cloud::Bigquery::Migration::V2::TranslationConfig::ObjectNameMappingList'];

coerce 'ObjectNameMappingList',
    from HashRef, via { 'Google::Cloud::Bigquery::Migration::V2::TranslationConfig::ObjectNameMappingList'->new($_) };

declare 'RepeatedObjectNameMappingList',
    as ArrayRef[ObjectNameMappingList()];

coerce 'RepeatedObjectNameMappingList',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Migration::V2::TranslationConfig::ObjectNameMappingList'->new($_) } @$_ ] };

declare 'MapStringObjectNameMappingList',
    as HashRef[ObjectNameMappingList()];

declare 'ObjectNameMapping',
    as InstanceOf['Google::Cloud::Bigquery::Migration::V2::TranslationConfig::ObjectNameMapping'];

coerce 'ObjectNameMapping',
    from HashRef, via { 'Google::Cloud::Bigquery::Migration::V2::TranslationConfig::ObjectNameMapping'->new($_) };

declare 'RepeatedObjectNameMapping',
    as ArrayRef[ObjectNameMapping()];

coerce 'RepeatedObjectNameMapping',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Migration::V2::TranslationConfig::ObjectNameMapping'->new($_) } @$_ ] };

declare 'MapStringObjectNameMapping',
    as HashRef[ObjectNameMapping()];

declare 'NameMappingKey',
    as InstanceOf['Google::Cloud::Bigquery::Migration::V2::TranslationConfig::NameMappingKey'];

coerce 'NameMappingKey',
    from HashRef, via { 'Google::Cloud::Bigquery::Migration::V2::TranslationConfig::NameMappingKey'->new($_) };

declare 'RepeatedNameMappingKey',
    as ArrayRef[NameMappingKey()];

coerce 'RepeatedNameMappingKey',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Migration::V2::TranslationConfig::NameMappingKey'->new($_) } @$_ ] };

declare 'MapStringNameMappingKey',
    as HashRef[NameMappingKey()];

declare 'Type',
    as (Int | Str);

declare 'NameMappingValue',
    as InstanceOf['Google::Cloud::Bigquery::Migration::V2::TranslationConfig::NameMappingValue'];

coerce 'NameMappingValue',
    from HashRef, via { 'Google::Cloud::Bigquery::Migration::V2::TranslationConfig::NameMappingValue'->new($_) };

declare 'RepeatedNameMappingValue',
    as ArrayRef[NameMappingValue()];

coerce 'RepeatedNameMappingValue',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Migration::V2::TranslationConfig::NameMappingValue'->new($_) } @$_ ] };

declare 'MapStringNameMappingValue',
    as HashRef[NameMappingValue()];

declare 'SourceEnv',
    as InstanceOf['Google::Cloud::Bigquery::Migration::V2::TranslationConfig::SourceEnv'];

coerce 'SourceEnv',
    from HashRef, via { 'Google::Cloud::Bigquery::Migration::V2::TranslationConfig::SourceEnv'->new($_) };

declare 'RepeatedSourceEnv',
    as ArrayRef[SourceEnv()];

coerce 'RepeatedSourceEnv',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Migration::V2::TranslationConfig::SourceEnv'->new($_) } @$_ ] };

declare 'MapStringSourceEnv',
    as HashRef[SourceEnv()];

1;

__END__

=head1 NAME

Google::Cloud::Bigquery::Migration::V2::TranslationConfig::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
