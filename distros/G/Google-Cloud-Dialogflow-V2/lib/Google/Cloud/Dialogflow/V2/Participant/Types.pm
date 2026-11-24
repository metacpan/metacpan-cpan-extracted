package Google::Cloud::Dialogflow::V2::Participant::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'DatastoreResponseReason',
    as (Int | Str);

declare 'Participant',
    as InstanceOf['Google::Cloud::Dialogflow::V2::Participant::Participant'];

coerce 'Participant',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::Participant::Participant'->new($_) };

declare 'RepeatedParticipant',
    as ArrayRef[Participant()];

coerce 'RepeatedParticipant',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::Participant::Participant'->new($_) } @$_ ] };

declare 'MapStringParticipant',
    as HashRef[Participant()];

declare 'Role',
    as (Int | Str);

declare 'AgentDesktopSource',
    as (Int | Str);

declare 'DocumentsMetadataFiltersEntry',
    as InstanceOf['Google::Cloud::Dialogflow::V2::Participant::Participant::DocumentsMetadataFiltersEntry'];

coerce 'DocumentsMetadataFiltersEntry',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::Participant::Participant::DocumentsMetadataFiltersEntry'->new($_) };

declare 'RepeatedDocumentsMetadataFiltersEntry',
    as ArrayRef[DocumentsMetadataFiltersEntry()];

coerce 'RepeatedDocumentsMetadataFiltersEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::Participant::Participant::DocumentsMetadataFiltersEntry'->new($_) } @$_ ] };

declare 'MapStringDocumentsMetadataFiltersEntry',
    as HashRef[DocumentsMetadataFiltersEntry()];

declare 'Message',
    as InstanceOf['Google::Cloud::Dialogflow::V2::Participant::Message'];

coerce 'Message',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::Participant::Message'->new($_) };

declare 'RepeatedMessage',
    as ArrayRef[Message()];

coerce 'RepeatedMessage',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::Participant::Message'->new($_) } @$_ ] };

declare 'MapStringMessage',
    as HashRef[Message()];

declare 'CreateParticipantRequest',
    as InstanceOf['Google::Cloud::Dialogflow::V2::Participant::CreateParticipantRequest'];

coerce 'CreateParticipantRequest',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::Participant::CreateParticipantRequest'->new($_) };

declare 'RepeatedCreateParticipantRequest',
    as ArrayRef[CreateParticipantRequest()];

coerce 'RepeatedCreateParticipantRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::Participant::CreateParticipantRequest'->new($_) } @$_ ] };

declare 'MapStringCreateParticipantRequest',
    as HashRef[CreateParticipantRequest()];

declare 'GetParticipantRequest',
    as InstanceOf['Google::Cloud::Dialogflow::V2::Participant::GetParticipantRequest'];

coerce 'GetParticipantRequest',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::Participant::GetParticipantRequest'->new($_) };

declare 'RepeatedGetParticipantRequest',
    as ArrayRef[GetParticipantRequest()];

coerce 'RepeatedGetParticipantRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::Participant::GetParticipantRequest'->new($_) } @$_ ] };

declare 'MapStringGetParticipantRequest',
    as HashRef[GetParticipantRequest()];

declare 'ListParticipantsRequest',
    as InstanceOf['Google::Cloud::Dialogflow::V2::Participant::ListParticipantsRequest'];

coerce 'ListParticipantsRequest',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::Participant::ListParticipantsRequest'->new($_) };

declare 'RepeatedListParticipantsRequest',
    as ArrayRef[ListParticipantsRequest()];

coerce 'RepeatedListParticipantsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::Participant::ListParticipantsRequest'->new($_) } @$_ ] };

declare 'MapStringListParticipantsRequest',
    as HashRef[ListParticipantsRequest()];

declare 'ListParticipantsResponse',
    as InstanceOf['Google::Cloud::Dialogflow::V2::Participant::ListParticipantsResponse'];

coerce 'ListParticipantsResponse',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::Participant::ListParticipantsResponse'->new($_) };

declare 'RepeatedListParticipantsResponse',
    as ArrayRef[ListParticipantsResponse()];

coerce 'RepeatedListParticipantsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::Participant::ListParticipantsResponse'->new($_) } @$_ ] };

declare 'MapStringListParticipantsResponse',
    as HashRef[ListParticipantsResponse()];

declare 'UpdateParticipantRequest',
    as InstanceOf['Google::Cloud::Dialogflow::V2::Participant::UpdateParticipantRequest'];

coerce 'UpdateParticipantRequest',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::Participant::UpdateParticipantRequest'->new($_) };

declare 'RepeatedUpdateParticipantRequest',
    as ArrayRef[UpdateParticipantRequest()];

coerce 'RepeatedUpdateParticipantRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::Participant::UpdateParticipantRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateParticipantRequest',
    as HashRef[UpdateParticipantRequest()];

declare 'AnalyzeContentRequest',
    as InstanceOf['Google::Cloud::Dialogflow::V2::Participant::AnalyzeContentRequest'];

coerce 'AnalyzeContentRequest',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::Participant::AnalyzeContentRequest'->new($_) };

declare 'RepeatedAnalyzeContentRequest',
    as ArrayRef[AnalyzeContentRequest()];

coerce 'RepeatedAnalyzeContentRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::Participant::AnalyzeContentRequest'->new($_) } @$_ ] };

declare 'MapStringAnalyzeContentRequest',
    as HashRef[AnalyzeContentRequest()];

declare 'DtmfParameters',
    as InstanceOf['Google::Cloud::Dialogflow::V2::Participant::DtmfParameters'];

coerce 'DtmfParameters',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::Participant::DtmfParameters'->new($_) };

declare 'RepeatedDtmfParameters',
    as ArrayRef[DtmfParameters()];

coerce 'RepeatedDtmfParameters',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::Participant::DtmfParameters'->new($_) } @$_ ] };

declare 'MapStringDtmfParameters',
    as HashRef[DtmfParameters()];

declare 'AnalyzeContentResponse',
    as InstanceOf['Google::Cloud::Dialogflow::V2::Participant::AnalyzeContentResponse'];

coerce 'AnalyzeContentResponse',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::Participant::AnalyzeContentResponse'->new($_) };

declare 'RepeatedAnalyzeContentResponse',
    as ArrayRef[AnalyzeContentResponse()];

coerce 'RepeatedAnalyzeContentResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::Participant::AnalyzeContentResponse'->new($_) } @$_ ] };

