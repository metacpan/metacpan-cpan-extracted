package Google::Cloud::Contactcenterinsights::V1::Resources::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'DatasetValidationWarning',
    as (Int | Str);

declare 'Conversation',
    as InstanceOf['Google::Cloud::Contactcenterinsights::V1::Resources::Conversation'];

coerce 'Conversation',
    from HashRef, via { 'Google::Cloud::Contactcenterinsights::V1::Resources::Conversation'->new($_) };

declare 'RepeatedConversation',
    as ArrayRef[Conversation()];

coerce 'RepeatedConversation',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contactcenterinsights::V1::Resources::Conversation'->new($_) } @$_ ] };

declare 'MapStringConversation',
    as HashRef[Conversation()];

declare 'Medium',
    as (Int | Str);

declare 'CallMetadata',
    as InstanceOf['Google::Cloud::Contactcenterinsights::V1::Resources::Conversation::CallMetadata'];

coerce 'CallMetadata',
    from HashRef, via { 'Google::Cloud::Contactcenterinsights::V1::Resources::Conversation::CallMetadata'->new($_) };

declare 'RepeatedCallMetadata',
    as ArrayRef[CallMetadata()];

coerce 'RepeatedCallMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contactcenterinsights::V1::Resources::Conversation::CallMetadata'->new($_) } @$_ ] };

declare 'MapStringCallMetadata',
    as HashRef[CallMetadata()];

declare 'QualityMetadata',
    as InstanceOf['Google::Cloud::Contactcenterinsights::V1::Resources::Conversation::QualityMetadata'];

coerce 'QualityMetadata',
    from HashRef, via { 'Google::Cloud::Contactcenterinsights::V1::Resources::Conversation::QualityMetadata'->new($_) };

declare 'RepeatedQualityMetadata',
    as ArrayRef[QualityMetadata()];

coerce 'RepeatedQualityMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contactcenterinsights::V1::Resources::Conversation::QualityMetadata'->new($_) } @$_ ] };

declare 'MapStringQualityMetadata',
    as HashRef[QualityMetadata()];

declare 'AgentInfo',
    as InstanceOf['Google::Cloud::Contactcenterinsights::V1::Resources::Conversation::QualityMetadata::AgentInfo'];

coerce 'AgentInfo',
    from HashRef, via { 'Google::Cloud::Contactcenterinsights::V1::Resources::Conversation::QualityMetadata::AgentInfo'->new($_) };

declare 'RepeatedAgentInfo',
    as ArrayRef[AgentInfo()];

coerce 'RepeatedAgentInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contactcenterinsights::V1::Resources::Conversation::QualityMetadata::AgentInfo'->new($_) } @$_ ] };

declare 'MapStringAgentInfo',
    as HashRef[AgentInfo()];

declare 'Transcript',
    as InstanceOf['Google::Cloud::Contactcenterinsights::V1::Resources::Conversation::Transcript'];

coerce 'Transcript',
    from HashRef, via { 'Google::Cloud::Contactcenterinsights::V1::Resources::Conversation::Transcript'->new($_) };

declare 'RepeatedTranscript',
    as ArrayRef[Transcript()];

coerce 'RepeatedTranscript',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contactcenterinsights::V1::Resources::Conversation::Transcript'->new($_) } @$_ ] };

declare 'MapStringTranscript',
    as HashRef[Transcript()];

declare 'TranscriptSegment',
    as InstanceOf['Google::Cloud::Contactcenterinsights::V1::Resources::Conversation::Transcript::TranscriptSegment'];

coerce 'TranscriptSegment',
    from HashRef, via { 'Google::Cloud::Contactcenterinsights::V1::Resources::Conversation::Transcript::TranscriptSegment'->new($_) };

declare 'RepeatedTranscriptSegment',
    as ArrayRef[TranscriptSegment()];

coerce 'RepeatedTranscriptSegment',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contactcenterinsights::V1::Resources::Conversation::Transcript::TranscriptSegment'->new($_) } @$_ ] };

declare 'MapStringTranscriptSegment',
    as HashRef[TranscriptSegment()];

declare 'WordInfo',
    as InstanceOf['Google::Cloud::Contactcenterinsights::V1::Resources::Conversation::Transcript::TranscriptSegment::WordInfo'];

coerce 'WordInfo',
    from HashRef, via { 'Google::Cloud::Contactcenterinsights::V1::Resources::Conversation::Transcript::TranscriptSegment::WordInfo'->new($_) };

declare 'RepeatedWordInfo',
    as ArrayRef[WordInfo()];

coerce 'RepeatedWordInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contactcenterinsights::V1::Resources::Conversation::Transcript::TranscriptSegment::WordInfo'->new($_) } @$_ ] };

declare 'MapStringWordInfo',
    as HashRef[WordInfo()];

declare 'DialogflowSegmentMetadata',
    as InstanceOf['Google::Cloud::Contactcenterinsights::V1::Resources::Conversation::Transcript::TranscriptSegment::DialogflowSegmentMetadata'];

coerce 'DialogflowSegmentMetadata',
    from HashRef, via { 'Google::Cloud::Contactcenterinsights::V1::Resources::Conversation::Transcript::TranscriptSegment::DialogflowSegmentMetadata'->new($_) };

declare 'RepeatedDialogflowSegmentMetadata',
    as ArrayRef[DialogflowSegmentMetadata()];

coerce 'RepeatedDialogflowSegmentMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contactcenterinsights::V1::Resources::Conversation::Transcript::TranscriptSegment::DialogflowSegmentMetadata'->new($_) } @$_ ] };

declare 'MapStringDialogflowSegmentMetadata',
    as HashRef[DialogflowSegmentMetadata()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Contactcenterinsights::V1::Resources::Conversation::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Contactcenterinsights::V1::Resources::Conversation::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contactcenterinsights::V1::Resources::Conversation::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'DialogflowIntentsEntry',
    as InstanceOf['Google::Cloud::Contactcenterinsights::V1::Resources::Conversation::DialogflowIntentsEntry'];

coerce 'DialogflowIntentsEntry',
    from HashRef, via { 'Google::Cloud::Contactcenterinsights::V1::Resources::Conversation::DialogflowIntentsEntry'->new($_) };

declare 'RepeatedDialogflowIntentsEntry',
    as ArrayRef[DialogflowIntentsEntry()];

coerce 'RepeatedDialogflowIntentsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contactcenterinsights::V1::Resources::Conversation::DialogflowIntentsEntry'->new($_) } @$_ ] };

declare 'MapStringDialogflowIntentsEntry',
    as HashRef[DialogflowIntentsEntry()];

declare 'Analysis',
    as InstanceOf['Google::Cloud::Contactcenterinsights::V1::Resources::Analysis'];

coerce 'Analysis',
    from HashRef, via { 'Google::Cloud::Contactcenterinsights::V1::Resources::Analysis'->new($_) };

declare 'RepeatedAnalysis',
    as ArrayRef[Analysis()];

coerce 'RepeatedAnalysis',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contactcenterinsights::V1::Resources::Analysis'->new($_) } @$_ ] };

declare 'MapStringAnalysis',
    as HashRef[Analysis()];

declare 'ConversationDataSource',
    as InstanceOf['Google::Cloud::Contactcenterinsights::V1::Resources::ConversationDataSource'];

coerce 'ConversationDataSource',
    from HashRef, via { 'Google::Cloud::Contactcenterinsights::V1::Resources::ConversationDataSource'->new($_) };

