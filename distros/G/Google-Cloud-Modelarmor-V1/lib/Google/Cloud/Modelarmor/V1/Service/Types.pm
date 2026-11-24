package Google::Cloud::Modelarmor::V1::Service::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'FilterMatchState',
    as (Int | Str);

declare 'FilterExecutionState',
    as (Int | Str);

declare 'RaiFilterType',
    as (Int | Str);

declare 'DetectionConfidenceLevel',
    as (Int | Str);

declare 'SdpFindingLikelihood',
    as (Int | Str);

declare 'InvocationResult',
    as (Int | Str);

declare 'StreamingMode',
    as (Int | Str);

declare 'Modality',
    as (Int | Str);

declare 'FilterVersionAlias',
    as (Int | Str);

declare 'MatchingScope',
    as (Int | Str);

declare 'RuleFilterType',
    as (Int | Str);

declare 'FilterVersionSelector',
    as InstanceOf['Google::Cloud::Modelarmor::V1::Service::FilterVersionSelector'];

coerce 'FilterVersionSelector',
    from HashRef, via { 'Google::Cloud::Modelarmor::V1::Service::FilterVersionSelector'->new($_) };

declare 'RepeatedFilterVersionSelector',
    as ArrayRef[FilterVersionSelector()];

coerce 'RepeatedFilterVersionSelector',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Modelarmor::V1::Service::FilterVersionSelector'->new($_) } @$_ ] };

declare 'MapStringFilterVersionSelector',
    as HashRef[FilterVersionSelector()];

declare 'Template',
    as InstanceOf['Google::Cloud::Modelarmor::V1::Service::Template'];

coerce 'Template',
    from HashRef, via { 'Google::Cloud::Modelarmor::V1::Service::Template'->new($_) };

declare 'RepeatedTemplate',
    as ArrayRef[Template()];

coerce 'RepeatedTemplate',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Modelarmor::V1::Service::Template'->new($_) } @$_ ] };

declare 'MapStringTemplate',
    as HashRef[Template()];

declare 'TemplateMetadata',
    as InstanceOf['Google::Cloud::Modelarmor::V1::Service::Template::TemplateMetadata'];

coerce 'TemplateMetadata',
    from HashRef, via { 'Google::Cloud::Modelarmor::V1::Service::Template::TemplateMetadata'->new($_) };

declare 'RepeatedTemplateMetadata',
    as ArrayRef[TemplateMetadata()];

coerce 'RepeatedTemplateMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Modelarmor::V1::Service::Template::TemplateMetadata'->new($_) } @$_ ] };

declare 'MapStringTemplateMetadata',
    as HashRef[TemplateMetadata()];

declare 'EnforcementType',
    as (Int | Str);

declare 'MultiLanguageDetection',
    as InstanceOf['Google::Cloud::Modelarmor::V1::Service::Template::TemplateMetadata::MultiLanguageDetection'];

coerce 'MultiLanguageDetection',
    from HashRef, via { 'Google::Cloud::Modelarmor::V1::Service::Template::TemplateMetadata::MultiLanguageDetection'->new($_) };

declare 'RepeatedMultiLanguageDetection',
    as ArrayRef[MultiLanguageDetection()];

coerce 'RepeatedMultiLanguageDetection',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Modelarmor::V1::Service::Template::TemplateMetadata::MultiLanguageDetection'->new($_) } @$_ ] };

declare 'MapStringMultiLanguageDetection',
    as HashRef[MultiLanguageDetection()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Modelarmor::V1::Service::Template::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Modelarmor::V1::Service::Template::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Modelarmor::V1::Service::Template::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'FloorSetting',
    as InstanceOf['Google::Cloud::Modelarmor::V1::Service::FloorSetting'];

coerce 'FloorSetting',
    from HashRef, via { 'Google::Cloud::Modelarmor::V1::Service::FloorSetting'->new($_) };

declare 'RepeatedFloorSetting',
    as ArrayRef[FloorSetting()];

coerce 'RepeatedFloorSetting',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Modelarmor::V1::Service::FloorSetting'->new($_) } @$_ ] };

declare 'MapStringFloorSetting',
    as HashRef[FloorSetting()];

declare 'IntegratedService',
    as (Int | Str);

declare 'FloorSettingMetadata',
    as InstanceOf['Google::Cloud::Modelarmor::V1::Service::FloorSetting::FloorSettingMetadata'];

coerce 'FloorSettingMetadata',
    from HashRef, via { 'Google::Cloud::Modelarmor::V1::Service::FloorSetting::FloorSettingMetadata'->new($_) };

declare 'RepeatedFloorSettingMetadata',
    as ArrayRef[FloorSettingMetadata()];

coerce 'RepeatedFloorSettingMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Modelarmor::V1::Service::FloorSetting::FloorSettingMetadata'->new($_) } @$_ ] };

declare 'MapStringFloorSettingMetadata',
    as HashRef[FloorSettingMetadata()];

declare 'MultiLanguageDetection',
    as InstanceOf['Google::Cloud::Modelarmor::V1::Service::FloorSetting::FloorSettingMetadata::MultiLanguageDetection'];

coerce 'MultiLanguageDetection',
    from HashRef, via { 'Google::Cloud::Modelarmor::V1::Service::FloorSetting::FloorSettingMetadata::MultiLanguageDetection'->new($_) };

declare 'RepeatedMultiLanguageDetection',
    as ArrayRef[MultiLanguageDetection()];

coerce 'RepeatedMultiLanguageDetection',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Modelarmor::V1::Service::FloorSetting::FloorSettingMetadata::MultiLanguageDetection'->new($_) } @$_ ] };

