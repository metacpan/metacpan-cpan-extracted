package Google::Cloud::Dialogflow::V2beta1::Generator::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'TriggerEvent',
    as (Int | Str);

declare 'CreateGeneratorRequest',
    as InstanceOf['Google::Cloud::Dialogflow::V2beta1::Generator::CreateGeneratorRequest'];

coerce 'CreateGeneratorRequest',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2beta1::Generator::CreateGeneratorRequest'->new($_) };

declare 'RepeatedCreateGeneratorRequest',
    as ArrayRef[CreateGeneratorRequest()];

coerce 'RepeatedCreateGeneratorRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2beta1::Generator::CreateGeneratorRequest'->new($_) } @$_ ] };

declare 'MapStringCreateGeneratorRequest',
    as HashRef[CreateGeneratorRequest()];

declare 'GetGeneratorRequest',
    as InstanceOf['Google::Cloud::Dialogflow::V2beta1::Generator::GetGeneratorRequest'];

coerce 'GetGeneratorRequest',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2beta1::Generator::GetGeneratorRequest'->new($_) };

declare 'RepeatedGetGeneratorRequest',
    as ArrayRef[GetGeneratorRequest()];

coerce 'RepeatedGetGeneratorRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2beta1::Generator::GetGeneratorRequest'->new($_) } @$_ ] };

declare 'MapStringGetGeneratorRequest',
    as HashRef[GetGeneratorRequest()];

declare 'ListGeneratorsRequest',
    as InstanceOf['Google::Cloud::Dialogflow::V2beta1::Generator::ListGeneratorsRequest'];

coerce 'ListGeneratorsRequest',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2beta1::Generator::ListGeneratorsRequest'->new($_) };

declare 'RepeatedListGeneratorsRequest',
    as ArrayRef[ListGeneratorsRequest()];

coerce 'RepeatedListGeneratorsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2beta1::Generator::ListGeneratorsRequest'->new($_) } @$_ ] };

declare 'MapStringListGeneratorsRequest',
    as HashRef[ListGeneratorsRequest()];

declare 'ListGeneratorsResponse',
    as InstanceOf['Google::Cloud::Dialogflow::V2beta1::Generator::ListGeneratorsResponse'];

coerce 'ListGeneratorsResponse',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2beta1::Generator::ListGeneratorsResponse'->new($_) };

declare 'RepeatedListGeneratorsResponse',
    as ArrayRef[ListGeneratorsResponse()];

coerce 'RepeatedListGeneratorsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2beta1::Generator::ListGeneratorsResponse'->new($_) } @$_ ] };

declare 'MapStringListGeneratorsResponse',
    as HashRef[ListGeneratorsResponse()];

declare 'DeleteGeneratorRequest',
    as InstanceOf['Google::Cloud::Dialogflow::V2beta1::Generator::DeleteGeneratorRequest'];

coerce 'DeleteGeneratorRequest',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2beta1::Generator::DeleteGeneratorRequest'->new($_) };

declare 'RepeatedDeleteGeneratorRequest',
    as ArrayRef[DeleteGeneratorRequest()];

coerce 'RepeatedDeleteGeneratorRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2beta1::Generator::DeleteGeneratorRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteGeneratorRequest',
    as HashRef[DeleteGeneratorRequest()];

declare 'UpdateGeneratorRequest',
    as InstanceOf['Google::Cloud::Dialogflow::V2beta1::Generator::UpdateGeneratorRequest'];

coerce 'UpdateGeneratorRequest',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2beta1::Generator::UpdateGeneratorRequest'->new($_) };

declare 'RepeatedUpdateGeneratorRequest',
    as ArrayRef[UpdateGeneratorRequest()];

coerce 'RepeatedUpdateGeneratorRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2beta1::Generator::UpdateGeneratorRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateGeneratorRequest',
    as HashRef[UpdateGeneratorRequest()];

declare 'MessageEntry',
    as InstanceOf['Google::Cloud::Dialogflow::V2beta1::Generator::MessageEntry'];

coerce 'MessageEntry',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2beta1::Generator::MessageEntry'->new($_) };

declare 'RepeatedMessageEntry',
    as ArrayRef[MessageEntry()];

coerce 'RepeatedMessageEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2beta1::Generator::MessageEntry'->new($_) } @$_ ] };

declare 'MapStringMessageEntry',
    as HashRef[MessageEntry()];

declare 'Role',
    as (Int | Str);

declare 'ConversationContext',
    as InstanceOf['Google::Cloud::Dialogflow::V2beta1::Generator::ConversationContext'];

coerce 'ConversationContext',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2beta1::Generator::ConversationContext'->new($_) };

declare 'RepeatedConversationContext',
    as ArrayRef[ConversationContext()];