declare 'RepeatedConversationDataSource',
    as ArrayRef[ConversationDataSource()];

coerce 'RepeatedConversationDataSource',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contactcenterinsights::V1::Resources::ConversationDataSource'->new($_) } @$_ ] };

declare 'MapStringConversationDataSource',
    as HashRef[ConversationDataSource()];

declare 'GcsSource',
    as InstanceOf['Google::Cloud::Contactcenterinsights::V1::Resources::GcsSource'];

coerce 'GcsSource',
    from HashRef, via { 'Google::Cloud::Contactcenterinsights::V1::Resources::GcsSource'->new($_) };

declare 'RepeatedGcsSource',
    as ArrayRef[GcsSource()];

coerce 'RepeatedGcsSource',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contactcenterinsights::V1::Resources::GcsSource'->new($_) } @$_ ] };

declare 'MapStringGcsSource',
    as HashRef[GcsSource()];

declare 'DialogflowSource',
    as InstanceOf['Google::Cloud::Contactcenterinsights::V1::Resources::DialogflowSource'];

coerce 'DialogflowSource',
    from HashRef, via { 'Google::Cloud::Contactcenterinsights::V1::Resources::DialogflowSource'->new($_) };

declare 'RepeatedDialogflowSource',
    as ArrayRef[DialogflowSource()];

coerce 'RepeatedDialogflowSource',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contactcenterinsights::V1::Resources::DialogflowSource'->new($_) } @$_ ] };

declare 'MapStringDialogflowSource',
    as HashRef[DialogflowSource()];

declare 'AnalysisResult',
    as InstanceOf['Google::Cloud::Contactcenterinsights::V1::Resources::AnalysisResult'];

coerce 'AnalysisResult',
    from HashRef, via { 'Google::Cloud::Contactcenterinsights::V1::Resources::AnalysisResult'->new($_) };

declare 'RepeatedAnalysisResult',
    as ArrayRef[AnalysisResult()];

coerce 'RepeatedAnalysisResult',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contactcenterinsights::V1::Resources::AnalysisResult'->new($_) } @$_ ] };

declare 'MapStringAnalysisResult',
    as HashRef[AnalysisResult()];

declare 'CallAnalysisMetadata',
    as InstanceOf['Google::Cloud::Contactcenterinsights::V1::Resources::AnalysisResult::CallAnalysisMetadata'];

coerce 'CallAnalysisMetadata',
    from HashRef, via { 'Google::Cloud::Contactcenterinsights::V1::Resources::AnalysisResult::CallAnalysisMetadata'->new($_) };

declare 'RepeatedCallAnalysisMetadata',
    as ArrayRef[CallAnalysisMetadata()];

coerce 'RepeatedCallAnalysisMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contactcenterinsights::V1::Resources::AnalysisResult::CallAnalysisMetadata'->new($_) } @$_ ] };

declare 'MapStringCallAnalysisMetadata',
    as HashRef[CallAnalysisMetadata()];

declare 'EntitiesEntry',
    as InstanceOf['Google::Cloud::Contactcenterinsights::V1::Resources::AnalysisResult::CallAnalysisMetadata::EntitiesEntry'];

coerce 'EntitiesEntry',
    from HashRef, via { 'Google::Cloud::Contactcenterinsights::V1::Resources::AnalysisResult::CallAnalysisMetadata::EntitiesEntry'->new($_) };

declare 'RepeatedEntitiesEntry',
    as ArrayRef[EntitiesEntry()];

coerce 'RepeatedEntitiesEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contactcenterinsights::V1::Resources::AnalysisResult::CallAnalysisMetadata::EntitiesEntry'->new($_) } @$_ ] };

declare 'MapStringEntitiesEntry',
    as HashRef[EntitiesEntry()];

declare 'IntentsEntry',
    as InstanceOf['Google::Cloud::Contactcenterinsights::V1::Resources::AnalysisResult::CallAnalysisMetadata::IntentsEntry'];

coerce 'IntentsEntry',
    from HashRef, via { 'Google::Cloud::Contactcenterinsights::V1::Resources::AnalysisResult::CallAnalysisMetadata::IntentsEntry'->new($_) };

declare 'RepeatedIntentsEntry',
    as ArrayRef[IntentsEntry()];

coerce 'RepeatedIntentsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contactcenterinsights::V1::Resources::AnalysisResult::CallAnalysisMetadata::IntentsEntry'->new($_) } @$_ ] };

declare 'MapStringIntentsEntry',
    as HashRef[IntentsEntry()];

declare 'PhraseMatchersEntry',
    as InstanceOf['Google::Cloud::Contactcenterinsights::V1::Resources::AnalysisResult::CallAnalysisMetadata::PhraseMatchersEntry'];

coerce 'PhraseMatchersEntry',
    from HashRef, via { 'Google::Cloud::Contactcenterinsights::V1::Resources::AnalysisResult::CallAnalysisMetadata::PhraseMatchersEntry'->new($_) };

declare 'RepeatedPhraseMatchersEntry',
    as ArrayRef[PhraseMatchersEntry()];

coerce 'RepeatedPhraseMatchersEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contactcenterinsights::V1::Resources::AnalysisResult::CallAnalysisMetadata::PhraseMatchersEntry'->new($_) } @$_ ] };

declare 'MapStringPhraseMatchersEntry',
    as HashRef[PhraseMatchersEntry()];

declare 'IssueModelResult',
    as InstanceOf['Google::Cloud::Contactcenterinsights::V1::Resources::IssueModelResult'];

coerce 'IssueModelResult',
    from HashRef, via { 'Google::Cloud::Contactcenterinsights::V1::Resources::IssueModelResult'->new($_) };

declare 'RepeatedIssueModelResult',
    as ArrayRef[IssueModelResult()];

coerce 'RepeatedIssueModelResult',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contactcenterinsights::V1::Resources::IssueModelResult'->new($_) } @$_ ] };

declare 'MapStringIssueModelResult',
    as HashRef[IssueModelResult()];

declare 'FeedbackLabel',
    as InstanceOf['Google::Cloud::Contactcenterinsights::V1::Resources::FeedbackLabel'];

coerce 'FeedbackLabel',
    from HashRef, via { 'Google::Cloud::Contactcenterinsights::V1::Resources::FeedbackLabel'->new($_) };

declare 'RepeatedFeedbackLabel',
    as ArrayRef[FeedbackLabel()];

coerce 'RepeatedFeedbackLabel',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contactcenterinsights::V1::Resources::FeedbackLabel'->new($_) } @$_ ] };

declare 'MapStringFeedbackLabel',
    as HashRef[FeedbackLabel()];

declare 'ConversationLevelSentiment',
    as InstanceOf['Google::Cloud::Contactcenterinsights::V1::Resources::ConversationLevelSentiment'];

coerce 'ConversationLevelSentiment',
    from HashRef, via { 'Google::Cloud::Contactcenterinsights::V1::Resources::ConversationLevelSentiment'->new($_) };

declare 'RepeatedConversationLevelSentiment',
    as ArrayRef[ConversationLevelSentiment()];

coerce 'RepeatedConversationLevelSentiment',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contactcenterinsights::V1::Resources::ConversationLevelSentiment'->new($_) } @$_ ] };

declare 'MapStringConversationLevelSentiment',
    as HashRef[ConversationLevelSentiment()];

