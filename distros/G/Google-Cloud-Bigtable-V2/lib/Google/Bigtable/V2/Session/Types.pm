package Google::Bigtable::V2::Session::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'SessionType',
    as (Int | Str);

declare 'GetClientConfigurationRequest',
    as InstanceOf['Google::Bigtable::V2::Session::GetClientConfigurationRequest'];

coerce 'GetClientConfigurationRequest',
    from HashRef, via { 'Google::Bigtable::V2::Session::GetClientConfigurationRequest'->new($_) };

declare 'RepeatedGetClientConfigurationRequest',
    as ArrayRef[GetClientConfigurationRequest()];

coerce 'RepeatedGetClientConfigurationRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::V2::Session::GetClientConfigurationRequest'->new($_) } @$_ ] };

declare 'MapStringGetClientConfigurationRequest',
    as HashRef[GetClientConfigurationRequest()];

declare 'LoadBalancingOptions',
    as InstanceOf['Google::Bigtable::V2::Session::LoadBalancingOptions'];

coerce 'LoadBalancingOptions',
    from HashRef, via { 'Google::Bigtable::V2::Session::LoadBalancingOptions'->new($_) };

declare 'RepeatedLoadBalancingOptions',
    as ArrayRef[LoadBalancingOptions()];

coerce 'RepeatedLoadBalancingOptions',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::V2::Session::LoadBalancingOptions'->new($_) } @$_ ] };

declare 'MapStringLoadBalancingOptions',
    as HashRef[LoadBalancingOptions()];

declare 'LeastInFlight',
    as InstanceOf['Google::Bigtable::V2::Session::LoadBalancingOptions::LeastInFlight'];

coerce 'LeastInFlight',
    from HashRef, via { 'Google::Bigtable::V2::Session::LoadBalancingOptions::LeastInFlight'->new($_) };

declare 'RepeatedLeastInFlight',
    as ArrayRef[LeastInFlight()];

coerce 'RepeatedLeastInFlight',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::V2::Session::LoadBalancingOptions::LeastInFlight'->new($_) } @$_ ] };

declare 'MapStringLeastInFlight',
    as HashRef[LeastInFlight()];

declare 'PeakEwma',
    as InstanceOf['Google::Bigtable::V2::Session::LoadBalancingOptions::PeakEwma'];

coerce 'PeakEwma',
    from HashRef, via { 'Google::Bigtable::V2::Session::LoadBalancingOptions::PeakEwma'->new($_) };

declare 'RepeatedPeakEwma',
    as ArrayRef[PeakEwma()];

coerce 'RepeatedPeakEwma',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::V2::Session::LoadBalancingOptions::PeakEwma'->new($_) } @$_ ] };

declare 'MapStringPeakEwma',
    as HashRef[PeakEwma()];

declare 'Random',
    as InstanceOf['Google::Bigtable::V2::Session::LoadBalancingOptions::Random'];

coerce 'Random',
    from HashRef, via { 'Google::Bigtable::V2::Session::LoadBalancingOptions::Random'->new($_) };

declare 'RepeatedRandom',
    as ArrayRef[Random()];

coerce 'RepeatedRandom',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::V2::Session::LoadBalancingOptions::Random'->new($_) } @$_ ] };

declare 'MapStringRandom',
    as HashRef[Random()];

declare 'SessionScopeDiversionConfiguration',
    as InstanceOf['Google::Bigtable::V2::Session::SessionScopeDiversionConfiguration'];

coerce 'SessionScopeDiversionConfiguration',
    from HashRef, via { 'Google::Bigtable::V2::Session::SessionScopeDiversionConfiguration'->new($_) };

declare 'RepeatedSessionScopeDiversionConfiguration',
    as ArrayRef[SessionScopeDiversionConfiguration()];

coerce 'RepeatedSessionScopeDiversionConfiguration',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::V2::Session::SessionScopeDiversionConfiguration'->new($_) } @$_ ] };

declare 'MapStringSessionScopeDiversionConfiguration',
    as HashRef[SessionScopeDiversionConfiguration()];

declare 'SessionDiversionConfiguration',
    as InstanceOf['Google::Bigtable::V2::Session::SessionDiversionConfiguration'];

coerce 'SessionDiversionConfiguration',
    from HashRef, via { 'Google::Bigtable::V2::Session::SessionDiversionConfiguration'->new($_) };

declare 'RepeatedSessionDiversionConfiguration',
    as ArrayRef[SessionDiversionConfiguration()];

coerce 'RepeatedSessionDiversionConfiguration',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::V2::Session::SessionDiversionConfiguration'->new($_) } @$_ ] };

declare 'MapStringSessionDiversionConfiguration',
    as HashRef[SessionDiversionConfiguration()];

declare 'PerScopeDiversion',
    as InstanceOf['Google::Bigtable::V2::Session::SessionDiversionConfiguration::PerScopeDiversion'];

coerce 'PerScopeDiversion',
    from HashRef, via { 'Google::Bigtable::V2::Session::SessionDiversionConfiguration::PerScopeDiversion'->new($_) };

declare 'RepeatedPerScopeDiversion',
    as ArrayRef[PerScopeDiversion()];

