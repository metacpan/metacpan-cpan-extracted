package Google::Cloud::Discoveryengine::V1alpha::SiteSearchEngineService::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'GetSiteSearchEngineRequest',
    as InstanceOf['Google::Cloud::Discoveryengine::V1alpha::SiteSearchEngineService::GetSiteSearchEngineRequest'];

coerce 'GetSiteSearchEngineRequest',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1alpha::SiteSearchEngineService::GetSiteSearchEngineRequest'->new($_) };

declare 'RepeatedGetSiteSearchEngineRequest',
    as ArrayRef[GetSiteSearchEngineRequest()];

coerce 'RepeatedGetSiteSearchEngineRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1alpha::SiteSearchEngineService::GetSiteSearchEngineRequest'->new($_) } @$_ ] };

declare 'MapStringGetSiteSearchEngineRequest',
    as HashRef[GetSiteSearchEngineRequest()];

declare 'CreateTargetSiteRequest',
    as InstanceOf['Google::Cloud::Discoveryengine::V1alpha::SiteSearchEngineService::CreateTargetSiteRequest'];

coerce 'CreateTargetSiteRequest',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1alpha::SiteSearchEngineService::CreateTargetSiteRequest'->new($_) };

declare 'RepeatedCreateTargetSiteRequest',
    as ArrayRef[CreateTargetSiteRequest()];

coerce 'RepeatedCreateTargetSiteRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1alpha::SiteSearchEngineService::CreateTargetSiteRequest'->new($_) } @$_ ] };

declare 'MapStringCreateTargetSiteRequest',
    as HashRef[CreateTargetSiteRequest()];

declare 'CreateTargetSiteMetadata',
    as InstanceOf['Google::Cloud::Discoveryengine::V1alpha::SiteSearchEngineService::CreateTargetSiteMetadata'];

coerce 'CreateTargetSiteMetadata',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1alpha::SiteSearchEngineService::CreateTargetSiteMetadata'->new($_) };

declare 'RepeatedCreateTargetSiteMetadata',
    as ArrayRef[CreateTargetSiteMetadata()];

coerce 'RepeatedCreateTargetSiteMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1alpha::SiteSearchEngineService::CreateTargetSiteMetadata'->new($_) } @$_ ] };

declare 'MapStringCreateTargetSiteMetadata',
    as HashRef[CreateTargetSiteMetadata()];

declare 'BatchCreateTargetSitesRequest',
    as InstanceOf['Google::Cloud::Discoveryengine::V1alpha::SiteSearchEngineService::BatchCreateTargetSitesRequest'];

coerce 'BatchCreateTargetSitesRequest',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1alpha::SiteSearchEngineService::BatchCreateTargetSitesRequest'->new($_) };

declare 'RepeatedBatchCreateTargetSitesRequest',
    as ArrayRef[BatchCreateTargetSitesRequest()];

coerce 'RepeatedBatchCreateTargetSitesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1alpha::SiteSearchEngineService::BatchCreateTargetSitesRequest'->new($_) } @$_ ] };

declare 'MapStringBatchCreateTargetSitesRequest',
    as HashRef[BatchCreateTargetSitesRequest()];

declare 'GetTargetSiteRequest',
    as InstanceOf['Google::Cloud::Discoveryengine::V1alpha::SiteSearchEngineService::GetTargetSiteRequest'];

coerce 'GetTargetSiteRequest',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1alpha::SiteSearchEngineService::GetTargetSiteRequest'->new($_) };

declare 'RepeatedGetTargetSiteRequest',
    as ArrayRef[GetTargetSiteRequest()];

coerce 'RepeatedGetTargetSiteRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1alpha::SiteSearchEngineService::GetTargetSiteRequest'->new($_) } @$_ ] };

declare 'MapStringGetTargetSiteRequest',
    as HashRef[GetTargetSiteRequest()];

declare 'UpdateTargetSiteRequest',
    as InstanceOf['Google::Cloud::Discoveryengine::V1alpha::SiteSearchEngineService::UpdateTargetSiteRequest'];