declare 'ConversationLevelSilence',
    as InstanceOf['Google::Cloud::Contactcenterinsights::V1::Resources::ConversationLevelSilence'];

coerce 'ConversationLevelSilence',
    from HashRef, via { 'Google::Cloud::Contactcenterinsights::V1::Resources::ConversationLevelSilence'->new($_) };

declare 'RepeatedConversationLevelSilence',
    as ArrayRef[ConversationLevelSilence()];

coerce 'RepeatedConversationLevelSilence',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contactcenterinsights::V1::Resources::ConversationLevelSilence'->new($_) } @$_ ] };

declare 'MapStringConversationLevelSilence',
    as HashRef[ConversationLevelSilence()];

declare 'IssueAssignment',
    as InstanceOf['Google::Cloud::Contactcenterinsights::V1::Resources::IssueAssignment'];

coerce 'IssueAssignment',
    from HashRef, via { 'Google::Cloud::Contactcenterinsights::V1::Resources::IssueAssignment'->new($_) };

declare 'RepeatedIssueAssignment',
    as ArrayRef[IssueAssignment()];

coerce 'RepeatedIssueAssignment',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contactcenterinsights::V1::Resources::IssueAssignment'->new($_) } @$_ ] };

declare 'MapStringIssueAssignment',
    as HashRef[IssueAssignment()];

declare 'CallAnnotation',
    as InstanceOf['Google::Cloud::Contactcenterinsights::V1::Resources::CallAnnotation'];

coerce 'CallAnnotation',
    from HashRef, via { 'Google::Cloud::Contactcenterinsights::V1::Resources::CallAnnotation'->new($_) };

declare 'RepeatedCallAnnotation',
    as ArrayRef[CallAnnotation()];

coerce 'RepeatedCallAnnotation',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contactcenterinsights::V1::Resources::CallAnnotation'->new($_) } @$_ ] };

declare 'MapStringCallAnnotation',
    as HashRef[CallAnnotation()];

declare 'AnnotationBoundary',
    as InstanceOf['Google::Cloud::Contactcenterinsights::V1::Resources::AnnotationBoundary'];

coerce 'AnnotationBoundary',
    from HashRef, via { 'Google::Cloud::Contactcenterinsights::V1::Resources::AnnotationBoundary'->new($_) };

declare 'RepeatedAnnotationBoundary',
    as ArrayRef[AnnotationBoundary()];

coerce 'RepeatedAnnotationBoundary',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contactcenterinsights::V1::Resources::AnnotationBoundary'->new($_) } @$_ ] };

declare 'MapStringAnnotationBoundary',
    as HashRef[AnnotationBoundary()];

declare 'Entity',
    as InstanceOf['Google::Cloud::Contactcenterinsights::V1::Resources::Entity'];

coerce 'Entity',
    from HashRef, via { 'Google::Cloud::Contactcenterinsights::V1::Resources::Entity'->new($_) };

declare 'RepeatedEntity',
    as ArrayRef[Entity()];

coerce 'RepeatedEntity',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contactcenterinsights::V1::Resources::Entity'->new($_) } @$_ ] };

declare 'MapStringEntity',
    as HashRef[Entity()];

declare 'Type',
    as (Int | Str);

declare 'MetadataEntry',
    as InstanceOf['Google::Cloud::Contactcenterinsights::V1::Resources::Entity::MetadataEntry'];

coerce 'MetadataEntry',
    from HashRef, via { 'Google::Cloud::Contactcenterinsights::V1::Resources::Entity::MetadataEntry'->new($_) };

declare 'RepeatedMetadataEntry',
    as ArrayRef[MetadataEntry()];

coerce 'RepeatedMetadataEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contactcenterinsights::V1::Resources::Entity::MetadataEntry'->new($_) } @$_ ] };

declare 'MapStringMetadataEntry',
    as HashRef[MetadataEntry()];

declare 'Intent',
    as InstanceOf['Google::Cloud::Contactcenterinsights::V1::Resources::Intent'];

coerce 'Intent',
    from HashRef, via { 'Google::Cloud::Contactcenterinsights::V1::Resources::Intent'->new($_) };

declare 'RepeatedIntent',
    as ArrayRef[Intent()];

coerce 'RepeatedIntent',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contactcenterinsights::V1::Resources::Intent'->new($_) } @$_ ] };

declare 'MapStringIntent',
    as HashRef[Intent()];

declare 'PhraseMatchData',
    as InstanceOf['Google::Cloud::Contactcenterinsights::V1::Resources::PhraseMatchData'];

coerce 'PhraseMatchData',
    from HashRef, via { 'Google::Cloud::Contactcenterinsights::V1::Resources::PhraseMatchData'->new($_) };

declare 'RepeatedPhraseMatchData',
    as ArrayRef[PhraseMatchData()];

coerce 'RepeatedPhraseMatchData',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contactcenterinsights::V1::Resources::PhraseMatchData'->new($_) } @$_ ] };

declare 'MapStringPhraseMatchData',
    as HashRef[PhraseMatchData()];

declare 'DialogflowIntent',
    as InstanceOf['Google::Cloud::Contactcenterinsights::V1::Resources::DialogflowIntent'];

coerce 'DialogflowIntent',
    from HashRef, via { 'Google::Cloud::Contactcenterinsights::V1::Resources::DialogflowIntent'->new($_) };

declare 'RepeatedDialogflowIntent',
    as ArrayRef[DialogflowIntent()];

coerce 'RepeatedDialogflowIntent',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contactcenterinsights::V1::Resources::DialogflowIntent'->new($_) } @$_ ] };

declare 'MapStringDialogflowIntent',
    as HashRef[DialogflowIntent()];

declare 'InterruptionData',
    as InstanceOf['Google::Cloud::Contactcenterinsights::V1::Resources::InterruptionData'];

coerce 'InterruptionData',
    from HashRef, via { 'Google::Cloud::Contactcenterinsights::V1::Resources::InterruptionData'->new($_) };

declare 'RepeatedInterruptionData',
    as ArrayRef[InterruptionData()];

coerce 'RepeatedInterruptionData',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contactcenterinsights::V1::Resources::InterruptionData'->new($_) } @$_ ] };

declare 'MapStringInterruptionData',
    as HashRef[InterruptionData()];

declare 'SilenceData',
    as InstanceOf['Google::Cloud::Contactcenterinsights::V1::Resources::SilenceData'];

coerce 'SilenceData',
    from HashRef, via { 'Google::Cloud::Contactcenterinsights::V1::Resources::SilenceData'->new($_) };

declare 'RepeatedSilenceData',
    as ArrayRef[SilenceData()];

coerce 'RepeatedSilenceData',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contactcenterinsights::V1::Resources::SilenceData'->new($_) } @$_ ] };

declare 'MapStringSilenceData',
    as HashRef[SilenceData()];

declare 'HoldData',
    as InstanceOf['Google::Cloud::Contactcenterinsights::V1::Resources::HoldData'];

coerce 'HoldData',
    from HashRef, via { 'Google::Cloud::Contactcenterinsights::V1::Resources::HoldData'->new($_) };

declare 'RepeatedHoldData',
    as ArrayRef[HoldData()];

coerce 'RepeatedHoldData',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contactcenterinsights::V1::Resources::HoldData'->new($_) } @$_ ] };

declare 'MapStringHoldData',
    as HashRef[HoldData()];

declare 'EntityMentionData',
    as InstanceOf['Google::Cloud::Contactcenterinsights::V1::Resources::EntityMentionData'];

