package Google::Cloud::Biglake::Hive::V1beta::HiveMetastore::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'HiveCatalog',
    as InstanceOf['Google::Cloud::Biglake::Hive::V1beta::HiveMetastore::HiveCatalog'];

coerce 'HiveCatalog',
    from HashRef, via { 'Google::Cloud::Biglake::Hive::V1beta::HiveMetastore::HiveCatalog'->new($_) };

declare 'RepeatedHiveCatalog',
    as ArrayRef[HiveCatalog()];

coerce 'RepeatedHiveCatalog',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Biglake::Hive::V1beta::HiveMetastore::HiveCatalog'->new($_) } @$_ ] };

declare 'MapStringHiveCatalog',
    as HashRef[HiveCatalog()];

declare 'Replica',
    as InstanceOf['Google::Cloud::Biglake::Hive::V1beta::HiveMetastore::HiveCatalog::Replica'];

coerce 'Replica',
    from HashRef, via { 'Google::Cloud::Biglake::Hive::V1beta::HiveMetastore::HiveCatalog::Replica'->new($_) };

declare 'RepeatedReplica',
    as ArrayRef[Replica()];

coerce 'RepeatedReplica',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Biglake::Hive::V1beta::HiveMetastore::HiveCatalog::Replica'->new($_) } @$_ ] };

declare 'MapStringReplica',
    as HashRef[Replica()];

declare 'State',
    as (Int | Str);

declare 'CreateHiveCatalogRequest',
    as InstanceOf['Google::Cloud::Biglake::Hive::V1beta::HiveMetastore::CreateHiveCatalogRequest'];

coerce 'CreateHiveCatalogRequest',
    from HashRef, via { 'Google::Cloud::Biglake::Hive::V1beta::HiveMetastore::CreateHiveCatalogRequest'->new($_) };

declare 'RepeatedCreateHiveCatalogRequest',
    as ArrayRef[CreateHiveCatalogRequest()];

coerce 'RepeatedCreateHiveCatalogRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Biglake::Hive::V1beta::HiveMetastore::CreateHiveCatalogRequest'->new($_) } @$_ ] };

declare 'MapStringCreateHiveCatalogRequest',
    as HashRef[CreateHiveCatalogRequest()];

declare 'GetHiveCatalogRequest',
    as InstanceOf['Google::Cloud::Biglake::Hive::V1beta::HiveMetastore::GetHiveCatalogRequest'];

coerce 'GetHiveCatalogRequest',
    from HashRef, via { 'Google::Cloud::Biglake::Hive::V1beta::HiveMetastore::GetHiveCatalogRequest'->new($_) };

declare 'RepeatedGetHiveCatalogRequest',
    as ArrayRef[GetHiveCatalogRequest()];

coerce 'RepeatedGetHiveCatalogRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Biglake::Hive::V1beta::HiveMetastore::GetHiveCatalogRequest'->new($_) } @$_ ] };

declare 'MapStringGetHiveCatalogRequest',
    as HashRef[GetHiveCatalogRequest()];

declare 'ListHiveCatalogsRequest',
    as InstanceOf['Google::Cloud::Biglake::Hive::V1beta::HiveMetastore::ListHiveCatalogsRequest'];

coerce 'ListHiveCatalogsRequest',
    from HashRef, via { 'Google::Cloud::Biglake::Hive::V1beta::HiveMetastore::ListHiveCatalogsRequest'->new($_) };

declare 'RepeatedListHiveCatalogsRequest',
    as ArrayRef[ListHiveCatalogsRequest()];

coerce 'RepeatedListHiveCatalogsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Biglake::Hive::V1beta::HiveMetastore::ListHiveCatalogsRequest'->new($_) } @$_ ] };

declare 'MapStringListHiveCatalogsRequest',
    as HashRef[ListHiveCatalogsRequest()];

declare 'ListHiveCatalogsResponse',
    as InstanceOf['Google::Cloud::Biglake::Hive::V1beta::HiveMetastore::ListHiveCatalogsResponse'];

coerce 'ListHiveCatalogsResponse',
    from HashRef, via { 'Google::Cloud::Biglake::Hive::V1beta::HiveMetastore::ListHiveCatalogsResponse'->new($_) };

declare 'RepeatedListHiveCatalogsResponse',
    as ArrayRef[ListHiveCatalogsResponse()];

coerce 'RepeatedListHiveCatalogsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Biglake::Hive::V1beta::HiveMetastore::ListHiveCatalogsResponse'->new($_) } @$_ ] };

