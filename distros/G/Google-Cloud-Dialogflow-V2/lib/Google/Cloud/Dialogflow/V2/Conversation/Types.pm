package Google::Cloud::Dialogflow::V2::Conversation::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Conversation',
    as InstanceOf['Google::Cloud::Dialogflow::V2::Conversation::Conversation'];

coerce 'Conversation',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::Conversation::Conversation'->new($_) };

declare 'RepeatedConversation',
    as ArrayRef[Conversation()];

coerce 'RepeatedConversation',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::Conversation::Conversation'->new($_) } @$_ ] };

declare 'MapStringConversation',
    as HashRef[Conversation()];

declare 'LifecycleState',
    as (Int | Str);

declare 'ConversationStage',
    as (Int | Str);

declare 'TelephonyConnectionInfo',
    as InstanceOf['Google::Cloud::Dialogflow::V2::Conversation::Conversation::TelephonyConnectionInfo'];

coerce 'TelephonyConnectionInfo',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::Conversation::Conversation::TelephonyConnectionInfo'->new($_) };

declare 'RepeatedTelephonyConnectionInfo',
    as ArrayRef[TelephonyConnectionInfo()];

coerce 'RepeatedTelephonyConnectionInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::Conversation::Conversation::TelephonyConnectionInfo'->new($_) } @$_ ] };

declare 'MapStringTelephonyConnectionInfo',
    as HashRef[TelephonyConnectionInfo()];

declare 'SipHeader',
    as InstanceOf['Google::Cloud::Dialogflow::V2::Conversation::Conversation::TelephonyConnectionInfo::SipHeader'];

coerce 'SipHeader',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::Conversation::Conversation::TelephonyConnectionInfo::SipHeader'->new($_) };

declare 'RepeatedSipHeader',
    as ArrayRef[SipHeader()];

coerce 'RepeatedSipHeader',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::Conversation::Conversation::TelephonyConnectionInfo::SipHeader'->new($_) } @$_ ] };

declare 'MapStringSipHeader',
    as HashRef[SipHeader()];

declare 'MimeContent',
    as InstanceOf['Google::Cloud::Dialogflow::V2::Conversation::Conversation::TelephonyConnectionInfo::MimeContent'];

coerce 'MimeContent',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::Conversation::Conversation::TelephonyConnectionInfo::MimeContent'->new($_) };

declare 'RepeatedMimeContent',
    as ArrayRef[MimeContent()];

coerce 'RepeatedMimeContent',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::Conversation::Conversation::TelephonyConnectionInfo::MimeContent'->new($_) } @$_ ] };

declare 'MapStringMimeContent',
    as HashRef[MimeContent()];

declare 'ContextReference',
    as InstanceOf['Google::Cloud::Dialogflow::V2::Conversation::Conversation::ContextReference'];

coerce 'ContextReference',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::Conversation::Conversation::ContextReference'->new($_) };

declare 'RepeatedContextReference',
    as ArrayRef[ContextReference()];

coerce 'RepeatedContextReference',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::Conversation::Conversation::ContextReference'->new($_) } @$_ ] };

declare 'MapStringContextReference',
    as HashRef[ContextReference()];

declare 'UpdateMode',
    as (Int | Str);

declare 'ContextContent',
    as InstanceOf['Google::Cloud::Dialogflow::V2::Conversation::Conversation::ContextReference::ContextContent'];

coerce 'ContextContent',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::Conversation::Conversation::ContextReference::ContextContent'->new($_) };

declare 'RepeatedContextContent',
    as ArrayRef[ContextContent()];

coerce 'RepeatedContextContent',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::Conversation::Conversation::ContextReference::ContextContent'->new($_) } @$_ ] };

declare 'MapStringContextContent',
    as HashRef[ContextContent()];

declare 'ContentFormat',
    as (Int | Str);

declare 'GeneratorContext',
    as InstanceOf['Google::Cloud::Dialogflow::V2::Conversation::Conversation::GeneratorContext'];

coerce 'GeneratorContext',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::Conversation::Conversation::GeneratorContext'->new($_) };

