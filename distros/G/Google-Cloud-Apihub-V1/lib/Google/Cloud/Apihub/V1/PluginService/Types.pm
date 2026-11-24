package Google::Cloud::Apihub::V1::PluginService::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'ActionType',
    as (Int | Str);

declare 'GatewayType',
    as (Int | Str);

declare 'CurationType',
    as (Int | Str);

declare 'Plugin',
    as InstanceOf['Google::Cloud::Apihub::V1::PluginService::Plugin'];

coerce 'Plugin',
    from HashRef, via { 'Google::Cloud::Apihub::V1::PluginService::Plugin'->new($_) };

declare 'RepeatedPlugin',
    as ArrayRef[Plugin()];

coerce 'RepeatedPlugin',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apihub::V1::PluginService::Plugin'->new($_) } @$_ ] };

declare 'MapStringPlugin',
    as HashRef[Plugin()];

declare 'State',
    as (Int | Str);

declare 'OwnershipType',
    as (Int | Str);

declare 'HostingService',
    as InstanceOf['Google::Cloud::Apihub::V1::PluginService::Plugin::HostingService'];

coerce 'HostingService',
    from HashRef, via { 'Google::Cloud::Apihub::V1::PluginService::Plugin::HostingService'->new($_) };

declare 'RepeatedHostingService',
    as ArrayRef[HostingService()];

coerce 'RepeatedHostingService',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apihub::V1::PluginService::Plugin::HostingService'->new($_) } @$_ ] };

declare 'MapStringHostingService',
    as HashRef[HostingService()];

declare 'ConfigTemplate',
    as InstanceOf['Google::Cloud::Apihub::V1::PluginService::Plugin::ConfigTemplate'];

coerce 'ConfigTemplate',
    from HashRef, via { 'Google::Cloud::Apihub::V1::PluginService::Plugin::ConfigTemplate'->new($_) };

declare 'RepeatedConfigTemplate',
    as ArrayRef[ConfigTemplate()];

coerce 'RepeatedConfigTemplate',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apihub::V1::PluginService::Plugin::ConfigTemplate'->new($_) } @$_ ] };

declare 'MapStringConfigTemplate',
    as HashRef[ConfigTemplate()];

declare 'AuthConfigTemplate',
    as InstanceOf['Google::Cloud::Apihub::V1::PluginService::Plugin::ConfigTemplate::AuthConfigTemplate'];

coerce 'AuthConfigTemplate',
    from HashRef, via { 'Google::Cloud::Apihub::V1::PluginService::Plugin::ConfigTemplate::AuthConfigTemplate'->new($_) };

declare 'RepeatedAuthConfigTemplate',
    as ArrayRef[AuthConfigTemplate()];

coerce 'RepeatedAuthConfigTemplate',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apihub::V1::PluginService::Plugin::ConfigTemplate::AuthConfigTemplate'->new($_) } @$_ ] };

declare 'MapStringAuthConfigTemplate',
    as HashRef[AuthConfigTemplate()];

declare 'PluginActionConfig',
    as InstanceOf['Google::Cloud::Apihub::V1::PluginService::PluginActionConfig'];

coerce 'PluginActionConfig',
    from HashRef, via { 'Google::Cloud::Apihub::V1::PluginService::PluginActionConfig'->new($_) };

declare 'RepeatedPluginActionConfig',
    as ArrayRef[PluginActionConfig()];

coerce 'RepeatedPluginActionConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apihub::V1::PluginService::PluginActionConfig'->new($_) } @$_ ] };

declare 'MapStringPluginActionConfig',
    as HashRef[PluginActionConfig()];

declare 'TriggerMode',
    as (Int | Str);

declare 'GetPluginRequest',
    as InstanceOf['Google::Cloud::Apihub::V1::PluginService::GetPluginRequest'];

coerce 'GetPluginRequest',
    from HashRef, via { 'Google::Cloud::Apihub::V1::PluginService::GetPluginRequest'->new($_) };