declare 'MapStringListHiveCatalogsResponse',
    as HashRef[ListHiveCatalogsResponse()];

declare 'UpdateHiveCatalogRequest',
    as InstanceOf['Google::Cloud::Biglake::Hive::V1beta::HiveMetastore::UpdateHiveCatalogRequest'];

coerce 'UpdateHiveCatalogRequest',
    from HashRef, via { 'Google::Cloud::Biglake::Hive::V1beta::HiveMetastore::UpdateHiveCatalogRequest'->new($_) };

declare 'RepeatedUpdateHiveCatalogRequest',
    as ArrayRef[UpdateHiveCatalogRequest()];

coerce 'RepeatedUpdateHiveCatalogRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Biglake::Hive::V1beta::HiveMetastore::UpdateHiveCatalogRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateHiveCatalogRequest',
    as HashRef[UpdateHiveCatalogRequest()];

declare 'DeleteHiveCatalogRequest',
    as InstanceOf['Google::Cloud::Biglake::Hive::V1beta::HiveMetastore::DeleteHiveCatalogRequest'];

coerce 'DeleteHiveCatalogRequest',
    from HashRef, via { 'Google::Cloud::Biglake::Hive::V1beta::HiveMetastore::DeleteHiveCatalogRequest'->new($_) };

declare 'RepeatedDeleteHiveCatalogRequest',
    as ArrayRef[DeleteHiveCatalogRequest()];

coerce 'RepeatedDeleteHiveCatalogRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Biglake::Hive::V1beta::HiveMetastore::DeleteHiveCatalogRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteHiveCatalogRequest',
    as HashRef[DeleteHiveCatalogRequest()];

declare 'HiveDatabase',
    as InstanceOf['Google::Cloud::Biglake::Hive::V1beta::HiveMetastore::HiveDatabase'];

coerce 'HiveDatabase',
    from HashRef, via { 'Google::Cloud::Biglake::Hive::V1beta::HiveMetastore::HiveDatabase'->new($_) };

declare 'RepeatedHiveDatabase',
    as ArrayRef[HiveDatabase()];

coerce 'RepeatedHiveDatabase',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Biglake::Hive::V1beta::HiveMetastore::HiveDatabase'->new($_) } @$_ ] };

declare 'MapStringHiveDatabase',
    as HashRef[HiveDatabase()];

declare 'ParametersEntry',
    as InstanceOf['Google::Cloud::Biglake::Hive::V1beta::HiveMetastore::HiveDatabase::ParametersEntry'];

coerce 'ParametersEntry',
    from HashRef, via { 'Google::Cloud::Biglake::Hive::V1beta::HiveMetastore::HiveDatabase::ParametersEntry'->new($_) };

declare 'RepeatedParametersEntry',
    as ArrayRef[ParametersEntry()];

coerce 'RepeatedParametersEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Biglake::Hive::V1beta::HiveMetastore::HiveDatabase::ParametersEntry'->new($_) } @$_ ] };

declare 'MapStringParametersEntry',
    as HashRef[ParametersEntry()];

declare 'CreateHiveDatabaseRequest',
    as InstanceOf['Google::Cloud::Biglake::Hive::V1beta::HiveMetastore::CreateHiveDatabaseRequest'];

coerce 'CreateHiveDatabaseRequest',
    from HashRef, via { 'Google::Cloud::Biglake::Hive::V1beta::HiveMetastore::CreateHiveDatabaseRequest'->new($_) };

declare 'RepeatedCreateHiveDatabaseRequest',
    as ArrayRef[CreateHiveDatabaseRequest()];

coerce 'RepeatedCreateHiveDatabaseRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Biglake::Hive::V1beta::HiveMetastore::CreateHiveDatabaseRequest'->new($_) } @$_ ] };

declare 'MapStringCreateHiveDatabaseRequest',
    as HashRef[CreateHiveDatabaseRequest()];

declare 'GetHiveDatabaseRequest',
    as InstanceOf['Google::Cloud::Biglake::Hive::V1beta::HiveMetastore::GetHiveDatabaseRequest'];

coerce 'GetHiveDatabaseRequest',
    from HashRef, via { 'Google::Cloud::Biglake::Hive::V1beta::HiveMetastore::GetHiveDatabaseRequest'->new($_) };

declare 'RepeatedGetHiveDatabaseRequest',
    as ArrayRef[GetHiveDatabaseRequest()];

coerce 'RepeatedGetHiveDatabaseRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Biglake::Hive::V1beta::HiveMetastore::GetHiveDatabaseRequest'->new($_) } @$_ ] };

declare 'MapStringGetHiveDatabaseRequest',
    as HashRef[GetHiveDatabaseRequest()];

declare 'ListHiveDatabasesRequest',
    as InstanceOf['Google::Cloud::Biglake::Hive::V1beta::HiveMetastore::ListHiveDatabasesRequest'];

coerce 'ListHiveDatabasesRequest',
    from HashRef, via { 'Google::Cloud::Biglake::Hive::V1beta::HiveMetastore::ListHiveDatabasesRequest'->new($_) };

declare 'RepeatedListHiveDatabasesRequest',
    as ArrayRef[ListHiveDatabasesRequest()];

coerce 'RepeatedListHiveDatabasesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Biglake::Hive::V1beta::HiveMetastore::ListHiveDatabasesRequest'->new($_) } @$_ ] };

declare 'MapStringListHiveDatabasesRequest',
    as HashRef[ListHiveDatabasesRequest()];

declare 'ListHiveDatabasesResponse',
    as InstanceOf['Google::Cloud::Biglake::Hive::V1beta::HiveMetastore::ListHiveDatabasesResponse'];

coerce 'ListHiveDatabasesResponse',
    from HashRef, via { 'Google::Cloud::Biglake::Hive::V1beta::HiveMetastore::ListHiveDatabasesResponse'->new($_) };

declare 'RepeatedListHiveDatabasesResponse',
    as ArrayRef[ListHiveDatabasesResponse()];

coerce 'RepeatedListHiveDatabasesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Biglake::Hive::V1beta::HiveMetastore::ListHiveDatabasesResponse'->new($_) } @$_ ] };

declare 'MapStringListHiveDatabasesResponse',
    as HashRef[ListHiveDatabasesResponse()];

declare 'UpdateHiveDatabaseRequest',
    as InstanceOf['Google::Cloud::Biglake::Hive::V1beta::HiveMetastore::UpdateHiveDatabaseRequest'];

coerce 'UpdateHiveDatabaseRequest',
    from HashRef, via { 'Google::Cloud::Biglake::Hive::V1beta::HiveMetastore::UpdateHiveDatabaseRequest'->new($_) };

declare 'RepeatedUpdateHiveDatabaseRequest',
    as ArrayRef[UpdateHiveDatabaseRequest()];

coerce 'RepeatedUpdateHiveDatabaseRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Biglake::Hive::V1beta::HiveMetastore::UpdateHiveDatabaseRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateHiveDatabaseRequest',
    as HashRef[UpdateHiveDatabaseRequest()];

declare 'DeleteHiveDatabaseRequest',
    as InstanceOf['Google::Cloud::Biglake::Hive::V1beta::HiveMetastore::DeleteHiveDatabaseRequest'];

coerce 'DeleteHiveDatabaseRequest',
    from HashRef, via { 'Google::Cloud::Biglake::Hive::V1beta::HiveMetastore::DeleteHiveDatabaseRequest'->new($_) };

declare 'RepeatedDeleteHiveDatabaseRequest',
    as ArrayRef[DeleteHiveDatabaseRequest()];

coerce 'RepeatedDeleteHiveDatabaseRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Biglake::Hive::V1beta::HiveMetastore::DeleteHiveDatabaseRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteHiveDatabaseRequest',
    as HashRef[DeleteHiveDatabaseRequest()];

declare 'HiveTable',
    as InstanceOf['Google::Cloud::Biglake::Hive::V1beta::HiveMetastore::HiveTable'];

coerce 'HiveTable',
    from HashRef, via { 'Google::Cloud::Biglake::Hive::V1beta::HiveMetastore::HiveTable'->new($_) };

declare 'RepeatedHiveTable',
    as ArrayRef[HiveTable()];

coerce 'RepeatedHiveTable',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Biglake::Hive::V1beta::HiveMetastore::HiveTable'->new($_) } @$_ ] };

declare 'MapStringHiveTable',
    as HashRef[HiveTable()];

declare 'ParametersEntry',
    as InstanceOf['Google::Cloud::Biglake::Hive::V1beta::HiveMetastore::HiveTable::ParametersEntry'];

coerce 'ParametersEntry',
    from HashRef, via { 'Google::Cloud::Biglake::Hive::V1beta::HiveMetastore::HiveTable::ParametersEntry'->new($_) };