declare 'MapStringAnalyzeContentResponse',
    as HashRef[AnalyzeContentResponse()];

declare 'StreamingAnalyzeContentRequest',
    as InstanceOf['Google::Cloud::Dialogflow::V2::Participant::StreamingAnalyzeContentRequest'];

coerce 'StreamingAnalyzeContentRequest',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::Participant::StreamingAnalyzeContentRequest'->new($_) };

declare 'RepeatedStreamingAnalyzeContentRequest',
    as ArrayRef[StreamingAnalyzeContentRequest()];

coerce 'RepeatedStreamingAnalyzeContentRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::Participant::StreamingAnalyzeContentRequest'->new($_) } @$_ ] };

declare 'MapStringStreamingAnalyzeContentRequest',
    as HashRef[StreamingAnalyzeContentRequest()];

declare 'StreamingAnalyzeContentResponse',
    as InstanceOf['Google::Cloud::Dialogflow::V2::Participant::StreamingAnalyzeContentResponse'];

coerce 'StreamingAnalyzeContentResponse',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::Participant::StreamingAnalyzeContentResponse'->new($_) };

declare 'RepeatedStreamingAnalyzeContentResponse',
    as ArrayRef[StreamingAnalyzeContentResponse()];

coerce 'RepeatedStreamingAnalyzeContentResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::Participant::StreamingAnalyzeContentResponse'->new($_) } @$_ ] };

declare 'MapStringStreamingAnalyzeContentResponse',
    as HashRef[StreamingAnalyzeContentResponse()];

declare 'SuggestArticlesRequest',
    as InstanceOf['Google::Cloud::Dialogflow::V2::Participant::SuggestArticlesRequest'];

coerce 'SuggestArticlesRequest',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::Participant::SuggestArticlesRequest'->new($_) };

declare 'RepeatedSuggestArticlesRequest',
    as ArrayRef[SuggestArticlesRequest()];

coerce 'RepeatedSuggestArticlesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::Participant::SuggestArticlesRequest'->new($_) } @$_ ] };

declare 'MapStringSuggestArticlesRequest',
    as HashRef[SuggestArticlesRequest()];

declare 'SuggestArticlesResponse',
    as InstanceOf['Google::Cloud::Dialogflow::V2::Participant::SuggestArticlesResponse'];

coerce 'SuggestArticlesResponse',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::Participant::SuggestArticlesResponse'->new($_) };

declare 'RepeatedSuggestArticlesResponse',
    as ArrayRef[SuggestArticlesResponse()];

coerce 'RepeatedSuggestArticlesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::Participant::SuggestArticlesResponse'->new($_) } @$_ ] };

declare 'MapStringSuggestArticlesResponse',
    as HashRef[SuggestArticlesResponse()];

declare 'SuggestFaqAnswersRequest',
    as InstanceOf['Google::Cloud::Dialogflow::V2::Participant::SuggestFaqAnswersRequest'];

coerce 'SuggestFaqAnswersRequest',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::Participant::SuggestFaqAnswersRequest'->new($_) };

declare 'RepeatedSuggestFaqAnswersRequest',
    as ArrayRef[SuggestFaqAnswersRequest()];

coerce 'RepeatedSuggestFaqAnswersRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::Participant::SuggestFaqAnswersRequest'->new($_) } @$_ ] };

declare 'MapStringSuggestFaqAnswersRequest',
    as HashRef[SuggestFaqAnswersRequest()];

declare 'SuggestFaqAnswersResponse',
    as InstanceOf['Google::Cloud::Dialogflow::V2::Participant::SuggestFaqAnswersResponse'];

coerce 'SuggestFaqAnswersResponse',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::Participant::SuggestFaqAnswersResponse'->new($_) };

declare 'RepeatedSuggestFaqAnswersResponse',
    as ArrayRef[SuggestFaqAnswersResponse()];

coerce 'RepeatedSuggestFaqAnswersResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::Participant::SuggestFaqAnswersResponse'->new($_) } @$_ ] };

declare 'MapStringSuggestFaqAnswersResponse',
    as HashRef[SuggestFaqAnswersResponse()];

declare 'GenerateSuggestionsResponse',
    as InstanceOf['Google::Cloud::Dialogflow::V2::Participant::GenerateSuggestionsResponse'];

coerce 'GenerateSuggestionsResponse',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::Participant::GenerateSuggestionsResponse'->new($_) };

declare 'RepeatedGenerateSuggestionsResponse',
    as ArrayRef[GenerateSuggestionsResponse()];

coerce 'RepeatedGenerateSuggestionsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::Participant::GenerateSuggestionsResponse'->new($_) } @$_ ] };

declare 'MapStringGenerateSuggestionsResponse',
    as HashRef[GenerateSuggestionsResponse()];

declare 'GeneratorSuggestionAnswer',
    as InstanceOf['Google::Cloud::Dialogflow::V2::Participant::GenerateSuggestionsResponse::GeneratorSuggestionAnswer'];

coerce 'GeneratorSuggestionAnswer',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::Participant::GenerateSuggestionsResponse::GeneratorSuggestionAnswer'->new($_) };

declare 'RepeatedGeneratorSuggestionAnswer',
    as ArrayRef[GeneratorSuggestionAnswer()];

coerce 'RepeatedGeneratorSuggestionAnswer',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::Participant::GenerateSuggestionsResponse::GeneratorSuggestionAnswer'->new($_) } @$_ ] };

declare 'MapStringGeneratorSuggestionAnswer',
    as HashRef[GeneratorSuggestionAnswer()];

declare 'ToolCallSuggestion',
    as InstanceOf['Google::Cloud::Dialogflow::V2::Participant::ToolCallSuggestion'];

coerce 'ToolCallSuggestion',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::Participant::ToolCallSuggestion'->new($_) };

declare 'RepeatedToolCallSuggestion',
    as ArrayRef[ToolCallSuggestion()];

coerce 'RepeatedToolCallSuggestion',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::Participant::ToolCallSuggestion'->new($_) } @$_ ] };

declare 'MapStringToolCallSuggestion',
    as HashRef[ToolCallSuggestion()];

declare 'ToolCallEvents',
    as InstanceOf['Google::Cloud::Dialogflow::V2::Participant::ToolCallEvents'];

coerce 'ToolCallEvents',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::Participant::ToolCallEvents'->new($_) };

declare 'RepeatedToolCallEvents',
    as ArrayRef[ToolCallEvents()];