declare 'RepeatedGetPluginRequest',
    as ArrayRef[GetPluginRequest()];

coerce 'RepeatedGetPluginRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apihub::V1::PluginService::GetPluginRequest'->new($_) } @$_ ] };

declare 'MapStringGetPluginRequest',
    as HashRef[GetPluginRequest()];

declare 'EnablePluginRequest',
    as InstanceOf['Google::Cloud::Apihub::V1::PluginService::EnablePluginRequest'];

coerce 'EnablePluginRequest',
    from HashRef, via { 'Google::Cloud::Apihub::V1::PluginService::EnablePluginRequest'->new($_) };

declare 'RepeatedEnablePluginRequest',
    as ArrayRef[EnablePluginRequest()];

coerce 'RepeatedEnablePluginRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apihub::V1::PluginService::EnablePluginRequest'->new($_) } @$_ ] };

declare 'MapStringEnablePluginRequest',
    as HashRef[EnablePluginRequest()];

declare 'DisablePluginRequest',
    as InstanceOf['Google::Cloud::Apihub::V1::PluginService::DisablePluginRequest'];

coerce 'DisablePluginRequest',
    from HashRef, via { 'Google::Cloud::Apihub::V1::PluginService::DisablePluginRequest'->new($_) };

declare 'RepeatedDisablePluginRequest',
    as ArrayRef[DisablePluginRequest()];

coerce 'RepeatedDisablePluginRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apihub::V1::PluginService::DisablePluginRequest'->new($_) } @$_ ] };

declare 'MapStringDisablePluginRequest',
    as HashRef[DisablePluginRequest()];

declare 'PluginInstanceAction',
    as InstanceOf['Google::Cloud::Apihub::V1::PluginService::PluginInstanceAction'];

coerce 'PluginInstanceAction',
    from HashRef, via { 'Google::Cloud::Apihub::V1::PluginService::PluginInstanceAction'->new($_) };

declare 'RepeatedPluginInstanceAction',
    as ArrayRef[PluginInstanceAction()];

coerce 'RepeatedPluginInstanceAction',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apihub::V1::PluginService::PluginInstanceAction'->new($_) } @$_ ] };

declare 'MapStringPluginInstanceAction',
    as HashRef[PluginInstanceAction()];

declare 'State',
    as (Int | Str);

declare 'ResourceConfig',
    as InstanceOf['Google::Cloud::Apihub::V1::PluginService::PluginInstanceAction::ResourceConfig'];

coerce 'ResourceConfig',
    from HashRef, via { 'Google::Cloud::Apihub::V1::PluginService::PluginInstanceAction::ResourceConfig'->new($_) };

declare 'RepeatedResourceConfig',
    as ArrayRef[ResourceConfig()];

coerce 'RepeatedResourceConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apihub::V1::PluginService::PluginInstanceAction::ResourceConfig'->new($_) } @$_ ] };

declare 'MapStringResourceConfig',
    as HashRef[ResourceConfig()];

declare 'PluginInstance',
    as InstanceOf['Google::Cloud::Apihub::V1::PluginService::PluginInstance'];

coerce 'PluginInstance',
    from HashRef, via { 'Google::Cloud::Apihub::V1::PluginService::PluginInstance'->new($_) };

declare 'RepeatedPluginInstance',
    as ArrayRef[PluginInstance()];

coerce 'RepeatedPluginInstance',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apihub::V1::PluginService::PluginInstance'->new($_) } @$_ ] };

declare 'MapStringPluginInstance',
    as HashRef[PluginInstance()];

declare 'State',
    as (Int | Str);

declare 'AdditionalConfigEntry',
    as InstanceOf['Google::Cloud::Apihub::V1::PluginService::PluginInstance::AdditionalConfigEntry'];

