package Google::Cloud::Securitycentermanagement::V1::SecurityCenterManagement::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'SecurityCenterService',
    as InstanceOf['Google::Cloud::Securitycentermanagement::V1::SecurityCenterManagement::SecurityCenterService'];

coerce 'SecurityCenterService',
    from HashRef, via { 'Google::Cloud::Securitycentermanagement::V1::SecurityCenterManagement::SecurityCenterService'->new($_) };

declare 'RepeatedSecurityCenterService',
    as ArrayRef[SecurityCenterService()];

coerce 'RepeatedSecurityCenterService',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycentermanagement::V1::SecurityCenterManagement::SecurityCenterService'->new($_) } @$_ ] };

declare 'MapStringSecurityCenterService',
    as HashRef[SecurityCenterService()];

declare 'EnablementState',
    as (Int | Str);

declare 'ModuleSettings',
    as InstanceOf['Google::Cloud::Securitycentermanagement::V1::SecurityCenterManagement::SecurityCenterService::ModuleSettings'];

coerce 'ModuleSettings',
    from HashRef, via { 'Google::Cloud::Securitycentermanagement::V1::SecurityCenterManagement::SecurityCenterService::ModuleSettings'->new($_) };

declare 'RepeatedModuleSettings',
    as ArrayRef[ModuleSettings()];

coerce 'RepeatedModuleSettings',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycentermanagement::V1::SecurityCenterManagement::SecurityCenterService::ModuleSettings'->new($_) } @$_ ] };

declare 'MapStringModuleSettings',
    as HashRef[ModuleSettings()];

declare 'ModulesEntry',
    as InstanceOf['Google::Cloud::Securitycentermanagement::V1::SecurityCenterManagement::SecurityCenterService::ModulesEntry'];

coerce 'ModulesEntry',
    from HashRef, via { 'Google::Cloud::Securitycentermanagement::V1::SecurityCenterManagement::SecurityCenterService::ModulesEntry'->new($_) };

declare 'RepeatedModulesEntry',
    as ArrayRef[ModulesEntry()];

coerce 'RepeatedModulesEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycentermanagement::V1::SecurityCenterManagement::SecurityCenterService::ModulesEntry'->new($_) } @$_ ] };

declare 'MapStringModulesEntry',
    as HashRef[ModulesEntry()];

declare 'EffectiveSecurityHealthAnalyticsCustomModule',
    as InstanceOf['Google::Cloud::Securitycentermanagement::V1::SecurityCenterManagement::EffectiveSecurityHealthAnalyticsCustomModule'];

coerce 'EffectiveSecurityHealthAnalyticsCustomModule',
    from HashRef, via { 'Google::Cloud::Securitycentermanagement::V1::SecurityCenterManagement::EffectiveSecurityHealthAnalyticsCustomModule'->new($_) };

declare 'RepeatedEffectiveSecurityHealthAnalyticsCustomModule',
    as ArrayRef[EffectiveSecurityHealthAnalyticsCustomModule()];

coerce 'RepeatedEffectiveSecurityHealthAnalyticsCustomModule',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycentermanagement::V1::SecurityCenterManagement::EffectiveSecurityHealthAnalyticsCustomModule'->new($_) } @$_ ] };

declare 'MapStringEffectiveSecurityHealthAnalyticsCustomModule',
    as HashRef[EffectiveSecurityHealthAnalyticsCustomModule()];

declare 'EnablementState',
    as (Int | Str);

declare 'ListEffectiveSecurityHealthAnalyticsCustomModulesRequest',
    as InstanceOf['Google::Cloud::Securitycentermanagement::V1::SecurityCenterManagement::ListEffectiveSecurityHealthAnalyticsCustomModulesRequest'];

coerce 'ListEffectiveSecurityHealthAnalyticsCustomModulesRequest',
    from HashRef, via { 'Google::Cloud::Securitycentermanagement::V1::SecurityCenterManagement::ListEffectiveSecurityHealthAnalyticsCustomModulesRequest'->new($_) };

declare 'RepeatedListEffectiveSecurityHealthAnalyticsCustomModulesRequest',
    as ArrayRef[ListEffectiveSecurityHealthAnalyticsCustomModulesRequest()];

coerce 'RepeatedListEffectiveSecurityHealthAnalyticsCustomModulesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycentermanagement::V1::SecurityCenterManagement::ListEffectiveSecurityHealthAnalyticsCustomModulesRequest'->new($_) } @$_ ] };

declare 'MapStringListEffectiveSecurityHealthAnalyticsCustomModulesRequest',
    as HashRef[ListEffectiveSecurityHealthAnalyticsCustomModulesRequest()];

declare 'ListEffectiveSecurityHealthAnalyticsCustomModulesResponse',
    as InstanceOf['Google::Cloud::Securitycentermanagement::V1::SecurityCenterManagement::ListEffectiveSecurityHealthAnalyticsCustomModulesResponse'];

coerce 'ListEffectiveSecurityHealthAnalyticsCustomModulesResponse',
    from HashRef, via { 'Google::Cloud::Securitycentermanagement::V1::SecurityCenterManagement::ListEffectiveSecurityHealthAnalyticsCustomModulesResponse'->new($_) };

declare 'RepeatedListEffectiveSecurityHealthAnalyticsCustomModulesResponse',
    as ArrayRef[ListEffectiveSecurityHealthAnalyticsCustomModulesResponse()];

coerce 'RepeatedListEffectiveSecurityHealthAnalyticsCustomModulesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycentermanagement::V1::SecurityCenterManagement::ListEffectiveSecurityHealthAnalyticsCustomModulesResponse'->new($_) } @$_ ] };

declare 'MapStringListEffectiveSecurityHealthAnalyticsCustomModulesResponse',
    as HashRef[ListEffectiveSecurityHealthAnalyticsCustomModulesResponse()];