coerce 'EntityMentionData',
    from HashRef, via { 'Google::Cloud::Contactcenterinsights::V1::Resources::EntityMentionData'->new($_) };

declare 'RepeatedEntityMentionData',
    as ArrayRef[EntityMentionData()];

coerce 'RepeatedEntityMentionData',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contactcenterinsights::V1::Resources::EntityMentionData'->new($_) } @$_ ] };

declare 'MapStringEntityMentionData',
    as HashRef[EntityMentionData()];

declare 'MentionType',
    as (Int | Str);

declare 'IntentMatchData',
    as InstanceOf['Google::Cloud::Contactcenterinsights::V1::Resources::IntentMatchData'];

coerce 'IntentMatchData',
    from HashRef, via { 'Google::Cloud::Contactcenterinsights::V1::Resources::IntentMatchData'->new($_) };

declare 'RepeatedIntentMatchData',
    as ArrayRef[IntentMatchData()];

coerce 'RepeatedIntentMatchData',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contactcenterinsights::V1::Resources::IntentMatchData'->new($_) } @$_ ] };

declare 'MapStringIntentMatchData',
    as HashRef[IntentMatchData()];

declare 'SentimentData',
    as InstanceOf['Google::Cloud::Contactcenterinsights::V1::Resources::SentimentData'];

coerce 'SentimentData',
    from HashRef, via { 'Google::Cloud::Contactcenterinsights::V1::Resources::SentimentData'->new($_) };

declare 'RepeatedSentimentData',
    as ArrayRef[SentimentData()];

coerce 'RepeatedSentimentData',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contactcenterinsights::V1::Resources::SentimentData'->new($_) } @$_ ] };

declare 'MapStringSentimentData',
    as HashRef[SentimentData()];

declare 'IssueMatchData',
    as InstanceOf['Google::Cloud::Contactcenterinsights::V1::Resources::IssueMatchData'];

coerce 'IssueMatchData',
    from HashRef, via { 'Google::Cloud::Contactcenterinsights::V1::Resources::IssueMatchData'->new($_) };

declare 'RepeatedIssueMatchData',
    as ArrayRef[IssueMatchData()];

coerce 'RepeatedIssueMatchData',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contactcenterinsights::V1::Resources::IssueMatchData'->new($_) } @$_ ] };

declare 'MapStringIssueMatchData',
    as HashRef[IssueMatchData()];

declare 'IssueModel',
    as InstanceOf['Google::Cloud::Contactcenterinsights::V1::Resources::IssueModel'];

coerce 'IssueModel',
    from HashRef, via { 'Google::Cloud::Contactcenterinsights::V1::Resources::IssueModel'->new($_) };

declare 'RepeatedIssueModel',
    as ArrayRef[IssueModel()];

coerce 'RepeatedIssueModel',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contactcenterinsights::V1::Resources::IssueModel'->new($_) } @$_ ] };

declare 'MapStringIssueModel',
    as HashRef[IssueModel()];

declare 'State',
    as (Int | Str);

declare 'ModelType',
    as (Int | Str);

declare 'InputDataConfig',
    as InstanceOf['Google::Cloud::Contactcenterinsights::V1::Resources::IssueModel::InputDataConfig'];

coerce 'InputDataConfig',
    from HashRef, via { 'Google::Cloud::Contactcenterinsights::V1::Resources::IssueModel::InputDataConfig'->new($_) };

declare 'RepeatedInputDataConfig',
    as ArrayRef[InputDataConfig()];

coerce 'RepeatedInputDataConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contactcenterinsights::V1::Resources::IssueModel::InputDataConfig'->new($_) } @$_ ] };

declare 'MapStringInputDataConfig',
    as HashRef[InputDataConfig()];

declare 'Issue',
    as InstanceOf['Google::Cloud::Contactcenterinsights::V1::Resources::Issue'];

coerce 'Issue',
    from HashRef, via { 'Google::Cloud::Contactcenterinsights::V1::Resources::Issue'->new($_) };

declare 'RepeatedIssue',
    as ArrayRef[Issue()];

coerce 'RepeatedIssue',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contactcenterinsights::V1::Resources::Issue'->new($_) } @$_ ] };

declare 'MapStringIssue',
    as HashRef[Issue()];

declare 'IssueModelLabelStats',
    as InstanceOf['Google::Cloud::Contactcenterinsights::V1::Resources::IssueModelLabelStats'];

coerce 'IssueModelLabelStats',
    from HashRef, via { 'Google::Cloud::Contactcenterinsights::V1::Resources::IssueModelLabelStats'->new($_) };

declare 'RepeatedIssueModelLabelStats',
    as ArrayRef[IssueModelLabelStats()];

coerce 'RepeatedIssueModelLabelStats',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contactcenterinsights::V1::Resources::IssueModelLabelStats'->new($_) } @$_ ] };

declare 'MapStringIssueModelLabelStats',
    as HashRef[IssueModelLabelStats()];

declare 'IssueStats',
    as InstanceOf['Google::Cloud::Contactcenterinsights::V1::Resources::IssueModelLabelStats::IssueStats'];

coerce 'IssueStats',
    from HashRef, via { 'Google::Cloud::Contactcenterinsights::V1::Resources::IssueModelLabelStats::IssueStats'->new($_) };

declare 'RepeatedIssueStats',
    as ArrayRef[IssueStats()];

coerce 'RepeatedIssueStats',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contactcenterinsights::V1::Resources::IssueModelLabelStats::IssueStats'->new($_) } @$_ ] };

declare 'MapStringIssueStats',
    as HashRef[IssueStats()];

declare 'IssueStatsEntry',
    as InstanceOf['Google::Cloud::Contactcenterinsights::V1::Resources::IssueModelLabelStats::IssueStatsEntry'];

coerce 'IssueStatsEntry',
    from HashRef, via { 'Google::Cloud::Contactcenterinsights::V1::Resources::IssueModelLabelStats::IssueStatsEntry'->new($_) };

declare 'RepeatedIssueStatsEntry',
    as ArrayRef[IssueStatsEntry()];

coerce 'RepeatedIssueStatsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contactcenterinsights::V1::Resources::IssueModelLabelStats::IssueStatsEntry'->new($_) } @$_ ] };

declare 'MapStringIssueStatsEntry',
    as HashRef[IssueStatsEntry()];

declare 'PhraseMatcher',
    as InstanceOf['Google::Cloud::Contactcenterinsights::V1::Resources::PhraseMatcher'];

coerce 'PhraseMatcher',
    from HashRef, via { 'Google::Cloud::Contactcenterinsights::V1::Resources::PhraseMatcher'->new($_) };

declare 'RepeatedPhraseMatcher',
    as ArrayRef[PhraseMatcher()];

coerce 'RepeatedPhraseMatcher',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contactcenterinsights::V1::Resources::PhraseMatcher'->new($_) } @$_ ] };

declare 'MapStringPhraseMatcher',
    as HashRef[PhraseMatcher()];

declare 'PhraseMatcherType',
    as (Int | Str);

declare 'PhraseMatchRuleGroup',
    as InstanceOf['Google::Cloud::Contactcenterinsights::V1::Resources::PhraseMatchRuleGroup'];

coerce 'PhraseMatchRuleGroup',
    from HashRef, via { 'Google::Cloud::Contactcenterinsights::V1::Resources::PhraseMatchRuleGroup'->new($_) };