coerce 'RepeatedToolCallEvents',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::Participant::ToolCallEvents'->new($_) } @$_ ] };

declare 'MapStringToolCallEvents',
    as HashRef[ToolCallEvents()];

declare 'CompanionSuggestion',
    as InstanceOf['Google::Cloud::Dialogflow::V2::Participant::CompanionSuggestion'];

coerce 'CompanionSuggestion',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::Participant::CompanionSuggestion'->new($_) };

declare 'RepeatedCompanionSuggestion',
    as ArrayRef[CompanionSuggestion()];

coerce 'RepeatedCompanionSuggestion',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::Participant::CompanionSuggestion'->new($_) } @$_ ] };

declare 'MapStringCompanionSuggestion',
    as HashRef[CompanionSuggestion()];

declare 'Guidance',
    as InstanceOf['Google::Cloud::Dialogflow::V2::Participant::CompanionSuggestion::Guidance'];

coerce 'Guidance',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::Participant::CompanionSuggestion::Guidance'->new($_) };

declare 'RepeatedGuidance',
    as ArrayRef[Guidance()];

coerce 'RepeatedGuidance',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::Participant::CompanionSuggestion::Guidance'->new($_) } @$_ ] };

declare 'MapStringGuidance',
    as HashRef[Guidance()];

declare 'KnowledgeSource',
    as InstanceOf['Google::Cloud::Dialogflow::V2::Participant::CompanionSuggestion::Guidance::KnowledgeSource'];

coerce 'KnowledgeSource',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::Participant::CompanionSuggestion::Guidance::KnowledgeSource'->new($_) };

declare 'RepeatedKnowledgeSource',
    as ArrayRef[KnowledgeSource()];

coerce 'RepeatedKnowledgeSource',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::Participant::CompanionSuggestion::Guidance::KnowledgeSource'->new($_) } @$_ ] };

declare 'MapStringKnowledgeSource',
    as HashRef[KnowledgeSource()];

declare 'GenerateCompanionSuggestionsResponse',
    as InstanceOf['Google::Cloud::Dialogflow::V2::Participant::GenerateCompanionSuggestionsResponse'];

coerce 'GenerateCompanionSuggestionsResponse',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::Participant::GenerateCompanionSuggestionsResponse'->new($_) };

declare 'RepeatedGenerateCompanionSuggestionsResponse',
    as ArrayRef[GenerateCompanionSuggestionsResponse()];

coerce 'RepeatedGenerateCompanionSuggestionsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::Participant::GenerateCompanionSuggestionsResponse'->new($_) } @$_ ] };

declare 'MapStringGenerateCompanionSuggestionsResponse',
    as HashRef[GenerateCompanionSuggestionsResponse()];

declare 'SuggestSmartRepliesRequest',
    as InstanceOf['Google::Cloud::Dialogflow::V2::Participant::SuggestSmartRepliesRequest'];

coerce 'SuggestSmartRepliesRequest',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::Participant::SuggestSmartRepliesRequest'->new($_) };

declare 'RepeatedSuggestSmartRepliesRequest',
    as ArrayRef[SuggestSmartRepliesRequest()];

coerce 'RepeatedSuggestSmartRepliesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::Participant::SuggestSmartRepliesRequest'->new($_) } @$_ ] };

declare 'MapStringSuggestSmartRepliesRequest',
    as HashRef[SuggestSmartRepliesRequest()];

declare 'SuggestSmartRepliesResponse',
    as InstanceOf['Google::Cloud::Dialogflow::V2::Participant::SuggestSmartRepliesResponse'];

coerce 'SuggestSmartRepliesResponse',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::Participant::SuggestSmartRepliesResponse'->new($_) };

declare 'RepeatedSuggestSmartRepliesResponse',
    as ArrayRef[SuggestSmartRepliesResponse()];

coerce 'RepeatedSuggestSmartRepliesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::Participant::SuggestSmartRepliesResponse'->new($_) } @$_ ] };

declare 'MapStringSuggestSmartRepliesResponse',
    as HashRef[SuggestSmartRepliesResponse()];

declare 'AudioInput',
    as InstanceOf['Google::Cloud::Dialogflow::V2::Participant::AudioInput'];

coerce 'AudioInput',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::Participant::AudioInput'->new($_) };

declare 'RepeatedAudioInput',
    as ArrayRef[AudioInput()];

coerce 'RepeatedAudioInput',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::Participant::AudioInput'->new($_) } @$_ ] };

declare 'MapStringAudioInput',
    as HashRef[AudioInput()];

declare 'OutputAudio',
    as InstanceOf['Google::Cloud::Dialogflow::V2::Participant::OutputAudio'];

coerce 'OutputAudio',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::Participant::OutputAudio'->new($_) };

declare 'RepeatedOutputAudio',
    as ArrayRef[OutputAudio()];

coerce 'RepeatedOutputAudio',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::Participant::OutputAudio'->new($_) } @$_ ] };

declare 'MapStringOutputAudio',
    as HashRef[OutputAudio()];

declare 'AutomatedAgentReply',
    as InstanceOf['Google::Cloud::Dialogflow::V2::Participant::AutomatedAgentReply'];

coerce 'AutomatedAgentReply',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::Participant::AutomatedAgentReply'->new($_) };

declare 'RepeatedAutomatedAgentReply',
    as ArrayRef[AutomatedAgentReply()];

coerce 'RepeatedAutomatedAgentReply',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::Participant::AutomatedAgentReply'->new($_) } @$_ ] };

declare 'MapStringAutomatedAgentReply',
    as HashRef[AutomatedAgentReply()];

declare 'AutomatedAgentReplyType',
    as (Int | Str);

declare 'ArticleAnswer',
    as InstanceOf['Google::Cloud::Dialogflow::V2::Participant::ArticleAnswer'];

coerce 'ArticleAnswer',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::Participant::ArticleAnswer'->new($_) };

declare 'RepeatedArticleAnswer',
    as ArrayRef[ArticleAnswer()];

coerce 'RepeatedArticleAnswer',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::Participant::ArticleAnswer'->new($_) } @$_ ] };

declare 'MapStringArticleAnswer',
    as HashRef[ArticleAnswer()];

declare 'MetadataEntry',
    as InstanceOf['Google::Cloud::Dialogflow::V2::Participant::ArticleAnswer::MetadataEntry'];

coerce 'MetadataEntry',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::Participant::ArticleAnswer::MetadataEntry'->new($_) };