declare 'GetEffectiveSecurityHealthAnalyticsCustomModuleRequest',
    as InstanceOf['Google::Cloud::Securitycentermanagement::V1::SecurityCenterManagement::GetEffectiveSecurityHealthAnalyticsCustomModuleRequest'];

coerce 'GetEffectiveSecurityHealthAnalyticsCustomModuleRequest',
    from HashRef, via { 'Google::Cloud::Securitycentermanagement::V1::SecurityCenterManagement::GetEffectiveSecurityHealthAnalyticsCustomModuleRequest'->new($_) };

declare 'RepeatedGetEffectiveSecurityHealthAnalyticsCustomModuleRequest',
    as ArrayRef[GetEffectiveSecurityHealthAnalyticsCustomModuleRequest()];

coerce 'RepeatedGetEffectiveSecurityHealthAnalyticsCustomModuleRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycentermanagement::V1::SecurityCenterManagement::GetEffectiveSecurityHealthAnalyticsCustomModuleRequest'->new($_) } @$_ ] };

declare 'MapStringGetEffectiveSecurityHealthAnalyticsCustomModuleRequest',
    as HashRef[GetEffectiveSecurityHealthAnalyticsCustomModuleRequest()];

declare 'SecurityHealthAnalyticsCustomModule',
    as InstanceOf['Google::Cloud::Securitycentermanagement::V1::SecurityCenterManagement::SecurityHealthAnalyticsCustomModule'];

coerce 'SecurityHealthAnalyticsCustomModule',
    from HashRef, via { 'Google::Cloud::Securitycentermanagement::V1::SecurityCenterManagement::SecurityHealthAnalyticsCustomModule'->new($_) };

declare 'RepeatedSecurityHealthAnalyticsCustomModule',
    as ArrayRef[SecurityHealthAnalyticsCustomModule()];

coerce 'RepeatedSecurityHealthAnalyticsCustomModule',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycentermanagement::V1::SecurityCenterManagement::SecurityHealthAnalyticsCustomModule'->new($_) } @$_ ] };

declare 'MapStringSecurityHealthAnalyticsCustomModule',
    as HashRef[SecurityHealthAnalyticsCustomModule()];

declare 'EnablementState',
    as (Int | Str);

declare 'CustomConfig',
    as InstanceOf['Google::Cloud::Securitycentermanagement::V1::SecurityCenterManagement::CustomConfig'];

coerce 'CustomConfig',
    from HashRef, via { 'Google::Cloud::Securitycentermanagement::V1::SecurityCenterManagement::CustomConfig'->new($_) };

declare 'RepeatedCustomConfig',
    as ArrayRef[CustomConfig()];

coerce 'RepeatedCustomConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycentermanagement::V1::SecurityCenterManagement::CustomConfig'->new($_) } @$_ ] };

declare 'MapStringCustomConfig',
    as HashRef[CustomConfig()];

declare 'Severity',
    as (Int | Str);

declare 'CustomOutputSpec',
    as InstanceOf['Google::Cloud::Securitycentermanagement::V1::SecurityCenterManagement::CustomConfig::CustomOutputSpec'];

coerce 'CustomOutputSpec',
    from HashRef, via { 'Google::Cloud::Securitycentermanagement::V1::SecurityCenterManagement::CustomConfig::CustomOutputSpec'->new($_) };

declare 'RepeatedCustomOutputSpec',
    as ArrayRef[CustomOutputSpec()];

coerce 'RepeatedCustomOutputSpec',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycentermanagement::V1::SecurityCenterManagement::CustomConfig::CustomOutputSpec'->new($_) } @$_ ] };

declare 'MapStringCustomOutputSpec',
    as HashRef[CustomOutputSpec()];

declare 'Property',
    as InstanceOf['Google::Cloud::Securitycentermanagement::V1::SecurityCenterManagement::CustomConfig::CustomOutputSpec::Property'];

coerce 'Property',
    from HashRef, via { 'Google::Cloud::Securitycentermanagement::V1::SecurityCenterManagement::CustomConfig::CustomOutputSpec::Property'->new($_) };

declare 'RepeatedProperty',
    as ArrayRef[Property()];

coerce 'RepeatedProperty',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycentermanagement::V1::SecurityCenterManagement::CustomConfig::CustomOutputSpec::Property'->new($_) } @$_ ] };

declare 'MapStringProperty',
    as HashRef[Property()];

declare 'ResourceSelector',
    as InstanceOf['Google::Cloud::Securitycentermanagement::V1::SecurityCenterManagement::CustomConfig::ResourceSelector'];

coerce 'ResourceSelector',
    from HashRef, via { 'Google::Cloud::Securitycentermanagement::V1::SecurityCenterManagement::CustomConfig::ResourceSelector'->new($_) };

declare 'RepeatedResourceSelector',
    as ArrayRef[ResourceSelector()];

coerce 'RepeatedResourceSelector',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycentermanagement::V1::SecurityCenterManagement::CustomConfig::ResourceSelector'->new($_) } @$_ ] };

declare 'MapStringResourceSelector',
    as HashRef[ResourceSelector()];

declare 'ListSecurityHealthAnalyticsCustomModulesRequest',
    as InstanceOf['Google::Cloud::Securitycentermanagement::V1::SecurityCenterManagement::ListSecurityHealthAnalyticsCustomModulesRequest'];

coerce 'ListSecurityHealthAnalyticsCustomModulesRequest',
    from HashRef, via { 'Google::Cloud::Securitycentermanagement::V1::SecurityCenterManagement::ListSecurityHealthAnalyticsCustomModulesRequest'->new($_) };

declare 'RepeatedListSecurityHealthAnalyticsCustomModulesRequest',
    as ArrayRef[ListSecurityHealthAnalyticsCustomModulesRequest()];

