package Google::Cloud::Dialogflow::Cx::V3beta1::Agent::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'SpeechToTextSettings',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3beta1::Agent::SpeechToTextSettings'];

coerce 'SpeechToTextSettings',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3beta1::Agent::SpeechToTextSettings'->new($_) };

declare 'RepeatedSpeechToTextSettings',
    as ArrayRef[SpeechToTextSettings()];

coerce 'RepeatedSpeechToTextSettings',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3beta1::Agent::SpeechToTextSettings'->new($_) } @$_ ] };

declare 'MapStringSpeechToTextSettings',
    as HashRef[SpeechToTextSettings()];

declare 'Agent',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3beta1::Agent::Agent'];

coerce 'Agent',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3beta1::Agent::Agent'->new($_) };

declare 'RepeatedAgent',
    as ArrayRef[Agent()];

coerce 'RepeatedAgent',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3beta1::Agent::Agent'->new($_) } @$_ ] };

declare 'MapStringAgent',
    as HashRef[Agent()];

declare 'GitIntegrationSettings',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3beta1::Agent::Agent::GitIntegrationSettings'];

coerce 'GitIntegrationSettings',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3beta1::Agent::Agent::GitIntegrationSettings'->new($_) };

declare 'RepeatedGitIntegrationSettings',
    as ArrayRef[GitIntegrationSettings()];

coerce 'RepeatedGitIntegrationSettings',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3beta1::Agent::Agent::GitIntegrationSettings'->new($_) } @$_ ] };

declare 'MapStringGitIntegrationSettings',
    as HashRef[GitIntegrationSettings()];

declare 'GithubSettings',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3beta1::Agent::Agent::GitIntegrationSettings::GithubSettings'];

coerce 'GithubSettings',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3beta1::Agent::Agent::GitIntegrationSettings::GithubSettings'->new($_) };

declare 'RepeatedGithubSettings',
    as ArrayRef[GithubSettings()];

coerce 'RepeatedGithubSettings',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3beta1::Agent::Agent::GitIntegrationSettings::GithubSettings'->new($_) } @$_ ] };

declare 'MapStringGithubSettings',
    as HashRef[GithubSettings()];

declare 'GitConnectionSettings',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3beta1::Agent::Agent::GitIntegrationSettings::GitConnectionSettings'];

coerce 'GitConnectionSettings',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3beta1::Agent::Agent::GitIntegrationSettings::GitConnectionSettings'->new($_) };

declare 'RepeatedGitConnectionSettings',
    as ArrayRef[GitConnectionSettings()];

coerce 'RepeatedGitConnectionSettings',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3beta1::Agent::Agent::GitIntegrationSettings::GitConnectionSettings'->new($_) } @$_ ] };

declare 'MapStringGitConnectionSettings',
    as HashRef[GitConnectionSettings()];

declare 'GenAppBuilderSettings',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3beta1::Agent::Agent::GenAppBuilderSettings'];

coerce 'GenAppBuilderSettings',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3beta1::Agent::Agent::GenAppBuilderSettings'->new($_) };

declare 'RepeatedGenAppBuilderSettings',
    as ArrayRef[GenAppBuilderSettings()];

coerce 'RepeatedGenAppBuilderSettings',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3beta1::Agent::Agent::GenAppBuilderSettings'->new($_) } @$_ ] };

declare 'MapStringGenAppBuilderSettings',
    as HashRef[GenAppBuilderSettings()];

declare 'AnswerFeedbackSettings',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3beta1::Agent::Agent::AnswerFeedbackSettings'];

coerce 'AnswerFeedbackSettings',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3beta1::Agent::Agent::AnswerFeedbackSettings'->new($_) };

declare 'RepeatedAnswerFeedbackSettings',
    as ArrayRef[AnswerFeedbackSettings()];

coerce 'RepeatedAnswerFeedbackSettings',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3beta1::Agent::Agent::AnswerFeedbackSettings'->new($_) } @$_ ] };

declare 'MapStringAnswerFeedbackSettings',
    as HashRef[AnswerFeedbackSettings()];

declare 'PersonalizationSettings',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3beta1::Agent::Agent::PersonalizationSettings'];

coerce 'PersonalizationSettings',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3beta1::Agent::Agent::PersonalizationSettings'->new($_) };

declare 'RepeatedPersonalizationSettings',
    as ArrayRef[PersonalizationSettings()];

coerce 'RepeatedPersonalizationSettings',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3beta1::Agent::Agent::PersonalizationSettings'->new($_) } @$_ ] };

declare 'MapStringPersonalizationSettings',
    as HashRef[PersonalizationSettings()];

