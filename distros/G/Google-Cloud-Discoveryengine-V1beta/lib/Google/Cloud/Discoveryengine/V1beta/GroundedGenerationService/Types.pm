package Google::Cloud::Discoveryengine::V1beta::GroundedGenerationService::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'GroundedGenerationContent',
    as InstanceOf['Google::Cloud::Discoveryengine::V1beta::GroundedGenerationService::GroundedGenerationContent'];

coerce 'GroundedGenerationContent',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1beta::GroundedGenerationService::GroundedGenerationContent'->new($_) };

declare 'RepeatedGroundedGenerationContent',
    as ArrayRef[GroundedGenerationContent()];

coerce 'RepeatedGroundedGenerationContent',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1beta::GroundedGenerationService::GroundedGenerationContent'->new($_) } @$_ ] };

declare 'MapStringGroundedGenerationContent',
    as HashRef[GroundedGenerationContent()];

declare 'Part',
    as InstanceOf['Google::Cloud::Discoveryengine::V1beta::GroundedGenerationService::GroundedGenerationContent::Part'];

coerce 'Part',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1beta::GroundedGenerationService::GroundedGenerationContent::Part'->new($_) };

declare 'RepeatedPart',
    as ArrayRef[Part()];

coerce 'RepeatedPart',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1beta::GroundedGenerationService::GroundedGenerationContent::Part'->new($_) } @$_ ] };

declare 'MapStringPart',
    as HashRef[Part()];

declare 'GenerateGroundedContentRequest',
    as InstanceOf['Google::Cloud::Discoveryengine::V1beta::GroundedGenerationService::GenerateGroundedContentRequest'];

coerce 'GenerateGroundedContentRequest',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1beta::GroundedGenerationService::GenerateGroundedContentRequest'->new($_) };

declare 'RepeatedGenerateGroundedContentRequest',
    as ArrayRef[GenerateGroundedContentRequest()];

coerce 'RepeatedGenerateGroundedContentRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1beta::GroundedGenerationService::GenerateGroundedContentRequest'->new($_) } @$_ ] };

declare 'MapStringGenerateGroundedContentRequest',
    as HashRef[GenerateGroundedContentRequest()];

declare 'GenerationSpec',
    as InstanceOf['Google::Cloud::Discoveryengine::V1beta::GroundedGenerationService::GenerateGroundedContentRequest::GenerationSpec'];

coerce 'GenerationSpec',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1beta::GroundedGenerationService::GenerateGroundedContentRequest::GenerationSpec'->new($_) };

declare 'RepeatedGenerationSpec',
    as ArrayRef[GenerationSpec()];

coerce 'RepeatedGenerationSpec',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1beta::GroundedGenerationService::GenerateGroundedContentRequest::GenerationSpec'->new($_) } @$_ ] };

declare 'MapStringGenerationSpec',
    as HashRef[GenerationSpec()];

declare 'ProvisionedThroughputSetting',
    as (Int | Str);

declare 'DynamicRetrievalConfiguration',
    as InstanceOf['Google::Cloud::Discoveryengine::V1beta::GroundedGenerationService::GenerateGroundedContentRequest::DynamicRetrievalConfiguration'];

coerce 'DynamicRetrievalConfiguration',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1beta::GroundedGenerationService::GenerateGroundedContentRequest::DynamicRetrievalConfiguration'->new($_) };

declare 'RepeatedDynamicRetrievalConfiguration',
    as ArrayRef[DynamicRetrievalConfiguration()];

coerce 'RepeatedDynamicRetrievalConfiguration',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1beta::GroundedGenerationService::GenerateGroundedContentRequest::DynamicRetrievalConfiguration'->new($_) } @$_ ] };

declare 'MapStringDynamicRetrievalConfiguration',
    as HashRef[DynamicRetrievalConfiguration()];

declare 'DynamicRetrievalPredictor',
    as InstanceOf['Google::Cloud::Discoveryengine::V1beta::GroundedGenerationService::GenerateGroundedContentRequest::DynamicRetrievalConfiguration::DynamicRetrievalPredictor'];

coerce 'DynamicRetrievalPredictor',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1beta::GroundedGenerationService::GenerateGroundedContentRequest::DynamicRetrievalConfiguration::DynamicRetrievalPredictor'->new($_) };

