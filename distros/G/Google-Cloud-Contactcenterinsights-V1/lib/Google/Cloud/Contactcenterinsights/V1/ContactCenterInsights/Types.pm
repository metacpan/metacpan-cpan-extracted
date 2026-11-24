package Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'ConversationView',
    as (Int | Str);

declare 'CalculateStatsRequest',
    as InstanceOf['Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::CalculateStatsRequest'];

coerce 'CalculateStatsRequest',
    from HashRef, via { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::CalculateStatsRequest'->new($_) };

declare 'RepeatedCalculateStatsRequest',
    as ArrayRef[CalculateStatsRequest()];

coerce 'RepeatedCalculateStatsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::CalculateStatsRequest'->new($_) } @$_ ] };

declare 'MapStringCalculateStatsRequest',
    as HashRef[CalculateStatsRequest()];

declare 'CalculateStatsResponse',
    as InstanceOf['Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::CalculateStatsResponse'];

coerce 'CalculateStatsResponse',
    from HashRef, via { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::CalculateStatsResponse'->new($_) };

declare 'RepeatedCalculateStatsResponse',
    as ArrayRef[CalculateStatsResponse()];

coerce 'RepeatedCalculateStatsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::CalculateStatsResponse'->new($_) } @$_ ] };

declare 'MapStringCalculateStatsResponse',
    as HashRef[CalculateStatsResponse()];

declare 'TimeSeries',
    as InstanceOf['Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::CalculateStatsResponse::TimeSeries'];

coerce 'TimeSeries',
    from HashRef, via { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::CalculateStatsResponse::TimeSeries'->new($_) };

declare 'RepeatedTimeSeries',
    as ArrayRef[TimeSeries()];

coerce 'RepeatedTimeSeries',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::CalculateStatsResponse::TimeSeries'->new($_) } @$_ ] };

declare 'MapStringTimeSeries',
    as HashRef[TimeSeries()];

declare 'Interval',
    as InstanceOf['Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::CalculateStatsResponse::TimeSeries::Interval'];

coerce 'Interval',
    from HashRef, via { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::CalculateStatsResponse::TimeSeries::Interval'->new($_) };

declare 'RepeatedInterval',
    as ArrayRef[Interval()];

coerce 'RepeatedInterval',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::CalculateStatsResponse::TimeSeries::Interval'->new($_) } @$_ ] };

declare 'MapStringInterval',
    as HashRef[Interval()];

declare 'SmartHighlighterMatchesEntry',
    as InstanceOf['Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::CalculateStatsResponse::SmartHighlighterMatchesEntry'];

coerce 'SmartHighlighterMatchesEntry',
    from HashRef, via { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::CalculateStatsResponse::SmartHighlighterMatchesEntry'->new($_) };

declare 'RepeatedSmartHighlighterMatchesEntry',
    as ArrayRef[SmartHighlighterMatchesEntry()];

coerce 'RepeatedSmartHighlighterMatchesEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::CalculateStatsResponse::SmartHighlighterMatchesEntry'->new($_) } @$_ ] };

declare 'MapStringSmartHighlighterMatchesEntry',
    as HashRef[SmartHighlighterMatchesEntry()];

declare 'CustomHighlighterMatchesEntry',
    as InstanceOf['Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::CalculateStatsResponse::CustomHighlighterMatchesEntry'];

coerce 'CustomHighlighterMatchesEntry',
    from HashRef, via { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::CalculateStatsResponse::CustomHighlighterMatchesEntry'->new($_) };

declare 'RepeatedCustomHighlighterMatchesEntry',
    as ArrayRef[CustomHighlighterMatchesEntry()];

coerce 'RepeatedCustomHighlighterMatchesEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::CalculateStatsResponse::CustomHighlighterMatchesEntry'->new($_) } @$_ ] };

declare 'MapStringCustomHighlighterMatchesEntry',
    as HashRef[CustomHighlighterMatchesEntry()];

declare 'IssueMatchesEntry',
    as InstanceOf['Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::CalculateStatsResponse::IssueMatchesEntry'];

coerce 'IssueMatchesEntry',
    from HashRef, via { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::CalculateStatsResponse::IssueMatchesEntry'->new($_) };

declare 'RepeatedIssueMatchesEntry',
    as ArrayRef[IssueMatchesEntry()];

coerce 'RepeatedIssueMatchesEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::CalculateStatsResponse::IssueMatchesEntry'->new($_) } @$_ ] };

declare 'MapStringIssueMatchesEntry',
    as HashRef[IssueMatchesEntry()];

declare 'IssueMatchesStatsEntry',
    as InstanceOf['Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::CalculateStatsResponse::IssueMatchesStatsEntry'];

coerce 'IssueMatchesStatsEntry',
    from HashRef, via { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::CalculateStatsResponse::IssueMatchesStatsEntry'->new($_) };

declare 'RepeatedIssueMatchesStatsEntry',
    as ArrayRef[IssueMatchesStatsEntry()];

coerce 'RepeatedIssueMatchesStatsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::CalculateStatsResponse::IssueMatchesStatsEntry'->new($_) } @$_ ] };

declare 'MapStringIssueMatchesStatsEntry',
    as HashRef[IssueMatchesStatsEntry()];

declare 'CreateAnalysisOperationMetadata',
    as InstanceOf['Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::CreateAnalysisOperationMetadata'];

coerce 'CreateAnalysisOperationMetadata',
    from HashRef, via { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::CreateAnalysisOperationMetadata'->new($_) };

declare 'RepeatedCreateAnalysisOperationMetadata',
    as ArrayRef[CreateAnalysisOperationMetadata()];

coerce 'RepeatedCreateAnalysisOperationMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::CreateAnalysisOperationMetadata'->new($_) } @$_ ] };

declare 'MapStringCreateAnalysisOperationMetadata',
    as HashRef[CreateAnalysisOperationMetadata()];

declare 'CreateConversationRequest',
    as InstanceOf['Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::CreateConversationRequest'];

coerce 'CreateConversationRequest',
    from HashRef, via { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::CreateConversationRequest'->new($_) };

declare 'RepeatedCreateConversationRequest',
    as ArrayRef[CreateConversationRequest()];

coerce 'RepeatedCreateConversationRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::CreateConversationRequest'->new($_) } @$_ ] };

declare 'MapStringCreateConversationRequest',
    as HashRef[CreateConversationRequest()];

declare 'UploadConversationRequest',
    as InstanceOf['Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::UploadConversationRequest'];

coerce 'UploadConversationRequest',
    from HashRef, via { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::UploadConversationRequest'->new($_) };

declare 'RepeatedUploadConversationRequest',
    as ArrayRef[UploadConversationRequest()];

coerce 'RepeatedUploadConversationRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::UploadConversationRequest'->new($_) } @$_ ] };

declare 'MapStringUploadConversationRequest',
    as HashRef[UploadConversationRequest()];

declare 'UploadConversationMetadata',
    as InstanceOf['Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::UploadConversationMetadata'];

coerce 'UploadConversationMetadata',
    from HashRef, via { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::UploadConversationMetadata'->new($_) };

declare 'RepeatedUploadConversationMetadata',
    as ArrayRef[UploadConversationMetadata()];

coerce 'RepeatedUploadConversationMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::UploadConversationMetadata'->new($_) } @$_ ] };

declare 'MapStringUploadConversationMetadata',
    as HashRef[UploadConversationMetadata()];

declare 'ListConversationsRequest',
    as InstanceOf['Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::ListConversationsRequest'];

coerce 'ListConversationsRequest',
    from HashRef, via { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::ListConversationsRequest'->new($_) };

declare 'RepeatedListConversationsRequest',
    as ArrayRef[ListConversationsRequest()];

coerce 'RepeatedListConversationsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::ListConversationsRequest'->new($_) } @$_ ] };

declare 'MapStringListConversationsRequest',
    as HashRef[ListConversationsRequest()];

declare 'ListConversationsResponse',
    as InstanceOf['Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::ListConversationsResponse'];

coerce 'ListConversationsResponse',
    from HashRef, via { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::ListConversationsResponse'->new($_) };

declare 'RepeatedListConversationsResponse',
    as ArrayRef[ListConversationsResponse()];

coerce 'RepeatedListConversationsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::ListConversationsResponse'->new($_) } @$_ ] };

declare 'MapStringListConversationsResponse',
    as HashRef[ListConversationsResponse()];

declare 'GetConversationRequest',
    as InstanceOf['Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::GetConversationRequest'];

coerce 'GetConversationRequest',
    from HashRef, via { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::GetConversationRequest'->new($_) };

declare 'RepeatedGetConversationRequest',
    as ArrayRef[GetConversationRequest()];

coerce 'RepeatedGetConversationRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::GetConversationRequest'->new($_) } @$_ ] };

declare 'MapStringGetConversationRequest',
    as HashRef[GetConversationRequest()];

declare 'UpdateConversationRequest',
    as InstanceOf['Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::UpdateConversationRequest'];

coerce 'UpdateConversationRequest',
    from HashRef, via { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::UpdateConversationRequest'->new($_) };

declare 'RepeatedUpdateConversationRequest',
    as ArrayRef[UpdateConversationRequest()];

coerce 'RepeatedUpdateConversationRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::UpdateConversationRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateConversationRequest',
    as HashRef[UpdateConversationRequest()];

declare 'DeleteConversationRequest',
    as InstanceOf['Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::DeleteConversationRequest'];

coerce 'DeleteConversationRequest',
    from HashRef, via { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::DeleteConversationRequest'->new($_) };

declare 'RepeatedDeleteConversationRequest',
    as ArrayRef[DeleteConversationRequest()];

coerce 'RepeatedDeleteConversationRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::DeleteConversationRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteConversationRequest',
    as HashRef[DeleteConversationRequest()];

declare 'IngestConversationsRequest',
    as InstanceOf['Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::IngestConversationsRequest'];

coerce 'IngestConversationsRequest',
    from HashRef, via { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::IngestConversationsRequest'->new($_) };

declare 'RepeatedIngestConversationsRequest',
    as ArrayRef[IngestConversationsRequest()];

coerce 'RepeatedIngestConversationsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::IngestConversationsRequest'->new($_) } @$_ ] };

declare 'MapStringIngestConversationsRequest',
    as HashRef[IngestConversationsRequest()];

declare 'GcsSource',
    as InstanceOf['Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::IngestConversationsRequest::GcsSource'];

coerce 'GcsSource',
    from HashRef, via { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::IngestConversationsRequest::GcsSource'->new($_) };

declare 'RepeatedGcsSource',
    as ArrayRef[GcsSource()];

coerce 'RepeatedGcsSource',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::IngestConversationsRequest::GcsSource'->new($_) } @$_ ] };

declare 'MapStringGcsSource',
    as HashRef[GcsSource()];

declare 'BucketObjectType',
    as (Int | Str);

declare 'TranscriptObjectConfig',
    as InstanceOf['Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::IngestConversationsRequest::TranscriptObjectConfig'];

coerce 'TranscriptObjectConfig',
    from HashRef, via { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::IngestConversationsRequest::TranscriptObjectConfig'->new($_) };

declare 'RepeatedTranscriptObjectConfig',
    as ArrayRef[TranscriptObjectConfig()];

coerce 'RepeatedTranscriptObjectConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::IngestConversationsRequest::TranscriptObjectConfig'->new($_) } @$_ ] };

