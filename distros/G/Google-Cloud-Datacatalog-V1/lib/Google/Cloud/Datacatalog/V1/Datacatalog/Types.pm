package Google::Cloud::Datacatalog::V1::Datacatalog::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'EntryType',
    as (Int | Str);

declare 'TagTemplateMigration',
    as (Int | Str);

declare 'CatalogUIExperience',
    as (Int | Str);

declare 'SearchCatalogRequest',
    as InstanceOf['Google::Cloud::Datacatalog::V1::Datacatalog::SearchCatalogRequest'];

coerce 'SearchCatalogRequest',
    from HashRef, via { 'Google::Cloud::Datacatalog::V1::Datacatalog::SearchCatalogRequest'->new($_) };

declare 'RepeatedSearchCatalogRequest',
    as ArrayRef[SearchCatalogRequest()];

coerce 'RepeatedSearchCatalogRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datacatalog::V1::Datacatalog::SearchCatalogRequest'->new($_) } @$_ ] };

declare 'MapStringSearchCatalogRequest',
    as HashRef[SearchCatalogRequest()];

declare 'Scope',
    as InstanceOf['Google::Cloud::Datacatalog::V1::Datacatalog::SearchCatalogRequest::Scope'];

coerce 'Scope',
    from HashRef, via { 'Google::Cloud::Datacatalog::V1::Datacatalog::SearchCatalogRequest::Scope'->new($_) };

declare 'RepeatedScope',
    as ArrayRef[Scope()];

coerce 'RepeatedScope',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datacatalog::V1::Datacatalog::SearchCatalogRequest::Scope'->new($_) } @$_ ] };

declare 'MapStringScope',
    as HashRef[Scope()];

declare 'SearchCatalogResponse',
    as InstanceOf['Google::Cloud::Datacatalog::V1::Datacatalog::SearchCatalogResponse'];

coerce 'SearchCatalogResponse',
    from HashRef, via { 'Google::Cloud::Datacatalog::V1::Datacatalog::SearchCatalogResponse'->new($_) };

declare 'RepeatedSearchCatalogResponse',
    as ArrayRef[SearchCatalogResponse()];

coerce 'RepeatedSearchCatalogResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datacatalog::V1::Datacatalog::SearchCatalogResponse'->new($_) } @$_ ] };

declare 'MapStringSearchCatalogResponse',
    as HashRef[SearchCatalogResponse()];

declare 'CreateEntryGroupRequest',
    as InstanceOf['Google::Cloud::Datacatalog::V1::Datacatalog::CreateEntryGroupRequest'];

coerce 'CreateEntryGroupRequest',
    from HashRef, via { 'Google::Cloud::Datacatalog::V1::Datacatalog::CreateEntryGroupRequest'->new($_) };

declare 'RepeatedCreateEntryGroupRequest',
    as ArrayRef[CreateEntryGroupRequest()];

coerce 'RepeatedCreateEntryGroupRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datacatalog::V1::Datacatalog::CreateEntryGroupRequest'->new($_) } @$_ ] };

declare 'MapStringCreateEntryGroupRequest',
    as HashRef[CreateEntryGroupRequest()];

declare 'UpdateEntryGroupRequest',
    as InstanceOf['Google::Cloud::Datacatalog::V1::Datacatalog::UpdateEntryGroupRequest'];

coerce 'UpdateEntryGroupRequest',
    from HashRef, via { 'Google::Cloud::Datacatalog::V1::Datacatalog::UpdateEntryGroupRequest'->new($_) };

declare 'RepeatedUpdateEntryGroupRequest',
    as ArrayRef[UpdateEntryGroupRequest()];

coerce 'RepeatedUpdateEntryGroupRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datacatalog::V1::Datacatalog::UpdateEntryGroupRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateEntryGroupRequest',
    as HashRef[UpdateEntryGroupRequest()];

declare 'GetEntryGroupRequest',
    as InstanceOf['Google::Cloud::Datacatalog::V1::Datacatalog::GetEntryGroupRequest'];

coerce 'GetEntryGroupRequest',
    from HashRef, via { 'Google::Cloud::Datacatalog::V1::Datacatalog::GetEntryGroupRequest'->new($_) };

declare 'RepeatedGetEntryGroupRequest',
    as ArrayRef[GetEntryGroupRequest()];

coerce 'RepeatedGetEntryGroupRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datacatalog::V1::Datacatalog::GetEntryGroupRequest'->new($_) } @$_ ] };

declare 'MapStringGetEntryGroupRequest',
    as HashRef[GetEntryGroupRequest()];

declare 'DeleteEntryGroupRequest',
    as InstanceOf['Google::Cloud::Datacatalog::V1::Datacatalog::DeleteEntryGroupRequest'];

coerce 'DeleteEntryGroupRequest',
    from HashRef, via { 'Google::Cloud::Datacatalog::V1::Datacatalog::DeleteEntryGroupRequest'->new($_) };

declare 'RepeatedDeleteEntryGroupRequest',
    as ArrayRef[DeleteEntryGroupRequest()];

coerce 'RepeatedDeleteEntryGroupRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datacatalog::V1::Datacatalog::DeleteEntryGroupRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteEntryGroupRequest',
    as HashRef[DeleteEntryGroupRequest()];

declare 'ListEntryGroupsRequest',
    as InstanceOf['Google::Cloud::Datacatalog::V1::Datacatalog::ListEntryGroupsRequest'];

coerce 'ListEntryGroupsRequest',
    from HashRef, via { 'Google::Cloud::Datacatalog::V1::Datacatalog::ListEntryGroupsRequest'->new($_) };

declare 'RepeatedListEntryGroupsRequest',
    as ArrayRef[ListEntryGroupsRequest()];

coerce 'RepeatedListEntryGroupsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datacatalog::V1::Datacatalog::ListEntryGroupsRequest'->new($_) } @$_ ] };

declare 'MapStringListEntryGroupsRequest',
    as HashRef[ListEntryGroupsRequest()];

declare 'ListEntryGroupsResponse',
    as InstanceOf['Google::Cloud::Datacatalog::V1::Datacatalog::ListEntryGroupsResponse'];

coerce 'ListEntryGroupsResponse',
    from HashRef, via { 'Google::Cloud::Datacatalog::V1::Datacatalog::ListEntryGroupsResponse'->new($_) };

declare 'RepeatedListEntryGroupsResponse',
    as ArrayRef[ListEntryGroupsResponse()];

coerce 'RepeatedListEntryGroupsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datacatalog::V1::Datacatalog::ListEntryGroupsResponse'->new($_) } @$_ ] };

declare 'MapStringListEntryGroupsResponse',
    as HashRef[ListEntryGroupsResponse()];

declare 'CreateEntryRequest',
    as InstanceOf['Google::Cloud::Datacatalog::V1::Datacatalog::CreateEntryRequest'];

coerce 'CreateEntryRequest',
    from HashRef, via { 'Google::Cloud::Datacatalog::V1::Datacatalog::CreateEntryRequest'->new($_) };

declare 'RepeatedCreateEntryRequest',
    as ArrayRef[CreateEntryRequest()];

coerce 'RepeatedCreateEntryRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datacatalog::V1::Datacatalog::CreateEntryRequest'->new($_) } @$_ ] };

declare 'MapStringCreateEntryRequest',
    as HashRef[CreateEntryRequest()];

declare 'UpdateEntryRequest',
    as InstanceOf['Google::Cloud::Datacatalog::V1::Datacatalog::UpdateEntryRequest'];

coerce 'UpdateEntryRequest',
    from HashRef, via { 'Google::Cloud::Datacatalog::V1::Datacatalog::UpdateEntryRequest'->new($_) };

declare 'RepeatedUpdateEntryRequest',
    as ArrayRef[UpdateEntryRequest()];

coerce 'RepeatedUpdateEntryRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datacatalog::V1::Datacatalog::UpdateEntryRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateEntryRequest',
    as HashRef[UpdateEntryRequest()];

declare 'DeleteEntryRequest',
    as InstanceOf['Google::Cloud::Datacatalog::V1::Datacatalog::DeleteEntryRequest'];

coerce 'DeleteEntryRequest',
    from HashRef, via { 'Google::Cloud::Datacatalog::V1::Datacatalog::DeleteEntryRequest'->new($_) };

declare 'RepeatedDeleteEntryRequest',
    as ArrayRef[DeleteEntryRequest()];

coerce 'RepeatedDeleteEntryRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datacatalog::V1::Datacatalog::DeleteEntryRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteEntryRequest',
    as HashRef[DeleteEntryRequest()];

declare 'GetEntryRequest',
    as InstanceOf['Google::Cloud::Datacatalog::V1::Datacatalog::GetEntryRequest'];

coerce 'GetEntryRequest',
    from HashRef, via { 'Google::Cloud::Datacatalog::V1::Datacatalog::GetEntryRequest'->new($_) };

declare 'RepeatedGetEntryRequest',
    as ArrayRef[GetEntryRequest()];

coerce 'RepeatedGetEntryRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datacatalog::V1::Datacatalog::GetEntryRequest'->new($_) } @$_ ] };

declare 'MapStringGetEntryRequest',
    as HashRef[GetEntryRequest()];

declare 'LookupEntryRequest',
    as InstanceOf['Google::Cloud::Datacatalog::V1::Datacatalog::LookupEntryRequest'];

coerce 'LookupEntryRequest',
    from HashRef, via { 'Google::Cloud::Datacatalog::V1::Datacatalog::LookupEntryRequest'->new($_) };

declare 'RepeatedLookupEntryRequest',
    as ArrayRef[LookupEntryRequest()];

coerce 'RepeatedLookupEntryRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datacatalog::V1::Datacatalog::LookupEntryRequest'->new($_) } @$_ ] };

declare 'MapStringLookupEntryRequest',
    as HashRef[LookupEntryRequest()];

declare 'Entry',
    as InstanceOf['Google::Cloud::Datacatalog::V1::Datacatalog::Entry'];

coerce 'Entry',
    from HashRef, via { 'Google::Cloud::Datacatalog::V1::Datacatalog::Entry'->new($_) };

declare 'RepeatedEntry',
    as ArrayRef[Entry()];

coerce 'RepeatedEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datacatalog::V1::Datacatalog::Entry'->new($_) } @$_ ] };

