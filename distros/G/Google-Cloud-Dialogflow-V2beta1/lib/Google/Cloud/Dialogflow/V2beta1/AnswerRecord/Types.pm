package Google::Cloud::Dialogflow::V2beta1::AnswerRecord::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'AnswerRecord',
    as InstanceOf['Google::Cloud::Dialogflow::V2beta1::AnswerRecord::AnswerRecord'];

coerce 'AnswerRecord',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2beta1::AnswerRecord::AnswerRecord'->new($_) };

declare 'RepeatedAnswerRecord',
    as ArrayRef[AnswerRecord()];

coerce 'RepeatedAnswerRecord',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2beta1::AnswerRecord::AnswerRecord'->new($_) } @$_ ] };

declare 'MapStringAnswerRecord',
    as HashRef[AnswerRecord()];

declare 'AgentAssistantRecord',
    as InstanceOf['Google::Cloud::Dialogflow::V2beta1::AnswerRecord::AgentAssistantRecord'];

coerce 'AgentAssistantRecord',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2beta1::AnswerRecord::AgentAssistantRecord'->new($_) };

declare 'RepeatedAgentAssistantRecord',
    as ArrayRef[AgentAssistantRecord()];

coerce 'RepeatedAgentAssistantRecord',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2beta1::AnswerRecord::AgentAssistantRecord'->new($_) } @$_ ] };

declare 'MapStringAgentAssistantRecord',
    as HashRef[AgentAssistantRecord()];

declare 'AnswerFeedback',
    as InstanceOf['Google::Cloud::Dialogflow::V2beta1::AnswerRecord::AnswerFeedback'];

coerce 'AnswerFeedback',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2beta1::AnswerRecord::AnswerFeedback'->new($_) };

declare 'RepeatedAnswerFeedback',
    as ArrayRef[AnswerFeedback()];

coerce 'RepeatedAnswerFeedback',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2beta1::AnswerRecord::AnswerFeedback'->new($_) } @$_ ] };

declare 'MapStringAnswerFeedback',
    as HashRef[AnswerFeedback()];

declare 'CorrectnessLevel',
    as (Int | Str);

declare 'AgentAssistantFeedback',
    as InstanceOf['Google::Cloud::Dialogflow::V2beta1::AnswerRecord::AgentAssistantFeedback'];

coerce 'AgentAssistantFeedback',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2beta1::AnswerRecord::AgentAssistantFeedback'->new($_) };

declare 'RepeatedAgentAssistantFeedback',
    as ArrayRef[AgentAssistantFeedback()];

coerce 'RepeatedAgentAssistantFeedback',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2beta1::AnswerRecord::AgentAssistantFeedback'->new($_) } @$_ ] };

declare 'MapStringAgentAssistantFeedback',
    as HashRef[AgentAssistantFeedback()];

declare 'AnswerRelevance',
    as (Int | Str);

declare 'DocumentCorrectness',
    as (Int | Str);

declare 'DocumentEfficiency',
    as (Int | Str);

declare 'SummarizationFeedback',
    as InstanceOf['Google::Cloud::Dialogflow::V2beta1::AnswerRecord::AgentAssistantFeedback::SummarizationFeedback'];

coerce 'SummarizationFeedback',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2beta1::AnswerRecord::AgentAssistantFeedback::SummarizationFeedback'->new($_) };

declare 'RepeatedSummarizationFeedback',
    as ArrayRef[SummarizationFeedback()];

coerce 'RepeatedSummarizationFeedback',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2beta1::AnswerRecord::AgentAssistantFeedback::SummarizationFeedback'->new($_) } @$_ ] };

declare 'MapStringSummarizationFeedback',
    as HashRef[SummarizationFeedback()];

declare 'TextSectionsEntry',
    as InstanceOf['Google::Cloud::Dialogflow::V2beta1::AnswerRecord::AgentAssistantFeedback::SummarizationFeedback::TextSectionsEntry'];

coerce 'TextSectionsEntry',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2beta1::AnswerRecord::AgentAssistantFeedback::SummarizationFeedback::TextSectionsEntry'->new($_) };

declare 'RepeatedTextSectionsEntry',
    as ArrayRef[TextSectionsEntry()];

coerce 'RepeatedTextSectionsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2beta1::AnswerRecord::AgentAssistantFeedback::SummarizationFeedback::TextSectionsEntry'->new($_) } @$_ ] };

declare 'MapStringTextSectionsEntry',
    as HashRef[TextSectionsEntry()];

declare 'KnowledgeSearchFeedback',
    as InstanceOf['Google::Cloud::Dialogflow::V2beta1::AnswerRecord::AgentAssistantFeedback::KnowledgeSearchFeedback'];

coerce 'KnowledgeSearchFeedback',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2beta1::AnswerRecord::AgentAssistantFeedback::KnowledgeSearchFeedback'->new($_) };