declare 'RepeatedGeneratorContext',
    as ArrayRef[GeneratorContext()];

coerce 'RepeatedGeneratorContext',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::Conversation::Conversation::GeneratorContext'->new($_) } @$_ ] };

declare 'MapStringGeneratorContext',
    as HashRef[GeneratorContext()];

declare 'GeneratorType',
    as (Int | Str);

declare 'IngestedContextReferencesEntry',
    as InstanceOf['Google::Cloud::Dialogflow::V2::Conversation::Conversation::IngestedContextReferencesEntry'];

coerce 'IngestedContextReferencesEntry',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::Conversation::Conversation::IngestedContextReferencesEntry'->new($_) };

declare 'RepeatedIngestedContextReferencesEntry',
    as ArrayRef[IngestedContextReferencesEntry()];

coerce 'RepeatedIngestedContextReferencesEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::Conversation::Conversation::IngestedContextReferencesEntry'->new($_) } @$_ ] };

declare 'MapStringIngestedContextReferencesEntry',
    as HashRef[IngestedContextReferencesEntry()];

declare 'InitialGeneratorContextsEntry',
    as InstanceOf['Google::Cloud::Dialogflow::V2::Conversation::Conversation::InitialGeneratorContextsEntry'];

coerce 'InitialGeneratorContextsEntry',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::Conversation::Conversation::InitialGeneratorContextsEntry'->new($_) };

declare 'RepeatedInitialGeneratorContextsEntry',
    as ArrayRef[InitialGeneratorContextsEntry()];

coerce 'RepeatedInitialGeneratorContextsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::Conversation::Conversation::InitialGeneratorContextsEntry'->new($_) } @$_ ] };

declare 'MapStringInitialGeneratorContextsEntry',
    as HashRef[InitialGeneratorContextsEntry()];

declare 'CreateConversationRequest',
    as InstanceOf['Google::Cloud::Dialogflow::V2::Conversation::CreateConversationRequest'];

coerce 'CreateConversationRequest',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::Conversation::CreateConversationRequest'->new($_) };

declare 'RepeatedCreateConversationRequest',
    as ArrayRef[CreateConversationRequest()];

coerce 'RepeatedCreateConversationRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::Conversation::CreateConversationRequest'->new($_) } @$_ ] };

declare 'MapStringCreateConversationRequest',
    as HashRef[CreateConversationRequest()];

declare 'ListConversationsRequest',
    as InstanceOf['Google::Cloud::Dialogflow::V2::Conversation::ListConversationsRequest'];

coerce 'ListConversationsRequest',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::Conversation::ListConversationsRequest'->new($_) };

declare 'RepeatedListConversationsRequest',
    as ArrayRef[ListConversationsRequest()];

coerce 'RepeatedListConversationsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::Conversation::ListConversationsRequest'->new($_) } @$_ ] };

declare 'MapStringListConversationsRequest',
    as HashRef[ListConversationsRequest()];

declare 'ListConversationsResponse',
    as InstanceOf['Google::Cloud::Dialogflow::V2::Conversation::ListConversationsResponse'];

coerce 'ListConversationsResponse',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::Conversation::ListConversationsResponse'->new($_) };

declare 'RepeatedListConversationsResponse',
    as ArrayRef[ListConversationsResponse()];

coerce 'RepeatedListConversationsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::Conversation::ListConversationsResponse'->new($_) } @$_ ] };

declare 'MapStringListConversationsResponse',
    as HashRef[ListConversationsResponse()];

declare 'GetConversationRequest',
    as InstanceOf['Google::Cloud::Dialogflow::V2::Conversation::GetConversationRequest'];

coerce 'GetConversationRequest',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::Conversation::GetConversationRequest'->new($_) };

declare 'RepeatedGetConversationRequest',
    as ArrayRef[GetConversationRequest()];

coerce 'RepeatedGetConversationRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::Conversation::GetConversationRequest'->new($_) } @$_ ] };

declare 'MapStringGetConversationRequest',
    as HashRef[GetConversationRequest()];