declare 'MapStringTranscriptObjectConfig',
    as HashRef[TranscriptObjectConfig()];

declare 'ConversationConfig',
    as InstanceOf['Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::IngestConversationsRequest::ConversationConfig'];

coerce 'ConversationConfig',
    from HashRef, via { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::IngestConversationsRequest::ConversationConfig'->new($_) };

declare 'RepeatedConversationConfig',
    as ArrayRef[ConversationConfig()];

coerce 'RepeatedConversationConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::IngestConversationsRequest::ConversationConfig'->new($_) } @$_ ] };

declare 'MapStringConversationConfig',
    as HashRef[ConversationConfig()];

declare 'IngestConversationsMetadata',
    as InstanceOf['Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::IngestConversationsMetadata'];

coerce 'IngestConversationsMetadata',
    from HashRef, via { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::IngestConversationsMetadata'->new($_) };

declare 'RepeatedIngestConversationsMetadata',
    as ArrayRef[IngestConversationsMetadata()];

coerce 'RepeatedIngestConversationsMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::IngestConversationsMetadata'->new($_) } @$_ ] };

declare 'MapStringIngestConversationsMetadata',
    as HashRef[IngestConversationsMetadata()];

declare 'IngestConversationsStats',
    as InstanceOf['Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::IngestConversationsMetadata::IngestConversationsStats'];

coerce 'IngestConversationsStats',
    from HashRef, via { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::IngestConversationsMetadata::IngestConversationsStats'->new($_) };

declare 'RepeatedIngestConversationsStats',
    as ArrayRef[IngestConversationsStats()];

coerce 'RepeatedIngestConversationsStats',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::IngestConversationsMetadata::IngestConversationsStats'->new($_) } @$_ ] };

declare 'MapStringIngestConversationsStats',
    as HashRef[IngestConversationsStats()];

declare 'IngestConversationsResponse',
    as InstanceOf['Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::IngestConversationsResponse'];

coerce 'IngestConversationsResponse',
    from HashRef, via { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::IngestConversationsResponse'->new($_) };

declare 'RepeatedIngestConversationsResponse',
    as ArrayRef[IngestConversationsResponse()];

coerce 'RepeatedIngestConversationsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::IngestConversationsResponse'->new($_) } @$_ ] };

declare 'MapStringIngestConversationsResponse',
    as HashRef[IngestConversationsResponse()];

declare 'CreateAnalysisRequest',
    as InstanceOf['Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::CreateAnalysisRequest'];

coerce 'CreateAnalysisRequest',
    from HashRef, via { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::CreateAnalysisRequest'->new($_) };

declare 'RepeatedCreateAnalysisRequest',
    as ArrayRef[CreateAnalysisRequest()];

coerce 'RepeatedCreateAnalysisRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::CreateAnalysisRequest'->new($_) } @$_ ] };

declare 'MapStringCreateAnalysisRequest',
    as HashRef[CreateAnalysisRequest()];

declare 'ListAnalysesRequest',
    as InstanceOf['Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::ListAnalysesRequest'];

coerce 'ListAnalysesRequest',
    from HashRef, via { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::ListAnalysesRequest'->new($_) };

declare 'RepeatedListAnalysesRequest',
    as ArrayRef[ListAnalysesRequest()];

coerce 'RepeatedListAnalysesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::ListAnalysesRequest'->new($_) } @$_ ] };

declare 'MapStringListAnalysesRequest',
    as HashRef[ListAnalysesRequest()];

declare 'ListAnalysesResponse',
    as InstanceOf['Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::ListAnalysesResponse'];

coerce 'ListAnalysesResponse',
    from HashRef, via { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::ListAnalysesResponse'->new($_) };

declare 'RepeatedListAnalysesResponse',
    as ArrayRef[ListAnalysesResponse()];

coerce 'RepeatedListAnalysesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::ListAnalysesResponse'->new($_) } @$_ ] };

declare 'MapStringListAnalysesResponse',
    as HashRef[ListAnalysesResponse()];

declare 'GetAnalysisRequest',
    as InstanceOf['Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::GetAnalysisRequest'];

coerce 'GetAnalysisRequest',
    from HashRef, via { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::GetAnalysisRequest'->new($_) };

declare 'RepeatedGetAnalysisRequest',
    as ArrayRef[GetAnalysisRequest()];

coerce 'RepeatedGetAnalysisRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::GetAnalysisRequest'->new($_) } @$_ ] };

declare 'MapStringGetAnalysisRequest',
    as HashRef[GetAnalysisRequest()];

declare 'DeleteAnalysisRequest',
    as InstanceOf['Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::DeleteAnalysisRequest'];

coerce 'DeleteAnalysisRequest',
    from HashRef, via { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::DeleteAnalysisRequest'->new($_) };

declare 'RepeatedDeleteAnalysisRequest',
    as ArrayRef[DeleteAnalysisRequest()];

coerce 'RepeatedDeleteAnalysisRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::DeleteAnalysisRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteAnalysisRequest',
    as HashRef[DeleteAnalysisRequest()];

declare 'BulkAnalyzeConversationsRequest',
    as InstanceOf['Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::BulkAnalyzeConversationsRequest'];

coerce 'BulkAnalyzeConversationsRequest',
    from HashRef, via { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::BulkAnalyzeConversationsRequest'->new($_) };

declare 'RepeatedBulkAnalyzeConversationsRequest',
    as ArrayRef[BulkAnalyzeConversationsRequest()];

coerce 'RepeatedBulkAnalyzeConversationsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::BulkAnalyzeConversationsRequest'->new($_) } @$_ ] };

declare 'MapStringBulkAnalyzeConversationsRequest',
    as HashRef[BulkAnalyzeConversationsRequest()];

declare 'BulkAnalyzeConversationsMetadata',
    as InstanceOf['Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::BulkAnalyzeConversationsMetadata'];

coerce 'BulkAnalyzeConversationsMetadata',
    from HashRef, via { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::BulkAnalyzeConversationsMetadata'->new($_) };

declare 'RepeatedBulkAnalyzeConversationsMetadata',
    as ArrayRef[BulkAnalyzeConversationsMetadata()];

coerce 'RepeatedBulkAnalyzeConversationsMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::BulkAnalyzeConversationsMetadata'->new($_) } @$_ ] };

declare 'MapStringBulkAnalyzeConversationsMetadata',
    as HashRef[BulkAnalyzeConversationsMetadata()];

declare 'BulkAnalyzeConversationsResponse',
    as InstanceOf['Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::BulkAnalyzeConversationsResponse'];

coerce 'BulkAnalyzeConversationsResponse',
    from HashRef, via { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::BulkAnalyzeConversationsResponse'->new($_) };

declare 'RepeatedBulkAnalyzeConversationsResponse',
    as ArrayRef[BulkAnalyzeConversationsResponse()];

coerce 'RepeatedBulkAnalyzeConversationsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::BulkAnalyzeConversationsResponse'->new($_) } @$_ ] };

declare 'MapStringBulkAnalyzeConversationsResponse',
    as HashRef[BulkAnalyzeConversationsResponse()];

declare 'BulkDeleteConversationsRequest',
    as InstanceOf['Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::BulkDeleteConversationsRequest'];

coerce 'BulkDeleteConversationsRequest',
    from HashRef, via { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::BulkDeleteConversationsRequest'->new($_) };

declare 'RepeatedBulkDeleteConversationsRequest',
    as ArrayRef[BulkDeleteConversationsRequest()];

coerce 'RepeatedBulkDeleteConversationsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::BulkDeleteConversationsRequest'->new($_) } @$_ ] };

declare 'MapStringBulkDeleteConversationsRequest',
    as HashRef[BulkDeleteConversationsRequest()];

declare 'BulkDeleteConversationsMetadata',
    as InstanceOf['Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::BulkDeleteConversationsMetadata'];

coerce 'BulkDeleteConversationsMetadata',
    from HashRef, via { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::BulkDeleteConversationsMetadata'->new($_) };

declare 'RepeatedBulkDeleteConversationsMetadata',
    as ArrayRef[BulkDeleteConversationsMetadata()];

coerce 'RepeatedBulkDeleteConversationsMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::BulkDeleteConversationsMetadata'->new($_) } @$_ ] };

declare 'MapStringBulkDeleteConversationsMetadata',
    as HashRef[BulkDeleteConversationsMetadata()];

declare 'BulkDeleteConversationsResponse',
    as InstanceOf['Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::BulkDeleteConversationsResponse'];

coerce 'BulkDeleteConversationsResponse',
    from HashRef, via { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::BulkDeleteConversationsResponse'->new($_) };

declare 'RepeatedBulkDeleteConversationsResponse',
    as ArrayRef[BulkDeleteConversationsResponse()];

coerce 'RepeatedBulkDeleteConversationsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::BulkDeleteConversationsResponse'->new($_) } @$_ ] };

declare 'MapStringBulkDeleteConversationsResponse',
    as HashRef[BulkDeleteConversationsResponse()];

declare 'ExportInsightsDataRequest',
    as InstanceOf['Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::ExportInsightsDataRequest'];

coerce 'ExportInsightsDataRequest',
    from HashRef, via { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::ExportInsightsDataRequest'->new($_) };

declare 'RepeatedExportInsightsDataRequest',
    as ArrayRef[ExportInsightsDataRequest()];

coerce 'RepeatedExportInsightsDataRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::ExportInsightsDataRequest'->new($_) } @$_ ] };

declare 'MapStringExportInsightsDataRequest',
    as HashRef[ExportInsightsDataRequest()];

declare 'WriteDisposition',
    as (Int | Str);

declare 'BigQueryDestination',
    as InstanceOf['Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::ExportInsightsDataRequest::BigQueryDestination'];

coerce 'BigQueryDestination',
    from HashRef, via { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::ExportInsightsDataRequest::BigQueryDestination'->new($_) };

declare 'RepeatedBigQueryDestination',
    as ArrayRef[BigQueryDestination()];

coerce 'RepeatedBigQueryDestination',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::ExportInsightsDataRequest::BigQueryDestination'->new($_) } @$_ ] };

declare 'MapStringBigQueryDestination',
    as HashRef[BigQueryDestination()];

declare 'ExportInsightsDataMetadata',
    as InstanceOf['Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::ExportInsightsDataMetadata'];

coerce 'ExportInsightsDataMetadata',
    from HashRef, via { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::ExportInsightsDataMetadata'->new($_) };

declare 'RepeatedExportInsightsDataMetadata',
    as ArrayRef[ExportInsightsDataMetadata()];

coerce 'RepeatedExportInsightsDataMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::ExportInsightsDataMetadata'->new($_) } @$_ ] };

