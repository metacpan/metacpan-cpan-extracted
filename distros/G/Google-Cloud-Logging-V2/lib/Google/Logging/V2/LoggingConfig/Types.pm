package Google::Logging::V2::LoggingConfig::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'OperationState',
    as (Int | Str);

declare 'LifecycleState',
    as (Int | Str);

declare 'IndexType',
    as (Int | Str);

declare 'IndexConfig',
    as InstanceOf['Google::Logging::V2::LoggingConfig::IndexConfig'];

coerce 'IndexConfig',
    from HashRef, via { 'Google::Logging::V2::LoggingConfig::IndexConfig'->new($_) };

declare 'RepeatedIndexConfig',
    as ArrayRef[IndexConfig()];

coerce 'RepeatedIndexConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Logging::V2::LoggingConfig::IndexConfig'->new($_) } @$_ ] };

declare 'MapStringIndexConfig',
    as HashRef[IndexConfig()];

declare 'LogBucket',
    as InstanceOf['Google::Logging::V2::LoggingConfig::LogBucket'];

coerce 'LogBucket',
    from HashRef, via { 'Google::Logging::V2::LoggingConfig::LogBucket'->new($_) };

declare 'RepeatedLogBucket',
    as ArrayRef[LogBucket()];

coerce 'RepeatedLogBucket',
    from ArrayRef[HashRef], via { [ map { 'Google::Logging::V2::LoggingConfig::LogBucket'->new($_) } @$_ ] };

declare 'MapStringLogBucket',
    as HashRef[LogBucket()];

declare 'LogView',
    as InstanceOf['Google::Logging::V2::LoggingConfig::LogView'];

coerce 'LogView',
    from HashRef, via { 'Google::Logging::V2::LoggingConfig::LogView'->new($_) };

declare 'RepeatedLogView',
    as ArrayRef[LogView()];

coerce 'RepeatedLogView',
    from ArrayRef[HashRef], via { [ map { 'Google::Logging::V2::LoggingConfig::LogView'->new($_) } @$_ ] };

declare 'MapStringLogView',
    as HashRef[LogView()];

declare 'LogSink',
    as InstanceOf['Google::Logging::V2::LoggingConfig::LogSink'];

coerce 'LogSink',
    from HashRef, via { 'Google::Logging::V2::LoggingConfig::LogSink'->new($_) };

declare 'RepeatedLogSink',
    as ArrayRef[LogSink()];

coerce 'RepeatedLogSink',
    from ArrayRef[HashRef], via { [ map { 'Google::Logging::V2::LoggingConfig::LogSink'->new($_) } @$_ ] };

declare 'MapStringLogSink',
    as HashRef[LogSink()];

declare 'VersionFormat',
    as (Int | Str);

declare 'BigQueryDataset',
    as InstanceOf['Google::Logging::V2::LoggingConfig::BigQueryDataset'];

coerce 'BigQueryDataset',
    from HashRef, via { 'Google::Logging::V2::LoggingConfig::BigQueryDataset'->new($_) };

declare 'RepeatedBigQueryDataset',
    as ArrayRef[BigQueryDataset()];

coerce 'RepeatedBigQueryDataset',
    from ArrayRef[HashRef], via { [ map { 'Google::Logging::V2::LoggingConfig::BigQueryDataset'->new($_) } @$_ ] };

declare 'MapStringBigQueryDataset',
    as HashRef[BigQueryDataset()];

declare 'Link',
    as InstanceOf['Google::Logging::V2::LoggingConfig::Link'];

coerce 'Link',
    from HashRef, via { 'Google::Logging::V2::LoggingConfig::Link'->new($_) };

declare 'RepeatedLink',
    as ArrayRef[Link()];

coerce 'RepeatedLink',
    from ArrayRef[HashRef], via { [ map { 'Google::Logging::V2::LoggingConfig::Link'->new($_) } @$_ ] };

declare 'MapStringLink',
    as HashRef[Link()];