coerce 'AdditionalConfigEntry',
    from HashRef, via { 'Google::Cloud::Apihub::V1::PluginService::PluginInstance::AdditionalConfigEntry'->new($_) };

declare 'RepeatedAdditionalConfigEntry',
    as ArrayRef[AdditionalConfigEntry()];

coerce 'RepeatedAdditionalConfigEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apihub::V1::PluginService::PluginInstance::AdditionalConfigEntry'->new($_) } @$_ ] };

declare 'MapStringAdditionalConfigEntry',
    as HashRef[AdditionalConfigEntry()];

declare 'CurationConfig',
    as InstanceOf['Google::Cloud::Apihub::V1::PluginService::CurationConfig'];

coerce 'CurationConfig',
    from HashRef, via { 'Google::Cloud::Apihub::V1::PluginService::CurationConfig'->new($_) };

declare 'RepeatedCurationConfig',
    as ArrayRef[CurationConfig()];

coerce 'RepeatedCurationConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apihub::V1::PluginService::CurationConfig'->new($_) } @$_ ] };

declare 'MapStringCurationConfig',
    as HashRef[CurationConfig()];

declare 'CustomCuration',
    as InstanceOf['Google::Cloud::Apihub::V1::PluginService::CurationConfig::CustomCuration'];

coerce 'CustomCuration',
    from HashRef, via { 'Google::Cloud::Apihub::V1::PluginService::CurationConfig::CustomCuration'->new($_) };

declare 'RepeatedCustomCuration',
    as ArrayRef[CustomCuration()];

coerce 'RepeatedCustomCuration',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apihub::V1::PluginService::CurationConfig::CustomCuration'->new($_) } @$_ ] };

declare 'MapStringCustomCuration',
    as HashRef[CustomCuration()];

declare 'ExecutionStatus',
    as InstanceOf['Google::Cloud::Apihub::V1::PluginService::ExecutionStatus'];

coerce 'ExecutionStatus',
    from HashRef, via { 'Google::Cloud::Apihub::V1::PluginService::ExecutionStatus'->new($_) };

declare 'RepeatedExecutionStatus',
    as ArrayRef[ExecutionStatus()];

coerce 'RepeatedExecutionStatus',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apihub::V1::PluginService::ExecutionStatus'->new($_) } @$_ ] };

declare 'MapStringExecutionStatus',
    as HashRef[ExecutionStatus()];

declare 'CurrentExecutionState',
    as (Int | Str);

declare 'LastExecution',
    as InstanceOf['Google::Cloud::Apihub::V1::PluginService::ExecutionStatus::LastExecution'];

coerce 'LastExecution',
    from HashRef, via { 'Google::Cloud::Apihub::V1::PluginService::ExecutionStatus::LastExecution'->new($_) };

declare 'RepeatedLastExecution',
    as ArrayRef[LastExecution()];

coerce 'RepeatedLastExecution',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apihub::V1::PluginService::ExecutionStatus::LastExecution'->new($_) } @$_ ] };

declare 'MapStringLastExecution',
    as HashRef[LastExecution()];

declare 'Result',
    as (Int | Str);

declare 'CreatePluginRequest',
    as InstanceOf['Google::Cloud::Apihub::V1::PluginService::CreatePluginRequest'];

coerce 'CreatePluginRequest',
    from HashRef, via { 'Google::Cloud::Apihub::V1::PluginService::CreatePluginRequest'->new($_) };

declare 'RepeatedCreatePluginRequest',
    as ArrayRef[CreatePluginRequest()];

coerce 'RepeatedCreatePluginRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apihub::V1::PluginService::CreatePluginRequest'->new($_) } @$_ ] };

declare 'MapStringCreatePluginRequest',
    as HashRef[CreatePluginRequest()];

declare 'DeletePluginRequest',
    as InstanceOf['Google::Cloud::Apihub::V1::PluginService::DeletePluginRequest'];