coerce 'UpdateTargetSiteRequest',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1alpha::SiteSearchEngineService::UpdateTargetSiteRequest'->new($_) };

declare 'RepeatedUpdateTargetSiteRequest',
    as ArrayRef[UpdateTargetSiteRequest()];

coerce 'RepeatedUpdateTargetSiteRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1alpha::SiteSearchEngineService::UpdateTargetSiteRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateTargetSiteRequest',
    as HashRef[UpdateTargetSiteRequest()];

declare 'UpdateTargetSiteMetadata',
    as InstanceOf['Google::Cloud::Discoveryengine::V1alpha::SiteSearchEngineService::UpdateTargetSiteMetadata'];

coerce 'UpdateTargetSiteMetadata',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1alpha::SiteSearchEngineService::UpdateTargetSiteMetadata'->new($_) };

declare 'RepeatedUpdateTargetSiteMetadata',
    as ArrayRef[UpdateTargetSiteMetadata()];

coerce 'RepeatedUpdateTargetSiteMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1alpha::SiteSearchEngineService::UpdateTargetSiteMetadata'->new($_) } @$_ ] };

declare 'MapStringUpdateTargetSiteMetadata',
    as HashRef[UpdateTargetSiteMetadata()];

declare 'DeleteTargetSiteRequest',
    as InstanceOf['Google::Cloud::Discoveryengine::V1alpha::SiteSearchEngineService::DeleteTargetSiteRequest'];

coerce 'DeleteTargetSiteRequest',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1alpha::SiteSearchEngineService::DeleteTargetSiteRequest'->new($_) };

declare 'RepeatedDeleteTargetSiteRequest',
    as ArrayRef[DeleteTargetSiteRequest()];

coerce 'RepeatedDeleteTargetSiteRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1alpha::SiteSearchEngineService::DeleteTargetSiteRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteTargetSiteRequest',
    as HashRef[DeleteTargetSiteRequest()];

declare 'DeleteTargetSiteMetadata',
    as InstanceOf['Google::Cloud::Discoveryengine::V1alpha::SiteSearchEngineService::DeleteTargetSiteMetadata'];

coerce 'DeleteTargetSiteMetadata',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1alpha::SiteSearchEngineService::DeleteTargetSiteMetadata'->new($_) };

declare 'RepeatedDeleteTargetSiteMetadata',
    as ArrayRef[DeleteTargetSiteMetadata()];

coerce 'RepeatedDeleteTargetSiteMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1alpha::SiteSearchEngineService::DeleteTargetSiteMetadata'->new($_) } @$_ ] };

declare 'MapStringDeleteTargetSiteMetadata',
    as HashRef[DeleteTargetSiteMetadata()];

declare 'ListTargetSitesRequest',
    as InstanceOf['Google::Cloud::Discoveryengine::V1alpha::SiteSearchEngineService::ListTargetSitesRequest'];

coerce 'ListTargetSitesRequest',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1alpha::SiteSearchEngineService::ListTargetSitesRequest'->new($_) };

declare 'RepeatedListTargetSitesRequest',
    as ArrayRef[ListTargetSitesRequest()];

coerce 'RepeatedListTargetSitesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1alpha::SiteSearchEngineService::ListTargetSitesRequest'->new($_) } @$_ ] };

declare 'MapStringListTargetSitesRequest',
    as HashRef[ListTargetSitesRequest()];

declare 'ListTargetSitesResponse',
    as InstanceOf['Google::Cloud::Discoveryengine::V1alpha::SiteSearchEngineService::ListTargetSitesResponse'];

coerce 'ListTargetSitesResponse',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1alpha::SiteSearchEngineService::ListTargetSitesResponse'->new($_) };

declare 'RepeatedListTargetSitesResponse',
    as ArrayRef[ListTargetSitesResponse()];

coerce 'RepeatedListTargetSitesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1alpha::SiteSearchEngineService::ListTargetSitesResponse'->new($_) } @$_ ] };

declare 'MapStringListTargetSitesResponse',
    as HashRef[ListTargetSitesResponse()];