declare 'BigQueryOptions',
    as InstanceOf['Google::Logging::V2::LoggingConfig::BigQueryOptions'];

coerce 'BigQueryOptions',
    from HashRef, via { 'Google::Logging::V2::LoggingConfig::BigQueryOptions'->new($_) };

declare 'RepeatedBigQueryOptions',
    as ArrayRef[BigQueryOptions()];

coerce 'RepeatedBigQueryOptions',
    from ArrayRef[HashRef], via { [ map { 'Google::Logging::V2::LoggingConfig::BigQueryOptions'->new($_) } @$_ ] };

declare 'MapStringBigQueryOptions',
    as HashRef[BigQueryOptions()];

declare 'ListBucketsRequest',
    as InstanceOf['Google::Logging::V2::LoggingConfig::ListBucketsRequest'];

coerce 'ListBucketsRequest',
    from HashRef, via { 'Google::Logging::V2::LoggingConfig::ListBucketsRequest'->new($_) };

declare 'RepeatedListBucketsRequest',
    as ArrayRef[ListBucketsRequest()];

coerce 'RepeatedListBucketsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Logging::V2::LoggingConfig::ListBucketsRequest'->new($_) } @$_ ] };

declare 'MapStringListBucketsRequest',
    as HashRef[ListBucketsRequest()];

declare 'ListBucketsResponse',
    as InstanceOf['Google::Logging::V2::LoggingConfig::ListBucketsResponse'];

coerce 'ListBucketsResponse',
    from HashRef, via { 'Google::Logging::V2::LoggingConfig::ListBucketsResponse'->new($_) };

declare 'RepeatedListBucketsResponse',
    as ArrayRef[ListBucketsResponse()];

coerce 'RepeatedListBucketsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Logging::V2::LoggingConfig::ListBucketsResponse'->new($_) } @$_ ] };

declare 'MapStringListBucketsResponse',
    as HashRef[ListBucketsResponse()];

declare 'CreateBucketRequest',
    as InstanceOf['Google::Logging::V2::LoggingConfig::CreateBucketRequest'];

coerce 'CreateBucketRequest',
    from HashRef, via { 'Google::Logging::V2::LoggingConfig::CreateBucketRequest'->new($_) };

declare 'RepeatedCreateBucketRequest',
    as ArrayRef[CreateBucketRequest()];

coerce 'RepeatedCreateBucketRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Logging::V2::LoggingConfig::CreateBucketRequest'->new($_) } @$_ ] };

declare 'MapStringCreateBucketRequest',
    as HashRef[CreateBucketRequest()];

declare 'UpdateBucketRequest',
    as InstanceOf['Google::Logging::V2::LoggingConfig::UpdateBucketRequest'];

coerce 'UpdateBucketRequest',
    from HashRef, via { 'Google::Logging::V2::LoggingConfig::UpdateBucketRequest'->new($_) };

declare 'RepeatedUpdateBucketRequest',
    as ArrayRef[UpdateBucketRequest()];

coerce 'RepeatedUpdateBucketRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Logging::V2::LoggingConfig::UpdateBucketRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateBucketRequest',
    as HashRef[UpdateBucketRequest()];

declare 'GetBucketRequest',
    as InstanceOf['Google::Logging::V2::LoggingConfig::GetBucketRequest'];

coerce 'GetBucketRequest',
    from HashRef, via { 'Google::Logging::V2::LoggingConfig::GetBucketRequest'->new($_) };

declare 'RepeatedGetBucketRequest',
    as ArrayRef[GetBucketRequest()];

coerce 'RepeatedGetBucketRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Logging::V2::LoggingConfig::GetBucketRequest'->new($_) } @$_ ] };

declare 'MapStringGetBucketRequest',
    as HashRef[GetBucketRequest()];

declare 'DeleteBucketRequest',
    as InstanceOf['Google::Logging::V2::LoggingConfig::DeleteBucketRequest'];

