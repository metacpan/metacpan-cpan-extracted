package Google::Cloud::Dialogflow::V2::ConversationProfile::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'ConversationProfile',
    as InstanceOf['Google::Cloud::Dialogflow::V2::ConversationProfile::ConversationProfile'];

coerce 'ConversationProfile',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::ConversationProfile::ConversationProfile'->new($_) };

declare 'RepeatedConversationProfile',
    as ArrayRef[ConversationProfile()];

coerce 'RepeatedConversationProfile',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::ConversationProfile::ConversationProfile'->new($_) } @$_ ] };

declare 'MapStringConversationProfile',
    as HashRef[ConversationProfile()];

declare 'ListConversationProfilesRequest',
    as InstanceOf['Google::Cloud::Dialogflow::V2::ConversationProfile::ListConversationProfilesRequest'];

coerce 'ListConversationProfilesRequest',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::ConversationProfile::ListConversationProfilesRequest'->new($_) };

declare 'RepeatedListConversationProfilesRequest',
    as ArrayRef[ListConversationProfilesRequest()];

coerce 'RepeatedListConversationProfilesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::ConversationProfile::ListConversationProfilesRequest'->new($_) } @$_ ] };

declare 'MapStringListConversationProfilesRequest',
    as HashRef[ListConversationProfilesRequest()];

declare 'ListConversationProfilesResponse',
    as InstanceOf['Google::Cloud::Dialogflow::V2::ConversationProfile::ListConversationProfilesResponse'];

coerce 'ListConversationProfilesResponse',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::ConversationProfile::ListConversationProfilesResponse'->new($_) };

declare 'RepeatedListConversationProfilesResponse',
    as ArrayRef[ListConversationProfilesResponse()];

coerce 'RepeatedListConversationProfilesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::ConversationProfile::ListConversationProfilesResponse'->new($_) } @$_ ] };

declare 'MapStringListConversationProfilesResponse',
    as HashRef[ListConversationProfilesResponse()];

declare 'GetConversationProfileRequest',
    as InstanceOf['Google::Cloud::Dialogflow::V2::ConversationProfile::GetConversationProfileRequest'];

coerce 'GetConversationProfileRequest',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::ConversationProfile::GetConversationProfileRequest'->new($_) };

declare 'RepeatedGetConversationProfileRequest',
    as ArrayRef[GetConversationProfileRequest()];

coerce 'RepeatedGetConversationProfileRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::ConversationProfile::GetConversationProfileRequest'->new($_) } @$_ ] };

declare 'MapStringGetConversationProfileRequest',
    as HashRef[GetConversationProfileRequest()];

declare 'CreateConversationProfileRequest',
    as InstanceOf['Google::Cloud::Dialogflow::V2::ConversationProfile::CreateConversationProfileRequest'];

coerce 'CreateConversationProfileRequest',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::ConversationProfile::CreateConversationProfileRequest'->new($_) };

declare 'RepeatedCreateConversationProfileRequest',
    as ArrayRef[CreateConversationProfileRequest()];

coerce 'RepeatedCreateConversationProfileRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::ConversationProfile::CreateConversationProfileRequest'->new($_) } @$_ ] };

declare 'MapStringCreateConversationProfileRequest',
    as HashRef[CreateConversationProfileRequest()];

declare 'UpdateConversationProfileRequest',
    as InstanceOf['Google::Cloud::Dialogflow::V2::ConversationProfile::UpdateConversationProfileRequest'];

coerce 'UpdateConversationProfileRequest',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::ConversationProfile::UpdateConversationProfileRequest'->new($_) };

declare 'RepeatedUpdateConversationProfileRequest',
    as ArrayRef[UpdateConversationProfileRequest()];

coerce 'RepeatedUpdateConversationProfileRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::ConversationProfile::UpdateConversationProfileRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateConversationProfileRequest',
    as HashRef[UpdateConversationProfileRequest()];