coerce 'RepeatedPerScopeDiversion',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::V2::Session::SessionDiversionConfiguration::PerScopeDiversion'->new($_) } @$_ ] };

declare 'MapStringPerScopeDiversion',
    as HashRef[PerScopeDiversion()];

declare 'ScopeDiversionsEntry',
    as InstanceOf['Google::Bigtable::V2::Session::SessionDiversionConfiguration::PerScopeDiversion::ScopeDiversionsEntry'];

coerce 'ScopeDiversionsEntry',
    from HashRef, via { 'Google::Bigtable::V2::Session::SessionDiversionConfiguration::PerScopeDiversion::ScopeDiversionsEntry'->new($_) };

declare 'RepeatedScopeDiversionsEntry',
    as ArrayRef[ScopeDiversionsEntry()];

coerce 'RepeatedScopeDiversionsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::V2::Session::SessionDiversionConfiguration::PerScopeDiversion::ScopeDiversionsEntry'->new($_) } @$_ ] };

declare 'MapStringScopeDiversionsEntry',
    as HashRef[ScopeDiversionsEntry()];

declare 'SessionClientConfiguration',
    as InstanceOf['Google::Bigtable::V2::Session::SessionClientConfiguration'];

coerce 'SessionClientConfiguration',
    from HashRef, via { 'Google::Bigtable::V2::Session::SessionClientConfiguration'->new($_) };

declare 'RepeatedSessionClientConfiguration',
    as ArrayRef[SessionClientConfiguration()];

coerce 'RepeatedSessionClientConfiguration',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::V2::Session::SessionClientConfiguration'->new($_) } @$_ ] };

declare 'MapStringSessionClientConfiguration',
    as HashRef[SessionClientConfiguration()];

declare 'ChannelPoolConfiguration',
    as InstanceOf['Google::Bigtable::V2::Session::SessionClientConfiguration::ChannelPoolConfiguration'];

coerce 'ChannelPoolConfiguration',
    from HashRef, via { 'Google::Bigtable::V2::Session::SessionClientConfiguration::ChannelPoolConfiguration'->new($_) };

declare 'RepeatedChannelPoolConfiguration',
    as ArrayRef[ChannelPoolConfiguration()];

coerce 'RepeatedChannelPoolConfiguration',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::V2::Session::SessionClientConfiguration::ChannelPoolConfiguration'->new($_) } @$_ ] };

declare 'MapStringChannelPoolConfiguration',
    as HashRef[ChannelPoolConfiguration()];

declare 'DirectAccessWithFallback',
    as InstanceOf['Google::Bigtable::V2::Session::SessionClientConfiguration::ChannelPoolConfiguration::DirectAccessWithFallback'];

coerce 'DirectAccessWithFallback',
    from HashRef, via { 'Google::Bigtable::V2::Session::SessionClientConfiguration::ChannelPoolConfiguration::DirectAccessWithFallback'->new($_) };

declare 'RepeatedDirectAccessWithFallback',
    as ArrayRef[DirectAccessWithFallback()];

coerce 'RepeatedDirectAccessWithFallback',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::V2::Session::SessionClientConfiguration::ChannelPoolConfiguration::DirectAccessWithFallback'->new($_) } @$_ ] };

declare 'MapStringDirectAccessWithFallback',
    as HashRef[DirectAccessWithFallback()];

declare 'DirectAccessOnly',
    as InstanceOf['Google::Bigtable::V2::Session::SessionClientConfiguration::ChannelPoolConfiguration::DirectAccessOnly'];

coerce 'DirectAccessOnly',
    from HashRef, via { 'Google::Bigtable::V2::Session::SessionClientConfiguration::ChannelPoolConfiguration::DirectAccessOnly'->new($_) };

declare 'RepeatedDirectAccessOnly',
    as ArrayRef[DirectAccessOnly()];

coerce 'RepeatedDirectAccessOnly',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::V2::Session::SessionClientConfiguration::ChannelPoolConfiguration::DirectAccessOnly'->new($_) } @$_ ] };

declare 'MapStringDirectAccessOnly',
    as HashRef[DirectAccessOnly()];

declare 'CloudPathOnly',
    as InstanceOf['Google::Bigtable::V2::Session::SessionClientConfiguration::ChannelPoolConfiguration::CloudPathOnly'];

coerce 'CloudPathOnly',
    from HashRef, via { 'Google::Bigtable::V2::Session::SessionClientConfiguration::ChannelPoolConfiguration::CloudPathOnly'->new($_) };

declare 'RepeatedCloudPathOnly',
    as ArrayRef[CloudPathOnly()];

coerce 'RepeatedCloudPathOnly',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::V2::Session::SessionClientConfiguration::ChannelPoolConfiguration::CloudPathOnly'->new($_) } @$_ ] };

declare 'MapStringCloudPathOnly',
    as HashRef[CloudPathOnly()];

declare 'SessionPoolConfiguration',
    as InstanceOf['Google::Bigtable::V2::Session::SessionClientConfiguration::SessionPoolConfiguration'];

coerce 'SessionPoolConfiguration',
    from HashRef, via { 'Google::Bigtable::V2::Session::SessionClientConfiguration::SessionPoolConfiguration'->new($_) };

declare 'RepeatedSessionPoolConfiguration',
    as ArrayRef[SessionPoolConfiguration()];

