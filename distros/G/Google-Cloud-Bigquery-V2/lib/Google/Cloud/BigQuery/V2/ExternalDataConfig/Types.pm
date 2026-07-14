package Google::Cloud::BigQuery::V2::ExternalDataConfig::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'AvroOptions',
    as InstanceOf['Google::Cloud::BigQuery::V2::ExternalDataConfig::AvroOptions'];

coerce 'AvroOptions',
    from HashRef, via { 'Google::Cloud::BigQuery::V2::ExternalDataConfig::AvroOptions'->new($_) };

declare 'RepeatedAvroOptions',
    as ArrayRef[AvroOptions()];

coerce 'RepeatedAvroOptions',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::BigQuery::V2::ExternalDataConfig::AvroOptions'->new($_) } @$_ ] };

declare 'MapStringAvroOptions',
    as HashRef[AvroOptions()];

declare 'ParquetOptions',
    as InstanceOf['Google::Cloud::BigQuery::V2::ExternalDataConfig::ParquetOptions'];

coerce 'ParquetOptions',
    from HashRef, via { 'Google::Cloud::BigQuery::V2::ExternalDataConfig::ParquetOptions'->new($_) };

declare 'RepeatedParquetOptions',
    as ArrayRef[ParquetOptions()];

coerce 'RepeatedParquetOptions',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::BigQuery::V2::ExternalDataConfig::ParquetOptions'->new($_) } @$_ ] };

declare 'MapStringParquetOptions',
    as HashRef[ParquetOptions()];

declare 'CsvOptions',
    as InstanceOf['Google::Cloud::BigQuery::V2::ExternalDataConfig::CsvOptions'];

coerce 'CsvOptions',
    from HashRef, via { 'Google::Cloud::BigQuery::V2::ExternalDataConfig::CsvOptions'->new($_) };

declare 'RepeatedCsvOptions',
    as ArrayRef[CsvOptions()];

coerce 'RepeatedCsvOptions',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::BigQuery::V2::ExternalDataConfig::CsvOptions'->new($_) } @$_ ] };

declare 'MapStringCsvOptions',
    as HashRef[CsvOptions()];

declare 'JsonOptions',
    as InstanceOf['Google::Cloud::BigQuery::V2::ExternalDataConfig::JsonOptions'];

coerce 'JsonOptions',
    from HashRef, via { 'Google::Cloud::BigQuery::V2::ExternalDataConfig::JsonOptions'->new($_) };

declare 'RepeatedJsonOptions',
    as ArrayRef[JsonOptions()];

coerce 'RepeatedJsonOptions',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::BigQuery::V2::ExternalDataConfig::JsonOptions'->new($_) } @$_ ] };

declare 'MapStringJsonOptions',
    as HashRef[JsonOptions()];

declare 'BigtableProtoConfig',
    as InstanceOf['Google::Cloud::BigQuery::V2::ExternalDataConfig::BigtableProtoConfig'];

coerce 'BigtableProtoConfig',
    from HashRef, via { 'Google::Cloud::BigQuery::V2::ExternalDataConfig::BigtableProtoConfig'->new($_) };

declare 'RepeatedBigtableProtoConfig',
    as ArrayRef[BigtableProtoConfig()];

coerce 'RepeatedBigtableProtoConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::BigQuery::V2::ExternalDataConfig::BigtableProtoConfig'->new($_) } @$_ ] };

declare 'MapStringBigtableProtoConfig',
    as HashRef[BigtableProtoConfig()];

declare 'BigtableColumn',
    as InstanceOf['Google::Cloud::BigQuery::V2::ExternalDataConfig::BigtableColumn'];

coerce 'BigtableColumn',
    from HashRef, via { 'Google::Cloud::BigQuery::V2::ExternalDataConfig::BigtableColumn'->new($_) };

declare 'RepeatedBigtableColumn',
    as ArrayRef[BigtableColumn()];

coerce 'RepeatedBigtableColumn',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::BigQuery::V2::ExternalDataConfig::BigtableColumn'->new($_) } @$_ ] };

declare 'MapStringBigtableColumn',
    as HashRef[BigtableColumn()];

declare 'BigtableColumnFamily',
    as InstanceOf['Google::Cloud::BigQuery::V2::ExternalDataConfig::BigtableColumnFamily'];

coerce 'BigtableColumnFamily',
    from HashRef, via { 'Google::Cloud::BigQuery::V2::ExternalDataConfig::BigtableColumnFamily'->new($_) };

declare 'RepeatedBigtableColumnFamily',
    as ArrayRef[BigtableColumnFamily()];

coerce 'RepeatedBigtableColumnFamily',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::BigQuery::V2::ExternalDataConfig::BigtableColumnFamily'->new($_) } @$_ ] };

declare 'MapStringBigtableColumnFamily',
    as HashRef[BigtableColumnFamily()];

declare 'BigtableOptions',
    as InstanceOf['Google::Cloud::BigQuery::V2::ExternalDataConfig::BigtableOptions'];

coerce 'BigtableOptions',
    from HashRef, via { 'Google::Cloud::BigQuery::V2::ExternalDataConfig::BigtableOptions'->new($_) };

declare 'RepeatedBigtableOptions',
    as ArrayRef[BigtableOptions()];

coerce 'RepeatedBigtableOptions',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::BigQuery::V2::ExternalDataConfig::BigtableOptions'->new($_) } @$_ ] };

declare 'MapStringBigtableOptions',
    as HashRef[BigtableOptions()];

declare 'GoogleSheetsOptions',
    as InstanceOf['Google::Cloud::BigQuery::V2::ExternalDataConfig::GoogleSheetsOptions'];

coerce 'GoogleSheetsOptions',
    from HashRef, via { 'Google::Cloud::BigQuery::V2::ExternalDataConfig::GoogleSheetsOptions'->new($_) };

declare 'RepeatedGoogleSheetsOptions',
    as ArrayRef[GoogleSheetsOptions()];

coerce 'RepeatedGoogleSheetsOptions',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::BigQuery::V2::ExternalDataConfig::GoogleSheetsOptions'->new($_) } @$_ ] };

declare 'MapStringGoogleSheetsOptions',
    as HashRef[GoogleSheetsOptions()];

declare 'ExternalDataConfiguration',
    as InstanceOf['Google::Cloud::BigQuery::V2::ExternalDataConfig::ExternalDataConfiguration'];

coerce 'ExternalDataConfiguration',
    from HashRef, via { 'Google::Cloud::BigQuery::V2::ExternalDataConfig::ExternalDataConfiguration'->new($_) };

declare 'RepeatedExternalDataConfiguration',
    as ArrayRef[ExternalDataConfiguration()];

coerce 'RepeatedExternalDataConfiguration',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::BigQuery::V2::ExternalDataConfig::ExternalDataConfiguration'->new($_) } @$_ ] };

declare 'MapStringExternalDataConfiguration',
    as HashRef[ExternalDataConfiguration()];

declare 'ObjectMetadata',
    as (Int | Str);

declare 'MetadataCacheMode',
    as (Int | Str);

1;
