package Google::Cloud::Bigquery::Analyticshub::V1::Analyticshub::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'DiscoveryType',
    as (Int | Str);

declare 'SharedResourceType',
    as (Int | Str);

declare 'DataExchange',
    as InstanceOf['Google::Cloud::Bigquery::Analyticshub::V1::Analyticshub::DataExchange'];

coerce 'DataExchange',
    from HashRef, via { 'Google::Cloud::Bigquery::Analyticshub::V1::Analyticshub::DataExchange'->new($_) };

declare 'RepeatedDataExchange',
    as ArrayRef[DataExchange()];

coerce 'RepeatedDataExchange',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Analyticshub::V1::Analyticshub::DataExchange'->new($_) } @$_ ] };

declare 'MapStringDataExchange',
    as HashRef[DataExchange()];

declare 'QueryTemplate',
    as InstanceOf['Google::Cloud::Bigquery::Analyticshub::V1::Analyticshub::QueryTemplate'];

coerce 'QueryTemplate',
    from HashRef, via { 'Google::Cloud::Bigquery::Analyticshub::V1::Analyticshub::QueryTemplate'->new($_) };

declare 'RepeatedQueryTemplate',
    as ArrayRef[QueryTemplate()];

coerce 'RepeatedQueryTemplate',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Analyticshub::V1::Analyticshub::QueryTemplate'->new($_) } @$_ ] };

declare 'MapStringQueryTemplate',
    as HashRef[QueryTemplate()];

declare 'State',
    as (Int | Str);

declare 'Routine',
    as InstanceOf['Google::Cloud::Bigquery::Analyticshub::V1::Analyticshub::Routine'];

coerce 'Routine',
    from HashRef, via { 'Google::Cloud::Bigquery::Analyticshub::V1::Analyticshub::Routine'->new($_) };

declare 'RepeatedRoutine',
    as ArrayRef[Routine()];

coerce 'RepeatedRoutine',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Analyticshub::V1::Analyticshub::Routine'->new($_) } @$_ ] };

declare 'MapStringRoutine',
    as HashRef[Routine()];

declare 'RoutineType',
    as (Int | Str);

declare 'CreateQueryTemplateRequest',
    as InstanceOf['Google::Cloud::Bigquery::Analyticshub::V1::Analyticshub::CreateQueryTemplateRequest'];

coerce 'CreateQueryTemplateRequest',
    from HashRef, via { 'Google::Cloud::Bigquery::Analyticshub::V1::Analyticshub::CreateQueryTemplateRequest'->new($_) };

declare 'RepeatedCreateQueryTemplateRequest',
    as ArrayRef[CreateQueryTemplateRequest()];

coerce 'RepeatedCreateQueryTemplateRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Analyticshub::V1::Analyticshub::CreateQueryTemplateRequest'->new($_) } @$_ ] };

declare 'MapStringCreateQueryTemplateRequest',
    as HashRef[CreateQueryTemplateRequest()];

declare 'GetQueryTemplateRequest',
    as InstanceOf['Google::Cloud::Bigquery::Analyticshub::V1::Analyticshub::GetQueryTemplateRequest'];

coerce 'GetQueryTemplateRequest',
    from HashRef, via { 'Google::Cloud::Bigquery::Analyticshub::V1::Analyticshub::GetQueryTemplateRequest'->new($_) };

declare 'RepeatedGetQueryTemplateRequest',
    as ArrayRef[GetQueryTemplateRequest()];

coerce 'RepeatedGetQueryTemplateRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Analyticshub::V1::Analyticshub::GetQueryTemplateRequest'->new($_) } @$_ ] };

declare 'MapStringGetQueryTemplateRequest',
    as HashRef[GetQueryTemplateRequest()];

declare 'ListQueryTemplatesRequest',
    as InstanceOf['Google::Cloud::Bigquery::Analyticshub::V1::Analyticshub::ListQueryTemplatesRequest'];

coerce 'ListQueryTemplatesRequest',
    from HashRef, via { 'Google::Cloud::Bigquery::Analyticshub::V1::Analyticshub::ListQueryTemplatesRequest'->new($_) };

declare 'RepeatedListQueryTemplatesRequest',
    as ArrayRef[ListQueryTemplatesRequest()];

coerce 'RepeatedListQueryTemplatesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Analyticshub::V1::Analyticshub::ListQueryTemplatesRequest'->new($_) } @$_ ] };

declare 'MapStringListQueryTemplatesRequest',
    as HashRef[ListQueryTemplatesRequest()];

declare 'ListQueryTemplatesResponse',
    as InstanceOf['Google::Cloud::Bigquery::Analyticshub::V1::Analyticshub::ListQueryTemplatesResponse'];

coerce 'ListQueryTemplatesResponse',
    from HashRef, via { 'Google::Cloud::Bigquery::Analyticshub::V1::Analyticshub::ListQueryTemplatesResponse'->new($_) };

declare 'RepeatedListQueryTemplatesResponse',
    as ArrayRef[ListQueryTemplatesResponse()];

coerce 'RepeatedListQueryTemplatesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Analyticshub::V1::Analyticshub::ListQueryTemplatesResponse'->new($_) } @$_ ] };

declare 'MapStringListQueryTemplatesResponse',
    as HashRef[ListQueryTemplatesResponse()];

declare 'UpdateQueryTemplateRequest',
    as InstanceOf['Google::Cloud::Bigquery::Analyticshub::V1::Analyticshub::UpdateQueryTemplateRequest'];

coerce 'UpdateQueryTemplateRequest',
    from HashRef, via { 'Google::Cloud::Bigquery::Analyticshub::V1::Analyticshub::UpdateQueryTemplateRequest'->new($_) };

declare 'RepeatedUpdateQueryTemplateRequest',
    as ArrayRef[UpdateQueryTemplateRequest()];

coerce 'RepeatedUpdateQueryTemplateRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Analyticshub::V1::Analyticshub::UpdateQueryTemplateRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateQueryTemplateRequest',
    as HashRef[UpdateQueryTemplateRequest()];