declare 'MapStringMultiLanguageDetection',
    as HashRef[MultiLanguageDetection()];

declare 'McpServerFloorSetting',
    as InstanceOf['Google::Cloud::Modelarmor::V1::Service::McpServerFloorSetting'];

coerce 'McpServerFloorSetting',
    from HashRef, via { 'Google::Cloud::Modelarmor::V1::Service::McpServerFloorSetting'->new($_) };

declare 'RepeatedMcpServerFloorSetting',
    as ArrayRef[McpServerFloorSetting()];

coerce 'RepeatedMcpServerFloorSetting',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Modelarmor::V1::Service::McpServerFloorSetting'->new($_) } @$_ ] };

declare 'MapStringMcpServerFloorSetting',
    as HashRef[McpServerFloorSetting()];

declare 'AiPlatformFloorSetting',
    as InstanceOf['Google::Cloud::Modelarmor::V1::Service::AiPlatformFloorSetting'];

coerce 'AiPlatformFloorSetting',
    from HashRef, via { 'Google::Cloud::Modelarmor::V1::Service::AiPlatformFloorSetting'->new($_) };

declare 'RepeatedAiPlatformFloorSetting',
    as ArrayRef[AiPlatformFloorSetting()];

coerce 'RepeatedAiPlatformFloorSetting',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Modelarmor::V1::Service::AiPlatformFloorSetting'->new($_) } @$_ ] };

declare 'MapStringAiPlatformFloorSetting',
    as HashRef[AiPlatformFloorSetting()];

declare 'ListTemplatesRequest',
    as InstanceOf['Google::Cloud::Modelarmor::V1::Service::ListTemplatesRequest'];

coerce 'ListTemplatesRequest',
    from HashRef, via { 'Google::Cloud::Modelarmor::V1::Service::ListTemplatesRequest'->new($_) };

declare 'RepeatedListTemplatesRequest',
    as ArrayRef[ListTemplatesRequest()];

coerce 'RepeatedListTemplatesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Modelarmor::V1::Service::ListTemplatesRequest'->new($_) } @$_ ] };

declare 'MapStringListTemplatesRequest',
    as HashRef[ListTemplatesRequest()];

declare 'ListTemplatesResponse',
    as InstanceOf['Google::Cloud::Modelarmor::V1::Service::ListTemplatesResponse'];

coerce 'ListTemplatesResponse',
    from HashRef, via { 'Google::Cloud::Modelarmor::V1::Service::ListTemplatesResponse'->new($_) };

declare 'RepeatedListTemplatesResponse',
    as ArrayRef[ListTemplatesResponse()];

coerce 'RepeatedListTemplatesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Modelarmor::V1::Service::ListTemplatesResponse'->new($_) } @$_ ] };

declare 'MapStringListTemplatesResponse',
    as HashRef[ListTemplatesResponse()];

declare 'GetTemplateRequest',
    as InstanceOf['Google::Cloud::Modelarmor::V1::Service::GetTemplateRequest'];

coerce 'GetTemplateRequest',
    from HashRef, via { 'Google::Cloud::Modelarmor::V1::Service::GetTemplateRequest'->new($_) };

declare 'RepeatedGetTemplateRequest',
    as ArrayRef[GetTemplateRequest()];

coerce 'RepeatedGetTemplateRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Modelarmor::V1::Service::GetTemplateRequest'->new($_) } @$_ ] };

declare 'MapStringGetTemplateRequest',
    as HashRef[GetTemplateRequest()];

declare 'CreateTemplateRequest',
    as InstanceOf['Google::Cloud::Modelarmor::V1::Service::CreateTemplateRequest'];

coerce 'CreateTemplateRequest',
    from HashRef, via { 'Google::Cloud::Modelarmor::V1::Service::CreateTemplateRequest'->new($_) };

declare 'RepeatedCreateTemplateRequest',
    as ArrayRef[CreateTemplateRequest()];

coerce 'RepeatedCreateTemplateRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Modelarmor::V1::Service::CreateTemplateRequest'->new($_) } @$_ ] };

declare 'MapStringCreateTemplateRequest',
    as HashRef[CreateTemplateRequest()];

declare 'UpdateTemplateRequest',
    as InstanceOf['Google::Cloud::Modelarmor::V1::Service::UpdateTemplateRequest'];

coerce 'UpdateTemplateRequest',
    from HashRef, via { 'Google::Cloud::Modelarmor::V1::Service::UpdateTemplateRequest'->new($_) };

declare 'RepeatedUpdateTemplateRequest',
    as ArrayRef[UpdateTemplateRequest()];

coerce 'RepeatedUpdateTemplateRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Modelarmor::V1::Service::UpdateTemplateRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateTemplateRequest',
    as HashRef[UpdateTemplateRequest()];

declare 'DeleteTemplateRequest',
    as InstanceOf['Google::Cloud::Modelarmor::V1::Service::DeleteTemplateRequest'];

coerce 'DeleteTemplateRequest',
    from HashRef, via { 'Google::Cloud::Modelarmor::V1::Service::DeleteTemplateRequest'->new($_) };

declare 'RepeatedDeleteTemplateRequest',
    as ArrayRef[DeleteTemplateRequest()];

coerce 'RepeatedDeleteTemplateRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Modelarmor::V1::Service::DeleteTemplateRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteTemplateRequest',
    as HashRef[DeleteTemplateRequest()];

declare 'GetFloorSettingRequest',
    as InstanceOf['Google::Cloud::Modelarmor::V1::Service::GetFloorSettingRequest'];