declare 'CompleteConversationRequest',
    as InstanceOf['Google::Cloud::Dialogflow::V2::Conversation::CompleteConversationRequest'];

coerce 'CompleteConversationRequest',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::Conversation::CompleteConversationRequest'->new($_) };

declare 'RepeatedCompleteConversationRequest',
    as ArrayRef[CompleteConversationRequest()];

coerce 'RepeatedCompleteConversationRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::Conversation::CompleteConversationRequest'->new($_) } @$_ ] };

declare 'MapStringCompleteConversationRequest',
    as HashRef[CompleteConversationRequest()];

declare 'ListMessagesRequest',
    as InstanceOf['Google::Cloud::Dialogflow::V2::Conversation::ListMessagesRequest'];

coerce 'ListMessagesRequest',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::Conversation::ListMessagesRequest'->new($_) };

declare 'RepeatedListMessagesRequest',
    as ArrayRef[ListMessagesRequest()];

coerce 'RepeatedListMessagesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::Conversation::ListMessagesRequest'->new($_) } @$_ ] };

declare 'MapStringListMessagesRequest',
    as HashRef[ListMessagesRequest()];

declare 'ListMessagesResponse',
    as InstanceOf['Google::Cloud::Dialogflow::V2::Conversation::ListMessagesResponse'];

coerce 'ListMessagesResponse',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::Conversation::ListMessagesResponse'->new($_) };

declare 'RepeatedListMessagesResponse',
    as ArrayRef[ListMessagesResponse()];

coerce 'RepeatedListMessagesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::Conversation::ListMessagesResponse'->new($_) } @$_ ] };

declare 'MapStringListMessagesResponse',
    as HashRef[ListMessagesResponse()];

declare 'ConversationPhoneNumber',
    as InstanceOf['Google::Cloud::Dialogflow::V2::Conversation::ConversationPhoneNumber'];

coerce 'ConversationPhoneNumber',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::Conversation::ConversationPhoneNumber'->new($_) };

declare 'RepeatedConversationPhoneNumber',
    as ArrayRef[ConversationPhoneNumber()];

coerce 'RepeatedConversationPhoneNumber',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::Conversation::ConversationPhoneNumber'->new($_) } @$_ ] };

declare 'MapStringConversationPhoneNumber',
    as HashRef[ConversationPhoneNumber()];

declare 'IngestContextReferencesRequest',
    as InstanceOf['Google::Cloud::Dialogflow::V2::Conversation::IngestContextReferencesRequest'];

coerce 'IngestContextReferencesRequest',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::Conversation::IngestContextReferencesRequest'->new($_) };

declare 'RepeatedIngestContextReferencesRequest',
    as ArrayRef[IngestContextReferencesRequest()];

coerce 'RepeatedIngestContextReferencesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::Conversation::IngestContextReferencesRequest'->new($_) } @$_ ] };

declare 'MapStringIngestContextReferencesRequest',
    as HashRef[IngestContextReferencesRequest()];

declare 'ContextReferencesEntry',
    as InstanceOf['Google::Cloud::Dialogflow::V2::Conversation::IngestContextReferencesRequest::ContextReferencesEntry'];

coerce 'ContextReferencesEntry',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::Conversation::IngestContextReferencesRequest::ContextReferencesEntry'->new($_) };

declare 'RepeatedContextReferencesEntry',
    as ArrayRef[ContextReferencesEntry()];

coerce 'RepeatedContextReferencesEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::Conversation::IngestContextReferencesRequest::ContextReferencesEntry'->new($_) } @$_ ] };

declare 'MapStringContextReferencesEntry',
    as HashRef[ContextReferencesEntry()];

declare 'IngestContextReferencesResponse',
    as InstanceOf['Google::Cloud::Dialogflow::V2::Conversation::IngestContextReferencesResponse'];

coerce 'IngestContextReferencesResponse',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::Conversation::IngestContextReferencesResponse'->new($_) };

declare 'RepeatedIngestContextReferencesResponse',
    as ArrayRef[IngestContextReferencesResponse()];

coerce 'RepeatedIngestContextReferencesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::Conversation::IngestContextReferencesResponse'->new($_) } @$_ ] };

declare 'MapStringIngestContextReferencesResponse',
    as HashRef[IngestContextReferencesResponse()];

declare 'IngestedContextReferencesEntry',
    as InstanceOf['Google::Cloud::Dialogflow::V2::Conversation::IngestContextReferencesResponse::IngestedContextReferencesEntry'];

coerce 'IngestedContextReferencesEntry',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::Conversation::IngestContextReferencesResponse::IngestedContextReferencesEntry'->new($_) };

declare 'RepeatedIngestedContextReferencesEntry',
    as ArrayRef[IngestedContextReferencesEntry()];

coerce 'RepeatedIngestedContextReferencesEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::Conversation::IngestContextReferencesResponse::IngestedContextReferencesEntry'->new($_) } @$_ ] };

declare 'MapStringIngestedContextReferencesEntry',
    as HashRef[IngestedContextReferencesEntry()];

declare 'SuggestConversationSummaryRequest',
    as InstanceOf['Google::Cloud::Dialogflow::V2::Conversation::SuggestConversationSummaryRequest'];

coerce 'SuggestConversationSummaryRequest',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::Conversation::SuggestConversationSummaryRequest'->new($_) };

declare 'RepeatedSuggestConversationSummaryRequest',
    as ArrayRef[SuggestConversationSummaryRequest()];

coerce 'RepeatedSuggestConversationSummaryRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::Conversation::SuggestConversationSummaryRequest'->new($_) } @$_ ] };

declare 'MapStringSuggestConversationSummaryRequest',
    as HashRef[SuggestConversationSummaryRequest()];

declare 'SuggestConversationSummaryResponse',
    as InstanceOf['Google::Cloud::Dialogflow::V2::Conversation::SuggestConversationSummaryResponse'];

coerce 'SuggestConversationSummaryResponse',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::Conversation::SuggestConversationSummaryResponse'->new($_) };

declare 'RepeatedSuggestConversationSummaryResponse',
    as ArrayRef[SuggestConversationSummaryResponse()];

coerce 'RepeatedSuggestConversationSummaryResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::Conversation::SuggestConversationSummaryResponse'->new($_) } @$_ ] };

declare 'MapStringSuggestConversationSummaryResponse',
    as HashRef[SuggestConversationSummaryResponse()];

declare 'Summary',
    as InstanceOf['Google::Cloud::Dialogflow::V2::Conversation::SuggestConversationSummaryResponse::Summary'];

coerce 'Summary',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::Conversation::SuggestConversationSummaryResponse::Summary'->new($_) };

declare 'RepeatedSummary',
    as ArrayRef[Summary()];

coerce 'RepeatedSummary',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::Conversation::SuggestConversationSummaryResponse::Summary'->new($_) } @$_ ] };

declare 'MapStringSummary',
    as HashRef[Summary()];

declare 'SummarySection',
    as InstanceOf['Google::Cloud::Dialogflow::V2::Conversation::SuggestConversationSummaryResponse::Summary::SummarySection'];

coerce 'SummarySection',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::Conversation::SuggestConversationSummaryResponse::Summary::SummarySection'->new($_) };

declare 'RepeatedSummarySection',
    as ArrayRef[SummarySection()];

coerce 'RepeatedSummarySection',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::Conversation::SuggestConversationSummaryResponse::Summary::SummarySection'->new($_) } @$_ ] };

declare 'MapStringSummarySection',
    as HashRef[SummarySection()];

declare 'TextSectionsEntry',
    as InstanceOf['Google::Cloud::Dialogflow::V2::Conversation::SuggestConversationSummaryResponse::Summary::TextSectionsEntry'];

coerce 'TextSectionsEntry',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::Conversation::SuggestConversationSummaryResponse::Summary::TextSectionsEntry'->new($_) };

declare 'RepeatedTextSectionsEntry',
    as ArrayRef[TextSectionsEntry()];