declare 'RepeatedParametersEntry',
    as ArrayRef[ParametersEntry()];

coerce 'RepeatedParametersEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Biglake::Hive::V1beta::HiveMetastore::HiveTable::ParametersEntry'->new($_) } @$_ ] };

declare 'MapStringParametersEntry',
    as HashRef[ParametersEntry()];

declare 'FieldSchema',
    as InstanceOf['Google::Cloud::Biglake::Hive::V1beta::HiveMetastore::FieldSchema'];

coerce 'FieldSchema',
    from HashRef, via { 'Google::Cloud::Biglake::Hive::V1beta::HiveMetastore::FieldSchema'->new($_) };

declare 'RepeatedFieldSchema',
    as ArrayRef[FieldSchema()];

coerce 'RepeatedFieldSchema',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Biglake::Hive::V1beta::HiveMetastore::FieldSchema'->new($_) } @$_ ] };

declare 'MapStringFieldSchema',
    as HashRef[FieldSchema()];

declare 'StorageDescriptor',
    as InstanceOf['Google::Cloud::Biglake::Hive::V1beta::HiveMetastore::StorageDescriptor'];

coerce 'StorageDescriptor',
    from HashRef, via { 'Google::Cloud::Biglake::Hive::V1beta::HiveMetastore::StorageDescriptor'->new($_) };

declare 'RepeatedStorageDescriptor',
    as ArrayRef[StorageDescriptor()];

coerce 'RepeatedStorageDescriptor',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Biglake::Hive::V1beta::HiveMetastore::StorageDescriptor'->new($_) } @$_ ] };

declare 'MapStringStorageDescriptor',
    as HashRef[StorageDescriptor()];

declare 'Order',
    as InstanceOf['Google::Cloud::Biglake::Hive::V1beta::HiveMetastore::StorageDescriptor::Order'];

coerce 'Order',
    from HashRef, via { 'Google::Cloud::Biglake::Hive::V1beta::HiveMetastore::StorageDescriptor::Order'->new($_) };

declare 'RepeatedOrder',
    as ArrayRef[Order()];

coerce 'RepeatedOrder',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Biglake::Hive::V1beta::HiveMetastore::StorageDescriptor::Order'->new($_) } @$_ ] };

declare 'MapStringOrder',
    as HashRef[Order()];

declare 'SkewedInfo',
    as InstanceOf['Google::Cloud::Biglake::Hive::V1beta::HiveMetastore::StorageDescriptor::SkewedInfo'];

coerce 'SkewedInfo',
    from HashRef, via { 'Google::Cloud::Biglake::Hive::V1beta::HiveMetastore::StorageDescriptor::SkewedInfo'->new($_) };

declare 'RepeatedSkewedInfo',
    as ArrayRef[SkewedInfo()];

coerce 'RepeatedSkewedInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Biglake::Hive::V1beta::HiveMetastore::StorageDescriptor::SkewedInfo'->new($_) } @$_ ] };

declare 'MapStringSkewedInfo',
    as HashRef[SkewedInfo()];

declare 'SkewedColumnValue',
    as InstanceOf['Google::Cloud::Biglake::Hive::V1beta::HiveMetastore::StorageDescriptor::SkewedInfo::SkewedColumnValue'];

coerce 'SkewedColumnValue',
    from HashRef, via { 'Google::Cloud::Biglake::Hive::V1beta::HiveMetastore::StorageDescriptor::SkewedInfo::SkewedColumnValue'->new($_) };

declare 'RepeatedSkewedColumnValue',
    as ArrayRef[SkewedColumnValue()];

coerce 'RepeatedSkewedColumnValue',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Biglake::Hive::V1beta::HiveMetastore::StorageDescriptor::SkewedInfo::SkewedColumnValue'->new($_) } @$_ ] };

declare 'MapStringSkewedColumnValue',
    as HashRef[SkewedColumnValue()];

declare 'SkewedKeyValuesLocation',
    as InstanceOf['Google::Cloud::Biglake::Hive::V1beta::HiveMetastore::StorageDescriptor::SkewedInfo::SkewedKeyValuesLocation'];

coerce 'SkewedKeyValuesLocation',
    from HashRef, via { 'Google::Cloud::Biglake::Hive::V1beta::HiveMetastore::StorageDescriptor::SkewedInfo::SkewedKeyValuesLocation'->new($_) };

declare 'RepeatedSkewedKeyValuesLocation',
    as ArrayRef[SkewedKeyValuesLocation()];

