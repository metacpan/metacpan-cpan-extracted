package Google::Cloud::Asset::V1::AssetService::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'ContentType',
    as (Int | Str);

declare 'AnalyzeIamPolicyLongrunningMetadata',
    as InstanceOf['Google::Cloud::Asset::V1::AssetService::AnalyzeIamPolicyLongrunningMetadata'];

coerce 'AnalyzeIamPolicyLongrunningMetadata',
    from HashRef, via { 'Google::Cloud::Asset::V1::AssetService::AnalyzeIamPolicyLongrunningMetadata'->new($_) };

declare 'RepeatedAnalyzeIamPolicyLongrunningMetadata',
    as ArrayRef[AnalyzeIamPolicyLongrunningMetadata()];

coerce 'RepeatedAnalyzeIamPolicyLongrunningMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Asset::V1::AssetService::AnalyzeIamPolicyLongrunningMetadata'->new($_) } @$_ ] };

declare 'MapStringAnalyzeIamPolicyLongrunningMetadata',
    as HashRef[AnalyzeIamPolicyLongrunningMetadata()];

declare 'ExportAssetsRequest',
    as InstanceOf['Google::Cloud::Asset::V1::AssetService::ExportAssetsRequest'];

coerce 'ExportAssetsRequest',
    from HashRef, via { 'Google::Cloud::Asset::V1::AssetService::ExportAssetsRequest'->new($_) };

declare 'RepeatedExportAssetsRequest',
    as ArrayRef[ExportAssetsRequest()];

coerce 'RepeatedExportAssetsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Asset::V1::AssetService::ExportAssetsRequest'->new($_) } @$_ ] };

declare 'MapStringExportAssetsRequest',
    as HashRef[ExportAssetsRequest()];

declare 'ExportAssetsResponse',
    as InstanceOf['Google::Cloud::Asset::V1::AssetService::ExportAssetsResponse'];

coerce 'ExportAssetsResponse',
    from HashRef, via { 'Google::Cloud::Asset::V1::AssetService::ExportAssetsResponse'->new($_) };

declare 'RepeatedExportAssetsResponse',
    as ArrayRef[ExportAssetsResponse()];

coerce 'RepeatedExportAssetsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Asset::V1::AssetService::ExportAssetsResponse'->new($_) } @$_ ] };

declare 'MapStringExportAssetsResponse',
    as HashRef[ExportAssetsResponse()];

declare 'ListAssetsRequest',
    as InstanceOf['Google::Cloud::Asset::V1::AssetService::ListAssetsRequest'];

coerce 'ListAssetsRequest',
    from HashRef, via { 'Google::Cloud::Asset::V1::AssetService::ListAssetsRequest'->new($_) };

declare 'RepeatedListAssetsRequest',
    as ArrayRef[ListAssetsRequest()];

coerce 'RepeatedListAssetsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Asset::V1::AssetService::ListAssetsRequest'->new($_) } @$_ ] };

declare 'MapStringListAssetsRequest',
    as HashRef[ListAssetsRequest()];

declare 'ListAssetsResponse',
    as InstanceOf['Google::Cloud::Asset::V1::AssetService::ListAssetsResponse'];

coerce 'ListAssetsResponse',
    from HashRef, via { 'Google::Cloud::Asset::V1::AssetService::ListAssetsResponse'->new($_) };

declare 'RepeatedListAssetsResponse',
    as ArrayRef[ListAssetsResponse()];

coerce 'RepeatedListAssetsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Asset::V1::AssetService::ListAssetsResponse'->new($_) } @$_ ] };

declare 'MapStringListAssetsResponse',
    as HashRef[ListAssetsResponse()];

declare 'BatchGetAssetsHistoryRequest',
    as InstanceOf['Google::Cloud::Asset::V1::AssetService::BatchGetAssetsHistoryRequest'];

coerce 'BatchGetAssetsHistoryRequest',
    from HashRef, via { 'Google::Cloud::Asset::V1::AssetService::BatchGetAssetsHistoryRequest'->new($_) };

declare 'RepeatedBatchGetAssetsHistoryRequest',
    as ArrayRef[BatchGetAssetsHistoryRequest()];

coerce 'RepeatedBatchGetAssetsHistoryRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Asset::V1::AssetService::BatchGetAssetsHistoryRequest'->new($_) } @$_ ] };

declare 'MapStringBatchGetAssetsHistoryRequest',
    as HashRef[BatchGetAssetsHistoryRequest()];

declare 'BatchGetAssetsHistoryResponse',
    as InstanceOf['Google::Cloud::Asset::V1::AssetService::BatchGetAssetsHistoryResponse'];

coerce 'BatchGetAssetsHistoryResponse',
    from HashRef, via { 'Google::Cloud::Asset::V1::AssetService::BatchGetAssetsHistoryResponse'->new($_) };

declare 'RepeatedBatchGetAssetsHistoryResponse',
    as ArrayRef[BatchGetAssetsHistoryResponse()];

coerce 'RepeatedBatchGetAssetsHistoryResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Asset::V1::AssetService::BatchGetAssetsHistoryResponse'->new($_) } @$_ ] };

declare 'MapStringBatchGetAssetsHistoryResponse',
    as HashRef[BatchGetAssetsHistoryResponse()];

declare 'CreateFeedRequest',
    as InstanceOf['Google::Cloud::Asset::V1::AssetService::CreateFeedRequest'];

coerce 'CreateFeedRequest',
    from HashRef, via { 'Google::Cloud::Asset::V1::AssetService::CreateFeedRequest'->new($_) };

declare 'RepeatedCreateFeedRequest',
    as ArrayRef[CreateFeedRequest()];

coerce 'RepeatedCreateFeedRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Asset::V1::AssetService::CreateFeedRequest'->new($_) } @$_ ] };

declare 'MapStringCreateFeedRequest',
    as HashRef[CreateFeedRequest()];

declare 'GetFeedRequest',
    as InstanceOf['Google::Cloud::Asset::V1::AssetService::GetFeedRequest'];

coerce 'GetFeedRequest',
    from HashRef, via { 'Google::Cloud::Asset::V1::AssetService::GetFeedRequest'->new($_) };

declare 'RepeatedGetFeedRequest',
    as ArrayRef[GetFeedRequest()];

coerce 'RepeatedGetFeedRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Asset::V1::AssetService::GetFeedRequest'->new($_) } @$_ ] };

declare 'MapStringGetFeedRequest',
    as HashRef[GetFeedRequest()];

declare 'ListFeedsRequest',
    as InstanceOf['Google::Cloud::Asset::V1::AssetService::ListFeedsRequest'];

coerce 'ListFeedsRequest',
    from HashRef, via { 'Google::Cloud::Asset::V1::AssetService::ListFeedsRequest'->new($_) };

declare 'RepeatedListFeedsRequest',
    as ArrayRef[ListFeedsRequest()];

coerce 'RepeatedListFeedsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Asset::V1::AssetService::ListFeedsRequest'->new($_) } @$_ ] };

declare 'MapStringListFeedsRequest',
    as HashRef[ListFeedsRequest()];

declare 'ListFeedsResponse',
    as InstanceOf['Google::Cloud::Asset::V1::AssetService::ListFeedsResponse'];

coerce 'ListFeedsResponse',
    from HashRef, via { 'Google::Cloud::Asset::V1::AssetService::ListFeedsResponse'->new($_) };

declare 'RepeatedListFeedsResponse',
    as ArrayRef[ListFeedsResponse()];