declare 'MapStringEntry',
    as HashRef[Entry()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Datacatalog::V1::Datacatalog::Entry::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Datacatalog::V1::Datacatalog::Entry::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datacatalog::V1::Datacatalog::Entry::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'DatabaseTableSpec',
    as InstanceOf['Google::Cloud::Datacatalog::V1::Datacatalog::DatabaseTableSpec'];

coerce 'DatabaseTableSpec',
    from HashRef, via { 'Google::Cloud::Datacatalog::V1::Datacatalog::DatabaseTableSpec'->new($_) };

declare 'RepeatedDatabaseTableSpec',
    as ArrayRef[DatabaseTableSpec()];

coerce 'RepeatedDatabaseTableSpec',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datacatalog::V1::Datacatalog::DatabaseTableSpec'->new($_) } @$_ ] };

declare 'MapStringDatabaseTableSpec',
    as HashRef[DatabaseTableSpec()];

declare 'TableType',
    as (Int | Str);

declare 'DatabaseViewSpec',
    as InstanceOf['Google::Cloud::Datacatalog::V1::Datacatalog::DatabaseTableSpec::DatabaseViewSpec'];

coerce 'DatabaseViewSpec',
    from HashRef, via { 'Google::Cloud::Datacatalog::V1::Datacatalog::DatabaseTableSpec::DatabaseViewSpec'->new($_) };

declare 'RepeatedDatabaseViewSpec',
    as ArrayRef[DatabaseViewSpec()];

coerce 'RepeatedDatabaseViewSpec',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datacatalog::V1::Datacatalog::DatabaseTableSpec::DatabaseViewSpec'->new($_) } @$_ ] };

declare 'MapStringDatabaseViewSpec',
    as HashRef[DatabaseViewSpec()];

declare 'ViewType',
    as (Int | Str);

declare 'FilesetSpec',
    as InstanceOf['Google::Cloud::Datacatalog::V1::Datacatalog::FilesetSpec'];

coerce 'FilesetSpec',
    from HashRef, via { 'Google::Cloud::Datacatalog::V1::Datacatalog::FilesetSpec'->new($_) };

declare 'RepeatedFilesetSpec',
    as ArrayRef[FilesetSpec()];

coerce 'RepeatedFilesetSpec',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datacatalog::V1::Datacatalog::FilesetSpec'->new($_) } @$_ ] };

declare 'MapStringFilesetSpec',
    as HashRef[FilesetSpec()];

declare 'DataSourceConnectionSpec',
    as InstanceOf['Google::Cloud::Datacatalog::V1::Datacatalog::DataSourceConnectionSpec'];

coerce 'DataSourceConnectionSpec',
    from HashRef, via { 'Google::Cloud::Datacatalog::V1::Datacatalog::DataSourceConnectionSpec'->new($_) };

declare 'RepeatedDataSourceConnectionSpec',
    as ArrayRef[DataSourceConnectionSpec()];

coerce 'RepeatedDataSourceConnectionSpec',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datacatalog::V1::Datacatalog::DataSourceConnectionSpec'->new($_) } @$_ ] };

declare 'MapStringDataSourceConnectionSpec',
    as HashRef[DataSourceConnectionSpec()];

declare 'RoutineSpec',
    as InstanceOf['Google::Cloud::Datacatalog::V1::Datacatalog::RoutineSpec'];

coerce 'RoutineSpec',
    from HashRef, via { 'Google::Cloud::Datacatalog::V1::Datacatalog::RoutineSpec'->new($_) };

declare 'RepeatedRoutineSpec',
    as ArrayRef[RoutineSpec()];

coerce 'RepeatedRoutineSpec',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datacatalog::V1::Datacatalog::RoutineSpec'->new($_) } @$_ ] };

declare 'MapStringRoutineSpec',
    as HashRef[RoutineSpec()];

declare 'RoutineType',
    as (Int | Str);

declare 'Argument',
    as InstanceOf['Google::Cloud::Datacatalog::V1::Datacatalog::RoutineSpec::Argument'];

coerce 'Argument',
    from HashRef, via { 'Google::Cloud::Datacatalog::V1::Datacatalog::RoutineSpec::Argument'->new($_) };

declare 'RepeatedArgument',
    as ArrayRef[Argument()];

coerce 'RepeatedArgument',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datacatalog::V1::Datacatalog::RoutineSpec::Argument'->new($_) } @$_ ] };

declare 'MapStringArgument',
    as HashRef[Argument()];

declare 'Mode',
    as (Int | Str);

declare 'DatasetSpec',
    as InstanceOf['Google::Cloud::Datacatalog::V1::Datacatalog::DatasetSpec'];

coerce 'DatasetSpec',
    from HashRef, via { 'Google::Cloud::Datacatalog::V1::Datacatalog::DatasetSpec'->new($_) };

declare 'RepeatedDatasetSpec',
    as ArrayRef[DatasetSpec()];

coerce 'RepeatedDatasetSpec',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datacatalog::V1::Datacatalog::DatasetSpec'->new($_) } @$_ ] };

declare 'MapStringDatasetSpec',
    as HashRef[DatasetSpec()];

declare 'SqlDatabaseSystemSpec',
    as InstanceOf['Google::Cloud::Datacatalog::V1::Datacatalog::SqlDatabaseSystemSpec'];

coerce 'SqlDatabaseSystemSpec',
    from HashRef, via { 'Google::Cloud::Datacatalog::V1::Datacatalog::SqlDatabaseSystemSpec'->new($_) };

declare 'RepeatedSqlDatabaseSystemSpec',
    as ArrayRef[SqlDatabaseSystemSpec()];

coerce 'RepeatedSqlDatabaseSystemSpec',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datacatalog::V1::Datacatalog::SqlDatabaseSystemSpec'->new($_) } @$_ ] };

declare 'MapStringSqlDatabaseSystemSpec',
    as HashRef[SqlDatabaseSystemSpec()];

declare 'LookerSystemSpec',
    as InstanceOf['Google::Cloud::Datacatalog::V1::Datacatalog::LookerSystemSpec'];

coerce 'LookerSystemSpec',
    from HashRef, via { 'Google::Cloud::Datacatalog::V1::Datacatalog::LookerSystemSpec'->new($_) };

declare 'RepeatedLookerSystemSpec',
    as ArrayRef[LookerSystemSpec()];

coerce 'RepeatedLookerSystemSpec',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datacatalog::V1::Datacatalog::LookerSystemSpec'->new($_) } @$_ ] };

declare 'MapStringLookerSystemSpec',
    as HashRef[LookerSystemSpec()];

declare 'CloudBigtableSystemSpec',
    as InstanceOf['Google::Cloud::Datacatalog::V1::Datacatalog::CloudBigtableSystemSpec'];

coerce 'CloudBigtableSystemSpec',
    from HashRef, via { 'Google::Cloud::Datacatalog::V1::Datacatalog::CloudBigtableSystemSpec'->new($_) };

declare 'RepeatedCloudBigtableSystemSpec',
    as ArrayRef[CloudBigtableSystemSpec()];

coerce 'RepeatedCloudBigtableSystemSpec',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datacatalog::V1::Datacatalog::CloudBigtableSystemSpec'->new($_) } @$_ ] };

declare 'MapStringCloudBigtableSystemSpec',
    as HashRef[CloudBigtableSystemSpec()];

declare 'CloudBigtableInstanceSpec',
    as InstanceOf['Google::Cloud::Datacatalog::V1::Datacatalog::CloudBigtableInstanceSpec'];

coerce 'CloudBigtableInstanceSpec',
    from HashRef, via { 'Google::Cloud::Datacatalog::V1::Datacatalog::CloudBigtableInstanceSpec'->new($_) };

declare 'RepeatedCloudBigtableInstanceSpec',
    as ArrayRef[CloudBigtableInstanceSpec()];

coerce 'RepeatedCloudBigtableInstanceSpec',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datacatalog::V1::Datacatalog::CloudBigtableInstanceSpec'->new($_) } @$_ ] };

declare 'MapStringCloudBigtableInstanceSpec',
    as HashRef[CloudBigtableInstanceSpec()];

declare 'CloudBigtableClusterSpec',
    as InstanceOf['Google::Cloud::Datacatalog::V1::Datacatalog::CloudBigtableInstanceSpec::CloudBigtableClusterSpec'];

coerce 'CloudBigtableClusterSpec',
    from HashRef, via { 'Google::Cloud::Datacatalog::V1::Datacatalog::CloudBigtableInstanceSpec::CloudBigtableClusterSpec'->new($_) };

declare 'RepeatedCloudBigtableClusterSpec',
    as ArrayRef[CloudBigtableClusterSpec()];

coerce 'RepeatedCloudBigtableClusterSpec',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datacatalog::V1::Datacatalog::CloudBigtableInstanceSpec::CloudBigtableClusterSpec'->new($_) } @$_ ] };

declare 'MapStringCloudBigtableClusterSpec',
    as HashRef[CloudBigtableClusterSpec()];

declare 'ServiceSpec',
    as InstanceOf['Google::Cloud::Datacatalog::V1::Datacatalog::ServiceSpec'];

coerce 'ServiceSpec',
    from HashRef, via { 'Google::Cloud::Datacatalog::V1::Datacatalog::ServiceSpec'->new($_) };

declare 'RepeatedServiceSpec',
    as ArrayRef[ServiceSpec()];

coerce 'RepeatedServiceSpec',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datacatalog::V1::Datacatalog::ServiceSpec'->new($_) } @$_ ] };

declare 'MapStringServiceSpec',
    as HashRef[ServiceSpec()];

declare 'VertexModelSourceInfo',
    as InstanceOf['Google::Cloud::Datacatalog::V1::Datacatalog::VertexModelSourceInfo'];

coerce 'VertexModelSourceInfo',
    from HashRef, via { 'Google::Cloud::Datacatalog::V1::Datacatalog::VertexModelSourceInfo'->new($_) };

declare 'RepeatedVertexModelSourceInfo',
    as ArrayRef[VertexModelSourceInfo()];

coerce 'RepeatedVertexModelSourceInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datacatalog::V1::Datacatalog::VertexModelSourceInfo'->new($_) } @$_ ] };