coerce 'RepeatedTextSectionsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::Conversation::SuggestConversationSummaryResponse::Summary::TextSectionsEntry'->new($_) } @$_ ] };

declare 'MapStringTextSectionsEntry',
    as HashRef[TextSectionsEntry()];

declare 'GenerateStatelessSummaryRequest',
    as InstanceOf['Google::Cloud::Dialogflow::V2::Conversation::GenerateStatelessSummaryRequest'];

coerce 'GenerateStatelessSummaryRequest',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::Conversation::GenerateStatelessSummaryRequest'->new($_) };

declare 'RepeatedGenerateStatelessSummaryRequest',
    as ArrayRef[GenerateStatelessSummaryRequest()];

coerce 'RepeatedGenerateStatelessSummaryRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::Conversation::GenerateStatelessSummaryRequest'->new($_) } @$_ ] };

declare 'MapStringGenerateStatelessSummaryRequest',
    as HashRef[GenerateStatelessSummaryRequest()];

declare 'MinimalConversation',
    as InstanceOf['Google::Cloud::Dialogflow::V2::Conversation::GenerateStatelessSummaryRequest::MinimalConversation'];

coerce 'MinimalConversation',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::Conversation::GenerateStatelessSummaryRequest::MinimalConversation'->new($_) };

declare 'RepeatedMinimalConversation',
    as ArrayRef[MinimalConversation()];

coerce 'RepeatedMinimalConversation',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::Conversation::GenerateStatelessSummaryRequest::MinimalConversation'->new($_) } @$_ ] };

declare 'MapStringMinimalConversation',
    as HashRef[MinimalConversation()];

declare 'GenerateStatelessSummaryResponse',
    as InstanceOf['Google::Cloud::Dialogflow::V2::Conversation::GenerateStatelessSummaryResponse'];

coerce 'GenerateStatelessSummaryResponse',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::Conversation::GenerateStatelessSummaryResponse'->new($_) };

declare 'RepeatedGenerateStatelessSummaryResponse',
    as ArrayRef[GenerateStatelessSummaryResponse()];

coerce 'RepeatedGenerateStatelessSummaryResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::Conversation::GenerateStatelessSummaryResponse'->new($_) } @$_ ] };

declare 'MapStringGenerateStatelessSummaryResponse',
    as HashRef[GenerateStatelessSummaryResponse()];

declare 'Summary',
    as InstanceOf['Google::Cloud::Dialogflow::V2::Conversation::GenerateStatelessSummaryResponse::Summary'];

coerce 'Summary',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::Conversation::GenerateStatelessSummaryResponse::Summary'->new($_) };

declare 'RepeatedSummary',
    as ArrayRef[Summary()];

coerce 'RepeatedSummary',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::Conversation::GenerateStatelessSummaryResponse::Summary'->new($_) } @$_ ] };

declare 'MapStringSummary',
    as HashRef[Summary()];

declare 'TextSectionsEntry',
    as InstanceOf['Google::Cloud::Dialogflow::V2::Conversation::GenerateStatelessSummaryResponse::Summary::TextSectionsEntry'];

coerce 'TextSectionsEntry',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::Conversation::GenerateStatelessSummaryResponse::Summary::TextSectionsEntry'->new($_) };

declare 'RepeatedTextSectionsEntry',
    as ArrayRef[TextSectionsEntry()];

coerce 'RepeatedTextSectionsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::Conversation::GenerateStatelessSummaryResponse::Summary::TextSectionsEntry'->new($_) } @$_ ] };

declare 'MapStringTextSectionsEntry',
    as HashRef[TextSectionsEntry()];

declare 'GenerateStatelessSuggestionRequest',
    as InstanceOf['Google::Cloud::Dialogflow::V2::Conversation::GenerateStatelessSuggestionRequest'];

coerce 'GenerateStatelessSuggestionRequest',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::Conversation::GenerateStatelessSuggestionRequest'->new($_) };

declare 'RepeatedGenerateStatelessSuggestionRequest',
    as ArrayRef[GenerateStatelessSuggestionRequest()];