declare 'DeleteConversationProfileRequest',
    as InstanceOf['Google::Cloud::Dialogflow::V2::ConversationProfile::DeleteConversationProfileRequest'];

coerce 'DeleteConversationProfileRequest',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::ConversationProfile::DeleteConversationProfileRequest'->new($_) };

declare 'RepeatedDeleteConversationProfileRequest',
    as ArrayRef[DeleteConversationProfileRequest()];

coerce 'RepeatedDeleteConversationProfileRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::ConversationProfile::DeleteConversationProfileRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteConversationProfileRequest',
    as HashRef[DeleteConversationProfileRequest()];

declare 'AutomatedAgentConfig',
    as InstanceOf['Google::Cloud::Dialogflow::V2::ConversationProfile::AutomatedAgentConfig'];

coerce 'AutomatedAgentConfig',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::ConversationProfile::AutomatedAgentConfig'->new($_) };

declare 'RepeatedAutomatedAgentConfig',
    as ArrayRef[AutomatedAgentConfig()];

coerce 'RepeatedAutomatedAgentConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::ConversationProfile::AutomatedAgentConfig'->new($_) } @$_ ] };

declare 'MapStringAutomatedAgentConfig',
    as HashRef[AutomatedAgentConfig()];

declare 'HumanAgentAssistantConfig',
    as InstanceOf['Google::Cloud::Dialogflow::V2::ConversationProfile::HumanAgentAssistantConfig'];

coerce 'HumanAgentAssistantConfig',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::ConversationProfile::HumanAgentAssistantConfig'->new($_) };

declare 'RepeatedHumanAgentAssistantConfig',
    as ArrayRef[HumanAgentAssistantConfig()];

coerce 'RepeatedHumanAgentAssistantConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::ConversationProfile::HumanAgentAssistantConfig'->new($_) } @$_ ] };

declare 'MapStringHumanAgentAssistantConfig',
    as HashRef[HumanAgentAssistantConfig()];

declare 'SuggestionTriggerSettings',
    as InstanceOf['Google::Cloud::Dialogflow::V2::ConversationProfile::HumanAgentAssistantConfig::SuggestionTriggerSettings'];

coerce 'SuggestionTriggerSettings',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::ConversationProfile::HumanAgentAssistantConfig::SuggestionTriggerSettings'->new($_) };

declare 'RepeatedSuggestionTriggerSettings',
    as ArrayRef[SuggestionTriggerSettings()];

coerce 'RepeatedSuggestionTriggerSettings',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::ConversationProfile::HumanAgentAssistantConfig::SuggestionTriggerSettings'->new($_) } @$_ ] };

declare 'MapStringSuggestionTriggerSettings',
    as HashRef[SuggestionTriggerSettings()];

declare 'SuggestionFeatureConfig',
    as InstanceOf['Google::Cloud::Dialogflow::V2::ConversationProfile::HumanAgentAssistantConfig::SuggestionFeatureConfig'];

coerce 'SuggestionFeatureConfig',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::ConversationProfile::HumanAgentAssistantConfig::SuggestionFeatureConfig'->new($_) };

declare 'RepeatedSuggestionFeatureConfig',
    as ArrayRef[SuggestionFeatureConfig()];

coerce 'RepeatedSuggestionFeatureConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::ConversationProfile::HumanAgentAssistantConfig::SuggestionFeatureConfig'->new($_) } @$_ ] };

declare 'MapStringSuggestionFeatureConfig',
    as HashRef[SuggestionFeatureConfig()];

declare 'SuggestionConfig',
    as InstanceOf['Google::Cloud::Dialogflow::V2::ConversationProfile::HumanAgentAssistantConfig::SuggestionConfig'];

coerce 'SuggestionConfig',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::ConversationProfile::HumanAgentAssistantConfig::SuggestionConfig'->new($_) };

declare 'RepeatedSuggestionConfig',
    as ArrayRef[SuggestionConfig()];

coerce 'RepeatedSuggestionConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::ConversationProfile::HumanAgentAssistantConfig::SuggestionConfig'->new($_) } @$_ ] };