coerce 'RepeatedSessionPoolConfiguration',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::V2::Session::SessionClientConfiguration::SessionPoolConfiguration'->new($_) } @$_ ] };

declare 'MapStringSessionPoolConfiguration',
    as HashRef[SessionPoolConfiguration()];

declare 'TelemetryConfiguration',
    as InstanceOf['Google::Bigtable::V2::Session::TelemetryConfiguration'];

coerce 'TelemetryConfiguration',
    from HashRef, via { 'Google::Bigtable::V2::Session::TelemetryConfiguration'->new($_) };

declare 'RepeatedTelemetryConfiguration',
    as ArrayRef[TelemetryConfiguration()];

coerce 'RepeatedTelemetryConfiguration',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::V2::Session::TelemetryConfiguration'->new($_) } @$_ ] };

declare 'MapStringTelemetryConfiguration',
    as HashRef[TelemetryConfiguration()];

declare 'Level',
    as (Int | Str);

declare 'ClientConfiguration',
    as InstanceOf['Google::Bigtable::V2::Session::ClientConfiguration'];

coerce 'ClientConfiguration',
    from HashRef, via { 'Google::Bigtable::V2::Session::ClientConfiguration'->new($_) };

declare 'RepeatedClientConfiguration',
    as ArrayRef[ClientConfiguration()];

coerce 'RepeatedClientConfiguration',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::V2::Session::ClientConfiguration'->new($_) } @$_ ] };

declare 'MapStringClientConfiguration',
    as HashRef[ClientConfiguration()];

declare 'PollingConfiguration',
    as InstanceOf['Google::Bigtable::V2::Session::ClientConfiguration::PollingConfiguration'];

coerce 'PollingConfiguration',
    from HashRef, via { 'Google::Bigtable::V2::Session::ClientConfiguration::PollingConfiguration'->new($_) };

declare 'RepeatedPollingConfiguration',
    as ArrayRef[PollingConfiguration()];

coerce 'RepeatedPollingConfiguration',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::V2::Session::ClientConfiguration::PollingConfiguration'->new($_) } @$_ ] };

declare 'MapStringPollingConfiguration',
    as HashRef[PollingConfiguration()];

declare 'SessionRequest',
    as InstanceOf['Google::Bigtable::V2::Session::SessionRequest'];

coerce 'SessionRequest',
    from HashRef, via { 'Google::Bigtable::V2::Session::SessionRequest'->new($_) };

declare 'RepeatedSessionRequest',
    as ArrayRef[SessionRequest()];

coerce 'RepeatedSessionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::V2::Session::SessionRequest'->new($_) } @$_ ] };

declare 'MapStringSessionRequest',
    as HashRef[SessionRequest()];

declare 'SessionResponse',
    as InstanceOf['Google::Bigtable::V2::Session::SessionResponse'];

coerce 'SessionResponse',
    from HashRef, via { 'Google::Bigtable::V2::Session::SessionResponse'->new($_) };

declare 'RepeatedSessionResponse',
    as ArrayRef[SessionResponse()];

coerce 'RepeatedSessionResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::V2::Session::SessionResponse'->new($_) } @$_ ] };

declare 'MapStringSessionResponse',
    as HashRef[SessionResponse()];

declare 'OpenSessionRequest',
    as InstanceOf['Google::Bigtable::V2::Session::OpenSessionRequest'];

coerce 'OpenSessionRequest',
    from HashRef, via { 'Google::Bigtable::V2::Session::OpenSessionRequest'->new($_) };

declare 'RepeatedOpenSessionRequest',
    as ArrayRef[OpenSessionRequest()];

coerce 'RepeatedOpenSessionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::V2::Session::OpenSessionRequest'->new($_) } @$_ ] };

declare 'MapStringOpenSessionRequest',
    as HashRef[OpenSessionRequest()];

declare 'BackendIdentifier',
    as InstanceOf['Google::Bigtable::V2::Session::BackendIdentifier'];

coerce 'BackendIdentifier',
    from HashRef, via { 'Google::Bigtable::V2::Session::BackendIdentifier'->new($_) };

declare 'RepeatedBackendIdentifier',
    as ArrayRef[BackendIdentifier()];

coerce 'RepeatedBackendIdentifier',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::V2::Session::BackendIdentifier'->new($_) } @$_ ] };

declare 'MapStringBackendIdentifier',
    as HashRef[BackendIdentifier()];

declare 'OpenSessionResponse',
    as InstanceOf['Google::Bigtable::V2::Session::OpenSessionResponse'];

coerce 'OpenSessionResponse',
    from HashRef, via { 'Google::Bigtable::V2::Session::OpenSessionResponse'->new($_) };

declare 'RepeatedOpenSessionResponse',
    as ArrayRef[OpenSessionResponse()];

coerce 'RepeatedOpenSessionResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::V2::Session::OpenSessionResponse'->new($_) } @$_ ] };

declare 'MapStringOpenSessionResponse',
    as HashRef[OpenSessionResponse()];

declare 'CloseSessionRequest',
    as InstanceOf['Google::Bigtable::V2::Session::CloseSessionRequest'];