coerce 'RepeatedListFeedsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Asset::V1::AssetService::ListFeedsResponse'->new($_) } @$_ ] };

declare 'MapStringListFeedsResponse',
    as HashRef[ListFeedsResponse()];

declare 'UpdateFeedRequest',
    as InstanceOf['Google::Cloud::Asset::V1::AssetService::UpdateFeedRequest'];

coerce 'UpdateFeedRequest',
    from HashRef, via { 'Google::Cloud::Asset::V1::AssetService::UpdateFeedRequest'->new($_) };

declare 'RepeatedUpdateFeedRequest',
    as ArrayRef[UpdateFeedRequest()];

coerce 'RepeatedUpdateFeedRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Asset::V1::AssetService::UpdateFeedRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateFeedRequest',
    as HashRef[UpdateFeedRequest()];

declare 'DeleteFeedRequest',
    as InstanceOf['Google::Cloud::Asset::V1::AssetService::DeleteFeedRequest'];

coerce 'DeleteFeedRequest',
    from HashRef, via { 'Google::Cloud::Asset::V1::AssetService::DeleteFeedRequest'->new($_) };

declare 'RepeatedDeleteFeedRequest',
    as ArrayRef[DeleteFeedRequest()];

coerce 'RepeatedDeleteFeedRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Asset::V1::AssetService::DeleteFeedRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteFeedRequest',
    as HashRef[DeleteFeedRequest()];

declare 'OutputConfig',
    as InstanceOf['Google::Cloud::Asset::V1::AssetService::OutputConfig'];

coerce 'OutputConfig',
    from HashRef, via { 'Google::Cloud::Asset::V1::AssetService::OutputConfig'->new($_) };

declare 'RepeatedOutputConfig',
    as ArrayRef[OutputConfig()];

coerce 'RepeatedOutputConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Asset::V1::AssetService::OutputConfig'->new($_) } @$_ ] };

declare 'MapStringOutputConfig',
    as HashRef[OutputConfig()];

declare 'OutputResult',
    as InstanceOf['Google::Cloud::Asset::V1::AssetService::OutputResult'];

coerce 'OutputResult',
    from HashRef, via { 'Google::Cloud::Asset::V1::AssetService::OutputResult'->new($_) };

declare 'RepeatedOutputResult',
    as ArrayRef[OutputResult()];

coerce 'RepeatedOutputResult',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Asset::V1::AssetService::OutputResult'->new($_) } @$_ ] };

declare 'MapStringOutputResult',
    as HashRef[OutputResult()];

declare 'GcsOutputResult',
    as InstanceOf['Google::Cloud::Asset::V1::AssetService::GcsOutputResult'];

coerce 'GcsOutputResult',
    from HashRef, via { 'Google::Cloud::Asset::V1::AssetService::GcsOutputResult'->new($_) };

declare 'RepeatedGcsOutputResult',
    as ArrayRef[GcsOutputResult()];

coerce 'RepeatedGcsOutputResult',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Asset::V1::AssetService::GcsOutputResult'->new($_) } @$_ ] };

declare 'MapStringGcsOutputResult',
    as HashRef[GcsOutputResult()];

declare 'GcsDestination',
    as InstanceOf['Google::Cloud::Asset::V1::AssetService::GcsDestination'];

coerce 'GcsDestination',
    from HashRef, via { 'Google::Cloud::Asset::V1::AssetService::GcsDestination'->new($_) };

declare 'RepeatedGcsDestination',
    as ArrayRef[GcsDestination()];

coerce 'RepeatedGcsDestination',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Asset::V1::AssetService::GcsDestination'->new($_) } @$_ ] };

declare 'MapStringGcsDestination',
    as HashRef[GcsDestination()];

declare 'BigQueryDestination',
    as InstanceOf['Google::Cloud::Asset::V1::AssetService::BigQueryDestination'];

coerce 'BigQueryDestination',
    from HashRef, via { 'Google::Cloud::Asset::V1::AssetService::BigQueryDestination'->new($_) };

declare 'RepeatedBigQueryDestination',
    as ArrayRef[BigQueryDestination()];

coerce 'RepeatedBigQueryDestination',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Asset::V1::AssetService::BigQueryDestination'->new($_) } @$_ ] };

declare 'MapStringBigQueryDestination',
    as HashRef[BigQueryDestination()];

declare 'PartitionSpec',
    as InstanceOf['Google::Cloud::Asset::V1::AssetService::PartitionSpec'];

coerce 'PartitionSpec',
    from HashRef, via { 'Google::Cloud::Asset::V1::AssetService::PartitionSpec'->new($_) };

declare 'RepeatedPartitionSpec',
    as ArrayRef[PartitionSpec()];

coerce 'RepeatedPartitionSpec',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Asset::V1::AssetService::PartitionSpec'->new($_) } @$_ ] };

declare 'MapStringPartitionSpec',
    as HashRef[PartitionSpec()];

declare 'PartitionKey',
    as (Int | Str);

declare 'PubsubDestination',
    as InstanceOf['Google::Cloud::Asset::V1::AssetService::PubsubDestination'];

coerce 'PubsubDestination',
    from HashRef, via { 'Google::Cloud::Asset::V1::AssetService::PubsubDestination'->new($_) };

declare 'RepeatedPubsubDestination',
    as ArrayRef[PubsubDestination()];

coerce 'RepeatedPubsubDestination',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Asset::V1::AssetService::PubsubDestination'->new($_) } @$_ ] };

declare 'MapStringPubsubDestination',
    as HashRef[PubsubDestination()];

declare 'FeedOutputConfig',
    as InstanceOf['Google::Cloud::Asset::V1::AssetService::FeedOutputConfig'];

coerce 'FeedOutputConfig',
    from HashRef, via { 'Google::Cloud::Asset::V1::AssetService::FeedOutputConfig'->new($_) };

declare 'RepeatedFeedOutputConfig',
    as ArrayRef[FeedOutputConfig()];

coerce 'RepeatedFeedOutputConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Asset::V1::AssetService::FeedOutputConfig'->new($_) } @$_ ] };

declare 'MapStringFeedOutputConfig',
    as HashRef[FeedOutputConfig()];

declare 'Feed',
    as InstanceOf['Google::Cloud::Asset::V1::AssetService::Feed'];

coerce 'Feed',
    from HashRef, via { 'Google::Cloud::Asset::V1::AssetService::Feed'->new($_) };

declare 'RepeatedFeed',
    as ArrayRef[Feed()];

coerce 'RepeatedFeed',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Asset::V1::AssetService::Feed'->new($_) } @$_ ] };

declare 'MapStringFeed',
    as HashRef[Feed()];

declare 'SearchAllResourcesRequest',
    as InstanceOf['Google::Cloud::Asset::V1::AssetService::SearchAllResourcesRequest'];

coerce 'SearchAllResourcesRequest',
    from HashRef, via { 'Google::Cloud::Asset::V1::AssetService::SearchAllResourcesRequest'->new($_) };

declare 'RepeatedSearchAllResourcesRequest',
    as ArrayRef[SearchAllResourcesRequest()];

coerce 'RepeatedSearchAllResourcesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Asset::V1::AssetService::SearchAllResourcesRequest'->new($_) } @$_ ] };

declare 'MapStringSearchAllResourcesRequest',
    as HashRef[SearchAllResourcesRequest()];

declare 'SearchAllResourcesResponse',
    as InstanceOf['Google::Cloud::Asset::V1::AssetService::SearchAllResourcesResponse'];