declare 'MapStringVertexModelSourceInfo',
    as HashRef[VertexModelSourceInfo()];

declare 'ModelSourceType',
    as (Int | Str);

declare 'VertexModelSpec',
    as InstanceOf['Google::Cloud::Datacatalog::V1::Datacatalog::VertexModelSpec'];

coerce 'VertexModelSpec',
    from HashRef, via { 'Google::Cloud::Datacatalog::V1::Datacatalog::VertexModelSpec'->new($_) };

declare 'RepeatedVertexModelSpec',
    as ArrayRef[VertexModelSpec()];

coerce 'RepeatedVertexModelSpec',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datacatalog::V1::Datacatalog::VertexModelSpec'->new($_) } @$_ ] };

declare 'MapStringVertexModelSpec',
    as HashRef[VertexModelSpec()];

declare 'VertexDatasetSpec',
    as InstanceOf['Google::Cloud::Datacatalog::V1::Datacatalog::VertexDatasetSpec'];

coerce 'VertexDatasetSpec',
    from HashRef, via { 'Google::Cloud::Datacatalog::V1::Datacatalog::VertexDatasetSpec'->new($_) };

declare 'RepeatedVertexDatasetSpec',
    as ArrayRef[VertexDatasetSpec()];

coerce 'RepeatedVertexDatasetSpec',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datacatalog::V1::Datacatalog::VertexDatasetSpec'->new($_) } @$_ ] };

declare 'MapStringVertexDatasetSpec',
    as HashRef[VertexDatasetSpec()];

declare 'DataType',
    as (Int | Str);

declare 'ModelSpec',
    as InstanceOf['Google::Cloud::Datacatalog::V1::Datacatalog::ModelSpec'];

coerce 'ModelSpec',
    from HashRef, via { 'Google::Cloud::Datacatalog::V1::Datacatalog::ModelSpec'->new($_) };

declare 'RepeatedModelSpec',
    as ArrayRef[ModelSpec()];

coerce 'RepeatedModelSpec',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datacatalog::V1::Datacatalog::ModelSpec'->new($_) } @$_ ] };

declare 'MapStringModelSpec',
    as HashRef[ModelSpec()];

declare 'FeatureOnlineStoreSpec',
    as InstanceOf['Google::Cloud::Datacatalog::V1::Datacatalog::FeatureOnlineStoreSpec'];

coerce 'FeatureOnlineStoreSpec',
    from HashRef, via { 'Google::Cloud::Datacatalog::V1::Datacatalog::FeatureOnlineStoreSpec'->new($_) };

declare 'RepeatedFeatureOnlineStoreSpec',
    as ArrayRef[FeatureOnlineStoreSpec()];

coerce 'RepeatedFeatureOnlineStoreSpec',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datacatalog::V1::Datacatalog::FeatureOnlineStoreSpec'->new($_) } @$_ ] };

declare 'MapStringFeatureOnlineStoreSpec',
    as HashRef[FeatureOnlineStoreSpec()];

declare 'StorageType',
    as (Int | Str);

declare 'BusinessContext',
    as InstanceOf['Google::Cloud::Datacatalog::V1::Datacatalog::BusinessContext'];

coerce 'BusinessContext',
    from HashRef, via { 'Google::Cloud::Datacatalog::V1::Datacatalog::BusinessContext'->new($_) };

declare 'RepeatedBusinessContext',
    as ArrayRef[BusinessContext()];

coerce 'RepeatedBusinessContext',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datacatalog::V1::Datacatalog::BusinessContext'->new($_) } @$_ ] };

declare 'MapStringBusinessContext',
    as HashRef[BusinessContext()];

declare 'EntryOverview',
    as InstanceOf['Google::Cloud::Datacatalog::V1::Datacatalog::EntryOverview'];

coerce 'EntryOverview',
    from HashRef, via { 'Google::Cloud::Datacatalog::V1::Datacatalog::EntryOverview'->new($_) };

declare 'RepeatedEntryOverview',
    as ArrayRef[EntryOverview()];

coerce 'RepeatedEntryOverview',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datacatalog::V1::Datacatalog::EntryOverview'->new($_) } @$_ ] };

declare 'MapStringEntryOverview',
    as HashRef[EntryOverview()];

declare 'Contacts',
    as InstanceOf['Google::Cloud::Datacatalog::V1::Datacatalog::Contacts'];

coerce 'Contacts',
    from HashRef, via { 'Google::Cloud::Datacatalog::V1::Datacatalog::Contacts'->new($_) };

declare 'RepeatedContacts',
    as ArrayRef[Contacts()];

coerce 'RepeatedContacts',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datacatalog::V1::Datacatalog::Contacts'->new($_) } @$_ ] };

declare 'MapStringContacts',
    as HashRef[Contacts()];

declare 'Person',
    as InstanceOf['Google::Cloud::Datacatalog::V1::Datacatalog::Contacts::Person'];

coerce 'Person',
    from HashRef, via { 'Google::Cloud::Datacatalog::V1::Datacatalog::Contacts::Person'->new($_) };

declare 'RepeatedPerson',
    as ArrayRef[Person()];