declare 'BatchCreateTargetSiteMetadata',
    as InstanceOf['Google::Cloud::Discoveryengine::V1alpha::SiteSearchEngineService::BatchCreateTargetSiteMetadata'];

coerce 'BatchCreateTargetSiteMetadata',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1alpha::SiteSearchEngineService::BatchCreateTargetSiteMetadata'->new($_) };

declare 'RepeatedBatchCreateTargetSiteMetadata',
    as ArrayRef[BatchCreateTargetSiteMetadata()];

coerce 'RepeatedBatchCreateTargetSiteMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1alpha::SiteSearchEngineService::BatchCreateTargetSiteMetadata'->new($_) } @$_ ] };

declare 'MapStringBatchCreateTargetSiteMetadata',
    as HashRef[BatchCreateTargetSiteMetadata()];

declare 'BatchCreateTargetSitesResponse',
    as InstanceOf['Google::Cloud::Discoveryengine::V1alpha::SiteSearchEngineService::BatchCreateTargetSitesResponse'];

coerce 'BatchCreateTargetSitesResponse',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1alpha::SiteSearchEngineService::BatchCreateTargetSitesResponse'->new($_) };

declare 'RepeatedBatchCreateTargetSitesResponse',
    as ArrayRef[BatchCreateTargetSitesResponse()];

coerce 'RepeatedBatchCreateTargetSitesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1alpha::SiteSearchEngineService::BatchCreateTargetSitesResponse'->new($_) } @$_ ] };

declare 'MapStringBatchCreateTargetSitesResponse',
    as HashRef[BatchCreateTargetSitesResponse()];

declare 'EnableAdvancedSiteSearchRequest',
    as InstanceOf['Google::Cloud::Discoveryengine::V1alpha::SiteSearchEngineService::EnableAdvancedSiteSearchRequest'];

coerce 'EnableAdvancedSiteSearchRequest',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1alpha::SiteSearchEngineService::EnableAdvancedSiteSearchRequest'->new($_) };

declare 'RepeatedEnableAdvancedSiteSearchRequest',
    as ArrayRef[EnableAdvancedSiteSearchRequest()];

coerce 'RepeatedEnableAdvancedSiteSearchRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1alpha::SiteSearchEngineService::EnableAdvancedSiteSearchRequest'->new($_) } @$_ ] };

declare 'MapStringEnableAdvancedSiteSearchRequest',
    as HashRef[EnableAdvancedSiteSearchRequest()];

declare 'EnableAdvancedSiteSearchResponse',
    as InstanceOf['Google::Cloud::Discoveryengine::V1alpha::SiteSearchEngineService::EnableAdvancedSiteSearchResponse'];

coerce 'EnableAdvancedSiteSearchResponse',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1alpha::SiteSearchEngineService::EnableAdvancedSiteSearchResponse'->new($_) };

declare 'RepeatedEnableAdvancedSiteSearchResponse',
    as ArrayRef[EnableAdvancedSiteSearchResponse()];

coerce 'RepeatedEnableAdvancedSiteSearchResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1alpha::SiteSearchEngineService::EnableAdvancedSiteSearchResponse'->new($_) } @$_ ] };

declare 'MapStringEnableAdvancedSiteSearchResponse',
    as HashRef[EnableAdvancedSiteSearchResponse()];

declare 'EnableAdvancedSiteSearchMetadata',
    as InstanceOf['Google::Cloud::Discoveryengine::V1alpha::SiteSearchEngineService::EnableAdvancedSiteSearchMetadata'];

coerce 'EnableAdvancedSiteSearchMetadata',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1alpha::SiteSearchEngineService::EnableAdvancedSiteSearchMetadata'->new($_) };

declare 'RepeatedEnableAdvancedSiteSearchMetadata',
    as ArrayRef[EnableAdvancedSiteSearchMetadata()];

coerce 'RepeatedEnableAdvancedSiteSearchMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1alpha::SiteSearchEngineService::EnableAdvancedSiteSearchMetadata'->new($_) } @$_ ] };