declare 'MapStringSuggestionConfig',
    as HashRef[SuggestionConfig()];

declare 'SuggestionQueryConfig',
    as InstanceOf['Google::Cloud::Dialogflow::V2::ConversationProfile::HumanAgentAssistantConfig::SuggestionQueryConfig'];

coerce 'SuggestionQueryConfig',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::ConversationProfile::HumanAgentAssistantConfig::SuggestionQueryConfig'->new($_) };

declare 'RepeatedSuggestionQueryConfig',
    as ArrayRef[SuggestionQueryConfig()];

coerce 'RepeatedSuggestionQueryConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::ConversationProfile::HumanAgentAssistantConfig::SuggestionQueryConfig'->new($_) } @$_ ] };

declare 'MapStringSuggestionQueryConfig',
    as HashRef[SuggestionQueryConfig()];

declare 'KnowledgeBaseQuerySource',
    as InstanceOf['Google::Cloud::Dialogflow::V2::ConversationProfile::HumanAgentAssistantConfig::SuggestionQueryConfig::KnowledgeBaseQuerySource'];

coerce 'KnowledgeBaseQuerySource',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::ConversationProfile::HumanAgentAssistantConfig::SuggestionQueryConfig::KnowledgeBaseQuerySource'->new($_) };

declare 'RepeatedKnowledgeBaseQuerySource',
    as ArrayRef[KnowledgeBaseQuerySource()];

coerce 'RepeatedKnowledgeBaseQuerySource',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::ConversationProfile::HumanAgentAssistantConfig::SuggestionQueryConfig::KnowledgeBaseQuerySource'->new($_) } @$_ ] };

declare 'MapStringKnowledgeBaseQuerySource',
    as HashRef[KnowledgeBaseQuerySource()];

declare 'DocumentQuerySource',
    as InstanceOf['Google::Cloud::Dialogflow::V2::ConversationProfile::HumanAgentAssistantConfig::SuggestionQueryConfig::DocumentQuerySource'];

coerce 'DocumentQuerySource',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::ConversationProfile::HumanAgentAssistantConfig::SuggestionQueryConfig::DocumentQuerySource'->new($_) };

declare 'RepeatedDocumentQuerySource',
    as ArrayRef[DocumentQuerySource()];

coerce 'RepeatedDocumentQuerySource',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::ConversationProfile::HumanAgentAssistantConfig::SuggestionQueryConfig::DocumentQuerySource'->new($_) } @$_ ] };

declare 'MapStringDocumentQuerySource',
    as HashRef[DocumentQuerySource()];

declare 'DialogflowQuerySource',
    as InstanceOf['Google::Cloud::Dialogflow::V2::ConversationProfile::HumanAgentAssistantConfig::SuggestionQueryConfig::DialogflowQuerySource'];

coerce 'DialogflowQuerySource',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::ConversationProfile::HumanAgentAssistantConfig::SuggestionQueryConfig::DialogflowQuerySource'->new($_) };

declare 'RepeatedDialogflowQuerySource',
    as ArrayRef[DialogflowQuerySource()];

coerce 'RepeatedDialogflowQuerySource',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::ConversationProfile::HumanAgentAssistantConfig::SuggestionQueryConfig::DialogflowQuerySource'->new($_) } @$_ ] };

declare 'MapStringDialogflowQuerySource',
    as HashRef[DialogflowQuerySource()];

declare 'HumanAgentSideConfig',
    as InstanceOf['Google::Cloud::Dialogflow::V2::ConversationProfile::HumanAgentAssistantConfig::SuggestionQueryConfig::DialogflowQuerySource::HumanAgentSideConfig'];

coerce 'HumanAgentSideConfig',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::ConversationProfile::HumanAgentAssistantConfig::SuggestionQueryConfig::DialogflowQuerySource::HumanAgentSideConfig'->new($_) };

declare 'RepeatedHumanAgentSideConfig',
    as ArrayRef[HumanAgentSideConfig()];

coerce 'RepeatedHumanAgentSideConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::ConversationProfile::HumanAgentAssistantConfig::SuggestionQueryConfig::DialogflowQuerySource::HumanAgentSideConfig'->new($_) } @$_ ] };

declare 'MapStringHumanAgentSideConfig',
    as HashRef[HumanAgentSideConfig()];

declare 'ContextFilterSettings',
    as InstanceOf['Google::Cloud::Dialogflow::V2::ConversationProfile::HumanAgentAssistantConfig::SuggestionQueryConfig::ContextFilterSettings'];

coerce 'ContextFilterSettings',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::ConversationProfile::HumanAgentAssistantConfig::SuggestionQueryConfig::ContextFilterSettings'->new($_) };

declare 'RepeatedContextFilterSettings',
    as ArrayRef[ContextFilterSettings()];

coerce 'RepeatedContextFilterSettings',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::ConversationProfile::HumanAgentAssistantConfig::SuggestionQueryConfig::ContextFilterSettings'->new($_) } @$_ ] };

declare 'MapStringContextFilterSettings',
    as HashRef[ContextFilterSettings()];

declare 'Sections',
    as InstanceOf['Google::Cloud::Dialogflow::V2::ConversationProfile::HumanAgentAssistantConfig::SuggestionQueryConfig::Sections'];

coerce 'Sections',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::ConversationProfile::HumanAgentAssistantConfig::SuggestionQueryConfig::Sections'->new($_) };

declare 'RepeatedSections',
    as ArrayRef[Sections()];

coerce 'RepeatedSections',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::ConversationProfile::HumanAgentAssistantConfig::SuggestionQueryConfig::Sections'->new($_) } @$_ ] };

declare 'MapStringSections',
    as HashRef[Sections()];

declare 'SectionType',
    as (Int | Str);

declare 'ConversationModelConfig',
    as InstanceOf['Google::Cloud::Dialogflow::V2::ConversationProfile::HumanAgentAssistantConfig::ConversationModelConfig'];

coerce 'ConversationModelConfig',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::ConversationProfile::HumanAgentAssistantConfig::ConversationModelConfig'->new($_) };

declare 'RepeatedConversationModelConfig',
    as ArrayRef[ConversationModelConfig()];

coerce 'RepeatedConversationModelConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::ConversationProfile::HumanAgentAssistantConfig::ConversationModelConfig'->new($_) } @$_ ] };

declare 'MapStringConversationModelConfig',
    as HashRef[ConversationModelConfig()];

declare 'ConversationProcessConfig',
    as InstanceOf['Google::Cloud::Dialogflow::V2::ConversationProfile::HumanAgentAssistantConfig::ConversationProcessConfig'];

coerce 'ConversationProcessConfig',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::ConversationProfile::HumanAgentAssistantConfig::ConversationProcessConfig'->new($_) };

declare 'RepeatedConversationProcessConfig',
    as ArrayRef[ConversationProcessConfig()];

coerce 'RepeatedConversationProcessConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::ConversationProfile::HumanAgentAssistantConfig::ConversationProcessConfig'->new($_) } @$_ ] };

declare 'MapStringConversationProcessConfig',
    as HashRef[ConversationProcessConfig()];

declare 'MessageAnalysisConfig',
    as InstanceOf['Google::Cloud::Dialogflow::V2::ConversationProfile::HumanAgentAssistantConfig::MessageAnalysisConfig'];

coerce 'MessageAnalysisConfig',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::ConversationProfile::HumanAgentAssistantConfig::MessageAnalysisConfig'->new($_) };

declare 'RepeatedMessageAnalysisConfig',
    as ArrayRef[MessageAnalysisConfig()];

coerce 'RepeatedMessageAnalysisConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::ConversationProfile::HumanAgentAssistantConfig::MessageAnalysisConfig'->new($_) } @$_ ] };

declare 'MapStringMessageAnalysisConfig',
    as HashRef[MessageAnalysisConfig()];