declare 'MapStringExportInsightsDataMetadata',
    as HashRef[ExportInsightsDataMetadata()];

declare 'ExportInsightsDataResponse',
    as InstanceOf['Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::ExportInsightsDataResponse'];

coerce 'ExportInsightsDataResponse',
    from HashRef, via { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::ExportInsightsDataResponse'->new($_) };

declare 'RepeatedExportInsightsDataResponse',
    as ArrayRef[ExportInsightsDataResponse()];

coerce 'RepeatedExportInsightsDataResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::ExportInsightsDataResponse'->new($_) } @$_ ] };

declare 'MapStringExportInsightsDataResponse',
    as HashRef[ExportInsightsDataResponse()];

declare 'CreateIssueModelRequest',
    as InstanceOf['Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::CreateIssueModelRequest'];

coerce 'CreateIssueModelRequest',
    from HashRef, via { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::CreateIssueModelRequest'->new($_) };

declare 'RepeatedCreateIssueModelRequest',
    as ArrayRef[CreateIssueModelRequest()];

coerce 'RepeatedCreateIssueModelRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::CreateIssueModelRequest'->new($_) } @$_ ] };

declare 'MapStringCreateIssueModelRequest',
    as HashRef[CreateIssueModelRequest()];

declare 'CreateIssueModelMetadata',
    as InstanceOf['Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::CreateIssueModelMetadata'];

coerce 'CreateIssueModelMetadata',
    from HashRef, via { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::CreateIssueModelMetadata'->new($_) };

declare 'RepeatedCreateIssueModelMetadata',
    as ArrayRef[CreateIssueModelMetadata()];

coerce 'RepeatedCreateIssueModelMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::CreateIssueModelMetadata'->new($_) } @$_ ] };

declare 'MapStringCreateIssueModelMetadata',
    as HashRef[CreateIssueModelMetadata()];

declare 'UpdateIssueModelRequest',
    as InstanceOf['Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::UpdateIssueModelRequest'];

coerce 'UpdateIssueModelRequest',
    from HashRef, via { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::UpdateIssueModelRequest'->new($_) };

declare 'RepeatedUpdateIssueModelRequest',
    as ArrayRef[UpdateIssueModelRequest()];

coerce 'RepeatedUpdateIssueModelRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::UpdateIssueModelRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateIssueModelRequest',
    as HashRef[UpdateIssueModelRequest()];

declare 'ListIssueModelsRequest',
    as InstanceOf['Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::ListIssueModelsRequest'];

coerce 'ListIssueModelsRequest',
    from HashRef, via { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::ListIssueModelsRequest'->new($_) };

declare 'RepeatedListIssueModelsRequest',
    as ArrayRef[ListIssueModelsRequest()];

coerce 'RepeatedListIssueModelsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::ListIssueModelsRequest'->new($_) } @$_ ] };

declare 'MapStringListIssueModelsRequest',
    as HashRef[ListIssueModelsRequest()];

declare 'ListIssueModelsResponse',
    as InstanceOf['Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::ListIssueModelsResponse'];

coerce 'ListIssueModelsResponse',
    from HashRef, via { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::ListIssueModelsResponse'->new($_) };

declare 'RepeatedListIssueModelsResponse',
    as ArrayRef[ListIssueModelsResponse()];

coerce 'RepeatedListIssueModelsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::ListIssueModelsResponse'->new($_) } @$_ ] };

declare 'MapStringListIssueModelsResponse',
    as HashRef[ListIssueModelsResponse()];

declare 'GetIssueModelRequest',
    as InstanceOf['Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::GetIssueModelRequest'];

coerce 'GetIssueModelRequest',
    from HashRef, via { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::GetIssueModelRequest'->new($_) };

declare 'RepeatedGetIssueModelRequest',
    as ArrayRef[GetIssueModelRequest()];

coerce 'RepeatedGetIssueModelRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::GetIssueModelRequest'->new($_) } @$_ ] };

declare 'MapStringGetIssueModelRequest',
    as HashRef[GetIssueModelRequest()];

declare 'DeleteIssueModelRequest',
    as InstanceOf['Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::DeleteIssueModelRequest'];

coerce 'DeleteIssueModelRequest',
    from HashRef, via { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::DeleteIssueModelRequest'->new($_) };

declare 'RepeatedDeleteIssueModelRequest',
    as ArrayRef[DeleteIssueModelRequest()];

coerce 'RepeatedDeleteIssueModelRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::DeleteIssueModelRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteIssueModelRequest',
    as HashRef[DeleteIssueModelRequest()];

declare 'DeleteIssueModelMetadata',
    as InstanceOf['Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::DeleteIssueModelMetadata'];

coerce 'DeleteIssueModelMetadata',
    from HashRef, via { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::DeleteIssueModelMetadata'->new($_) };

declare 'RepeatedDeleteIssueModelMetadata',
    as ArrayRef[DeleteIssueModelMetadata()];

coerce 'RepeatedDeleteIssueModelMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::DeleteIssueModelMetadata'->new($_) } @$_ ] };

declare 'MapStringDeleteIssueModelMetadata',
    as HashRef[DeleteIssueModelMetadata()];

declare 'DeployIssueModelRequest',
    as InstanceOf['Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::DeployIssueModelRequest'];

coerce 'DeployIssueModelRequest',
    from HashRef, via { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::DeployIssueModelRequest'->new($_) };

declare 'RepeatedDeployIssueModelRequest',
    as ArrayRef[DeployIssueModelRequest()];

coerce 'RepeatedDeployIssueModelRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::DeployIssueModelRequest'->new($_) } @$_ ] };

declare 'MapStringDeployIssueModelRequest',
    as HashRef[DeployIssueModelRequest()];

declare 'DeployIssueModelResponse',
    as InstanceOf['Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::DeployIssueModelResponse'];

coerce 'DeployIssueModelResponse',
    from HashRef, via { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::DeployIssueModelResponse'->new($_) };

declare 'RepeatedDeployIssueModelResponse',
    as ArrayRef[DeployIssueModelResponse()];

coerce 'RepeatedDeployIssueModelResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::DeployIssueModelResponse'->new($_) } @$_ ] };

declare 'MapStringDeployIssueModelResponse',
    as HashRef[DeployIssueModelResponse()];

declare 'DeployIssueModelMetadata',
    as InstanceOf['Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::DeployIssueModelMetadata'];

coerce 'DeployIssueModelMetadata',
    from HashRef, via { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::DeployIssueModelMetadata'->new($_) };

declare 'RepeatedDeployIssueModelMetadata',
    as ArrayRef[DeployIssueModelMetadata()];

coerce 'RepeatedDeployIssueModelMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::DeployIssueModelMetadata'->new($_) } @$_ ] };

declare 'MapStringDeployIssueModelMetadata',
    as HashRef[DeployIssueModelMetadata()];

declare 'UndeployIssueModelRequest',
    as InstanceOf['Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::UndeployIssueModelRequest'];

coerce 'UndeployIssueModelRequest',
    from HashRef, via { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::UndeployIssueModelRequest'->new($_) };

declare 'RepeatedUndeployIssueModelRequest',
    as ArrayRef[UndeployIssueModelRequest()];

coerce 'RepeatedUndeployIssueModelRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::UndeployIssueModelRequest'->new($_) } @$_ ] };

declare 'MapStringUndeployIssueModelRequest',
    as HashRef[UndeployIssueModelRequest()];

declare 'UndeployIssueModelResponse',
    as InstanceOf['Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::UndeployIssueModelResponse'];

coerce 'UndeployIssueModelResponse',
    from HashRef, via { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::UndeployIssueModelResponse'->new($_) };

declare 'RepeatedUndeployIssueModelResponse',
    as ArrayRef[UndeployIssueModelResponse()];

coerce 'RepeatedUndeployIssueModelResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::UndeployIssueModelResponse'->new($_) } @$_ ] };

declare 'MapStringUndeployIssueModelResponse',
    as HashRef[UndeployIssueModelResponse()];

declare 'UndeployIssueModelMetadata',
    as InstanceOf['Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::UndeployIssueModelMetadata'];

coerce 'UndeployIssueModelMetadata',
    from HashRef, via { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::UndeployIssueModelMetadata'->new($_) };

declare 'RepeatedUndeployIssueModelMetadata',
    as ArrayRef[UndeployIssueModelMetadata()];

coerce 'RepeatedUndeployIssueModelMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::UndeployIssueModelMetadata'->new($_) } @$_ ] };

declare 'MapStringUndeployIssueModelMetadata',
    as HashRef[UndeployIssueModelMetadata()];

declare 'ExportIssueModelRequest',
    as InstanceOf['Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::ExportIssueModelRequest'];

coerce 'ExportIssueModelRequest',
    from HashRef, via { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::ExportIssueModelRequest'->new($_) };

declare 'RepeatedExportIssueModelRequest',
    as ArrayRef[ExportIssueModelRequest()];

coerce 'RepeatedExportIssueModelRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::ExportIssueModelRequest'->new($_) } @$_ ] };

declare 'MapStringExportIssueModelRequest',
    as HashRef[ExportIssueModelRequest()];

declare 'GcsDestination',
    as InstanceOf['Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::ExportIssueModelRequest::GcsDestination'];

coerce 'GcsDestination',
    from HashRef, via { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::ExportIssueModelRequest::GcsDestination'->new($_) };

declare 'RepeatedGcsDestination',
    as ArrayRef[GcsDestination()];

coerce 'RepeatedGcsDestination',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::ExportIssueModelRequest::GcsDestination'->new($_) } @$_ ] };

declare 'MapStringGcsDestination',
    as HashRef[GcsDestination()];

declare 'ExportIssueModelResponse',
    as InstanceOf['Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::ExportIssueModelResponse'];

coerce 'ExportIssueModelResponse',
    from HashRef, via { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::ExportIssueModelResponse'->new($_) };

declare 'RepeatedExportIssueModelResponse',
    as ArrayRef[ExportIssueModelResponse()];

coerce 'RepeatedExportIssueModelResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::ExportIssueModelResponse'->new($_) } @$_ ] };

declare 'MapStringExportIssueModelResponse',
    as HashRef[ExportIssueModelResponse()];

declare 'ExportIssueModelMetadata',
    as InstanceOf['Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::ExportIssueModelMetadata'];

coerce 'ExportIssueModelMetadata',
    from HashRef, via { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::ExportIssueModelMetadata'->new($_) };

declare 'RepeatedExportIssueModelMetadata',
    as ArrayRef[ExportIssueModelMetadata()];

coerce 'RepeatedExportIssueModelMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::ExportIssueModelMetadata'->new($_) } @$_ ] };

declare 'MapStringExportIssueModelMetadata',
    as HashRef[ExportIssueModelMetadata()];

declare 'ImportIssueModelRequest',
    as InstanceOf['Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::ImportIssueModelRequest'];