declare 'MapStringEnableAdvancedSiteSearchMetadata',
    as HashRef[EnableAdvancedSiteSearchMetadata()];

declare 'DisableAdvancedSiteSearchRequest',
    as InstanceOf['Google::Cloud::Discoveryengine::V1alpha::SiteSearchEngineService::DisableAdvancedSiteSearchRequest'];

coerce 'DisableAdvancedSiteSearchRequest',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1alpha::SiteSearchEngineService::DisableAdvancedSiteSearchRequest'->new($_) };

declare 'RepeatedDisableAdvancedSiteSearchRequest',
    as ArrayRef[DisableAdvancedSiteSearchRequest()];

coerce 'RepeatedDisableAdvancedSiteSearchRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1alpha::SiteSearchEngineService::DisableAdvancedSiteSearchRequest'->new($_) } @$_ ] };

declare 'MapStringDisableAdvancedSiteSearchRequest',
    as HashRef[DisableAdvancedSiteSearchRequest()];

declare 'DisableAdvancedSiteSearchResponse',
    as InstanceOf['Google::Cloud::Discoveryengine::V1alpha::SiteSearchEngineService::DisableAdvancedSiteSearchResponse'];

coerce 'DisableAdvancedSiteSearchResponse',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1alpha::SiteSearchEngineService::DisableAdvancedSiteSearchResponse'->new($_) };

declare 'RepeatedDisableAdvancedSiteSearchResponse',
    as ArrayRef[DisableAdvancedSiteSearchResponse()];

coerce 'RepeatedDisableAdvancedSiteSearchResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1alpha::SiteSearchEngineService::DisableAdvancedSiteSearchResponse'->new($_) } @$_ ] };

declare 'MapStringDisableAdvancedSiteSearchResponse',
    as HashRef[DisableAdvancedSiteSearchResponse()];

declare 'DisableAdvancedSiteSearchMetadata',
    as InstanceOf['Google::Cloud::Discoveryengine::V1alpha::SiteSearchEngineService::DisableAdvancedSiteSearchMetadata'];

coerce 'DisableAdvancedSiteSearchMetadata',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1alpha::SiteSearchEngineService::DisableAdvancedSiteSearchMetadata'->new($_) };

declare 'RepeatedDisableAdvancedSiteSearchMetadata',
    as ArrayRef[DisableAdvancedSiteSearchMetadata()];

coerce 'RepeatedDisableAdvancedSiteSearchMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1alpha::SiteSearchEngineService::DisableAdvancedSiteSearchMetadata'->new($_) } @$_ ] };

declare 'MapStringDisableAdvancedSiteSearchMetadata',
    as HashRef[DisableAdvancedSiteSearchMetadata()];

declare 'RecrawlUrisRequest',
    as InstanceOf['Google::Cloud::Discoveryengine::V1alpha::SiteSearchEngineService::RecrawlUrisRequest'];

coerce 'RecrawlUrisRequest',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1alpha::SiteSearchEngineService::RecrawlUrisRequest'->new($_) };

declare 'RepeatedRecrawlUrisRequest',
    as ArrayRef[RecrawlUrisRequest()];

coerce 'RepeatedRecrawlUrisRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1alpha::SiteSearchEngineService::RecrawlUrisRequest'->new($_) } @$_ ] };

declare 'MapStringRecrawlUrisRequest',
    as HashRef[RecrawlUrisRequest()];

declare 'RecrawlUrisResponse',
    as InstanceOf['Google::Cloud::Discoveryengine::V1alpha::SiteSearchEngineService::RecrawlUrisResponse'];

coerce 'RecrawlUrisResponse',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1alpha::SiteSearchEngineService::RecrawlUrisResponse'->new($_) };

declare 'RepeatedRecrawlUrisResponse',
    as ArrayRef[RecrawlUrisResponse()];

coerce 'RepeatedRecrawlUrisResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1alpha::SiteSearchEngineService::RecrawlUrisResponse'->new($_) } @$_ ] };

declare 'MapStringRecrawlUrisResponse',
    as HashRef[RecrawlUrisResponse()];