declare 'ClientCertificateSettings',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3beta1::Agent::Agent::ClientCertificateSettings'];

coerce 'ClientCertificateSettings',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3beta1::Agent::Agent::ClientCertificateSettings'->new($_) };

declare 'RepeatedClientCertificateSettings',
    as ArrayRef[ClientCertificateSettings()];

coerce 'RepeatedClientCertificateSettings',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3beta1::Agent::Agent::ClientCertificateSettings'->new($_) } @$_ ] };

declare 'MapStringClientCertificateSettings',
    as HashRef[ClientCertificateSettings()];

declare 'ListAgentsRequest',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3beta1::Agent::ListAgentsRequest'];

coerce 'ListAgentsRequest',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3beta1::Agent::ListAgentsRequest'->new($_) };

declare 'RepeatedListAgentsRequest',
    as ArrayRef[ListAgentsRequest()];

coerce 'RepeatedListAgentsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3beta1::Agent::ListAgentsRequest'->new($_) } @$_ ] };

declare 'MapStringListAgentsRequest',
    as HashRef[ListAgentsRequest()];

declare 'ListAgentsResponse',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3beta1::Agent::ListAgentsResponse'];

coerce 'ListAgentsResponse',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3beta1::Agent::ListAgentsResponse'->new($_) };

declare 'RepeatedListAgentsResponse',
    as ArrayRef[ListAgentsResponse()];

coerce 'RepeatedListAgentsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3beta1::Agent::ListAgentsResponse'->new($_) } @$_ ] };

declare 'MapStringListAgentsResponse',
    as HashRef[ListAgentsResponse()];

declare 'GetAgentRequest',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3beta1::Agent::GetAgentRequest'];

coerce 'GetAgentRequest',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3beta1::Agent::GetAgentRequest'->new($_) };

declare 'RepeatedGetAgentRequest',
    as ArrayRef[GetAgentRequest()];

coerce 'RepeatedGetAgentRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3beta1::Agent::GetAgentRequest'->new($_) } @$_ ] };

declare 'MapStringGetAgentRequest',
    as HashRef[GetAgentRequest()];

declare 'CreateAgentRequest',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3beta1::Agent::CreateAgentRequest'];

coerce 'CreateAgentRequest',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3beta1::Agent::CreateAgentRequest'->new($_) };

declare 'RepeatedCreateAgentRequest',
    as ArrayRef[CreateAgentRequest()];

coerce 'RepeatedCreateAgentRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3beta1::Agent::CreateAgentRequest'->new($_) } @$_ ] };

declare 'MapStringCreateAgentRequest',
    as HashRef[CreateAgentRequest()];

declare 'UpdateAgentRequest',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3beta1::Agent::UpdateAgentRequest'];

coerce 'UpdateAgentRequest',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3beta1::Agent::UpdateAgentRequest'->new($_) };

declare 'RepeatedUpdateAgentRequest',
    as ArrayRef[UpdateAgentRequest()];

coerce 'RepeatedUpdateAgentRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3beta1::Agent::UpdateAgentRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateAgentRequest',
    as HashRef[UpdateAgentRequest()];

declare 'DeleteAgentRequest',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3beta1::Agent::DeleteAgentRequest'];

coerce 'DeleteAgentRequest',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3beta1::Agent::DeleteAgentRequest'->new($_) };

declare 'RepeatedDeleteAgentRequest',
    as ArrayRef[DeleteAgentRequest()];

coerce 'RepeatedDeleteAgentRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3beta1::Agent::DeleteAgentRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteAgentRequest',
    as HashRef[DeleteAgentRequest()];

declare 'ExportAgentRequest',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3beta1::Agent::ExportAgentRequest'];

coerce 'ExportAgentRequest',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3beta1::Agent::ExportAgentRequest'->new($_) };

declare 'RepeatedExportAgentRequest',
    as ArrayRef[ExportAgentRequest()];

coerce 'RepeatedExportAgentRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3beta1::Agent::ExportAgentRequest'->new($_) } @$_ ] };

declare 'MapStringExportAgentRequest',
    as HashRef[ExportAgentRequest()];

declare 'DataFormat',
    as (Int | Str);

declare 'GitDestination',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3beta1::Agent::ExportAgentRequest::GitDestination'];

coerce 'GitDestination',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3beta1::Agent::ExportAgentRequest::GitDestination'->new($_) };

declare 'RepeatedGitDestination',
    as ArrayRef[GitDestination()];

coerce 'RepeatedGitDestination',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3beta1::Agent::ExportAgentRequest::GitDestination'->new($_) } @$_ ] };

declare 'MapStringGitDestination',
    as HashRef[GitDestination()];

