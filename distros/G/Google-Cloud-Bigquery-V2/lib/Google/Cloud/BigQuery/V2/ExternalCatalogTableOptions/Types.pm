package Google::Cloud::BigQuery::V2::ExternalCatalogTableOptions::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'ExternalCatalogTableOptions',
    as InstanceOf['Google::Cloud::BigQuery::V2::ExternalCatalogTableOptions::ExternalCatalogTableOptions'];

coerce 'ExternalCatalogTableOptions',
    from HashRef, via { 'Google::Cloud::BigQuery::V2::ExternalCatalogTableOptions::ExternalCatalogTableOptions'->new($_) };

declare 'RepeatedExternalCatalogTableOptions',
    as ArrayRef[ExternalCatalogTableOptions()];

coerce 'RepeatedExternalCatalogTableOptions',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::BigQuery::V2::ExternalCatalogTableOptions::ExternalCatalogTableOptions'->new($_) } @$_ ] };

declare 'MapStringExternalCatalogTableOptions',
    as HashRef[ExternalCatalogTableOptions()];

declare 'ParametersEntry',
    as InstanceOf['Google::Cloud::BigQuery::V2::ExternalCatalogTableOptions::ExternalCatalogTableOptions::ParametersEntry'];

coerce 'ParametersEntry',
    from HashRef, via { 'Google::Cloud::BigQuery::V2::ExternalCatalogTableOptions::ExternalCatalogTableOptions::ParametersEntry'->new($_) };

declare 'RepeatedParametersEntry',
    as ArrayRef[ParametersEntry()];

coerce 'RepeatedParametersEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::BigQuery::V2::ExternalCatalogTableOptions::ExternalCatalogTableOptions::ParametersEntry'->new($_) } @$_ ] };

declare 'MapStringParametersEntry',
    as HashRef[ParametersEntry()];

declare 'StorageDescriptor',
    as InstanceOf['Google::Cloud::BigQuery::V2::ExternalCatalogTableOptions::StorageDescriptor'];

coerce 'StorageDescriptor',
    from HashRef, via { 'Google::Cloud::BigQuery::V2::ExternalCatalogTableOptions::StorageDescriptor'->new($_) };

declare 'RepeatedStorageDescriptor',
    as ArrayRef[StorageDescriptor()];

coerce 'RepeatedStorageDescriptor',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::BigQuery::V2::ExternalCatalogTableOptions::StorageDescriptor'->new($_) } @$_ ] };

declare 'MapStringStorageDescriptor',
    as HashRef[StorageDescriptor()];

declare 'SerDeInfo',
    as InstanceOf['Google::Cloud::BigQuery::V2::ExternalCatalogTableOptions::SerDeInfo'];

coerce 'SerDeInfo',
    from HashRef, via { 'Google::Cloud::BigQuery::V2::ExternalCatalogTableOptions::SerDeInfo'->new($_) };

declare 'RepeatedSerDeInfo',
    as ArrayRef[SerDeInfo()];

coerce 'RepeatedSerDeInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::BigQuery::V2::ExternalCatalogTableOptions::SerDeInfo'->new($_) } @$_ ] };

declare 'MapStringSerDeInfo',
    as HashRef[SerDeInfo()];

declare 'ParametersEntry',
    as InstanceOf['Google::Cloud::BigQuery::V2::ExternalCatalogTableOptions::SerDeInfo::ParametersEntry'];

coerce 'ParametersEntry',
    from HashRef, via { 'Google::Cloud::BigQuery::V2::ExternalCatalogTableOptions::SerDeInfo::ParametersEntry'->new($_) };

declare 'RepeatedParametersEntry',
    as ArrayRef[ParametersEntry()];

coerce 'RepeatedParametersEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::BigQuery::V2::ExternalCatalogTableOptions::SerDeInfo::ParametersEntry'->new($_) } @$_ ] };

declare 'MapStringParametersEntry',
    as HashRef[ParametersEntry()];

1;
