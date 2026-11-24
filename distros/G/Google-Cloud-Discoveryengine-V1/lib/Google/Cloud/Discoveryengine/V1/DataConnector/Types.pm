package Google::Cloud::Discoveryengine::V1::DataConnector::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'ConnectorType',
    as (Int | Str);

declare 'DataConnector',
    as InstanceOf['Google::Cloud::Discoveryengine::V1::DataConnector::DataConnector'];

coerce 'DataConnector',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1::DataConnector::DataConnector'->new($_) };

declare 'RepeatedDataConnector',
    as ArrayRef[DataConnector()];

coerce 'RepeatedDataConnector',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1::DataConnector::DataConnector'->new($_) } @$_ ] };

declare 'MapStringDataConnector',
    as HashRef[DataConnector()];

declare 'State',
    as (Int | Str);

declare 'SyncMode',
    as (Int | Str);

declare 'ConnectorMode',
    as (Int | Str);

declare 'BlockingReason',
    as (Int | Str);

declare 'SourceEntity',
    as InstanceOf['Google::Cloud::Discoveryengine::V1::DataConnector::DataConnector::SourceEntity'];

coerce 'SourceEntity',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1::DataConnector::DataConnector::SourceEntity'->new($_) };

declare 'RepeatedSourceEntity',
    as ArrayRef[SourceEntity()];

coerce 'RepeatedSourceEntity',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1::DataConnector::DataConnector::SourceEntity'->new($_) } @$_ ] };

declare 'MapStringSourceEntity',
    as HashRef[SourceEntity()];

declare 'KeyPropertyMappingsEntry',
    as InstanceOf['Google::Cloud::Discoveryengine::V1::DataConnector::DataConnector::SourceEntity::KeyPropertyMappingsEntry'];

coerce 'KeyPropertyMappingsEntry',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1::DataConnector::DataConnector::SourceEntity::KeyPropertyMappingsEntry'->new($_) };

declare 'RepeatedKeyPropertyMappingsEntry',
    as ArrayRef[KeyPropertyMappingsEntry()];

coerce 'RepeatedKeyPropertyMappingsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1::DataConnector::DataConnector::SourceEntity::KeyPropertyMappingsEntry'->new($_) } @$_ ] };

declare 'MapStringKeyPropertyMappingsEntry',
    as HashRef[KeyPropertyMappingsEntry()];

declare 'EndUserConfig',
    as InstanceOf['Google::Cloud::Discoveryengine::V1::DataConnector::DataConnector::EndUserConfig'];

coerce 'EndUserConfig',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1::DataConnector::DataConnector::EndUserConfig'->new($_) };

declare 'RepeatedEndUserConfig',
    as ArrayRef[EndUserConfig()];

coerce 'RepeatedEndUserConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1::DataConnector::DataConnector::EndUserConfig'->new($_) } @$_ ] };

declare 'MapStringEndUserConfig',
    as HashRef[EndUserConfig()];

declare 'FederatedConfig',
    as InstanceOf['Google::Cloud::Discoveryengine::V1::DataConnector::DataConnector::FederatedConfig'];

coerce 'FederatedConfig',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1::DataConnector::DataConnector::FederatedConfig'->new($_) };

declare 'RepeatedFederatedConfig',
    as ArrayRef[FederatedConfig()];

coerce 'RepeatedFederatedConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1::DataConnector::DataConnector::FederatedConfig'->new($_) } @$_ ] };

declare 'MapStringFederatedConfig',
    as HashRef[FederatedConfig()];

declare 'RealtimeSyncConfig',
    as InstanceOf['Google::Cloud::Discoveryengine::V1::DataConnector::DataConnector::RealtimeSyncConfig'];

coerce 'RealtimeSyncConfig',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1::DataConnector::DataConnector::RealtimeSyncConfig'->new($_) };

declare 'RepeatedRealtimeSyncConfig',
    as ArrayRef[RealtimeSyncConfig()];

coerce 'RepeatedRealtimeSyncConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1::DataConnector::DataConnector::RealtimeSyncConfig'->new($_) } @$_ ] };

declare 'MapStringRealtimeSyncConfig',
    as HashRef[RealtimeSyncConfig()];

declare 'StreamingError',
    as InstanceOf['Google::Cloud::Discoveryengine::V1::DataConnector::DataConnector::RealtimeSyncConfig::StreamingError'];