declare 'DeleteQueryTemplateRequest',
    as InstanceOf['Google::Cloud::Bigquery::Analyticshub::V1::Analyticshub::DeleteQueryTemplateRequest'];

coerce 'DeleteQueryTemplateRequest',
    from HashRef, via { 'Google::Cloud::Bigquery::Analyticshub::V1::Analyticshub::DeleteQueryTemplateRequest'->new($_) };

declare 'RepeatedDeleteQueryTemplateRequest',
    as ArrayRef[DeleteQueryTemplateRequest()];

coerce 'RepeatedDeleteQueryTemplateRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Analyticshub::V1::Analyticshub::DeleteQueryTemplateRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteQueryTemplateRequest',
    as HashRef[DeleteQueryTemplateRequest()];

declare 'SubmitQueryTemplateRequest',
    as InstanceOf['Google::Cloud::Bigquery::Analyticshub::V1::Analyticshub::SubmitQueryTemplateRequest'];

coerce 'SubmitQueryTemplateRequest',
    from HashRef, via { 'Google::Cloud::Bigquery::Analyticshub::V1::Analyticshub::SubmitQueryTemplateRequest'->new($_) };

declare 'RepeatedSubmitQueryTemplateRequest',
    as ArrayRef[SubmitQueryTemplateRequest()];

coerce 'RepeatedSubmitQueryTemplateRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Analyticshub::V1::Analyticshub::SubmitQueryTemplateRequest'->new($_) } @$_ ] };

declare 'MapStringSubmitQueryTemplateRequest',
    as HashRef[SubmitQueryTemplateRequest()];

declare 'ApproveQueryTemplateRequest',
    as InstanceOf['Google::Cloud::Bigquery::Analyticshub::V1::Analyticshub::ApproveQueryTemplateRequest'];

coerce 'ApproveQueryTemplateRequest',
    from HashRef, via { 'Google::Cloud::Bigquery::Analyticshub::V1::Analyticshub::ApproveQueryTemplateRequest'->new($_) };

declare 'RepeatedApproveQueryTemplateRequest',
    as ArrayRef[ApproveQueryTemplateRequest()];

coerce 'RepeatedApproveQueryTemplateRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Analyticshub::V1::Analyticshub::ApproveQueryTemplateRequest'->new($_) } @$_ ] };

declare 'MapStringApproveQueryTemplateRequest',
    as HashRef[ApproveQueryTemplateRequest()];

declare 'SharingEnvironmentConfig',
    as InstanceOf['Google::Cloud::Bigquery::Analyticshub::V1::Analyticshub::SharingEnvironmentConfig'];

coerce 'SharingEnvironmentConfig',
    from HashRef, via { 'Google::Cloud::Bigquery::Analyticshub::V1::Analyticshub::SharingEnvironmentConfig'->new($_) };

declare 'RepeatedSharingEnvironmentConfig',
    as ArrayRef[SharingEnvironmentConfig()];

coerce 'RepeatedSharingEnvironmentConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Analyticshub::V1::Analyticshub::SharingEnvironmentConfig'->new($_) } @$_ ] };

declare 'MapStringSharingEnvironmentConfig',
    as HashRef[SharingEnvironmentConfig()];

declare 'DefaultExchangeConfig',
    as InstanceOf['Google::Cloud::Bigquery::Analyticshub::V1::Analyticshub::SharingEnvironmentConfig::DefaultExchangeConfig'];

coerce 'DefaultExchangeConfig',
    from HashRef, via { 'Google::Cloud::Bigquery::Analyticshub::V1::Analyticshub::SharingEnvironmentConfig::DefaultExchangeConfig'->new($_) };

declare 'RepeatedDefaultExchangeConfig',
    as ArrayRef[DefaultExchangeConfig()];

coerce 'RepeatedDefaultExchangeConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Analyticshub::V1::Analyticshub::SharingEnvironmentConfig::DefaultExchangeConfig'->new($_) } @$_ ] };

declare 'MapStringDefaultExchangeConfig',
    as HashRef[DefaultExchangeConfig()];

declare 'DcrExchangeConfig',
    as InstanceOf['Google::Cloud::Bigquery::Analyticshub::V1::Analyticshub::SharingEnvironmentConfig::DcrExchangeConfig'];

coerce 'DcrExchangeConfig',
    from HashRef, via { 'Google::Cloud::Bigquery::Analyticshub::V1::Analyticshub::SharingEnvironmentConfig::DcrExchangeConfig'->new($_) };

declare 'RepeatedDcrExchangeConfig',
    as ArrayRef[DcrExchangeConfig()];

coerce 'RepeatedDcrExchangeConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Analyticshub::V1::Analyticshub::SharingEnvironmentConfig::DcrExchangeConfig'->new($_) } @$_ ] };

declare 'MapStringDcrExchangeConfig',
    as HashRef[DcrExchangeConfig()];

declare 'DataProvider',
    as InstanceOf['Google::Cloud::Bigquery::Analyticshub::V1::Analyticshub::DataProvider'];

coerce 'DataProvider',
    from HashRef, via { 'Google::Cloud::Bigquery::Analyticshub::V1::Analyticshub::DataProvider'->new($_) };

declare 'RepeatedDataProvider',
    as ArrayRef[DataProvider()];

coerce 'RepeatedDataProvider',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Analyticshub::V1::Analyticshub::DataProvider'->new($_) } @$_ ] };

declare 'MapStringDataProvider',
    as HashRef[DataProvider()];

declare 'Publisher',
    as InstanceOf['Google::Cloud::Bigquery::Analyticshub::V1::Analyticshub::Publisher'];

coerce 'Publisher',
    from HashRef, via { 'Google::Cloud::Bigquery::Analyticshub::V1::Analyticshub::Publisher'->new($_) };

declare 'RepeatedPublisher',
    as ArrayRef[Publisher()];

coerce 'RepeatedPublisher',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Analyticshub::V1::Analyticshub::Publisher'->new($_) } @$_ ] };