declare 'RepeatedMetadataEntry',
    as ArrayRef[MetadataEntry()];

coerce 'RepeatedMetadataEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::Participant::ArticleAnswer::MetadataEntry'->new($_) } @$_ ] };

declare 'MapStringMetadataEntry',
    as HashRef[MetadataEntry()];

declare 'FaqAnswer',
    as InstanceOf['Google::Cloud::Dialogflow::V2::Participant::FaqAnswer'];

coerce 'FaqAnswer',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::Participant::FaqAnswer'->new($_) };

declare 'RepeatedFaqAnswer',
    as ArrayRef[FaqAnswer()];

coerce 'RepeatedFaqAnswer',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::Participant::FaqAnswer'->new($_) } @$_ ] };

declare 'MapStringFaqAnswer',
    as HashRef[FaqAnswer()];

declare 'MetadataEntry',
    as InstanceOf['Google::Cloud::Dialogflow::V2::Participant::FaqAnswer::MetadataEntry'];

coerce 'MetadataEntry',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::Participant::FaqAnswer::MetadataEntry'->new($_) };

declare 'RepeatedMetadataEntry',
    as ArrayRef[MetadataEntry()];

coerce 'RepeatedMetadataEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::Participant::FaqAnswer::MetadataEntry'->new($_) } @$_ ] };

declare 'MapStringMetadataEntry',
    as HashRef[MetadataEntry()];

declare 'SmartReplyAnswer',
    as InstanceOf['Google::Cloud::Dialogflow::V2::Participant::SmartReplyAnswer'];

coerce 'SmartReplyAnswer',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::Participant::SmartReplyAnswer'->new($_) };

declare 'RepeatedSmartReplyAnswer',
    as ArrayRef[SmartReplyAnswer()];

coerce 'RepeatedSmartReplyAnswer',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::Participant::SmartReplyAnswer'->new($_) } @$_ ] };

declare 'MapStringSmartReplyAnswer',
    as HashRef[SmartReplyAnswer()];

declare 'IntentSuggestion',
    as InstanceOf['Google::Cloud::Dialogflow::V2::Participant::IntentSuggestion'];

coerce 'IntentSuggestion',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::Participant::IntentSuggestion'->new($_) };

declare 'RepeatedIntentSuggestion',
    as ArrayRef[IntentSuggestion()];

coerce 'RepeatedIntentSuggestion',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::Participant::IntentSuggestion'->new($_) } @$_ ] };

declare 'MapStringIntentSuggestion',
    as HashRef[IntentSuggestion()];

declare 'DialogflowAssistAnswer',
    as InstanceOf['Google::Cloud::Dialogflow::V2::Participant::DialogflowAssistAnswer'];

coerce 'DialogflowAssistAnswer',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::Participant::DialogflowAssistAnswer'->new($_) };

declare 'RepeatedDialogflowAssistAnswer',
    as ArrayRef[DialogflowAssistAnswer()];

coerce 'RepeatedDialogflowAssistAnswer',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::Participant::DialogflowAssistAnswer'->new($_) } @$_ ] };

declare 'MapStringDialogflowAssistAnswer',
    as HashRef[DialogflowAssistAnswer()];

declare 'SuggestionResult',
    as InstanceOf['Google::Cloud::Dialogflow::V2::Participant::SuggestionResult'];

coerce 'SuggestionResult',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::Participant::SuggestionResult'->new($_) };

declare 'RepeatedSuggestionResult',
    as ArrayRef[SuggestionResult()];

coerce 'RepeatedSuggestionResult',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::Participant::SuggestionResult'->new($_) } @$_ ] };

declare 'MapStringSuggestionResult',
    as HashRef[SuggestionResult()];

declare 'InputTextConfig',
    as InstanceOf['Google::Cloud::Dialogflow::V2::Participant::InputTextConfig'];

coerce 'InputTextConfig',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::Participant::InputTextConfig'->new($_) };

declare 'RepeatedInputTextConfig',
    as ArrayRef[InputTextConfig()];

coerce 'RepeatedInputTextConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::Participant::InputTextConfig'->new($_) } @$_ ] };

declare 'MapStringInputTextConfig',
    as HashRef[InputTextConfig()];

declare 'AnnotatedMessagePart',
    as InstanceOf['Google::Cloud::Dialogflow::V2::Participant::AnnotatedMessagePart'];

coerce 'AnnotatedMessagePart',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::Participant::AnnotatedMessagePart'->new($_) };

declare 'RepeatedAnnotatedMessagePart',
    as ArrayRef[AnnotatedMessagePart()];

coerce 'RepeatedAnnotatedMessagePart',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::Participant::AnnotatedMessagePart'->new($_) } @$_ ] };

declare 'MapStringAnnotatedMessagePart',
    as HashRef[AnnotatedMessagePart()];

declare 'MessageAnnotation',
    as InstanceOf['Google::Cloud::Dialogflow::V2::Participant::MessageAnnotation'];

coerce 'MessageAnnotation',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::Participant::MessageAnnotation'->new($_) };

declare 'RepeatedMessageAnnotation',
    as ArrayRef[MessageAnnotation()];

coerce 'RepeatedMessageAnnotation',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::Participant::MessageAnnotation'->new($_) } @$_ ] };

declare 'MapStringMessageAnnotation',
    as HashRef[MessageAnnotation()];

declare 'SuggestionInput',
    as InstanceOf['Google::Cloud::Dialogflow::V2::Participant::SuggestionInput'];

coerce 'SuggestionInput',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::Participant::SuggestionInput'->new($_) };

declare 'RepeatedSuggestionInput',
    as ArrayRef[SuggestionInput()];

coerce 'RepeatedSuggestionInput',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::Participant::SuggestionInput'->new($_) } @$_ ] };

declare 'MapStringSuggestionInput',
    as HashRef[SuggestionInput()];

declare 'Action',
    as (Int | Str);

declare 'AssistQueryParameters',
    as InstanceOf['Google::Cloud::Dialogflow::V2::Participant::AssistQueryParameters'];

coerce 'AssistQueryParameters',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::Participant::AssistQueryParameters'->new($_) };

declare 'RepeatedAssistQueryParameters',
    as ArrayRef[AssistQueryParameters()];

coerce 'RepeatedAssistQueryParameters',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::Participant::AssistQueryParameters'->new($_) } @$_ ] };