coerce 'ImportIssueModelRequest',
    from HashRef, via { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::ImportIssueModelRequest'->new($_) };

declare 'RepeatedImportIssueModelRequest',
    as ArrayRef[ImportIssueModelRequest()];

coerce 'RepeatedImportIssueModelRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::ImportIssueModelRequest'->new($_) } @$_ ] };

declare 'MapStringImportIssueModelRequest',
    as HashRef[ImportIssueModelRequest()];

declare 'GcsSource',
    as InstanceOf['Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::ImportIssueModelRequest::GcsSource'];

coerce 'GcsSource',
    from HashRef, via { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::ImportIssueModelRequest::GcsSource'->new($_) };

declare 'RepeatedGcsSource',
    as ArrayRef[GcsSource()];

coerce 'RepeatedGcsSource',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::ImportIssueModelRequest::GcsSource'->new($_) } @$_ ] };

declare 'MapStringGcsSource',
    as HashRef[GcsSource()];

declare 'ImportIssueModelResponse',
    as InstanceOf['Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::ImportIssueModelResponse'];

coerce 'ImportIssueModelResponse',
    from HashRef, via { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::ImportIssueModelResponse'->new($_) };

declare 'RepeatedImportIssueModelResponse',
    as ArrayRef[ImportIssueModelResponse()];

coerce 'RepeatedImportIssueModelResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::ImportIssueModelResponse'->new($_) } @$_ ] };

declare 'MapStringImportIssueModelResponse',
    as HashRef[ImportIssueModelResponse()];

declare 'ImportIssueModelMetadata',
    as InstanceOf['Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::ImportIssueModelMetadata'];

coerce 'ImportIssueModelMetadata',
    from HashRef, via { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::ImportIssueModelMetadata'->new($_) };

declare 'RepeatedImportIssueModelMetadata',
    as ArrayRef[ImportIssueModelMetadata()];

coerce 'RepeatedImportIssueModelMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::ImportIssueModelMetadata'->new($_) } @$_ ] };

declare 'MapStringImportIssueModelMetadata',
    as HashRef[ImportIssueModelMetadata()];

declare 'GetIssueRequest',
    as InstanceOf['Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::GetIssueRequest'];

coerce 'GetIssueRequest',
    from HashRef, via { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::GetIssueRequest'->new($_) };

declare 'RepeatedGetIssueRequest',
    as ArrayRef[GetIssueRequest()];

coerce 'RepeatedGetIssueRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::GetIssueRequest'->new($_) } @$_ ] };

declare 'MapStringGetIssueRequest',
    as HashRef[GetIssueRequest()];

declare 'ListIssuesRequest',
    as InstanceOf['Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::ListIssuesRequest'];

coerce 'ListIssuesRequest',
    from HashRef, via { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::ListIssuesRequest'->new($_) };

declare 'RepeatedListIssuesRequest',
    as ArrayRef[ListIssuesRequest()];

coerce 'RepeatedListIssuesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::ListIssuesRequest'->new($_) } @$_ ] };

declare 'MapStringListIssuesRequest',
    as HashRef[ListIssuesRequest()];

declare 'ListIssuesResponse',
    as InstanceOf['Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::ListIssuesResponse'];

coerce 'ListIssuesResponse',
    from HashRef, via { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::ListIssuesResponse'->new($_) };

declare 'RepeatedListIssuesResponse',
    as ArrayRef[ListIssuesResponse()];

coerce 'RepeatedListIssuesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::ListIssuesResponse'->new($_) } @$_ ] };

declare 'MapStringListIssuesResponse',
    as HashRef[ListIssuesResponse()];

declare 'UpdateIssueRequest',
    as InstanceOf['Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::UpdateIssueRequest'];

coerce 'UpdateIssueRequest',
    from HashRef, via { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::UpdateIssueRequest'->new($_) };

declare 'RepeatedUpdateIssueRequest',
    as ArrayRef[UpdateIssueRequest()];

coerce 'RepeatedUpdateIssueRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::UpdateIssueRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateIssueRequest',
    as HashRef[UpdateIssueRequest()];

declare 'DeleteIssueRequest',
    as InstanceOf['Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::DeleteIssueRequest'];

coerce 'DeleteIssueRequest',
    from HashRef, via { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::DeleteIssueRequest'->new($_) };

declare 'RepeatedDeleteIssueRequest',
    as ArrayRef[DeleteIssueRequest()];

coerce 'RepeatedDeleteIssueRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::DeleteIssueRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteIssueRequest',
    as HashRef[DeleteIssueRequest()];

declare 'CalculateIssueModelStatsRequest',
    as InstanceOf['Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::CalculateIssueModelStatsRequest'];

coerce 'CalculateIssueModelStatsRequest',
    from HashRef, via { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::CalculateIssueModelStatsRequest'->new($_) };

declare 'RepeatedCalculateIssueModelStatsRequest',
    as ArrayRef[CalculateIssueModelStatsRequest()];

coerce 'RepeatedCalculateIssueModelStatsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::CalculateIssueModelStatsRequest'->new($_) } @$_ ] };

declare 'MapStringCalculateIssueModelStatsRequest',
    as HashRef[CalculateIssueModelStatsRequest()];

declare 'CalculateIssueModelStatsResponse',
    as InstanceOf['Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::CalculateIssueModelStatsResponse'];

coerce 'CalculateIssueModelStatsResponse',
    from HashRef, via { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::CalculateIssueModelStatsResponse'->new($_) };

declare 'RepeatedCalculateIssueModelStatsResponse',
    as ArrayRef[CalculateIssueModelStatsResponse()];

coerce 'RepeatedCalculateIssueModelStatsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::CalculateIssueModelStatsResponse'->new($_) } @$_ ] };

declare 'MapStringCalculateIssueModelStatsResponse',
    as HashRef[CalculateIssueModelStatsResponse()];

declare 'CreatePhraseMatcherRequest',
    as InstanceOf['Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::CreatePhraseMatcherRequest'];

coerce 'CreatePhraseMatcherRequest',
    from HashRef, via { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::CreatePhraseMatcherRequest'->new($_) };

declare 'RepeatedCreatePhraseMatcherRequest',
    as ArrayRef[CreatePhraseMatcherRequest()];

coerce 'RepeatedCreatePhraseMatcherRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::CreatePhraseMatcherRequest'->new($_) } @$_ ] };

declare 'MapStringCreatePhraseMatcherRequest',
    as HashRef[CreatePhraseMatcherRequest()];

declare 'ListPhraseMatchersRequest',
    as InstanceOf['Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::ListPhraseMatchersRequest'];

coerce 'ListPhraseMatchersRequest',
    from HashRef, via { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::ListPhraseMatchersRequest'->new($_) };

declare 'RepeatedListPhraseMatchersRequest',
    as ArrayRef[ListPhraseMatchersRequest()];

coerce 'RepeatedListPhraseMatchersRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::ListPhraseMatchersRequest'->new($_) } @$_ ] };

declare 'MapStringListPhraseMatchersRequest',
    as HashRef[ListPhraseMatchersRequest()];

declare 'ListPhraseMatchersResponse',
    as InstanceOf['Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::ListPhraseMatchersResponse'];

coerce 'ListPhraseMatchersResponse',
    from HashRef, via { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::ListPhraseMatchersResponse'->new($_) };

declare 'RepeatedListPhraseMatchersResponse',
    as ArrayRef[ListPhraseMatchersResponse()];

coerce 'RepeatedListPhraseMatchersResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::ListPhraseMatchersResponse'->new($_) } @$_ ] };

declare 'MapStringListPhraseMatchersResponse',
    as HashRef[ListPhraseMatchersResponse()];

declare 'GetPhraseMatcherRequest',
    as InstanceOf['Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::GetPhraseMatcherRequest'];

coerce 'GetPhraseMatcherRequest',
    from HashRef, via { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::GetPhraseMatcherRequest'->new($_) };

declare 'RepeatedGetPhraseMatcherRequest',
    as ArrayRef[GetPhraseMatcherRequest()];

coerce 'RepeatedGetPhraseMatcherRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::GetPhraseMatcherRequest'->new($_) } @$_ ] };

declare 'MapStringGetPhraseMatcherRequest',
    as HashRef[GetPhraseMatcherRequest()];

declare 'DeletePhraseMatcherRequest',
    as InstanceOf['Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::DeletePhraseMatcherRequest'];

coerce 'DeletePhraseMatcherRequest',
    from HashRef, via { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::DeletePhraseMatcherRequest'->new($_) };

declare 'RepeatedDeletePhraseMatcherRequest',
    as ArrayRef[DeletePhraseMatcherRequest()];

coerce 'RepeatedDeletePhraseMatcherRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::DeletePhraseMatcherRequest'->new($_) } @$_ ] };

declare 'MapStringDeletePhraseMatcherRequest',
    as HashRef[DeletePhraseMatcherRequest()];

declare 'UpdatePhraseMatcherRequest',
    as InstanceOf['Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::UpdatePhraseMatcherRequest'];

coerce 'UpdatePhraseMatcherRequest',
    from HashRef, via { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::UpdatePhraseMatcherRequest'->new($_) };

declare 'RepeatedUpdatePhraseMatcherRequest',
    as ArrayRef[UpdatePhraseMatcherRequest()];

coerce 'RepeatedUpdatePhraseMatcherRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::UpdatePhraseMatcherRequest'->new($_) } @$_ ] };

declare 'MapStringUpdatePhraseMatcherRequest',
    as HashRef[UpdatePhraseMatcherRequest()];

declare 'GetSettingsRequest',
    as InstanceOf['Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::GetSettingsRequest'];

coerce 'GetSettingsRequest',
    from HashRef, via { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::GetSettingsRequest'->new($_) };

declare 'RepeatedGetSettingsRequest',
    as ArrayRef[GetSettingsRequest()];

coerce 'RepeatedGetSettingsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::GetSettingsRequest'->new($_) } @$_ ] };

declare 'MapStringGetSettingsRequest',
    as HashRef[GetSettingsRequest()];

declare 'UpdateSettingsRequest',
    as InstanceOf['Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::UpdateSettingsRequest'];

coerce 'UpdateSettingsRequest',
    from HashRef, via { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::UpdateSettingsRequest'->new($_) };

declare 'RepeatedUpdateSettingsRequest',
    as ArrayRef[UpdateSettingsRequest()];

coerce 'RepeatedUpdateSettingsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::UpdateSettingsRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateSettingsRequest',
    as HashRef[UpdateSettingsRequest()];

declare 'CreateAnalysisRuleRequest',
    as InstanceOf['Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::CreateAnalysisRuleRequest'];

coerce 'CreateAnalysisRuleRequest',
    from HashRef, via { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::CreateAnalysisRuleRequest'->new($_) };

declare 'RepeatedCreateAnalysisRuleRequest',
    as ArrayRef[CreateAnalysisRuleRequest()];

coerce 'RepeatedCreateAnalysisRuleRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::CreateAnalysisRuleRequest'->new($_) } @$_ ] };

