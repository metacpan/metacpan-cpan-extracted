package Google::Cloud::Dialogflow::V2::CompanionAgent::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'CreateCompanionAgentRequest',
    as InstanceOf['Google::Cloud::Dialogflow::V2::CompanionAgent::CreateCompanionAgentRequest'];

coerce 'CreateCompanionAgentRequest',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::CompanionAgent::CreateCompanionAgentRequest'->new($_) };

declare 'RepeatedCreateCompanionAgentRequest',
    as ArrayRef[CreateCompanionAgentRequest()];

coerce 'RepeatedCreateCompanionAgentRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::CompanionAgent::CreateCompanionAgentRequest'->new($_) } @$_ ] };

declare 'MapStringCreateCompanionAgentRequest',
    as HashRef[CreateCompanionAgentRequest()];

declare 'GetCompanionAgentRequest',
    as InstanceOf['Google::Cloud::Dialogflow::V2::CompanionAgent::GetCompanionAgentRequest'];

coerce 'GetCompanionAgentRequest',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::CompanionAgent::GetCompanionAgentRequest'->new($_) };

declare 'RepeatedGetCompanionAgentRequest',
    as ArrayRef[GetCompanionAgentRequest()];

coerce 'RepeatedGetCompanionAgentRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::CompanionAgent::GetCompanionAgentRequest'->new($_) } @$_ ] };

declare 'MapStringGetCompanionAgentRequest',
    as HashRef[GetCompanionAgentRequest()];

declare 'ListCompanionAgentsRequest',
    as InstanceOf['Google::Cloud::Dialogflow::V2::CompanionAgent::ListCompanionAgentsRequest'];

coerce 'ListCompanionAgentsRequest',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::CompanionAgent::ListCompanionAgentsRequest'->new($_) };

declare 'RepeatedListCompanionAgentsRequest',
    as ArrayRef[ListCompanionAgentsRequest()];

coerce 'RepeatedListCompanionAgentsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::CompanionAgent::ListCompanionAgentsRequest'->new($_) } @$_ ] };

declare 'MapStringListCompanionAgentsRequest',
    as HashRef[ListCompanionAgentsRequest()];

declare 'ListCompanionAgentsResponse',
    as InstanceOf['Google::Cloud::Dialogflow::V2::CompanionAgent::ListCompanionAgentsResponse'];

coerce 'ListCompanionAgentsResponse',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::CompanionAgent::ListCompanionAgentsResponse'->new($_) };

declare 'RepeatedListCompanionAgentsResponse',
    as ArrayRef[ListCompanionAgentsResponse()];

coerce 'RepeatedListCompanionAgentsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::CompanionAgent::ListCompanionAgentsResponse'->new($_) } @$_ ] };

declare 'MapStringListCompanionAgentsResponse',
    as HashRef[ListCompanionAgentsResponse()];

declare 'UpdateCompanionAgentRequest',
    as InstanceOf['Google::Cloud::Dialogflow::V2::CompanionAgent::UpdateCompanionAgentRequest'];

coerce 'UpdateCompanionAgentRequest',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::CompanionAgent::UpdateCompanionAgentRequest'->new($_) };

declare 'RepeatedUpdateCompanionAgentRequest',
    as ArrayRef[UpdateCompanionAgentRequest()];

coerce 'RepeatedUpdateCompanionAgentRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::CompanionAgent::UpdateCompanionAgentRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateCompanionAgentRequest',
    as HashRef[UpdateCompanionAgentRequest()];

declare 'DeleteCompanionAgentRequest',
    as InstanceOf['Google::Cloud::Dialogflow::V2::CompanionAgent::DeleteCompanionAgentRequest'];

coerce 'DeleteCompanionAgentRequest',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::CompanionAgent::DeleteCompanionAgentRequest'->new($_) };

declare 'RepeatedDeleteCompanionAgentRequest',
    as ArrayRef[DeleteCompanionAgentRequest()];

coerce 'RepeatedDeleteCompanionAgentRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::CompanionAgent::DeleteCompanionAgentRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteCompanionAgentRequest',
    as HashRef[DeleteCompanionAgentRequest()];

declare 'GuidanceInstruction',
    as InstanceOf['Google::Cloud::Dialogflow::V2::CompanionAgent::GuidanceInstruction'];