declare 'RepeatedPhraseMatchRuleGroup',
    as ArrayRef[PhraseMatchRuleGroup()];

coerce 'RepeatedPhraseMatchRuleGroup',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contactcenterinsights::V1::Resources::PhraseMatchRuleGroup'->new($_) } @$_ ] };

declare 'MapStringPhraseMatchRuleGroup',
    as HashRef[PhraseMatchRuleGroup()];

declare 'PhraseMatchRuleGroupType',
    as (Int | Str);

declare 'PhraseMatchRule',
    as InstanceOf['Google::Cloud::Contactcenterinsights::V1::Resources::PhraseMatchRule'];

coerce 'PhraseMatchRule',
    from HashRef, via { 'Google::Cloud::Contactcenterinsights::V1::Resources::PhraseMatchRule'->new($_) };

declare 'RepeatedPhraseMatchRule',
    as ArrayRef[PhraseMatchRule()];

coerce 'RepeatedPhraseMatchRule',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contactcenterinsights::V1::Resources::PhraseMatchRule'->new($_) } @$_ ] };

declare 'MapStringPhraseMatchRule',
    as HashRef[PhraseMatchRule()];

declare 'PhraseMatchRuleConfig',
    as InstanceOf['Google::Cloud::Contactcenterinsights::V1::Resources::PhraseMatchRuleConfig'];

coerce 'PhraseMatchRuleConfig',
    from HashRef, via { 'Google::Cloud::Contactcenterinsights::V1::Resources::PhraseMatchRuleConfig'->new($_) };

declare 'RepeatedPhraseMatchRuleConfig',
    as ArrayRef[PhraseMatchRuleConfig()];

coerce 'RepeatedPhraseMatchRuleConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contactcenterinsights::V1::Resources::PhraseMatchRuleConfig'->new($_) } @$_ ] };

declare 'MapStringPhraseMatchRuleConfig',
    as HashRef[PhraseMatchRuleConfig()];

declare 'ExactMatchConfig',
    as InstanceOf['Google::Cloud::Contactcenterinsights::V1::Resources::ExactMatchConfig'];

coerce 'ExactMatchConfig',
    from HashRef, via { 'Google::Cloud::Contactcenterinsights::V1::Resources::ExactMatchConfig'->new($_) };

declare 'RepeatedExactMatchConfig',
    as ArrayRef[ExactMatchConfig()];

coerce 'RepeatedExactMatchConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contactcenterinsights::V1::Resources::ExactMatchConfig'->new($_) } @$_ ] };

declare 'MapStringExactMatchConfig',
    as HashRef[ExactMatchConfig()];

declare 'Settings',
    as InstanceOf['Google::Cloud::Contactcenterinsights::V1::Resources::Settings'];

coerce 'Settings',
    from HashRef, via { 'Google::Cloud::Contactcenterinsights::V1::Resources::Settings'->new($_) };

declare 'RepeatedSettings',
    as ArrayRef[Settings()];

coerce 'RepeatedSettings',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contactcenterinsights::V1::Resources::Settings'->new($_) } @$_ ] };

declare 'MapStringSettings',
    as HashRef[Settings()];

declare 'AnalysisConfig',
    as InstanceOf['Google::Cloud::Contactcenterinsights::V1::Resources::Settings::AnalysisConfig'];

coerce 'AnalysisConfig',
    from HashRef, via { 'Google::Cloud::Contactcenterinsights::V1::Resources::Settings::AnalysisConfig'->new($_) };

declare 'RepeatedAnalysisConfig',
    as ArrayRef[AnalysisConfig()];

coerce 'RepeatedAnalysisConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contactcenterinsights::V1::Resources::Settings::AnalysisConfig'->new($_) } @$_ ] };

declare 'MapStringAnalysisConfig',
    as HashRef[AnalysisConfig()];

declare 'PubsubNotificationSettingsEntry',
    as InstanceOf['Google::Cloud::Contactcenterinsights::V1::Resources::Settings::PubsubNotificationSettingsEntry'];

coerce 'PubsubNotificationSettingsEntry',
    from HashRef, via { 'Google::Cloud::Contactcenterinsights::V1::Resources::Settings::PubsubNotificationSettingsEntry'->new($_) };

declare 'RepeatedPubsubNotificationSettingsEntry',
    as ArrayRef[PubsubNotificationSettingsEntry()];

coerce 'RepeatedPubsubNotificationSettingsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contactcenterinsights::V1::Resources::Settings::PubsubNotificationSettingsEntry'->new($_) } @$_ ] };

declare 'MapStringPubsubNotificationSettingsEntry',
    as HashRef[PubsubNotificationSettingsEntry()];

declare 'AnalysisRule',
    as InstanceOf['Google::Cloud::Contactcenterinsights::V1::Resources::AnalysisRule'];

coerce 'AnalysisRule',
    from HashRef, via { 'Google::Cloud::Contactcenterinsights::V1::Resources::AnalysisRule'->new($_) };

declare 'RepeatedAnalysisRule',
    as ArrayRef[AnalysisRule()];

coerce 'RepeatedAnalysisRule',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contactcenterinsights::V1::Resources::AnalysisRule'->new($_) } @$_ ] };

declare 'MapStringAnalysisRule',
    as HashRef[AnalysisRule()];

declare 'EncryptionSpec',
    as InstanceOf['Google::Cloud::Contactcenterinsights::V1::Resources::EncryptionSpec'];

coerce 'EncryptionSpec',
    from HashRef, via { 'Google::Cloud::Contactcenterinsights::V1::Resources::EncryptionSpec'->new($_) };

declare 'RepeatedEncryptionSpec',
    as ArrayRef[EncryptionSpec()];

coerce 'RepeatedEncryptionSpec',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contactcenterinsights::V1::Resources::EncryptionSpec'->new($_) } @$_ ] };

declare 'MapStringEncryptionSpec',
    as HashRef[EncryptionSpec()];

declare 'RedactionConfig',
    as InstanceOf['Google::Cloud::Contactcenterinsights::V1::Resources::RedactionConfig'];

coerce 'RedactionConfig',
    from HashRef, via { 'Google::Cloud::Contactcenterinsights::V1::Resources::RedactionConfig'->new($_) };

declare 'RepeatedRedactionConfig',
    as ArrayRef[RedactionConfig()];

coerce 'RepeatedRedactionConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contactcenterinsights::V1::Resources::RedactionConfig'->new($_) } @$_ ] };

declare 'MapStringRedactionConfig',
    as HashRef[RedactionConfig()];

declare 'SpeechConfig',
    as InstanceOf['Google::Cloud::Contactcenterinsights::V1::Resources::SpeechConfig'];

coerce 'SpeechConfig',
    from HashRef, via { 'Google::Cloud::Contactcenterinsights::V1::Resources::SpeechConfig'->new($_) };

declare 'RepeatedSpeechConfig',
    as ArrayRef[SpeechConfig()];

coerce 'RepeatedSpeechConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contactcenterinsights::V1::Resources::SpeechConfig'->new($_) } @$_ ] };

declare 'MapStringSpeechConfig',
    as HashRef[SpeechConfig()];

declare 'RuntimeAnnotation',
    as InstanceOf['Google::Cloud::Contactcenterinsights::V1::Resources::RuntimeAnnotation'];

coerce 'RuntimeAnnotation',
    from HashRef, via { 'Google::Cloud::Contactcenterinsights::V1::Resources::RuntimeAnnotation'->new($_) };