declare 'FailureInfo',
    as InstanceOf['Google::Cloud::Discoveryengine::V1alpha::SiteSearchEngineService::RecrawlUrisResponse::FailureInfo'];

coerce 'FailureInfo',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1alpha::SiteSearchEngineService::RecrawlUrisResponse::FailureInfo'->new($_) };

declare 'RepeatedFailureInfo',
    as ArrayRef[FailureInfo()];

coerce 'RepeatedFailureInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1alpha::SiteSearchEngineService::RecrawlUrisResponse::FailureInfo'->new($_) } @$_ ] };

declare 'MapStringFailureInfo',
    as HashRef[FailureInfo()];

declare 'FailureReason',
    as InstanceOf['Google::Cloud::Discoveryengine::V1alpha::SiteSearchEngineService::RecrawlUrisResponse::FailureInfo::FailureReason'];

coerce 'FailureReason',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1alpha::SiteSearchEngineService::RecrawlUrisResponse::FailureInfo::FailureReason'->new($_) };

declare 'RepeatedFailureReason',
    as ArrayRef[FailureReason()];

coerce 'RepeatedFailureReason',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1alpha::SiteSearchEngineService::RecrawlUrisResponse::FailureInfo::FailureReason'->new($_) } @$_ ] };

declare 'MapStringFailureReason',
    as HashRef[FailureReason()];

declare 'CorpusType',
    as (Int | Str);

declare 'RecrawlUrisMetadata',
    as InstanceOf['Google::Cloud::Discoveryengine::V1alpha::SiteSearchEngineService::RecrawlUrisMetadata'];

coerce 'RecrawlUrisMetadata',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1alpha::SiteSearchEngineService::RecrawlUrisMetadata'->new($_) };

declare 'RepeatedRecrawlUrisMetadata',
    as ArrayRef[RecrawlUrisMetadata()];

coerce 'RepeatedRecrawlUrisMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1alpha::SiteSearchEngineService::RecrawlUrisMetadata'->new($_) } @$_ ] };

declare 'MapStringRecrawlUrisMetadata',
    as HashRef[RecrawlUrisMetadata()];

declare 'BatchVerifyTargetSitesRequest',
    as InstanceOf['Google::Cloud::Discoveryengine::V1alpha::SiteSearchEngineService::BatchVerifyTargetSitesRequest'];

coerce 'BatchVerifyTargetSitesRequest',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1alpha::SiteSearchEngineService::BatchVerifyTargetSitesRequest'->new($_) };

declare 'RepeatedBatchVerifyTargetSitesRequest',
    as ArrayRef[BatchVerifyTargetSitesRequest()];

coerce 'RepeatedBatchVerifyTargetSitesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1alpha::SiteSearchEngineService::BatchVerifyTargetSitesRequest'->new($_) } @$_ ] };

declare 'MapStringBatchVerifyTargetSitesRequest',
    as HashRef[BatchVerifyTargetSitesRequest()];

declare 'BatchVerifyTargetSitesResponse',
    as InstanceOf['Google::Cloud::Discoveryengine::V1alpha::SiteSearchEngineService::BatchVerifyTargetSitesResponse'];

coerce 'BatchVerifyTargetSitesResponse',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1alpha::SiteSearchEngineService::BatchVerifyTargetSitesResponse'->new($_) };

declare 'RepeatedBatchVerifyTargetSitesResponse',
    as ArrayRef[BatchVerifyTargetSitesResponse()];

coerce 'RepeatedBatchVerifyTargetSitesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1alpha::SiteSearchEngineService::BatchVerifyTargetSitesResponse'->new($_) } @$_ ] };

declare 'MapStringBatchVerifyTargetSitesResponse',
    as HashRef[BatchVerifyTargetSitesResponse()];

declare 'BatchVerifyTargetSitesMetadata',
    as InstanceOf['Google::Cloud::Discoveryengine::V1alpha::SiteSearchEngineService::BatchVerifyTargetSitesMetadata'];