declare 'MapStringAssistQueryParameters',
    as HashRef[AssistQueryParameters()];

declare 'DocumentsMetadataFiltersEntry',
    as InstanceOf['Google::Cloud::Dialogflow::V2::Participant::AssistQueryParameters::DocumentsMetadataFiltersEntry'];

coerce 'DocumentsMetadataFiltersEntry',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::Participant::AssistQueryParameters::DocumentsMetadataFiltersEntry'->new($_) };

declare 'RepeatedDocumentsMetadataFiltersEntry',
    as ArrayRef[DocumentsMetadataFiltersEntry()];

coerce 'RepeatedDocumentsMetadataFiltersEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::Participant::AssistQueryParameters::DocumentsMetadataFiltersEntry'->new($_) } @$_ ] };

declare 'MapStringDocumentsMetadataFiltersEntry',
    as HashRef[DocumentsMetadataFiltersEntry()];

declare 'ResponseMessage',
    as InstanceOf['Google::Cloud::Dialogflow::V2::Participant::ResponseMessage'];

coerce 'ResponseMessage',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::Participant::ResponseMessage'->new($_) };

declare 'RepeatedResponseMessage',
    as ArrayRef[ResponseMessage()];

coerce 'RepeatedResponseMessage',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::Participant::ResponseMessage'->new($_) } @$_ ] };

declare 'MapStringResponseMessage',
    as HashRef[ResponseMessage()];

declare 'Text',
    as InstanceOf['Google::Cloud::Dialogflow::V2::Participant::ResponseMessage::Text'];

coerce 'Text',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::Participant::ResponseMessage::Text'->new($_) };

declare 'RepeatedText',
    as ArrayRef[Text()];

coerce 'RepeatedText',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::Participant::ResponseMessage::Text'->new($_) } @$_ ] };

declare 'MapStringText',
    as HashRef[Text()];

declare 'LiveAgentHandoff',
    as InstanceOf['Google::Cloud::Dialogflow::V2::Participant::ResponseMessage::LiveAgentHandoff'];

coerce 'LiveAgentHandoff',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::Participant::ResponseMessage::LiveAgentHandoff'->new($_) };

declare 'RepeatedLiveAgentHandoff',
    as ArrayRef[LiveAgentHandoff()];

coerce 'RepeatedLiveAgentHandoff',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::Participant::ResponseMessage::LiveAgentHandoff'->new($_) } @$_ ] };

declare 'MapStringLiveAgentHandoff',
    as HashRef[LiveAgentHandoff()];

declare 'EndInteraction',
    as InstanceOf['Google::Cloud::Dialogflow::V2::Participant::ResponseMessage::EndInteraction'];

coerce 'EndInteraction',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::Participant::ResponseMessage::EndInteraction'->new($_) };

declare 'RepeatedEndInteraction',
    as ArrayRef[EndInteraction()];

coerce 'RepeatedEndInteraction',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::Participant::ResponseMessage::EndInteraction'->new($_) } @$_ ] };

declare 'MapStringEndInteraction',
    as HashRef[EndInteraction()];

declare 'MixedAudio',
    as InstanceOf['Google::Cloud::Dialogflow::V2::Participant::ResponseMessage::MixedAudio'];

coerce 'MixedAudio',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::Participant::ResponseMessage::MixedAudio'->new($_) };

declare 'RepeatedMixedAudio',
    as ArrayRef[MixedAudio()];

coerce 'RepeatedMixedAudio',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::Participant::ResponseMessage::MixedAudio'->new($_) } @$_ ] };

declare 'MapStringMixedAudio',
    as HashRef[MixedAudio()];

declare 'Segment',
    as InstanceOf['Google::Cloud::Dialogflow::V2::Participant::ResponseMessage::MixedAudio::Segment'];

coerce 'Segment',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::Participant::ResponseMessage::MixedAudio::Segment'->new($_) };

declare 'RepeatedSegment',
    as ArrayRef[Segment()];

coerce 'RepeatedSegment',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::Participant::ResponseMessage::MixedAudio::Segment'->new($_) } @$_ ] };

declare 'MapStringSegment',
    as HashRef[Segment()];

declare 'TelephonyTransferCall',
    as InstanceOf['Google::Cloud::Dialogflow::V2::Participant::ResponseMessage::TelephonyTransferCall'];

coerce 'TelephonyTransferCall',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::Participant::ResponseMessage::TelephonyTransferCall'->new($_) };

declare 'RepeatedTelephonyTransferCall',
    as ArrayRef[TelephonyTransferCall()];

coerce 'RepeatedTelephonyTransferCall',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::Participant::ResponseMessage::TelephonyTransferCall'->new($_) } @$_ ] };

declare 'MapStringTelephonyTransferCall',
    as HashRef[TelephonyTransferCall()];

declare 'SuggestKnowledgeAssistRequest',
    as InstanceOf['Google::Cloud::Dialogflow::V2::Participant::SuggestKnowledgeAssistRequest'];

coerce 'SuggestKnowledgeAssistRequest',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::Participant::SuggestKnowledgeAssistRequest'->new($_) };

declare 'RepeatedSuggestKnowledgeAssistRequest',
    as ArrayRef[SuggestKnowledgeAssistRequest()];

coerce 'RepeatedSuggestKnowledgeAssistRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::Participant::SuggestKnowledgeAssistRequest'->new($_) } @$_ ] };

declare 'MapStringSuggestKnowledgeAssistRequest',
    as HashRef[SuggestKnowledgeAssistRequest()];

declare 'SuggestKnowledgeAssistResponse',
    as InstanceOf['Google::Cloud::Dialogflow::V2::Participant::SuggestKnowledgeAssistResponse'];

coerce 'SuggestKnowledgeAssistResponse',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::Participant::SuggestKnowledgeAssistResponse'->new($_) };

declare 'RepeatedSuggestKnowledgeAssistResponse',
    as ArrayRef[SuggestKnowledgeAssistResponse()];

coerce 'RepeatedSuggestKnowledgeAssistResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::Participant::SuggestKnowledgeAssistResponse'->new($_) } @$_ ] };

declare 'MapStringSuggestKnowledgeAssistResponse',
    as HashRef[SuggestKnowledgeAssistResponse()];

declare 'IngestedContextReferenceDebugInfo',
    as InstanceOf['Google::Cloud::Dialogflow::V2::Participant::IngestedContextReferenceDebugInfo'];