declare 'HumanAgentHandoffConfig',
    as InstanceOf['Google::Cloud::Dialogflow::V2::ConversationProfile::HumanAgentHandoffConfig'];

coerce 'HumanAgentHandoffConfig',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::ConversationProfile::HumanAgentHandoffConfig'->new($_) };

declare 'RepeatedHumanAgentHandoffConfig',
    as ArrayRef[HumanAgentHandoffConfig()];

coerce 'RepeatedHumanAgentHandoffConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::ConversationProfile::HumanAgentHandoffConfig'->new($_) } @$_ ] };

declare 'MapStringHumanAgentHandoffConfig',
    as HashRef[HumanAgentHandoffConfig()];

declare 'LivePersonConfig',
    as InstanceOf['Google::Cloud::Dialogflow::V2::ConversationProfile::HumanAgentHandoffConfig::LivePersonConfig'];

coerce 'LivePersonConfig',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::ConversationProfile::HumanAgentHandoffConfig::LivePersonConfig'->new($_) };

declare 'RepeatedLivePersonConfig',
    as ArrayRef[LivePersonConfig()];

coerce 'RepeatedLivePersonConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::ConversationProfile::HumanAgentHandoffConfig::LivePersonConfig'->new($_) } @$_ ] };

declare 'MapStringLivePersonConfig',
    as HashRef[LivePersonConfig()];

declare 'SalesforceLiveAgentConfig',
    as InstanceOf['Google::Cloud::Dialogflow::V2::ConversationProfile::HumanAgentHandoffConfig::SalesforceLiveAgentConfig'];

coerce 'SalesforceLiveAgentConfig',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::ConversationProfile::HumanAgentHandoffConfig::SalesforceLiveAgentConfig'->new($_) };

declare 'RepeatedSalesforceLiveAgentConfig',
    as ArrayRef[SalesforceLiveAgentConfig()];

coerce 'RepeatedSalesforceLiveAgentConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::ConversationProfile::HumanAgentHandoffConfig::SalesforceLiveAgentConfig'->new($_) } @$_ ] };

declare 'MapStringSalesforceLiveAgentConfig',
    as HashRef[SalesforceLiveAgentConfig()];

declare 'NotificationConfig',
    as InstanceOf['Google::Cloud::Dialogflow::V2::ConversationProfile::NotificationConfig'];

coerce 'NotificationConfig',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::ConversationProfile::NotificationConfig'->new($_) };

declare 'RepeatedNotificationConfig',
    as ArrayRef[NotificationConfig()];

coerce 'RepeatedNotificationConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::ConversationProfile::NotificationConfig'->new($_) } @$_ ] };

declare 'MapStringNotificationConfig',
    as HashRef[NotificationConfig()];

declare 'MessageFormat',
    as (Int | Str);

declare 'LoggingConfig',
    as InstanceOf['Google::Cloud::Dialogflow::V2::ConversationProfile::LoggingConfig'];

coerce 'LoggingConfig',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::ConversationProfile::LoggingConfig'->new($_) };

declare 'RepeatedLoggingConfig',
    as ArrayRef[LoggingConfig()];

coerce 'RepeatedLoggingConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::ConversationProfile::LoggingConfig'->new($_) } @$_ ] };

declare 'MapStringLoggingConfig',
    as HashRef[LoggingConfig()];

declare 'SipConfig',
    as InstanceOf['Google::Cloud::Dialogflow::V2::ConversationProfile::SipConfig'];

coerce 'SipConfig',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::ConversationProfile::SipConfig'->new($_) };

declare 'RepeatedSipConfig',
    as ArrayRef[SipConfig()];

coerce 'RepeatedSipConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::ConversationProfile::SipConfig'->new($_) } @$_ ] };

declare 'MapStringSipConfig',
    as HashRef[SipConfig()];

declare 'SuggestionFeature',
    as InstanceOf['Google::Cloud::Dialogflow::V2::ConversationProfile::SuggestionFeature'];