coerce 'BatchVerifyTargetSitesMetadata',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1alpha::SiteSearchEngineService::BatchVerifyTargetSitesMetadata'->new($_) };

declare 'RepeatedBatchVerifyTargetSitesMetadata',
    as ArrayRef[BatchVerifyTargetSitesMetadata()];

coerce 'RepeatedBatchVerifyTargetSitesMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1alpha::SiteSearchEngineService::BatchVerifyTargetSitesMetadata'->new($_) } @$_ ] };

declare 'MapStringBatchVerifyTargetSitesMetadata',
    as HashRef[BatchVerifyTargetSitesMetadata()];

declare 'FetchDomainVerificationStatusRequest',
    as InstanceOf['Google::Cloud::Discoveryengine::V1alpha::SiteSearchEngineService::FetchDomainVerificationStatusRequest'];

coerce 'FetchDomainVerificationStatusRequest',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1alpha::SiteSearchEngineService::FetchDomainVerificationStatusRequest'->new($_) };

declare 'RepeatedFetchDomainVerificationStatusRequest',
    as ArrayRef[FetchDomainVerificationStatusRequest()];

coerce 'RepeatedFetchDomainVerificationStatusRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1alpha::SiteSearchEngineService::FetchDomainVerificationStatusRequest'->new($_) } @$_ ] };

declare 'MapStringFetchDomainVerificationStatusRequest',
    as HashRef[FetchDomainVerificationStatusRequest()];

declare 'FetchDomainVerificationStatusResponse',
    as InstanceOf['Google::Cloud::Discoveryengine::V1alpha::SiteSearchEngineService::FetchDomainVerificationStatusResponse'];

coerce 'FetchDomainVerificationStatusResponse',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1alpha::SiteSearchEngineService::FetchDomainVerificationStatusResponse'->new($_) };

declare 'RepeatedFetchDomainVerificationStatusResponse',
    as ArrayRef[FetchDomainVerificationStatusResponse()];

coerce 'RepeatedFetchDomainVerificationStatusResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1alpha::SiteSearchEngineService::FetchDomainVerificationStatusResponse'->new($_) } @$_ ] };

declare 'MapStringFetchDomainVerificationStatusResponse',
    as HashRef[FetchDomainVerificationStatusResponse()];

declare 'SetUriPatternDocumentDataRequest',
    as InstanceOf['Google::Cloud::Discoveryengine::V1alpha::SiteSearchEngineService::SetUriPatternDocumentDataRequest'];

coerce 'SetUriPatternDocumentDataRequest',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1alpha::SiteSearchEngineService::SetUriPatternDocumentDataRequest'->new($_) };

declare 'RepeatedSetUriPatternDocumentDataRequest',
    as ArrayRef[SetUriPatternDocumentDataRequest()];

coerce 'RepeatedSetUriPatternDocumentDataRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1alpha::SiteSearchEngineService::SetUriPatternDocumentDataRequest'->new($_) } @$_ ] };

declare 'MapStringSetUriPatternDocumentDataRequest',
    as HashRef[SetUriPatternDocumentDataRequest()];

declare 'DocumentDataMapEntry',
    as InstanceOf['Google::Cloud::Discoveryengine::V1alpha::SiteSearchEngineService::SetUriPatternDocumentDataRequest::DocumentDataMapEntry'];

coerce 'DocumentDataMapEntry',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1alpha::SiteSearchEngineService::SetUriPatternDocumentDataRequest::DocumentDataMapEntry'->new($_) };

declare 'RepeatedDocumentDataMapEntry',
    as ArrayRef[DocumentDataMapEntry()];

coerce 'RepeatedDocumentDataMapEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1alpha::SiteSearchEngineService::SetUriPatternDocumentDataRequest::DocumentDataMapEntry'->new($_) } @$_ ] };

declare 'MapStringDocumentDataMapEntry',
    as HashRef[DocumentDataMapEntry()];

declare 'SetUriPatternDocumentDataResponse',
    as InstanceOf['Google::Cloud::Discoveryengine::V1alpha::SiteSearchEngineService::SetUriPatternDocumentDataResponse'];