coerce 'IngestedContextReferenceDebugInfo',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::Participant::IngestedContextReferenceDebugInfo'->new($_) };

declare 'RepeatedIngestedContextReferenceDebugInfo',
    as ArrayRef[IngestedContextReferenceDebugInfo()];

coerce 'RepeatedIngestedContextReferenceDebugInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::Participant::IngestedContextReferenceDebugInfo'->new($_) } @$_ ] };

declare 'MapStringIngestedContextReferenceDebugInfo',
    as HashRef[IngestedContextReferenceDebugInfo()];

declare 'IngestedParameterDebugInfo',
    as InstanceOf['Google::Cloud::Dialogflow::V2::Participant::IngestedContextReferenceDebugInfo::IngestedParameterDebugInfo'];

coerce 'IngestedParameterDebugInfo',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::Participant::IngestedContextReferenceDebugInfo::IngestedParameterDebugInfo'->new($_) };

declare 'RepeatedIngestedParameterDebugInfo',
    as ArrayRef[IngestedParameterDebugInfo()];

coerce 'RepeatedIngestedParameterDebugInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::Participant::IngestedContextReferenceDebugInfo::IngestedParameterDebugInfo'->new($_) } @$_ ] };

declare 'MapStringIngestedParameterDebugInfo',
    as HashRef[IngestedParameterDebugInfo()];

declare 'IngestionStatus',
    as (Int | Str);

declare 'ServiceLatency',
    as InstanceOf['Google::Cloud::Dialogflow::V2::Participant::ServiceLatency'];

coerce 'ServiceLatency',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::Participant::ServiceLatency'->new($_) };

declare 'RepeatedServiceLatency',
    as ArrayRef[ServiceLatency()];

coerce 'RepeatedServiceLatency',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::Participant::ServiceLatency'->new($_) } @$_ ] };

declare 'MapStringServiceLatency',
    as HashRef[ServiceLatency()];

declare 'InternalServiceLatency',
    as InstanceOf['Google::Cloud::Dialogflow::V2::Participant::ServiceLatency::InternalServiceLatency'];

coerce 'InternalServiceLatency',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::Participant::ServiceLatency::InternalServiceLatency'->new($_) };

declare 'RepeatedInternalServiceLatency',
    as ArrayRef[InternalServiceLatency()];

coerce 'RepeatedInternalServiceLatency',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::Participant::ServiceLatency::InternalServiceLatency'->new($_) } @$_ ] };

declare 'MapStringInternalServiceLatency',
    as HashRef[InternalServiceLatency()];

declare 'KnowledgeAssistDebugInfo',
    as InstanceOf['Google::Cloud::Dialogflow::V2::Participant::KnowledgeAssistDebugInfo'];

coerce 'KnowledgeAssistDebugInfo',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::Participant::KnowledgeAssistDebugInfo'->new($_) };

declare 'RepeatedKnowledgeAssistDebugInfo',
    as ArrayRef[KnowledgeAssistDebugInfo()];

coerce 'RepeatedKnowledgeAssistDebugInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::Participant::KnowledgeAssistDebugInfo'->new($_) } @$_ ] };

declare 'MapStringKnowledgeAssistDebugInfo',
    as HashRef[KnowledgeAssistDebugInfo()];

declare 'QueryGenerationFailureReason',
    as (Int | Str);

declare 'QueryCategorizationFailureReason',
    as (Int | Str);

declare 'KnowledgeAssistBehavior',
    as InstanceOf['Google::Cloud::Dialogflow::V2::Participant::KnowledgeAssistDebugInfo::KnowledgeAssistBehavior'];

coerce 'KnowledgeAssistBehavior',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::Participant::KnowledgeAssistDebugInfo::KnowledgeAssistBehavior'->new($_) };

declare 'RepeatedKnowledgeAssistBehavior',
    as ArrayRef[KnowledgeAssistBehavior()];

coerce 'RepeatedKnowledgeAssistBehavior',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::Participant::KnowledgeAssistDebugInfo::KnowledgeAssistBehavior'->new($_) } @$_ ] };

declare 'MapStringKnowledgeAssistBehavior',
    as HashRef[KnowledgeAssistBehavior()];

declare 'QueryGenerationDebugInfo',
    as InstanceOf['Google::Cloud::Dialogflow::V2::Participant::KnowledgeAssistDebugInfo::QueryGenerationDebugInfo'];

coerce 'QueryGenerationDebugInfo',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::Participant::KnowledgeAssistDebugInfo::QueryGenerationDebugInfo'->new($_) };

declare 'RepeatedQueryGenerationDebugInfo',
    as ArrayRef[QueryGenerationDebugInfo()];

coerce 'RepeatedQueryGenerationDebugInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::Participant::KnowledgeAssistDebugInfo::QueryGenerationDebugInfo'->new($_) } @$_ ] };

declare 'MapStringQueryGenerationDebugInfo',
    as HashRef[QueryGenerationDebugInfo()];

declare 'KnowledgeAssistAnswer',
    as InstanceOf['Google::Cloud::Dialogflow::V2::Participant::KnowledgeAssistAnswer'];

coerce 'KnowledgeAssistAnswer',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::Participant::KnowledgeAssistAnswer'->new($_) };

declare 'RepeatedKnowledgeAssistAnswer',
    as ArrayRef[KnowledgeAssistAnswer()];

coerce 'RepeatedKnowledgeAssistAnswer',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::Participant::KnowledgeAssistAnswer'->new($_) } @$_ ] };

declare 'MapStringKnowledgeAssistAnswer',
    as HashRef[KnowledgeAssistAnswer()];

declare 'SuggestedQuery',
    as InstanceOf['Google::Cloud::Dialogflow::V2::Participant::KnowledgeAssistAnswer::SuggestedQuery'];

coerce 'SuggestedQuery',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::Participant::KnowledgeAssistAnswer::SuggestedQuery'->new($_) };

declare 'RepeatedSuggestedQuery',
    as ArrayRef[SuggestedQuery()];

coerce 'RepeatedSuggestedQuery',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::Participant::KnowledgeAssistAnswer::SuggestedQuery'->new($_) } @$_ ] };

declare 'MapStringSuggestedQuery',
    as HashRef[SuggestedQuery()];

declare 'SearchContext',
    as InstanceOf['Google::Cloud::Dialogflow::V2::Participant::KnowledgeAssistAnswer::SuggestedQuery::SearchContext'];