declare 'RepeatedDynamicRetrievalPredictor',
    as ArrayRef[DynamicRetrievalPredictor()];

coerce 'RepeatedDynamicRetrievalPredictor',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1beta::GroundedGenerationService::GenerateGroundedContentRequest::DynamicRetrievalConfiguration::DynamicRetrievalPredictor'->new($_) } @$_ ] };

declare 'MapStringDynamicRetrievalPredictor',
    as HashRef[DynamicRetrievalPredictor()];

declare 'Version',
    as (Int | Str);

declare 'GroundingSource',
    as InstanceOf['Google::Cloud::Discoveryengine::V1beta::GroundedGenerationService::GenerateGroundedContentRequest::GroundingSource'];

coerce 'GroundingSource',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1beta::GroundedGenerationService::GenerateGroundedContentRequest::GroundingSource'->new($_) };

declare 'RepeatedGroundingSource',
    as ArrayRef[GroundingSource()];

coerce 'RepeatedGroundingSource',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1beta::GroundedGenerationService::GenerateGroundedContentRequest::GroundingSource'->new($_) } @$_ ] };

declare 'MapStringGroundingSource',
    as HashRef[GroundingSource()];

declare 'InlineSource',
    as InstanceOf['Google::Cloud::Discoveryengine::V1beta::GroundedGenerationService::GenerateGroundedContentRequest::GroundingSource::InlineSource'];

coerce 'InlineSource',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1beta::GroundedGenerationService::GenerateGroundedContentRequest::GroundingSource::InlineSource'->new($_) };

declare 'RepeatedInlineSource',
    as ArrayRef[InlineSource()];

coerce 'RepeatedInlineSource',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1beta::GroundedGenerationService::GenerateGroundedContentRequest::GroundingSource::InlineSource'->new($_) } @$_ ] };

declare 'MapStringInlineSource',
    as HashRef[InlineSource()];

declare 'AttributesEntry',
    as InstanceOf['Google::Cloud::Discoveryengine::V1beta::GroundedGenerationService::GenerateGroundedContentRequest::GroundingSource::InlineSource::AttributesEntry'];

coerce 'AttributesEntry',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1beta::GroundedGenerationService::GenerateGroundedContentRequest::GroundingSource::InlineSource::AttributesEntry'->new($_) };

declare 'RepeatedAttributesEntry',
    as ArrayRef[AttributesEntry()];

coerce 'RepeatedAttributesEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1beta::GroundedGenerationService::GenerateGroundedContentRequest::GroundingSource::InlineSource::AttributesEntry'->new($_) } @$_ ] };

declare 'MapStringAttributesEntry',
    as HashRef[AttributesEntry()];

declare 'SearchSource',
    as InstanceOf['Google::Cloud::Discoveryengine::V1beta::GroundedGenerationService::GenerateGroundedContentRequest::GroundingSource::SearchSource'];

coerce 'SearchSource',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1beta::GroundedGenerationService::GenerateGroundedContentRequest::GroundingSource::SearchSource'->new($_) };

declare 'RepeatedSearchSource',
    as ArrayRef[SearchSource()];

coerce 'RepeatedSearchSource',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1beta::GroundedGenerationService::GenerateGroundedContentRequest::GroundingSource::SearchSource'->new($_) } @$_ ] };

declare 'MapStringSearchSource',
    as HashRef[SearchSource()];

declare 'GoogleSearchSource',
    as InstanceOf['Google::Cloud::Discoveryengine::V1beta::GroundedGenerationService::GenerateGroundedContentRequest::GroundingSource::GoogleSearchSource'];

coerce 'GoogleSearchSource',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1beta::GroundedGenerationService::GenerateGroundedContentRequest::GroundingSource::GoogleSearchSource'->new($_) };

declare 'RepeatedGoogleSearchSource',
    as ArrayRef[GoogleSearchSource()];

coerce 'RepeatedGoogleSearchSource',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1beta::GroundedGenerationService::GenerateGroundedContentRequest::GroundingSource::GoogleSearchSource'->new($_) } @$_ ] };

declare 'MapStringGoogleSearchSource',
    as HashRef[GoogleSearchSource()];

declare 'EnterpriseWebRetrievalSource',
    as InstanceOf['Google::Cloud::Discoveryengine::V1beta::GroundedGenerationService::GenerateGroundedContentRequest::GroundingSource::EnterpriseWebRetrievalSource'];