declare 'MapStringPublisher',
    as HashRef[Publisher()];

declare 'DestinationDatasetReference',
    as InstanceOf['Google::Cloud::Bigquery::Analyticshub::V1::Analyticshub::DestinationDatasetReference'];

coerce 'DestinationDatasetReference',
    from HashRef, via { 'Google::Cloud::Bigquery::Analyticshub::V1::Analyticshub::DestinationDatasetReference'->new($_) };

declare 'RepeatedDestinationDatasetReference',
    as ArrayRef[DestinationDatasetReference()];

coerce 'RepeatedDestinationDatasetReference',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Analyticshub::V1::Analyticshub::DestinationDatasetReference'->new($_) } @$_ ] };

declare 'MapStringDestinationDatasetReference',
    as HashRef[DestinationDatasetReference()];

declare 'DestinationDataset',
    as InstanceOf['Google::Cloud::Bigquery::Analyticshub::V1::Analyticshub::DestinationDataset'];

coerce 'DestinationDataset',
    from HashRef, via { 'Google::Cloud::Bigquery::Analyticshub::V1::Analyticshub::DestinationDataset'->new($_) };

declare 'RepeatedDestinationDataset',
    as ArrayRef[DestinationDataset()];

coerce 'RepeatedDestinationDataset',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Analyticshub::V1::Analyticshub::DestinationDataset'->new($_) } @$_ ] };

declare 'MapStringDestinationDataset',
    as HashRef[DestinationDataset()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Bigquery::Analyticshub::V1::Analyticshub::DestinationDataset::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Bigquery::Analyticshub::V1::Analyticshub::DestinationDataset::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Analyticshub::V1::Analyticshub::DestinationDataset::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'DestinationPubSubSubscription',
    as InstanceOf['Google::Cloud::Bigquery::Analyticshub::V1::Analyticshub::DestinationPubSubSubscription'];

coerce 'DestinationPubSubSubscription',
    from HashRef, via { 'Google::Cloud::Bigquery::Analyticshub::V1::Analyticshub::DestinationPubSubSubscription'->new($_) };

declare 'RepeatedDestinationPubSubSubscription',
    as ArrayRef[DestinationPubSubSubscription()];

coerce 'RepeatedDestinationPubSubSubscription',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Analyticshub::V1::Analyticshub::DestinationPubSubSubscription'->new($_) } @$_ ] };

declare 'MapStringDestinationPubSubSubscription',
    as HashRef[DestinationPubSubSubscription()];

declare 'Listing',
    as InstanceOf['Google::Cloud::Bigquery::Analyticshub::V1::Analyticshub::Listing'];

coerce 'Listing',
    from HashRef, via { 'Google::Cloud::Bigquery::Analyticshub::V1::Analyticshub::Listing'->new($_) };

declare 'RepeatedListing',
    as ArrayRef[Listing()];

coerce 'RepeatedListing',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Analyticshub::V1::Analyticshub::Listing'->new($_) } @$_ ] };

declare 'MapStringListing',
    as HashRef[Listing()];

declare 'State',
    as (Int | Str);

declare 'Category',
    as (Int | Str);

declare 'BigQueryDatasetSource',
    as InstanceOf['Google::Cloud::Bigquery::Analyticshub::V1::Analyticshub::Listing::BigQueryDatasetSource'];

coerce 'BigQueryDatasetSource',
    from HashRef, via { 'Google::Cloud::Bigquery::Analyticshub::V1::Analyticshub::Listing::BigQueryDatasetSource'->new($_) };

declare 'RepeatedBigQueryDatasetSource',
    as ArrayRef[BigQueryDatasetSource()];

coerce 'RepeatedBigQueryDatasetSource',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Analyticshub::V1::Analyticshub::Listing::BigQueryDatasetSource'->new($_) } @$_ ] };

declare 'MapStringBigQueryDatasetSource',
    as HashRef[BigQueryDatasetSource()];

declare 'SelectedResource',
    as InstanceOf['Google::Cloud::Bigquery::Analyticshub::V1::Analyticshub::Listing::BigQueryDatasetSource::SelectedResource'];

coerce 'SelectedResource',
    from HashRef, via { 'Google::Cloud::Bigquery::Analyticshub::V1::Analyticshub::Listing::BigQueryDatasetSource::SelectedResource'->new($_) };

declare 'RepeatedSelectedResource',
    as ArrayRef[SelectedResource()];

coerce 'RepeatedSelectedResource',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Analyticshub::V1::Analyticshub::Listing::BigQueryDatasetSource::SelectedResource'->new($_) } @$_ ] };

declare 'MapStringSelectedResource',
    as HashRef[SelectedResource()];

declare 'RestrictedExportPolicy',
    as InstanceOf['Google::Cloud::Bigquery::Analyticshub::V1::Analyticshub::Listing::BigQueryDatasetSource::RestrictedExportPolicy'];

coerce 'RestrictedExportPolicy',
    from HashRef, via { 'Google::Cloud::Bigquery::Analyticshub::V1::Analyticshub::Listing::BigQueryDatasetSource::RestrictedExportPolicy'->new($_) };

declare 'RepeatedRestrictedExportPolicy',
    as ArrayRef[RestrictedExportPolicy()];

coerce 'RepeatedRestrictedExportPolicy',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Analyticshub::V1::Analyticshub::Listing::BigQueryDatasetSource::RestrictedExportPolicy'->new($_) } @$_ ] };

declare 'MapStringRestrictedExportPolicy',
    as HashRef[RestrictedExportPolicy()];

declare 'Replica',
    as InstanceOf['Google::Cloud::Bigquery::Analyticshub::V1::Analyticshub::Listing::BigQueryDatasetSource::Replica'];

coerce 'Replica',
    from HashRef, via { 'Google::Cloud::Bigquery::Analyticshub::V1::Analyticshub::Listing::BigQueryDatasetSource::Replica'->new($_) };

declare 'RepeatedReplica',
    as ArrayRef[Replica()];

coerce 'RepeatedReplica',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Analyticshub::V1::Analyticshub::Listing::BigQueryDatasetSource::Replica'->new($_) } @$_ ] };

declare 'MapStringReplica',
    as HashRef[Replica()];

declare 'ReplicaState',
    as (Int | Str);

declare 'PrimaryState',
    as (Int | Str);

declare 'PubSubTopicSource',
    as InstanceOf['Google::Cloud::Bigquery::Analyticshub::V1::Analyticshub::Listing::PubSubTopicSource'];

coerce 'PubSubTopicSource',
    from HashRef, via { 'Google::Cloud::Bigquery::Analyticshub::V1::Analyticshub::Listing::PubSubTopicSource'->new($_) };

declare 'RepeatedPubSubTopicSource',
    as ArrayRef[PubSubTopicSource()];

coerce 'RepeatedPubSubTopicSource',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Analyticshub::V1::Analyticshub::Listing::PubSubTopicSource'->new($_) } @$_ ] };

declare 'MapStringPubSubTopicSource',
    as HashRef[PubSubTopicSource()];

declare 'RestrictedExportConfig',
    as InstanceOf['Google::Cloud::Bigquery::Analyticshub::V1::Analyticshub::Listing::RestrictedExportConfig'];

coerce 'RestrictedExportConfig',
    from HashRef, via { 'Google::Cloud::Bigquery::Analyticshub::V1::Analyticshub::Listing::RestrictedExportConfig'->new($_) };

declare 'RepeatedRestrictedExportConfig',
    as ArrayRef[RestrictedExportConfig()];

coerce 'RepeatedRestrictedExportConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Analyticshub::V1::Analyticshub::Listing::RestrictedExportConfig'->new($_) } @$_ ] };