coerce 'DeletePluginRequest',
    from HashRef, via { 'Google::Cloud::Apihub::V1::PluginService::DeletePluginRequest'->new($_) };

declare 'RepeatedDeletePluginRequest',
    as ArrayRef[DeletePluginRequest()];

coerce 'RepeatedDeletePluginRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apihub::V1::PluginService::DeletePluginRequest'->new($_) } @$_ ] };

declare 'MapStringDeletePluginRequest',
    as HashRef[DeletePluginRequest()];

declare 'ListPluginsRequest',
    as InstanceOf['Google::Cloud::Apihub::V1::PluginService::ListPluginsRequest'];

coerce 'ListPluginsRequest',
    from HashRef, via { 'Google::Cloud::Apihub::V1::PluginService::ListPluginsRequest'->new($_) };

declare 'RepeatedListPluginsRequest',
    as ArrayRef[ListPluginsRequest()];

coerce 'RepeatedListPluginsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apihub::V1::PluginService::ListPluginsRequest'->new($_) } @$_ ] };

declare 'MapStringListPluginsRequest',
    as HashRef[ListPluginsRequest()];

declare 'ListPluginsResponse',
    as InstanceOf['Google::Cloud::Apihub::V1::PluginService::ListPluginsResponse'];

coerce 'ListPluginsResponse',
    from HashRef, via { 'Google::Cloud::Apihub::V1::PluginService::ListPluginsResponse'->new($_) };

declare 'RepeatedListPluginsResponse',
    as ArrayRef[ListPluginsResponse()];

coerce 'RepeatedListPluginsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apihub::V1::PluginService::ListPluginsResponse'->new($_) } @$_ ] };

declare 'MapStringListPluginsResponse',
    as HashRef[ListPluginsResponse()];

declare 'CreatePluginInstanceRequest',
    as InstanceOf['Google::Cloud::Apihub::V1::PluginService::CreatePluginInstanceRequest'];

coerce 'CreatePluginInstanceRequest',
    from HashRef, via { 'Google::Cloud::Apihub::V1::PluginService::CreatePluginInstanceRequest'->new($_) };

declare 'RepeatedCreatePluginInstanceRequest',
    as ArrayRef[CreatePluginInstanceRequest()];

coerce 'RepeatedCreatePluginInstanceRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apihub::V1::PluginService::CreatePluginInstanceRequest'->new($_) } @$_ ] };

declare 'MapStringCreatePluginInstanceRequest',
    as HashRef[CreatePluginInstanceRequest()];

declare 'ExecutePluginInstanceActionRequest',
    as InstanceOf['Google::Cloud::Apihub::V1::PluginService::ExecutePluginInstanceActionRequest'];

coerce 'ExecutePluginInstanceActionRequest',
    from HashRef, via { 'Google::Cloud::Apihub::V1::PluginService::ExecutePluginInstanceActionRequest'->new($_) };

declare 'RepeatedExecutePluginInstanceActionRequest',
    as ArrayRef[ExecutePluginInstanceActionRequest()];

coerce 'RepeatedExecutePluginInstanceActionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apihub::V1::PluginService::ExecutePluginInstanceActionRequest'->new($_) } @$_ ] };

declare 'MapStringExecutePluginInstanceActionRequest',
    as HashRef[ExecutePluginInstanceActionRequest()];

declare 'ActionExecutionDetail',
    as InstanceOf['Google::Cloud::Apihub::V1::PluginService::ActionExecutionDetail'];

coerce 'ActionExecutionDetail',
    from HashRef, via { 'Google::Cloud::Apihub::V1::PluginService::ActionExecutionDetail'->new($_) };

declare 'RepeatedActionExecutionDetail',
    as ArrayRef[ActionExecutionDetail()];

coerce 'RepeatedActionExecutionDetail',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apihub::V1::PluginService::ActionExecutionDetail'->new($_) } @$_ ] };

declare 'MapStringActionExecutionDetail',
    as HashRef[ActionExecutionDetail()];