coerce 'EnterpriseWebRetrievalSource',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1beta::GroundedGenerationService::GenerateGroundedContentRequest::GroundingSource::EnterpriseWebRetrievalSource'->new($_) };

declare 'RepeatedEnterpriseWebRetrievalSource',
    as ArrayRef[EnterpriseWebRetrievalSource()];

coerce 'RepeatedEnterpriseWebRetrievalSource',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1beta::GroundedGenerationService::GenerateGroundedContentRequest::GroundingSource::EnterpriseWebRetrievalSource'->new($_) } @$_ ] };

declare 'MapStringEnterpriseWebRetrievalSource',
    as HashRef[EnterpriseWebRetrievalSource()];

declare 'GroundingSpec',
    as InstanceOf['Google::Cloud::Discoveryengine::V1beta::GroundedGenerationService::GenerateGroundedContentRequest::GroundingSpec'];

coerce 'GroundingSpec',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1beta::GroundedGenerationService::GenerateGroundedContentRequest::GroundingSpec'->new($_) };

declare 'RepeatedGroundingSpec',
    as ArrayRef[GroundingSpec()];

coerce 'RepeatedGroundingSpec',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1beta::GroundedGenerationService::GenerateGroundedContentRequest::GroundingSpec'->new($_) } @$_ ] };

declare 'MapStringGroundingSpec',
    as HashRef[GroundingSpec()];

declare 'UserLabelsEntry',
    as InstanceOf['Google::Cloud::Discoveryengine::V1beta::GroundedGenerationService::GenerateGroundedContentRequest::UserLabelsEntry'];

coerce 'UserLabelsEntry',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1beta::GroundedGenerationService::GenerateGroundedContentRequest::UserLabelsEntry'->new($_) };

declare 'RepeatedUserLabelsEntry',
    as ArrayRef[UserLabelsEntry()];

coerce 'RepeatedUserLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1beta::GroundedGenerationService::GenerateGroundedContentRequest::UserLabelsEntry'->new($_) } @$_ ] };

declare 'MapStringUserLabelsEntry',
    as HashRef[UserLabelsEntry()];

declare 'GenerateGroundedContentResponse',
    as InstanceOf['Google::Cloud::Discoveryengine::V1beta::GroundedGenerationService::GenerateGroundedContentResponse'];

coerce 'GenerateGroundedContentResponse',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1beta::GroundedGenerationService::GenerateGroundedContentResponse'->new($_) };

declare 'RepeatedGenerateGroundedContentResponse',
    as ArrayRef[GenerateGroundedContentResponse()];

coerce 'RepeatedGenerateGroundedContentResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1beta::GroundedGenerationService::GenerateGroundedContentResponse'->new($_) } @$_ ] };

declare 'MapStringGenerateGroundedContentResponse',
    as HashRef[GenerateGroundedContentResponse()];

declare 'Candidate',
    as InstanceOf['Google::Cloud::Discoveryengine::V1beta::GroundedGenerationService::GenerateGroundedContentResponse::Candidate'];

coerce 'Candidate',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1beta::GroundedGenerationService::GenerateGroundedContentResponse::Candidate'->new($_) };

declare 'RepeatedCandidate',
    as ArrayRef[Candidate()];

coerce 'RepeatedCandidate',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1beta::GroundedGenerationService::GenerateGroundedContentResponse::Candidate'->new($_) } @$_ ] };

declare 'MapStringCandidate',
    as HashRef[Candidate()];

declare 'GroundingMetadata',
    as InstanceOf['Google::Cloud::Discoveryengine::V1beta::GroundedGenerationService::GenerateGroundedContentResponse::Candidate::GroundingMetadata'];

coerce 'GroundingMetadata',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1beta::GroundedGenerationService::GenerateGroundedContentResponse::Candidate::GroundingMetadata'->new($_) };

declare 'RepeatedGroundingMetadata',
    as ArrayRef[GroundingMetadata()];

coerce 'RepeatedGroundingMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1beta::GroundedGenerationService::GenerateGroundedContentResponse::Candidate::GroundingMetadata'->new($_) } @$_ ] };

declare 'MapStringGroundingMetadata',
    as HashRef[GroundingMetadata()];