declare 'MapStringCreateAnalysisRuleRequest',
    as HashRef[CreateAnalysisRuleRequest()];

declare 'GetAnalysisRuleRequest',
    as InstanceOf['Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::GetAnalysisRuleRequest'];

coerce 'GetAnalysisRuleRequest',
    from HashRef, via { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::GetAnalysisRuleRequest'->new($_) };

declare 'RepeatedGetAnalysisRuleRequest',
    as ArrayRef[GetAnalysisRuleRequest()];

coerce 'RepeatedGetAnalysisRuleRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::GetAnalysisRuleRequest'->new($_) } @$_ ] };

declare 'MapStringGetAnalysisRuleRequest',
    as HashRef[GetAnalysisRuleRequest()];

declare 'UpdateAnalysisRuleRequest',
    as InstanceOf['Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::UpdateAnalysisRuleRequest'];

coerce 'UpdateAnalysisRuleRequest',
    from HashRef, via { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::UpdateAnalysisRuleRequest'->new($_) };

declare 'RepeatedUpdateAnalysisRuleRequest',
    as ArrayRef[UpdateAnalysisRuleRequest()];

coerce 'RepeatedUpdateAnalysisRuleRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::UpdateAnalysisRuleRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateAnalysisRuleRequest',
    as HashRef[UpdateAnalysisRuleRequest()];

declare 'DeleteAnalysisRuleRequest',
    as InstanceOf['Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::DeleteAnalysisRuleRequest'];

coerce 'DeleteAnalysisRuleRequest',
    from HashRef, via { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::DeleteAnalysisRuleRequest'->new($_) };

declare 'RepeatedDeleteAnalysisRuleRequest',
    as ArrayRef[DeleteAnalysisRuleRequest()];

coerce 'RepeatedDeleteAnalysisRuleRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::DeleteAnalysisRuleRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteAnalysisRuleRequest',
    as HashRef[DeleteAnalysisRuleRequest()];

declare 'ListAnalysisRulesRequest',
    as InstanceOf['Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::ListAnalysisRulesRequest'];

coerce 'ListAnalysisRulesRequest',
    from HashRef, via { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::ListAnalysisRulesRequest'->new($_) };

declare 'RepeatedListAnalysisRulesRequest',
    as ArrayRef[ListAnalysisRulesRequest()];

coerce 'RepeatedListAnalysisRulesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::ListAnalysisRulesRequest'->new($_) } @$_ ] };

declare 'MapStringListAnalysisRulesRequest',
    as HashRef[ListAnalysisRulesRequest()];

declare 'ListAnalysisRulesResponse',
    as InstanceOf['Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::ListAnalysisRulesResponse'];

coerce 'ListAnalysisRulesResponse',
    from HashRef, via { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::ListAnalysisRulesResponse'->new($_) };

declare 'RepeatedListAnalysisRulesResponse',
    as ArrayRef[ListAnalysisRulesResponse()];

coerce 'RepeatedListAnalysisRulesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::ListAnalysisRulesResponse'->new($_) } @$_ ] };

declare 'MapStringListAnalysisRulesResponse',
    as HashRef[ListAnalysisRulesResponse()];

declare 'GetEncryptionSpecRequest',
    as InstanceOf['Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::GetEncryptionSpecRequest'];

coerce 'GetEncryptionSpecRequest',
    from HashRef, via { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::GetEncryptionSpecRequest'->new($_) };

declare 'RepeatedGetEncryptionSpecRequest',
    as ArrayRef[GetEncryptionSpecRequest()];

coerce 'RepeatedGetEncryptionSpecRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::GetEncryptionSpecRequest'->new($_) } @$_ ] };

declare 'MapStringGetEncryptionSpecRequest',
    as HashRef[GetEncryptionSpecRequest()];

declare 'InitializeEncryptionSpecRequest',
    as InstanceOf['Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::InitializeEncryptionSpecRequest'];

coerce 'InitializeEncryptionSpecRequest',
    from HashRef, via { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::InitializeEncryptionSpecRequest'->new($_) };

declare 'RepeatedInitializeEncryptionSpecRequest',
    as ArrayRef[InitializeEncryptionSpecRequest()];

coerce 'RepeatedInitializeEncryptionSpecRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::InitializeEncryptionSpecRequest'->new($_) } @$_ ] };

declare 'MapStringInitializeEncryptionSpecRequest',
    as HashRef[InitializeEncryptionSpecRequest()];

declare 'InitializeEncryptionSpecResponse',
    as InstanceOf['Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::InitializeEncryptionSpecResponse'];

coerce 'InitializeEncryptionSpecResponse',
    from HashRef, via { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::InitializeEncryptionSpecResponse'->new($_) };

declare 'RepeatedInitializeEncryptionSpecResponse',
    as ArrayRef[InitializeEncryptionSpecResponse()];

coerce 'RepeatedInitializeEncryptionSpecResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::InitializeEncryptionSpecResponse'->new($_) } @$_ ] };

declare 'MapStringInitializeEncryptionSpecResponse',
    as HashRef[InitializeEncryptionSpecResponse()];

declare 'InitializeEncryptionSpecMetadata',
    as InstanceOf['Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::InitializeEncryptionSpecMetadata'];

coerce 'InitializeEncryptionSpecMetadata',
    from HashRef, via { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::InitializeEncryptionSpecMetadata'->new($_) };

declare 'RepeatedInitializeEncryptionSpecMetadata',
    as ArrayRef[InitializeEncryptionSpecMetadata()];

coerce 'RepeatedInitializeEncryptionSpecMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::InitializeEncryptionSpecMetadata'->new($_) } @$_ ] };

declare 'MapStringInitializeEncryptionSpecMetadata',
    as HashRef[InitializeEncryptionSpecMetadata()];

declare 'CreateViewRequest',
    as InstanceOf['Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::CreateViewRequest'];

coerce 'CreateViewRequest',
    from HashRef, via { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::CreateViewRequest'->new($_) };

declare 'RepeatedCreateViewRequest',
    as ArrayRef[CreateViewRequest()];

coerce 'RepeatedCreateViewRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::CreateViewRequest'->new($_) } @$_ ] };

declare 'MapStringCreateViewRequest',
    as HashRef[CreateViewRequest()];

declare 'GetViewRequest',
    as InstanceOf['Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::GetViewRequest'];

coerce 'GetViewRequest',
    from HashRef, via { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::GetViewRequest'->new($_) };

declare 'RepeatedGetViewRequest',
    as ArrayRef[GetViewRequest()];

coerce 'RepeatedGetViewRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::GetViewRequest'->new($_) } @$_ ] };

declare 'MapStringGetViewRequest',
    as HashRef[GetViewRequest()];

declare 'ListViewsRequest',
    as InstanceOf['Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::ListViewsRequest'];

coerce 'ListViewsRequest',
    from HashRef, via { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::ListViewsRequest'->new($_) };

declare 'RepeatedListViewsRequest',
    as ArrayRef[ListViewsRequest()];

coerce 'RepeatedListViewsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::ListViewsRequest'->new($_) } @$_ ] };

declare 'MapStringListViewsRequest',
    as HashRef[ListViewsRequest()];

declare 'ListViewsResponse',
    as InstanceOf['Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::ListViewsResponse'];

coerce 'ListViewsResponse',
    from HashRef, via { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::ListViewsResponse'->new($_) };

declare 'RepeatedListViewsResponse',
    as ArrayRef[ListViewsResponse()];

coerce 'RepeatedListViewsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::ListViewsResponse'->new($_) } @$_ ] };

declare 'MapStringListViewsResponse',
    as HashRef[ListViewsResponse()];

declare 'UpdateViewRequest',
    as InstanceOf['Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::UpdateViewRequest'];

coerce 'UpdateViewRequest',
    from HashRef, via { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::UpdateViewRequest'->new($_) };

declare 'RepeatedUpdateViewRequest',
    as ArrayRef[UpdateViewRequest()];

coerce 'RepeatedUpdateViewRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::UpdateViewRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateViewRequest',
    as HashRef[UpdateViewRequest()];

declare 'DeleteViewRequest',
    as InstanceOf['Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::DeleteViewRequest'];

coerce 'DeleteViewRequest',
    from HashRef, via { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::DeleteViewRequest'->new($_) };

declare 'RepeatedDeleteViewRequest',
    as ArrayRef[DeleteViewRequest()];

coerce 'RepeatedDeleteViewRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::DeleteViewRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteViewRequest',
    as HashRef[DeleteViewRequest()];

declare 'Dimension',
    as InstanceOf['Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::Dimension'];

coerce 'Dimension',
    from HashRef, via { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::Dimension'->new($_) };

declare 'RepeatedDimension',
    as ArrayRef[Dimension()];

coerce 'RepeatedDimension',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::Dimension'->new($_) } @$_ ] };

declare 'MapStringDimension',
    as HashRef[Dimension()];

declare 'DimensionKey',
    as (Int | Str);

declare 'IssueDimensionMetadata',
    as InstanceOf['Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::Dimension::IssueDimensionMetadata'];

coerce 'IssueDimensionMetadata',
    from HashRef, via { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::Dimension::IssueDimensionMetadata'->new($_) };

declare 'RepeatedIssueDimensionMetadata',
    as ArrayRef[IssueDimensionMetadata()];

coerce 'RepeatedIssueDimensionMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::Dimension::IssueDimensionMetadata'->new($_) } @$_ ] };

declare 'MapStringIssueDimensionMetadata',
    as HashRef[IssueDimensionMetadata()];

declare 'AgentDimensionMetadata',
    as InstanceOf['Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::Dimension::AgentDimensionMetadata'];

coerce 'AgentDimensionMetadata',
    from HashRef, via { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::Dimension::AgentDimensionMetadata'->new($_) };

declare 'RepeatedAgentDimensionMetadata',
    as ArrayRef[AgentDimensionMetadata()];

coerce 'RepeatedAgentDimensionMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::Dimension::AgentDimensionMetadata'->new($_) } @$_ ] };

declare 'MapStringAgentDimensionMetadata',
    as HashRef[AgentDimensionMetadata()];

declare 'QaQuestionDimensionMetadata',
    as InstanceOf['Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::Dimension::QaQuestionDimensionMetadata'];

coerce 'QaQuestionDimensionMetadata',
    from HashRef, via { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::Dimension::QaQuestionDimensionMetadata'->new($_) };

declare 'RepeatedQaQuestionDimensionMetadata',
    as ArrayRef[QaQuestionDimensionMetadata()];

coerce 'RepeatedQaQuestionDimensionMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::Dimension::QaQuestionDimensionMetadata'->new($_) } @$_ ] };

declare 'MapStringQaQuestionDimensionMetadata',
    as HashRef[QaQuestionDimensionMetadata()];

declare 'QaQuestionAnswerDimensionMetadata',
    as InstanceOf['Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::Dimension::QaQuestionAnswerDimensionMetadata'];