coerce 'CloseSessionRequest',
    from HashRef, via { 'Google::Bigtable::V2::Session::CloseSessionRequest'->new($_) };

declare 'RepeatedCloseSessionRequest',
    as ArrayRef[CloseSessionRequest()];

coerce 'RepeatedCloseSessionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::V2::Session::CloseSessionRequest'->new($_) } @$_ ] };

declare 'MapStringCloseSessionRequest',
    as HashRef[CloseSessionRequest()];

declare 'CloseSessionReason',
    as (Int | Str);

declare 'OpenTableRequest',
    as InstanceOf['Google::Bigtable::V2::Session::OpenTableRequest'];

coerce 'OpenTableRequest',
    from HashRef, via { 'Google::Bigtable::V2::Session::OpenTableRequest'->new($_) };

declare 'RepeatedOpenTableRequest',
    as ArrayRef[OpenTableRequest()];

coerce 'RepeatedOpenTableRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::V2::Session::OpenTableRequest'->new($_) } @$_ ] };

declare 'MapStringOpenTableRequest',
    as HashRef[OpenTableRequest()];

declare 'Permission',
    as (Int | Str);

declare 'OpenTableResponse',
    as InstanceOf['Google::Bigtable::V2::Session::OpenTableResponse'];

coerce 'OpenTableResponse',
    from HashRef, via { 'Google::Bigtable::V2::Session::OpenTableResponse'->new($_) };

declare 'RepeatedOpenTableResponse',
    as ArrayRef[OpenTableResponse()];

coerce 'RepeatedOpenTableResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::V2::Session::OpenTableResponse'->new($_) } @$_ ] };

declare 'MapStringOpenTableResponse',
    as HashRef[OpenTableResponse()];

declare 'OpenAuthorizedViewRequest',
    as InstanceOf['Google::Bigtable::V2::Session::OpenAuthorizedViewRequest'];

coerce 'OpenAuthorizedViewRequest',
    from HashRef, via { 'Google::Bigtable::V2::Session::OpenAuthorizedViewRequest'->new($_) };

declare 'RepeatedOpenAuthorizedViewRequest',
    as ArrayRef[OpenAuthorizedViewRequest()];

coerce 'RepeatedOpenAuthorizedViewRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::V2::Session::OpenAuthorizedViewRequest'->new($_) } @$_ ] };

declare 'MapStringOpenAuthorizedViewRequest',
    as HashRef[OpenAuthorizedViewRequest()];

declare 'Permission',
    as (Int | Str);

declare 'OpenAuthorizedViewResponse',
    as InstanceOf['Google::Bigtable::V2::Session::OpenAuthorizedViewResponse'];

coerce 'OpenAuthorizedViewResponse',
    from HashRef, via { 'Google::Bigtable::V2::Session::OpenAuthorizedViewResponse'->new($_) };

declare 'RepeatedOpenAuthorizedViewResponse',
    as ArrayRef[OpenAuthorizedViewResponse()];

coerce 'RepeatedOpenAuthorizedViewResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::V2::Session::OpenAuthorizedViewResponse'->new($_) } @$_ ] };

declare 'MapStringOpenAuthorizedViewResponse',
    as HashRef[OpenAuthorizedViewResponse()];

declare 'OpenMaterializedViewRequest',
    as InstanceOf['Google::Bigtable::V2::Session::OpenMaterializedViewRequest'];

coerce 'OpenMaterializedViewRequest',
    from HashRef, via { 'Google::Bigtable::V2::Session::OpenMaterializedViewRequest'->new($_) };

declare 'RepeatedOpenMaterializedViewRequest',
    as ArrayRef[OpenMaterializedViewRequest()];

coerce 'RepeatedOpenMaterializedViewRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::V2::Session::OpenMaterializedViewRequest'->new($_) } @$_ ] };

declare 'MapStringOpenMaterializedViewRequest',
    as HashRef[OpenMaterializedViewRequest()];

declare 'Permission',
    as (Int | Str);

declare 'OpenMaterializedViewResponse',
    as InstanceOf['Google::Bigtable::V2::Session::OpenMaterializedViewResponse'];

coerce 'OpenMaterializedViewResponse',
    from HashRef, via { 'Google::Bigtable::V2::Session::OpenMaterializedViewResponse'->new($_) };

declare 'RepeatedOpenMaterializedViewResponse',
    as ArrayRef[OpenMaterializedViewResponse()];

coerce 'RepeatedOpenMaterializedViewResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::V2::Session::OpenMaterializedViewResponse'->new($_) } @$_ ] };

declare 'MapStringOpenMaterializedViewResponse',
    as HashRef[OpenMaterializedViewResponse()];

declare 'VirtualRpcRequest',
    as InstanceOf['Google::Bigtable::V2::Session::VirtualRpcRequest'];

coerce 'VirtualRpcRequest',
    from HashRef, via { 'Google::Bigtable::V2::Session::VirtualRpcRequest'->new($_) };

declare 'RepeatedVirtualRpcRequest',
    as ArrayRef[VirtualRpcRequest()];

coerce 'RepeatedVirtualRpcRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::V2::Session::VirtualRpcRequest'->new($_) } @$_ ] };

declare 'MapStringVirtualRpcRequest',
    as HashRef[VirtualRpcRequest()];