coerce 'SearchAllResourcesResponse',
    from HashRef, via { 'Google::Cloud::Asset::V1::AssetService::SearchAllResourcesResponse'->new($_) };

declare 'RepeatedSearchAllResourcesResponse',
    as ArrayRef[SearchAllResourcesResponse()];

coerce 'RepeatedSearchAllResourcesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Asset::V1::AssetService::SearchAllResourcesResponse'->new($_) } @$_ ] };

declare 'MapStringSearchAllResourcesResponse',
    as HashRef[SearchAllResourcesResponse()];

declare 'SearchAllIamPoliciesRequest',
    as InstanceOf['Google::Cloud::Asset::V1::AssetService::SearchAllIamPoliciesRequest'];

coerce 'SearchAllIamPoliciesRequest',
    from HashRef, via { 'Google::Cloud::Asset::V1::AssetService::SearchAllIamPoliciesRequest'->new($_) };

declare 'RepeatedSearchAllIamPoliciesRequest',
    as ArrayRef[SearchAllIamPoliciesRequest()];

coerce 'RepeatedSearchAllIamPoliciesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Asset::V1::AssetService::SearchAllIamPoliciesRequest'->new($_) } @$_ ] };

declare 'MapStringSearchAllIamPoliciesRequest',
    as HashRef[SearchAllIamPoliciesRequest()];

declare 'SearchAllIamPoliciesResponse',
    as InstanceOf['Google::Cloud::Asset::V1::AssetService::SearchAllIamPoliciesResponse'];

coerce 'SearchAllIamPoliciesResponse',
    from HashRef, via { 'Google::Cloud::Asset::V1::AssetService::SearchAllIamPoliciesResponse'->new($_) };

declare 'RepeatedSearchAllIamPoliciesResponse',
    as ArrayRef[SearchAllIamPoliciesResponse()];

coerce 'RepeatedSearchAllIamPoliciesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Asset::V1::AssetService::SearchAllIamPoliciesResponse'->new($_) } @$_ ] };

declare 'MapStringSearchAllIamPoliciesResponse',
    as HashRef[SearchAllIamPoliciesResponse()];

declare 'IamPolicyAnalysisQuery',
    as InstanceOf['Google::Cloud::Asset::V1::AssetService::IamPolicyAnalysisQuery'];

coerce 'IamPolicyAnalysisQuery',
    from HashRef, via { 'Google::Cloud::Asset::V1::AssetService::IamPolicyAnalysisQuery'->new($_) };

declare 'RepeatedIamPolicyAnalysisQuery',
    as ArrayRef[IamPolicyAnalysisQuery()];

coerce 'RepeatedIamPolicyAnalysisQuery',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Asset::V1::AssetService::IamPolicyAnalysisQuery'->new($_) } @$_ ] };

declare 'MapStringIamPolicyAnalysisQuery',
    as HashRef[IamPolicyAnalysisQuery()];

declare 'ResourceSelector',
    as InstanceOf['Google::Cloud::Asset::V1::AssetService::IamPolicyAnalysisQuery::ResourceSelector'];

coerce 'ResourceSelector',
    from HashRef, via { 'Google::Cloud::Asset::V1::AssetService::IamPolicyAnalysisQuery::ResourceSelector'->new($_) };

declare 'RepeatedResourceSelector',
    as ArrayRef[ResourceSelector()];

coerce 'RepeatedResourceSelector',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Asset::V1::AssetService::IamPolicyAnalysisQuery::ResourceSelector'->new($_) } @$_ ] };

declare 'MapStringResourceSelector',
    as HashRef[ResourceSelector()];

declare 'IdentitySelector',
    as InstanceOf['Google::Cloud::Asset::V1::AssetService::IamPolicyAnalysisQuery::IdentitySelector'];

coerce 'IdentitySelector',
    from HashRef, via { 'Google::Cloud::Asset::V1::AssetService::IamPolicyAnalysisQuery::IdentitySelector'->new($_) };

declare 'RepeatedIdentitySelector',
    as ArrayRef[IdentitySelector()];

coerce 'RepeatedIdentitySelector',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Asset::V1::AssetService::IamPolicyAnalysisQuery::IdentitySelector'->new($_) } @$_ ] };

declare 'MapStringIdentitySelector',
    as HashRef[IdentitySelector()];

declare 'AccessSelector',
    as InstanceOf['Google::Cloud::Asset::V1::AssetService::IamPolicyAnalysisQuery::AccessSelector'];

coerce 'AccessSelector',
    from HashRef, via { 'Google::Cloud::Asset::V1::AssetService::IamPolicyAnalysisQuery::AccessSelector'->new($_) };

declare 'RepeatedAccessSelector',
    as ArrayRef[AccessSelector()];

coerce 'RepeatedAccessSelector',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Asset::V1::AssetService::IamPolicyAnalysisQuery::AccessSelector'->new($_) } @$_ ] };

declare 'MapStringAccessSelector',
    as HashRef[AccessSelector()];

declare 'Options',
    as InstanceOf['Google::Cloud::Asset::V1::AssetService::IamPolicyAnalysisQuery::Options'];

coerce 'Options',
    from HashRef, via { 'Google::Cloud::Asset::V1::AssetService::IamPolicyAnalysisQuery::Options'->new($_) };

declare 'RepeatedOptions',
    as ArrayRef[Options()];

coerce 'RepeatedOptions',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Asset::V1::AssetService::IamPolicyAnalysisQuery::Options'->new($_) } @$_ ] };

declare 'MapStringOptions',
    as HashRef[Options()];

declare 'ConditionContext',
    as InstanceOf['Google::Cloud::Asset::V1::AssetService::IamPolicyAnalysisQuery::ConditionContext'];

coerce 'ConditionContext',
    from HashRef, via { 'Google::Cloud::Asset::V1::AssetService::IamPolicyAnalysisQuery::ConditionContext'->new($_) };

declare 'RepeatedConditionContext',
    as ArrayRef[ConditionContext()];

coerce 'RepeatedConditionContext',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Asset::V1::AssetService::IamPolicyAnalysisQuery::ConditionContext'->new($_) } @$_ ] };

declare 'MapStringConditionContext',
    as HashRef[ConditionContext()];

declare 'AnalyzeIamPolicyRequest',
    as InstanceOf['Google::Cloud::Asset::V1::AssetService::AnalyzeIamPolicyRequest'];

coerce 'AnalyzeIamPolicyRequest',
    from HashRef, via { 'Google::Cloud::Asset::V1::AssetService::AnalyzeIamPolicyRequest'->new($_) };

declare 'RepeatedAnalyzeIamPolicyRequest',
    as ArrayRef[AnalyzeIamPolicyRequest()];

coerce 'RepeatedAnalyzeIamPolicyRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Asset::V1::AssetService::AnalyzeIamPolicyRequest'->new($_) } @$_ ] };

declare 'MapStringAnalyzeIamPolicyRequest',
    as HashRef[AnalyzeIamPolicyRequest()];

declare 'AnalyzeIamPolicyResponse',
    as InstanceOf['Google::Cloud::Asset::V1::AssetService::AnalyzeIamPolicyResponse'];

coerce 'AnalyzeIamPolicyResponse',
    from HashRef, via { 'Google::Cloud::Asset::V1::AssetService::AnalyzeIamPolicyResponse'->new($_) };

declare 'RepeatedAnalyzeIamPolicyResponse',
    as ArrayRef[AnalyzeIamPolicyResponse()];