coerce 'GetFloorSettingRequest',
    from HashRef, via { 'Google::Cloud::Modelarmor::V1::Service::GetFloorSettingRequest'->new($_) };

declare 'RepeatedGetFloorSettingRequest',
    as ArrayRef[GetFloorSettingRequest()];

coerce 'RepeatedGetFloorSettingRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Modelarmor::V1::Service::GetFloorSettingRequest'->new($_) } @$_ ] };

declare 'MapStringGetFloorSettingRequest',
    as HashRef[GetFloorSettingRequest()];

declare 'UpdateFloorSettingRequest',
    as InstanceOf['Google::Cloud::Modelarmor::V1::Service::UpdateFloorSettingRequest'];

coerce 'UpdateFloorSettingRequest',
    from HashRef, via { 'Google::Cloud::Modelarmor::V1::Service::UpdateFloorSettingRequest'->new($_) };

declare 'RepeatedUpdateFloorSettingRequest',
    as ArrayRef[UpdateFloorSettingRequest()];

coerce 'RepeatedUpdateFloorSettingRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Modelarmor::V1::Service::UpdateFloorSettingRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateFloorSettingRequest',
    as HashRef[UpdateFloorSettingRequest()];

declare 'FilterConfig',
    as InstanceOf['Google::Cloud::Modelarmor::V1::Service::FilterConfig'];

coerce 'FilterConfig',
    from HashRef, via { 'Google::Cloud::Modelarmor::V1::Service::FilterConfig'->new($_) };

declare 'RepeatedFilterConfig',
    as ArrayRef[FilterConfig()];

coerce 'RepeatedFilterConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Modelarmor::V1::Service::FilterConfig'->new($_) } @$_ ] };

declare 'MapStringFilterConfig',
    as HashRef[FilterConfig()];

declare 'CsamFilterSettings',
    as InstanceOf['Google::Cloud::Modelarmor::V1::Service::CsamFilterSettings'];

coerce 'CsamFilterSettings',
    from HashRef, via { 'Google::Cloud::Modelarmor::V1::Service::CsamFilterSettings'->new($_) };

declare 'RepeatedCsamFilterSettings',
    as ArrayRef[CsamFilterSettings()];

coerce 'RepeatedCsamFilterSettings',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Modelarmor::V1::Service::CsamFilterSettings'->new($_) } @$_ ] };

declare 'MapStringCsamFilterSettings',
    as HashRef[CsamFilterSettings()];

declare 'CsamFilterEnforcement',
    as (Int | Str);

declare 'PiAndJailbreakFilterSettings',
    as InstanceOf['Google::Cloud::Modelarmor::V1::Service::PiAndJailbreakFilterSettings'];

coerce 'PiAndJailbreakFilterSettings',
    from HashRef, via { 'Google::Cloud::Modelarmor::V1::Service::PiAndJailbreakFilterSettings'->new($_) };

declare 'RepeatedPiAndJailbreakFilterSettings',
    as ArrayRef[PiAndJailbreakFilterSettings()];

coerce 'RepeatedPiAndJailbreakFilterSettings',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Modelarmor::V1::Service::PiAndJailbreakFilterSettings'->new($_) } @$_ ] };

declare 'MapStringPiAndJailbreakFilterSettings',
    as HashRef[PiAndJailbreakFilterSettings()];

declare 'PiAndJailbreakFilterEnforcement',
    as (Int | Str);

declare 'MaliciousUriFilterSettings',
    as InstanceOf['Google::Cloud::Modelarmor::V1::Service::MaliciousUriFilterSettings'];

coerce 'MaliciousUriFilterSettings',
    from HashRef, via { 'Google::Cloud::Modelarmor::V1::Service::MaliciousUriFilterSettings'->new($_) };

declare 'RepeatedMaliciousUriFilterSettings',
    as ArrayRef[MaliciousUriFilterSettings()];

coerce 'RepeatedMaliciousUriFilterSettings',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Modelarmor::V1::Service::MaliciousUriFilterSettings'->new($_) } @$_ ] };

declare 'MapStringMaliciousUriFilterSettings',
    as HashRef[MaliciousUriFilterSettings()];

declare 'MaliciousUriFilterEnforcement',
    as (Int | Str);

declare 'RaiFilterSettings',
    as InstanceOf['Google::Cloud::Modelarmor::V1::Service::RaiFilterSettings'];

coerce 'RaiFilterSettings',
    from HashRef, via { 'Google::Cloud::Modelarmor::V1::Service::RaiFilterSettings'->new($_) };

declare 'RepeatedRaiFilterSettings',
    as ArrayRef[RaiFilterSettings()];

coerce 'RepeatedRaiFilterSettings',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Modelarmor::V1::Service::RaiFilterSettings'->new($_) } @$_ ] };

declare 'MapStringRaiFilterSettings',
    as HashRef[RaiFilterSettings()];

declare 'RaiFilter',
    as InstanceOf['Google::Cloud::Modelarmor::V1::Service::RaiFilterSettings::RaiFilter'];

coerce 'RaiFilter',
    from HashRef, via { 'Google::Cloud::Modelarmor::V1::Service::RaiFilterSettings::RaiFilter'->new($_) };

declare 'RepeatedRaiFilter',
    as ArrayRef[RaiFilter()];

coerce 'RepeatedRaiFilter',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Modelarmor::V1::Service::RaiFilterSettings::RaiFilter'->new($_) } @$_ ] };

declare 'MapStringRaiFilter',
    as HashRef[RaiFilter()];