declare 'RepeatedKnowledgeSearchFeedback',
    as ArrayRef[KnowledgeSearchFeedback()];

coerce 'RepeatedKnowledgeSearchFeedback',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2beta1::AnswerRecord::AgentAssistantFeedback::KnowledgeSearchFeedback'->new($_) } @$_ ] };

declare 'MapStringKnowledgeSearchFeedback',
    as HashRef[KnowledgeSearchFeedback()];

declare 'KnowledgeAssistFeedback',
    as InstanceOf['Google::Cloud::Dialogflow::V2beta1::AnswerRecord::AgentAssistantFeedback::KnowledgeAssistFeedback'];

coerce 'KnowledgeAssistFeedback',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2beta1::AnswerRecord::AgentAssistantFeedback::KnowledgeAssistFeedback'->new($_) };

declare 'RepeatedKnowledgeAssistFeedback',
    as ArrayRef[KnowledgeAssistFeedback()];

coerce 'RepeatedKnowledgeAssistFeedback',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2beta1::AnswerRecord::AgentAssistantFeedback::KnowledgeAssistFeedback'->new($_) } @$_ ] };

declare 'MapStringKnowledgeAssistFeedback',
    as HashRef[KnowledgeAssistFeedback()];

declare 'CompanionFeedback',
    as InstanceOf['Google::Cloud::Dialogflow::V2beta1::AnswerRecord::AgentAssistantFeedback::CompanionFeedback'];

coerce 'CompanionFeedback',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2beta1::AnswerRecord::AgentAssistantFeedback::CompanionFeedback'->new($_) };

declare 'RepeatedCompanionFeedback',
    as ArrayRef[CompanionFeedback()];

coerce 'RepeatedCompanionFeedback',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2beta1::AnswerRecord::AgentAssistantFeedback::CompanionFeedback'->new($_) } @$_ ] };

declare 'MapStringCompanionFeedback',
    as HashRef[CompanionFeedback()];

declare 'GetAnswerRecordRequest',
    as InstanceOf['Google::Cloud::Dialogflow::V2beta1::AnswerRecord::GetAnswerRecordRequest'];

coerce 'GetAnswerRecordRequest',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2beta1::AnswerRecord::GetAnswerRecordRequest'->new($_) };

declare 'RepeatedGetAnswerRecordRequest',
    as ArrayRef[GetAnswerRecordRequest()];

coerce 'RepeatedGetAnswerRecordRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2beta1::AnswerRecord::GetAnswerRecordRequest'->new($_) } @$_ ] };

declare 'MapStringGetAnswerRecordRequest',
    as HashRef[GetAnswerRecordRequest()];

declare 'ListAnswerRecordsRequest',
    as InstanceOf['Google::Cloud::Dialogflow::V2beta1::AnswerRecord::ListAnswerRecordsRequest'];

coerce 'ListAnswerRecordsRequest',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2beta1::AnswerRecord::ListAnswerRecordsRequest'->new($_) };

declare 'RepeatedListAnswerRecordsRequest',
    as ArrayRef[ListAnswerRecordsRequest()];

coerce 'RepeatedListAnswerRecordsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2beta1::AnswerRecord::ListAnswerRecordsRequest'->new($_) } @$_ ] };

declare 'MapStringListAnswerRecordsRequest',
    as HashRef[ListAnswerRecordsRequest()];

declare 'ListAnswerRecordsResponse',
    as InstanceOf['Google::Cloud::Dialogflow::V2beta1::AnswerRecord::ListAnswerRecordsResponse'];

coerce 'ListAnswerRecordsResponse',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2beta1::AnswerRecord::ListAnswerRecordsResponse'->new($_) };

declare 'RepeatedListAnswerRecordsResponse',
    as ArrayRef[ListAnswerRecordsResponse()];

coerce 'RepeatedListAnswerRecordsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2beta1::AnswerRecord::ListAnswerRecordsResponse'->new($_) } @$_ ] };

declare 'MapStringListAnswerRecordsResponse',
    as HashRef[ListAnswerRecordsResponse()];

declare 'UpdateAnswerRecordRequest',
    as InstanceOf['Google::Cloud::Dialogflow::V2beta1::AnswerRecord::UpdateAnswerRecordRequest'];

coerce 'UpdateAnswerRecordRequest',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2beta1::AnswerRecord::UpdateAnswerRecordRequest'->new($_) };

declare 'RepeatedUpdateAnswerRecordRequest',
    as ArrayRef[UpdateAnswerRecordRequest()];

coerce 'RepeatedUpdateAnswerRecordRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2beta1::AnswerRecord::UpdateAnswerRecordRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateAnswerRecordRequest',
    as HashRef[UpdateAnswerRecordRequest()];

1;

__END__

=head1 NAME

Google::Cloud::Dialogflow::V2beta1::AnswerRecord::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