coerce 'RepeatedListSecurityHealthAnalyticsCustomModulesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycentermanagement::V1::SecurityCenterManagement::ListSecurityHealthAnalyticsCustomModulesRequest'->new($_) } @$_ ] };

declare 'MapStringListSecurityHealthAnalyticsCustomModulesRequest',
    as HashRef[ListSecurityHealthAnalyticsCustomModulesRequest()];

declare 'ListSecurityHealthAnalyticsCustomModulesResponse',
    as InstanceOf['Google::Cloud::Securitycentermanagement::V1::SecurityCenterManagement::ListSecurityHealthAnalyticsCustomModulesResponse'];

coerce 'ListSecurityHealthAnalyticsCustomModulesResponse',
    from HashRef, via { 'Google::Cloud::Securitycentermanagement::V1::SecurityCenterManagement::ListSecurityHealthAnalyticsCustomModulesResponse'->new($_) };

declare 'RepeatedListSecurityHealthAnalyticsCustomModulesResponse',
    as ArrayRef[ListSecurityHealthAnalyticsCustomModulesResponse()];

coerce 'RepeatedListSecurityHealthAnalyticsCustomModulesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycentermanagement::V1::SecurityCenterManagement::ListSecurityHealthAnalyticsCustomModulesResponse'->new($_) } @$_ ] };

declare 'MapStringListSecurityHealthAnalyticsCustomModulesResponse',
    as HashRef[ListSecurityHealthAnalyticsCustomModulesResponse()];

declare 'ListDescendantSecurityHealthAnalyticsCustomModulesRequest',
    as InstanceOf['Google::Cloud::Securitycentermanagement::V1::SecurityCenterManagement::ListDescendantSecurityHealthAnalyticsCustomModulesRequest'];

coerce 'ListDescendantSecurityHealthAnalyticsCustomModulesRequest',
    from HashRef, via { 'Google::Cloud::Securitycentermanagement::V1::SecurityCenterManagement::ListDescendantSecurityHealthAnalyticsCustomModulesRequest'->new($_) };

declare 'RepeatedListDescendantSecurityHealthAnalyticsCustomModulesRequest',
    as ArrayRef[ListDescendantSecurityHealthAnalyticsCustomModulesRequest()];

coerce 'RepeatedListDescendantSecurityHealthAnalyticsCustomModulesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycentermanagement::V1::SecurityCenterManagement::ListDescendantSecurityHealthAnalyticsCustomModulesRequest'->new($_) } @$_ ] };

declare 'MapStringListDescendantSecurityHealthAnalyticsCustomModulesRequest',
    as HashRef[ListDescendantSecurityHealthAnalyticsCustomModulesRequest()];

declare 'ListDescendantSecurityHealthAnalyticsCustomModulesResponse',
    as InstanceOf['Google::Cloud::Securitycentermanagement::V1::SecurityCenterManagement::ListDescendantSecurityHealthAnalyticsCustomModulesResponse'];

coerce 'ListDescendantSecurityHealthAnalyticsCustomModulesResponse',
    from HashRef, via { 'Google::Cloud::Securitycentermanagement::V1::SecurityCenterManagement::ListDescendantSecurityHealthAnalyticsCustomModulesResponse'->new($_) };

declare 'RepeatedListDescendantSecurityHealthAnalyticsCustomModulesResponse',
    as ArrayRef[ListDescendantSecurityHealthAnalyticsCustomModulesResponse()];

coerce 'RepeatedListDescendantSecurityHealthAnalyticsCustomModulesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycentermanagement::V1::SecurityCenterManagement::ListDescendantSecurityHealthAnalyticsCustomModulesResponse'->new($_) } @$_ ] };

declare 'MapStringListDescendantSecurityHealthAnalyticsCustomModulesResponse',
    as HashRef[ListDescendantSecurityHealthAnalyticsCustomModulesResponse()];

declare 'GetSecurityHealthAnalyticsCustomModuleRequest',
    as InstanceOf['Google::Cloud::Securitycentermanagement::V1::SecurityCenterManagement::GetSecurityHealthAnalyticsCustomModuleRequest'];

coerce 'GetSecurityHealthAnalyticsCustomModuleRequest',
    from HashRef, via { 'Google::Cloud::Securitycentermanagement::V1::SecurityCenterManagement::GetSecurityHealthAnalyticsCustomModuleRequest'->new($_) };

declare 'RepeatedGetSecurityHealthAnalyticsCustomModuleRequest',
    as ArrayRef[GetSecurityHealthAnalyticsCustomModuleRequest()];

coerce 'RepeatedGetSecurityHealthAnalyticsCustomModuleRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycentermanagement::V1::SecurityCenterManagement::GetSecurityHealthAnalyticsCustomModuleRequest'->new($_) } @$_ ] };

declare 'MapStringGetSecurityHealthAnalyticsCustomModuleRequest',
    as HashRef[GetSecurityHealthAnalyticsCustomModuleRequest()];

declare 'CreateSecurityHealthAnalyticsCustomModuleRequest',
    as InstanceOf['Google::Cloud::Securitycentermanagement::V1::SecurityCenterManagement::CreateSecurityHealthAnalyticsCustomModuleRequest'];

coerce 'CreateSecurityHealthAnalyticsCustomModuleRequest',
    from HashRef, via { 'Google::Cloud::Securitycentermanagement::V1::SecurityCenterManagement::CreateSecurityHealthAnalyticsCustomModuleRequest'->new($_) };

declare 'RepeatedCreateSecurityHealthAnalyticsCustomModuleRequest',
    as ArrayRef[CreateSecurityHealthAnalyticsCustomModuleRequest()];