declare 'MapStringRestrictedExportConfig',
    as HashRef[RestrictedExportConfig()];

declare 'CommercialInfo',
    as InstanceOf['Google::Cloud::Bigquery::Analyticshub::V1::Analyticshub::Listing::CommercialInfo'];

coerce 'CommercialInfo',
    from HashRef, via { 'Google::Cloud::Bigquery::Analyticshub::V1::Analyticshub::Listing::CommercialInfo'->new($_) };

declare 'RepeatedCommercialInfo',
    as ArrayRef[CommercialInfo()];

coerce 'RepeatedCommercialInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Analyticshub::V1::Analyticshub::Listing::CommercialInfo'->new($_) } @$_ ] };

declare 'MapStringCommercialInfo',
    as HashRef[CommercialInfo()];

declare 'GoogleCloudMarketplaceInfo',
    as InstanceOf['Google::Cloud::Bigquery::Analyticshub::V1::Analyticshub::Listing::CommercialInfo::GoogleCloudMarketplaceInfo'];

coerce 'GoogleCloudMarketplaceInfo',
    from HashRef, via { 'Google::Cloud::Bigquery::Analyticshub::V1::Analyticshub::Listing::CommercialInfo::GoogleCloudMarketplaceInfo'->new($_) };

declare 'RepeatedGoogleCloudMarketplaceInfo',
    as ArrayRef[GoogleCloudMarketplaceInfo()];

coerce 'RepeatedGoogleCloudMarketplaceInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Analyticshub::V1::Analyticshub::Listing::CommercialInfo::GoogleCloudMarketplaceInfo'->new($_) } @$_ ] };

declare 'MapStringGoogleCloudMarketplaceInfo',
    as HashRef[GoogleCloudMarketplaceInfo()];

declare 'CommercialState',
    as (Int | Str);

declare 'StoredProcedureConfig',
    as InstanceOf['Google::Cloud::Bigquery::Analyticshub::V1::Analyticshub::StoredProcedureConfig'];

coerce 'StoredProcedureConfig',
    from HashRef, via { 'Google::Cloud::Bigquery::Analyticshub::V1::Analyticshub::StoredProcedureConfig'->new($_) };

declare 'RepeatedStoredProcedureConfig',
    as ArrayRef[StoredProcedureConfig()];

coerce 'RepeatedStoredProcedureConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Analyticshub::V1::Analyticshub::StoredProcedureConfig'->new($_) } @$_ ] };

declare 'MapStringStoredProcedureConfig',
    as HashRef[StoredProcedureConfig()];

declare 'StoredProcedureType',
    as (Int | Str);

declare 'Subscription',
    as InstanceOf['Google::Cloud::Bigquery::Analyticshub::V1::Analyticshub::Subscription'];

coerce 'Subscription',
    from HashRef, via { 'Google::Cloud::Bigquery::Analyticshub::V1::Analyticshub::Subscription'->new($_) };

declare 'RepeatedSubscription',
    as ArrayRef[Subscription()];

coerce 'RepeatedSubscription',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Analyticshub::V1::Analyticshub::Subscription'->new($_) } @$_ ] };

declare 'MapStringSubscription',
    as HashRef[Subscription()];

declare 'State',
    as (Int | Str);

declare 'LinkedResource',
    as InstanceOf['Google::Cloud::Bigquery::Analyticshub::V1::Analyticshub::Subscription::LinkedResource'];

coerce 'LinkedResource',
    from HashRef, via { 'Google::Cloud::Bigquery::Analyticshub::V1::Analyticshub::Subscription::LinkedResource'->new($_) };

declare 'RepeatedLinkedResource',
    as ArrayRef[LinkedResource()];

coerce 'RepeatedLinkedResource',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Analyticshub::V1::Analyticshub::Subscription::LinkedResource'->new($_) } @$_ ] };

declare 'MapStringLinkedResource',
    as HashRef[LinkedResource()];

declare 'CommercialInfo',
    as InstanceOf['Google::Cloud::Bigquery::Analyticshub::V1::Analyticshub::Subscription::CommercialInfo'];

coerce 'CommercialInfo',
    from HashRef, via { 'Google::Cloud::Bigquery::Analyticshub::V1::Analyticshub::Subscription::CommercialInfo'->new($_) };

declare 'RepeatedCommercialInfo',
    as ArrayRef[CommercialInfo()];