declare 'Metadata',
    as InstanceOf['Google::Bigtable::V2::Session::VirtualRpcRequest::Metadata'];

coerce 'Metadata',
    from HashRef, via { 'Google::Bigtable::V2::Session::VirtualRpcRequest::Metadata'->new($_) };

declare 'RepeatedMetadata',
    as ArrayRef[Metadata()];

coerce 'RepeatedMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::V2::Session::VirtualRpcRequest::Metadata'->new($_) } @$_ ] };

declare 'MapStringMetadata',
    as HashRef[Metadata()];

declare 'ContinueVirtualRpcRequest',
    as InstanceOf['Google::Bigtable::V2::Session::ContinueVirtualRpcRequest'];

coerce 'ContinueVirtualRpcRequest',
    from HashRef, via { 'Google::Bigtable::V2::Session::ContinueVirtualRpcRequest'->new($_) };

declare 'RepeatedContinueVirtualRpcRequest',
    as ArrayRef[ContinueVirtualRpcRequest()];

coerce 'RepeatedContinueVirtualRpcRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::V2::Session::ContinueVirtualRpcRequest'->new($_) } @$_ ] };

declare 'MapStringContinueVirtualRpcRequest',
    as HashRef[ContinueVirtualRpcRequest()];

declare 'CancelVirtualRpcRequest',
    as InstanceOf['Google::Bigtable::V2::Session::CancelVirtualRpcRequest'];

coerce 'CancelVirtualRpcRequest',
    from HashRef, via { 'Google::Bigtable::V2::Session::CancelVirtualRpcRequest'->new($_) };

declare 'RepeatedCancelVirtualRpcRequest',
    as ArrayRef[CancelVirtualRpcRequest()];

coerce 'RepeatedCancelVirtualRpcRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::V2::Session::CancelVirtualRpcRequest'->new($_) } @$_ ] };

declare 'MapStringCancelVirtualRpcRequest',
    as HashRef[CancelVirtualRpcRequest()];

declare 'ClusterInformation',
    as InstanceOf['Google::Bigtable::V2::Session::ClusterInformation'];

coerce 'ClusterInformation',
    from HashRef, via { 'Google::Bigtable::V2::Session::ClusterInformation'->new($_) };

declare 'RepeatedClusterInformation',
    as ArrayRef[ClusterInformation()];

coerce 'RepeatedClusterInformation',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::V2::Session::ClusterInformation'->new($_) } @$_ ] };

declare 'MapStringClusterInformation',
    as HashRef[ClusterInformation()];

declare 'SessionRequestStats',
    as InstanceOf['Google::Bigtable::V2::Session::SessionRequestStats'];

coerce 'SessionRequestStats',
    from HashRef, via { 'Google::Bigtable::V2::Session::SessionRequestStats'->new($_) };

declare 'RepeatedSessionRequestStats',
    as ArrayRef[SessionRequestStats()];

coerce 'RepeatedSessionRequestStats',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::V2::Session::SessionRequestStats'->new($_) } @$_ ] };

declare 'MapStringSessionRequestStats',
    as HashRef[SessionRequestStats()];

declare 'VirtualRpcResponse',
    as InstanceOf['Google::Bigtable::V2::Session::VirtualRpcResponse'];

coerce 'VirtualRpcResponse',
    from HashRef, via { 'Google::Bigtable::V2::Session::VirtualRpcResponse'->new($_) };

declare 'RepeatedVirtualRpcResponse',
    as ArrayRef[VirtualRpcResponse()];

coerce 'RepeatedVirtualRpcResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::V2::Session::VirtualRpcResponse'->new($_) } @$_ ] };

declare 'MapStringVirtualRpcResponse',
    as HashRef[VirtualRpcResponse()];

declare 'ErrorResponse',
    as InstanceOf['Google::Bigtable::V2::Session::ErrorResponse'];

coerce 'ErrorResponse',
    from HashRef, via { 'Google::Bigtable::V2::Session::ErrorResponse'->new($_) };

declare 'RepeatedErrorResponse',
    as ArrayRef[ErrorResponse()];

coerce 'RepeatedErrorResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::V2::Session::ErrorResponse'->new($_) } @$_ ] };

declare 'MapStringErrorResponse',
    as HashRef[ErrorResponse()];

declare 'TableRequest',
    as InstanceOf['Google::Bigtable::V2::Session::TableRequest'];

coerce 'TableRequest',
    from HashRef, via { 'Google::Bigtable::V2::Session::TableRequest'->new($_) };

declare 'RepeatedTableRequest',
    as ArrayRef[TableRequest()];

coerce 'RepeatedTableRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::V2::Session::TableRequest'->new($_) } @$_ ] };

declare 'MapStringTableRequest',
    as HashRef[TableRequest()];

declare 'TableResponse',
    as InstanceOf['Google::Bigtable::V2::Session::TableResponse'];

coerce 'TableResponse',
    from HashRef, via { 'Google::Bigtable::V2::Session::TableResponse'->new($_) };

declare 'RepeatedTableResponse',
    as ArrayRef[TableResponse()];

coerce 'RepeatedTableResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::V2::Session::TableResponse'->new($_) } @$_ ] };