coerce 'RepeatedCreateSecurityHealthAnalyticsCustomModuleRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycentermanagement::V1::SecurityCenterManagement::CreateSecurityHealthAnalyticsCustomModuleRequest'->new($_) } @$_ ] };

declare 'MapStringCreateSecurityHealthAnalyticsCustomModuleRequest',
    as HashRef[CreateSecurityHealthAnalyticsCustomModuleRequest()];

declare 'UpdateSecurityHealthAnalyticsCustomModuleRequest',
    as InstanceOf['Google::Cloud::Securitycentermanagement::V1::SecurityCenterManagement::UpdateSecurityHealthAnalyticsCustomModuleRequest'];

coerce 'UpdateSecurityHealthAnalyticsCustomModuleRequest',
    from HashRef, via { 'Google::Cloud::Securitycentermanagement::V1::SecurityCenterManagement::UpdateSecurityHealthAnalyticsCustomModuleRequest'->new($_) };

declare 'RepeatedUpdateSecurityHealthAnalyticsCustomModuleRequest',
    as ArrayRef[UpdateSecurityHealthAnalyticsCustomModuleRequest()];

coerce 'RepeatedUpdateSecurityHealthAnalyticsCustomModuleRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycentermanagement::V1::SecurityCenterManagement::UpdateSecurityHealthAnalyticsCustomModuleRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateSecurityHealthAnalyticsCustomModuleRequest',
    as HashRef[UpdateSecurityHealthAnalyticsCustomModuleRequest()];

declare 'DeleteSecurityHealthAnalyticsCustomModuleRequest',
    as InstanceOf['Google::Cloud::Securitycentermanagement::V1::SecurityCenterManagement::DeleteSecurityHealthAnalyticsCustomModuleRequest'];

coerce 'DeleteSecurityHealthAnalyticsCustomModuleRequest',
    from HashRef, via { 'Google::Cloud::Securitycentermanagement::V1::SecurityCenterManagement::DeleteSecurityHealthAnalyticsCustomModuleRequest'->new($_) };

declare 'RepeatedDeleteSecurityHealthAnalyticsCustomModuleRequest',
    as ArrayRef[DeleteSecurityHealthAnalyticsCustomModuleRequest()];

coerce 'RepeatedDeleteSecurityHealthAnalyticsCustomModuleRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycentermanagement::V1::SecurityCenterManagement::DeleteSecurityHealthAnalyticsCustomModuleRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteSecurityHealthAnalyticsCustomModuleRequest',
    as HashRef[DeleteSecurityHealthAnalyticsCustomModuleRequest()];

declare 'SimulateSecurityHealthAnalyticsCustomModuleRequest',
    as InstanceOf['Google::Cloud::Securitycentermanagement::V1::SecurityCenterManagement::SimulateSecurityHealthAnalyticsCustomModuleRequest'];

coerce 'SimulateSecurityHealthAnalyticsCustomModuleRequest',
    from HashRef, via { 'Google::Cloud::Securitycentermanagement::V1::SecurityCenterManagement::SimulateSecurityHealthAnalyticsCustomModuleRequest'->new($_) };

declare 'RepeatedSimulateSecurityHealthAnalyticsCustomModuleRequest',
    as ArrayRef[SimulateSecurityHealthAnalyticsCustomModuleRequest()];

coerce 'RepeatedSimulateSecurityHealthAnalyticsCustomModuleRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycentermanagement::V1::SecurityCenterManagement::SimulateSecurityHealthAnalyticsCustomModuleRequest'->new($_) } @$_ ] };

declare 'MapStringSimulateSecurityHealthAnalyticsCustomModuleRequest',
    as HashRef[SimulateSecurityHealthAnalyticsCustomModuleRequest()];

declare 'SimulatedResource',
    as InstanceOf['Google::Cloud::Securitycentermanagement::V1::SecurityCenterManagement::SimulateSecurityHealthAnalyticsCustomModuleRequest::SimulatedResource'];

coerce 'SimulatedResource',
    from HashRef, via { 'Google::Cloud::Securitycentermanagement::V1::SecurityCenterManagement::SimulateSecurityHealthAnalyticsCustomModuleRequest::SimulatedResource'->new($_) };

declare 'RepeatedSimulatedResource',
    as ArrayRef[SimulatedResource()];

coerce 'RepeatedSimulatedResource',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycentermanagement::V1::SecurityCenterManagement::SimulateSecurityHealthAnalyticsCustomModuleRequest::SimulatedResource'->new($_) } @$_ ] };

declare 'MapStringSimulatedResource',
    as HashRef[SimulatedResource()];

declare 'SimulatedFinding',
    as InstanceOf['Google::Cloud::Securitycentermanagement::V1::SecurityCenterManagement::SimulatedFinding'];

coerce 'SimulatedFinding',
    from HashRef, via { 'Google::Cloud::Securitycentermanagement::V1::SecurityCenterManagement::SimulatedFinding'->new($_) };

declare 'RepeatedSimulatedFinding',
    as ArrayRef[SimulatedFinding()];

coerce 'RepeatedSimulatedFinding',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycentermanagement::V1::SecurityCenterManagement::SimulatedFinding'->new($_) } @$_ ] };

declare 'MapStringSimulatedFinding',
    as HashRef[SimulatedFinding()];

declare 'State',
    as (Int | Str);

declare 'Severity',
    as (Int | Str);

declare 'FindingClass',
    as (Int | Str);

declare 'SourcePropertiesEntry',
    as InstanceOf['Google::Cloud::Securitycentermanagement::V1::SecurityCenterManagement::SimulatedFinding::SourcePropertiesEntry'];

coerce 'SourcePropertiesEntry',
    from HashRef, via { 'Google::Cloud::Securitycentermanagement::V1::SecurityCenterManagement::SimulatedFinding::SourcePropertiesEntry'->new($_) };

