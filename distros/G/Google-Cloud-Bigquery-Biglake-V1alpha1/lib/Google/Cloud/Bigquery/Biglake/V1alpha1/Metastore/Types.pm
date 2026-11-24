package Google::Cloud::Bigquery::Biglake::V1alpha1::Metastore::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'TableView',
    as (Int | Str);

declare 'Catalog',
    as InstanceOf['Google::Cloud::Bigquery::Biglake::V1alpha1::Metastore::Catalog'];

coerce 'Catalog',
    from HashRef, via { 'Google::Cloud::Bigquery::Biglake::V1alpha1::Metastore::Catalog'->new($_) };

declare 'RepeatedCatalog',
    as ArrayRef[Catalog()];

coerce 'RepeatedCatalog',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Biglake::V1alpha1::Metastore::Catalog'->new($_) } @$_ ] };

declare 'MapStringCatalog',
    as HashRef[Catalog()];

declare 'Database',
    as InstanceOf['Google::Cloud::Bigquery::Biglake::V1alpha1::Metastore::Database'];

coerce 'Database',
    from HashRef, via { 'Google::Cloud::Bigquery::Biglake::V1alpha1::Metastore::Database'->new($_) };

declare 'RepeatedDatabase',
    as ArrayRef[Database()];

coerce 'RepeatedDatabase',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Biglake::V1alpha1::Metastore::Database'->new($_) } @$_ ] };

declare 'MapStringDatabase',
    as HashRef[Database()];

declare 'Type',
    as (Int | Str);

declare 'Table',
    as InstanceOf['Google::Cloud::Bigquery::Biglake::V1alpha1::Metastore::Table'];

coerce 'Table',
    from HashRef, via { 'Google::Cloud::Bigquery::Biglake::V1alpha1::Metastore::Table'->new($_) };

declare 'RepeatedTable',
    as ArrayRef[Table()];

coerce 'RepeatedTable',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Biglake::V1alpha1::Metastore::Table'->new($_) } @$_ ] };

declare 'MapStringTable',
    as HashRef[Table()];

declare 'Type',
    as (Int | Str);

declare 'Lock',
    as InstanceOf['Google::Cloud::Bigquery::Biglake::V1alpha1::Metastore::Lock'];

coerce 'Lock',
    from HashRef, via { 'Google::Cloud::Bigquery::Biglake::V1alpha1::Metastore::Lock'->new($_) };

declare 'RepeatedLock',
    as ArrayRef[Lock()];

coerce 'RepeatedLock',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Biglake::V1alpha1::Metastore::Lock'->new($_) } @$_ ] };

declare 'MapStringLock',
    as HashRef[Lock()];

declare 'Type',
    as (Int | Str);

declare 'State',
    as (Int | Str);

declare 'CreateCatalogRequest',
    as InstanceOf['Google::Cloud::Bigquery::Biglake::V1alpha1::Metastore::CreateCatalogRequest'];

coerce 'CreateCatalogRequest',
    from HashRef, via { 'Google::Cloud::Bigquery::Biglake::V1alpha1::Metastore::CreateCatalogRequest'->new($_) };

declare 'RepeatedCreateCatalogRequest',
    as ArrayRef[CreateCatalogRequest()];

coerce 'RepeatedCreateCatalogRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Biglake::V1alpha1::Metastore::CreateCatalogRequest'->new($_) } @$_ ] };

declare 'MapStringCreateCatalogRequest',
    as HashRef[CreateCatalogRequest()];

declare 'DeleteCatalogRequest',
    as InstanceOf['Google::Cloud::Bigquery::Biglake::V1alpha1::Metastore::DeleteCatalogRequest'];

coerce 'DeleteCatalogRequest',
    from HashRef, via { 'Google::Cloud::Bigquery::Biglake::V1alpha1::Metastore::DeleteCatalogRequest'->new($_) };

declare 'RepeatedDeleteCatalogRequest',
    as ArrayRef[DeleteCatalogRequest()];

coerce 'RepeatedDeleteCatalogRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Biglake::V1alpha1::Metastore::DeleteCatalogRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteCatalogRequest',
    as HashRef[DeleteCatalogRequest()];

declare 'GetCatalogRequest',
    as InstanceOf['Google::Cloud::Bigquery::Biglake::V1alpha1::Metastore::GetCatalogRequest'];

coerce 'GetCatalogRequest',
    from HashRef, via { 'Google::Cloud::Bigquery::Biglake::V1alpha1::Metastore::GetCatalogRequest'->new($_) };

declare 'RepeatedGetCatalogRequest',
    as ArrayRef[GetCatalogRequest()];

coerce 'RepeatedGetCatalogRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Biglake::V1alpha1::Metastore::GetCatalogRequest'->new($_) } @$_ ] };

declare 'MapStringGetCatalogRequest',
    as HashRef[GetCatalogRequest()];

declare 'ListCatalogsRequest',
    as InstanceOf['Google::Cloud::Bigquery::Biglake::V1alpha1::Metastore::ListCatalogsRequest'];

coerce 'ListCatalogsRequest',
    from HashRef, via { 'Google::Cloud::Bigquery::Biglake::V1alpha1::Metastore::ListCatalogsRequest'->new($_) };

declare 'RepeatedListCatalogsRequest',
    as ArrayRef[ListCatalogsRequest()];

coerce 'RepeatedListCatalogsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Biglake::V1alpha1::Metastore::ListCatalogsRequest'->new($_) } @$_ ] };

declare 'MapStringListCatalogsRequest',
    as HashRef[ListCatalogsRequest()];

declare 'ListCatalogsResponse',
    as InstanceOf['Google::Cloud::Bigquery::Biglake::V1alpha1::Metastore::ListCatalogsResponse'];

coerce 'ListCatalogsResponse',
    from HashRef, via { 'Google::Cloud::Bigquery::Biglake::V1alpha1::Metastore::ListCatalogsResponse'->new($_) };

declare 'RepeatedListCatalogsResponse',
    as ArrayRef[ListCatalogsResponse()];

coerce 'RepeatedListCatalogsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Biglake::V1alpha1::Metastore::ListCatalogsResponse'->new($_) } @$_ ] };

declare 'MapStringListCatalogsResponse',
    as HashRef[ListCatalogsResponse()];

declare 'CreateDatabaseRequest',
    as InstanceOf['Google::Cloud::Bigquery::Biglake::V1alpha1::Metastore::CreateDatabaseRequest'];

coerce 'CreateDatabaseRequest',
    from HashRef, via { 'Google::Cloud::Bigquery::Biglake::V1alpha1::Metastore::CreateDatabaseRequest'->new($_) };

declare 'RepeatedCreateDatabaseRequest',
    as ArrayRef[CreateDatabaseRequest()];

coerce 'RepeatedCreateDatabaseRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Biglake::V1alpha1::Metastore::CreateDatabaseRequest'->new($_) } @$_ ] };

declare 'MapStringCreateDatabaseRequest',
    as HashRef[CreateDatabaseRequest()];

declare 'DeleteDatabaseRequest',
    as InstanceOf['Google::Cloud::Bigquery::Biglake::V1alpha1::Metastore::DeleteDatabaseRequest'];

coerce 'DeleteDatabaseRequest',
    from HashRef, via { 'Google::Cloud::Bigquery::Biglake::V1alpha1::Metastore::DeleteDatabaseRequest'->new($_) };

declare 'RepeatedDeleteDatabaseRequest',
    as ArrayRef[DeleteDatabaseRequest()];

coerce 'RepeatedDeleteDatabaseRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Biglake::V1alpha1::Metastore::DeleteDatabaseRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteDatabaseRequest',
    as HashRef[DeleteDatabaseRequest()];

declare 'UpdateDatabaseRequest',
    as InstanceOf['Google::Cloud::Bigquery::Biglake::V1alpha1::Metastore::UpdateDatabaseRequest'];

coerce 'UpdateDatabaseRequest',
    from HashRef, via { 'Google::Cloud::Bigquery::Biglake::V1alpha1::Metastore::UpdateDatabaseRequest'->new($_) };

declare 'RepeatedUpdateDatabaseRequest',
    as ArrayRef[UpdateDatabaseRequest()];

coerce 'RepeatedUpdateDatabaseRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Biglake::V1alpha1::Metastore::UpdateDatabaseRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateDatabaseRequest',
    as HashRef[UpdateDatabaseRequest()];

declare 'GetDatabaseRequest',
    as InstanceOf['Google::Cloud::Bigquery::Biglake::V1alpha1::Metastore::GetDatabaseRequest'];

coerce 'GetDatabaseRequest',
    from HashRef, via { 'Google::Cloud::Bigquery::Biglake::V1alpha1::Metastore::GetDatabaseRequest'->new($_) };

declare 'RepeatedGetDatabaseRequest',
    as ArrayRef[GetDatabaseRequest()];

coerce 'RepeatedGetDatabaseRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Biglake::V1alpha1::Metastore::GetDatabaseRequest'->new($_) } @$_ ] };

declare 'MapStringGetDatabaseRequest',
    as HashRef[GetDatabaseRequest()];