coerce 'SearchContext',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::Participant::KnowledgeAssistAnswer::SuggestedQuery::SearchContext'->new($_) };

declare 'RepeatedSearchContext',
    as ArrayRef[SearchContext()];

coerce 'RepeatedSearchContext',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::Participant::KnowledgeAssistAnswer::SuggestedQuery::SearchContext'->new($_) } @$_ ] };

declare 'MapStringSearchContext',
    as HashRef[SearchContext()];

declare 'AdditionalSuggestedQueryResult',
    as InstanceOf['Google::Cloud::Dialogflow::V2::Participant::KnowledgeAssistAnswer::AdditionalSuggestedQueryResult'];

coerce 'AdditionalSuggestedQueryResult',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::Participant::KnowledgeAssistAnswer::AdditionalSuggestedQueryResult'->new($_) };

declare 'RepeatedAdditionalSuggestedQueryResult',
    as ArrayRef[AdditionalSuggestedQueryResult()];

coerce 'RepeatedAdditionalSuggestedQueryResult',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::Participant::KnowledgeAssistAnswer::AdditionalSuggestedQueryResult'->new($_) } @$_ ] };

declare 'MapStringAdditionalSuggestedQueryResult',
    as HashRef[AdditionalSuggestedQueryResult()];

declare 'KnowledgeAnswer',
    as InstanceOf['Google::Cloud::Dialogflow::V2::Participant::KnowledgeAssistAnswer::KnowledgeAnswer'];

coerce 'KnowledgeAnswer',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::Participant::KnowledgeAssistAnswer::KnowledgeAnswer'->new($_) };

declare 'RepeatedKnowledgeAnswer',
    as ArrayRef[KnowledgeAnswer()];

coerce 'RepeatedKnowledgeAnswer',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::Participant::KnowledgeAssistAnswer::KnowledgeAnswer'->new($_) } @$_ ] };

declare 'MapStringKnowledgeAnswer',
    as HashRef[KnowledgeAnswer()];

declare 'FaqSource',
    as InstanceOf['Google::Cloud::Dialogflow::V2::Participant::KnowledgeAssistAnswer::KnowledgeAnswer::FaqSource'];

coerce 'FaqSource',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::Participant::KnowledgeAssistAnswer::KnowledgeAnswer::FaqSource'->new($_) };

declare 'RepeatedFaqSource',
    as ArrayRef[FaqSource()];

coerce 'RepeatedFaqSource',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::Participant::KnowledgeAssistAnswer::KnowledgeAnswer::FaqSource'->new($_) } @$_ ] };

declare 'MapStringFaqSource',
    as HashRef[FaqSource()];

declare 'GenerativeSource',
    as InstanceOf['Google::Cloud::Dialogflow::V2::Participant::KnowledgeAssistAnswer::KnowledgeAnswer::GenerativeSource'];

coerce 'GenerativeSource',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::Participant::KnowledgeAssistAnswer::KnowledgeAnswer::GenerativeSource'->new($_) };

declare 'RepeatedGenerativeSource',
    as ArrayRef[GenerativeSource()];

coerce 'RepeatedGenerativeSource',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::Participant::KnowledgeAssistAnswer::KnowledgeAnswer::GenerativeSource'->new($_) } @$_ ] };

declare 'MapStringGenerativeSource',
    as HashRef[GenerativeSource()];

declare 'Snippet',
    as InstanceOf['Google::Cloud::Dialogflow::V2::Participant::KnowledgeAssistAnswer::KnowledgeAnswer::GenerativeSource::Snippet'];

coerce 'Snippet',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::Participant::KnowledgeAssistAnswer::KnowledgeAnswer::GenerativeSource::Snippet'->new($_) };

declare 'RepeatedSnippet',
    as ArrayRef[Snippet()];

coerce 'RepeatedSnippet',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::Participant::KnowledgeAssistAnswer::KnowledgeAnswer::GenerativeSource::Snippet'->new($_) } @$_ ] };

declare 'MapStringSnippet',
    as HashRef[Snippet()];

declare 'EventSource',
    as InstanceOf['Google::Cloud::Dialogflow::V2::Participant::KnowledgeAssistAnswer::KnowledgeAnswer::EventSource'];

coerce 'EventSource',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::Participant::KnowledgeAssistAnswer::KnowledgeAnswer::EventSource'->new($_) };

declare 'RepeatedEventSource',
    as ArrayRef[EventSource()];

coerce 'RepeatedEventSource',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::Participant::KnowledgeAssistAnswer::KnowledgeAnswer::EventSource'->new($_) } @$_ ] };

declare 'MapStringEventSource',
    as HashRef[EventSource()];

declare 'StreamingReactiveCompanionSuggestionsRequest',
    as InstanceOf['Google::Cloud::Dialogflow::V2::Participant::StreamingReactiveCompanionSuggestionsRequest'];

coerce 'StreamingReactiveCompanionSuggestionsRequest',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::Participant::StreamingReactiveCompanionSuggestionsRequest'->new($_) };

declare 'RepeatedStreamingReactiveCompanionSuggestionsRequest',
    as ArrayRef[StreamingReactiveCompanionSuggestionsRequest()];

coerce 'RepeatedStreamingReactiveCompanionSuggestionsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::Participant::StreamingReactiveCompanionSuggestionsRequest'->new($_) } @$_ ] };

declare 'MapStringStreamingReactiveCompanionSuggestionsRequest',
    as HashRef[StreamingReactiveCompanionSuggestionsRequest()];

declare 'CancelQuery',
    as InstanceOf['Google::Cloud::Dialogflow::V2::Participant::CancelQuery'];

coerce 'CancelQuery',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::Participant::CancelQuery'->new($_) };

declare 'RepeatedCancelQuery',
    as ArrayRef[CancelQuery()];

coerce 'RepeatedCancelQuery',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::Participant::CancelQuery'->new($_) } @$_ ] };

declare 'MapStringCancelQuery',
    as HashRef[CancelQuery()];

declare 'StreamingReactiveCompanionSuggestionsResponse',
    as InstanceOf['Google::Cloud::Dialogflow::V2::Participant::StreamingReactiveCompanionSuggestionsResponse'];

coerce 'StreamingReactiveCompanionSuggestionsResponse',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::Participant::StreamingReactiveCompanionSuggestionsResponse'->new($_) };

declare 'RepeatedStreamingReactiveCompanionSuggestionsResponse',
    as ArrayRef[StreamingReactiveCompanionSuggestionsResponse()];