declare 'ExecutePluginInstanceActionResponse',
    as InstanceOf['Google::Cloud::Apihub::V1::PluginService::ExecutePluginInstanceActionResponse'];

coerce 'ExecutePluginInstanceActionResponse',
    from HashRef, via { 'Google::Cloud::Apihub::V1::PluginService::ExecutePluginInstanceActionResponse'->new($_) };

declare 'RepeatedExecutePluginInstanceActionResponse',
    as ArrayRef[ExecutePluginInstanceActionResponse()];

coerce 'RepeatedExecutePluginInstanceActionResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apihub::V1::PluginService::ExecutePluginInstanceActionResponse'->new($_) } @$_ ] };

declare 'MapStringExecutePluginInstanceActionResponse',
    as HashRef[ExecutePluginInstanceActionResponse()];

declare 'GetPluginInstanceRequest',
    as InstanceOf['Google::Cloud::Apihub::V1::PluginService::GetPluginInstanceRequest'];

coerce 'GetPluginInstanceRequest',
    from HashRef, via { 'Google::Cloud::Apihub::V1::PluginService::GetPluginInstanceRequest'->new($_) };

declare 'RepeatedGetPluginInstanceRequest',
    as ArrayRef[GetPluginInstanceRequest()];

coerce 'RepeatedGetPluginInstanceRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apihub::V1::PluginService::GetPluginInstanceRequest'->new($_) } @$_ ] };

declare 'MapStringGetPluginInstanceRequest',
    as HashRef[GetPluginInstanceRequest()];

declare 'ListPluginInstancesRequest',
    as InstanceOf['Google::Cloud::Apihub::V1::PluginService::ListPluginInstancesRequest'];

coerce 'ListPluginInstancesRequest',
    from HashRef, via { 'Google::Cloud::Apihub::V1::PluginService::ListPluginInstancesRequest'->new($_) };

declare 'RepeatedListPluginInstancesRequest',
    as ArrayRef[ListPluginInstancesRequest()];

coerce 'RepeatedListPluginInstancesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apihub::V1::PluginService::ListPluginInstancesRequest'->new($_) } @$_ ] };

declare 'MapStringListPluginInstancesRequest',
    as HashRef[ListPluginInstancesRequest()];

declare 'ListPluginInstancesResponse',
    as InstanceOf['Google::Cloud::Apihub::V1::PluginService::ListPluginInstancesResponse'];

coerce 'ListPluginInstancesResponse',
    from HashRef, via { 'Google::Cloud::Apihub::V1::PluginService::ListPluginInstancesResponse'->new($_) };

declare 'RepeatedListPluginInstancesResponse',
    as ArrayRef[ListPluginInstancesResponse()];

coerce 'RepeatedListPluginInstancesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apihub::V1::PluginService::ListPluginInstancesResponse'->new($_) } @$_ ] };

declare 'MapStringListPluginInstancesResponse',
    as HashRef[ListPluginInstancesResponse()];

declare 'EnablePluginInstanceActionRequest',
    as InstanceOf['Google::Cloud::Apihub::V1::PluginService::EnablePluginInstanceActionRequest'];

coerce 'EnablePluginInstanceActionRequest',
    from HashRef, via { 'Google::Cloud::Apihub::V1::PluginService::EnablePluginInstanceActionRequest'->new($_) };

declare 'RepeatedEnablePluginInstanceActionRequest',
    as ArrayRef[EnablePluginInstanceActionRequest()];

coerce 'RepeatedEnablePluginInstanceActionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apihub::V1::PluginService::EnablePluginInstanceActionRequest'->new($_) } @$_ ] };

declare 'MapStringEnablePluginInstanceActionRequest',
    as HashRef[EnablePluginInstanceActionRequest()];

declare 'EnablePluginInstanceActionResponse',
    as InstanceOf['Google::Cloud::Apihub::V1::PluginService::EnablePluginInstanceActionResponse'];