declare 'ListDatabasesRequest',
    as InstanceOf['Google::Cloud::Bigquery::Biglake::V1alpha1::Metastore::ListDatabasesRequest'];

coerce 'ListDatabasesRequest',
    from HashRef, via { 'Google::Cloud::Bigquery::Biglake::V1alpha1::Metastore::ListDatabasesRequest'->new($_) };

declare 'RepeatedListDatabasesRequest',
    as ArrayRef[ListDatabasesRequest()];

coerce 'RepeatedListDatabasesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Biglake::V1alpha1::Metastore::ListDatabasesRequest'->new($_) } @$_ ] };

declare 'MapStringListDatabasesRequest',
    as HashRef[ListDatabasesRequest()];

declare 'ListDatabasesResponse',
    as InstanceOf['Google::Cloud::Bigquery::Biglake::V1alpha1::Metastore::ListDatabasesResponse'];

coerce 'ListDatabasesResponse',
    from HashRef, via { 'Google::Cloud::Bigquery::Biglake::V1alpha1::Metastore::ListDatabasesResponse'->new($_) };

declare 'RepeatedListDatabasesResponse',
    as ArrayRef[ListDatabasesResponse()];

coerce 'RepeatedListDatabasesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Biglake::V1alpha1::Metastore::ListDatabasesResponse'->new($_) } @$_ ] };

declare 'MapStringListDatabasesResponse',
    as HashRef[ListDatabasesResponse()];

declare 'CreateTableRequest',
    as InstanceOf['Google::Cloud::Bigquery::Biglake::V1alpha1::Metastore::CreateTableRequest'];

coerce 'CreateTableRequest',
    from HashRef, via { 'Google::Cloud::Bigquery::Biglake::V1alpha1::Metastore::CreateTableRequest'->new($_) };

declare 'RepeatedCreateTableRequest',
    as ArrayRef[CreateTableRequest()];

coerce 'RepeatedCreateTableRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Biglake::V1alpha1::Metastore::CreateTableRequest'->new($_) } @$_ ] };

declare 'MapStringCreateTableRequest',
    as HashRef[CreateTableRequest()];

declare 'DeleteTableRequest',
    as InstanceOf['Google::Cloud::Bigquery::Biglake::V1alpha1::Metastore::DeleteTableRequest'];

coerce 'DeleteTableRequest',
    from HashRef, via { 'Google::Cloud::Bigquery::Biglake::V1alpha1::Metastore::DeleteTableRequest'->new($_) };

declare 'RepeatedDeleteTableRequest',
    as ArrayRef[DeleteTableRequest()];

coerce 'RepeatedDeleteTableRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Biglake::V1alpha1::Metastore::DeleteTableRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteTableRequest',
    as HashRef[DeleteTableRequest()];

declare 'UpdateTableRequest',
    as InstanceOf['Google::Cloud::Bigquery::Biglake::V1alpha1::Metastore::UpdateTableRequest'];

coerce 'UpdateTableRequest',
    from HashRef, via { 'Google::Cloud::Bigquery::Biglake::V1alpha1::Metastore::UpdateTableRequest'->new($_) };

declare 'RepeatedUpdateTableRequest',
    as ArrayRef[UpdateTableRequest()];

coerce 'RepeatedUpdateTableRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Biglake::V1alpha1::Metastore::UpdateTableRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateTableRequest',
    as HashRef[UpdateTableRequest()];

declare 'RenameTableRequest',
    as InstanceOf['Google::Cloud::Bigquery::Biglake::V1alpha1::Metastore::RenameTableRequest'];

coerce 'RenameTableRequest',
    from HashRef, via { 'Google::Cloud::Bigquery::Biglake::V1alpha1::Metastore::RenameTableRequest'->new($_) };

declare 'RepeatedRenameTableRequest',
    as ArrayRef[RenameTableRequest()];

coerce 'RepeatedRenameTableRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Biglake::V1alpha1::Metastore::RenameTableRequest'->new($_) } @$_ ] };

declare 'MapStringRenameTableRequest',
    as HashRef[RenameTableRequest()];

declare 'GetTableRequest',
    as InstanceOf['Google::Cloud::Bigquery::Biglake::V1alpha1::Metastore::GetTableRequest'];

coerce 'GetTableRequest',
    from HashRef, via { 'Google::Cloud::Bigquery::Biglake::V1alpha1::Metastore::GetTableRequest'->new($_) };

declare 'RepeatedGetTableRequest',
    as ArrayRef[GetTableRequest()];

coerce 'RepeatedGetTableRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Biglake::V1alpha1::Metastore::GetTableRequest'->new($_) } @$_ ] };