coerce 'DeleteBucketRequest',
    from HashRef, via { 'Google::Logging::V2::LoggingConfig::DeleteBucketRequest'->new($_) };

declare 'RepeatedDeleteBucketRequest',
    as ArrayRef[DeleteBucketRequest()];

coerce 'RepeatedDeleteBucketRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Logging::V2::LoggingConfig::DeleteBucketRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteBucketRequest',
    as HashRef[DeleteBucketRequest()];

declare 'UndeleteBucketRequest',
    as InstanceOf['Google::Logging::V2::LoggingConfig::UndeleteBucketRequest'];

coerce 'UndeleteBucketRequest',
    from HashRef, via { 'Google::Logging::V2::LoggingConfig::UndeleteBucketRequest'->new($_) };

declare 'RepeatedUndeleteBucketRequest',
    as ArrayRef[UndeleteBucketRequest()];

coerce 'RepeatedUndeleteBucketRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Logging::V2::LoggingConfig::UndeleteBucketRequest'->new($_) } @$_ ] };

declare 'MapStringUndeleteBucketRequest',
    as HashRef[UndeleteBucketRequest()];

declare 'ListViewsRequest',
    as InstanceOf['Google::Logging::V2::LoggingConfig::ListViewsRequest'];

coerce 'ListViewsRequest',
    from HashRef, via { 'Google::Logging::V2::LoggingConfig::ListViewsRequest'->new($_) };

declare 'RepeatedListViewsRequest',
    as ArrayRef[ListViewsRequest()];

coerce 'RepeatedListViewsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Logging::V2::LoggingConfig::ListViewsRequest'->new($_) } @$_ ] };

declare 'MapStringListViewsRequest',
    as HashRef[ListViewsRequest()];

declare 'ListViewsResponse',
    as InstanceOf['Google::Logging::V2::LoggingConfig::ListViewsResponse'];

coerce 'ListViewsResponse',
    from HashRef, via { 'Google::Logging::V2::LoggingConfig::ListViewsResponse'->new($_) };

declare 'RepeatedListViewsResponse',
    as ArrayRef[ListViewsResponse()];

coerce 'RepeatedListViewsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Logging::V2::LoggingConfig::ListViewsResponse'->new($_) } @$_ ] };

declare 'MapStringListViewsResponse',
    as HashRef[ListViewsResponse()];

declare 'CreateViewRequest',
    as InstanceOf['Google::Logging::V2::LoggingConfig::CreateViewRequest'];

coerce 'CreateViewRequest',
    from HashRef, via { 'Google::Logging::V2::LoggingConfig::CreateViewRequest'->new($_) };

declare 'RepeatedCreateViewRequest',
    as ArrayRef[CreateViewRequest()];

coerce 'RepeatedCreateViewRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Logging::V2::LoggingConfig::CreateViewRequest'->new($_) } @$_ ] };

declare 'MapStringCreateViewRequest',
    as HashRef[CreateViewRequest()];

declare 'UpdateViewRequest',
    as InstanceOf['Google::Logging::V2::LoggingConfig::UpdateViewRequest'];

coerce 'UpdateViewRequest',
    from HashRef, via { 'Google::Logging::V2::LoggingConfig::UpdateViewRequest'->new($_) };

declare 'RepeatedUpdateViewRequest',
    as ArrayRef[UpdateViewRequest()];

coerce 'RepeatedUpdateViewRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Logging::V2::LoggingConfig::UpdateViewRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateViewRequest',
    as HashRef[UpdateViewRequest()];

declare 'GetViewRequest',
    as InstanceOf['Google::Logging::V2::LoggingConfig::GetViewRequest'];

coerce 'GetViewRequest',
    from HashRef, via { 'Google::Logging::V2::LoggingConfig::GetViewRequest'->new($_) };

declare 'RepeatedGetViewRequest',
    as ArrayRef[GetViewRequest()];