declare 'SdpFilterSettings',
    as InstanceOf['Google::Cloud::Modelarmor::V1::Service::SdpFilterSettings'];

coerce 'SdpFilterSettings',
    from HashRef, via { 'Google::Cloud::Modelarmor::V1::Service::SdpFilterSettings'->new($_) };

declare 'RepeatedSdpFilterSettings',
    as ArrayRef[SdpFilterSettings()];

coerce 'RepeatedSdpFilterSettings',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Modelarmor::V1::Service::SdpFilterSettings'->new($_) } @$_ ] };

declare 'MapStringSdpFilterSettings',
    as HashRef[SdpFilterSettings()];

declare 'SdpBasicConfig',
    as InstanceOf['Google::Cloud::Modelarmor::V1::Service::SdpBasicConfig'];

coerce 'SdpBasicConfig',
    from HashRef, via { 'Google::Cloud::Modelarmor::V1::Service::SdpBasicConfig'->new($_) };

declare 'RepeatedSdpBasicConfig',
    as ArrayRef[SdpBasicConfig()];

coerce 'RepeatedSdpBasicConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Modelarmor::V1::Service::SdpBasicConfig'->new($_) } @$_ ] };

declare 'MapStringSdpBasicConfig',
    as HashRef[SdpBasicConfig()];

declare 'SdpBasicConfigEnforcement',
    as (Int | Str);

declare 'SdpAdvancedConfig',
    as InstanceOf['Google::Cloud::Modelarmor::V1::Service::SdpAdvancedConfig'];

coerce 'SdpAdvancedConfig',
    from HashRef, via { 'Google::Cloud::Modelarmor::V1::Service::SdpAdvancedConfig'->new($_) };

declare 'RepeatedSdpAdvancedConfig',
    as ArrayRef[SdpAdvancedConfig()];

coerce 'RepeatedSdpAdvancedConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Modelarmor::V1::Service::SdpAdvancedConfig'->new($_) } @$_ ] };

declare 'MapStringSdpAdvancedConfig',
    as HashRef[SdpAdvancedConfig()];

declare 'SanitizeUserPromptRequest',
    as InstanceOf['Google::Cloud::Modelarmor::V1::Service::SanitizeUserPromptRequest'];

coerce 'SanitizeUserPromptRequest',
    from HashRef, via { 'Google::Cloud::Modelarmor::V1::Service::SanitizeUserPromptRequest'->new($_) };

declare 'RepeatedSanitizeUserPromptRequest',
    as ArrayRef[SanitizeUserPromptRequest()];

coerce 'RepeatedSanitizeUserPromptRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Modelarmor::V1::Service::SanitizeUserPromptRequest'->new($_) } @$_ ] };

declare 'MapStringSanitizeUserPromptRequest',
    as HashRef[SanitizeUserPromptRequest()];

declare 'SanitizeModelResponseRequest',
    as InstanceOf['Google::Cloud::Modelarmor::V1::Service::SanitizeModelResponseRequest'];

coerce 'SanitizeModelResponseRequest',
    from HashRef, via { 'Google::Cloud::Modelarmor::V1::Service::SanitizeModelResponseRequest'->new($_) };

declare 'RepeatedSanitizeModelResponseRequest',
    as ArrayRef[SanitizeModelResponseRequest()];

coerce 'RepeatedSanitizeModelResponseRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Modelarmor::V1::Service::SanitizeModelResponseRequest'->new($_) } @$_ ] };

declare 'MapStringSanitizeModelResponseRequest',
    as HashRef[SanitizeModelResponseRequest()];

declare 'SanitizeUserPromptResponse',
    as InstanceOf['Google::Cloud::Modelarmor::V1::Service::SanitizeUserPromptResponse'];

coerce 'SanitizeUserPromptResponse',
    from HashRef, via { 'Google::Cloud::Modelarmor::V1::Service::SanitizeUserPromptResponse'->new($_) };

declare 'RepeatedSanitizeUserPromptResponse',
    as ArrayRef[SanitizeUserPromptResponse()];

coerce 'RepeatedSanitizeUserPromptResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Modelarmor::V1::Service::SanitizeUserPromptResponse'->new($_) } @$_ ] };

declare 'MapStringSanitizeUserPromptResponse',
    as HashRef[SanitizeUserPromptResponse()];

declare 'SanitizeModelResponseResponse',
    as InstanceOf['Google::Cloud::Modelarmor::V1::Service::SanitizeModelResponseResponse'];

coerce 'SanitizeModelResponseResponse',
    from HashRef, via { 'Google::Cloud::Modelarmor::V1::Service::SanitizeModelResponseResponse'->new($_) };

declare 'RepeatedSanitizeModelResponseResponse',
    as ArrayRef[SanitizeModelResponseResponse()];

coerce 'RepeatedSanitizeModelResponseResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Modelarmor::V1::Service::SanitizeModelResponseResponse'->new($_) } @$_ ] };

declare 'MapStringSanitizeModelResponseResponse',
    as HashRef[SanitizeModelResponseResponse()];

declare 'FilterVersionConfig',
    as InstanceOf['Google::Cloud::Modelarmor::V1::Service::FilterVersionConfig'];

coerce 'FilterVersionConfig',
    from HashRef, via { 'Google::Cloud::Modelarmor::V1::Service::FilterVersionConfig'->new($_) };

declare 'RepeatedFilterVersionConfig',
    as ArrayRef[FilterVersionConfig()];

coerce 'RepeatedFilterVersionConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Modelarmor::V1::Service::FilterVersionConfig'->new($_) } @$_ ] };