coerce 'SuggestionFeature',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::ConversationProfile::SuggestionFeature'->new($_) };

declare 'RepeatedSuggestionFeature',
    as ArrayRef[SuggestionFeature()];

coerce 'RepeatedSuggestionFeature',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::ConversationProfile::SuggestionFeature'->new($_) } @$_ ] };

declare 'MapStringSuggestionFeature',
    as HashRef[SuggestionFeature()];

declare 'Type',
    as (Int | Str);

declare 'SetSuggestionFeatureConfigRequest',
    as InstanceOf['Google::Cloud::Dialogflow::V2::ConversationProfile::SetSuggestionFeatureConfigRequest'];

coerce 'SetSuggestionFeatureConfigRequest',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::ConversationProfile::SetSuggestionFeatureConfigRequest'->new($_) };

declare 'RepeatedSetSuggestionFeatureConfigRequest',
    as ArrayRef[SetSuggestionFeatureConfigRequest()];

coerce 'RepeatedSetSuggestionFeatureConfigRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::ConversationProfile::SetSuggestionFeatureConfigRequest'->new($_) } @$_ ] };

declare 'MapStringSetSuggestionFeatureConfigRequest',
    as HashRef[SetSuggestionFeatureConfigRequest()];

declare 'ClearSuggestionFeatureConfigRequest',
    as InstanceOf['Google::Cloud::Dialogflow::V2::ConversationProfile::ClearSuggestionFeatureConfigRequest'];

coerce 'ClearSuggestionFeatureConfigRequest',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::ConversationProfile::ClearSuggestionFeatureConfigRequest'->new($_) };

declare 'RepeatedClearSuggestionFeatureConfigRequest',
    as ArrayRef[ClearSuggestionFeatureConfigRequest()];

coerce 'RepeatedClearSuggestionFeatureConfigRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::ConversationProfile::ClearSuggestionFeatureConfigRequest'->new($_) } @$_ ] };

declare 'MapStringClearSuggestionFeatureConfigRequest',
    as HashRef[ClearSuggestionFeatureConfigRequest()];

declare 'SetSuggestionFeatureConfigOperationMetadata',
    as InstanceOf['Google::Cloud::Dialogflow::V2::ConversationProfile::SetSuggestionFeatureConfigOperationMetadata'];

coerce 'SetSuggestionFeatureConfigOperationMetadata',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::ConversationProfile::SetSuggestionFeatureConfigOperationMetadata'->new($_) };

declare 'RepeatedSetSuggestionFeatureConfigOperationMetadata',
    as ArrayRef[SetSuggestionFeatureConfigOperationMetadata()];

coerce 'RepeatedSetSuggestionFeatureConfigOperationMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::ConversationProfile::SetSuggestionFeatureConfigOperationMetadata'->new($_) } @$_ ] };

declare 'MapStringSetSuggestionFeatureConfigOperationMetadata',
    as HashRef[SetSuggestionFeatureConfigOperationMetadata()];

declare 'ClearSuggestionFeatureConfigOperationMetadata',
    as InstanceOf['Google::Cloud::Dialogflow::V2::ConversationProfile::ClearSuggestionFeatureConfigOperationMetadata'];

coerce 'ClearSuggestionFeatureConfigOperationMetadata',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::ConversationProfile::ClearSuggestionFeatureConfigOperationMetadata'->new($_) };

declare 'RepeatedClearSuggestionFeatureConfigOperationMetadata',
    as ArrayRef[ClearSuggestionFeatureConfigOperationMetadata()];

coerce 'RepeatedClearSuggestionFeatureConfigOperationMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::ConversationProfile::ClearSuggestionFeatureConfigOperationMetadata'->new($_) } @$_ ] };

declare 'MapStringClearSuggestionFeatureConfigOperationMetadata',
    as HashRef[ClearSuggestionFeatureConfigOperationMetadata()];

1;

__END__

=head1 NAME

Google::Cloud::Dialogflow::V2::ConversationProfile::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