declare 'RepeatedRuntimeAnnotation',
    as ArrayRef[RuntimeAnnotation()];

coerce 'RepeatedRuntimeAnnotation',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contactcenterinsights::V1::Resources::RuntimeAnnotation'->new($_) } @$_ ] };

declare 'MapStringRuntimeAnnotation',
    as HashRef[RuntimeAnnotation()];

declare 'UserInput',
    as InstanceOf['Google::Cloud::Contactcenterinsights::V1::Resources::RuntimeAnnotation::UserInput'];

coerce 'UserInput',
    from HashRef, via { 'Google::Cloud::Contactcenterinsights::V1::Resources::RuntimeAnnotation::UserInput'->new($_) };

declare 'RepeatedUserInput',
    as ArrayRef[UserInput()];

coerce 'RepeatedUserInput',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contactcenterinsights::V1::Resources::RuntimeAnnotation::UserInput'->new($_) } @$_ ] };

declare 'MapStringUserInput',
    as HashRef[UserInput()];

declare 'QuerySource',
    as (Int | Str);

declare 'AnswerFeedback',
    as InstanceOf['Google::Cloud::Contactcenterinsights::V1::Resources::AnswerFeedback'];

coerce 'AnswerFeedback',
    from HashRef, via { 'Google::Cloud::Contactcenterinsights::V1::Resources::AnswerFeedback'->new($_) };

declare 'RepeatedAnswerFeedback',
    as ArrayRef[AnswerFeedback()];

coerce 'RepeatedAnswerFeedback',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contactcenterinsights::V1::Resources::AnswerFeedback'->new($_) } @$_ ] };

declare 'MapStringAnswerFeedback',
    as HashRef[AnswerFeedback()];

declare 'CorrectnessLevel',
    as (Int | Str);

declare 'ArticleSuggestionData',
    as InstanceOf['Google::Cloud::Contactcenterinsights::V1::Resources::ArticleSuggestionData'];

coerce 'ArticleSuggestionData',
    from HashRef, via { 'Google::Cloud::Contactcenterinsights::V1::Resources::ArticleSuggestionData'->new($_) };

declare 'RepeatedArticleSuggestionData',
    as ArrayRef[ArticleSuggestionData()];

coerce 'RepeatedArticleSuggestionData',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contactcenterinsights::V1::Resources::ArticleSuggestionData'->new($_) } @$_ ] };

declare 'MapStringArticleSuggestionData',
    as HashRef[ArticleSuggestionData()];

declare 'MetadataEntry',
    as InstanceOf['Google::Cloud::Contactcenterinsights::V1::Resources::ArticleSuggestionData::MetadataEntry'];

coerce 'MetadataEntry',
    from HashRef, via { 'Google::Cloud::Contactcenterinsights::V1::Resources::ArticleSuggestionData::MetadataEntry'->new($_) };

declare 'RepeatedMetadataEntry',
    as ArrayRef[MetadataEntry()];

coerce 'RepeatedMetadataEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contactcenterinsights::V1::Resources::ArticleSuggestionData::MetadataEntry'->new($_) } @$_ ] };

declare 'MapStringMetadataEntry',
    as HashRef[MetadataEntry()];

declare 'FaqAnswerData',
    as InstanceOf['Google::Cloud::Contactcenterinsights::V1::Resources::FaqAnswerData'];

coerce 'FaqAnswerData',
    from HashRef, via { 'Google::Cloud::Contactcenterinsights::V1::Resources::FaqAnswerData'->new($_) };

declare 'RepeatedFaqAnswerData',
    as ArrayRef[FaqAnswerData()];

coerce 'RepeatedFaqAnswerData',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contactcenterinsights::V1::Resources::FaqAnswerData'->new($_) } @$_ ] };

declare 'MapStringFaqAnswerData',
    as HashRef[FaqAnswerData()];

declare 'MetadataEntry',
    as InstanceOf['Google::Cloud::Contactcenterinsights::V1::Resources::FaqAnswerData::MetadataEntry'];

coerce 'MetadataEntry',
    from HashRef, via { 'Google::Cloud::Contactcenterinsights::V1::Resources::FaqAnswerData::MetadataEntry'->new($_) };

declare 'RepeatedMetadataEntry',
    as ArrayRef[MetadataEntry()];

coerce 'RepeatedMetadataEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contactcenterinsights::V1::Resources::FaqAnswerData::MetadataEntry'->new($_) } @$_ ] };

declare 'MapStringMetadataEntry',
    as HashRef[MetadataEntry()];

declare 'SmartReplyData',
    as InstanceOf['Google::Cloud::Contactcenterinsights::V1::Resources::SmartReplyData'];

coerce 'SmartReplyData',
    from HashRef, via { 'Google::Cloud::Contactcenterinsights::V1::Resources::SmartReplyData'->new($_) };

declare 'RepeatedSmartReplyData',
    as ArrayRef[SmartReplyData()];

coerce 'RepeatedSmartReplyData',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contactcenterinsights::V1::Resources::SmartReplyData'->new($_) } @$_ ] };

declare 'MapStringSmartReplyData',
    as HashRef[SmartReplyData()];

declare 'MetadataEntry',
    as InstanceOf['Google::Cloud::Contactcenterinsights::V1::Resources::SmartReplyData::MetadataEntry'];

coerce 'MetadataEntry',
    from HashRef, via { 'Google::Cloud::Contactcenterinsights::V1::Resources::SmartReplyData::MetadataEntry'->new($_) };

declare 'RepeatedMetadataEntry',
    as ArrayRef[MetadataEntry()];

coerce 'RepeatedMetadataEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contactcenterinsights::V1::Resources::SmartReplyData::MetadataEntry'->new($_) } @$_ ] };

declare 'MapStringMetadataEntry',
    as HashRef[MetadataEntry()];

declare 'SmartComposeSuggestionData',
    as InstanceOf['Google::Cloud::Contactcenterinsights::V1::Resources::SmartComposeSuggestionData'];

coerce 'SmartComposeSuggestionData',
    from HashRef, via { 'Google::Cloud::Contactcenterinsights::V1::Resources::SmartComposeSuggestionData'->new($_) };

declare 'RepeatedSmartComposeSuggestionData',
    as ArrayRef[SmartComposeSuggestionData()];

coerce 'RepeatedSmartComposeSuggestionData',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contactcenterinsights::V1::Resources::SmartComposeSuggestionData'->new($_) } @$_ ] };

declare 'MapStringSmartComposeSuggestionData',
    as HashRef[SmartComposeSuggestionData()];

declare 'MetadataEntry',
    as InstanceOf['Google::Cloud::Contactcenterinsights::V1::Resources::SmartComposeSuggestionData::MetadataEntry'];

coerce 'MetadataEntry',
    from HashRef, via { 'Google::Cloud::Contactcenterinsights::V1::Resources::SmartComposeSuggestionData::MetadataEntry'->new($_) };

declare 'RepeatedMetadataEntry',
    as ArrayRef[MetadataEntry()];

coerce 'RepeatedMetadataEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contactcenterinsights::V1::Resources::SmartComposeSuggestionData::MetadataEntry'->new($_) } @$_ ] };

declare 'MapStringMetadataEntry',
    as HashRef[MetadataEntry()];

declare 'DialogflowInteractionData',
    as InstanceOf['Google::Cloud::Contactcenterinsights::V1::Resources::DialogflowInteractionData'];