coerce 'RepeatedPerson',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datacatalog::V1::Datacatalog::Contacts::Person'->new($_) } @$_ ] };

declare 'MapStringPerson',
    as HashRef[Person()];

declare 'EntryGroup',
    as InstanceOf['Google::Cloud::Datacatalog::V1::Datacatalog::EntryGroup'];

coerce 'EntryGroup',
    from HashRef, via { 'Google::Cloud::Datacatalog::V1::Datacatalog::EntryGroup'->new($_) };

declare 'RepeatedEntryGroup',
    as ArrayRef[EntryGroup()];

coerce 'RepeatedEntryGroup',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datacatalog::V1::Datacatalog::EntryGroup'->new($_) } @$_ ] };

declare 'MapStringEntryGroup',
    as HashRef[EntryGroup()];

declare 'CreateTagTemplateRequest',
    as InstanceOf['Google::Cloud::Datacatalog::V1::Datacatalog::CreateTagTemplateRequest'];

coerce 'CreateTagTemplateRequest',
    from HashRef, via { 'Google::Cloud::Datacatalog::V1::Datacatalog::CreateTagTemplateRequest'->new($_) };

declare 'RepeatedCreateTagTemplateRequest',
    as ArrayRef[CreateTagTemplateRequest()];

coerce 'RepeatedCreateTagTemplateRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datacatalog::V1::Datacatalog::CreateTagTemplateRequest'->new($_) } @$_ ] };

declare 'MapStringCreateTagTemplateRequest',
    as HashRef[CreateTagTemplateRequest()];

declare 'GetTagTemplateRequest',
    as InstanceOf['Google::Cloud::Datacatalog::V1::Datacatalog::GetTagTemplateRequest'];

coerce 'GetTagTemplateRequest',
    from HashRef, via { 'Google::Cloud::Datacatalog::V1::Datacatalog::GetTagTemplateRequest'->new($_) };

declare 'RepeatedGetTagTemplateRequest',
    as ArrayRef[GetTagTemplateRequest()];

coerce 'RepeatedGetTagTemplateRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datacatalog::V1::Datacatalog::GetTagTemplateRequest'->new($_) } @$_ ] };

declare 'MapStringGetTagTemplateRequest',
    as HashRef[GetTagTemplateRequest()];

declare 'UpdateTagTemplateRequest',
    as InstanceOf['Google::Cloud::Datacatalog::V1::Datacatalog::UpdateTagTemplateRequest'];

coerce 'UpdateTagTemplateRequest',
    from HashRef, via { 'Google::Cloud::Datacatalog::V1::Datacatalog::UpdateTagTemplateRequest'->new($_) };

declare 'RepeatedUpdateTagTemplateRequest',
    as ArrayRef[UpdateTagTemplateRequest()];

coerce 'RepeatedUpdateTagTemplateRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datacatalog::V1::Datacatalog::UpdateTagTemplateRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateTagTemplateRequest',
    as HashRef[UpdateTagTemplateRequest()];

declare 'DeleteTagTemplateRequest',
    as InstanceOf['Google::Cloud::Datacatalog::V1::Datacatalog::DeleteTagTemplateRequest'];

coerce 'DeleteTagTemplateRequest',
    from HashRef, via { 'Google::Cloud::Datacatalog::V1::Datacatalog::DeleteTagTemplateRequest'->new($_) };

declare 'RepeatedDeleteTagTemplateRequest',
    as ArrayRef[DeleteTagTemplateRequest()];

coerce 'RepeatedDeleteTagTemplateRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datacatalog::V1::Datacatalog::DeleteTagTemplateRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteTagTemplateRequest',
    as HashRef[DeleteTagTemplateRequest()];

declare 'CreateTagRequest',
    as InstanceOf['Google::Cloud::Datacatalog::V1::Datacatalog::CreateTagRequest'];

coerce 'CreateTagRequest',
    from HashRef, via { 'Google::Cloud::Datacatalog::V1::Datacatalog::CreateTagRequest'->new($_) };

declare 'RepeatedCreateTagRequest',
    as ArrayRef[CreateTagRequest()];

coerce 'RepeatedCreateTagRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datacatalog::V1::Datacatalog::CreateTagRequest'->new($_) } @$_ ] };

declare 'MapStringCreateTagRequest',
    as HashRef[CreateTagRequest()];

declare 'UpdateTagRequest',
    as InstanceOf['Google::Cloud::Datacatalog::V1::Datacatalog::UpdateTagRequest'];

coerce 'UpdateTagRequest',
    from HashRef, via { 'Google::Cloud::Datacatalog::V1::Datacatalog::UpdateTagRequest'->new($_) };

declare 'RepeatedUpdateTagRequest',
    as ArrayRef[UpdateTagRequest()];

coerce 'RepeatedUpdateTagRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datacatalog::V1::Datacatalog::UpdateTagRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateTagRequest',
    as HashRef[UpdateTagRequest()];

declare 'DeleteTagRequest',
    as InstanceOf['Google::Cloud::Datacatalog::V1::Datacatalog::DeleteTagRequest'];

coerce 'DeleteTagRequest',
    from HashRef, via { 'Google::Cloud::Datacatalog::V1::Datacatalog::DeleteTagRequest'->new($_) };

declare 'RepeatedDeleteTagRequest',
    as ArrayRef[DeleteTagRequest()];

coerce 'RepeatedDeleteTagRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datacatalog::V1::Datacatalog::DeleteTagRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteTagRequest',
    as HashRef[DeleteTagRequest()];

declare 'CreateTagTemplateFieldRequest',
    as InstanceOf['Google::Cloud::Datacatalog::V1::Datacatalog::CreateTagTemplateFieldRequest'];

coerce 'CreateTagTemplateFieldRequest',
    from HashRef, via { 'Google::Cloud::Datacatalog::V1::Datacatalog::CreateTagTemplateFieldRequest'->new($_) };

declare 'RepeatedCreateTagTemplateFieldRequest',
    as ArrayRef[CreateTagTemplateFieldRequest()];

coerce 'RepeatedCreateTagTemplateFieldRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datacatalog::V1::Datacatalog::CreateTagTemplateFieldRequest'->new($_) } @$_ ] };

declare 'MapStringCreateTagTemplateFieldRequest',
    as HashRef[CreateTagTemplateFieldRequest()];

declare 'UpdateTagTemplateFieldRequest',
    as InstanceOf['Google::Cloud::Datacatalog::V1::Datacatalog::UpdateTagTemplateFieldRequest'];