coerce 'RepeatedAnalyzeIamPolicyResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Asset::V1::AssetService::AnalyzeIamPolicyResponse'->new($_) } @$_ ] };

declare 'MapStringAnalyzeIamPolicyResponse',
    as HashRef[AnalyzeIamPolicyResponse()];

declare 'IamPolicyAnalysis',
    as InstanceOf['Google::Cloud::Asset::V1::AssetService::AnalyzeIamPolicyResponse::IamPolicyAnalysis'];

coerce 'IamPolicyAnalysis',
    from HashRef, via { 'Google::Cloud::Asset::V1::AssetService::AnalyzeIamPolicyResponse::IamPolicyAnalysis'->new($_) };

declare 'RepeatedIamPolicyAnalysis',
    as ArrayRef[IamPolicyAnalysis()];

coerce 'RepeatedIamPolicyAnalysis',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Asset::V1::AssetService::AnalyzeIamPolicyResponse::IamPolicyAnalysis'->new($_) } @$_ ] };

declare 'MapStringIamPolicyAnalysis',
    as HashRef[IamPolicyAnalysis()];

declare 'IamPolicyAnalysisOutputConfig',
    as InstanceOf['Google::Cloud::Asset::V1::AssetService::IamPolicyAnalysisOutputConfig'];

coerce 'IamPolicyAnalysisOutputConfig',
    from HashRef, via { 'Google::Cloud::Asset::V1::AssetService::IamPolicyAnalysisOutputConfig'->new($_) };

declare 'RepeatedIamPolicyAnalysisOutputConfig',
    as ArrayRef[IamPolicyAnalysisOutputConfig()];

coerce 'RepeatedIamPolicyAnalysisOutputConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Asset::V1::AssetService::IamPolicyAnalysisOutputConfig'->new($_) } @$_ ] };

declare 'MapStringIamPolicyAnalysisOutputConfig',
    as HashRef[IamPolicyAnalysisOutputConfig()];

declare 'GcsDestination',
    as InstanceOf['Google::Cloud::Asset::V1::AssetService::IamPolicyAnalysisOutputConfig::GcsDestination'];

coerce 'GcsDestination',
    from HashRef, via { 'Google::Cloud::Asset::V1::AssetService::IamPolicyAnalysisOutputConfig::GcsDestination'->new($_) };

declare 'RepeatedGcsDestination',
    as ArrayRef[GcsDestination()];

coerce 'RepeatedGcsDestination',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Asset::V1::AssetService::IamPolicyAnalysisOutputConfig::GcsDestination'->new($_) } @$_ ] };

declare 'MapStringGcsDestination',
    as HashRef[GcsDestination()];

declare 'BigQueryDestination',
    as InstanceOf['Google::Cloud::Asset::V1::AssetService::IamPolicyAnalysisOutputConfig::BigQueryDestination'];

coerce 'BigQueryDestination',
    from HashRef, via { 'Google::Cloud::Asset::V1::AssetService::IamPolicyAnalysisOutputConfig::BigQueryDestination'->new($_) };

declare 'RepeatedBigQueryDestination',
    as ArrayRef[BigQueryDestination()];

coerce 'RepeatedBigQueryDestination',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Asset::V1::AssetService::IamPolicyAnalysisOutputConfig::BigQueryDestination'->new($_) } @$_ ] };

declare 'MapStringBigQueryDestination',
    as HashRef[BigQueryDestination()];

declare 'PartitionKey',
    as (Int | Str);

declare 'AnalyzeIamPolicyLongrunningRequest',
    as InstanceOf['Google::Cloud::Asset::V1::AssetService::AnalyzeIamPolicyLongrunningRequest'];

coerce 'AnalyzeIamPolicyLongrunningRequest',
    from HashRef, via { 'Google::Cloud::Asset::V1::AssetService::AnalyzeIamPolicyLongrunningRequest'->new($_) };

declare 'RepeatedAnalyzeIamPolicyLongrunningRequest',
    as ArrayRef[AnalyzeIamPolicyLongrunningRequest()];

coerce 'RepeatedAnalyzeIamPolicyLongrunningRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Asset::V1::AssetService::AnalyzeIamPolicyLongrunningRequest'->new($_) } @$_ ] };

declare 'MapStringAnalyzeIamPolicyLongrunningRequest',
    as HashRef[AnalyzeIamPolicyLongrunningRequest()];

declare 'AnalyzeIamPolicyLongrunningResponse',
    as InstanceOf['Google::Cloud::Asset::V1::AssetService::AnalyzeIamPolicyLongrunningResponse'];

coerce 'AnalyzeIamPolicyLongrunningResponse',
    from HashRef, via { 'Google::Cloud::Asset::V1::AssetService::AnalyzeIamPolicyLongrunningResponse'->new($_) };

declare 'RepeatedAnalyzeIamPolicyLongrunningResponse',
    as ArrayRef[AnalyzeIamPolicyLongrunningResponse()];

coerce 'RepeatedAnalyzeIamPolicyLongrunningResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Asset::V1::AssetService::AnalyzeIamPolicyLongrunningResponse'->new($_) } @$_ ] };

declare 'MapStringAnalyzeIamPolicyLongrunningResponse',
    as HashRef[AnalyzeIamPolicyLongrunningResponse()];

declare 'SavedQuery',
    as InstanceOf['Google::Cloud::Asset::V1::AssetService::SavedQuery'];

coerce 'SavedQuery',
    from HashRef, via { 'Google::Cloud::Asset::V1::AssetService::SavedQuery'->new($_) };

declare 'RepeatedSavedQuery',
    as ArrayRef[SavedQuery()];

coerce 'RepeatedSavedQuery',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Asset::V1::AssetService::SavedQuery'->new($_) } @$_ ] };

declare 'MapStringSavedQuery',
    as HashRef[SavedQuery()];

declare 'QueryContent',
    as InstanceOf['Google::Cloud::Asset::V1::AssetService::SavedQuery::QueryContent'];

coerce 'QueryContent',
    from HashRef, via { 'Google::Cloud::Asset::V1::AssetService::SavedQuery::QueryContent'->new($_) };

declare 'RepeatedQueryContent',
    as ArrayRef[QueryContent()];

coerce 'RepeatedQueryContent',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Asset::V1::AssetService::SavedQuery::QueryContent'->new($_) } @$_ ] };

declare 'MapStringQueryContent',
    as HashRef[QueryContent()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Asset::V1::AssetService::SavedQuery::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Asset::V1::AssetService::SavedQuery::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Asset::V1::AssetService::SavedQuery::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'CreateSavedQueryRequest',
    as InstanceOf['Google::Cloud::Asset::V1::AssetService::CreateSavedQueryRequest'];

coerce 'CreateSavedQueryRequest',
    from HashRef, via { 'Google::Cloud::Asset::V1::AssetService::CreateSavedQueryRequest'->new($_) };

declare 'RepeatedCreateSavedQueryRequest',
    as ArrayRef[CreateSavedQueryRequest()];

coerce 'RepeatedCreateSavedQueryRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Asset::V1::AssetService::CreateSavedQueryRequest'->new($_) } @$_ ] };

declare 'MapStringCreateSavedQueryRequest',
    as HashRef[CreateSavedQueryRequest()];

declare 'GetSavedQueryRequest',
    as InstanceOf['Google::Cloud::Asset::V1::AssetService::GetSavedQueryRequest'];