coerce 'RepeatedStreamingReactiveCompanionSuggestionsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::Participant::StreamingReactiveCompanionSuggestionsResponse'->new($_) } @$_ ] };

declare 'MapStringStreamingReactiveCompanionSuggestionsResponse',
    as HashRef[StreamingReactiveCompanionSuggestionsResponse()];

declare 'ReactiveModeResponse',
    as InstanceOf['Google::Cloud::Dialogflow::V2::Participant::StreamingReactiveCompanionSuggestionsResponse::ReactiveModeResponse'];

coerce 'ReactiveModeResponse',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::Participant::StreamingReactiveCompanionSuggestionsResponse::ReactiveModeResponse'->new($_) };

declare 'RepeatedReactiveModeResponse',
    as ArrayRef[ReactiveModeResponse()];

coerce 'RepeatedReactiveModeResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::Participant::StreamingReactiveCompanionSuggestionsResponse::ReactiveModeResponse'->new($_) } @$_ ] };

declare 'MapStringReactiveModeResponse',
    as HashRef[ReactiveModeResponse()];

declare 'BidiStreamingAnalyzeContentRequest',
    as InstanceOf['Google::Cloud::Dialogflow::V2::Participant::BidiStreamingAnalyzeContentRequest'];

coerce 'BidiStreamingAnalyzeContentRequest',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::Participant::BidiStreamingAnalyzeContentRequest'->new($_) };

declare 'RepeatedBidiStreamingAnalyzeContentRequest',
    as ArrayRef[BidiStreamingAnalyzeContentRequest()];

coerce 'RepeatedBidiStreamingAnalyzeContentRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::Participant::BidiStreamingAnalyzeContentRequest'->new($_) } @$_ ] };

declare 'MapStringBidiStreamingAnalyzeContentRequest',
    as HashRef[BidiStreamingAnalyzeContentRequest()];

declare 'Config',
    as InstanceOf['Google::Cloud::Dialogflow::V2::Participant::BidiStreamingAnalyzeContentRequest::Config'];

coerce 'Config',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::Participant::BidiStreamingAnalyzeContentRequest::Config'->new($_) };

declare 'RepeatedConfig',
    as ArrayRef[Config()];

coerce 'RepeatedConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::Participant::BidiStreamingAnalyzeContentRequest::Config'->new($_) } @$_ ] };

declare 'MapStringConfig',
    as HashRef[Config()];

declare 'VoiceSessionConfig',
    as InstanceOf['Google::Cloud::Dialogflow::V2::Participant::BidiStreamingAnalyzeContentRequest::Config::VoiceSessionConfig'];

coerce 'VoiceSessionConfig',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::Participant::BidiStreamingAnalyzeContentRequest::Config::VoiceSessionConfig'->new($_) };

declare 'RepeatedVoiceSessionConfig',
    as ArrayRef[VoiceSessionConfig()];

coerce 'RepeatedVoiceSessionConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::Participant::BidiStreamingAnalyzeContentRequest::Config::VoiceSessionConfig'->new($_) } @$_ ] };

declare 'MapStringVoiceSessionConfig',
    as HashRef[VoiceSessionConfig()];

declare 'TurnInput',
    as InstanceOf['Google::Cloud::Dialogflow::V2::Participant::BidiStreamingAnalyzeContentRequest::TurnInput'];

coerce 'TurnInput',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::Participant::BidiStreamingAnalyzeContentRequest::TurnInput'->new($_) };

declare 'RepeatedTurnInput',
    as ArrayRef[TurnInput()];

coerce 'RepeatedTurnInput',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::Participant::BidiStreamingAnalyzeContentRequest::TurnInput'->new($_) } @$_ ] };

declare 'MapStringTurnInput',
    as HashRef[TurnInput()];

declare 'Input',
    as InstanceOf['Google::Cloud::Dialogflow::V2::Participant::BidiStreamingAnalyzeContentRequest::Input'];

coerce 'Input',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::Participant::BidiStreamingAnalyzeContentRequest::Input'->new($_) };

declare 'RepeatedInput',
    as ArrayRef[Input()];

coerce 'RepeatedInput',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::Participant::BidiStreamingAnalyzeContentRequest::Input'->new($_) } @$_ ] };

declare 'MapStringInput',
    as HashRef[Input()];

declare 'BidiStreamingAnalyzeContentResponse',
    as InstanceOf['Google::Cloud::Dialogflow::V2::Participant::BidiStreamingAnalyzeContentResponse'];

coerce 'BidiStreamingAnalyzeContentResponse',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::Participant::BidiStreamingAnalyzeContentResponse'->new($_) };

declare 'RepeatedBidiStreamingAnalyzeContentResponse',
    as ArrayRef[BidiStreamingAnalyzeContentResponse()];

coerce 'RepeatedBidiStreamingAnalyzeContentResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::Participant::BidiStreamingAnalyzeContentResponse'->new($_) } @$_ ] };

declare 'MapStringBidiStreamingAnalyzeContentResponse',
    as HashRef[BidiStreamingAnalyzeContentResponse()];

declare 'BargeInSignal',
    as InstanceOf['Google::Cloud::Dialogflow::V2::Participant::BidiStreamingAnalyzeContentResponse::BargeInSignal'];

coerce 'BargeInSignal',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::Participant::BidiStreamingAnalyzeContentResponse::BargeInSignal'->new($_) };

declare 'RepeatedBargeInSignal',
    as ArrayRef[BargeInSignal()];

coerce 'RepeatedBargeInSignal',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::Participant::BidiStreamingAnalyzeContentResponse::BargeInSignal'->new($_) } @$_ ] };

declare 'MapStringBargeInSignal',
    as HashRef[BargeInSignal()];

declare 'TurnComplete',
    as InstanceOf['Google::Cloud::Dialogflow::V2::Participant::BidiStreamingAnalyzeContentResponse::TurnComplete'];

coerce 'TurnComplete',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::Participant::BidiStreamingAnalyzeContentResponse::TurnComplete'->new($_) };

declare 'RepeatedTurnComplete',
    as ArrayRef[TurnComplete()];

coerce 'RepeatedTurnComplete',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::Participant::BidiStreamingAnalyzeContentResponse::TurnComplete'->new($_) } @$_ ] };

declare 'MapStringTurnComplete',
    as HashRef[TurnComplete()];

1;

__END__

=head1 NAME

Google::Cloud::Dialogflow::V2::Participant::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