coerce 'StreamingError',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1::DataConnector::DataConnector::RealtimeSyncConfig::StreamingError'->new($_) };

declare 'RepeatedStreamingError',
    as ArrayRef[StreamingError()];

coerce 'RepeatedStreamingError',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1::DataConnector::DataConnector::RealtimeSyncConfig::StreamingError'->new($_) } @$_ ] };

declare 'MapStringStreamingError',
    as HashRef[StreamingError()];

declare 'StreamingErrorReason',
    as (Int | Str);

declare 'ConnectorMetadata',
    as InstanceOf['Google::Cloud::Discoveryengine::V1::DataConnector::DataConnector::ConnectorMetadata'];

coerce 'ConnectorMetadata',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1::DataConnector::DataConnector::ConnectorMetadata'->new($_) };

declare 'RepeatedConnectorMetadata',
    as ArrayRef[ConnectorMetadata()];

coerce 'RepeatedConnectorMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1::DataConnector::DataConnector::ConnectorMetadata'->new($_) } @$_ ] };

declare 'MapStringConnectorMetadata',
    as HashRef[ConnectorMetadata()];

declare 'DestinationConfig',
    as InstanceOf['Google::Cloud::Discoveryengine::V1::DataConnector::DestinationConfig'];

coerce 'DestinationConfig',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1::DataConnector::DestinationConfig'->new($_) };

declare 'RepeatedDestinationConfig',
    as ArrayRef[DestinationConfig()];

coerce 'RepeatedDestinationConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1::DataConnector::DestinationConfig'->new($_) } @$_ ] };

declare 'MapStringDestinationConfig',
    as HashRef[DestinationConfig()];

declare 'Destination',
    as InstanceOf['Google::Cloud::Discoveryengine::V1::DataConnector::DestinationConfig::Destination'];

coerce 'Destination',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1::DataConnector::DestinationConfig::Destination'->new($_) };

declare 'RepeatedDestination',
    as ArrayRef[Destination()];

coerce 'RepeatedDestination',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1::DataConnector::DestinationConfig::Destination'->new($_) } @$_ ] };

declare 'MapStringDestination',
    as HashRef[Destination()];

declare 'ActionConfig',
    as InstanceOf['Google::Cloud::Discoveryengine::V1::DataConnector::ActionConfig'];

coerce 'ActionConfig',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1::DataConnector::ActionConfig'->new($_) };

declare 'RepeatedActionConfig',
    as ArrayRef[ActionConfig()];

coerce 'RepeatedActionConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1::DataConnector::ActionConfig'->new($_) } @$_ ] };

declare 'MapStringActionConfig',
    as HashRef[ActionConfig()];

declare 'ScopeList',
    as InstanceOf['Google::Cloud::Discoveryengine::V1::DataConnector::ActionConfig::ScopeList'];

coerce 'ScopeList',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1::DataConnector::ActionConfig::ScopeList'->new($_) };

declare 'RepeatedScopeList',
    as ArrayRef[ScopeList()];

coerce 'RepeatedScopeList',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1::DataConnector::ActionConfig::ScopeList'->new($_) } @$_ ] };

declare 'MapStringScopeList',
    as HashRef[ScopeList()];

declare 'UserDefinedScopesMappingEntry',
    as InstanceOf['Google::Cloud::Discoveryengine::V1::DataConnector::ActionConfig::UserDefinedScopesMappingEntry'];

coerce 'UserDefinedScopesMappingEntry',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1::DataConnector::ActionConfig::UserDefinedScopesMappingEntry'->new($_) };

declare 'RepeatedUserDefinedScopesMappingEntry',
    as ArrayRef[UserDefinedScopesMappingEntry()];

coerce 'RepeatedUserDefinedScopesMappingEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1::DataConnector::ActionConfig::UserDefinedScopesMappingEntry'->new($_) } @$_ ] };

declare 'MapStringUserDefinedScopesMappingEntry',
    as HashRef[UserDefinedScopesMappingEntry()];

declare 'IdentityScheduleConfig',
    as InstanceOf['Google::Cloud::Discoveryengine::V1::DataConnector::IdentityScheduleConfig'];

coerce 'IdentityScheduleConfig',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1::DataConnector::IdentityScheduleConfig'->new($_) };

declare 'RepeatedIdentityScheduleConfig',
    as ArrayRef[IdentityScheduleConfig()];

coerce 'RepeatedIdentityScheduleConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1::DataConnector::IdentityScheduleConfig'->new($_) } @$_ ] };

declare 'MapStringIdentityScheduleConfig',
    as HashRef[IdentityScheduleConfig()];

declare 'BAPConfig',
    as InstanceOf['Google::Cloud::Discoveryengine::V1::DataConnector::BAPConfig'];

coerce 'BAPConfig',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1::DataConnector::BAPConfig'->new($_) };

declare 'RepeatedBAPConfig',
    as ArrayRef[BAPConfig()];

coerce 'RepeatedBAPConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1::DataConnector::BAPConfig'->new($_) } @$_ ] };

declare 'MapStringBAPConfig',
    as HashRef[BAPConfig()];

declare 'ConnectorMode',
    as (Int | Str);

declare 'ToolspecOverride',
    as InstanceOf['Google::Cloud::Discoveryengine::V1::DataConnector::BAPConfig::ToolspecOverride'];

coerce 'ToolspecOverride',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1::DataConnector::BAPConfig::ToolspecOverride'->new($_) };

declare 'RepeatedToolspecOverride',
    as ArrayRef[ToolspecOverride()];

coerce 'RepeatedToolspecOverride',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1::DataConnector::BAPConfig::ToolspecOverride'->new($_) } @$_ ] };

declare 'MapStringToolspecOverride',
    as HashRef[ToolspecOverride()];

declare 'CliConfig',
    as InstanceOf['Google::Cloud::Discoveryengine::V1::DataConnector::CliConfig'];

coerce 'CliConfig',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1::DataConnector::CliConfig'->new($_) };

declare 'RepeatedCliConfig',
    as ArrayRef[CliConfig()];

coerce 'RepeatedCliConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1::DataConnector::CliConfig'->new($_) } @$_ ] };

declare 'MapStringCliConfig',
    as HashRef[CliConfig()];

declare 'AlertPolicyConfig',
    as InstanceOf['Google::Cloud::Discoveryengine::V1::DataConnector::AlertPolicyConfig'];

coerce 'AlertPolicyConfig',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1::DataConnector::AlertPolicyConfig'->new($_) };

declare 'RepeatedAlertPolicyConfig',
    as ArrayRef[AlertPolicyConfig()];

coerce 'RepeatedAlertPolicyConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1::DataConnector::AlertPolicyConfig'->new($_) } @$_ ] };

declare 'MapStringAlertPolicyConfig',
    as HashRef[AlertPolicyConfig()];

declare 'AlertEnrollment',
    as InstanceOf['Google::Cloud::Discoveryengine::V1::DataConnector::AlertPolicyConfig::AlertEnrollment'];

coerce 'AlertEnrollment',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1::DataConnector::AlertPolicyConfig::AlertEnrollment'->new($_) };

declare 'RepeatedAlertEnrollment',
    as ArrayRef[AlertEnrollment()];

coerce 'RepeatedAlertEnrollment',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1::DataConnector::AlertPolicyConfig::AlertEnrollment'->new($_) } @$_ ] };

declare 'MapStringAlertEnrollment',
    as HashRef[AlertEnrollment()];

declare 'EnrollStates',
    as (Int | Str);

declare 'Tenant',
    as InstanceOf['Google::Cloud::Discoveryengine::V1::DataConnector::Tenant'];

coerce 'Tenant',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1::DataConnector::Tenant'->new($_) };

declare 'RepeatedTenant',
    as ArrayRef[Tenant()];

coerce 'RepeatedTenant',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1::DataConnector::Tenant'->new($_) } @$_ ] };

declare 'MapStringTenant',
    as HashRef[Tenant()];

declare 'DynamicTool',
    as InstanceOf['Google::Cloud::Discoveryengine::V1::DataConnector::DynamicTool'];

coerce 'DynamicTool',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1::DataConnector::DynamicTool'->new($_) };

declare 'RepeatedDynamicTool',
    as ArrayRef[DynamicTool()];

coerce 'RepeatedDynamicTool',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1::DataConnector::DynamicTool'->new($_) } @$_ ] };

declare 'MapStringDynamicTool',
    as HashRef[DynamicTool()];

1;

__END__

=head1 NAME

Google::Cloud::Discoveryengine::V1::DataConnector::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