coerce 'RepeatedGetViewRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Logging::V2::LoggingConfig::GetViewRequest'->new($_) } @$_ ] };

declare 'MapStringGetViewRequest',
    as HashRef[GetViewRequest()];

declare 'DeleteViewRequest',
    as InstanceOf['Google::Logging::V2::LoggingConfig::DeleteViewRequest'];

coerce 'DeleteViewRequest',
    from HashRef, via { 'Google::Logging::V2::LoggingConfig::DeleteViewRequest'->new($_) };

declare 'RepeatedDeleteViewRequest',
    as ArrayRef[DeleteViewRequest()];

coerce 'RepeatedDeleteViewRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Logging::V2::LoggingConfig::DeleteViewRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteViewRequest',
    as HashRef[DeleteViewRequest()];

declare 'ListSinksRequest',
    as InstanceOf['Google::Logging::V2::LoggingConfig::ListSinksRequest'];

coerce 'ListSinksRequest',
    from HashRef, via { 'Google::Logging::V2::LoggingConfig::ListSinksRequest'->new($_) };

declare 'RepeatedListSinksRequest',
    as ArrayRef[ListSinksRequest()];

coerce 'RepeatedListSinksRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Logging::V2::LoggingConfig::ListSinksRequest'->new($_) } @$_ ] };

declare 'MapStringListSinksRequest',
    as HashRef[ListSinksRequest()];

declare 'ListSinksResponse',
    as InstanceOf['Google::Logging::V2::LoggingConfig::ListSinksResponse'];

coerce 'ListSinksResponse',
    from HashRef, via { 'Google::Logging::V2::LoggingConfig::ListSinksResponse'->new($_) };

declare 'RepeatedListSinksResponse',
    as ArrayRef[ListSinksResponse()];

coerce 'RepeatedListSinksResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Logging::V2::LoggingConfig::ListSinksResponse'->new($_) } @$_ ] };

declare 'MapStringListSinksResponse',
    as HashRef[ListSinksResponse()];

declare 'GetSinkRequest',
    as InstanceOf['Google::Logging::V2::LoggingConfig::GetSinkRequest'];

coerce 'GetSinkRequest',
    from HashRef, via { 'Google::Logging::V2::LoggingConfig::GetSinkRequest'->new($_) };

declare 'RepeatedGetSinkRequest',
    as ArrayRef[GetSinkRequest()];

coerce 'RepeatedGetSinkRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Logging::V2::LoggingConfig::GetSinkRequest'->new($_) } @$_ ] };

declare 'MapStringGetSinkRequest',
    as HashRef[GetSinkRequest()];

declare 'CreateSinkRequest',
    as InstanceOf['Google::Logging::V2::LoggingConfig::CreateSinkRequest'];

coerce 'CreateSinkRequest',
    from HashRef, via { 'Google::Logging::V2::LoggingConfig::CreateSinkRequest'->new($_) };

declare 'RepeatedCreateSinkRequest',
    as ArrayRef[CreateSinkRequest()];

coerce 'RepeatedCreateSinkRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Logging::V2::LoggingConfig::CreateSinkRequest'->new($_) } @$_ ] };

declare 'MapStringCreateSinkRequest',
    as HashRef[CreateSinkRequest()];

declare 'UpdateSinkRequest',
    as InstanceOf['Google::Logging::V2::LoggingConfig::UpdateSinkRequest'];

coerce 'UpdateSinkRequest',
    from HashRef, via { 'Google::Logging::V2::LoggingConfig::UpdateSinkRequest'->new($_) };

declare 'RepeatedUpdateSinkRequest',
    as ArrayRef[UpdateSinkRequest()];

coerce 'RepeatedUpdateSinkRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Logging::V2::LoggingConfig::UpdateSinkRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateSinkRequest',
    as HashRef[UpdateSinkRequest()];

declare 'DeleteSinkRequest',
    as InstanceOf['Google::Logging::V2::LoggingConfig::DeleteSinkRequest'];