declare 'MapStringFilterVersionConfig',
    as HashRef[FilterVersionConfig()];

declare 'SanitizationResult',
    as InstanceOf['Google::Cloud::Modelarmor::V1::Service::SanitizationResult'];

coerce 'SanitizationResult',
    from HashRef, via { 'Google::Cloud::Modelarmor::V1::Service::SanitizationResult'->new($_) };

declare 'RepeatedSanitizationResult',
    as ArrayRef[SanitizationResult()];

coerce 'RepeatedSanitizationResult',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Modelarmor::V1::Service::SanitizationResult'->new($_) } @$_ ] };

declare 'MapStringSanitizationResult',
    as HashRef[SanitizationResult()];

declare 'SanitizationMetadata',
    as InstanceOf['Google::Cloud::Modelarmor::V1::Service::SanitizationResult::SanitizationMetadata'];

coerce 'SanitizationMetadata',
    from HashRef, via { 'Google::Cloud::Modelarmor::V1::Service::SanitizationResult::SanitizationMetadata'->new($_) };

declare 'RepeatedSanitizationMetadata',
    as ArrayRef[SanitizationMetadata()];

coerce 'RepeatedSanitizationMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Modelarmor::V1::Service::SanitizationResult::SanitizationMetadata'->new($_) } @$_ ] };

declare 'MapStringSanitizationMetadata',
    as HashRef[SanitizationMetadata()];

declare 'FilterResultsEntry',
    as InstanceOf['Google::Cloud::Modelarmor::V1::Service::SanitizationResult::FilterResultsEntry'];

coerce 'FilterResultsEntry',
    from HashRef, via { 'Google::Cloud::Modelarmor::V1::Service::SanitizationResult::FilterResultsEntry'->new($_) };

declare 'RepeatedFilterResultsEntry',
    as ArrayRef[FilterResultsEntry()];

coerce 'RepeatedFilterResultsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Modelarmor::V1::Service::SanitizationResult::FilterResultsEntry'->new($_) } @$_ ] };

declare 'MapStringFilterResultsEntry',
    as HashRef[FilterResultsEntry()];

declare 'MultiLanguageDetectionMetadata',
    as InstanceOf['Google::Cloud::Modelarmor::V1::Service::MultiLanguageDetectionMetadata'];

coerce 'MultiLanguageDetectionMetadata',
    from HashRef, via { 'Google::Cloud::Modelarmor::V1::Service::MultiLanguageDetectionMetadata'->new($_) };

declare 'RepeatedMultiLanguageDetectionMetadata',
    as ArrayRef[MultiLanguageDetectionMetadata()];

coerce 'RepeatedMultiLanguageDetectionMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Modelarmor::V1::Service::MultiLanguageDetectionMetadata'->new($_) } @$_ ] };

declare 'MapStringMultiLanguageDetectionMetadata',
    as HashRef[MultiLanguageDetectionMetadata()];

declare 'FilterResult',
    as InstanceOf['Google::Cloud::Modelarmor::V1::Service::FilterResult'];

coerce 'FilterResult',
    from HashRef, via { 'Google::Cloud::Modelarmor::V1::Service::FilterResult'->new($_) };

declare 'RepeatedFilterResult',
    as ArrayRef[FilterResult()];

coerce 'RepeatedFilterResult',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Modelarmor::V1::Service::FilterResult'->new($_) } @$_ ] };

declare 'MapStringFilterResult',
    as HashRef[FilterResult()];

declare 'RaiFilterResult',
    as InstanceOf['Google::Cloud::Modelarmor::V1::Service::RaiFilterResult'];

coerce 'RaiFilterResult',
    from HashRef, via { 'Google::Cloud::Modelarmor::V1::Service::RaiFilterResult'->new($_) };

declare 'RepeatedRaiFilterResult',
    as ArrayRef[RaiFilterResult()];

coerce 'RepeatedRaiFilterResult',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Modelarmor::V1::Service::RaiFilterResult'->new($_) } @$_ ] };

declare 'MapStringRaiFilterResult',
    as HashRef[RaiFilterResult()];

declare 'RaiFilterTypeResult',
    as InstanceOf['Google::Cloud::Modelarmor::V1::Service::RaiFilterResult::RaiFilterTypeResult'];

coerce 'RaiFilterTypeResult',
    from HashRef, via { 'Google::Cloud::Modelarmor::V1::Service::RaiFilterResult::RaiFilterTypeResult'->new($_) };

declare 'RepeatedRaiFilterTypeResult',
    as ArrayRef[RaiFilterTypeResult()];

coerce 'RepeatedRaiFilterTypeResult',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Modelarmor::V1::Service::RaiFilterResult::RaiFilterTypeResult'->new($_) } @$_ ] };

declare 'MapStringRaiFilterTypeResult',
    as HashRef[RaiFilterTypeResult()];

declare 'RaiFilterTypeResultsEntry',
    as InstanceOf['Google::Cloud::Modelarmor::V1::Service::RaiFilterResult::RaiFilterTypeResultsEntry'];

coerce 'RaiFilterTypeResultsEntry',
    from HashRef, via { 'Google::Cloud::Modelarmor::V1::Service::RaiFilterResult::RaiFilterTypeResultsEntry'->new($_) };

declare 'RepeatedRaiFilterTypeResultsEntry',
    as ArrayRef[RaiFilterTypeResultsEntry()];

coerce 'RepeatedRaiFilterTypeResultsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Modelarmor::V1::Service::RaiFilterResult::RaiFilterTypeResultsEntry'->new($_) } @$_ ] };