coerce 'RepeatedCommercialInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Analyticshub::V1::Analyticshub::Subscription::CommercialInfo'->new($_) } @$_ ] };

declare 'MapStringCommercialInfo',
    as HashRef[CommercialInfo()];

declare 'GoogleCloudMarketplaceInfo',
    as InstanceOf['Google::Cloud::Bigquery::Analyticshub::V1::Analyticshub::Subscription::CommercialInfo::GoogleCloudMarketplaceInfo'];

coerce 'GoogleCloudMarketplaceInfo',
    from HashRef, via { 'Google::Cloud::Bigquery::Analyticshub::V1::Analyticshub::Subscription::CommercialInfo::GoogleCloudMarketplaceInfo'->new($_) };

declare 'RepeatedGoogleCloudMarketplaceInfo',
    as ArrayRef[GoogleCloudMarketplaceInfo()];

coerce 'RepeatedGoogleCloudMarketplaceInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Analyticshub::V1::Analyticshub::Subscription::CommercialInfo::GoogleCloudMarketplaceInfo'->new($_) } @$_ ] };

declare 'MapStringGoogleCloudMarketplaceInfo',
    as HashRef[GoogleCloudMarketplaceInfo()];

declare 'LinkedDatasetMapEntry',
    as InstanceOf['Google::Cloud::Bigquery::Analyticshub::V1::Analyticshub::Subscription::LinkedDatasetMapEntry'];

coerce 'LinkedDatasetMapEntry',
    from HashRef, via { 'Google::Cloud::Bigquery::Analyticshub::V1::Analyticshub::Subscription::LinkedDatasetMapEntry'->new($_) };

declare 'RepeatedLinkedDatasetMapEntry',
    as ArrayRef[LinkedDatasetMapEntry()];

coerce 'RepeatedLinkedDatasetMapEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Analyticshub::V1::Analyticshub::Subscription::LinkedDatasetMapEntry'->new($_) } @$_ ] };

declare 'MapStringLinkedDatasetMapEntry',
    as HashRef[LinkedDatasetMapEntry()];

declare 'ListDataExchangesRequest',
    as InstanceOf['Google::Cloud::Bigquery::Analyticshub::V1::Analyticshub::ListDataExchangesRequest'];

coerce 'ListDataExchangesRequest',
    from HashRef, via { 'Google::Cloud::Bigquery::Analyticshub::V1::Analyticshub::ListDataExchangesRequest'->new($_) };

declare 'RepeatedListDataExchangesRequest',
    as ArrayRef[ListDataExchangesRequest()];

coerce 'RepeatedListDataExchangesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Analyticshub::V1::Analyticshub::ListDataExchangesRequest'->new($_) } @$_ ] };

declare 'MapStringListDataExchangesRequest',
    as HashRef[ListDataExchangesRequest()];

declare 'ListDataExchangesResponse',
    as InstanceOf['Google::Cloud::Bigquery::Analyticshub::V1::Analyticshub::ListDataExchangesResponse'];

coerce 'ListDataExchangesResponse',
    from HashRef, via { 'Google::Cloud::Bigquery::Analyticshub::V1::Analyticshub::ListDataExchangesResponse'->new($_) };

declare 'RepeatedListDataExchangesResponse',
    as ArrayRef[ListDataExchangesResponse()];

coerce 'RepeatedListDataExchangesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Analyticshub::V1::Analyticshub::ListDataExchangesResponse'->new($_) } @$_ ] };

declare 'MapStringListDataExchangesResponse',
    as HashRef[ListDataExchangesResponse()];

declare 'ListOrgDataExchangesRequest',
    as InstanceOf['Google::Cloud::Bigquery::Analyticshub::V1::Analyticshub::ListOrgDataExchangesRequest'];

coerce 'ListOrgDataExchangesRequest',
    from HashRef, via { 'Google::Cloud::Bigquery::Analyticshub::V1::Analyticshub::ListOrgDataExchangesRequest'->new($_) };

declare 'RepeatedListOrgDataExchangesRequest',
    as ArrayRef[ListOrgDataExchangesRequest()];

coerce 'RepeatedListOrgDataExchangesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Analyticshub::V1::Analyticshub::ListOrgDataExchangesRequest'->new($_) } @$_ ] };

declare 'MapStringListOrgDataExchangesRequest',
    as HashRef[ListOrgDataExchangesRequest()];

declare 'ListOrgDataExchangesResponse',
    as InstanceOf['Google::Cloud::Bigquery::Analyticshub::V1::Analyticshub::ListOrgDataExchangesResponse'];

coerce 'ListOrgDataExchangesResponse',
    from HashRef, via { 'Google::Cloud::Bigquery::Analyticshub::V1::Analyticshub::ListOrgDataExchangesResponse'->new($_) };

declare 'RepeatedListOrgDataExchangesResponse',
    as ArrayRef[ListOrgDataExchangesResponse()];

coerce 'RepeatedListOrgDataExchangesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Analyticshub::V1::Analyticshub::ListOrgDataExchangesResponse'->new($_) } @$_ ] };

declare 'MapStringListOrgDataExchangesResponse',
    as HashRef[ListOrgDataExchangesResponse()];

declare 'GetDataExchangeRequest',
    as InstanceOf['Google::Cloud::Bigquery::Analyticshub::V1::Analyticshub::GetDataExchangeRequest'];

coerce 'GetDataExchangeRequest',
    from HashRef, via { 'Google::Cloud::Bigquery::Analyticshub::V1::Analyticshub::GetDataExchangeRequest'->new($_) };

declare 'RepeatedGetDataExchangeRequest',
    as ArrayRef[GetDataExchangeRequest()];

coerce 'RepeatedGetDataExchangeRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Analyticshub::V1::Analyticshub::GetDataExchangeRequest'->new($_) } @$_ ] };

declare 'MapStringGetDataExchangeRequest',
    as HashRef[GetDataExchangeRequest()];