coerce 'QaQuestionAnswerDimensionMetadata',
    from HashRef, via { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::Dimension::QaQuestionAnswerDimensionMetadata'->new($_) };

declare 'RepeatedQaQuestionAnswerDimensionMetadata',
    as ArrayRef[QaQuestionAnswerDimensionMetadata()];

coerce 'RepeatedQaQuestionAnswerDimensionMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::Dimension::QaQuestionAnswerDimensionMetadata'->new($_) } @$_ ] };

declare 'MapStringQaQuestionAnswerDimensionMetadata',
    as HashRef[QaQuestionAnswerDimensionMetadata()];

declare 'QueryMetricsRequest',
    as InstanceOf['Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::QueryMetricsRequest'];

coerce 'QueryMetricsRequest',
    from HashRef, via { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::QueryMetricsRequest'->new($_) };

declare 'RepeatedQueryMetricsRequest',
    as ArrayRef[QueryMetricsRequest()];

coerce 'RepeatedQueryMetricsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::QueryMetricsRequest'->new($_) } @$_ ] };

declare 'MapStringQueryMetricsRequest',
    as HashRef[QueryMetricsRequest()];

declare 'TimeGranularity',
    as (Int | Str);

declare 'QueryMetricsResponse',
    as InstanceOf['Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::QueryMetricsResponse'];

coerce 'QueryMetricsResponse',
    from HashRef, via { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::QueryMetricsResponse'->new($_) };

declare 'RepeatedQueryMetricsResponse',
    as ArrayRef[QueryMetricsResponse()];

coerce 'RepeatedQueryMetricsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::QueryMetricsResponse'->new($_) } @$_ ] };

declare 'MapStringQueryMetricsResponse',
    as HashRef[QueryMetricsResponse()];

declare 'Slice',
    as InstanceOf['Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::QueryMetricsResponse::Slice'];

coerce 'Slice',
    from HashRef, via { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::QueryMetricsResponse::Slice'->new($_) };

declare 'RepeatedSlice',
    as ArrayRef[Slice()];

coerce 'RepeatedSlice',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::QueryMetricsResponse::Slice'->new($_) } @$_ ] };

declare 'MapStringSlice',
    as HashRef[Slice()];

declare 'DataPoint',
    as InstanceOf['Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::QueryMetricsResponse::Slice::DataPoint'];

coerce 'DataPoint',
    from HashRef, via { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::QueryMetricsResponse::Slice::DataPoint'->new($_) };

declare 'RepeatedDataPoint',
    as ArrayRef[DataPoint()];

coerce 'RepeatedDataPoint',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::QueryMetricsResponse::Slice::DataPoint'->new($_) } @$_ ] };

declare 'MapStringDataPoint',
    as HashRef[DataPoint()];

declare 'ConversationMeasure',
    as InstanceOf['Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::QueryMetricsResponse::Slice::DataPoint::ConversationMeasure'];

coerce 'ConversationMeasure',
    from HashRef, via { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::QueryMetricsResponse::Slice::DataPoint::ConversationMeasure'->new($_) };

declare 'RepeatedConversationMeasure',
    as ArrayRef[ConversationMeasure()];

coerce 'RepeatedConversationMeasure',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::QueryMetricsResponse::Slice::DataPoint::ConversationMeasure'->new($_) } @$_ ] };

declare 'MapStringConversationMeasure',
    as HashRef[ConversationMeasure()];

declare 'QaTagScore',
    as InstanceOf['Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::QueryMetricsResponse::Slice::DataPoint::ConversationMeasure::QaTagScore'];

coerce 'QaTagScore',
    from HashRef, via { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::QueryMetricsResponse::Slice::DataPoint::ConversationMeasure::QaTagScore'->new($_) };

declare 'RepeatedQaTagScore',
    as ArrayRef[QaTagScore()];

coerce 'RepeatedQaTagScore',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::QueryMetricsResponse::Slice::DataPoint::ConversationMeasure::QaTagScore'->new($_) } @$_ ] };

declare 'MapStringQaTagScore',
    as HashRef[QaTagScore()];

declare 'TimeSeries',
    as InstanceOf['Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::QueryMetricsResponse::Slice::TimeSeries'];

coerce 'TimeSeries',
    from HashRef, via { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::QueryMetricsResponse::Slice::TimeSeries'->new($_) };

declare 'RepeatedTimeSeries',
    as ArrayRef[TimeSeries()];

coerce 'RepeatedTimeSeries',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::QueryMetricsResponse::Slice::TimeSeries'->new($_) } @$_ ] };

declare 'MapStringTimeSeries',
    as HashRef[TimeSeries()];

declare 'QueryMetricsMetadata',
    as InstanceOf['Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::QueryMetricsMetadata'];

coerce 'QueryMetricsMetadata',
    from HashRef, via { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::QueryMetricsMetadata'->new($_) };

declare 'RepeatedQueryMetricsMetadata',
    as ArrayRef[QueryMetricsMetadata()];

coerce 'RepeatedQueryMetricsMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::QueryMetricsMetadata'->new($_) } @$_ ] };

declare 'MapStringQueryMetricsMetadata',
    as HashRef[QueryMetricsMetadata()];

declare 'CreateQaQuestionRequest',
    as InstanceOf['Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::CreateQaQuestionRequest'];

coerce 'CreateQaQuestionRequest',
    from HashRef, via { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::CreateQaQuestionRequest'->new($_) };

declare 'RepeatedCreateQaQuestionRequest',
    as ArrayRef[CreateQaQuestionRequest()];

coerce 'RepeatedCreateQaQuestionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::CreateQaQuestionRequest'->new($_) } @$_ ] };

declare 'MapStringCreateQaQuestionRequest',
    as HashRef[CreateQaQuestionRequest()];

declare 'GetQaQuestionRequest',
    as InstanceOf['Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::GetQaQuestionRequest'];

coerce 'GetQaQuestionRequest',
    from HashRef, via { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::GetQaQuestionRequest'->new($_) };

declare 'RepeatedGetQaQuestionRequest',
    as ArrayRef[GetQaQuestionRequest()];

coerce 'RepeatedGetQaQuestionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::GetQaQuestionRequest'->new($_) } @$_ ] };

declare 'MapStringGetQaQuestionRequest',
    as HashRef[GetQaQuestionRequest()];

declare 'ListQaQuestionsRequest',
    as InstanceOf['Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::ListQaQuestionsRequest'];

coerce 'ListQaQuestionsRequest',
    from HashRef, via { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::ListQaQuestionsRequest'->new($_) };

declare 'RepeatedListQaQuestionsRequest',
    as ArrayRef[ListQaQuestionsRequest()];

coerce 'RepeatedListQaQuestionsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::ListQaQuestionsRequest'->new($_) } @$_ ] };

declare 'MapStringListQaQuestionsRequest',
    as HashRef[ListQaQuestionsRequest()];

declare 'ListQaQuestionsResponse',
    as InstanceOf['Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::ListQaQuestionsResponse'];

coerce 'ListQaQuestionsResponse',
    from HashRef, via { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::ListQaQuestionsResponse'->new($_) };

declare 'RepeatedListQaQuestionsResponse',
    as ArrayRef[ListQaQuestionsResponse()];

coerce 'RepeatedListQaQuestionsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::ListQaQuestionsResponse'->new($_) } @$_ ] };

declare 'MapStringListQaQuestionsResponse',
    as HashRef[ListQaQuestionsResponse()];

declare 'UpdateQaQuestionRequest',
    as InstanceOf['Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::UpdateQaQuestionRequest'];

coerce 'UpdateQaQuestionRequest',
    from HashRef, via { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::UpdateQaQuestionRequest'->new($_) };

declare 'RepeatedUpdateQaQuestionRequest',
    as ArrayRef[UpdateQaQuestionRequest()];

coerce 'RepeatedUpdateQaQuestionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::UpdateQaQuestionRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateQaQuestionRequest',
    as HashRef[UpdateQaQuestionRequest()];

declare 'DeleteQaQuestionRequest',
    as InstanceOf['Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::DeleteQaQuestionRequest'];

coerce 'DeleteQaQuestionRequest',
    from HashRef, via { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::DeleteQaQuestionRequest'->new($_) };

declare 'RepeatedDeleteQaQuestionRequest',
    as ArrayRef[DeleteQaQuestionRequest()];

coerce 'RepeatedDeleteQaQuestionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::DeleteQaQuestionRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteQaQuestionRequest',
    as HashRef[DeleteQaQuestionRequest()];

declare 'CreateQaScorecardRequest',
    as InstanceOf['Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::CreateQaScorecardRequest'];

coerce 'CreateQaScorecardRequest',
    from HashRef, via { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::CreateQaScorecardRequest'->new($_) };

declare 'RepeatedCreateQaScorecardRequest',
    as ArrayRef[CreateQaScorecardRequest()];

coerce 'RepeatedCreateQaScorecardRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::CreateQaScorecardRequest'->new($_) } @$_ ] };

declare 'MapStringCreateQaScorecardRequest',
    as HashRef[CreateQaScorecardRequest()];

declare 'GetQaScorecardRequest',
    as InstanceOf['Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::GetQaScorecardRequest'];

coerce 'GetQaScorecardRequest',
    from HashRef, via { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::GetQaScorecardRequest'->new($_) };

declare 'RepeatedGetQaScorecardRequest',
    as ArrayRef[GetQaScorecardRequest()];

coerce 'RepeatedGetQaScorecardRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::GetQaScorecardRequest'->new($_) } @$_ ] };

declare 'MapStringGetQaScorecardRequest',
    as HashRef[GetQaScorecardRequest()];

declare 'UpdateQaScorecardRequest',
    as InstanceOf['Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::UpdateQaScorecardRequest'];

coerce 'UpdateQaScorecardRequest',
    from HashRef, via { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::UpdateQaScorecardRequest'->new($_) };

declare 'RepeatedUpdateQaScorecardRequest',
    as ArrayRef[UpdateQaScorecardRequest()];

coerce 'RepeatedUpdateQaScorecardRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::UpdateQaScorecardRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateQaScorecardRequest',
    as HashRef[UpdateQaScorecardRequest()];

declare 'DeleteQaScorecardRequest',
    as InstanceOf['Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::DeleteQaScorecardRequest'];

coerce 'DeleteQaScorecardRequest',
    from HashRef, via { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::DeleteQaScorecardRequest'->new($_) };

declare 'RepeatedDeleteQaScorecardRequest',
    as ArrayRef[DeleteQaScorecardRequest()];

coerce 'RepeatedDeleteQaScorecardRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::DeleteQaScorecardRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteQaScorecardRequest',
    as HashRef[DeleteQaScorecardRequest()];

declare 'CreateQaScorecardRevisionRequest',
    as InstanceOf['Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::CreateQaScorecardRevisionRequest'];

coerce 'CreateQaScorecardRevisionRequest',
    from HashRef, via { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::CreateQaScorecardRevisionRequest'->new($_) };

declare 'RepeatedCreateQaScorecardRevisionRequest',
    as ArrayRef[CreateQaScorecardRevisionRequest()];

coerce 'RepeatedCreateQaScorecardRevisionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::CreateQaScorecardRevisionRequest'->new($_) } @$_ ] };