declare 'ExportAgentResponse',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3beta1::Agent::ExportAgentResponse'];

coerce 'ExportAgentResponse',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3beta1::Agent::ExportAgentResponse'->new($_) };

declare 'RepeatedExportAgentResponse',
    as ArrayRef[ExportAgentResponse()];

coerce 'RepeatedExportAgentResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3beta1::Agent::ExportAgentResponse'->new($_) } @$_ ] };

declare 'MapStringExportAgentResponse',
    as HashRef[ExportAgentResponse()];

declare 'RestoreAgentRequest',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3beta1::Agent::RestoreAgentRequest'];

coerce 'RestoreAgentRequest',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3beta1::Agent::RestoreAgentRequest'->new($_) };

declare 'RepeatedRestoreAgentRequest',
    as ArrayRef[RestoreAgentRequest()];

coerce 'RepeatedRestoreAgentRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3beta1::Agent::RestoreAgentRequest'->new($_) } @$_ ] };

declare 'MapStringRestoreAgentRequest',
    as HashRef[RestoreAgentRequest()];

declare 'RestoreOption',
    as (Int | Str);

declare 'GitSource',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3beta1::Agent::RestoreAgentRequest::GitSource'];

coerce 'GitSource',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3beta1::Agent::RestoreAgentRequest::GitSource'->new($_) };

declare 'RepeatedGitSource',
    as ArrayRef[GitSource()];

coerce 'RepeatedGitSource',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3beta1::Agent::RestoreAgentRequest::GitSource'->new($_) } @$_ ] };

declare 'MapStringGitSource',
    as HashRef[GitSource()];

declare 'ValidateAgentRequest',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3beta1::Agent::ValidateAgentRequest'];

coerce 'ValidateAgentRequest',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3beta1::Agent::ValidateAgentRequest'->new($_) };

declare 'RepeatedValidateAgentRequest',
    as ArrayRef[ValidateAgentRequest()];

coerce 'RepeatedValidateAgentRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3beta1::Agent::ValidateAgentRequest'->new($_) } @$_ ] };

declare 'MapStringValidateAgentRequest',
    as HashRef[ValidateAgentRequest()];

declare 'GetAgentValidationResultRequest',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3beta1::Agent::GetAgentValidationResultRequest'];

coerce 'GetAgentValidationResultRequest',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3beta1::Agent::GetAgentValidationResultRequest'->new($_) };

declare 'RepeatedGetAgentValidationResultRequest',
    as ArrayRef[GetAgentValidationResultRequest()];

coerce 'RepeatedGetAgentValidationResultRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3beta1::Agent::GetAgentValidationResultRequest'->new($_) } @$_ ] };

declare 'MapStringGetAgentValidationResultRequest',
    as HashRef[GetAgentValidationResultRequest()];

declare 'AgentValidationResult',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3beta1::Agent::AgentValidationResult'];

coerce 'AgentValidationResult',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3beta1::Agent::AgentValidationResult'->new($_) };

declare 'RepeatedAgentValidationResult',
    as ArrayRef[AgentValidationResult()];

coerce 'RepeatedAgentValidationResult',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3beta1::Agent::AgentValidationResult'->new($_) } @$_ ] };

declare 'MapStringAgentValidationResult',
    as HashRef[AgentValidationResult()];

declare 'GetGenerativeSettingsRequest',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3beta1::Agent::GetGenerativeSettingsRequest'];

coerce 'GetGenerativeSettingsRequest',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3beta1::Agent::GetGenerativeSettingsRequest'->new($_) };

declare 'RepeatedGetGenerativeSettingsRequest',
    as ArrayRef[GetGenerativeSettingsRequest()];

coerce 'RepeatedGetGenerativeSettingsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3beta1::Agent::GetGenerativeSettingsRequest'->new($_) } @$_ ] };

declare 'MapStringGetGenerativeSettingsRequest',
    as HashRef[GetGenerativeSettingsRequest()];

declare 'UpdateGenerativeSettingsRequest',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3beta1::Agent::UpdateGenerativeSettingsRequest'];

coerce 'UpdateGenerativeSettingsRequest',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3beta1::Agent::UpdateGenerativeSettingsRequest'->new($_) };

declare 'RepeatedUpdateGenerativeSettingsRequest',
    as ArrayRef[UpdateGenerativeSettingsRequest()];

coerce 'RepeatedUpdateGenerativeSettingsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3beta1::Agent::UpdateGenerativeSettingsRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateGenerativeSettingsRequest',
    as HashRef[UpdateGenerativeSettingsRequest()];

1;

__END__

=head1 NAME

Google::Cloud::Dialogflow::Cx::V3beta1::Agent::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