declare 'MapStringTableResponse',
    as HashRef[TableResponse()];

declare 'AuthorizedViewRequest',
    as InstanceOf['Google::Bigtable::V2::Session::AuthorizedViewRequest'];

coerce 'AuthorizedViewRequest',
    from HashRef, via { 'Google::Bigtable::V2::Session::AuthorizedViewRequest'->new($_) };

declare 'RepeatedAuthorizedViewRequest',
    as ArrayRef[AuthorizedViewRequest()];

coerce 'RepeatedAuthorizedViewRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::V2::Session::AuthorizedViewRequest'->new($_) } @$_ ] };

declare 'MapStringAuthorizedViewRequest',
    as HashRef[AuthorizedViewRequest()];

declare 'AuthorizedViewResponse',
    as InstanceOf['Google::Bigtable::V2::Session::AuthorizedViewResponse'];

coerce 'AuthorizedViewResponse',
    from HashRef, via { 'Google::Bigtable::V2::Session::AuthorizedViewResponse'->new($_) };

declare 'RepeatedAuthorizedViewResponse',
    as ArrayRef[AuthorizedViewResponse()];

coerce 'RepeatedAuthorizedViewResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::V2::Session::AuthorizedViewResponse'->new($_) } @$_ ] };

declare 'MapStringAuthorizedViewResponse',
    as HashRef[AuthorizedViewResponse()];

declare 'MaterializedViewRequest',
    as InstanceOf['Google::Bigtable::V2::Session::MaterializedViewRequest'];

coerce 'MaterializedViewRequest',
    from HashRef, via { 'Google::Bigtable::V2::Session::MaterializedViewRequest'->new($_) };

declare 'RepeatedMaterializedViewRequest',
    as ArrayRef[MaterializedViewRequest()];

coerce 'RepeatedMaterializedViewRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::V2::Session::MaterializedViewRequest'->new($_) } @$_ ] };

declare 'MapStringMaterializedViewRequest',
    as HashRef[MaterializedViewRequest()];

declare 'MaterializedViewResponse',
    as InstanceOf['Google::Bigtable::V2::Session::MaterializedViewResponse'];

coerce 'MaterializedViewResponse',
    from HashRef, via { 'Google::Bigtable::V2::Session::MaterializedViewResponse'->new($_) };

declare 'RepeatedMaterializedViewResponse',
    as ArrayRef[MaterializedViewResponse()];

coerce 'RepeatedMaterializedViewResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::V2::Session::MaterializedViewResponse'->new($_) } @$_ ] };

declare 'MapStringMaterializedViewResponse',
    as HashRef[MaterializedViewResponse()];

declare 'SessionReadRowRequest',
    as InstanceOf['Google::Bigtable::V2::Session::SessionReadRowRequest'];

coerce 'SessionReadRowRequest',
    from HashRef, via { 'Google::Bigtable::V2::Session::SessionReadRowRequest'->new($_) };

declare 'RepeatedSessionReadRowRequest',
    as ArrayRef[SessionReadRowRequest()];

coerce 'RepeatedSessionReadRowRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::V2::Session::SessionReadRowRequest'->new($_) } @$_ ] };

declare 'MapStringSessionReadRowRequest',
    as HashRef[SessionReadRowRequest()];

declare 'SessionReadRowResponse',
    as InstanceOf['Google::Bigtable::V2::Session::SessionReadRowResponse'];

coerce 'SessionReadRowResponse',
    from HashRef, via { 'Google::Bigtable::V2::Session::SessionReadRowResponse'->new($_) };

declare 'RepeatedSessionReadRowResponse',
    as ArrayRef[SessionReadRowResponse()];

coerce 'RepeatedSessionReadRowResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::V2::Session::SessionReadRowResponse'->new($_) } @$_ ] };

declare 'MapStringSessionReadRowResponse',
    as HashRef[SessionReadRowResponse()];

declare 'SessionReadRowsRequest',
    as InstanceOf['Google::Bigtable::V2::Session::SessionReadRowsRequest'];

coerce 'SessionReadRowsRequest',
    from HashRef, via { 'Google::Bigtable::V2::Session::SessionReadRowsRequest'->new($_) };

declare 'RepeatedSessionReadRowsRequest',
    as ArrayRef[SessionReadRowsRequest()];

coerce 'RepeatedSessionReadRowsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::V2::Session::SessionReadRowsRequest'->new($_) } @$_ ] };

declare 'MapStringSessionReadRowsRequest',
    as HashRef[SessionReadRowsRequest()];

declare 'SessionReadRowsResponse',
    as InstanceOf['Google::Bigtable::V2::Session::SessionReadRowsResponse'];

coerce 'SessionReadRowsResponse',
    from HashRef, via { 'Google::Bigtable::V2::Session::SessionReadRowsResponse'->new($_) };

declare 'RepeatedSessionReadRowsResponse',
    as ArrayRef[SessionReadRowsResponse()];

coerce 'RepeatedSessionReadRowsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::V2::Session::SessionReadRowsResponse'->new($_) } @$_ ] };

declare 'MapStringSessionReadRowsResponse',
    as HashRef[SessionReadRowsResponse()];

declare 'SessionMutateRowRequest',
    as InstanceOf['Google::Bigtable::V2::Session::SessionMutateRowRequest'];