coerce 'DeleteSinkRequest',
    from HashRef, via { 'Google::Logging::V2::LoggingConfig::DeleteSinkRequest'->new($_) };

declare 'RepeatedDeleteSinkRequest',
    as ArrayRef[DeleteSinkRequest()];

coerce 'RepeatedDeleteSinkRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Logging::V2::LoggingConfig::DeleteSinkRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteSinkRequest',
    as HashRef[DeleteSinkRequest()];

declare 'CreateLinkRequest',
    as InstanceOf['Google::Logging::V2::LoggingConfig::CreateLinkRequest'];

coerce 'CreateLinkRequest',
    from HashRef, via { 'Google::Logging::V2::LoggingConfig::CreateLinkRequest'->new($_) };

declare 'RepeatedCreateLinkRequest',
    as ArrayRef[CreateLinkRequest()];

coerce 'RepeatedCreateLinkRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Logging::V2::LoggingConfig::CreateLinkRequest'->new($_) } @$_ ] };

declare 'MapStringCreateLinkRequest',
    as HashRef[CreateLinkRequest()];

declare 'DeleteLinkRequest',
    as InstanceOf['Google::Logging::V2::LoggingConfig::DeleteLinkRequest'];

coerce 'DeleteLinkRequest',
    from HashRef, via { 'Google::Logging::V2::LoggingConfig::DeleteLinkRequest'->new($_) };

declare 'RepeatedDeleteLinkRequest',
    as ArrayRef[DeleteLinkRequest()];

coerce 'RepeatedDeleteLinkRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Logging::V2::LoggingConfig::DeleteLinkRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteLinkRequest',
    as HashRef[DeleteLinkRequest()];

declare 'ListLinksRequest',
    as InstanceOf['Google::Logging::V2::LoggingConfig::ListLinksRequest'];

coerce 'ListLinksRequest',
    from HashRef, via { 'Google::Logging::V2::LoggingConfig::ListLinksRequest'->new($_) };

declare 'RepeatedListLinksRequest',
    as ArrayRef[ListLinksRequest()];

coerce 'RepeatedListLinksRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Logging::V2::LoggingConfig::ListLinksRequest'->new($_) } @$_ ] };

declare 'MapStringListLinksRequest',
    as HashRef[ListLinksRequest()];

declare 'ListLinksResponse',
    as InstanceOf['Google::Logging::V2::LoggingConfig::ListLinksResponse'];

coerce 'ListLinksResponse',
    from HashRef, via { 'Google::Logging::V2::LoggingConfig::ListLinksResponse'->new($_) };

declare 'RepeatedListLinksResponse',
    as ArrayRef[ListLinksResponse()];

coerce 'RepeatedListLinksResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Logging::V2::LoggingConfig::ListLinksResponse'->new($_) } @$_ ] };

declare 'MapStringListLinksResponse',
    as HashRef[ListLinksResponse()];

declare 'GetLinkRequest',
    as InstanceOf['Google::Logging::V2::LoggingConfig::GetLinkRequest'];

coerce 'GetLinkRequest',
    from HashRef, via { 'Google::Logging::V2::LoggingConfig::GetLinkRequest'->new($_) };

declare 'RepeatedGetLinkRequest',
    as ArrayRef[GetLinkRequest()];

coerce 'RepeatedGetLinkRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Logging::V2::LoggingConfig::GetLinkRequest'->new($_) } @$_ ] };

declare 'MapStringGetLinkRequest',
    as HashRef[GetLinkRequest()];

declare 'LogExclusion',
    as InstanceOf['Google::Logging::V2::LoggingConfig::LogExclusion'];

coerce 'LogExclusion',
    from HashRef, via { 'Google::Logging::V2::LoggingConfig::LogExclusion'->new($_) };

declare 'RepeatedLogExclusion',
    as ArrayRef[LogExclusion()];

coerce 'RepeatedLogExclusion',
    from ArrayRef[HashRef], via { [ map { 'Google::Logging::V2::LoggingConfig::LogExclusion'->new($_) } @$_ ] };