declare 'MapStringRaiFilterTypeResultsEntry',
    as HashRef[RaiFilterTypeResultsEntry()];

declare 'SdpFilterResult',
    as InstanceOf['Google::Cloud::Modelarmor::V1::Service::SdpFilterResult'];

coerce 'SdpFilterResult',
    from HashRef, via { 'Google::Cloud::Modelarmor::V1::Service::SdpFilterResult'->new($_) };

declare 'RepeatedSdpFilterResult',
    as ArrayRef[SdpFilterResult()];

coerce 'RepeatedSdpFilterResult',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Modelarmor::V1::Service::SdpFilterResult'->new($_) } @$_ ] };

declare 'MapStringSdpFilterResult',
    as HashRef[SdpFilterResult()];

declare 'SdpInspectResult',
    as InstanceOf['Google::Cloud::Modelarmor::V1::Service::SdpInspectResult'];

coerce 'SdpInspectResult',
    from HashRef, via { 'Google::Cloud::Modelarmor::V1::Service::SdpInspectResult'->new($_) };

declare 'RepeatedSdpInspectResult',
    as ArrayRef[SdpInspectResult()];

coerce 'RepeatedSdpInspectResult',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Modelarmor::V1::Service::SdpInspectResult'->new($_) } @$_ ] };

declare 'MapStringSdpInspectResult',
    as HashRef[SdpInspectResult()];

declare 'DataItem',
    as InstanceOf['Google::Cloud::Modelarmor::V1::Service::DataItem'];

coerce 'DataItem',
    from HashRef, via { 'Google::Cloud::Modelarmor::V1::Service::DataItem'->new($_) };

declare 'RepeatedDataItem',
    as ArrayRef[DataItem()];

coerce 'RepeatedDataItem',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Modelarmor::V1::Service::DataItem'->new($_) } @$_ ] };

declare 'MapStringDataItem',
    as HashRef[DataItem()];

declare 'ByteDataItem',
    as InstanceOf['Google::Cloud::Modelarmor::V1::Service::ByteDataItem'];

coerce 'ByteDataItem',
    from HashRef, via { 'Google::Cloud::Modelarmor::V1::Service::ByteDataItem'->new($_) };

declare 'RepeatedByteDataItem',
    as ArrayRef[ByteDataItem()];

coerce 'RepeatedByteDataItem',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Modelarmor::V1::Service::ByteDataItem'->new($_) } @$_ ] };

declare 'MapStringByteDataItem',
    as HashRef[ByteDataItem()];

declare 'ByteItemType',
    as (Int | Str);

declare 'SdpDeidentifyResult',
    as InstanceOf['Google::Cloud::Modelarmor::V1::Service::SdpDeidentifyResult'];

coerce 'SdpDeidentifyResult',
    from HashRef, via { 'Google::Cloud::Modelarmor::V1::Service::SdpDeidentifyResult'->new($_) };

declare 'RepeatedSdpDeidentifyResult',
    as ArrayRef[SdpDeidentifyResult()];

coerce 'RepeatedSdpDeidentifyResult',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Modelarmor::V1::Service::SdpDeidentifyResult'->new($_) } @$_ ] };

declare 'MapStringSdpDeidentifyResult',
    as HashRef[SdpDeidentifyResult()];

declare 'SdpImageFindingLocation',
    as InstanceOf['Google::Cloud::Modelarmor::V1::Service::SdpImageFindingLocation'];

coerce 'SdpImageFindingLocation',
    from HashRef, via { 'Google::Cloud::Modelarmor::V1::Service::SdpImageFindingLocation'->new($_) };

declare 'RepeatedSdpImageFindingLocation',
    as ArrayRef[SdpImageFindingLocation()];

coerce 'RepeatedSdpImageFindingLocation',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Modelarmor::V1::Service::SdpImageFindingLocation'->new($_) } @$_ ] };

declare 'MapStringSdpImageFindingLocation',
    as HashRef[SdpImageFindingLocation()];

declare 'SdpBoundingBox',
    as InstanceOf['Google::Cloud::Modelarmor::V1::Service::SdpImageFindingLocation::SdpBoundingBox'];

coerce 'SdpBoundingBox',
    from HashRef, via { 'Google::Cloud::Modelarmor::V1::Service::SdpImageFindingLocation::SdpBoundingBox'->new($_) };

declare 'RepeatedSdpBoundingBox',
    as ArrayRef[SdpBoundingBox()];

coerce 'RepeatedSdpBoundingBox',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Modelarmor::V1::Service::SdpImageFindingLocation::SdpBoundingBox'->new($_) } @$_ ] };

declare 'MapStringSdpBoundingBox',
    as HashRef[SdpBoundingBox()];

declare 'SdpContentLocation',
    as InstanceOf['Google::Cloud::Modelarmor::V1::Service::SdpContentLocation'];

coerce 'SdpContentLocation',
    from HashRef, via { 'Google::Cloud::Modelarmor::V1::Service::SdpContentLocation'->new($_) };

declare 'RepeatedSdpContentLocation',
    as ArrayRef[SdpContentLocation()];

coerce 'RepeatedSdpContentLocation',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Modelarmor::V1::Service::SdpContentLocation'->new($_) } @$_ ] };

declare 'MapStringSdpContentLocation',
    as HashRef[SdpContentLocation()];

declare 'SdpFinding',
    as InstanceOf['Google::Cloud::Modelarmor::V1::Service::SdpFinding'];

coerce 'SdpFinding',
    from HashRef, via { 'Google::Cloud::Modelarmor::V1::Service::SdpFinding'->new($_) };