coerce 'RepeatedConversationContext',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2beta1::Generator::ConversationContext'->new($_) } @$_ ] };

declare 'MapStringConversationContext',
    as HashRef[ConversationContext()];

declare 'SummarizationSectionList',
    as InstanceOf['Google::Cloud::Dialogflow::V2beta1::Generator::SummarizationSectionList'];

coerce 'SummarizationSectionList',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2beta1::Generator::SummarizationSectionList'->new($_) };

declare 'RepeatedSummarizationSectionList',
    as ArrayRef[SummarizationSectionList()];

coerce 'RepeatedSummarizationSectionList',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2beta1::Generator::SummarizationSectionList'->new($_) } @$_ ] };

declare 'MapStringSummarizationSectionList',
    as HashRef[SummarizationSectionList()];

declare 'FewShotExample',
    as InstanceOf['Google::Cloud::Dialogflow::V2beta1::Generator::FewShotExample'];

coerce 'FewShotExample',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2beta1::Generator::FewShotExample'->new($_) };

declare 'RepeatedFewShotExample',
    as ArrayRef[FewShotExample()];

coerce 'RepeatedFewShotExample',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2beta1::Generator::FewShotExample'->new($_) } @$_ ] };

declare 'MapStringFewShotExample',
    as HashRef[FewShotExample()];

declare 'ExtraInfoEntry',
    as InstanceOf['Google::Cloud::Dialogflow::V2beta1::Generator::FewShotExample::ExtraInfoEntry'];

coerce 'ExtraInfoEntry',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2beta1::Generator::FewShotExample::ExtraInfoEntry'->new($_) };

declare 'RepeatedExtraInfoEntry',
    as ArrayRef[ExtraInfoEntry()];

coerce 'RepeatedExtraInfoEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2beta1::Generator::FewShotExample::ExtraInfoEntry'->new($_) } @$_ ] };

declare 'MapStringExtraInfoEntry',
    as HashRef[ExtraInfoEntry()];

declare 'InferenceParameter',
    as InstanceOf['Google::Cloud::Dialogflow::V2beta1::Generator::InferenceParameter'];

coerce 'InferenceParameter',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2beta1::Generator::InferenceParameter'->new($_) };

declare 'RepeatedInferenceParameter',
    as ArrayRef[InferenceParameter()];

coerce 'RepeatedInferenceParameter',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2beta1::Generator::InferenceParameter'->new($_) } @$_ ] };

declare 'MapStringInferenceParameter',
    as HashRef[InferenceParameter()];

declare 'AgentCoachingContext',
    as InstanceOf['Google::Cloud::Dialogflow::V2beta1::Generator::AgentCoachingContext'];

coerce 'AgentCoachingContext',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2beta1::Generator::AgentCoachingContext'->new($_) };

declare 'RepeatedAgentCoachingContext',
    as ArrayRef[AgentCoachingContext()];

coerce 'RepeatedAgentCoachingContext',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2beta1::Generator::AgentCoachingContext'->new($_) } @$_ ] };

declare 'MapStringAgentCoachingContext',
    as HashRef[AgentCoachingContext()];

declare 'SummarizationSection',
    as InstanceOf['Google::Cloud::Dialogflow::V2beta1::Generator::SummarizationSection'];

coerce 'SummarizationSection',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2beta1::Generator::SummarizationSection'->new($_) };

declare 'RepeatedSummarizationSection',
    as ArrayRef[SummarizationSection()];

coerce 'RepeatedSummarizationSection',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2beta1::Generator::SummarizationSection'->new($_) } @$_ ] };

declare 'MapStringSummarizationSection',
    as HashRef[SummarizationSection()];

declare 'Type',
    as (Int | Str);

declare 'SummarizationContext',
    as InstanceOf['Google::Cloud::Dialogflow::V2beta1::Generator::SummarizationContext'];

coerce 'SummarizationContext',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2beta1::Generator::SummarizationContext'->new($_) };

declare 'RepeatedSummarizationContext',
    as ArrayRef[SummarizationContext()];

coerce 'RepeatedSummarizationContext',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2beta1::Generator::SummarizationContext'->new($_) } @$_ ] };

declare 'MapStringSummarizationContext',
    as HashRef[SummarizationContext()];

declare 'FreeFormContext',
    as InstanceOf['Google::Cloud::Dialogflow::V2beta1::Generator::FreeFormContext'];

coerce 'FreeFormContext',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2beta1::Generator::FreeFormContext'->new($_) };

declare 'RepeatedFreeFormContext',
    as ArrayRef[FreeFormContext()];

coerce 'RepeatedFreeFormContext',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2beta1::Generator::FreeFormContext'->new($_) } @$_ ] };

declare 'MapStringFreeFormContext',
    as HashRef[FreeFormContext()];