coerce 'GetSavedQueryRequest',
    from HashRef, via { 'Google::Cloud::Asset::V1::AssetService::GetSavedQueryRequest'->new($_) };

declare 'RepeatedGetSavedQueryRequest',
    as ArrayRef[GetSavedQueryRequest()];

coerce 'RepeatedGetSavedQueryRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Asset::V1::AssetService::GetSavedQueryRequest'->new($_) } @$_ ] };

declare 'MapStringGetSavedQueryRequest',
    as HashRef[GetSavedQueryRequest()];

declare 'ListSavedQueriesRequest',
    as InstanceOf['Google::Cloud::Asset::V1::AssetService::ListSavedQueriesRequest'];

coerce 'ListSavedQueriesRequest',
    from HashRef, via { 'Google::Cloud::Asset::V1::AssetService::ListSavedQueriesRequest'->new($_) };

declare 'RepeatedListSavedQueriesRequest',
    as ArrayRef[ListSavedQueriesRequest()];

coerce 'RepeatedListSavedQueriesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Asset::V1::AssetService::ListSavedQueriesRequest'->new($_) } @$_ ] };

declare 'MapStringListSavedQueriesRequest',
    as HashRef[ListSavedQueriesRequest()];

declare 'ListSavedQueriesResponse',
    as InstanceOf['Google::Cloud::Asset::V1::AssetService::ListSavedQueriesResponse'];

coerce 'ListSavedQueriesResponse',
    from HashRef, via { 'Google::Cloud::Asset::V1::AssetService::ListSavedQueriesResponse'->new($_) };

declare 'RepeatedListSavedQueriesResponse',
    as ArrayRef[ListSavedQueriesResponse()];

coerce 'RepeatedListSavedQueriesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Asset::V1::AssetService::ListSavedQueriesResponse'->new($_) } @$_ ] };

declare 'MapStringListSavedQueriesResponse',
    as HashRef[ListSavedQueriesResponse()];

declare 'UpdateSavedQueryRequest',
    as InstanceOf['Google::Cloud::Asset::V1::AssetService::UpdateSavedQueryRequest'];

coerce 'UpdateSavedQueryRequest',
    from HashRef, via { 'Google::Cloud::Asset::V1::AssetService::UpdateSavedQueryRequest'->new($_) };

declare 'RepeatedUpdateSavedQueryRequest',
    as ArrayRef[UpdateSavedQueryRequest()];

coerce 'RepeatedUpdateSavedQueryRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Asset::V1::AssetService::UpdateSavedQueryRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateSavedQueryRequest',
    as HashRef[UpdateSavedQueryRequest()];

declare 'DeleteSavedQueryRequest',
    as InstanceOf['Google::Cloud::Asset::V1::AssetService::DeleteSavedQueryRequest'];

coerce 'DeleteSavedQueryRequest',
    from HashRef, via { 'Google::Cloud::Asset::V1::AssetService::DeleteSavedQueryRequest'->new($_) };

declare 'RepeatedDeleteSavedQueryRequest',
    as ArrayRef[DeleteSavedQueryRequest()];

coerce 'RepeatedDeleteSavedQueryRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Asset::V1::AssetService::DeleteSavedQueryRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteSavedQueryRequest',
    as HashRef[DeleteSavedQueryRequest()];

declare 'AnalyzeMoveRequest',
    as InstanceOf['Google::Cloud::Asset::V1::AssetService::AnalyzeMoveRequest'];

coerce 'AnalyzeMoveRequest',
    from HashRef, via { 'Google::Cloud::Asset::V1::AssetService::AnalyzeMoveRequest'->new($_) };

declare 'RepeatedAnalyzeMoveRequest',
    as ArrayRef[AnalyzeMoveRequest()];

coerce 'RepeatedAnalyzeMoveRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Asset::V1::AssetService::AnalyzeMoveRequest'->new($_) } @$_ ] };

declare 'MapStringAnalyzeMoveRequest',
    as HashRef[AnalyzeMoveRequest()];

declare 'AnalysisView',
    as (Int | Str);

declare 'AnalyzeMoveResponse',
    as InstanceOf['Google::Cloud::Asset::V1::AssetService::AnalyzeMoveResponse'];

coerce 'AnalyzeMoveResponse',
    from HashRef, via { 'Google::Cloud::Asset::V1::AssetService::AnalyzeMoveResponse'->new($_) };

declare 'RepeatedAnalyzeMoveResponse',
    as ArrayRef[AnalyzeMoveResponse()];

coerce 'RepeatedAnalyzeMoveResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Asset::V1::AssetService::AnalyzeMoveResponse'->new($_) } @$_ ] };

declare 'MapStringAnalyzeMoveResponse',
    as HashRef[AnalyzeMoveResponse()];

declare 'MoveAnalysis',
    as InstanceOf['Google::Cloud::Asset::V1::AssetService::MoveAnalysis'];

coerce 'MoveAnalysis',
    from HashRef, via { 'Google::Cloud::Asset::V1::AssetService::MoveAnalysis'->new($_) };

declare 'RepeatedMoveAnalysis',
    as ArrayRef[MoveAnalysis()];

coerce 'RepeatedMoveAnalysis',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Asset::V1::AssetService::MoveAnalysis'->new($_) } @$_ ] };

declare 'MapStringMoveAnalysis',
    as HashRef[MoveAnalysis()];

declare 'MoveAnalysisResult',
    as InstanceOf['Google::Cloud::Asset::V1::AssetService::MoveAnalysisResult'];

coerce 'MoveAnalysisResult',
    from HashRef, via { 'Google::Cloud::Asset::V1::AssetService::MoveAnalysisResult'->new($_) };

declare 'RepeatedMoveAnalysisResult',
    as ArrayRef[MoveAnalysisResult()];

coerce 'RepeatedMoveAnalysisResult',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Asset::V1::AssetService::MoveAnalysisResult'->new($_) } @$_ ] };

declare 'MapStringMoveAnalysisResult',
    as HashRef[MoveAnalysisResult()];

declare 'MoveImpact',
    as InstanceOf['Google::Cloud::Asset::V1::AssetService::MoveImpact'];

coerce 'MoveImpact',
    from HashRef, via { 'Google::Cloud::Asset::V1::AssetService::MoveImpact'->new($_) };

declare 'RepeatedMoveImpact',
    as ArrayRef[MoveImpact()];

coerce 'RepeatedMoveImpact',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Asset::V1::AssetService::MoveImpact'->new($_) } @$_ ] };

declare 'MapStringMoveImpact',
    as HashRef[MoveImpact()];

declare 'QueryAssetsOutputConfig',
    as InstanceOf['Google::Cloud::Asset::V1::AssetService::QueryAssetsOutputConfig'];

coerce 'QueryAssetsOutputConfig',
    from HashRef, via { 'Google::Cloud::Asset::V1::AssetService::QueryAssetsOutputConfig'->new($_) };

declare 'RepeatedQueryAssetsOutputConfig',
    as ArrayRef[QueryAssetsOutputConfig()];

coerce 'RepeatedQueryAssetsOutputConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Asset::V1::AssetService::QueryAssetsOutputConfig'->new($_) } @$_ ] };

declare 'MapStringQueryAssetsOutputConfig',
    as HashRef[QueryAssetsOutputConfig()];

declare 'BigQueryDestination',
    as InstanceOf['Google::Cloud::Asset::V1::AssetService::QueryAssetsOutputConfig::BigQueryDestination'];