declare 'RepeatedSdpFinding',
    as ArrayRef[SdpFinding()];

coerce 'RepeatedSdpFinding',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Modelarmor::V1::Service::SdpFinding'->new($_) } @$_ ] };

declare 'MapStringSdpFinding',
    as HashRef[SdpFinding()];

declare 'SdpFindingLocation',
    as InstanceOf['Google::Cloud::Modelarmor::V1::Service::SdpFinding::SdpFindingLocation'];

coerce 'SdpFindingLocation',
    from HashRef, via { 'Google::Cloud::Modelarmor::V1::Service::SdpFinding::SdpFindingLocation'->new($_) };

declare 'RepeatedSdpFindingLocation',
    as ArrayRef[SdpFindingLocation()];

coerce 'RepeatedSdpFindingLocation',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Modelarmor::V1::Service::SdpFinding::SdpFindingLocation'->new($_) } @$_ ] };

declare 'MapStringSdpFindingLocation',
    as HashRef[SdpFindingLocation()];

declare 'SdpRedactResult',
    as InstanceOf['Google::Cloud::Modelarmor::V1::Service::SdpRedactResult'];

coerce 'SdpRedactResult',
    from HashRef, via { 'Google::Cloud::Modelarmor::V1::Service::SdpRedactResult'->new($_) };

declare 'RepeatedSdpRedactResult',
    as ArrayRef[SdpRedactResult()];

coerce 'RepeatedSdpRedactResult',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Modelarmor::V1::Service::SdpRedactResult'->new($_) } @$_ ] };

declare 'MapStringSdpRedactResult',
    as HashRef[SdpRedactResult()];

declare 'WordList',
    as InstanceOf['Google::Cloud::Modelarmor::V1::Service::WordList'];

coerce 'WordList',
    from HashRef, via { 'Google::Cloud::Modelarmor::V1::Service::WordList'->new($_) };

declare 'RepeatedWordList',
    as ArrayRef[WordList()];

coerce 'RepeatedWordList',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Modelarmor::V1::Service::WordList'->new($_) } @$_ ] };

declare 'MapStringWordList',
    as HashRef[WordList()];

declare 'Dictionary',
    as InstanceOf['Google::Cloud::Modelarmor::V1::Service::Dictionary'];

coerce 'Dictionary',
    from HashRef, via { 'Google::Cloud::Modelarmor::V1::Service::Dictionary'->new($_) };

declare 'RepeatedDictionary',
    as ArrayRef[Dictionary()];

coerce 'RepeatedDictionary',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Modelarmor::V1::Service::Dictionary'->new($_) } @$_ ] };

declare 'MapStringDictionary',
    as HashRef[Dictionary()];

declare 'Regex',
    as InstanceOf['Google::Cloud::Modelarmor::V1::Service::Regex'];

coerce 'Regex',
    from HashRef, via { 'Google::Cloud::Modelarmor::V1::Service::Regex'->new($_) };

declare 'RepeatedRegex',
    as ArrayRef[Regex()];

coerce 'RepeatedRegex',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Modelarmor::V1::Service::Regex'->new($_) } @$_ ] };

declare 'MapStringRegex',
    as HashRef[Regex()];

declare 'ExclusionRule',
    as InstanceOf['Google::Cloud::Modelarmor::V1::Service::ExclusionRule'];

coerce 'ExclusionRule',
    from HashRef, via { 'Google::Cloud::Modelarmor::V1::Service::ExclusionRule'->new($_) };

declare 'RepeatedExclusionRule',
    as ArrayRef[ExclusionRule()];

coerce 'RepeatedExclusionRule',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Modelarmor::V1::Service::ExclusionRule'->new($_) } @$_ ] };

declare 'MapStringExclusionRule',
    as HashRef[ExclusionRule()];

declare 'FilterRule',
    as InstanceOf['Google::Cloud::Modelarmor::V1::Service::FilterRule'];

coerce 'FilterRule',
    from HashRef, via { 'Google::Cloud::Modelarmor::V1::Service::FilterRule'->new($_) };

declare 'RepeatedFilterRule',
    as ArrayRef[FilterRule()];

coerce 'RepeatedFilterRule',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Modelarmor::V1::Service::FilterRule'->new($_) } @$_ ] };

declare 'MapStringFilterRule',
    as HashRef[FilterRule()];

declare 'FilterRuleSet',
    as InstanceOf['Google::Cloud::Modelarmor::V1::Service::FilterRuleSet'];

coerce 'FilterRuleSet',
    from HashRef, via { 'Google::Cloud::Modelarmor::V1::Service::FilterRuleSet'->new($_) };

declare 'RepeatedFilterRuleSet',
    as ArrayRef[FilterRuleSet()];

coerce 'RepeatedFilterRuleSet',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Modelarmor::V1::Service::FilterRuleSet'->new($_) } @$_ ] };

declare 'MapStringFilterRuleSet',
    as HashRef[FilterRuleSet()];

declare 'FilterRuleSettings',
    as InstanceOf['Google::Cloud::Modelarmor::V1::Service::FilterRuleSettings'];

coerce 'FilterRuleSettings',
    from HashRef, via { 'Google::Cloud::Modelarmor::V1::Service::FilterRuleSettings'->new($_) };

declare 'RepeatedFilterRuleSettings',
    as ArrayRef[FilterRuleSettings()];

coerce 'RepeatedFilterRuleSettings',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Modelarmor::V1::Service::FilterRuleSettings'->new($_) } @$_ ] };

declare 'MapStringFilterRuleSettings',
    as HashRef[FilterRuleSettings()];