coerce 'UpdateTagTemplateFieldRequest',
    from HashRef, via { 'Google::Cloud::Datacatalog::V1::Datacatalog::UpdateTagTemplateFieldRequest'->new($_) };

declare 'RepeatedUpdateTagTemplateFieldRequest',
    as ArrayRef[UpdateTagTemplateFieldRequest()];

coerce 'RepeatedUpdateTagTemplateFieldRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datacatalog::V1::Datacatalog::UpdateTagTemplateFieldRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateTagTemplateFieldRequest',
    as HashRef[UpdateTagTemplateFieldRequest()];

declare 'RenameTagTemplateFieldRequest',
    as InstanceOf['Google::Cloud::Datacatalog::V1::Datacatalog::RenameTagTemplateFieldRequest'];

coerce 'RenameTagTemplateFieldRequest',
    from HashRef, via { 'Google::Cloud::Datacatalog::V1::Datacatalog::RenameTagTemplateFieldRequest'->new($_) };

declare 'RepeatedRenameTagTemplateFieldRequest',
    as ArrayRef[RenameTagTemplateFieldRequest()];

coerce 'RepeatedRenameTagTemplateFieldRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datacatalog::V1::Datacatalog::RenameTagTemplateFieldRequest'->new($_) } @$_ ] };

declare 'MapStringRenameTagTemplateFieldRequest',
    as HashRef[RenameTagTemplateFieldRequest()];

declare 'RenameTagTemplateFieldEnumValueRequest',
    as InstanceOf['Google::Cloud::Datacatalog::V1::Datacatalog::RenameTagTemplateFieldEnumValueRequest'];

coerce 'RenameTagTemplateFieldEnumValueRequest',
    from HashRef, via { 'Google::Cloud::Datacatalog::V1::Datacatalog::RenameTagTemplateFieldEnumValueRequest'->new($_) };

declare 'RepeatedRenameTagTemplateFieldEnumValueRequest',
    as ArrayRef[RenameTagTemplateFieldEnumValueRequest()];

coerce 'RepeatedRenameTagTemplateFieldEnumValueRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datacatalog::V1::Datacatalog::RenameTagTemplateFieldEnumValueRequest'->new($_) } @$_ ] };

declare 'MapStringRenameTagTemplateFieldEnumValueRequest',
    as HashRef[RenameTagTemplateFieldEnumValueRequest()];

declare 'DeleteTagTemplateFieldRequest',
    as InstanceOf['Google::Cloud::Datacatalog::V1::Datacatalog::DeleteTagTemplateFieldRequest'];

coerce 'DeleteTagTemplateFieldRequest',
    from HashRef, via { 'Google::Cloud::Datacatalog::V1::Datacatalog::DeleteTagTemplateFieldRequest'->new($_) };

declare 'RepeatedDeleteTagTemplateFieldRequest',
    as ArrayRef[DeleteTagTemplateFieldRequest()];

coerce 'RepeatedDeleteTagTemplateFieldRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datacatalog::V1::Datacatalog::DeleteTagTemplateFieldRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteTagTemplateFieldRequest',
    as HashRef[DeleteTagTemplateFieldRequest()];

declare 'ListTagsRequest',
    as InstanceOf['Google::Cloud::Datacatalog::V1::Datacatalog::ListTagsRequest'];

coerce 'ListTagsRequest',
    from HashRef, via { 'Google::Cloud::Datacatalog::V1::Datacatalog::ListTagsRequest'->new($_) };

declare 'RepeatedListTagsRequest',
    as ArrayRef[ListTagsRequest()];

coerce 'RepeatedListTagsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datacatalog::V1::Datacatalog::ListTagsRequest'->new($_) } @$_ ] };

declare 'MapStringListTagsRequest',
    as HashRef[ListTagsRequest()];

declare 'ListTagsResponse',
    as InstanceOf['Google::Cloud::Datacatalog::V1::Datacatalog::ListTagsResponse'];

coerce 'ListTagsResponse',
    from HashRef, via { 'Google::Cloud::Datacatalog::V1::Datacatalog::ListTagsResponse'->new($_) };

declare 'RepeatedListTagsResponse',
    as ArrayRef[ListTagsResponse()];

coerce 'RepeatedListTagsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datacatalog::V1::Datacatalog::ListTagsResponse'->new($_) } @$_ ] };

declare 'MapStringListTagsResponse',
    as HashRef[ListTagsResponse()];

declare 'ReconcileTagsRequest',
    as InstanceOf['Google::Cloud::Datacatalog::V1::Datacatalog::ReconcileTagsRequest'];

coerce 'ReconcileTagsRequest',
    from HashRef, via { 'Google::Cloud::Datacatalog::V1::Datacatalog::ReconcileTagsRequest'->new($_) };

declare 'RepeatedReconcileTagsRequest',
    as ArrayRef[ReconcileTagsRequest()];

coerce 'RepeatedReconcileTagsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datacatalog::V1::Datacatalog::ReconcileTagsRequest'->new($_) } @$_ ] };

declare 'MapStringReconcileTagsRequest',
    as HashRef[ReconcileTagsRequest()];

declare 'ReconcileTagsResponse',
    as InstanceOf['Google::Cloud::Datacatalog::V1::Datacatalog::ReconcileTagsResponse'];

coerce 'ReconcileTagsResponse',
    from HashRef, via { 'Google::Cloud::Datacatalog::V1::Datacatalog::ReconcileTagsResponse'->new($_) };

declare 'RepeatedReconcileTagsResponse',
    as ArrayRef[ReconcileTagsResponse()];

coerce 'RepeatedReconcileTagsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datacatalog::V1::Datacatalog::ReconcileTagsResponse'->new($_) } @$_ ] };

declare 'MapStringReconcileTagsResponse',
    as HashRef[ReconcileTagsResponse()];

declare 'ReconcileTagsMetadata',
    as InstanceOf['Google::Cloud::Datacatalog::V1::Datacatalog::ReconcileTagsMetadata'];

coerce 'ReconcileTagsMetadata',
    from HashRef, via { 'Google::Cloud::Datacatalog::V1::Datacatalog::ReconcileTagsMetadata'->new($_) };

declare 'RepeatedReconcileTagsMetadata',
    as ArrayRef[ReconcileTagsMetadata()];

coerce 'RepeatedReconcileTagsMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datacatalog::V1::Datacatalog::ReconcileTagsMetadata'->new($_) } @$_ ] };

declare 'MapStringReconcileTagsMetadata',
    as HashRef[ReconcileTagsMetadata()];

declare 'ReconciliationState',
    as (Int | Str);

declare 'ErrorsEntry',
    as InstanceOf['Google::Cloud::Datacatalog::V1::Datacatalog::ReconcileTagsMetadata::ErrorsEntry'];

coerce 'ErrorsEntry',
    from HashRef, via { 'Google::Cloud::Datacatalog::V1::Datacatalog::ReconcileTagsMetadata::ErrorsEntry'->new($_) };

declare 'RepeatedErrorsEntry',
    as ArrayRef[ErrorsEntry()];

coerce 'RepeatedErrorsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datacatalog::V1::Datacatalog::ReconcileTagsMetadata::ErrorsEntry'->new($_) } @$_ ] };

declare 'MapStringErrorsEntry',
    as HashRef[ErrorsEntry()];

declare 'ListEntriesRequest',
    as InstanceOf['Google::Cloud::Datacatalog::V1::Datacatalog::ListEntriesRequest'];

coerce 'ListEntriesRequest',
    from HashRef, via { 'Google::Cloud::Datacatalog::V1::Datacatalog::ListEntriesRequest'->new($_) };

declare 'RepeatedListEntriesRequest',
    as ArrayRef[ListEntriesRequest()];

coerce 'RepeatedListEntriesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datacatalog::V1::Datacatalog::ListEntriesRequest'->new($_) } @$_ ] };

declare 'MapStringListEntriesRequest',
    as HashRef[ListEntriesRequest()];

declare 'ListEntriesResponse',
    as InstanceOf['Google::Cloud::Datacatalog::V1::Datacatalog::ListEntriesResponse'];

coerce 'ListEntriesResponse',
    from HashRef, via { 'Google::Cloud::Datacatalog::V1::Datacatalog::ListEntriesResponse'->new($_) };

declare 'RepeatedListEntriesResponse',
    as ArrayRef[ListEntriesResponse()];

coerce 'RepeatedListEntriesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datacatalog::V1::Datacatalog::ListEntriesResponse'->new($_) } @$_ ] };

declare 'MapStringListEntriesResponse',
    as HashRef[ListEntriesResponse()];

declare 'StarEntryRequest',
    as InstanceOf['Google::Cloud::Datacatalog::V1::Datacatalog::StarEntryRequest'];

coerce 'StarEntryRequest',
    from HashRef, via { 'Google::Cloud::Datacatalog::V1::Datacatalog::StarEntryRequest'->new($_) };

declare 'RepeatedStarEntryRequest',
    as ArrayRef[StarEntryRequest()];

coerce 'RepeatedStarEntryRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datacatalog::V1::Datacatalog::StarEntryRequest'->new($_) } @$_ ] };

declare 'MapStringStarEntryRequest',
    as HashRef[StarEntryRequest()];

declare 'StarEntryResponse',
    as InstanceOf['Google::Cloud::Datacatalog::V1::Datacatalog::StarEntryResponse'];

coerce 'StarEntryResponse',
    from HashRef, via { 'Google::Cloud::Datacatalog::V1::Datacatalog::StarEntryResponse'->new($_) };

declare 'RepeatedStarEntryResponse',
    as ArrayRef[StarEntryResponse()];

coerce 'RepeatedStarEntryResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datacatalog::V1::Datacatalog::StarEntryResponse'->new($_) } @$_ ] };

declare 'MapStringStarEntryResponse',
    as HashRef[StarEntryResponse()];

declare 'UnstarEntryRequest',
    as InstanceOf['Google::Cloud::Datacatalog::V1::Datacatalog::UnstarEntryRequest'];

coerce 'UnstarEntryRequest',
    from HashRef, via { 'Google::Cloud::Datacatalog::V1::Datacatalog::UnstarEntryRequest'->new($_) };

declare 'RepeatedUnstarEntryRequest',
    as ArrayRef[UnstarEntryRequest()];

coerce 'RepeatedUnstarEntryRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datacatalog::V1::Datacatalog::UnstarEntryRequest'->new($_) } @$_ ] };

declare 'MapStringUnstarEntryRequest',
    as HashRef[UnstarEntryRequest()];

declare 'UnstarEntryResponse',
    as InstanceOf['Google::Cloud::Datacatalog::V1::Datacatalog::UnstarEntryResponse'];

coerce 'UnstarEntryResponse',
    from HashRef, via { 'Google::Cloud::Datacatalog::V1::Datacatalog::UnstarEntryResponse'->new($_) };

declare 'RepeatedUnstarEntryResponse',
    as ArrayRef[UnstarEntryResponse()];

coerce 'RepeatedUnstarEntryResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datacatalog::V1::Datacatalog::UnstarEntryResponse'->new($_) } @$_ ] };

declare 'MapStringUnstarEntryResponse',
    as HashRef[UnstarEntryResponse()];

declare 'ImportEntriesRequest',
    as InstanceOf['Google::Cloud::Datacatalog::V1::Datacatalog::ImportEntriesRequest'];

coerce 'ImportEntriesRequest',
    from HashRef, via { 'Google::Cloud::Datacatalog::V1::Datacatalog::ImportEntriesRequest'->new($_) };

declare 'RepeatedImportEntriesRequest',
    as ArrayRef[ImportEntriesRequest()];

coerce 'RepeatedImportEntriesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datacatalog::V1::Datacatalog::ImportEntriesRequest'->new($_) } @$_ ] };

declare 'MapStringImportEntriesRequest',
    as HashRef[ImportEntriesRequest()];

declare 'ImportEntriesResponse',
    as InstanceOf['Google::Cloud::Datacatalog::V1::Datacatalog::ImportEntriesResponse'];

coerce 'ImportEntriesResponse',
    from HashRef, via { 'Google::Cloud::Datacatalog::V1::Datacatalog::ImportEntriesResponse'->new($_) };

declare 'RepeatedImportEntriesResponse',
    as ArrayRef[ImportEntriesResponse()];

coerce 'RepeatedImportEntriesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datacatalog::V1::Datacatalog::ImportEntriesResponse'->new($_) } @$_ ] };

declare 'MapStringImportEntriesResponse',
    as HashRef[ImportEntriesResponse()];

declare 'ImportEntriesMetadata',
    as InstanceOf['Google::Cloud::Datacatalog::V1::Datacatalog::ImportEntriesMetadata'];