declare 'MapStringGetTableRequest',
    as HashRef[GetTableRequest()];

declare 'ListTablesRequest',
    as InstanceOf['Google::Cloud::Bigquery::Biglake::V1alpha1::Metastore::ListTablesRequest'];

coerce 'ListTablesRequest',
    from HashRef, via { 'Google::Cloud::Bigquery::Biglake::V1alpha1::Metastore::ListTablesRequest'->new($_) };

declare 'RepeatedListTablesRequest',
    as ArrayRef[ListTablesRequest()];

coerce 'RepeatedListTablesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Biglake::V1alpha1::Metastore::ListTablesRequest'->new($_) } @$_ ] };

declare 'MapStringListTablesRequest',
    as HashRef[ListTablesRequest()];

declare 'ListTablesResponse',
    as InstanceOf['Google::Cloud::Bigquery::Biglake::V1alpha1::Metastore::ListTablesResponse'];

coerce 'ListTablesResponse',
    from HashRef, via { 'Google::Cloud::Bigquery::Biglake::V1alpha1::Metastore::ListTablesResponse'->new($_) };

declare 'RepeatedListTablesResponse',
    as ArrayRef[ListTablesResponse()];

coerce 'RepeatedListTablesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Biglake::V1alpha1::Metastore::ListTablesResponse'->new($_) } @$_ ] };

declare 'MapStringListTablesResponse',
    as HashRef[ListTablesResponse()];

declare 'CreateLockRequest',
    as InstanceOf['Google::Cloud::Bigquery::Biglake::V1alpha1::Metastore::CreateLockRequest'];

coerce 'CreateLockRequest',
    from HashRef, via { 'Google::Cloud::Bigquery::Biglake::V1alpha1::Metastore::CreateLockRequest'->new($_) };

declare 'RepeatedCreateLockRequest',
    as ArrayRef[CreateLockRequest()];

coerce 'RepeatedCreateLockRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Biglake::V1alpha1::Metastore::CreateLockRequest'->new($_) } @$_ ] };

declare 'MapStringCreateLockRequest',
    as HashRef[CreateLockRequest()];

declare 'DeleteLockRequest',
    as InstanceOf['Google::Cloud::Bigquery::Biglake::V1alpha1::Metastore::DeleteLockRequest'];

coerce 'DeleteLockRequest',
    from HashRef, via { 'Google::Cloud::Bigquery::Biglake::V1alpha1::Metastore::DeleteLockRequest'->new($_) };

declare 'RepeatedDeleteLockRequest',
    as ArrayRef[DeleteLockRequest()];

coerce 'RepeatedDeleteLockRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Biglake::V1alpha1::Metastore::DeleteLockRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteLockRequest',
    as HashRef[DeleteLockRequest()];

declare 'CheckLockRequest',
    as InstanceOf['Google::Cloud::Bigquery::Biglake::V1alpha1::Metastore::CheckLockRequest'];

coerce 'CheckLockRequest',
    from HashRef, via { 'Google::Cloud::Bigquery::Biglake::V1alpha1::Metastore::CheckLockRequest'->new($_) };

declare 'RepeatedCheckLockRequest',
    as ArrayRef[CheckLockRequest()];

coerce 'RepeatedCheckLockRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Biglake::V1alpha1::Metastore::CheckLockRequest'->new($_) } @$_ ] };

declare 'MapStringCheckLockRequest',
    as HashRef[CheckLockRequest()];

declare 'ListLocksRequest',
    as InstanceOf['Google::Cloud::Bigquery::Biglake::V1alpha1::Metastore::ListLocksRequest'];

coerce 'ListLocksRequest',
    from HashRef, via { 'Google::Cloud::Bigquery::Biglake::V1alpha1::Metastore::ListLocksRequest'->new($_) };

declare 'RepeatedListLocksRequest',
    as ArrayRef[ListLocksRequest()];

coerce 'RepeatedListLocksRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Biglake::V1alpha1::Metastore::ListLocksRequest'->new($_) } @$_ ] };

declare 'MapStringListLocksRequest',
    as HashRef[ListLocksRequest()];

declare 'ListLocksResponse',
    as InstanceOf['Google::Cloud::Bigquery::Biglake::V1alpha1::Metastore::ListLocksResponse'];

coerce 'ListLocksResponse',
    from HashRef, via { 'Google::Cloud::Bigquery::Biglake::V1alpha1::Metastore::ListLocksResponse'->new($_) };

declare 'RepeatedListLocksResponse',
    as ArrayRef[ListLocksResponse()];

coerce 'RepeatedListLocksResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Biglake::V1alpha1::Metastore::ListLocksResponse'->new($_) } @$_ ] };