declare 'PiAndJailbreakFilterResult',
    as InstanceOf['Google::Cloud::Modelarmor::V1::Service::PiAndJailbreakFilterResult'];

coerce 'PiAndJailbreakFilterResult',
    from HashRef, via { 'Google::Cloud::Modelarmor::V1::Service::PiAndJailbreakFilterResult'->new($_) };

declare 'RepeatedPiAndJailbreakFilterResult',
    as ArrayRef[PiAndJailbreakFilterResult()];

coerce 'RepeatedPiAndJailbreakFilterResult',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Modelarmor::V1::Service::PiAndJailbreakFilterResult'->new($_) } @$_ ] };

declare 'MapStringPiAndJailbreakFilterResult',
    as HashRef[PiAndJailbreakFilterResult()];

declare 'MaliciousUriFilterResult',
    as InstanceOf['Google::Cloud::Modelarmor::V1::Service::MaliciousUriFilterResult'];

coerce 'MaliciousUriFilterResult',
    from HashRef, via { 'Google::Cloud::Modelarmor::V1::Service::MaliciousUriFilterResult'->new($_) };

declare 'RepeatedMaliciousUriFilterResult',
    as ArrayRef[MaliciousUriFilterResult()];

coerce 'RepeatedMaliciousUriFilterResult',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Modelarmor::V1::Service::MaliciousUriFilterResult'->new($_) } @$_ ] };

declare 'MapStringMaliciousUriFilterResult',
    as HashRef[MaliciousUriFilterResult()];

declare 'MaliciousUriMatchedItem',
    as InstanceOf['Google::Cloud::Modelarmor::V1::Service::MaliciousUriFilterResult::MaliciousUriMatchedItem'];

coerce 'MaliciousUriMatchedItem',
    from HashRef, via { 'Google::Cloud::Modelarmor::V1::Service::MaliciousUriFilterResult::MaliciousUriMatchedItem'->new($_) };

declare 'RepeatedMaliciousUriMatchedItem',
    as ArrayRef[MaliciousUriMatchedItem()];

coerce 'RepeatedMaliciousUriMatchedItem',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Modelarmor::V1::Service::MaliciousUriFilterResult::MaliciousUriMatchedItem'->new($_) } @$_ ] };

declare 'MapStringMaliciousUriMatchedItem',
    as HashRef[MaliciousUriMatchedItem()];

declare 'VirusScanFilterResult',
    as InstanceOf['Google::Cloud::Modelarmor::V1::Service::VirusScanFilterResult'];

coerce 'VirusScanFilterResult',
    from HashRef, via { 'Google::Cloud::Modelarmor::V1::Service::VirusScanFilterResult'->new($_) };

declare 'RepeatedVirusScanFilterResult',
    as ArrayRef[VirusScanFilterResult()];

coerce 'RepeatedVirusScanFilterResult',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Modelarmor::V1::Service::VirusScanFilterResult'->new($_) } @$_ ] };

declare 'MapStringVirusScanFilterResult',
    as HashRef[VirusScanFilterResult()];

declare 'ScannedContentType',
    as (Int | Str);

declare 'VirusDetail',
    as InstanceOf['Google::Cloud::Modelarmor::V1::Service::VirusDetail'];

coerce 'VirusDetail',
    from HashRef, via { 'Google::Cloud::Modelarmor::V1::Service::VirusDetail'->new($_) };

declare 'RepeatedVirusDetail',
    as ArrayRef[VirusDetail()];

coerce 'RepeatedVirusDetail',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Modelarmor::V1::Service::VirusDetail'->new($_) } @$_ ] };

declare 'MapStringVirusDetail',
    as HashRef[VirusDetail()];

declare 'ThreatType',
    as (Int | Str);

declare 'CsamFilterResult',
    as InstanceOf['Google::Cloud::Modelarmor::V1::Service::CsamFilterResult'];

coerce 'CsamFilterResult',
    from HashRef, via { 'Google::Cloud::Modelarmor::V1::Service::CsamFilterResult'->new($_) };

declare 'RepeatedCsamFilterResult',
    as ArrayRef[CsamFilterResult()];

coerce 'RepeatedCsamFilterResult',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Modelarmor::V1::Service::CsamFilterResult'->new($_) } @$_ ] };

declare 'MapStringCsamFilterResult',
    as HashRef[CsamFilterResult()];

declare 'MessageItem',
    as InstanceOf['Google::Cloud::Modelarmor::V1::Service::MessageItem'];

coerce 'MessageItem',
    from HashRef, via { 'Google::Cloud::Modelarmor::V1::Service::MessageItem'->new($_) };

declare 'RepeatedMessageItem',
    as ArrayRef[MessageItem()];

coerce 'RepeatedMessageItem',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Modelarmor::V1::Service::MessageItem'->new($_) } @$_ ] };

declare 'MapStringMessageItem',
    as HashRef[MessageItem()];

declare 'MessageType',
    as (Int | Str);

declare 'RangeInfo',
    as InstanceOf['Google::Cloud::Modelarmor::V1::Service::RangeInfo'];

coerce 'RangeInfo',
    from HashRef, via { 'Google::Cloud::Modelarmor::V1::Service::RangeInfo'->new($_) };

declare 'RepeatedRangeInfo',
    as ArrayRef[RangeInfo()];

coerce 'RepeatedRangeInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Modelarmor::V1::Service::RangeInfo'->new($_) } @$_ ] };

declare 'MapStringRangeInfo',
    as HashRef[RangeInfo()];

1;

__END__

=head1 NAME

Google::Cloud::Modelarmor::V1::Service::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