declare 'RepeatedSourcePropertiesEntry',
    as ArrayRef[SourcePropertiesEntry()];

coerce 'RepeatedSourcePropertiesEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycentermanagement::V1::SecurityCenterManagement::SimulatedFinding::SourcePropertiesEntry'->new($_) } @$_ ] };

declare 'MapStringSourcePropertiesEntry',
    as HashRef[SourcePropertiesEntry()];

declare 'SimulateSecurityHealthAnalyticsCustomModuleResponse',
    as InstanceOf['Google::Cloud::Securitycentermanagement::V1::SecurityCenterManagement::SimulateSecurityHealthAnalyticsCustomModuleResponse'];

coerce 'SimulateSecurityHealthAnalyticsCustomModuleResponse',
    from HashRef, via { 'Google::Cloud::Securitycentermanagement::V1::SecurityCenterManagement::SimulateSecurityHealthAnalyticsCustomModuleResponse'->new($_) };

declare 'RepeatedSimulateSecurityHealthAnalyticsCustomModuleResponse',
    as ArrayRef[SimulateSecurityHealthAnalyticsCustomModuleResponse()];

coerce 'RepeatedSimulateSecurityHealthAnalyticsCustomModuleResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycentermanagement::V1::SecurityCenterManagement::SimulateSecurityHealthAnalyticsCustomModuleResponse'->new($_) } @$_ ] };

declare 'MapStringSimulateSecurityHealthAnalyticsCustomModuleResponse',
    as HashRef[SimulateSecurityHealthAnalyticsCustomModuleResponse()];

declare 'SimulatedResult',
    as InstanceOf['Google::Cloud::Securitycentermanagement::V1::SecurityCenterManagement::SimulateSecurityHealthAnalyticsCustomModuleResponse::SimulatedResult'];

coerce 'SimulatedResult',
    from HashRef, via { 'Google::Cloud::Securitycentermanagement::V1::SecurityCenterManagement::SimulateSecurityHealthAnalyticsCustomModuleResponse::SimulatedResult'->new($_) };

declare 'RepeatedSimulatedResult',
    as ArrayRef[SimulatedResult()];

coerce 'RepeatedSimulatedResult',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycentermanagement::V1::SecurityCenterManagement::SimulateSecurityHealthAnalyticsCustomModuleResponse::SimulatedResult'->new($_) } @$_ ] };

declare 'MapStringSimulatedResult',
    as HashRef[SimulatedResult()];

declare 'EffectiveEventThreatDetectionCustomModule',
    as InstanceOf['Google::Cloud::Securitycentermanagement::V1::SecurityCenterManagement::EffectiveEventThreatDetectionCustomModule'];

coerce 'EffectiveEventThreatDetectionCustomModule',
    from HashRef, via { 'Google::Cloud::Securitycentermanagement::V1::SecurityCenterManagement::EffectiveEventThreatDetectionCustomModule'->new($_) };

declare 'RepeatedEffectiveEventThreatDetectionCustomModule',
    as ArrayRef[EffectiveEventThreatDetectionCustomModule()];

coerce 'RepeatedEffectiveEventThreatDetectionCustomModule',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycentermanagement::V1::SecurityCenterManagement::EffectiveEventThreatDetectionCustomModule'->new($_) } @$_ ] };

declare 'MapStringEffectiveEventThreatDetectionCustomModule',
    as HashRef[EffectiveEventThreatDetectionCustomModule()];

declare 'EnablementState',
    as (Int | Str);

declare 'ListEffectiveEventThreatDetectionCustomModulesRequest',
    as InstanceOf['Google::Cloud::Securitycentermanagement::V1::SecurityCenterManagement::ListEffectiveEventThreatDetectionCustomModulesRequest'];

coerce 'ListEffectiveEventThreatDetectionCustomModulesRequest',
    from HashRef, via { 'Google::Cloud::Securitycentermanagement::V1::SecurityCenterManagement::ListEffectiveEventThreatDetectionCustomModulesRequest'->new($_) };

declare 'RepeatedListEffectiveEventThreatDetectionCustomModulesRequest',
    as ArrayRef[ListEffectiveEventThreatDetectionCustomModulesRequest()];

coerce 'RepeatedListEffectiveEventThreatDetectionCustomModulesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycentermanagement::V1::SecurityCenterManagement::ListEffectiveEventThreatDetectionCustomModulesRequest'->new($_) } @$_ ] };

declare 'MapStringListEffectiveEventThreatDetectionCustomModulesRequest',
    as HashRef[ListEffectiveEventThreatDetectionCustomModulesRequest()];

declare 'ListEffectiveEventThreatDetectionCustomModulesResponse',
    as InstanceOf['Google::Cloud::Securitycentermanagement::V1::SecurityCenterManagement::ListEffectiveEventThreatDetectionCustomModulesResponse'];

coerce 'ListEffectiveEventThreatDetectionCustomModulesResponse',
    from HashRef, via { 'Google::Cloud::Securitycentermanagement::V1::SecurityCenterManagement::ListEffectiveEventThreatDetectionCustomModulesResponse'->new($_) };

declare 'RepeatedListEffectiveEventThreatDetectionCustomModulesResponse',
    as ArrayRef[ListEffectiveEventThreatDetectionCustomModulesResponse()];

coerce 'RepeatedListEffectiveEventThreatDetectionCustomModulesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycentermanagement::V1::SecurityCenterManagement::ListEffectiveEventThreatDetectionCustomModulesResponse'->new($_) } @$_ ] };

declare 'MapStringListEffectiveEventThreatDetectionCustomModulesResponse',
    as HashRef[ListEffectiveEventThreatDetectionCustomModulesResponse()];