declare 'MapStringListLocksResponse',
    as HashRef[ListLocksResponse()];

declare 'HiveDatabaseOptions',
    as InstanceOf['Google::Cloud::Bigquery::Biglake::V1alpha1::Metastore::HiveDatabaseOptions'];

coerce 'HiveDatabaseOptions',
    from HashRef, via { 'Google::Cloud::Bigquery::Biglake::V1alpha1::Metastore::HiveDatabaseOptions'->new($_) };

declare 'RepeatedHiveDatabaseOptions',
    as ArrayRef[HiveDatabaseOptions()];

coerce 'RepeatedHiveDatabaseOptions',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Biglake::V1alpha1::Metastore::HiveDatabaseOptions'->new($_) } @$_ ] };

declare 'MapStringHiveDatabaseOptions',
    as HashRef[HiveDatabaseOptions()];

declare 'ParametersEntry',
    as InstanceOf['Google::Cloud::Bigquery::Biglake::V1alpha1::Metastore::HiveDatabaseOptions::ParametersEntry'];

coerce 'ParametersEntry',
    from HashRef, via { 'Google::Cloud::Bigquery::Biglake::V1alpha1::Metastore::HiveDatabaseOptions::ParametersEntry'->new($_) };

declare 'RepeatedParametersEntry',
    as ArrayRef[ParametersEntry()];

coerce 'RepeatedParametersEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Biglake::V1alpha1::Metastore::HiveDatabaseOptions::ParametersEntry'->new($_) } @$_ ] };

declare 'MapStringParametersEntry',
    as HashRef[ParametersEntry()];

declare 'HiveTableOptions',
    as InstanceOf['Google::Cloud::Bigquery::Biglake::V1alpha1::Metastore::HiveTableOptions'];

coerce 'HiveTableOptions',
    from HashRef, via { 'Google::Cloud::Bigquery::Biglake::V1alpha1::Metastore::HiveTableOptions'->new($_) };

declare 'RepeatedHiveTableOptions',
    as ArrayRef[HiveTableOptions()];

coerce 'RepeatedHiveTableOptions',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Biglake::V1alpha1::Metastore::HiveTableOptions'->new($_) } @$_ ] };

declare 'MapStringHiveTableOptions',
    as HashRef[HiveTableOptions()];

declare 'SerDeInfo',
    as InstanceOf['Google::Cloud::Bigquery::Biglake::V1alpha1::Metastore::HiveTableOptions::SerDeInfo'];

coerce 'SerDeInfo',
    from HashRef, via { 'Google::Cloud::Bigquery::Biglake::V1alpha1::Metastore::HiveTableOptions::SerDeInfo'->new($_) };

declare 'RepeatedSerDeInfo',
    as ArrayRef[SerDeInfo()];

coerce 'RepeatedSerDeInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Biglake::V1alpha1::Metastore::HiveTableOptions::SerDeInfo'->new($_) } @$_ ] };

declare 'MapStringSerDeInfo',
    as HashRef[SerDeInfo()];

declare 'StorageDescriptor',
    as InstanceOf['Google::Cloud::Bigquery::Biglake::V1alpha1::Metastore::HiveTableOptions::StorageDescriptor'];

coerce 'StorageDescriptor',
    from HashRef, via { 'Google::Cloud::Bigquery::Biglake::V1alpha1::Metastore::HiveTableOptions::StorageDescriptor'->new($_) };

declare 'RepeatedStorageDescriptor',
    as ArrayRef[StorageDescriptor()];

coerce 'RepeatedStorageDescriptor',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Biglake::V1alpha1::Metastore::HiveTableOptions::StorageDescriptor'->new($_) } @$_ ] };

declare 'MapStringStorageDescriptor',
    as HashRef[StorageDescriptor()];

declare 'ParametersEntry',
    as InstanceOf['Google::Cloud::Bigquery::Biglake::V1alpha1::Metastore::HiveTableOptions::ParametersEntry'];

coerce 'ParametersEntry',
    from HashRef, via { 'Google::Cloud::Bigquery::Biglake::V1alpha1::Metastore::HiveTableOptions::ParametersEntry'->new($_) };

declare 'RepeatedParametersEntry',
    as ArrayRef[ParametersEntry()];

coerce 'RepeatedParametersEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Biglake::V1alpha1::Metastore::HiveTableOptions::ParametersEntry'->new($_) } @$_ ] };

declare 'MapStringParametersEntry',
    as HashRef[ParametersEntry()];

1;

__END__

=head1 NAME

Google::Cloud::Bigquery::Biglake::V1alpha1::Metastore::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