coerce 'RepeatedSkewedKeyValuesLocation',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Biglake::Hive::V1beta::HiveMetastore::StorageDescriptor::SkewedInfo::SkewedKeyValuesLocation'->new($_) } @$_ ] };

declare 'MapStringSkewedKeyValuesLocation',
    as HashRef[SkewedKeyValuesLocation()];

declare 'ParametersEntry',
    as InstanceOf['Google::Cloud::Biglake::Hive::V1beta::HiveMetastore::StorageDescriptor::ParametersEntry'];

coerce 'ParametersEntry',
    from HashRef, via { 'Google::Cloud::Biglake::Hive::V1beta::HiveMetastore::StorageDescriptor::ParametersEntry'->new($_) };

declare 'RepeatedParametersEntry',
    as ArrayRef[ParametersEntry()];

coerce 'RepeatedParametersEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Biglake::Hive::V1beta::HiveMetastore::StorageDescriptor::ParametersEntry'->new($_) } @$_ ] };

declare 'MapStringParametersEntry',
    as HashRef[ParametersEntry()];

declare 'SerdeInfo',
    as InstanceOf['Google::Cloud::Biglake::Hive::V1beta::HiveMetastore::SerdeInfo'];

coerce 'SerdeInfo',
    from HashRef, via { 'Google::Cloud::Biglake::Hive::V1beta::HiveMetastore::SerdeInfo'->new($_) };

declare 'RepeatedSerdeInfo',
    as ArrayRef[SerdeInfo()];

coerce 'RepeatedSerdeInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Biglake::Hive::V1beta::HiveMetastore::SerdeInfo'->new($_) } @$_ ] };

declare 'MapStringSerdeInfo',
    as HashRef[SerdeInfo()];

declare 'SerdeType',
    as (Int | Str);

declare 'ParametersEntry',
    as InstanceOf['Google::Cloud::Biglake::Hive::V1beta::HiveMetastore::SerdeInfo::ParametersEntry'];

coerce 'ParametersEntry',
    from HashRef, via { 'Google::Cloud::Biglake::Hive::V1beta::HiveMetastore::SerdeInfo::ParametersEntry'->new($_) };

declare 'RepeatedParametersEntry',
    as ArrayRef[ParametersEntry()];

coerce 'RepeatedParametersEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Biglake::Hive::V1beta::HiveMetastore::SerdeInfo::ParametersEntry'->new($_) } @$_ ] };

declare 'MapStringParametersEntry',
    as HashRef[ParametersEntry()];

declare 'CreateHiveTableRequest',
    as InstanceOf['Google::Cloud::Biglake::Hive::V1beta::HiveMetastore::CreateHiveTableRequest'];

coerce 'CreateHiveTableRequest',
    from HashRef, via { 'Google::Cloud::Biglake::Hive::V1beta::HiveMetastore::CreateHiveTableRequest'->new($_) };

declare 'RepeatedCreateHiveTableRequest',
    as ArrayRef[CreateHiveTableRequest()];

coerce 'RepeatedCreateHiveTableRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Biglake::Hive::V1beta::HiveMetastore::CreateHiveTableRequest'->new($_) } @$_ ] };

declare 'MapStringCreateHiveTableRequest',
    as HashRef[CreateHiveTableRequest()];

declare 'GetHiveTableRequest',
    as InstanceOf['Google::Cloud::Biglake::Hive::V1beta::HiveMetastore::GetHiveTableRequest'];

coerce 'GetHiveTableRequest',
    from HashRef, via { 'Google::Cloud::Biglake::Hive::V1beta::HiveMetastore::GetHiveTableRequest'->new($_) };

declare 'RepeatedGetHiveTableRequest',
    as ArrayRef[GetHiveTableRequest()];

coerce 'RepeatedGetHiveTableRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Biglake::Hive::V1beta::HiveMetastore::GetHiveTableRequest'->new($_) } @$_ ] };

declare 'MapStringGetHiveTableRequest',
    as HashRef[GetHiveTableRequest()];

declare 'ListHiveTablesRequest',
    as InstanceOf['Google::Cloud::Biglake::Hive::V1beta::HiveMetastore::ListHiveTablesRequest'];

coerce 'ListHiveTablesRequest',
    from HashRef, via { 'Google::Cloud::Biglake::Hive::V1beta::HiveMetastore::ListHiveTablesRequest'->new($_) };