declare 'GetEffectiveEventThreatDetectionCustomModuleRequest',
    as InstanceOf['Google::Cloud::Securitycentermanagement::V1::SecurityCenterManagement::GetEffectiveEventThreatDetectionCustomModuleRequest'];

coerce 'GetEffectiveEventThreatDetectionCustomModuleRequest',
    from HashRef, via { 'Google::Cloud::Securitycentermanagement::V1::SecurityCenterManagement::GetEffectiveEventThreatDetectionCustomModuleRequest'->new($_) };

declare 'RepeatedGetEffectiveEventThreatDetectionCustomModuleRequest',
    as ArrayRef[GetEffectiveEventThreatDetectionCustomModuleRequest()];

coerce 'RepeatedGetEffectiveEventThreatDetectionCustomModuleRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycentermanagement::V1::SecurityCenterManagement::GetEffectiveEventThreatDetectionCustomModuleRequest'->new($_) } @$_ ] };

declare 'MapStringGetEffectiveEventThreatDetectionCustomModuleRequest',
    as HashRef[GetEffectiveEventThreatDetectionCustomModuleRequest()];

declare 'EventThreatDetectionCustomModule',
    as InstanceOf['Google::Cloud::Securitycentermanagement::V1::SecurityCenterManagement::EventThreatDetectionCustomModule'];

coerce 'EventThreatDetectionCustomModule',
    from HashRef, via { 'Google::Cloud::Securitycentermanagement::V1::SecurityCenterManagement::EventThreatDetectionCustomModule'->new($_) };

declare 'RepeatedEventThreatDetectionCustomModule',
    as ArrayRef[EventThreatDetectionCustomModule()];

coerce 'RepeatedEventThreatDetectionCustomModule',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycentermanagement::V1::SecurityCenterManagement::EventThreatDetectionCustomModule'->new($_) } @$_ ] };

declare 'MapStringEventThreatDetectionCustomModule',
    as HashRef[EventThreatDetectionCustomModule()];

declare 'EnablementState',
    as (Int | Str);

declare 'ListEventThreatDetectionCustomModulesRequest',
    as InstanceOf['Google::Cloud::Securitycentermanagement::V1::SecurityCenterManagement::ListEventThreatDetectionCustomModulesRequest'];

coerce 'ListEventThreatDetectionCustomModulesRequest',
    from HashRef, via { 'Google::Cloud::Securitycentermanagement::V1::SecurityCenterManagement::ListEventThreatDetectionCustomModulesRequest'->new($_) };

declare 'RepeatedListEventThreatDetectionCustomModulesRequest',
    as ArrayRef[ListEventThreatDetectionCustomModulesRequest()];

coerce 'RepeatedListEventThreatDetectionCustomModulesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycentermanagement::V1::SecurityCenterManagement::ListEventThreatDetectionCustomModulesRequest'->new($_) } @$_ ] };

declare 'MapStringListEventThreatDetectionCustomModulesRequest',
    as HashRef[ListEventThreatDetectionCustomModulesRequest()];

declare 'ListEventThreatDetectionCustomModulesResponse',
    as InstanceOf['Google::Cloud::Securitycentermanagement::V1::SecurityCenterManagement::ListEventThreatDetectionCustomModulesResponse'];

coerce 'ListEventThreatDetectionCustomModulesResponse',
    from HashRef, via { 'Google::Cloud::Securitycentermanagement::V1::SecurityCenterManagement::ListEventThreatDetectionCustomModulesResponse'->new($_) };

declare 'RepeatedListEventThreatDetectionCustomModulesResponse',
    as ArrayRef[ListEventThreatDetectionCustomModulesResponse()];

coerce 'RepeatedListEventThreatDetectionCustomModulesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycentermanagement::V1::SecurityCenterManagement::ListEventThreatDetectionCustomModulesResponse'->new($_) } @$_ ] };

declare 'MapStringListEventThreatDetectionCustomModulesResponse',
    as HashRef[ListEventThreatDetectionCustomModulesResponse()];

declare 'ListDescendantEventThreatDetectionCustomModulesRequest',
    as InstanceOf['Google::Cloud::Securitycentermanagement::V1::SecurityCenterManagement::ListDescendantEventThreatDetectionCustomModulesRequest'];

coerce 'ListDescendantEventThreatDetectionCustomModulesRequest',
    from HashRef, via { 'Google::Cloud::Securitycentermanagement::V1::SecurityCenterManagement::ListDescendantEventThreatDetectionCustomModulesRequest'->new($_) };

declare 'RepeatedListDescendantEventThreatDetectionCustomModulesRequest',
    as ArrayRef[ListDescendantEventThreatDetectionCustomModulesRequest()];

coerce 'RepeatedListDescendantEventThreatDetectionCustomModulesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycentermanagement::V1::SecurityCenterManagement::ListDescendantEventThreatDetectionCustomModulesRequest'->new($_) } @$_ ] };

declare 'MapStringListDescendantEventThreatDetectionCustomModulesRequest',
    as HashRef[ListDescendantEventThreatDetectionCustomModulesRequest()];

declare 'ListDescendantEventThreatDetectionCustomModulesResponse',
    as InstanceOf['Google::Cloud::Securitycentermanagement::V1::SecurityCenterManagement::ListDescendantEventThreatDetectionCustomModulesResponse'];

coerce 'ListDescendantEventThreatDetectionCustomModulesResponse',
    from HashRef, via { 'Google::Cloud::Securitycentermanagement::V1::SecurityCenterManagement::ListDescendantEventThreatDetectionCustomModulesResponse'->new($_) };

declare 'RepeatedListDescendantEventThreatDetectionCustomModulesResponse',
    as ArrayRef[ListDescendantEventThreatDetectionCustomModulesResponse()];