declare 'MapStringCreateQaScorecardRevisionRequest',
    as HashRef[CreateQaScorecardRevisionRequest()];

declare 'GetQaScorecardRevisionRequest',
    as InstanceOf['Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::GetQaScorecardRevisionRequest'];

coerce 'GetQaScorecardRevisionRequest',
    from HashRef, via { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::GetQaScorecardRevisionRequest'->new($_) };

declare 'RepeatedGetQaScorecardRevisionRequest',
    as ArrayRef[GetQaScorecardRevisionRequest()];

coerce 'RepeatedGetQaScorecardRevisionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::GetQaScorecardRevisionRequest'->new($_) } @$_ ] };

declare 'MapStringGetQaScorecardRevisionRequest',
    as HashRef[GetQaScorecardRevisionRequest()];

declare 'TuneQaScorecardRevisionRequest',
    as InstanceOf['Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::TuneQaScorecardRevisionRequest'];

coerce 'TuneQaScorecardRevisionRequest',
    from HashRef, via { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::TuneQaScorecardRevisionRequest'->new($_) };

declare 'RepeatedTuneQaScorecardRevisionRequest',
    as ArrayRef[TuneQaScorecardRevisionRequest()];

coerce 'RepeatedTuneQaScorecardRevisionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::TuneQaScorecardRevisionRequest'->new($_) } @$_ ] };

declare 'MapStringTuneQaScorecardRevisionRequest',
    as HashRef[TuneQaScorecardRevisionRequest()];

declare 'TuneQaScorecardRevisionResponse',
    as InstanceOf['Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::TuneQaScorecardRevisionResponse'];

coerce 'TuneQaScorecardRevisionResponse',
    from HashRef, via { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::TuneQaScorecardRevisionResponse'->new($_) };

declare 'RepeatedTuneQaScorecardRevisionResponse',
    as ArrayRef[TuneQaScorecardRevisionResponse()];

coerce 'RepeatedTuneQaScorecardRevisionResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::TuneQaScorecardRevisionResponse'->new($_) } @$_ ] };

declare 'MapStringTuneQaScorecardRevisionResponse',
    as HashRef[TuneQaScorecardRevisionResponse()];

declare 'TuneQaScorecardRevisionMetadata',
    as InstanceOf['Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::TuneQaScorecardRevisionMetadata'];

coerce 'TuneQaScorecardRevisionMetadata',
    from HashRef, via { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::TuneQaScorecardRevisionMetadata'->new($_) };

declare 'RepeatedTuneQaScorecardRevisionMetadata',
    as ArrayRef[TuneQaScorecardRevisionMetadata()];

coerce 'RepeatedTuneQaScorecardRevisionMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::TuneQaScorecardRevisionMetadata'->new($_) } @$_ ] };

declare 'MapStringTuneQaScorecardRevisionMetadata',
    as HashRef[TuneQaScorecardRevisionMetadata()];

declare 'QaQuestionDatasetValidationResult',
    as InstanceOf['Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::TuneQaScorecardRevisionMetadata::QaQuestionDatasetValidationResult'];

coerce 'QaQuestionDatasetValidationResult',
    from HashRef, via { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::TuneQaScorecardRevisionMetadata::QaQuestionDatasetValidationResult'->new($_) };

declare 'RepeatedQaQuestionDatasetValidationResult',
    as ArrayRef[QaQuestionDatasetValidationResult()];

coerce 'RepeatedQaQuestionDatasetValidationResult',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::TuneQaScorecardRevisionMetadata::QaQuestionDatasetValidationResult'->new($_) } @$_ ] };

declare 'MapStringQaQuestionDatasetValidationResult',
    as HashRef[QaQuestionDatasetValidationResult()];

declare 'QaQuestionDatasetTuningMetrics',
    as InstanceOf['Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::TuneQaScorecardRevisionMetadata::QaQuestionDatasetTuningMetrics'];

coerce 'QaQuestionDatasetTuningMetrics',
    from HashRef, via { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::TuneQaScorecardRevisionMetadata::QaQuestionDatasetTuningMetrics'->new($_) };

declare 'RepeatedQaQuestionDatasetTuningMetrics',
    as ArrayRef[QaQuestionDatasetTuningMetrics()];

coerce 'RepeatedQaQuestionDatasetTuningMetrics',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::TuneQaScorecardRevisionMetadata::QaQuestionDatasetTuningMetrics'->new($_) } @$_ ] };

declare 'MapStringQaQuestionDatasetTuningMetrics',
    as HashRef[QaQuestionDatasetTuningMetrics()];

declare 'Metrics',
    as InstanceOf['Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::TuneQaScorecardRevisionMetadata::QaQuestionDatasetTuningMetrics::Metrics'];

coerce 'Metrics',
    from HashRef, via { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::TuneQaScorecardRevisionMetadata::QaQuestionDatasetTuningMetrics::Metrics'->new($_) };

declare 'RepeatedMetrics',
    as ArrayRef[Metrics()];

coerce 'RepeatedMetrics',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::TuneQaScorecardRevisionMetadata::QaQuestionDatasetTuningMetrics::Metrics'->new($_) } @$_ ] };

declare 'MapStringMetrics',
    as HashRef[Metrics()];

declare 'DeployQaScorecardRevisionRequest',
    as InstanceOf['Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::DeployQaScorecardRevisionRequest'];

coerce 'DeployQaScorecardRevisionRequest',
    from HashRef, via { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::DeployQaScorecardRevisionRequest'->new($_) };

declare 'RepeatedDeployQaScorecardRevisionRequest',
    as ArrayRef[DeployQaScorecardRevisionRequest()];

coerce 'RepeatedDeployQaScorecardRevisionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::DeployQaScorecardRevisionRequest'->new($_) } @$_ ] };

declare 'MapStringDeployQaScorecardRevisionRequest',
    as HashRef[DeployQaScorecardRevisionRequest()];

declare 'UndeployQaScorecardRevisionRequest',
    as InstanceOf['Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::UndeployQaScorecardRevisionRequest'];

coerce 'UndeployQaScorecardRevisionRequest',
    from HashRef, via { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::UndeployQaScorecardRevisionRequest'->new($_) };

declare 'RepeatedUndeployQaScorecardRevisionRequest',
    as ArrayRef[UndeployQaScorecardRevisionRequest()];

coerce 'RepeatedUndeployQaScorecardRevisionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::UndeployQaScorecardRevisionRequest'->new($_) } @$_ ] };

declare 'MapStringUndeployQaScorecardRevisionRequest',
    as HashRef[UndeployQaScorecardRevisionRequest()];

declare 'DeleteQaScorecardRevisionRequest',
    as InstanceOf['Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::DeleteQaScorecardRevisionRequest'];

coerce 'DeleteQaScorecardRevisionRequest',
    from HashRef, via { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::DeleteQaScorecardRevisionRequest'->new($_) };

declare 'RepeatedDeleteQaScorecardRevisionRequest',
    as ArrayRef[DeleteQaScorecardRevisionRequest()];

coerce 'RepeatedDeleteQaScorecardRevisionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::DeleteQaScorecardRevisionRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteQaScorecardRevisionRequest',
    as HashRef[DeleteQaScorecardRevisionRequest()];

declare 'ListQaScorecardsRequest',
    as InstanceOf['Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::ListQaScorecardsRequest'];

coerce 'ListQaScorecardsRequest',
    from HashRef, via { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::ListQaScorecardsRequest'->new($_) };

declare 'RepeatedListQaScorecardsRequest',
    as ArrayRef[ListQaScorecardsRequest()];

coerce 'RepeatedListQaScorecardsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::ListQaScorecardsRequest'->new($_) } @$_ ] };

declare 'MapStringListQaScorecardsRequest',
    as HashRef[ListQaScorecardsRequest()];

declare 'ListQaScorecardsResponse',
    as InstanceOf['Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::ListQaScorecardsResponse'];

coerce 'ListQaScorecardsResponse',
    from HashRef, via { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::ListQaScorecardsResponse'->new($_) };

declare 'RepeatedListQaScorecardsResponse',
    as ArrayRef[ListQaScorecardsResponse()];

coerce 'RepeatedListQaScorecardsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::ListQaScorecardsResponse'->new($_) } @$_ ] };

declare 'MapStringListQaScorecardsResponse',
    as HashRef[ListQaScorecardsResponse()];

declare 'ListQaScorecardRevisionsRequest',
    as InstanceOf['Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::ListQaScorecardRevisionsRequest'];

coerce 'ListQaScorecardRevisionsRequest',
    from HashRef, via { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::ListQaScorecardRevisionsRequest'->new($_) };

declare 'RepeatedListQaScorecardRevisionsRequest',
    as ArrayRef[ListQaScorecardRevisionsRequest()];

coerce 'RepeatedListQaScorecardRevisionsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::ListQaScorecardRevisionsRequest'->new($_) } @$_ ] };

declare 'MapStringListQaScorecardRevisionsRequest',
    as HashRef[ListQaScorecardRevisionsRequest()];

declare 'ListQaScorecardRevisionsResponse',
    as InstanceOf['Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::ListQaScorecardRevisionsResponse'];

coerce 'ListQaScorecardRevisionsResponse',
    from HashRef, via { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::ListQaScorecardRevisionsResponse'->new($_) };

declare 'RepeatedListQaScorecardRevisionsResponse',
    as ArrayRef[ListQaScorecardRevisionsResponse()];

coerce 'RepeatedListQaScorecardRevisionsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::ListQaScorecardRevisionsResponse'->new($_) } @$_ ] };

declare 'MapStringListQaScorecardRevisionsResponse',
    as HashRef[ListQaScorecardRevisionsResponse()];

declare 'CreateFeedbackLabelRequest',
    as InstanceOf['Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::CreateFeedbackLabelRequest'];

coerce 'CreateFeedbackLabelRequest',
    from HashRef, via { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::CreateFeedbackLabelRequest'->new($_) };

declare 'RepeatedCreateFeedbackLabelRequest',
    as ArrayRef[CreateFeedbackLabelRequest()];

coerce 'RepeatedCreateFeedbackLabelRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::CreateFeedbackLabelRequest'->new($_) } @$_ ] };

declare 'MapStringCreateFeedbackLabelRequest',
    as HashRef[CreateFeedbackLabelRequest()];

declare 'ListFeedbackLabelsRequest',
    as InstanceOf['Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::ListFeedbackLabelsRequest'];

coerce 'ListFeedbackLabelsRequest',
    from HashRef, via { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::ListFeedbackLabelsRequest'->new($_) };

declare 'RepeatedListFeedbackLabelsRequest',
    as ArrayRef[ListFeedbackLabelsRequest()];

coerce 'RepeatedListFeedbackLabelsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::ListFeedbackLabelsRequest'->new($_) } @$_ ] };