declare 'CreateDataExchangeRequest',
    as InstanceOf['Google::Cloud::Bigquery::Analyticshub::V1::Analyticshub::CreateDataExchangeRequest'];

coerce 'CreateDataExchangeRequest',
    from HashRef, via { 'Google::Cloud::Bigquery::Analyticshub::V1::Analyticshub::CreateDataExchangeRequest'->new($_) };

declare 'RepeatedCreateDataExchangeRequest',
    as ArrayRef[CreateDataExchangeRequest()];

coerce 'RepeatedCreateDataExchangeRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Analyticshub::V1::Analyticshub::CreateDataExchangeRequest'->new($_) } @$_ ] };

declare 'MapStringCreateDataExchangeRequest',
    as HashRef[CreateDataExchangeRequest()];

declare 'UpdateDataExchangeRequest',
    as InstanceOf['Google::Cloud::Bigquery::Analyticshub::V1::Analyticshub::UpdateDataExchangeRequest'];

coerce 'UpdateDataExchangeRequest',
    from HashRef, via { 'Google::Cloud::Bigquery::Analyticshub::V1::Analyticshub::UpdateDataExchangeRequest'->new($_) };

declare 'RepeatedUpdateDataExchangeRequest',
    as ArrayRef[UpdateDataExchangeRequest()];

coerce 'RepeatedUpdateDataExchangeRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Analyticshub::V1::Analyticshub::UpdateDataExchangeRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateDataExchangeRequest',
    as HashRef[UpdateDataExchangeRequest()];

declare 'DeleteDataExchangeRequest',
    as InstanceOf['Google::Cloud::Bigquery::Analyticshub::V1::Analyticshub::DeleteDataExchangeRequest'];

coerce 'DeleteDataExchangeRequest',
    from HashRef, via { 'Google::Cloud::Bigquery::Analyticshub::V1::Analyticshub::DeleteDataExchangeRequest'->new($_) };

declare 'RepeatedDeleteDataExchangeRequest',
    as ArrayRef[DeleteDataExchangeRequest()];

coerce 'RepeatedDeleteDataExchangeRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Analyticshub::V1::Analyticshub::DeleteDataExchangeRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteDataExchangeRequest',
    as HashRef[DeleteDataExchangeRequest()];

declare 'ListListingsRequest',
    as InstanceOf['Google::Cloud::Bigquery::Analyticshub::V1::Analyticshub::ListListingsRequest'];

coerce 'ListListingsRequest',
    from HashRef, via { 'Google::Cloud::Bigquery::Analyticshub::V1::Analyticshub::ListListingsRequest'->new($_) };

declare 'RepeatedListListingsRequest',
    as ArrayRef[ListListingsRequest()];

coerce 'RepeatedListListingsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Analyticshub::V1::Analyticshub::ListListingsRequest'->new($_) } @$_ ] };

declare 'MapStringListListingsRequest',
    as HashRef[ListListingsRequest()];

declare 'ListListingsResponse',
    as InstanceOf['Google::Cloud::Bigquery::Analyticshub::V1::Analyticshub::ListListingsResponse'];

coerce 'ListListingsResponse',
    from HashRef, via { 'Google::Cloud::Bigquery::Analyticshub::V1::Analyticshub::ListListingsResponse'->new($_) };

declare 'RepeatedListListingsResponse',
    as ArrayRef[ListListingsResponse()];

coerce 'RepeatedListListingsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Analyticshub::V1::Analyticshub::ListListingsResponse'->new($_) } @$_ ] };

declare 'MapStringListListingsResponse',
    as HashRef[ListListingsResponse()];

declare 'GetListingRequest',
    as InstanceOf['Google::Cloud::Bigquery::Analyticshub::V1::Analyticshub::GetListingRequest'];

coerce 'GetListingRequest',
    from HashRef, via { 'Google::Cloud::Bigquery::Analyticshub::V1::Analyticshub::GetListingRequest'->new($_) };

declare 'RepeatedGetListingRequest',
    as ArrayRef[GetListingRequest()];

coerce 'RepeatedGetListingRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Analyticshub::V1::Analyticshub::GetListingRequest'->new($_) } @$_ ] };

declare 'MapStringGetListingRequest',
    as HashRef[GetListingRequest()];

declare 'CreateListingRequest',
    as InstanceOf['Google::Cloud::Bigquery::Analyticshub::V1::Analyticshub::CreateListingRequest'];

coerce 'CreateListingRequest',
    from HashRef, via { 'Google::Cloud::Bigquery::Analyticshub::V1::Analyticshub::CreateListingRequest'->new($_) };

declare 'RepeatedCreateListingRequest',
    as ArrayRef[CreateListingRequest()];

coerce 'RepeatedCreateListingRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Analyticshub::V1::Analyticshub::CreateListingRequest'->new($_) } @$_ ] };

declare 'MapStringCreateListingRequest',
    as HashRef[CreateListingRequest()];

declare 'UpdateListingRequest',
    as InstanceOf['Google::Cloud::Bigquery::Analyticshub::V1::Analyticshub::UpdateListingRequest'];

coerce 'UpdateListingRequest',
    from HashRef, via { 'Google::Cloud::Bigquery::Analyticshub::V1::Analyticshub::UpdateListingRequest'->new($_) };

declare 'RepeatedUpdateListingRequest',
    as ArrayRef[UpdateListingRequest()];

coerce 'RepeatedUpdateListingRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Analyticshub::V1::Analyticshub::UpdateListingRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateListingRequest',
    as HashRef[UpdateListingRequest()];

declare 'DeleteListingRequest',
    as InstanceOf['Google::Cloud::Bigquery::Analyticshub::V1::Analyticshub::DeleteListingRequest'];

coerce 'DeleteListingRequest',
    from HashRef, via { 'Google::Cloud::Bigquery::Analyticshub::V1::Analyticshub::DeleteListingRequest'->new($_) };

declare 'RepeatedDeleteListingRequest',
    as ArrayRef[DeleteListingRequest()];

coerce 'RepeatedDeleteListingRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Analyticshub::V1::Analyticshub::DeleteListingRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteListingRequest',
    as HashRef[DeleteListingRequest()];

declare 'SubscribeListingRequest',
    as InstanceOf['Google::Cloud::Bigquery::Analyticshub::V1::Analyticshub::SubscribeListingRequest'];

coerce 'SubscribeListingRequest',
    from HashRef, via { 'Google::Cloud::Bigquery::Analyticshub::V1::Analyticshub::SubscribeListingRequest'->new($_) };

declare 'RepeatedSubscribeListingRequest',
    as ArrayRef[SubscribeListingRequest()];

coerce 'RepeatedSubscribeListingRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Analyticshub::V1::Analyticshub::SubscribeListingRequest'->new($_) } @$_ ] };

declare 'MapStringSubscribeListingRequest',
    as HashRef[SubscribeListingRequest()];

declare 'SubscribeListingResponse',
    as InstanceOf['Google::Cloud::Bigquery::Analyticshub::V1::Analyticshub::SubscribeListingResponse'];

coerce 'SubscribeListingResponse',
    from HashRef, via { 'Google::Cloud::Bigquery::Analyticshub::V1::Analyticshub::SubscribeListingResponse'->new($_) };

declare 'RepeatedSubscribeListingResponse',
    as ArrayRef[SubscribeListingResponse()];

coerce 'RepeatedSubscribeListingResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Analyticshub::V1::Analyticshub::SubscribeListingResponse'->new($_) } @$_ ] };

declare 'MapStringSubscribeListingResponse',
    as HashRef[SubscribeListingResponse()];

declare 'SubscribeDataExchangeRequest',
    as InstanceOf['Google::Cloud::Bigquery::Analyticshub::V1::Analyticshub::SubscribeDataExchangeRequest'];

coerce 'SubscribeDataExchangeRequest',
    from HashRef, via { 'Google::Cloud::Bigquery::Analyticshub::V1::Analyticshub::SubscribeDataExchangeRequest'->new($_) };

declare 'RepeatedSubscribeDataExchangeRequest',
    as ArrayRef[SubscribeDataExchangeRequest()];

coerce 'RepeatedSubscribeDataExchangeRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Analyticshub::V1::Analyticshub::SubscribeDataExchangeRequest'->new($_) } @$_ ] };

declare 'MapStringSubscribeDataExchangeRequest',
    as HashRef[SubscribeDataExchangeRequest()];

declare 'SubscribeDataExchangeResponse',
    as InstanceOf['Google::Cloud::Bigquery::Analyticshub::V1::Analyticshub::SubscribeDataExchangeResponse'];

coerce 'SubscribeDataExchangeResponse',
    from HashRef, via { 'Google::Cloud::Bigquery::Analyticshub::V1::Analyticshub::SubscribeDataExchangeResponse'->new($_) };

declare 'RepeatedSubscribeDataExchangeResponse',
    as ArrayRef[SubscribeDataExchangeResponse()];

coerce 'RepeatedSubscribeDataExchangeResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Analyticshub::V1::Analyticshub::SubscribeDataExchangeResponse'->new($_) } @$_ ] };

declare 'MapStringSubscribeDataExchangeResponse',
    as HashRef[SubscribeDataExchangeResponse()];

declare 'RefreshSubscriptionRequest',
    as InstanceOf['Google::Cloud::Bigquery::Analyticshub::V1::Analyticshub::RefreshSubscriptionRequest'];

coerce 'RefreshSubscriptionRequest',
    from HashRef, via { 'Google::Cloud::Bigquery::Analyticshub::V1::Analyticshub::RefreshSubscriptionRequest'->new($_) };

declare 'RepeatedRefreshSubscriptionRequest',
    as ArrayRef[RefreshSubscriptionRequest()];

coerce 'RepeatedRefreshSubscriptionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Analyticshub::V1::Analyticshub::RefreshSubscriptionRequest'->new($_) } @$_ ] };

declare 'MapStringRefreshSubscriptionRequest',
    as HashRef[RefreshSubscriptionRequest()];

declare 'RefreshSubscriptionResponse',
    as InstanceOf['Google::Cloud::Bigquery::Analyticshub::V1::Analyticshub::RefreshSubscriptionResponse'];

coerce 'RefreshSubscriptionResponse',
    from HashRef, via { 'Google::Cloud::Bigquery::Analyticshub::V1::Analyticshub::RefreshSubscriptionResponse'->new($_) };

declare 'RepeatedRefreshSubscriptionResponse',
    as ArrayRef[RefreshSubscriptionResponse()];

coerce 'RepeatedRefreshSubscriptionResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Analyticshub::V1::Analyticshub::RefreshSubscriptionResponse'->new($_) } @$_ ] };

declare 'MapStringRefreshSubscriptionResponse',
    as HashRef[RefreshSubscriptionResponse()];

declare 'GetSubscriptionRequest',
    as InstanceOf['Google::Cloud::Bigquery::Analyticshub::V1::Analyticshub::GetSubscriptionRequest'];

coerce 'GetSubscriptionRequest',
    from HashRef, via { 'Google::Cloud::Bigquery::Analyticshub::V1::Analyticshub::GetSubscriptionRequest'->new($_) };

declare 'RepeatedGetSubscriptionRequest',
    as ArrayRef[GetSubscriptionRequest()];

coerce 'RepeatedGetSubscriptionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Analyticshub::V1::Analyticshub::GetSubscriptionRequest'->new($_) } @$_ ] };

declare 'MapStringGetSubscriptionRequest',
    as HashRef[GetSubscriptionRequest()];

declare 'ListSubscriptionsRequest',
    as InstanceOf['Google::Cloud::Bigquery::Analyticshub::V1::Analyticshub::ListSubscriptionsRequest'];

coerce 'ListSubscriptionsRequest',
    from HashRef, via { 'Google::Cloud::Bigquery::Analyticshub::V1::Analyticshub::ListSubscriptionsRequest'->new($_) };