declare 'RepeatedListHiveTablesRequest',
    as ArrayRef[ListHiveTablesRequest()];

coerce 'RepeatedListHiveTablesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Biglake::Hive::V1beta::HiveMetastore::ListHiveTablesRequest'->new($_) } @$_ ] };

declare 'MapStringListHiveTablesRequest',
    as HashRef[ListHiveTablesRequest()];

declare 'ListHiveTablesResponse',
    as InstanceOf['Google::Cloud::Biglake::Hive::V1beta::HiveMetastore::ListHiveTablesResponse'];

coerce 'ListHiveTablesResponse',
    from HashRef, via { 'Google::Cloud::Biglake::Hive::V1beta::HiveMetastore::ListHiveTablesResponse'->new($_) };

declare 'RepeatedListHiveTablesResponse',
    as ArrayRef[ListHiveTablesResponse()];

coerce 'RepeatedListHiveTablesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Biglake::Hive::V1beta::HiveMetastore::ListHiveTablesResponse'->new($_) } @$_ ] };

declare 'MapStringListHiveTablesResponse',
    as HashRef[ListHiveTablesResponse()];

declare 'UpdateHiveTableRequest',
    as InstanceOf['Google::Cloud::Biglake::Hive::V1beta::HiveMetastore::UpdateHiveTableRequest'];

coerce 'UpdateHiveTableRequest',
    from HashRef, via { 'Google::Cloud::Biglake::Hive::V1beta::HiveMetastore::UpdateHiveTableRequest'->new($_) };

declare 'RepeatedUpdateHiveTableRequest',
    as ArrayRef[UpdateHiveTableRequest()];

coerce 'RepeatedUpdateHiveTableRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Biglake::Hive::V1beta::HiveMetastore::UpdateHiveTableRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateHiveTableRequest',
    as HashRef[UpdateHiveTableRequest()];

declare 'DeleteHiveTableRequest',
    as InstanceOf['Google::Cloud::Biglake::Hive::V1beta::HiveMetastore::DeleteHiveTableRequest'];

coerce 'DeleteHiveTableRequest',
    from HashRef, via { 'Google::Cloud::Biglake::Hive::V1beta::HiveMetastore::DeleteHiveTableRequest'->new($_) };

declare 'RepeatedDeleteHiveTableRequest',
    as ArrayRef[DeleteHiveTableRequest()];

coerce 'RepeatedDeleteHiveTableRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Biglake::Hive::V1beta::HiveMetastore::DeleteHiveTableRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteHiveTableRequest',
    as HashRef[DeleteHiveTableRequest()];

declare 'Partition',
    as InstanceOf['Google::Cloud::Biglake::Hive::V1beta::HiveMetastore::Partition'];

coerce 'Partition',
    from HashRef, via { 'Google::Cloud::Biglake::Hive::V1beta::HiveMetastore::Partition'->new($_) };

declare 'RepeatedPartition',
    as ArrayRef[Partition()];

coerce 'RepeatedPartition',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Biglake::Hive::V1beta::HiveMetastore::Partition'->new($_) } @$_ ] };

declare 'MapStringPartition',
    as HashRef[Partition()];

declare 'ParametersEntry',
    as InstanceOf['Google::Cloud::Biglake::Hive::V1beta::HiveMetastore::Partition::ParametersEntry'];

coerce 'ParametersEntry',
    from HashRef, via { 'Google::Cloud::Biglake::Hive::V1beta::HiveMetastore::Partition::ParametersEntry'->new($_) };

declare 'RepeatedParametersEntry',
    as ArrayRef[ParametersEntry()];

coerce 'RepeatedParametersEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Biglake::Hive::V1beta::HiveMetastore::Partition::ParametersEntry'->new($_) } @$_ ] };

declare 'MapStringParametersEntry',
    as HashRef[ParametersEntry()];

declare 'PartitionValues',
    as InstanceOf['Google::Cloud::Biglake::Hive::V1beta::HiveMetastore::PartitionValues'];

coerce 'PartitionValues',
    from HashRef, via { 'Google::Cloud::Biglake::Hive::V1beta::HiveMetastore::PartitionValues'->new($_) };

declare 'RepeatedPartitionValues',
    as ArrayRef[PartitionValues()];

coerce 'RepeatedPartitionValues',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Biglake::Hive::V1beta::HiveMetastore::PartitionValues'->new($_) } @$_ ] };

declare 'MapStringPartitionValues',
    as HashRef[PartitionValues()];