coerce 'SessionMutateRowRequest',
    from HashRef, via { 'Google::Bigtable::V2::Session::SessionMutateRowRequest'->new($_) };

declare 'RepeatedSessionMutateRowRequest',
    as ArrayRef[SessionMutateRowRequest()];

coerce 'RepeatedSessionMutateRowRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::V2::Session::SessionMutateRowRequest'->new($_) } @$_ ] };

declare 'MapStringSessionMutateRowRequest',
    as HashRef[SessionMutateRowRequest()];

declare 'SessionMutateRowResponse',
    as InstanceOf['Google::Bigtable::V2::Session::SessionMutateRowResponse'];

coerce 'SessionMutateRowResponse',
    from HashRef, via { 'Google::Bigtable::V2::Session::SessionMutateRowResponse'->new($_) };

declare 'RepeatedSessionMutateRowResponse',
    as ArrayRef[SessionMutateRowResponse()];

coerce 'RepeatedSessionMutateRowResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::V2::Session::SessionMutateRowResponse'->new($_) } @$_ ] };

declare 'MapStringSessionMutateRowResponse',
    as HashRef[SessionMutateRowResponse()];

declare 'SessionCheckAndMutateRowRequest',
    as InstanceOf['Google::Bigtable::V2::Session::SessionCheckAndMutateRowRequest'];

coerce 'SessionCheckAndMutateRowRequest',
    from HashRef, via { 'Google::Bigtable::V2::Session::SessionCheckAndMutateRowRequest'->new($_) };

declare 'RepeatedSessionCheckAndMutateRowRequest',
    as ArrayRef[SessionCheckAndMutateRowRequest()];

coerce 'RepeatedSessionCheckAndMutateRowRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::V2::Session::SessionCheckAndMutateRowRequest'->new($_) } @$_ ] };

declare 'MapStringSessionCheckAndMutateRowRequest',
    as HashRef[SessionCheckAndMutateRowRequest()];

declare 'SessionCheckAndMutateRowResponse',
    as InstanceOf['Google::Bigtable::V2::Session::SessionCheckAndMutateRowResponse'];

coerce 'SessionCheckAndMutateRowResponse',
    from HashRef, via { 'Google::Bigtable::V2::Session::SessionCheckAndMutateRowResponse'->new($_) };

declare 'RepeatedSessionCheckAndMutateRowResponse',
    as ArrayRef[SessionCheckAndMutateRowResponse()];

coerce 'RepeatedSessionCheckAndMutateRowResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::V2::Session::SessionCheckAndMutateRowResponse'->new($_) } @$_ ] };

declare 'MapStringSessionCheckAndMutateRowResponse',
    as HashRef[SessionCheckAndMutateRowResponse()];

declare 'SessionReadModifyWriteRowRequest',
    as InstanceOf['Google::Bigtable::V2::Session::SessionReadModifyWriteRowRequest'];

coerce 'SessionReadModifyWriteRowRequest',
    from HashRef, via { 'Google::Bigtable::V2::Session::SessionReadModifyWriteRowRequest'->new($_) };

declare 'RepeatedSessionReadModifyWriteRowRequest',
    as ArrayRef[SessionReadModifyWriteRowRequest()];

coerce 'RepeatedSessionReadModifyWriteRowRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::V2::Session::SessionReadModifyWriteRowRequest'->new($_) } @$_ ] };

declare 'MapStringSessionReadModifyWriteRowRequest',
    as HashRef[SessionReadModifyWriteRowRequest()];

declare 'SessionReadModifyWriteRowResponse',
    as InstanceOf['Google::Bigtable::V2::Session::SessionReadModifyWriteRowResponse'];

coerce 'SessionReadModifyWriteRowResponse',
    from HashRef, via { 'Google::Bigtable::V2::Session::SessionReadModifyWriteRowResponse'->new($_) };

declare 'RepeatedSessionReadModifyWriteRowResponse',
    as ArrayRef[SessionReadModifyWriteRowResponse()];

coerce 'RepeatedSessionReadModifyWriteRowResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::V2::Session::SessionReadModifyWriteRowResponse'->new($_) } @$_ ] };

declare 'MapStringSessionReadModifyWriteRowResponse',
    as HashRef[SessionReadModifyWriteRowResponse()];

declare 'SessionMutateRowsRequest',
    as InstanceOf['Google::Bigtable::V2::Session::SessionMutateRowsRequest'];

coerce 'SessionMutateRowsRequest',
    from HashRef, via { 'Google::Bigtable::V2::Session::SessionMutateRowsRequest'->new($_) };

declare 'RepeatedSessionMutateRowsRequest',
    as ArrayRef[SessionMutateRowsRequest()];

coerce 'RepeatedSessionMutateRowsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::V2::Session::SessionMutateRowsRequest'->new($_) } @$_ ] };

declare 'MapStringSessionMutateRowsRequest',
    as HashRef[SessionMutateRowsRequest()];

declare 'Entry',
    as InstanceOf['Google::Bigtable::V2::Session::SessionMutateRowsRequest::Entry'];

coerce 'Entry',
    from HashRef, via { 'Google::Bigtable::V2::Session::SessionMutateRowsRequest::Entry'->new($_) };