coerce 'ImportEntriesMetadata',
    from HashRef, via { 'Google::Cloud::Datacatalog::V1::Datacatalog::ImportEntriesMetadata'->new($_) };

declare 'RepeatedImportEntriesMetadata',
    as ArrayRef[ImportEntriesMetadata()];

coerce 'RepeatedImportEntriesMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datacatalog::V1::Datacatalog::ImportEntriesMetadata'->new($_) } @$_ ] };

declare 'MapStringImportEntriesMetadata',
    as HashRef[ImportEntriesMetadata()];

declare 'ImportState',
    as (Int | Str);

declare 'ModifyEntryOverviewRequest',
    as InstanceOf['Google::Cloud::Datacatalog::V1::Datacatalog::ModifyEntryOverviewRequest'];

coerce 'ModifyEntryOverviewRequest',
    from HashRef, via { 'Google::Cloud::Datacatalog::V1::Datacatalog::ModifyEntryOverviewRequest'->new($_) };

declare 'RepeatedModifyEntryOverviewRequest',
    as ArrayRef[ModifyEntryOverviewRequest()];

coerce 'RepeatedModifyEntryOverviewRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datacatalog::V1::Datacatalog::ModifyEntryOverviewRequest'->new($_) } @$_ ] };

declare 'MapStringModifyEntryOverviewRequest',
    as HashRef[ModifyEntryOverviewRequest()];

declare 'ModifyEntryContactsRequest',
    as InstanceOf['Google::Cloud::Datacatalog::V1::Datacatalog::ModifyEntryContactsRequest'];

coerce 'ModifyEntryContactsRequest',
    from HashRef, via { 'Google::Cloud::Datacatalog::V1::Datacatalog::ModifyEntryContactsRequest'->new($_) };

declare 'RepeatedModifyEntryContactsRequest',
    as ArrayRef[ModifyEntryContactsRequest()];

coerce 'RepeatedModifyEntryContactsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datacatalog::V1::Datacatalog::ModifyEntryContactsRequest'->new($_) } @$_ ] };

declare 'MapStringModifyEntryContactsRequest',
    as HashRef[ModifyEntryContactsRequest()];

declare 'SetConfigRequest',
    as InstanceOf['Google::Cloud::Datacatalog::V1::Datacatalog::SetConfigRequest'];

coerce 'SetConfigRequest',
    from HashRef, via { 'Google::Cloud::Datacatalog::V1::Datacatalog::SetConfigRequest'->new($_) };

declare 'RepeatedSetConfigRequest',
    as ArrayRef[SetConfigRequest()];

coerce 'RepeatedSetConfigRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datacatalog::V1::Datacatalog::SetConfigRequest'->new($_) } @$_ ] };

declare 'MapStringSetConfigRequest',
    as HashRef[SetConfigRequest()];

declare 'RetrieveConfigRequest',
    as InstanceOf['Google::Cloud::Datacatalog::V1::Datacatalog::RetrieveConfigRequest'];

coerce 'RetrieveConfigRequest',
    from HashRef, via { 'Google::Cloud::Datacatalog::V1::Datacatalog::RetrieveConfigRequest'->new($_) };

declare 'RepeatedRetrieveConfigRequest',
    as ArrayRef[RetrieveConfigRequest()];

coerce 'RepeatedRetrieveConfigRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datacatalog::V1::Datacatalog::RetrieveConfigRequest'->new($_) } @$_ ] };

declare 'MapStringRetrieveConfigRequest',
    as HashRef[RetrieveConfigRequest()];

declare 'RetrieveEffectiveConfigRequest',
    as InstanceOf['Google::Cloud::Datacatalog::V1::Datacatalog::RetrieveEffectiveConfigRequest'];

coerce 'RetrieveEffectiveConfigRequest',
    from HashRef, via { 'Google::Cloud::Datacatalog::V1::Datacatalog::RetrieveEffectiveConfigRequest'->new($_) };

declare 'RepeatedRetrieveEffectiveConfigRequest',
    as ArrayRef[RetrieveEffectiveConfigRequest()];

coerce 'RepeatedRetrieveEffectiveConfigRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datacatalog::V1::Datacatalog::RetrieveEffectiveConfigRequest'->new($_) } @$_ ] };

declare 'MapStringRetrieveEffectiveConfigRequest',
    as HashRef[RetrieveEffectiveConfigRequest()];

declare 'OrganizationConfig',
    as InstanceOf['Google::Cloud::Datacatalog::V1::Datacatalog::OrganizationConfig'];

coerce 'OrganizationConfig',
    from HashRef, via { 'Google::Cloud::Datacatalog::V1::Datacatalog::OrganizationConfig'->new($_) };

declare 'RepeatedOrganizationConfig',
    as ArrayRef[OrganizationConfig()];

coerce 'RepeatedOrganizationConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datacatalog::V1::Datacatalog::OrganizationConfig'->new($_) } @$_ ] };

declare 'MapStringOrganizationConfig',
    as HashRef[OrganizationConfig()];

declare 'ConfigEntry',
    as InstanceOf['Google::Cloud::Datacatalog::V1::Datacatalog::OrganizationConfig::ConfigEntry'];

coerce 'ConfigEntry',
    from HashRef, via { 'Google::Cloud::Datacatalog::V1::Datacatalog::OrganizationConfig::ConfigEntry'->new($_) };

declare 'RepeatedConfigEntry',
    as ArrayRef[ConfigEntry()];

coerce 'RepeatedConfigEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datacatalog::V1::Datacatalog::OrganizationConfig::ConfigEntry'->new($_) } @$_ ] };

declare 'MapStringConfigEntry',
    as HashRef[ConfigEntry()];

declare 'MigrationConfig',
    as InstanceOf['Google::Cloud::Datacatalog::V1::Datacatalog::MigrationConfig'];

coerce 'MigrationConfig',
    from HashRef, via { 'Google::Cloud::Datacatalog::V1::Datacatalog::MigrationConfig'->new($_) };

declare 'RepeatedMigrationConfig',
    as ArrayRef[MigrationConfig()];

coerce 'RepeatedMigrationConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datacatalog::V1::Datacatalog::MigrationConfig'->new($_) } @$_ ] };

declare 'MapStringMigrationConfig',
    as HashRef[MigrationConfig()];

1;

__END__

=head1 NAME

Google::Cloud::Datacatalog::V1::Datacatalog::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