declare 'CreatePartitionRequest',
    as InstanceOf['Google::Cloud::Biglake::Hive::V1beta::HiveMetastore::CreatePartitionRequest'];

coerce 'CreatePartitionRequest',
    from HashRef, via { 'Google::Cloud::Biglake::Hive::V1beta::HiveMetastore::CreatePartitionRequest'->new($_) };

declare 'RepeatedCreatePartitionRequest',
    as ArrayRef[CreatePartitionRequest()];

coerce 'RepeatedCreatePartitionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Biglake::Hive::V1beta::HiveMetastore::CreatePartitionRequest'->new($_) } @$_ ] };

declare 'MapStringCreatePartitionRequest',
    as HashRef[CreatePartitionRequest()];

declare 'BatchCreatePartitionsRequest',
    as InstanceOf['Google::Cloud::Biglake::Hive::V1beta::HiveMetastore::BatchCreatePartitionsRequest'];

coerce 'BatchCreatePartitionsRequest',
    from HashRef, via { 'Google::Cloud::Biglake::Hive::V1beta::HiveMetastore::BatchCreatePartitionsRequest'->new($_) };

declare 'RepeatedBatchCreatePartitionsRequest',
    as ArrayRef[BatchCreatePartitionsRequest()];

coerce 'RepeatedBatchCreatePartitionsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Biglake::Hive::V1beta::HiveMetastore::BatchCreatePartitionsRequest'->new($_) } @$_ ] };

declare 'MapStringBatchCreatePartitionsRequest',
    as HashRef[BatchCreatePartitionsRequest()];

declare 'BatchCreatePartitionsResponse',
    as InstanceOf['Google::Cloud::Biglake::Hive::V1beta::HiveMetastore::BatchCreatePartitionsResponse'];

coerce 'BatchCreatePartitionsResponse',
    from HashRef, via { 'Google::Cloud::Biglake::Hive::V1beta::HiveMetastore::BatchCreatePartitionsResponse'->new($_) };

declare 'RepeatedBatchCreatePartitionsResponse',
    as ArrayRef[BatchCreatePartitionsResponse()];

coerce 'RepeatedBatchCreatePartitionsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Biglake::Hive::V1beta::HiveMetastore::BatchCreatePartitionsResponse'->new($_) } @$_ ] };

declare 'MapStringBatchCreatePartitionsResponse',
    as HashRef[BatchCreatePartitionsResponse()];

declare 'BatchDeletePartitionsRequest',
    as InstanceOf['Google::Cloud::Biglake::Hive::V1beta::HiveMetastore::BatchDeletePartitionsRequest'];

coerce 'BatchDeletePartitionsRequest',
    from HashRef, via { 'Google::Cloud::Biglake::Hive::V1beta::HiveMetastore::BatchDeletePartitionsRequest'->new($_) };

declare 'RepeatedBatchDeletePartitionsRequest',
    as ArrayRef[BatchDeletePartitionsRequest()];

coerce 'RepeatedBatchDeletePartitionsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Biglake::Hive::V1beta::HiveMetastore::BatchDeletePartitionsRequest'->new($_) } @$_ ] };

declare 'MapStringBatchDeletePartitionsRequest',
    as HashRef[BatchDeletePartitionsRequest()];

declare 'UpdatePartitionRequest',
    as InstanceOf['Google::Cloud::Biglake::Hive::V1beta::HiveMetastore::UpdatePartitionRequest'];

coerce 'UpdatePartitionRequest',
    from HashRef, via { 'Google::Cloud::Biglake::Hive::V1beta::HiveMetastore::UpdatePartitionRequest'->new($_) };

declare 'RepeatedUpdatePartitionRequest',
    as ArrayRef[UpdatePartitionRequest()];

coerce 'RepeatedUpdatePartitionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Biglake::Hive::V1beta::HiveMetastore::UpdatePartitionRequest'->new($_) } @$_ ] };

declare 'MapStringUpdatePartitionRequest',
    as HashRef[UpdatePartitionRequest()];

declare 'BatchUpdatePartitionsRequest',
    as InstanceOf['Google::Cloud::Biglake::Hive::V1beta::HiveMetastore::BatchUpdatePartitionsRequest'];

coerce 'BatchUpdatePartitionsRequest',
    from HashRef, via { 'Google::Cloud::Biglake::Hive::V1beta::HiveMetastore::BatchUpdatePartitionsRequest'->new($_) };

declare 'RepeatedBatchUpdatePartitionsRequest',
    as ArrayRef[BatchUpdatePartitionsRequest()];

coerce 'RepeatedBatchUpdatePartitionsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Biglake::Hive::V1beta::HiveMetastore::BatchUpdatePartitionsRequest'->new($_) } @$_ ] };

declare 'MapStringBatchUpdatePartitionsRequest',
    as HashRef[BatchUpdatePartitionsRequest()];

declare 'BatchUpdatePartitionsResponse',
    as InstanceOf['Google::Cloud::Biglake::Hive::V1beta::HiveMetastore::BatchUpdatePartitionsResponse'];

coerce 'BatchUpdatePartitionsResponse',
    from HashRef, via { 'Google::Cloud::Biglake::Hive::V1beta::HiveMetastore::BatchUpdatePartitionsResponse'->new($_) };

declare 'RepeatedBatchUpdatePartitionsResponse',
    as ArrayRef[BatchUpdatePartitionsResponse()];

coerce 'RepeatedBatchUpdatePartitionsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Biglake::Hive::V1beta::HiveMetastore::BatchUpdatePartitionsResponse'->new($_) } @$_ ] };

declare 'MapStringBatchUpdatePartitionsResponse',
    as HashRef[BatchUpdatePartitionsResponse()];

declare 'ListPartitionsRequest',
    as InstanceOf['Google::Cloud::Biglake::Hive::V1beta::HiveMetastore::ListPartitionsRequest'];

coerce 'ListPartitionsRequest',
    from HashRef, via { 'Google::Cloud::Biglake::Hive::V1beta::HiveMetastore::ListPartitionsRequest'->new($_) };

declare 'RepeatedListPartitionsRequest',
    as ArrayRef[ListPartitionsRequest()];

coerce 'RepeatedListPartitionsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Biglake::Hive::V1beta::HiveMetastore::ListPartitionsRequest'->new($_) } @$_ ] };

declare 'MapStringListPartitionsRequest',
    as HashRef[ListPartitionsRequest()];

declare 'ListPartitionsResponse',
    as InstanceOf['Google::Cloud::Biglake::Hive::V1beta::HiveMetastore::ListPartitionsResponse'];

coerce 'ListPartitionsResponse',
    from HashRef, via { 'Google::Cloud::Biglake::Hive::V1beta::HiveMetastore::ListPartitionsResponse'->new($_) };

declare 'RepeatedListPartitionsResponse',
    as ArrayRef[ListPartitionsResponse()];

coerce 'RepeatedListPartitionsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Biglake::Hive::V1beta::HiveMetastore::ListPartitionsResponse'->new($_) } @$_ ] };

declare 'MapStringListPartitionsResponse',
    as HashRef[ListPartitionsResponse()];

declare 'FailoverHiveCatalogRequest',
    as InstanceOf['Google::Cloud::Biglake::Hive::V1beta::HiveMetastore::FailoverHiveCatalogRequest'];

coerce 'FailoverHiveCatalogRequest',
    from HashRef, via { 'Google::Cloud::Biglake::Hive::V1beta::HiveMetastore::FailoverHiveCatalogRequest'->new($_) };

declare 'RepeatedFailoverHiveCatalogRequest',
    as ArrayRef[FailoverHiveCatalogRequest()];

coerce 'RepeatedFailoverHiveCatalogRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Biglake::Hive::V1beta::HiveMetastore::FailoverHiveCatalogRequest'->new($_) } @$_ ] };

declare 'MapStringFailoverHiveCatalogRequest',
    as HashRef[FailoverHiveCatalogRequest()];

declare 'FailoverHiveCatalogResponse',
    as InstanceOf['Google::Cloud::Biglake::Hive::V1beta::HiveMetastore::FailoverHiveCatalogResponse'];

coerce 'FailoverHiveCatalogResponse',
    from HashRef, via { 'Google::Cloud::Biglake::Hive::V1beta::HiveMetastore::FailoverHiveCatalogResponse'->new($_) };

declare 'RepeatedFailoverHiveCatalogResponse',
    as ArrayRef[FailoverHiveCatalogResponse()];

coerce 'RepeatedFailoverHiveCatalogResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Biglake::Hive::V1beta::HiveMetastore::FailoverHiveCatalogResponse'->new($_) } @$_ ] };

declare 'MapStringFailoverHiveCatalogResponse',
    as HashRef[FailoverHiveCatalogResponse()];

1;

__END__

=head1 NAME

Google::Cloud::Biglake::Hive::V1beta::HiveMetastore::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