coerce 'RepeatedListDescendantEventThreatDetectionCustomModulesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycentermanagement::V1::SecurityCenterManagement::ListDescendantEventThreatDetectionCustomModulesResponse'->new($_) } @$_ ] };

declare 'MapStringListDescendantEventThreatDetectionCustomModulesResponse',
    as HashRef[ListDescendantEventThreatDetectionCustomModulesResponse()];

declare 'GetEventThreatDetectionCustomModuleRequest',
    as InstanceOf['Google::Cloud::Securitycentermanagement::V1::SecurityCenterManagement::GetEventThreatDetectionCustomModuleRequest'];

coerce 'GetEventThreatDetectionCustomModuleRequest',
    from HashRef, via { 'Google::Cloud::Securitycentermanagement::V1::SecurityCenterManagement::GetEventThreatDetectionCustomModuleRequest'->new($_) };

declare 'RepeatedGetEventThreatDetectionCustomModuleRequest',
    as ArrayRef[GetEventThreatDetectionCustomModuleRequest()];

coerce 'RepeatedGetEventThreatDetectionCustomModuleRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycentermanagement::V1::SecurityCenterManagement::GetEventThreatDetectionCustomModuleRequest'->new($_) } @$_ ] };

declare 'MapStringGetEventThreatDetectionCustomModuleRequest',
    as HashRef[GetEventThreatDetectionCustomModuleRequest()];

declare 'CreateEventThreatDetectionCustomModuleRequest',
    as InstanceOf['Google::Cloud::Securitycentermanagement::V1::SecurityCenterManagement::CreateEventThreatDetectionCustomModuleRequest'];

coerce 'CreateEventThreatDetectionCustomModuleRequest',
    from HashRef, via { 'Google::Cloud::Securitycentermanagement::V1::SecurityCenterManagement::CreateEventThreatDetectionCustomModuleRequest'->new($_) };

declare 'RepeatedCreateEventThreatDetectionCustomModuleRequest',
    as ArrayRef[CreateEventThreatDetectionCustomModuleRequest()];

coerce 'RepeatedCreateEventThreatDetectionCustomModuleRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycentermanagement::V1::SecurityCenterManagement::CreateEventThreatDetectionCustomModuleRequest'->new($_) } @$_ ] };

declare 'MapStringCreateEventThreatDetectionCustomModuleRequest',
    as HashRef[CreateEventThreatDetectionCustomModuleRequest()];

declare 'UpdateEventThreatDetectionCustomModuleRequest',
    as InstanceOf['Google::Cloud::Securitycentermanagement::V1::SecurityCenterManagement::UpdateEventThreatDetectionCustomModuleRequest'];

coerce 'UpdateEventThreatDetectionCustomModuleRequest',
    from HashRef, via { 'Google::Cloud::Securitycentermanagement::V1::SecurityCenterManagement::UpdateEventThreatDetectionCustomModuleRequest'->new($_) };

declare 'RepeatedUpdateEventThreatDetectionCustomModuleRequest',
    as ArrayRef[UpdateEventThreatDetectionCustomModuleRequest()];

coerce 'RepeatedUpdateEventThreatDetectionCustomModuleRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycentermanagement::V1::SecurityCenterManagement::UpdateEventThreatDetectionCustomModuleRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateEventThreatDetectionCustomModuleRequest',
    as HashRef[UpdateEventThreatDetectionCustomModuleRequest()];

declare 'DeleteEventThreatDetectionCustomModuleRequest',
    as InstanceOf['Google::Cloud::Securitycentermanagement::V1::SecurityCenterManagement::DeleteEventThreatDetectionCustomModuleRequest'];

coerce 'DeleteEventThreatDetectionCustomModuleRequest',
    from HashRef, via { 'Google::Cloud::Securitycentermanagement::V1::SecurityCenterManagement::DeleteEventThreatDetectionCustomModuleRequest'->new($_) };

declare 'RepeatedDeleteEventThreatDetectionCustomModuleRequest',
    as ArrayRef[DeleteEventThreatDetectionCustomModuleRequest()];

coerce 'RepeatedDeleteEventThreatDetectionCustomModuleRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycentermanagement::V1::SecurityCenterManagement::DeleteEventThreatDetectionCustomModuleRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteEventThreatDetectionCustomModuleRequest',
    as HashRef[DeleteEventThreatDetectionCustomModuleRequest()];

declare 'ValidateEventThreatDetectionCustomModuleRequest',
    as InstanceOf['Google::Cloud::Securitycentermanagement::V1::SecurityCenterManagement::ValidateEventThreatDetectionCustomModuleRequest'];

coerce 'ValidateEventThreatDetectionCustomModuleRequest',
    from HashRef, via { 'Google::Cloud::Securitycentermanagement::V1::SecurityCenterManagement::ValidateEventThreatDetectionCustomModuleRequest'->new($_) };

declare 'RepeatedValidateEventThreatDetectionCustomModuleRequest',
    as ArrayRef[ValidateEventThreatDetectionCustomModuleRequest()];

coerce 'RepeatedValidateEventThreatDetectionCustomModuleRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycentermanagement::V1::SecurityCenterManagement::ValidateEventThreatDetectionCustomModuleRequest'->new($_) } @$_ ] };

declare 'MapStringValidateEventThreatDetectionCustomModuleRequest',
    as HashRef[ValidateEventThreatDetectionCustomModuleRequest()];

declare 'ValidateEventThreatDetectionCustomModuleResponse',
    as InstanceOf['Google::Cloud::Securitycentermanagement::V1::SecurityCenterManagement::ValidateEventThreatDetectionCustomModuleResponse'];

coerce 'ValidateEventThreatDetectionCustomModuleResponse',
    from HashRef, via { 'Google::Cloud::Securitycentermanagement::V1::SecurityCenterManagement::ValidateEventThreatDetectionCustomModuleResponse'->new($_) };