declare 'MapStringLogExclusion',
    as HashRef[LogExclusion()];

declare 'ListExclusionsRequest',
    as InstanceOf['Google::Logging::V2::LoggingConfig::ListExclusionsRequest'];

coerce 'ListExclusionsRequest',
    from HashRef, via { 'Google::Logging::V2::LoggingConfig::ListExclusionsRequest'->new($_) };

declare 'RepeatedListExclusionsRequest',
    as ArrayRef[ListExclusionsRequest()];

coerce 'RepeatedListExclusionsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Logging::V2::LoggingConfig::ListExclusionsRequest'->new($_) } @$_ ] };

declare 'MapStringListExclusionsRequest',
    as HashRef[ListExclusionsRequest()];

declare 'ListExclusionsResponse',
    as InstanceOf['Google::Logging::V2::LoggingConfig::ListExclusionsResponse'];

coerce 'ListExclusionsResponse',
    from HashRef, via { 'Google::Logging::V2::LoggingConfig::ListExclusionsResponse'->new($_) };

declare 'RepeatedListExclusionsResponse',
    as ArrayRef[ListExclusionsResponse()];

coerce 'RepeatedListExclusionsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Logging::V2::LoggingConfig::ListExclusionsResponse'->new($_) } @$_ ] };

declare 'MapStringListExclusionsResponse',
    as HashRef[ListExclusionsResponse()];

declare 'GetExclusionRequest',
    as InstanceOf['Google::Logging::V2::LoggingConfig::GetExclusionRequest'];

coerce 'GetExclusionRequest',
    from HashRef, via { 'Google::Logging::V2::LoggingConfig::GetExclusionRequest'->new($_) };

declare 'RepeatedGetExclusionRequest',
    as ArrayRef[GetExclusionRequest()];

coerce 'RepeatedGetExclusionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Logging::V2::LoggingConfig::GetExclusionRequest'->new($_) } @$_ ] };

declare 'MapStringGetExclusionRequest',
    as HashRef[GetExclusionRequest()];

declare 'CreateExclusionRequest',
    as InstanceOf['Google::Logging::V2::LoggingConfig::CreateExclusionRequest'];

coerce 'CreateExclusionRequest',
    from HashRef, via { 'Google::Logging::V2::LoggingConfig::CreateExclusionRequest'->new($_) };

declare 'RepeatedCreateExclusionRequest',
    as ArrayRef[CreateExclusionRequest()];

coerce 'RepeatedCreateExclusionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Logging::V2::LoggingConfig::CreateExclusionRequest'->new($_) } @$_ ] };

declare 'MapStringCreateExclusionRequest',
    as HashRef[CreateExclusionRequest()];

declare 'UpdateExclusionRequest',
    as InstanceOf['Google::Logging::V2::LoggingConfig::UpdateExclusionRequest'];

coerce 'UpdateExclusionRequest',
    from HashRef, via { 'Google::Logging::V2::LoggingConfig::UpdateExclusionRequest'->new($_) };

declare 'RepeatedUpdateExclusionRequest',
    as ArrayRef[UpdateExclusionRequest()];

coerce 'RepeatedUpdateExclusionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Logging::V2::LoggingConfig::UpdateExclusionRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateExclusionRequest',
    as HashRef[UpdateExclusionRequest()];

declare 'DeleteExclusionRequest',
    as InstanceOf['Google::Logging::V2::LoggingConfig::DeleteExclusionRequest'];

coerce 'DeleteExclusionRequest',
    from HashRef, via { 'Google::Logging::V2::LoggingConfig::DeleteExclusionRequest'->new($_) };

declare 'RepeatedDeleteExclusionRequest',
    as ArrayRef[DeleteExclusionRequest()];

coerce 'RepeatedDeleteExclusionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Logging::V2::LoggingConfig::DeleteExclusionRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteExclusionRequest',
    as HashRef[DeleteExclusionRequest()];