coerce 'RepeatedGenerateStatelessSuggestionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::Conversation::GenerateStatelessSuggestionRequest'->new($_) } @$_ ] };

declare 'MapStringGenerateStatelessSuggestionRequest',
    as HashRef[GenerateStatelessSuggestionRequest()];

declare 'ContextReferencesEntry',
    as InstanceOf['Google::Cloud::Dialogflow::V2::Conversation::GenerateStatelessSuggestionRequest::ContextReferencesEntry'];

coerce 'ContextReferencesEntry',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::Conversation::GenerateStatelessSuggestionRequest::ContextReferencesEntry'->new($_) };

declare 'RepeatedContextReferencesEntry',
    as ArrayRef[ContextReferencesEntry()];

coerce 'RepeatedContextReferencesEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::Conversation::GenerateStatelessSuggestionRequest::ContextReferencesEntry'->new($_) } @$_ ] };

declare 'MapStringContextReferencesEntry',
    as HashRef[ContextReferencesEntry()];

declare 'GenerateStatelessSuggestionResponse',
    as InstanceOf['Google::Cloud::Dialogflow::V2::Conversation::GenerateStatelessSuggestionResponse'];

coerce 'GenerateStatelessSuggestionResponse',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::Conversation::GenerateStatelessSuggestionResponse'->new($_) };

declare 'RepeatedGenerateStatelessSuggestionResponse',
    as ArrayRef[GenerateStatelessSuggestionResponse()];

coerce 'RepeatedGenerateStatelessSuggestionResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::Conversation::GenerateStatelessSuggestionResponse'->new($_) } @$_ ] };

declare 'MapStringGenerateStatelessSuggestionResponse',
    as HashRef[GenerateStatelessSuggestionResponse()];

declare 'SearchKnowledgeRequest',
    as InstanceOf['Google::Cloud::Dialogflow::V2::Conversation::SearchKnowledgeRequest'];

coerce 'SearchKnowledgeRequest',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::Conversation::SearchKnowledgeRequest'->new($_) };

declare 'RepeatedSearchKnowledgeRequest',
    as ArrayRef[SearchKnowledgeRequest()];

coerce 'RepeatedSearchKnowledgeRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::Conversation::SearchKnowledgeRequest'->new($_) } @$_ ] };

declare 'MapStringSearchKnowledgeRequest',
    as HashRef[SearchKnowledgeRequest()];

declare 'QuerySource',
    as (Int | Str);

declare 'SearchConfig',
    as InstanceOf['Google::Cloud::Dialogflow::V2::Conversation::SearchKnowledgeRequest::SearchConfig'];

coerce 'SearchConfig',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::Conversation::SearchKnowledgeRequest::SearchConfig'->new($_) };

declare 'RepeatedSearchConfig',
    as ArrayRef[SearchConfig()];

coerce 'RepeatedSearchConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::Conversation::SearchKnowledgeRequest::SearchConfig'->new($_) } @$_ ] };

declare 'MapStringSearchConfig',
    as HashRef[SearchConfig()];

declare 'BoostSpecs',
    as InstanceOf['Google::Cloud::Dialogflow::V2::Conversation::SearchKnowledgeRequest::SearchConfig::BoostSpecs'];

coerce 'BoostSpecs',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::Conversation::SearchKnowledgeRequest::SearchConfig::BoostSpecs'->new($_) };

declare 'RepeatedBoostSpecs',
    as ArrayRef[BoostSpecs()];

coerce 'RepeatedBoostSpecs',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::Conversation::SearchKnowledgeRequest::SearchConfig::BoostSpecs'->new($_) } @$_ ] };

declare 'MapStringBoostSpecs',
    as HashRef[BoostSpecs()];

declare 'BoostSpec',
    as InstanceOf['Google::Cloud::Dialogflow::V2::Conversation::SearchKnowledgeRequest::SearchConfig::BoostSpecs::BoostSpec'];

coerce 'BoostSpec',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::Conversation::SearchKnowledgeRequest::SearchConfig::BoostSpecs::BoostSpec'->new($_) };