declare 'RetrievalMetadata',
    as InstanceOf['Google::Cloud::Discoveryengine::V1beta::GroundedGenerationService::GenerateGroundedContentResponse::Candidate::GroundingMetadata::RetrievalMetadata'];

coerce 'RetrievalMetadata',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1beta::GroundedGenerationService::GenerateGroundedContentResponse::Candidate::GroundingMetadata::RetrievalMetadata'->new($_) };

declare 'RepeatedRetrievalMetadata',
    as ArrayRef[RetrievalMetadata()];

coerce 'RepeatedRetrievalMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1beta::GroundedGenerationService::GenerateGroundedContentResponse::Candidate::GroundingMetadata::RetrievalMetadata'->new($_) } @$_ ] };

declare 'MapStringRetrievalMetadata',
    as HashRef[RetrievalMetadata()];

declare 'Source',
    as (Int | Str);

declare 'DynamicRetrievalMetadata',
    as InstanceOf['Google::Cloud::Discoveryengine::V1beta::GroundedGenerationService::GenerateGroundedContentResponse::Candidate::GroundingMetadata::DynamicRetrievalMetadata'];

coerce 'DynamicRetrievalMetadata',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1beta::GroundedGenerationService::GenerateGroundedContentResponse::Candidate::GroundingMetadata::DynamicRetrievalMetadata'->new($_) };

declare 'RepeatedDynamicRetrievalMetadata',
    as ArrayRef[DynamicRetrievalMetadata()];

coerce 'RepeatedDynamicRetrievalMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1beta::GroundedGenerationService::GenerateGroundedContentResponse::Candidate::GroundingMetadata::DynamicRetrievalMetadata'->new($_) } @$_ ] };

declare 'MapStringDynamicRetrievalMetadata',
    as HashRef[DynamicRetrievalMetadata()];

declare 'DynamicRetrievalPredictorMetadata',
    as InstanceOf['Google::Cloud::Discoveryengine::V1beta::GroundedGenerationService::GenerateGroundedContentResponse::Candidate::GroundingMetadata::DynamicRetrievalPredictorMetadata'];

coerce 'DynamicRetrievalPredictorMetadata',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1beta::GroundedGenerationService::GenerateGroundedContentResponse::Candidate::GroundingMetadata::DynamicRetrievalPredictorMetadata'->new($_) };

declare 'RepeatedDynamicRetrievalPredictorMetadata',
    as ArrayRef[DynamicRetrievalPredictorMetadata()];

coerce 'RepeatedDynamicRetrievalPredictorMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1beta::GroundedGenerationService::GenerateGroundedContentResponse::Candidate::GroundingMetadata::DynamicRetrievalPredictorMetadata'->new($_) } @$_ ] };

declare 'MapStringDynamicRetrievalPredictorMetadata',
    as HashRef[DynamicRetrievalPredictorMetadata()];

declare 'Version',
    as (Int | Str);

declare 'SearchEntryPoint',
    as InstanceOf['Google::Cloud::Discoveryengine::V1beta::GroundedGenerationService::GenerateGroundedContentResponse::Candidate::GroundingMetadata::SearchEntryPoint'];

coerce 'SearchEntryPoint',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1beta::GroundedGenerationService::GenerateGroundedContentResponse::Candidate::GroundingMetadata::SearchEntryPoint'->new($_) };

declare 'RepeatedSearchEntryPoint',
    as ArrayRef[SearchEntryPoint()];

coerce 'RepeatedSearchEntryPoint',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1beta::GroundedGenerationService::GenerateGroundedContentResponse::Candidate::GroundingMetadata::SearchEntryPoint'->new($_) } @$_ ] };

declare 'MapStringSearchEntryPoint',
    as HashRef[SearchEntryPoint()];

declare 'GroundingSupport',
    as InstanceOf['Google::Cloud::Discoveryengine::V1beta::GroundedGenerationService::GenerateGroundedContentResponse::Candidate::GroundingMetadata::GroundingSupport'];

coerce 'GroundingSupport',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1beta::GroundedGenerationService::GenerateGroundedContentResponse::Candidate::GroundingMetadata::GroundingSupport'->new($_) };

declare 'RepeatedGroundingSupport',
    as ArrayRef[GroundingSupport()];

coerce 'RepeatedGroundingSupport',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1beta::GroundedGenerationService::GenerateGroundedContentResponse::Candidate::GroundingMetadata::GroundingSupport'->new($_) } @$_ ] };