declare 'MapStringListFeedbackLabelsRequest',
    as HashRef[ListFeedbackLabelsRequest()];

declare 'ListFeedbackLabelsResponse',
    as InstanceOf['Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::ListFeedbackLabelsResponse'];

coerce 'ListFeedbackLabelsResponse',
    from HashRef, via { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::ListFeedbackLabelsResponse'->new($_) };

declare 'RepeatedListFeedbackLabelsResponse',
    as ArrayRef[ListFeedbackLabelsResponse()];

coerce 'RepeatedListFeedbackLabelsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::ListFeedbackLabelsResponse'->new($_) } @$_ ] };

declare 'MapStringListFeedbackLabelsResponse',
    as HashRef[ListFeedbackLabelsResponse()];

declare 'GetFeedbackLabelRequest',
    as InstanceOf['Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::GetFeedbackLabelRequest'];

coerce 'GetFeedbackLabelRequest',
    from HashRef, via { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::GetFeedbackLabelRequest'->new($_) };

declare 'RepeatedGetFeedbackLabelRequest',
    as ArrayRef[GetFeedbackLabelRequest()];

coerce 'RepeatedGetFeedbackLabelRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::GetFeedbackLabelRequest'->new($_) } @$_ ] };

declare 'MapStringGetFeedbackLabelRequest',
    as HashRef[GetFeedbackLabelRequest()];

declare 'UpdateFeedbackLabelRequest',
    as InstanceOf['Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::UpdateFeedbackLabelRequest'];

coerce 'UpdateFeedbackLabelRequest',
    from HashRef, via { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::UpdateFeedbackLabelRequest'->new($_) };

declare 'RepeatedUpdateFeedbackLabelRequest',
    as ArrayRef[UpdateFeedbackLabelRequest()];

coerce 'RepeatedUpdateFeedbackLabelRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::UpdateFeedbackLabelRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateFeedbackLabelRequest',
    as HashRef[UpdateFeedbackLabelRequest()];

declare 'DeleteFeedbackLabelRequest',
    as InstanceOf['Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::DeleteFeedbackLabelRequest'];

coerce 'DeleteFeedbackLabelRequest',
    from HashRef, via { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::DeleteFeedbackLabelRequest'->new($_) };

declare 'RepeatedDeleteFeedbackLabelRequest',
    as ArrayRef[DeleteFeedbackLabelRequest()];

coerce 'RepeatedDeleteFeedbackLabelRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::DeleteFeedbackLabelRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteFeedbackLabelRequest',
    as HashRef[DeleteFeedbackLabelRequest()];

declare 'ListAllFeedbackLabelsRequest',
    as InstanceOf['Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::ListAllFeedbackLabelsRequest'];

coerce 'ListAllFeedbackLabelsRequest',
    from HashRef, via { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::ListAllFeedbackLabelsRequest'->new($_) };

declare 'RepeatedListAllFeedbackLabelsRequest',
    as ArrayRef[ListAllFeedbackLabelsRequest()];

coerce 'RepeatedListAllFeedbackLabelsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::ListAllFeedbackLabelsRequest'->new($_) } @$_ ] };

declare 'MapStringListAllFeedbackLabelsRequest',
    as HashRef[ListAllFeedbackLabelsRequest()];

declare 'ListAllFeedbackLabelsResponse',
    as InstanceOf['Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::ListAllFeedbackLabelsResponse'];

coerce 'ListAllFeedbackLabelsResponse',
    from HashRef, via { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::ListAllFeedbackLabelsResponse'->new($_) };

declare 'RepeatedListAllFeedbackLabelsResponse',
    as ArrayRef[ListAllFeedbackLabelsResponse()];

coerce 'RepeatedListAllFeedbackLabelsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::ListAllFeedbackLabelsResponse'->new($_) } @$_ ] };

declare 'MapStringListAllFeedbackLabelsResponse',
    as HashRef[ListAllFeedbackLabelsResponse()];

declare 'BulkUploadFeedbackLabelsRequest',
    as InstanceOf['Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::BulkUploadFeedbackLabelsRequest'];

coerce 'BulkUploadFeedbackLabelsRequest',
    from HashRef, via { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::BulkUploadFeedbackLabelsRequest'->new($_) };

declare 'RepeatedBulkUploadFeedbackLabelsRequest',
    as ArrayRef[BulkUploadFeedbackLabelsRequest()];

coerce 'RepeatedBulkUploadFeedbackLabelsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::BulkUploadFeedbackLabelsRequest'->new($_) } @$_ ] };

declare 'MapStringBulkUploadFeedbackLabelsRequest',
    as HashRef[BulkUploadFeedbackLabelsRequest()];

declare 'GcsSource',
    as InstanceOf['Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::BulkUploadFeedbackLabelsRequest::GcsSource'];

coerce 'GcsSource',
    from HashRef, via { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::BulkUploadFeedbackLabelsRequest::GcsSource'->new($_) };

declare 'RepeatedGcsSource',
    as ArrayRef[GcsSource()];

coerce 'RepeatedGcsSource',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::BulkUploadFeedbackLabelsRequest::GcsSource'->new($_) } @$_ ] };

declare 'MapStringGcsSource',
    as HashRef[GcsSource()];

declare 'Format',
    as (Int | Str);

declare 'BulkUploadFeedbackLabelsResponse',
    as InstanceOf['Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::BulkUploadFeedbackLabelsResponse'];

coerce 'BulkUploadFeedbackLabelsResponse',
    from HashRef, via { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::BulkUploadFeedbackLabelsResponse'->new($_) };

declare 'RepeatedBulkUploadFeedbackLabelsResponse',
    as ArrayRef[BulkUploadFeedbackLabelsResponse()];

coerce 'RepeatedBulkUploadFeedbackLabelsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::BulkUploadFeedbackLabelsResponse'->new($_) } @$_ ] };

declare 'MapStringBulkUploadFeedbackLabelsResponse',
    as HashRef[BulkUploadFeedbackLabelsResponse()];

declare 'BulkUploadFeedbackLabelsMetadata',
    as InstanceOf['Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::BulkUploadFeedbackLabelsMetadata'];

coerce 'BulkUploadFeedbackLabelsMetadata',
    from HashRef, via { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::BulkUploadFeedbackLabelsMetadata'->new($_) };

declare 'RepeatedBulkUploadFeedbackLabelsMetadata',
    as ArrayRef[BulkUploadFeedbackLabelsMetadata()];

coerce 'RepeatedBulkUploadFeedbackLabelsMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::BulkUploadFeedbackLabelsMetadata'->new($_) } @$_ ] };

declare 'MapStringBulkUploadFeedbackLabelsMetadata',
    as HashRef[BulkUploadFeedbackLabelsMetadata()];

declare 'UploadStats',
    as InstanceOf['Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::BulkUploadFeedbackLabelsMetadata::UploadStats'];

coerce 'UploadStats',
    from HashRef, via { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::BulkUploadFeedbackLabelsMetadata::UploadStats'->new($_) };

declare 'RepeatedUploadStats',
    as ArrayRef[UploadStats()];

coerce 'RepeatedUploadStats',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::BulkUploadFeedbackLabelsMetadata::UploadStats'->new($_) } @$_ ] };

declare 'MapStringUploadStats',
    as HashRef[UploadStats()];

declare 'BulkDownloadFeedbackLabelsRequest',
    as InstanceOf['Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::BulkDownloadFeedbackLabelsRequest'];

coerce 'BulkDownloadFeedbackLabelsRequest',
    from HashRef, via { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::BulkDownloadFeedbackLabelsRequest'->new($_) };

declare 'RepeatedBulkDownloadFeedbackLabelsRequest',
    as ArrayRef[BulkDownloadFeedbackLabelsRequest()];

coerce 'RepeatedBulkDownloadFeedbackLabelsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::BulkDownloadFeedbackLabelsRequest'->new($_) } @$_ ] };

declare 'MapStringBulkDownloadFeedbackLabelsRequest',
    as HashRef[BulkDownloadFeedbackLabelsRequest()];

declare 'FeedbackLabelType',
    as (Int | Str);

declare 'GcsDestination',
    as InstanceOf['Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::BulkDownloadFeedbackLabelsRequest::GcsDestination'];

coerce 'GcsDestination',
    from HashRef, via { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::BulkDownloadFeedbackLabelsRequest::GcsDestination'->new($_) };

declare 'RepeatedGcsDestination',
    as ArrayRef[GcsDestination()];

coerce 'RepeatedGcsDestination',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::BulkDownloadFeedbackLabelsRequest::GcsDestination'->new($_) } @$_ ] };

declare 'MapStringGcsDestination',
    as HashRef[GcsDestination()];

declare 'Format',
    as (Int | Str);

declare 'BulkDownloadFeedbackLabelsResponse',
    as InstanceOf['Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::BulkDownloadFeedbackLabelsResponse'];

coerce 'BulkDownloadFeedbackLabelsResponse',
    from HashRef, via { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::BulkDownloadFeedbackLabelsResponse'->new($_) };

declare 'RepeatedBulkDownloadFeedbackLabelsResponse',
    as ArrayRef[BulkDownloadFeedbackLabelsResponse()];

coerce 'RepeatedBulkDownloadFeedbackLabelsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::BulkDownloadFeedbackLabelsResponse'->new($_) } @$_ ] };

declare 'MapStringBulkDownloadFeedbackLabelsResponse',
    as HashRef[BulkDownloadFeedbackLabelsResponse()];

declare 'BulkDownloadFeedbackLabelsMetadata',
    as InstanceOf['Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::BulkDownloadFeedbackLabelsMetadata'];

coerce 'BulkDownloadFeedbackLabelsMetadata',
    from HashRef, via { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::BulkDownloadFeedbackLabelsMetadata'->new($_) };

declare 'RepeatedBulkDownloadFeedbackLabelsMetadata',
    as ArrayRef[BulkDownloadFeedbackLabelsMetadata()];

coerce 'RepeatedBulkDownloadFeedbackLabelsMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::BulkDownloadFeedbackLabelsMetadata'->new($_) } @$_ ] };

declare 'MapStringBulkDownloadFeedbackLabelsMetadata',
    as HashRef[BulkDownloadFeedbackLabelsMetadata()];

declare 'DownloadStats',
    as InstanceOf['Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::BulkDownloadFeedbackLabelsMetadata::DownloadStats'];

coerce 'DownloadStats',
    from HashRef, via { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::BulkDownloadFeedbackLabelsMetadata::DownloadStats'->new($_) };

declare 'RepeatedDownloadStats',
    as ArrayRef[DownloadStats()];

coerce 'RepeatedDownloadStats',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::BulkDownloadFeedbackLabelsMetadata::DownloadStats'->new($_) } @$_ ] };

declare 'MapStringDownloadStats',
    as HashRef[DownloadStats()];

1;

__END__

=head1 NAME

Google::Cloud::Contactcenterinsights::V1::ContactCenterInsights::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