declare 'RepeatedBoostSpec',
    as ArrayRef[BoostSpec()];

coerce 'RepeatedBoostSpec',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::Conversation::SearchKnowledgeRequest::SearchConfig::BoostSpecs::BoostSpec'->new($_) } @$_ ] };

declare 'MapStringBoostSpec',
    as HashRef[BoostSpec()];

declare 'ConditionBoostSpec',
    as InstanceOf['Google::Cloud::Dialogflow::V2::Conversation::SearchKnowledgeRequest::SearchConfig::BoostSpecs::BoostSpec::ConditionBoostSpec'];

coerce 'ConditionBoostSpec',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::Conversation::SearchKnowledgeRequest::SearchConfig::BoostSpecs::BoostSpec::ConditionBoostSpec'->new($_) };

declare 'RepeatedConditionBoostSpec',
    as ArrayRef[ConditionBoostSpec()];

coerce 'RepeatedConditionBoostSpec',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::Conversation::SearchKnowledgeRequest::SearchConfig::BoostSpecs::BoostSpec::ConditionBoostSpec'->new($_) } @$_ ] };

declare 'MapStringConditionBoostSpec',
    as HashRef[ConditionBoostSpec()];

declare 'BoostControlSpec',
    as InstanceOf['Google::Cloud::Dialogflow::V2::Conversation::SearchKnowledgeRequest::SearchConfig::BoostSpecs::BoostSpec::ConditionBoostSpec::BoostControlSpec'];

coerce 'BoostControlSpec',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::Conversation::SearchKnowledgeRequest::SearchConfig::BoostSpecs::BoostSpec::ConditionBoostSpec::BoostControlSpec'->new($_) };

declare 'RepeatedBoostControlSpec',
    as ArrayRef[BoostControlSpec()];

coerce 'RepeatedBoostControlSpec',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::Conversation::SearchKnowledgeRequest::SearchConfig::BoostSpecs::BoostSpec::ConditionBoostSpec::BoostControlSpec'->new($_) } @$_ ] };

declare 'MapStringBoostControlSpec',
    as HashRef[BoostControlSpec()];

declare 'AttributeType',
    as (Int | Str);

declare 'InterpolationType',
    as (Int | Str);

declare 'ControlPoint',
    as InstanceOf['Google::Cloud::Dialogflow::V2::Conversation::SearchKnowledgeRequest::SearchConfig::BoostSpecs::BoostSpec::ConditionBoostSpec::BoostControlSpec::ControlPoint'];

coerce 'ControlPoint',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::Conversation::SearchKnowledgeRequest::SearchConfig::BoostSpecs::BoostSpec::ConditionBoostSpec::BoostControlSpec::ControlPoint'->new($_) };

declare 'RepeatedControlPoint',
    as ArrayRef[ControlPoint()];

coerce 'RepeatedControlPoint',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::Conversation::SearchKnowledgeRequest::SearchConfig::BoostSpecs::BoostSpec::ConditionBoostSpec::BoostControlSpec::ControlPoint'->new($_) } @$_ ] };

declare 'MapStringControlPoint',
    as HashRef[ControlPoint()];

declare 'FilterSpecs',
    as InstanceOf['Google::Cloud::Dialogflow::V2::Conversation::SearchKnowledgeRequest::SearchConfig::FilterSpecs'];

coerce 'FilterSpecs',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::Conversation::SearchKnowledgeRequest::SearchConfig::FilterSpecs'->new($_) };

declare 'RepeatedFilterSpecs',
    as ArrayRef[FilterSpecs()];

coerce 'RepeatedFilterSpecs',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::Conversation::SearchKnowledgeRequest::SearchConfig::FilterSpecs'->new($_) } @$_ ] };

declare 'MapStringFilterSpecs',
    as HashRef[FilterSpecs()];

declare 'SearchKnowledgeDebugInfo',
    as InstanceOf['Google::Cloud::Dialogflow::V2::Conversation::SearchKnowledgeDebugInfo'];