coerce 'BigQueryDestination',
    from HashRef, via { 'Google::Cloud::Asset::V1::AssetService::QueryAssetsOutputConfig::BigQueryDestination'->new($_) };

declare 'RepeatedBigQueryDestination',
    as ArrayRef[BigQueryDestination()];

coerce 'RepeatedBigQueryDestination',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Asset::V1::AssetService::QueryAssetsOutputConfig::BigQueryDestination'->new($_) } @$_ ] };

declare 'MapStringBigQueryDestination',
    as HashRef[BigQueryDestination()];

declare 'QueryAssetsRequest',
    as InstanceOf['Google::Cloud::Asset::V1::AssetService::QueryAssetsRequest'];

coerce 'QueryAssetsRequest',
    from HashRef, via { 'Google::Cloud::Asset::V1::AssetService::QueryAssetsRequest'->new($_) };

declare 'RepeatedQueryAssetsRequest',
    as ArrayRef[QueryAssetsRequest()];

coerce 'RepeatedQueryAssetsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Asset::V1::AssetService::QueryAssetsRequest'->new($_) } @$_ ] };

declare 'MapStringQueryAssetsRequest',
    as HashRef[QueryAssetsRequest()];

declare 'QueryAssetsResponse',
    as InstanceOf['Google::Cloud::Asset::V1::AssetService::QueryAssetsResponse'];

coerce 'QueryAssetsResponse',
    from HashRef, via { 'Google::Cloud::Asset::V1::AssetService::QueryAssetsResponse'->new($_) };

declare 'RepeatedQueryAssetsResponse',
    as ArrayRef[QueryAssetsResponse()];

coerce 'RepeatedQueryAssetsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Asset::V1::AssetService::QueryAssetsResponse'->new($_) } @$_ ] };

declare 'MapStringQueryAssetsResponse',
    as HashRef[QueryAssetsResponse()];

declare 'QueryResult',
    as InstanceOf['Google::Cloud::Asset::V1::AssetService::QueryResult'];

coerce 'QueryResult',
    from HashRef, via { 'Google::Cloud::Asset::V1::AssetService::QueryResult'->new($_) };

declare 'RepeatedQueryResult',
    as ArrayRef[QueryResult()];

coerce 'RepeatedQueryResult',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Asset::V1::AssetService::QueryResult'->new($_) } @$_ ] };

declare 'MapStringQueryResult',
    as HashRef[QueryResult()];

declare 'TableSchema',
    as InstanceOf['Google::Cloud::Asset::V1::AssetService::TableSchema'];

coerce 'TableSchema',
    from HashRef, via { 'Google::Cloud::Asset::V1::AssetService::TableSchema'->new($_) };

declare 'RepeatedTableSchema',
    as ArrayRef[TableSchema()];

coerce 'RepeatedTableSchema',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Asset::V1::AssetService::TableSchema'->new($_) } @$_ ] };

declare 'MapStringTableSchema',
    as HashRef[TableSchema()];

declare 'TableFieldSchema',
    as InstanceOf['Google::Cloud::Asset::V1::AssetService::TableFieldSchema'];

coerce 'TableFieldSchema',
    from HashRef, via { 'Google::Cloud::Asset::V1::AssetService::TableFieldSchema'->new($_) };

declare 'RepeatedTableFieldSchema',
    as ArrayRef[TableFieldSchema()];

coerce 'RepeatedTableFieldSchema',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Asset::V1::AssetService::TableFieldSchema'->new($_) } @$_ ] };

declare 'MapStringTableFieldSchema',
    as HashRef[TableFieldSchema()];

declare 'BatchGetEffectiveIamPoliciesRequest',
    as InstanceOf['Google::Cloud::Asset::V1::AssetService::BatchGetEffectiveIamPoliciesRequest'];

coerce 'BatchGetEffectiveIamPoliciesRequest',
    from HashRef, via { 'Google::Cloud::Asset::V1::AssetService::BatchGetEffectiveIamPoliciesRequest'->new($_) };

declare 'RepeatedBatchGetEffectiveIamPoliciesRequest',
    as ArrayRef[BatchGetEffectiveIamPoliciesRequest()];

coerce 'RepeatedBatchGetEffectiveIamPoliciesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Asset::V1::AssetService::BatchGetEffectiveIamPoliciesRequest'->new($_) } @$_ ] };

declare 'MapStringBatchGetEffectiveIamPoliciesRequest',
    as HashRef[BatchGetEffectiveIamPoliciesRequest()];

declare 'BatchGetEffectiveIamPoliciesResponse',
    as InstanceOf['Google::Cloud::Asset::V1::AssetService::BatchGetEffectiveIamPoliciesResponse'];

coerce 'BatchGetEffectiveIamPoliciesResponse',
    from HashRef, via { 'Google::Cloud::Asset::V1::AssetService::BatchGetEffectiveIamPoliciesResponse'->new($_) };

declare 'RepeatedBatchGetEffectiveIamPoliciesResponse',
    as ArrayRef[BatchGetEffectiveIamPoliciesResponse()];

coerce 'RepeatedBatchGetEffectiveIamPoliciesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Asset::V1::AssetService::BatchGetEffectiveIamPoliciesResponse'->new($_) } @$_ ] };

declare 'MapStringBatchGetEffectiveIamPoliciesResponse',
    as HashRef[BatchGetEffectiveIamPoliciesResponse()];

declare 'EffectiveIamPolicy',
    as InstanceOf['Google::Cloud::Asset::V1::AssetService::BatchGetEffectiveIamPoliciesResponse::EffectiveIamPolicy'];

coerce 'EffectiveIamPolicy',
    from HashRef, via { 'Google::Cloud::Asset::V1::AssetService::BatchGetEffectiveIamPoliciesResponse::EffectiveIamPolicy'->new($_) };

declare 'RepeatedEffectiveIamPolicy',
    as ArrayRef[EffectiveIamPolicy()];

coerce 'RepeatedEffectiveIamPolicy',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Asset::V1::AssetService::BatchGetEffectiveIamPoliciesResponse::EffectiveIamPolicy'->new($_) } @$_ ] };

declare 'MapStringEffectiveIamPolicy',
    as HashRef[EffectiveIamPolicy()];

declare 'PolicyInfo',
    as InstanceOf['Google::Cloud::Asset::V1::AssetService::BatchGetEffectiveIamPoliciesResponse::EffectiveIamPolicy::PolicyInfo'];

coerce 'PolicyInfo',
    from HashRef, via { 'Google::Cloud::Asset::V1::AssetService::BatchGetEffectiveIamPoliciesResponse::EffectiveIamPolicy::PolicyInfo'->new($_) };

declare 'RepeatedPolicyInfo',
    as ArrayRef[PolicyInfo()];

coerce 'RepeatedPolicyInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Asset::V1::AssetService::BatchGetEffectiveIamPoliciesResponse::EffectiveIamPolicy::PolicyInfo'->new($_) } @$_ ] };

declare 'MapStringPolicyInfo',
    as HashRef[PolicyInfo()];

declare 'AnalyzerOrgPolicy',
    as InstanceOf['Google::Cloud::Asset::V1::AssetService::AnalyzerOrgPolicy'];

coerce 'AnalyzerOrgPolicy',
    from HashRef, via { 'Google::Cloud::Asset::V1::AssetService::AnalyzerOrgPolicy'->new($_) };

declare 'RepeatedAnalyzerOrgPolicy',
    as ArrayRef[AnalyzerOrgPolicy()];