declare 'GetCmekSettingsRequest',
    as InstanceOf['Google::Logging::V2::LoggingConfig::GetCmekSettingsRequest'];

coerce 'GetCmekSettingsRequest',
    from HashRef, via { 'Google::Logging::V2::LoggingConfig::GetCmekSettingsRequest'->new($_) };

declare 'RepeatedGetCmekSettingsRequest',
    as ArrayRef[GetCmekSettingsRequest()];

coerce 'RepeatedGetCmekSettingsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Logging::V2::LoggingConfig::GetCmekSettingsRequest'->new($_) } @$_ ] };

declare 'MapStringGetCmekSettingsRequest',
    as HashRef[GetCmekSettingsRequest()];

declare 'UpdateCmekSettingsRequest',
    as InstanceOf['Google::Logging::V2::LoggingConfig::UpdateCmekSettingsRequest'];

coerce 'UpdateCmekSettingsRequest',
    from HashRef, via { 'Google::Logging::V2::LoggingConfig::UpdateCmekSettingsRequest'->new($_) };

declare 'RepeatedUpdateCmekSettingsRequest',
    as ArrayRef[UpdateCmekSettingsRequest()];

coerce 'RepeatedUpdateCmekSettingsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Logging::V2::LoggingConfig::UpdateCmekSettingsRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateCmekSettingsRequest',
    as HashRef[UpdateCmekSettingsRequest()];

declare 'CmekSettings',
    as InstanceOf['Google::Logging::V2::LoggingConfig::CmekSettings'];

coerce 'CmekSettings',
    from HashRef, via { 'Google::Logging::V2::LoggingConfig::CmekSettings'->new($_) };

declare 'RepeatedCmekSettings',
    as ArrayRef[CmekSettings()];

coerce 'RepeatedCmekSettings',
    from ArrayRef[HashRef], via { [ map { 'Google::Logging::V2::LoggingConfig::CmekSettings'->new($_) } @$_ ] };

declare 'MapStringCmekSettings',
    as HashRef[CmekSettings()];

declare 'GetSettingsRequest',
    as InstanceOf['Google::Logging::V2::LoggingConfig::GetSettingsRequest'];

coerce 'GetSettingsRequest',
    from HashRef, via { 'Google::Logging::V2::LoggingConfig::GetSettingsRequest'->new($_) };

declare 'RepeatedGetSettingsRequest',
    as ArrayRef[GetSettingsRequest()];

coerce 'RepeatedGetSettingsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Logging::V2::LoggingConfig::GetSettingsRequest'->new($_) } @$_ ] };

declare 'MapStringGetSettingsRequest',
    as HashRef[GetSettingsRequest()];

declare 'UpdateSettingsRequest',
    as InstanceOf['Google::Logging::V2::LoggingConfig::UpdateSettingsRequest'];

coerce 'UpdateSettingsRequest',
    from HashRef, via { 'Google::Logging::V2::LoggingConfig::UpdateSettingsRequest'->new($_) };

declare 'RepeatedUpdateSettingsRequest',
    as ArrayRef[UpdateSettingsRequest()];

coerce 'RepeatedUpdateSettingsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Logging::V2::LoggingConfig::UpdateSettingsRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateSettingsRequest',
    as HashRef[UpdateSettingsRequest()];

declare 'Settings',
    as InstanceOf['Google::Logging::V2::LoggingConfig::Settings'];

coerce 'Settings',
    from HashRef, via { 'Google::Logging::V2::LoggingConfig::Settings'->new($_) };

declare 'RepeatedSettings',
    as ArrayRef[Settings()];

coerce 'RepeatedSettings',
    from ArrayRef[HashRef], via { [ map { 'Google::Logging::V2::LoggingConfig::Settings'->new($_) } @$_ ] };

declare 'MapStringSettings',
    as HashRef[Settings()];