declare 'Generator',
    as InstanceOf['Google::Cloud::Dialogflow::V2beta1::Generator::Generator'];

coerce 'Generator',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2beta1::Generator::Generator'->new($_) };

declare 'RepeatedGenerator',
    as ArrayRef[Generator()];

coerce 'RepeatedGenerator',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2beta1::Generator::Generator'->new($_) } @$_ ] };

declare 'MapStringGenerator',
    as HashRef[Generator()];

declare 'FreeFormSuggestion',
    as InstanceOf['Google::Cloud::Dialogflow::V2beta1::Generator::FreeFormSuggestion'];

coerce 'FreeFormSuggestion',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2beta1::Generator::FreeFormSuggestion'->new($_) };

declare 'RepeatedFreeFormSuggestion',
    as ArrayRef[FreeFormSuggestion()];

coerce 'RepeatedFreeFormSuggestion',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2beta1::Generator::FreeFormSuggestion'->new($_) } @$_ ] };

declare 'MapStringFreeFormSuggestion',
    as HashRef[FreeFormSuggestion()];

declare 'SummarySuggestion',
    as InstanceOf['Google::Cloud::Dialogflow::V2beta1::Generator::SummarySuggestion'];

coerce 'SummarySuggestion',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2beta1::Generator::SummarySuggestion'->new($_) };

declare 'RepeatedSummarySuggestion',
    as ArrayRef[SummarySuggestion()];

coerce 'RepeatedSummarySuggestion',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2beta1::Generator::SummarySuggestion'->new($_) } @$_ ] };

declare 'MapStringSummarySuggestion',
    as HashRef[SummarySuggestion()];

declare 'SummarySection',
    as InstanceOf['Google::Cloud::Dialogflow::V2beta1::Generator::SummarySuggestion::SummarySection'];

coerce 'SummarySection',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2beta1::Generator::SummarySuggestion::SummarySection'->new($_) };

declare 'RepeatedSummarySection',
    as ArrayRef[SummarySection()];

coerce 'RepeatedSummarySection',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2beta1::Generator::SummarySuggestion::SummarySection'->new($_) } @$_ ] };

declare 'MapStringSummarySection',
    as HashRef[SummarySection()];

declare 'AgentCoachingSuggestion',
    as InstanceOf['Google::Cloud::Dialogflow::V2beta1::Generator::AgentCoachingSuggestion'];

coerce 'AgentCoachingSuggestion',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2beta1::Generator::AgentCoachingSuggestion'->new($_) };

declare 'RepeatedAgentCoachingSuggestion',
    as ArrayRef[AgentCoachingSuggestion()];

coerce 'RepeatedAgentCoachingSuggestion',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2beta1::Generator::AgentCoachingSuggestion'->new($_) } @$_ ] };

declare 'MapStringAgentCoachingSuggestion',
    as HashRef[AgentCoachingSuggestion()];

declare 'Sources',
    as InstanceOf['Google::Cloud::Dialogflow::V2beta1::Generator::AgentCoachingSuggestion::Sources'];

coerce 'Sources',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2beta1::Generator::AgentCoachingSuggestion::Sources'->new($_) };

declare 'RepeatedSources',
    as ArrayRef[Sources()];

coerce 'RepeatedSources',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2beta1::Generator::AgentCoachingSuggestion::Sources'->new($_) } @$_ ] };

declare 'MapStringSources',
    as HashRef[Sources()];

declare 'DuplicateCheckResult',
    as InstanceOf['Google::Cloud::Dialogflow::V2beta1::Generator::AgentCoachingSuggestion::DuplicateCheckResult'];

coerce 'DuplicateCheckResult',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2beta1::Generator::AgentCoachingSuggestion::DuplicateCheckResult'->new($_) };

declare 'RepeatedDuplicateCheckResult',
    as ArrayRef[DuplicateCheckResult()];

coerce 'RepeatedDuplicateCheckResult',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2beta1::Generator::AgentCoachingSuggestion::DuplicateCheckResult'->new($_) } @$_ ] };

declare 'MapStringDuplicateCheckResult',
    as HashRef[DuplicateCheckResult()];

declare 'DuplicateSuggestion',
    as InstanceOf['Google::Cloud::Dialogflow::V2beta1::Generator::AgentCoachingSuggestion::DuplicateCheckResult::DuplicateSuggestion'];

coerce 'DuplicateSuggestion',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2beta1::Generator::AgentCoachingSuggestion::DuplicateCheckResult::DuplicateSuggestion'->new($_) };

declare 'RepeatedDuplicateSuggestion',
    as ArrayRef[DuplicateSuggestion()];

coerce 'RepeatedDuplicateSuggestion',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2beta1::Generator::AgentCoachingSuggestion::DuplicateCheckResult::DuplicateSuggestion'->new($_) } @$_ ] };