declare 'RepeatedValidateEventThreatDetectionCustomModuleResponse',
    as ArrayRef[ValidateEventThreatDetectionCustomModuleResponse()];

coerce 'RepeatedValidateEventThreatDetectionCustomModuleResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycentermanagement::V1::SecurityCenterManagement::ValidateEventThreatDetectionCustomModuleResponse'->new($_) } @$_ ] };

declare 'MapStringValidateEventThreatDetectionCustomModuleResponse',
    as HashRef[ValidateEventThreatDetectionCustomModuleResponse()];

declare 'CustomModuleValidationError',
    as InstanceOf['Google::Cloud::Securitycentermanagement::V1::SecurityCenterManagement::ValidateEventThreatDetectionCustomModuleResponse::CustomModuleValidationError'];

coerce 'CustomModuleValidationError',
    from HashRef, via { 'Google::Cloud::Securitycentermanagement::V1::SecurityCenterManagement::ValidateEventThreatDetectionCustomModuleResponse::CustomModuleValidationError'->new($_) };

declare 'RepeatedCustomModuleValidationError',
    as ArrayRef[CustomModuleValidationError()];

coerce 'RepeatedCustomModuleValidationError',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycentermanagement::V1::SecurityCenterManagement::ValidateEventThreatDetectionCustomModuleResponse::CustomModuleValidationError'->new($_) } @$_ ] };

declare 'MapStringCustomModuleValidationError',
    as HashRef[CustomModuleValidationError()];

declare 'Position',
    as InstanceOf['Google::Cloud::Securitycentermanagement::V1::SecurityCenterManagement::ValidateEventThreatDetectionCustomModuleResponse::Position'];

coerce 'Position',
    from HashRef, via { 'Google::Cloud::Securitycentermanagement::V1::SecurityCenterManagement::ValidateEventThreatDetectionCustomModuleResponse::Position'->new($_) };

declare 'RepeatedPosition',
    as ArrayRef[Position()];

coerce 'RepeatedPosition',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycentermanagement::V1::SecurityCenterManagement::ValidateEventThreatDetectionCustomModuleResponse::Position'->new($_) } @$_ ] };

declare 'MapStringPosition',
    as HashRef[Position()];

declare 'GetSecurityCenterServiceRequest',
    as InstanceOf['Google::Cloud::Securitycentermanagement::V1::SecurityCenterManagement::GetSecurityCenterServiceRequest'];

coerce 'GetSecurityCenterServiceRequest',
    from HashRef, via { 'Google::Cloud::Securitycentermanagement::V1::SecurityCenterManagement::GetSecurityCenterServiceRequest'->new($_) };

declare 'RepeatedGetSecurityCenterServiceRequest',
    as ArrayRef[GetSecurityCenterServiceRequest()];

coerce 'RepeatedGetSecurityCenterServiceRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycentermanagement::V1::SecurityCenterManagement::GetSecurityCenterServiceRequest'->new($_) } @$_ ] };

declare 'MapStringGetSecurityCenterServiceRequest',
    as HashRef[GetSecurityCenterServiceRequest()];

declare 'ListSecurityCenterServicesRequest',
    as InstanceOf['Google::Cloud::Securitycentermanagement::V1::SecurityCenterManagement::ListSecurityCenterServicesRequest'];

coerce 'ListSecurityCenterServicesRequest',
    from HashRef, via { 'Google::Cloud::Securitycentermanagement::V1::SecurityCenterManagement::ListSecurityCenterServicesRequest'->new($_) };

declare 'RepeatedListSecurityCenterServicesRequest',
    as ArrayRef[ListSecurityCenterServicesRequest()];

coerce 'RepeatedListSecurityCenterServicesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycentermanagement::V1::SecurityCenterManagement::ListSecurityCenterServicesRequest'->new($_) } @$_ ] };

declare 'MapStringListSecurityCenterServicesRequest',
    as HashRef[ListSecurityCenterServicesRequest()];

declare 'ListSecurityCenterServicesResponse',
    as InstanceOf['Google::Cloud::Securitycentermanagement::V1::SecurityCenterManagement::ListSecurityCenterServicesResponse'];

coerce 'ListSecurityCenterServicesResponse',
    from HashRef, via { 'Google::Cloud::Securitycentermanagement::V1::SecurityCenterManagement::ListSecurityCenterServicesResponse'->new($_) };

declare 'RepeatedListSecurityCenterServicesResponse',
    as ArrayRef[ListSecurityCenterServicesResponse()];

coerce 'RepeatedListSecurityCenterServicesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycentermanagement::V1::SecurityCenterManagement::ListSecurityCenterServicesResponse'->new($_) } @$_ ] };

declare 'MapStringListSecurityCenterServicesResponse',
    as HashRef[ListSecurityCenterServicesResponse()];

declare 'UpdateSecurityCenterServiceRequest',
    as InstanceOf['Google::Cloud::Securitycentermanagement::V1::SecurityCenterManagement::UpdateSecurityCenterServiceRequest'];

coerce 'UpdateSecurityCenterServiceRequest',
    from HashRef, via { 'Google::Cloud::Securitycentermanagement::V1::SecurityCenterManagement::UpdateSecurityCenterServiceRequest'->new($_) };

declare 'RepeatedUpdateSecurityCenterServiceRequest',
    as ArrayRef[UpdateSecurityCenterServiceRequest()];

coerce 'RepeatedUpdateSecurityCenterServiceRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycentermanagement::V1::SecurityCenterManagement::UpdateSecurityCenterServiceRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateSecurityCenterServiceRequest',
    as HashRef[UpdateSecurityCenterServiceRequest()];

1;

__END__

=head1 NAME

Google::Cloud::Securitycentermanagement::V1::SecurityCenterManagement::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