coerce 'SearchKnowledgeDebugInfo',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::Conversation::SearchKnowledgeDebugInfo'->new($_) };

declare 'RepeatedSearchKnowledgeDebugInfo',
    as ArrayRef[SearchKnowledgeDebugInfo()];

coerce 'RepeatedSearchKnowledgeDebugInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::Conversation::SearchKnowledgeDebugInfo'->new($_) } @$_ ] };

declare 'MapStringSearchKnowledgeDebugInfo',
    as HashRef[SearchKnowledgeDebugInfo()];

declare 'SearchKnowledgeBehavior',
    as InstanceOf['Google::Cloud::Dialogflow::V2::Conversation::SearchKnowledgeDebugInfo::SearchKnowledgeBehavior'];

coerce 'SearchKnowledgeBehavior',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::Conversation::SearchKnowledgeDebugInfo::SearchKnowledgeBehavior'->new($_) };

declare 'RepeatedSearchKnowledgeBehavior',
    as ArrayRef[SearchKnowledgeBehavior()];

coerce 'RepeatedSearchKnowledgeBehavior',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::Conversation::SearchKnowledgeDebugInfo::SearchKnowledgeBehavior'->new($_) } @$_ ] };

declare 'MapStringSearchKnowledgeBehavior',
    as HashRef[SearchKnowledgeBehavior()];

declare 'SearchKnowledgeResponse',
    as InstanceOf['Google::Cloud::Dialogflow::V2::Conversation::SearchKnowledgeResponse'];

coerce 'SearchKnowledgeResponse',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::Conversation::SearchKnowledgeResponse'->new($_) };

declare 'RepeatedSearchKnowledgeResponse',
    as ArrayRef[SearchKnowledgeResponse()];

coerce 'RepeatedSearchKnowledgeResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::Conversation::SearchKnowledgeResponse'->new($_) } @$_ ] };

declare 'MapStringSearchKnowledgeResponse',
    as HashRef[SearchKnowledgeResponse()];

declare 'SearchKnowledgeAnswer',
    as InstanceOf['Google::Cloud::Dialogflow::V2::Conversation::SearchKnowledgeAnswer'];

coerce 'SearchKnowledgeAnswer',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::Conversation::SearchKnowledgeAnswer'->new($_) };

declare 'RepeatedSearchKnowledgeAnswer',
    as ArrayRef[SearchKnowledgeAnswer()];

coerce 'RepeatedSearchKnowledgeAnswer',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::Conversation::SearchKnowledgeAnswer'->new($_) } @$_ ] };

declare 'MapStringSearchKnowledgeAnswer',
    as HashRef[SearchKnowledgeAnswer()];

declare 'AnswerType',
    as (Int | Str);

declare 'AnswerSource',
    as InstanceOf['Google::Cloud::Dialogflow::V2::Conversation::SearchKnowledgeAnswer::AnswerSource'];

coerce 'AnswerSource',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::Conversation::SearchKnowledgeAnswer::AnswerSource'->new($_) };

declare 'RepeatedAnswerSource',
    as ArrayRef[AnswerSource()];

coerce 'RepeatedAnswerSource',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::Conversation::SearchKnowledgeAnswer::AnswerSource'->new($_) } @$_ ] };

declare 'MapStringAnswerSource',
    as HashRef[AnswerSource()];

declare 'GenerateSuggestionsRequest',
    as InstanceOf['Google::Cloud::Dialogflow::V2::Conversation::GenerateSuggestionsRequest'];

coerce 'GenerateSuggestionsRequest',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::Conversation::GenerateSuggestionsRequest'->new($_) };

declare 'RepeatedGenerateSuggestionsRequest',
    as ArrayRef[GenerateSuggestionsRequest()];

coerce 'RepeatedGenerateSuggestionsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::Conversation::GenerateSuggestionsRequest'->new($_) } @$_ ] };

declare 'MapStringGenerateSuggestionsRequest',
    as HashRef[GenerateSuggestionsRequest()];

1;

__END__

=head1 NAME

Google::Cloud::Dialogflow::V2::Conversation::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