coerce 'SetUriPatternDocumentDataResponse',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1alpha::SiteSearchEngineService::SetUriPatternDocumentDataResponse'->new($_) };

declare 'RepeatedSetUriPatternDocumentDataResponse',
    as ArrayRef[SetUriPatternDocumentDataResponse()];

coerce 'RepeatedSetUriPatternDocumentDataResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1alpha::SiteSearchEngineService::SetUriPatternDocumentDataResponse'->new($_) } @$_ ] };

declare 'MapStringSetUriPatternDocumentDataResponse',
    as HashRef[SetUriPatternDocumentDataResponse()];

declare 'SetUriPatternDocumentDataMetadata',
    as InstanceOf['Google::Cloud::Discoveryengine::V1alpha::SiteSearchEngineService::SetUriPatternDocumentDataMetadata'];

coerce 'SetUriPatternDocumentDataMetadata',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1alpha::SiteSearchEngineService::SetUriPatternDocumentDataMetadata'->new($_) };

declare 'RepeatedSetUriPatternDocumentDataMetadata',
    as ArrayRef[SetUriPatternDocumentDataMetadata()];

coerce 'RepeatedSetUriPatternDocumentDataMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1alpha::SiteSearchEngineService::SetUriPatternDocumentDataMetadata'->new($_) } @$_ ] };

declare 'MapStringSetUriPatternDocumentDataMetadata',
    as HashRef[SetUriPatternDocumentDataMetadata()];

declare 'GetUriPatternDocumentDataRequest',
    as InstanceOf['Google::Cloud::Discoveryengine::V1alpha::SiteSearchEngineService::GetUriPatternDocumentDataRequest'];

coerce 'GetUriPatternDocumentDataRequest',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1alpha::SiteSearchEngineService::GetUriPatternDocumentDataRequest'->new($_) };

declare 'RepeatedGetUriPatternDocumentDataRequest',
    as ArrayRef[GetUriPatternDocumentDataRequest()];

coerce 'RepeatedGetUriPatternDocumentDataRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1alpha::SiteSearchEngineService::GetUriPatternDocumentDataRequest'->new($_) } @$_ ] };

declare 'MapStringGetUriPatternDocumentDataRequest',
    as HashRef[GetUriPatternDocumentDataRequest()];

declare 'GetUriPatternDocumentDataResponse',
    as InstanceOf['Google::Cloud::Discoveryengine::V1alpha::SiteSearchEngineService::GetUriPatternDocumentDataResponse'];

coerce 'GetUriPatternDocumentDataResponse',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1alpha::SiteSearchEngineService::GetUriPatternDocumentDataResponse'->new($_) };

declare 'RepeatedGetUriPatternDocumentDataResponse',
    as ArrayRef[GetUriPatternDocumentDataResponse()];

coerce 'RepeatedGetUriPatternDocumentDataResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1alpha::SiteSearchEngineService::GetUriPatternDocumentDataResponse'->new($_) } @$_ ] };

declare 'MapStringGetUriPatternDocumentDataResponse',
    as HashRef[GetUriPatternDocumentDataResponse()];

declare 'DocumentDataMapEntry',
    as InstanceOf['Google::Cloud::Discoveryengine::V1alpha::SiteSearchEngineService::GetUriPatternDocumentDataResponse::DocumentDataMapEntry'];

coerce 'DocumentDataMapEntry',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1alpha::SiteSearchEngineService::GetUriPatternDocumentDataResponse::DocumentDataMapEntry'->new($_) };

declare 'RepeatedDocumentDataMapEntry',
    as ArrayRef[DocumentDataMapEntry()];

coerce 'RepeatedDocumentDataMapEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1alpha::SiteSearchEngineService::GetUriPatternDocumentDataResponse::DocumentDataMapEntry'->new($_) } @$_ ] };

declare 'MapStringDocumentDataMapEntry',
    as HashRef[DocumentDataMapEntry()];

1;

__END__

=head1 NAME

Google::Cloud::Discoveryengine::V1alpha::SiteSearchEngineService::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