coerce 'GuidanceInstruction',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::CompanionAgent::GuidanceInstruction'->new($_) };

declare 'RepeatedGuidanceInstruction',
    as ArrayRef[GuidanceInstruction()];

coerce 'RepeatedGuidanceInstruction',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::CompanionAgent::GuidanceInstruction'->new($_) } @$_ ] };

declare 'MapStringGuidanceInstruction',
    as HashRef[GuidanceInstruction()];

declare 'Action',
    as InstanceOf['Google::Cloud::Dialogflow::V2::CompanionAgent::GuidanceInstruction::Action'];

coerce 'Action',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::CompanionAgent::GuidanceInstruction::Action'->new($_) };

declare 'RepeatedAction',
    as ArrayRef[Action()];

coerce 'RepeatedAction',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::CompanionAgent::GuidanceInstruction::Action'->new($_) } @$_ ] };

declare 'MapStringAction',
    as HashRef[Action()];

declare 'CompanionAgent',
    as InstanceOf['Google::Cloud::Dialogflow::V2::CompanionAgent::CompanionAgent'];

coerce 'CompanionAgent',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::CompanionAgent::CompanionAgent'->new($_) };

declare 'RepeatedCompanionAgent',
    as ArrayRef[CompanionAgent()];

coerce 'RepeatedCompanionAgent',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::CompanionAgent::CompanionAgent'->new($_) } @$_ ] };

declare 'MapStringCompanionAgent',
    as HashRef[CompanionAgent()];

declare 'TriggerEvent',
    as (Int | Str);

declare 'SkillConfig',
    as InstanceOf['Google::Cloud::Dialogflow::V2::CompanionAgent::CompanionAgent::SkillConfig'];

coerce 'SkillConfig',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::CompanionAgent::CompanionAgent::SkillConfig'->new($_) };

declare 'RepeatedSkillConfig',
    as ArrayRef[SkillConfig()];

coerce 'RepeatedSkillConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::CompanionAgent::CompanionAgent::SkillConfig'->new($_) } @$_ ] };

declare 'MapStringSkillConfig',
    as HashRef[SkillConfig()];

declare 'SkillTriggerEvent',
    as (Int | Str);

declare 'GuidanceSkillConfig',
    as InstanceOf['Google::Cloud::Dialogflow::V2::CompanionAgent::CompanionAgent::GuidanceSkillConfig'];

coerce 'GuidanceSkillConfig',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::CompanionAgent::CompanionAgent::GuidanceSkillConfig'->new($_) };

declare 'RepeatedGuidanceSkillConfig',
    as ArrayRef[GuidanceSkillConfig()];

coerce 'RepeatedGuidanceSkillConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::CompanionAgent::CompanionAgent::GuidanceSkillConfig'->new($_) } @$_ ] };

declare 'MapStringGuidanceSkillConfig',
    as HashRef[GuidanceSkillConfig()];

declare 'KnowledgeSource',
    as InstanceOf['Google::Cloud::Dialogflow::V2::CompanionAgent::CompanionAgent::KnowledgeSource'];

coerce 'KnowledgeSource',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::CompanionAgent::CompanionAgent::KnowledgeSource'->new($_) };

declare 'RepeatedKnowledgeSource',
    as ArrayRef[KnowledgeSource()];

coerce 'RepeatedKnowledgeSource',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::CompanionAgent::CompanionAgent::KnowledgeSource'->new($_) } @$_ ] };

declare 'MapStringKnowledgeSource',
    as HashRef[KnowledgeSource()];

declare 'TranslationSkillConfig',
    as InstanceOf['Google::Cloud::Dialogflow::V2::CompanionAgent::CompanionAgent::TranslationSkillConfig'];

coerce 'TranslationSkillConfig',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::CompanionAgent::CompanionAgent::TranslationSkillConfig'->new($_) };

declare 'RepeatedTranslationSkillConfig',
    as ArrayRef[TranslationSkillConfig()];

coerce 'RepeatedTranslationSkillConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::CompanionAgent::CompanionAgent::TranslationSkillConfig'->new($_) } @$_ ] };

declare 'MapStringTranslationSkillConfig',
    as HashRef[TranslationSkillConfig()];

1;

__END__

=head1 NAME

Google::Cloud::Dialogflow::V2::CompanionAgent::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