declare 'MapStringDuplicateSuggestion',
    as HashRef[DuplicateSuggestion()];

declare 'AgentActionSuggestion',
    as InstanceOf['Google::Cloud::Dialogflow::V2beta1::Generator::AgentCoachingSuggestion::AgentActionSuggestion'];

coerce 'AgentActionSuggestion',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2beta1::Generator::AgentCoachingSuggestion::AgentActionSuggestion'->new($_) };

declare 'RepeatedAgentActionSuggestion',
    as ArrayRef[AgentActionSuggestion()];

coerce 'RepeatedAgentActionSuggestion',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2beta1::Generator::AgentCoachingSuggestion::AgentActionSuggestion'->new($_) } @$_ ] };

declare 'MapStringAgentActionSuggestion',
    as HashRef[AgentActionSuggestion()];

declare 'SampleResponse',
    as InstanceOf['Google::Cloud::Dialogflow::V2beta1::Generator::AgentCoachingSuggestion::SampleResponse'];

coerce 'SampleResponse',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2beta1::Generator::AgentCoachingSuggestion::SampleResponse'->new($_) };

declare 'RepeatedSampleResponse',
    as ArrayRef[SampleResponse()];

coerce 'RepeatedSampleResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2beta1::Generator::AgentCoachingSuggestion::SampleResponse'->new($_) } @$_ ] };

declare 'MapStringSampleResponse',
    as HashRef[SampleResponse()];

declare 'GeneratorSuggestion',
    as InstanceOf['Google::Cloud::Dialogflow::V2beta1::Generator::GeneratorSuggestion'];

coerce 'GeneratorSuggestion',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2beta1::Generator::GeneratorSuggestion'->new($_) };

declare 'RepeatedGeneratorSuggestion',
    as ArrayRef[GeneratorSuggestion()];

coerce 'RepeatedGeneratorSuggestion',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2beta1::Generator::GeneratorSuggestion'->new($_) } @$_ ] };

declare 'MapStringGeneratorSuggestion',
    as HashRef[GeneratorSuggestion()];

declare 'ToolCallInfo',
    as InstanceOf['Google::Cloud::Dialogflow::V2beta1::Generator::GeneratorSuggestion::ToolCallInfo'];

coerce 'ToolCallInfo',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2beta1::Generator::GeneratorSuggestion::ToolCallInfo'->new($_) };

declare 'RepeatedToolCallInfo',
    as ArrayRef[ToolCallInfo()];

coerce 'RepeatedToolCallInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2beta1::Generator::GeneratorSuggestion::ToolCallInfo'->new($_) } @$_ ] };

declare 'MapStringToolCallInfo',
    as HashRef[ToolCallInfo()];

declare 'SuggestionDedupingConfig',
    as InstanceOf['Google::Cloud::Dialogflow::V2beta1::Generator::SuggestionDedupingConfig'];

coerce 'SuggestionDedupingConfig',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2beta1::Generator::SuggestionDedupingConfig'->new($_) };

declare 'RepeatedSuggestionDedupingConfig',
    as ArrayRef[SuggestionDedupingConfig()];

coerce 'RepeatedSuggestionDedupingConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2beta1::Generator::SuggestionDedupingConfig'->new($_) } @$_ ] };

declare 'MapStringSuggestionDedupingConfig',
    as HashRef[SuggestionDedupingConfig()];

declare 'RaiSettings',
    as InstanceOf['Google::Cloud::Dialogflow::V2beta1::Generator::RaiSettings'];

coerce 'RaiSettings',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2beta1::Generator::RaiSettings'->new($_) };

declare 'RepeatedRaiSettings',
    as ArrayRef[RaiSettings()];

coerce 'RepeatedRaiSettings',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2beta1::Generator::RaiSettings'->new($_) } @$_ ] };

declare 'MapStringRaiSettings',
    as HashRef[RaiSettings()];

declare 'RaiCategoryConfig',
    as InstanceOf['Google::Cloud::Dialogflow::V2beta1::Generator::RaiSettings::RaiCategoryConfig'];

coerce 'RaiCategoryConfig',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2beta1::Generator::RaiSettings::RaiCategoryConfig'->new($_) };

declare 'RepeatedRaiCategoryConfig',
    as ArrayRef[RaiCategoryConfig()];

coerce 'RepeatedRaiCategoryConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2beta1::Generator::RaiSettings::RaiCategoryConfig'->new($_) } @$_ ] };

declare 'MapStringRaiCategoryConfig',
    as HashRef[RaiCategoryConfig()];

declare 'RaiCategory',
    as (Int | Str);

declare 'SensitivityLevel',
    as (Int | Str);

1;

__END__

=head1 NAME

Google::Cloud::Dialogflow::V2beta1::Generator::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