declare 'RepeatedEntry',
    as ArrayRef[Entry()];

coerce 'RepeatedEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::V2::Session::SessionMutateRowsRequest::Entry'->new($_) } @$_ ] };

declare 'MapStringEntry',
    as HashRef[Entry()];

declare 'SessionMutateRowsResponse',
    as InstanceOf['Google::Bigtable::V2::Session::SessionMutateRowsResponse'];

coerce 'SessionMutateRowsResponse',
    from HashRef, via { 'Google::Bigtable::V2::Session::SessionMutateRowsResponse'->new($_) };

declare 'RepeatedSessionMutateRowsResponse',
    as ArrayRef[SessionMutateRowsResponse()];

coerce 'RepeatedSessionMutateRowsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::V2::Session::SessionMutateRowsResponse'->new($_) } @$_ ] };

declare 'MapStringSessionMutateRowsResponse',
    as HashRef[SessionMutateRowsResponse()];

declare 'Entry',
    as InstanceOf['Google::Bigtable::V2::Session::SessionMutateRowsResponse::Entry'];

coerce 'Entry',
    from HashRef, via { 'Google::Bigtable::V2::Session::SessionMutateRowsResponse::Entry'->new($_) };

declare 'RepeatedEntry',
    as ArrayRef[Entry()];

coerce 'RepeatedEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::V2::Session::SessionMutateRowsResponse::Entry'->new($_) } @$_ ] };

declare 'MapStringEntry',
    as HashRef[Entry()];

declare 'RateLimitInfo',
    as InstanceOf['Google::Bigtable::V2::Session::SessionMutateRowsResponse::RateLimitInfo'];

coerce 'RateLimitInfo',
    from HashRef, via { 'Google::Bigtable::V2::Session::SessionMutateRowsResponse::RateLimitInfo'->new($_) };

declare 'RepeatedRateLimitInfo',
    as ArrayRef[RateLimitInfo()];

coerce 'RepeatedRateLimitInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::V2::Session::SessionMutateRowsResponse::RateLimitInfo'->new($_) } @$_ ] };

declare 'MapStringRateLimitInfo',
    as HashRef[RateLimitInfo()];

declare 'SessionParametersResponse',
    as InstanceOf['Google::Bigtable::V2::Session::SessionParametersResponse'];

coerce 'SessionParametersResponse',
    from HashRef, via { 'Google::Bigtable::V2::Session::SessionParametersResponse'->new($_) };

declare 'RepeatedSessionParametersResponse',
    as ArrayRef[SessionParametersResponse()];

coerce 'RepeatedSessionParametersResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::V2::Session::SessionParametersResponse'->new($_) } @$_ ] };

declare 'MapStringSessionParametersResponse',
    as HashRef[SessionParametersResponse()];

declare 'HeartbeatResponse',
    as InstanceOf['Google::Bigtable::V2::Session::HeartbeatResponse'];

coerce 'HeartbeatResponse',
    from HashRef, via { 'Google::Bigtable::V2::Session::HeartbeatResponse'->new($_) };

declare 'RepeatedHeartbeatResponse',
    as ArrayRef[HeartbeatResponse()];

coerce 'RepeatedHeartbeatResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::V2::Session::HeartbeatResponse'->new($_) } @$_ ] };

declare 'MapStringHeartbeatResponse',
    as HashRef[HeartbeatResponse()];

declare 'GoAwayResponse',
    as InstanceOf['Google::Bigtable::V2::Session::GoAwayResponse'];

coerce 'GoAwayResponse',
    from HashRef, via { 'Google::Bigtable::V2::Session::GoAwayResponse'->new($_) };

declare 'RepeatedGoAwayResponse',
    as ArrayRef[GoAwayResponse()];

coerce 'RepeatedGoAwayResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::V2::Session::GoAwayResponse'->new($_) } @$_ ] };

declare 'MapStringGoAwayResponse',
    as HashRef[GoAwayResponse()];

declare 'SessionRefreshConfig',
    as InstanceOf['Google::Bigtable::V2::Session::SessionRefreshConfig'];

coerce 'SessionRefreshConfig',
    from HashRef, via { 'Google::Bigtable::V2::Session::SessionRefreshConfig'->new($_) };

declare 'RepeatedSessionRefreshConfig',
    as ArrayRef[SessionRefreshConfig()];

coerce 'RepeatedSessionRefreshConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::V2::Session::SessionRefreshConfig'->new($_) } @$_ ] };

declare 'MapStringSessionRefreshConfig',
    as HashRef[SessionRefreshConfig()];

declare 'Metadata',
    as InstanceOf['Google::Bigtable::V2::Session::SessionRefreshConfig::Metadata'];

coerce 'Metadata',
    from HashRef, via { 'Google::Bigtable::V2::Session::SessionRefreshConfig::Metadata'->new($_) };

declare 'RepeatedMetadata',
    as ArrayRef[Metadata()];

coerce 'RepeatedMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::V2::Session::SessionRefreshConfig::Metadata'->new($_) } @$_ ] };

declare 'MapStringMetadata',
    as HashRef[Metadata()];

1;

__END__

=head1 NAME

Google::Bigtable::V2::Session::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