declare 'CopyLogEntriesRequest',
    as InstanceOf['Google::Logging::V2::LoggingConfig::CopyLogEntriesRequest'];

coerce 'CopyLogEntriesRequest',
    from HashRef, via { 'Google::Logging::V2::LoggingConfig::CopyLogEntriesRequest'->new($_) };

declare 'RepeatedCopyLogEntriesRequest',
    as ArrayRef[CopyLogEntriesRequest()];

coerce 'RepeatedCopyLogEntriesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Logging::V2::LoggingConfig::CopyLogEntriesRequest'->new($_) } @$_ ] };

declare 'MapStringCopyLogEntriesRequest',
    as HashRef[CopyLogEntriesRequest()];

declare 'CopyLogEntriesMetadata',
    as InstanceOf['Google::Logging::V2::LoggingConfig::CopyLogEntriesMetadata'];

coerce 'CopyLogEntriesMetadata',
    from HashRef, via { 'Google::Logging::V2::LoggingConfig::CopyLogEntriesMetadata'->new($_) };

declare 'RepeatedCopyLogEntriesMetadata',
    as ArrayRef[CopyLogEntriesMetadata()];

coerce 'RepeatedCopyLogEntriesMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Logging::V2::LoggingConfig::CopyLogEntriesMetadata'->new($_) } @$_ ] };

declare 'MapStringCopyLogEntriesMetadata',
    as HashRef[CopyLogEntriesMetadata()];

declare 'CopyLogEntriesResponse',
    as InstanceOf['Google::Logging::V2::LoggingConfig::CopyLogEntriesResponse'];

coerce 'CopyLogEntriesResponse',
    from HashRef, via { 'Google::Logging::V2::LoggingConfig::CopyLogEntriesResponse'->new($_) };

declare 'RepeatedCopyLogEntriesResponse',
    as ArrayRef[CopyLogEntriesResponse()];

coerce 'RepeatedCopyLogEntriesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Logging::V2::LoggingConfig::CopyLogEntriesResponse'->new($_) } @$_ ] };

declare 'MapStringCopyLogEntriesResponse',
    as HashRef[CopyLogEntriesResponse()];

declare 'BucketMetadata',
    as InstanceOf['Google::Logging::V2::LoggingConfig::BucketMetadata'];

coerce 'BucketMetadata',
    from HashRef, via { 'Google::Logging::V2::LoggingConfig::BucketMetadata'->new($_) };

declare 'RepeatedBucketMetadata',
    as ArrayRef[BucketMetadata()];

coerce 'RepeatedBucketMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Logging::V2::LoggingConfig::BucketMetadata'->new($_) } @$_ ] };

declare 'MapStringBucketMetadata',
    as HashRef[BucketMetadata()];

declare 'LinkMetadata',
    as InstanceOf['Google::Logging::V2::LoggingConfig::LinkMetadata'];

coerce 'LinkMetadata',
    from HashRef, via { 'Google::Logging::V2::LoggingConfig::LinkMetadata'->new($_) };

declare 'RepeatedLinkMetadata',
    as ArrayRef[LinkMetadata()];

coerce 'RepeatedLinkMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Logging::V2::LoggingConfig::LinkMetadata'->new($_) } @$_ ] };

declare 'MapStringLinkMetadata',
    as HashRef[LinkMetadata()];

declare 'LocationMetadata',
    as InstanceOf['Google::Logging::V2::LoggingConfig::LocationMetadata'];

coerce 'LocationMetadata',
    from HashRef, via { 'Google::Logging::V2::LoggingConfig::LocationMetadata'->new($_) };

declare 'RepeatedLocationMetadata',
    as ArrayRef[LocationMetadata()];

coerce 'RepeatedLocationMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Logging::V2::LoggingConfig::LocationMetadata'->new($_) } @$_ ] };

declare 'MapStringLocationMetadata',
    as HashRef[LocationMetadata()];

1;

__END__

=head1 NAME

Google::Logging::V2::LoggingConfig::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