declare 'MapStringGroundingSupport',
    as HashRef[GroundingSupport()];

declare 'ImageMetadata',
    as InstanceOf['Google::Cloud::Discoveryengine::V1beta::GroundedGenerationService::GenerateGroundedContentResponse::Candidate::GroundingMetadata::ImageMetadata'];

coerce 'ImageMetadata',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1beta::GroundedGenerationService::GenerateGroundedContentResponse::Candidate::GroundingMetadata::ImageMetadata'->new($_) };

declare 'RepeatedImageMetadata',
    as ArrayRef[ImageMetadata()];

coerce 'RepeatedImageMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1beta::GroundedGenerationService::GenerateGroundedContentResponse::Candidate::GroundingMetadata::ImageMetadata'->new($_) } @$_ ] };

declare 'MapStringImageMetadata',
    as HashRef[ImageMetadata()];

declare 'WebsiteInfo',
    as InstanceOf['Google::Cloud::Discoveryengine::V1beta::GroundedGenerationService::GenerateGroundedContentResponse::Candidate::GroundingMetadata::ImageMetadata::WebsiteInfo'];

coerce 'WebsiteInfo',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1beta::GroundedGenerationService::GenerateGroundedContentResponse::Candidate::GroundingMetadata::ImageMetadata::WebsiteInfo'->new($_) };

declare 'RepeatedWebsiteInfo',
    as ArrayRef[WebsiteInfo()];

coerce 'RepeatedWebsiteInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1beta::GroundedGenerationService::GenerateGroundedContentResponse::Candidate::GroundingMetadata::ImageMetadata::WebsiteInfo'->new($_) } @$_ ] };

declare 'MapStringWebsiteInfo',
    as HashRef[WebsiteInfo()];

declare 'Image',
    as InstanceOf['Google::Cloud::Discoveryengine::V1beta::GroundedGenerationService::GenerateGroundedContentResponse::Candidate::GroundingMetadata::ImageMetadata::Image'];

coerce 'Image',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1beta::GroundedGenerationService::GenerateGroundedContentResponse::Candidate::GroundingMetadata::ImageMetadata::Image'->new($_) };

declare 'RepeatedImage',
    as ArrayRef[Image()];

coerce 'RepeatedImage',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1beta::GroundedGenerationService::GenerateGroundedContentResponse::Candidate::GroundingMetadata::ImageMetadata::Image'->new($_) } @$_ ] };

declare 'MapStringImage',
    as HashRef[Image()];

declare 'VideoMetadata',
    as InstanceOf['Google::Cloud::Discoveryengine::V1beta::GroundedGenerationService::GenerateGroundedContentResponse::Candidate::GroundingMetadata::VideoMetadata'];

coerce 'VideoMetadata',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1beta::GroundedGenerationService::GenerateGroundedContentResponse::Candidate::GroundingMetadata::VideoMetadata'->new($_) };

declare 'RepeatedVideoMetadata',
    as ArrayRef[VideoMetadata()];

coerce 'RepeatedVideoMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1beta::GroundedGenerationService::GenerateGroundedContentResponse::Candidate::GroundingMetadata::VideoMetadata'->new($_) } @$_ ] };

declare 'MapStringVideoMetadata',
    as HashRef[VideoMetadata()];

declare 'CheckGroundingSpec',
    as InstanceOf['Google::Cloud::Discoveryengine::V1beta::GroundedGenerationService::CheckGroundingSpec'];

coerce 'CheckGroundingSpec',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1beta::GroundedGenerationService::CheckGroundingSpec'->new($_) };

declare 'RepeatedCheckGroundingSpec',
    as ArrayRef[CheckGroundingSpec()];

coerce 'RepeatedCheckGroundingSpec',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1beta::GroundedGenerationService::CheckGroundingSpec'->new($_) } @$_ ] };

declare 'MapStringCheckGroundingSpec',
    as HashRef[CheckGroundingSpec()];

declare 'CheckGroundingRequest',
    as InstanceOf['Google::Cloud::Discoveryengine::V1beta::GroundedGenerationService::CheckGroundingRequest'];

coerce 'CheckGroundingRequest',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1beta::GroundedGenerationService::CheckGroundingRequest'->new($_) };