coerce 'RepeatedAnalyzerOrgPolicy',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Asset::V1::AssetService::AnalyzerOrgPolicy'->new($_) } @$_ ] };

declare 'MapStringAnalyzerOrgPolicy',
    as HashRef[AnalyzerOrgPolicy()];

declare 'Rule',
    as InstanceOf['Google::Cloud::Asset::V1::AssetService::AnalyzerOrgPolicy::Rule'];

coerce 'Rule',
    from HashRef, via { 'Google::Cloud::Asset::V1::AssetService::AnalyzerOrgPolicy::Rule'->new($_) };

declare 'RepeatedRule',
    as ArrayRef[Rule()];

coerce 'RepeatedRule',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Asset::V1::AssetService::AnalyzerOrgPolicy::Rule'->new($_) } @$_ ] };

declare 'MapStringRule',
    as HashRef[Rule()];

declare 'StringValues',
    as InstanceOf['Google::Cloud::Asset::V1::AssetService::AnalyzerOrgPolicy::Rule::StringValues'];

coerce 'StringValues',
    from HashRef, via { 'Google::Cloud::Asset::V1::AssetService::AnalyzerOrgPolicy::Rule::StringValues'->new($_) };

declare 'RepeatedStringValues',
    as ArrayRef[StringValues()];

coerce 'RepeatedStringValues',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Asset::V1::AssetService::AnalyzerOrgPolicy::Rule::StringValues'->new($_) } @$_ ] };

declare 'MapStringStringValues',
    as HashRef[StringValues()];

declare 'AnalyzerOrgPolicyConstraint',
    as InstanceOf['Google::Cloud::Asset::V1::AssetService::AnalyzerOrgPolicyConstraint'];

coerce 'AnalyzerOrgPolicyConstraint',
    from HashRef, via { 'Google::Cloud::Asset::V1::AssetService::AnalyzerOrgPolicyConstraint'->new($_) };

declare 'RepeatedAnalyzerOrgPolicyConstraint',
    as ArrayRef[AnalyzerOrgPolicyConstraint()];

coerce 'RepeatedAnalyzerOrgPolicyConstraint',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Asset::V1::AssetService::AnalyzerOrgPolicyConstraint'->new($_) } @$_ ] };

declare 'MapStringAnalyzerOrgPolicyConstraint',
    as HashRef[AnalyzerOrgPolicyConstraint()];

declare 'Constraint',
    as InstanceOf['Google::Cloud::Asset::V1::AssetService::AnalyzerOrgPolicyConstraint::Constraint'];

coerce 'Constraint',
    from HashRef, via { 'Google::Cloud::Asset::V1::AssetService::AnalyzerOrgPolicyConstraint::Constraint'->new($_) };

declare 'RepeatedConstraint',
    as ArrayRef[Constraint()];

coerce 'RepeatedConstraint',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Asset::V1::AssetService::AnalyzerOrgPolicyConstraint::Constraint'->new($_) } @$_ ] };

declare 'MapStringConstraint',
    as HashRef[Constraint()];

declare 'ConstraintDefault',
    as (Int | Str);

declare 'ListConstraint',
    as InstanceOf['Google::Cloud::Asset::V1::AssetService::AnalyzerOrgPolicyConstraint::Constraint::ListConstraint'];

coerce 'ListConstraint',
    from HashRef, via { 'Google::Cloud::Asset::V1::AssetService::AnalyzerOrgPolicyConstraint::Constraint::ListConstraint'->new($_) };

declare 'RepeatedListConstraint',
    as ArrayRef[ListConstraint()];

coerce 'RepeatedListConstraint',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Asset::V1::AssetService::AnalyzerOrgPolicyConstraint::Constraint::ListConstraint'->new($_) } @$_ ] };

declare 'MapStringListConstraint',
    as HashRef[ListConstraint()];

declare 'BooleanConstraint',
    as InstanceOf['Google::Cloud::Asset::V1::AssetService::AnalyzerOrgPolicyConstraint::Constraint::BooleanConstraint'];

coerce 'BooleanConstraint',
    from HashRef, via { 'Google::Cloud::Asset::V1::AssetService::AnalyzerOrgPolicyConstraint::Constraint::BooleanConstraint'->new($_) };

declare 'RepeatedBooleanConstraint',
    as ArrayRef[BooleanConstraint()];

coerce 'RepeatedBooleanConstraint',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Asset::V1::AssetService::AnalyzerOrgPolicyConstraint::Constraint::BooleanConstraint'->new($_) } @$_ ] };

declare 'MapStringBooleanConstraint',
    as HashRef[BooleanConstraint()];

declare 'CustomConstraint',
    as InstanceOf['Google::Cloud::Asset::V1::AssetService::AnalyzerOrgPolicyConstraint::CustomConstraint'];

coerce 'CustomConstraint',
    from HashRef, via { 'Google::Cloud::Asset::V1::AssetService::AnalyzerOrgPolicyConstraint::CustomConstraint'->new($_) };

declare 'RepeatedCustomConstraint',
    as ArrayRef[CustomConstraint()];

coerce 'RepeatedCustomConstraint',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Asset::V1::AssetService::AnalyzerOrgPolicyConstraint::CustomConstraint'->new($_) } @$_ ] };

declare 'MapStringCustomConstraint',
    as HashRef[CustomConstraint()];

declare 'MethodType',
    as (Int | Str);

declare 'ActionType',
    as (Int | Str);

declare 'AnalyzeOrgPoliciesRequest',
    as InstanceOf['Google::Cloud::Asset::V1::AssetService::AnalyzeOrgPoliciesRequest'];

coerce 'AnalyzeOrgPoliciesRequest',
    from HashRef, via { 'Google::Cloud::Asset::V1::AssetService::AnalyzeOrgPoliciesRequest'->new($_) };

declare 'RepeatedAnalyzeOrgPoliciesRequest',
    as ArrayRef[AnalyzeOrgPoliciesRequest()];

coerce 'RepeatedAnalyzeOrgPoliciesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Asset::V1::AssetService::AnalyzeOrgPoliciesRequest'->new($_) } @$_ ] };

declare 'MapStringAnalyzeOrgPoliciesRequest',
    as HashRef[AnalyzeOrgPoliciesRequest()];

declare 'AnalyzeOrgPoliciesResponse',
    as InstanceOf['Google::Cloud::Asset::V1::AssetService::AnalyzeOrgPoliciesResponse'];

coerce 'AnalyzeOrgPoliciesResponse',
    from HashRef, via { 'Google::Cloud::Asset::V1::AssetService::AnalyzeOrgPoliciesResponse'->new($_) };

declare 'RepeatedAnalyzeOrgPoliciesResponse',
    as ArrayRef[AnalyzeOrgPoliciesResponse()];

coerce 'RepeatedAnalyzeOrgPoliciesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Asset::V1::AssetService::AnalyzeOrgPoliciesResponse'->new($_) } @$_ ] };

declare 'MapStringAnalyzeOrgPoliciesResponse',
    as HashRef[AnalyzeOrgPoliciesResponse()];

declare 'OrgPolicyResult',
    as InstanceOf['Google::Cloud::Asset::V1::AssetService::AnalyzeOrgPoliciesResponse::OrgPolicyResult'];

coerce 'OrgPolicyResult',
    from HashRef, via { 'Google::Cloud::Asset::V1::AssetService::AnalyzeOrgPoliciesResponse::OrgPolicyResult'->new($_) };

declare 'RepeatedOrgPolicyResult',
    as ArrayRef[OrgPolicyResult()];