coerce 'DialogflowInteractionData',
    from HashRef, via { 'Google::Cloud::Contactcenterinsights::V1::Resources::DialogflowInteractionData'->new($_) };

declare 'RepeatedDialogflowInteractionData',
    as ArrayRef[DialogflowInteractionData()];

coerce 'RepeatedDialogflowInteractionData',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contactcenterinsights::V1::Resources::DialogflowInteractionData'->new($_) } @$_ ] };

declare 'MapStringDialogflowInteractionData',
    as HashRef[DialogflowInteractionData()];

declare 'ConversationSummarizationSuggestionData',
    as InstanceOf['Google::Cloud::Contactcenterinsights::V1::Resources::ConversationSummarizationSuggestionData'];

coerce 'ConversationSummarizationSuggestionData',
    from HashRef, via { 'Google::Cloud::Contactcenterinsights::V1::Resources::ConversationSummarizationSuggestionData'->new($_) };

declare 'RepeatedConversationSummarizationSuggestionData',
    as ArrayRef[ConversationSummarizationSuggestionData()];

coerce 'RepeatedConversationSummarizationSuggestionData',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contactcenterinsights::V1::Resources::ConversationSummarizationSuggestionData'->new($_) } @$_ ] };

declare 'MapStringConversationSummarizationSuggestionData',
    as HashRef[ConversationSummarizationSuggestionData()];

declare 'TextSectionsEntry',
    as InstanceOf['Google::Cloud::Contactcenterinsights::V1::Resources::ConversationSummarizationSuggestionData::TextSectionsEntry'];

coerce 'TextSectionsEntry',
    from HashRef, via { 'Google::Cloud::Contactcenterinsights::V1::Resources::ConversationSummarizationSuggestionData::TextSectionsEntry'->new($_) };

declare 'RepeatedTextSectionsEntry',
    as ArrayRef[TextSectionsEntry()];

coerce 'RepeatedTextSectionsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contactcenterinsights::V1::Resources::ConversationSummarizationSuggestionData::TextSectionsEntry'->new($_) } @$_ ] };

declare 'MapStringTextSectionsEntry',
    as HashRef[TextSectionsEntry()];

declare 'MetadataEntry',
    as InstanceOf['Google::Cloud::Contactcenterinsights::V1::Resources::ConversationSummarizationSuggestionData::MetadataEntry'];

coerce 'MetadataEntry',
    from HashRef, via { 'Google::Cloud::Contactcenterinsights::V1::Resources::ConversationSummarizationSuggestionData::MetadataEntry'->new($_) };

declare 'RepeatedMetadataEntry',
    as ArrayRef[MetadataEntry()];

coerce 'RepeatedMetadataEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contactcenterinsights::V1::Resources::ConversationSummarizationSuggestionData::MetadataEntry'->new($_) } @$_ ] };

declare 'MapStringMetadataEntry',
    as HashRef[MetadataEntry()];

declare 'ConversationParticipant',
    as InstanceOf['Google::Cloud::Contactcenterinsights::V1::Resources::ConversationParticipant'];

coerce 'ConversationParticipant',
    from HashRef, via { 'Google::Cloud::Contactcenterinsights::V1::Resources::ConversationParticipant'->new($_) };

declare 'RepeatedConversationParticipant',
    as ArrayRef[ConversationParticipant()];

coerce 'RepeatedConversationParticipant',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contactcenterinsights::V1::Resources::ConversationParticipant'->new($_) } @$_ ] };

declare 'MapStringConversationParticipant',
    as HashRef[ConversationParticipant()];

declare 'Role',
    as (Int | Str);

declare 'View',
    as InstanceOf['Google::Cloud::Contactcenterinsights::V1::Resources::View'];

coerce 'View',
    from HashRef, via { 'Google::Cloud::Contactcenterinsights::V1::Resources::View'->new($_) };

declare 'RepeatedView',
    as ArrayRef[View()];

coerce 'RepeatedView',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contactcenterinsights::V1::Resources::View'->new($_) } @$_ ] };

declare 'MapStringView',
    as HashRef[View()];

declare 'AnnotatorSelector',
    as InstanceOf['Google::Cloud::Contactcenterinsights::V1::Resources::AnnotatorSelector'];

coerce 'AnnotatorSelector',
    from HashRef, via { 'Google::Cloud::Contactcenterinsights::V1::Resources::AnnotatorSelector'->new($_) };

declare 'RepeatedAnnotatorSelector',
    as ArrayRef[AnnotatorSelector()];

coerce 'RepeatedAnnotatorSelector',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contactcenterinsights::V1::Resources::AnnotatorSelector'->new($_) } @$_ ] };

declare 'MapStringAnnotatorSelector',
    as HashRef[AnnotatorSelector()];

declare 'SummarizationConfig',
    as InstanceOf['Google::Cloud::Contactcenterinsights::V1::Resources::AnnotatorSelector::SummarizationConfig'];

coerce 'SummarizationConfig',
    from HashRef, via { 'Google::Cloud::Contactcenterinsights::V1::Resources::AnnotatorSelector::SummarizationConfig'->new($_) };

declare 'RepeatedSummarizationConfig',
    as ArrayRef[SummarizationConfig()];

coerce 'RepeatedSummarizationConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contactcenterinsights::V1::Resources::AnnotatorSelector::SummarizationConfig'->new($_) } @$_ ] };

declare 'MapStringSummarizationConfig',
    as HashRef[SummarizationConfig()];

declare 'SummarizationModel',
    as (Int | Str);

declare 'QaConfig',
    as InstanceOf['Google::Cloud::Contactcenterinsights::V1::Resources::AnnotatorSelector::QaConfig'];

coerce 'QaConfig',
    from HashRef, via { 'Google::Cloud::Contactcenterinsights::V1::Resources::AnnotatorSelector::QaConfig'->new($_) };

declare 'RepeatedQaConfig',
    as ArrayRef[QaConfig()];

coerce 'RepeatedQaConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contactcenterinsights::V1::Resources::AnnotatorSelector::QaConfig'->new($_) } @$_ ] };

declare 'MapStringQaConfig',
    as HashRef[QaConfig()];

declare 'ScorecardList',
    as InstanceOf['Google::Cloud::Contactcenterinsights::V1::Resources::AnnotatorSelector::QaConfig::ScorecardList'];

coerce 'ScorecardList',
    from HashRef, via { 'Google::Cloud::Contactcenterinsights::V1::Resources::AnnotatorSelector::QaConfig::ScorecardList'->new($_) };

declare 'RepeatedScorecardList',
    as ArrayRef[ScorecardList()];

coerce 'RepeatedScorecardList',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contactcenterinsights::V1::Resources::AnnotatorSelector::QaConfig::ScorecardList'->new($_) } @$_ ] };

declare 'MapStringScorecardList',
    as HashRef[ScorecardList()];

declare 'QaQuestion',
    as InstanceOf['Google::Cloud::Contactcenterinsights::V1::Resources::QaQuestion'];

coerce 'QaQuestion',
    from HashRef, via { 'Google::Cloud::Contactcenterinsights::V1::Resources::QaQuestion'->new($_) };

declare 'RepeatedQaQuestion',
    as ArrayRef[QaQuestion()];

coerce 'RepeatedQaQuestion',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contactcenterinsights::V1::Resources::QaQuestion'->new($_) } @$_ ] };