declare 'RepeatedCheckGroundingRequest',
    as ArrayRef[CheckGroundingRequest()];

coerce 'RepeatedCheckGroundingRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1beta::GroundedGenerationService::CheckGroundingRequest'->new($_) } @$_ ] };

declare 'MapStringCheckGroundingRequest',
    as HashRef[CheckGroundingRequest()];

declare 'UserLabelsEntry',
    as InstanceOf['Google::Cloud::Discoveryengine::V1beta::GroundedGenerationService::CheckGroundingRequest::UserLabelsEntry'];

coerce 'UserLabelsEntry',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1beta::GroundedGenerationService::CheckGroundingRequest::UserLabelsEntry'->new($_) };

declare 'RepeatedUserLabelsEntry',
    as ArrayRef[UserLabelsEntry()];

coerce 'RepeatedUserLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1beta::GroundedGenerationService::CheckGroundingRequest::UserLabelsEntry'->new($_) } @$_ ] };

declare 'MapStringUserLabelsEntry',
    as HashRef[UserLabelsEntry()];

declare 'CheckGroundingResponse',
    as InstanceOf['Google::Cloud::Discoveryengine::V1beta::GroundedGenerationService::CheckGroundingResponse'];

coerce 'CheckGroundingResponse',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1beta::GroundedGenerationService::CheckGroundingResponse'->new($_) };

declare 'RepeatedCheckGroundingResponse',
    as ArrayRef[CheckGroundingResponse()];

coerce 'RepeatedCheckGroundingResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1beta::GroundedGenerationService::CheckGroundingResponse'->new($_) } @$_ ] };

declare 'MapStringCheckGroundingResponse',
    as HashRef[CheckGroundingResponse()];

declare 'CheckGroundingFactChunk',
    as InstanceOf['Google::Cloud::Discoveryengine::V1beta::GroundedGenerationService::CheckGroundingResponse::CheckGroundingFactChunk'];

coerce 'CheckGroundingFactChunk',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1beta::GroundedGenerationService::CheckGroundingResponse::CheckGroundingFactChunk'->new($_) };

declare 'RepeatedCheckGroundingFactChunk',
    as ArrayRef[CheckGroundingFactChunk()];

coerce 'RepeatedCheckGroundingFactChunk',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1beta::GroundedGenerationService::CheckGroundingResponse::CheckGroundingFactChunk'->new($_) } @$_ ] };

declare 'MapStringCheckGroundingFactChunk',
    as HashRef[CheckGroundingFactChunk()];

declare 'Claim',
    as InstanceOf['Google::Cloud::Discoveryengine::V1beta::GroundedGenerationService::CheckGroundingResponse::Claim'];

coerce 'Claim',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1beta::GroundedGenerationService::CheckGroundingResponse::Claim'->new($_) };

declare 'RepeatedClaim',
    as ArrayRef[Claim()];

coerce 'RepeatedClaim',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1beta::GroundedGenerationService::CheckGroundingResponse::Claim'->new($_) } @$_ ] };

declare 'MapStringClaim',
    as HashRef[Claim()];

declare 'CitationMetadata',
    as InstanceOf['Google::Cloud::Discoveryengine::V1beta::GroundedGenerationService::CitationMetadata'];

coerce 'CitationMetadata',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1beta::GroundedGenerationService::CitationMetadata'->new($_) };

declare 'RepeatedCitationMetadata',
    as ArrayRef[CitationMetadata()];

coerce 'RepeatedCitationMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1beta::GroundedGenerationService::CitationMetadata'->new($_) } @$_ ] };

declare 'MapStringCitationMetadata',
    as HashRef[CitationMetadata()];

declare 'Citation',
    as InstanceOf['Google::Cloud::Discoveryengine::V1beta::GroundedGenerationService::Citation'];

coerce 'Citation',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1beta::GroundedGenerationService::Citation'->new($_) };

declare 'RepeatedCitation',
    as ArrayRef[Citation()];

coerce 'RepeatedCitation',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1beta::GroundedGenerationService::Citation'->new($_) } @$_ ] };

declare 'MapStringCitation',
    as HashRef[Citation()];

declare 'PhishBlockThreshold',
    as (Int | Str);

1;

__END__

=head1 NAME

Google::Cloud::Discoveryengine::V1beta::GroundedGenerationService::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