coerce 'EnablePluginInstanceActionResponse',
    from HashRef, via { 'Google::Cloud::Apihub::V1::PluginService::EnablePluginInstanceActionResponse'->new($_) };

declare 'RepeatedEnablePluginInstanceActionResponse',
    as ArrayRef[EnablePluginInstanceActionResponse()];

coerce 'RepeatedEnablePluginInstanceActionResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apihub::V1::PluginService::EnablePluginInstanceActionResponse'->new($_) } @$_ ] };

declare 'MapStringEnablePluginInstanceActionResponse',
    as HashRef[EnablePluginInstanceActionResponse()];

declare 'DisablePluginInstanceActionRequest',
    as InstanceOf['Google::Cloud::Apihub::V1::PluginService::DisablePluginInstanceActionRequest'];

coerce 'DisablePluginInstanceActionRequest',
    from HashRef, via { 'Google::Cloud::Apihub::V1::PluginService::DisablePluginInstanceActionRequest'->new($_) };

declare 'RepeatedDisablePluginInstanceActionRequest',
    as ArrayRef[DisablePluginInstanceActionRequest()];

coerce 'RepeatedDisablePluginInstanceActionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apihub::V1::PluginService::DisablePluginInstanceActionRequest'->new($_) } @$_ ] };

declare 'MapStringDisablePluginInstanceActionRequest',
    as HashRef[DisablePluginInstanceActionRequest()];

declare 'DisablePluginInstanceActionResponse',
    as InstanceOf['Google::Cloud::Apihub::V1::PluginService::DisablePluginInstanceActionResponse'];

coerce 'DisablePluginInstanceActionResponse',
    from HashRef, via { 'Google::Cloud::Apihub::V1::PluginService::DisablePluginInstanceActionResponse'->new($_) };

declare 'RepeatedDisablePluginInstanceActionResponse',
    as ArrayRef[DisablePluginInstanceActionResponse()];

coerce 'RepeatedDisablePluginInstanceActionResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apihub::V1::PluginService::DisablePluginInstanceActionResponse'->new($_) } @$_ ] };

declare 'MapStringDisablePluginInstanceActionResponse',
    as HashRef[DisablePluginInstanceActionResponse()];

declare 'UpdatePluginInstanceRequest',
    as InstanceOf['Google::Cloud::Apihub::V1::PluginService::UpdatePluginInstanceRequest'];

coerce 'UpdatePluginInstanceRequest',
    from HashRef, via { 'Google::Cloud::Apihub::V1::PluginService::UpdatePluginInstanceRequest'->new($_) };

declare 'RepeatedUpdatePluginInstanceRequest',
    as ArrayRef[UpdatePluginInstanceRequest()];

coerce 'RepeatedUpdatePluginInstanceRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apihub::V1::PluginService::UpdatePluginInstanceRequest'->new($_) } @$_ ] };

declare 'MapStringUpdatePluginInstanceRequest',
    as HashRef[UpdatePluginInstanceRequest()];

declare 'DeletePluginInstanceRequest',
    as InstanceOf['Google::Cloud::Apihub::V1::PluginService::DeletePluginInstanceRequest'];

coerce 'DeletePluginInstanceRequest',
    from HashRef, via { 'Google::Cloud::Apihub::V1::PluginService::DeletePluginInstanceRequest'->new($_) };

declare 'RepeatedDeletePluginInstanceRequest',
    as ArrayRef[DeletePluginInstanceRequest()];

coerce 'RepeatedDeletePluginInstanceRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apihub::V1::PluginService::DeletePluginInstanceRequest'->new($_) } @$_ ] };

declare 'MapStringDeletePluginInstanceRequest',
    as HashRef[DeletePluginInstanceRequest()];

1;

__END__

=head1 NAME

Google::Cloud::Apihub::V1::PluginService::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