coerce 'RepeatedOrgPolicyResult',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Asset::V1::AssetService::AnalyzeOrgPoliciesResponse::OrgPolicyResult'->new($_) } @$_ ] };

declare 'MapStringOrgPolicyResult',
    as HashRef[OrgPolicyResult()];

declare 'AnalyzeOrgPolicyGovernedContainersRequest',
    as InstanceOf['Google::Cloud::Asset::V1::AssetService::AnalyzeOrgPolicyGovernedContainersRequest'];

coerce 'AnalyzeOrgPolicyGovernedContainersRequest',
    from HashRef, via { 'Google::Cloud::Asset::V1::AssetService::AnalyzeOrgPolicyGovernedContainersRequest'->new($_) };

declare 'RepeatedAnalyzeOrgPolicyGovernedContainersRequest',
    as ArrayRef[AnalyzeOrgPolicyGovernedContainersRequest()];

coerce 'RepeatedAnalyzeOrgPolicyGovernedContainersRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Asset::V1::AssetService::AnalyzeOrgPolicyGovernedContainersRequest'->new($_) } @$_ ] };

declare 'MapStringAnalyzeOrgPolicyGovernedContainersRequest',
    as HashRef[AnalyzeOrgPolicyGovernedContainersRequest()];

declare 'AnalyzeOrgPolicyGovernedContainersResponse',
    as InstanceOf['Google::Cloud::Asset::V1::AssetService::AnalyzeOrgPolicyGovernedContainersResponse'];

coerce 'AnalyzeOrgPolicyGovernedContainersResponse',
    from HashRef, via { 'Google::Cloud::Asset::V1::AssetService::AnalyzeOrgPolicyGovernedContainersResponse'->new($_) };

declare 'RepeatedAnalyzeOrgPolicyGovernedContainersResponse',
    as ArrayRef[AnalyzeOrgPolicyGovernedContainersResponse()];

coerce 'RepeatedAnalyzeOrgPolicyGovernedContainersResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Asset::V1::AssetService::AnalyzeOrgPolicyGovernedContainersResponse'->new($_) } @$_ ] };

declare 'MapStringAnalyzeOrgPolicyGovernedContainersResponse',
    as HashRef[AnalyzeOrgPolicyGovernedContainersResponse()];

declare 'GovernedContainer',
    as InstanceOf['Google::Cloud::Asset::V1::AssetService::AnalyzeOrgPolicyGovernedContainersResponse::GovernedContainer'];

coerce 'GovernedContainer',
    from HashRef, via { 'Google::Cloud::Asset::V1::AssetService::AnalyzeOrgPolicyGovernedContainersResponse::GovernedContainer'->new($_) };

declare 'RepeatedGovernedContainer',
    as ArrayRef[GovernedContainer()];

coerce 'RepeatedGovernedContainer',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Asset::V1::AssetService::AnalyzeOrgPolicyGovernedContainersResponse::GovernedContainer'->new($_) } @$_ ] };

declare 'MapStringGovernedContainer',
    as HashRef[GovernedContainer()];

declare 'AnalyzeOrgPolicyGovernedAssetsRequest',
    as InstanceOf['Google::Cloud::Asset::V1::AssetService::AnalyzeOrgPolicyGovernedAssetsRequest'];

coerce 'AnalyzeOrgPolicyGovernedAssetsRequest',
    from HashRef, via { 'Google::Cloud::Asset::V1::AssetService::AnalyzeOrgPolicyGovernedAssetsRequest'->new($_) };

declare 'RepeatedAnalyzeOrgPolicyGovernedAssetsRequest',
    as ArrayRef[AnalyzeOrgPolicyGovernedAssetsRequest()];

coerce 'RepeatedAnalyzeOrgPolicyGovernedAssetsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Asset::V1::AssetService::AnalyzeOrgPolicyGovernedAssetsRequest'->new($_) } @$_ ] };

declare 'MapStringAnalyzeOrgPolicyGovernedAssetsRequest',
    as HashRef[AnalyzeOrgPolicyGovernedAssetsRequest()];

declare 'AnalyzeOrgPolicyGovernedAssetsResponse',
    as InstanceOf['Google::Cloud::Asset::V1::AssetService::AnalyzeOrgPolicyGovernedAssetsResponse'];

coerce 'AnalyzeOrgPolicyGovernedAssetsResponse',
    from HashRef, via { 'Google::Cloud::Asset::V1::AssetService::AnalyzeOrgPolicyGovernedAssetsResponse'->new($_) };

declare 'RepeatedAnalyzeOrgPolicyGovernedAssetsResponse',
    as ArrayRef[AnalyzeOrgPolicyGovernedAssetsResponse()];

coerce 'RepeatedAnalyzeOrgPolicyGovernedAssetsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Asset::V1::AssetService::AnalyzeOrgPolicyGovernedAssetsResponse'->new($_) } @$_ ] };

declare 'MapStringAnalyzeOrgPolicyGovernedAssetsResponse',
    as HashRef[AnalyzeOrgPolicyGovernedAssetsResponse()];

declare 'GovernedResource',
    as InstanceOf['Google::Cloud::Asset::V1::AssetService::AnalyzeOrgPolicyGovernedAssetsResponse::GovernedResource'];

coerce 'GovernedResource',
    from HashRef, via { 'Google::Cloud::Asset::V1::AssetService::AnalyzeOrgPolicyGovernedAssetsResponse::GovernedResource'->new($_) };

declare 'RepeatedGovernedResource',
    as ArrayRef[GovernedResource()];

coerce 'RepeatedGovernedResource',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Asset::V1::AssetService::AnalyzeOrgPolicyGovernedAssetsResponse::GovernedResource'->new($_) } @$_ ] };

declare 'MapStringGovernedResource',
    as HashRef[GovernedResource()];

declare 'GovernedIamPolicy',
    as InstanceOf['Google::Cloud::Asset::V1::AssetService::AnalyzeOrgPolicyGovernedAssetsResponse::GovernedIamPolicy'];

coerce 'GovernedIamPolicy',
    from HashRef, via { 'Google::Cloud::Asset::V1::AssetService::AnalyzeOrgPolicyGovernedAssetsResponse::GovernedIamPolicy'->new($_) };

declare 'RepeatedGovernedIamPolicy',
    as ArrayRef[GovernedIamPolicy()];

coerce 'RepeatedGovernedIamPolicy',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Asset::V1::AssetService::AnalyzeOrgPolicyGovernedAssetsResponse::GovernedIamPolicy'->new($_) } @$_ ] };

declare 'MapStringGovernedIamPolicy',
    as HashRef[GovernedIamPolicy()];

declare 'GovernedAsset',
    as InstanceOf['Google::Cloud::Asset::V1::AssetService::AnalyzeOrgPolicyGovernedAssetsResponse::GovernedAsset'];

coerce 'GovernedAsset',
    from HashRef, via { 'Google::Cloud::Asset::V1::AssetService::AnalyzeOrgPolicyGovernedAssetsResponse::GovernedAsset'->new($_) };

declare 'RepeatedGovernedAsset',
    as ArrayRef[GovernedAsset()];

coerce 'RepeatedGovernedAsset',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Asset::V1::AssetService::AnalyzeOrgPolicyGovernedAssetsResponse::GovernedAsset'->new($_) } @$_ ] };

declare 'MapStringGovernedAsset',
    as HashRef[GovernedAsset()];

1;

__END__

=head1 NAME

Google::Cloud::Asset::V1::AssetService::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