declare 'MapStringQaQuestion',
    as HashRef[QaQuestion()];

declare 'AnswerChoice',
    as InstanceOf['Google::Cloud::Contactcenterinsights::V1::Resources::QaQuestion::AnswerChoice'];

coerce 'AnswerChoice',
    from HashRef, via { 'Google::Cloud::Contactcenterinsights::V1::Resources::QaQuestion::AnswerChoice'->new($_) };

declare 'RepeatedAnswerChoice',
    as ArrayRef[AnswerChoice()];

coerce 'RepeatedAnswerChoice',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contactcenterinsights::V1::Resources::QaQuestion::AnswerChoice'->new($_) } @$_ ] };

declare 'MapStringAnswerChoice',
    as HashRef[AnswerChoice()];

declare 'Metrics',
    as InstanceOf['Google::Cloud::Contactcenterinsights::V1::Resources::QaQuestion::Metrics'];

coerce 'Metrics',
    from HashRef, via { 'Google::Cloud::Contactcenterinsights::V1::Resources::QaQuestion::Metrics'->new($_) };

declare 'RepeatedMetrics',
    as ArrayRef[Metrics()];

coerce 'RepeatedMetrics',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contactcenterinsights::V1::Resources::QaQuestion::Metrics'->new($_) } @$_ ] };

declare 'MapStringMetrics',
    as HashRef[Metrics()];

declare 'TuningMetadata',
    as InstanceOf['Google::Cloud::Contactcenterinsights::V1::Resources::QaQuestion::TuningMetadata'];

coerce 'TuningMetadata',
    from HashRef, via { 'Google::Cloud::Contactcenterinsights::V1::Resources::QaQuestion::TuningMetadata'->new($_) };

declare 'RepeatedTuningMetadata',
    as ArrayRef[TuningMetadata()];

coerce 'RepeatedTuningMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contactcenterinsights::V1::Resources::QaQuestion::TuningMetadata'->new($_) } @$_ ] };

declare 'MapStringTuningMetadata',
    as HashRef[TuningMetadata()];

declare 'QaScorecard',
    as InstanceOf['Google::Cloud::Contactcenterinsights::V1::Resources::QaScorecard'];

coerce 'QaScorecard',
    from HashRef, via { 'Google::Cloud::Contactcenterinsights::V1::Resources::QaScorecard'->new($_) };

declare 'RepeatedQaScorecard',
    as ArrayRef[QaScorecard()];

coerce 'RepeatedQaScorecard',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contactcenterinsights::V1::Resources::QaScorecard'->new($_) } @$_ ] };

declare 'MapStringQaScorecard',
    as HashRef[QaScorecard()];

declare 'QaScorecardRevision',
    as InstanceOf['Google::Cloud::Contactcenterinsights::V1::Resources::QaScorecardRevision'];

coerce 'QaScorecardRevision',
    from HashRef, via { 'Google::Cloud::Contactcenterinsights::V1::Resources::QaScorecardRevision'->new($_) };

declare 'RepeatedQaScorecardRevision',
    as ArrayRef[QaScorecardRevision()];

coerce 'RepeatedQaScorecardRevision',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contactcenterinsights::V1::Resources::QaScorecardRevision'->new($_) } @$_ ] };

declare 'MapStringQaScorecardRevision',
    as HashRef[QaScorecardRevision()];

declare 'State',
    as (Int | Str);

declare 'QaAnswer',
    as InstanceOf['Google::Cloud::Contactcenterinsights::V1::Resources::QaAnswer'];

coerce 'QaAnswer',
    from HashRef, via { 'Google::Cloud::Contactcenterinsights::V1::Resources::QaAnswer'->new($_) };

declare 'RepeatedQaAnswer',
    as ArrayRef[QaAnswer()];

coerce 'RepeatedQaAnswer',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contactcenterinsights::V1::Resources::QaAnswer'->new($_) } @$_ ] };

declare 'MapStringQaAnswer',
    as HashRef[QaAnswer()];

declare 'AnswerValue',
    as InstanceOf['Google::Cloud::Contactcenterinsights::V1::Resources::QaAnswer::AnswerValue'];

coerce 'AnswerValue',
    from HashRef, via { 'Google::Cloud::Contactcenterinsights::V1::Resources::QaAnswer::AnswerValue'->new($_) };

declare 'RepeatedAnswerValue',
    as ArrayRef[AnswerValue()];

coerce 'RepeatedAnswerValue',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contactcenterinsights::V1::Resources::QaAnswer::AnswerValue'->new($_) } @$_ ] };

declare 'MapStringAnswerValue',
    as HashRef[AnswerValue()];

declare 'AnswerSource',
    as InstanceOf['Google::Cloud::Contactcenterinsights::V1::Resources::QaAnswer::AnswerSource'];

coerce 'AnswerSource',
    from HashRef, via { 'Google::Cloud::Contactcenterinsights::V1::Resources::QaAnswer::AnswerSource'->new($_) };

declare 'RepeatedAnswerSource',
    as ArrayRef[AnswerSource()];

coerce 'RepeatedAnswerSource',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contactcenterinsights::V1::Resources::QaAnswer::AnswerSource'->new($_) } @$_ ] };

declare 'MapStringAnswerSource',
    as HashRef[AnswerSource()];

declare 'SourceType',
    as (Int | Str);

declare 'QaScorecardResult',
    as InstanceOf['Google::Cloud::Contactcenterinsights::V1::Resources::QaScorecardResult'];

coerce 'QaScorecardResult',
    from HashRef, via { 'Google::Cloud::Contactcenterinsights::V1::Resources::QaScorecardResult'->new($_) };

declare 'RepeatedQaScorecardResult',
    as ArrayRef[QaScorecardResult()];

coerce 'RepeatedQaScorecardResult',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contactcenterinsights::V1::Resources::QaScorecardResult'->new($_) } @$_ ] };

declare 'MapStringQaScorecardResult',
    as HashRef[QaScorecardResult()];

declare 'QaTagResult',
    as InstanceOf['Google::Cloud::Contactcenterinsights::V1::Resources::QaScorecardResult::QaTagResult'];

coerce 'QaTagResult',
    from HashRef, via { 'Google::Cloud::Contactcenterinsights::V1::Resources::QaScorecardResult::QaTagResult'->new($_) };

declare 'RepeatedQaTagResult',
    as ArrayRef[QaTagResult()];

coerce 'RepeatedQaTagResult',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contactcenterinsights::V1::Resources::QaScorecardResult::QaTagResult'->new($_) } @$_ ] };

declare 'MapStringQaTagResult',
    as HashRef[QaTagResult()];

declare 'ScoreSource',
    as InstanceOf['Google::Cloud::Contactcenterinsights::V1::Resources::QaScorecardResult::ScoreSource'];

coerce 'ScoreSource',
    from HashRef, via { 'Google::Cloud::Contactcenterinsights::V1::Resources::QaScorecardResult::ScoreSource'->new($_) };

declare 'RepeatedScoreSource',
    as ArrayRef[ScoreSource()];

coerce 'RepeatedScoreSource',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contactcenterinsights::V1::Resources::QaScorecardResult::ScoreSource'->new($_) } @$_ ] };

declare 'MapStringScoreSource',
    as HashRef[ScoreSource()];

declare 'SourceType',
    as (Int | Str);

1;

__END__

=head1 NAME

Google::Cloud::Contactcenterinsights::V1::Resources::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