declare 'RepeatedListSubscriptionsRequest',
    as ArrayRef[ListSubscriptionsRequest()];

coerce 'RepeatedListSubscriptionsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Analyticshub::V1::Analyticshub::ListSubscriptionsRequest'->new($_) } @$_ ] };

declare 'MapStringListSubscriptionsRequest',
    as HashRef[ListSubscriptionsRequest()];

declare 'ListSubscriptionsResponse',
    as InstanceOf['Google::Cloud::Bigquery::Analyticshub::V1::Analyticshub::ListSubscriptionsResponse'];

coerce 'ListSubscriptionsResponse',
    from HashRef, via { 'Google::Cloud::Bigquery::Analyticshub::V1::Analyticshub::ListSubscriptionsResponse'->new($_) };

declare 'RepeatedListSubscriptionsResponse',
    as ArrayRef[ListSubscriptionsResponse()];

coerce 'RepeatedListSubscriptionsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Analyticshub::V1::Analyticshub::ListSubscriptionsResponse'->new($_) } @$_ ] };

declare 'MapStringListSubscriptionsResponse',
    as HashRef[ListSubscriptionsResponse()];

declare 'ListSharedResourceSubscriptionsRequest',
    as InstanceOf['Google::Cloud::Bigquery::Analyticshub::V1::Analyticshub::ListSharedResourceSubscriptionsRequest'];

coerce 'ListSharedResourceSubscriptionsRequest',
    from HashRef, via { 'Google::Cloud::Bigquery::Analyticshub::V1::Analyticshub::ListSharedResourceSubscriptionsRequest'->new($_) };

declare 'RepeatedListSharedResourceSubscriptionsRequest',
    as ArrayRef[ListSharedResourceSubscriptionsRequest()];

coerce 'RepeatedListSharedResourceSubscriptionsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Analyticshub::V1::Analyticshub::ListSharedResourceSubscriptionsRequest'->new($_) } @$_ ] };

declare 'MapStringListSharedResourceSubscriptionsRequest',
    as HashRef[ListSharedResourceSubscriptionsRequest()];

declare 'ListSharedResourceSubscriptionsResponse',
    as InstanceOf['Google::Cloud::Bigquery::Analyticshub::V1::Analyticshub::ListSharedResourceSubscriptionsResponse'];

coerce 'ListSharedResourceSubscriptionsResponse',
    from HashRef, via { 'Google::Cloud::Bigquery::Analyticshub::V1::Analyticshub::ListSharedResourceSubscriptionsResponse'->new($_) };

declare 'RepeatedListSharedResourceSubscriptionsResponse',
    as ArrayRef[ListSharedResourceSubscriptionsResponse()];

coerce 'RepeatedListSharedResourceSubscriptionsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Analyticshub::V1::Analyticshub::ListSharedResourceSubscriptionsResponse'->new($_) } @$_ ] };

declare 'MapStringListSharedResourceSubscriptionsResponse',
    as HashRef[ListSharedResourceSubscriptionsResponse()];

declare 'RevokeSubscriptionRequest',
    as InstanceOf['Google::Cloud::Bigquery::Analyticshub::V1::Analyticshub::RevokeSubscriptionRequest'];

coerce 'RevokeSubscriptionRequest',
    from HashRef, via { 'Google::Cloud::Bigquery::Analyticshub::V1::Analyticshub::RevokeSubscriptionRequest'->new($_) };

declare 'RepeatedRevokeSubscriptionRequest',
    as ArrayRef[RevokeSubscriptionRequest()];

coerce 'RepeatedRevokeSubscriptionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Analyticshub::V1::Analyticshub::RevokeSubscriptionRequest'->new($_) } @$_ ] };

declare 'MapStringRevokeSubscriptionRequest',
    as HashRef[RevokeSubscriptionRequest()];

declare 'RevokeSubscriptionResponse',
    as InstanceOf['Google::Cloud::Bigquery::Analyticshub::V1::Analyticshub::RevokeSubscriptionResponse'];

coerce 'RevokeSubscriptionResponse',
    from HashRef, via { 'Google::Cloud::Bigquery::Analyticshub::V1::Analyticshub::RevokeSubscriptionResponse'->new($_) };

declare 'RepeatedRevokeSubscriptionResponse',
    as ArrayRef[RevokeSubscriptionResponse()];

coerce 'RepeatedRevokeSubscriptionResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Analyticshub::V1::Analyticshub::RevokeSubscriptionResponse'->new($_) } @$_ ] };

declare 'MapStringRevokeSubscriptionResponse',
    as HashRef[RevokeSubscriptionResponse()];

declare 'DeleteSubscriptionRequest',
    as InstanceOf['Google::Cloud::Bigquery::Analyticshub::V1::Analyticshub::DeleteSubscriptionRequest'];

coerce 'DeleteSubscriptionRequest',
    from HashRef, via { 'Google::Cloud::Bigquery::Analyticshub::V1::Analyticshub::DeleteSubscriptionRequest'->new($_) };

declare 'RepeatedDeleteSubscriptionRequest',
    as ArrayRef[DeleteSubscriptionRequest()];

coerce 'RepeatedDeleteSubscriptionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Analyticshub::V1::Analyticshub::DeleteSubscriptionRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteSubscriptionRequest',
    as HashRef[DeleteSubscriptionRequest()];

declare 'OperationMetadata',
    as InstanceOf['Google::Cloud::Bigquery::Analyticshub::V1::Analyticshub::OperationMetadata'];

coerce 'OperationMetadata',
    from HashRef, via { 'Google::Cloud::Bigquery::Analyticshub::V1::Analyticshub::OperationMetadata'->new($_) };

declare 'RepeatedOperationMetadata',
    as ArrayRef[OperationMetadata()];

coerce 'RepeatedOperationMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Analyticshub::V1::Analyticshub::OperationMetadata'->new($_) } @$_ ] };

declare 'MapStringOperationMetadata',
    as HashRef[OperationMetadata()];

1;

__END__

=head1 NAME

Google::Cloud::Bigquery::Analyticshub::V1::Analyticshub::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
