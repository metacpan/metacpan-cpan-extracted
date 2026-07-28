package Google::Cloud::Networkservices::V1::AgentGateway::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'AgentGateway',
    as InstanceOf['Google::Cloud::Networkservices::V1::AgentGateway::AgentGateway'];

coerce 'AgentGateway',
    from HashRef, via { 'Google::Cloud::Networkservices::V1::AgentGateway::AgentGateway'->new($_) };

declare 'RepeatedAgentGateway',
    as ArrayRef[AgentGateway()];

coerce 'RepeatedAgentGateway',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkservices::V1::AgentGateway::AgentGateway'->new($_) } @$_ ] };

declare 'MapStringAgentGateway',
    as HashRef[AgentGateway()];

declare 'Protocol',
    as (Int | Str);

declare 'GoogleManaged',
    as InstanceOf['Google::Cloud::Networkservices::V1::AgentGateway::AgentGateway::GoogleManaged'];

coerce 'GoogleManaged',
    from HashRef, via { 'Google::Cloud::Networkservices::V1::AgentGateway::AgentGateway::GoogleManaged'->new($_) };

declare 'RepeatedGoogleManaged',
    as ArrayRef[GoogleManaged()];

coerce 'RepeatedGoogleManaged',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkservices::V1::AgentGateway::AgentGateway::GoogleManaged'->new($_) } @$_ ] };

declare 'MapStringGoogleManaged',
    as HashRef[GoogleManaged()];

declare 'GovernedAccessPath',
    as (Int | Str);

declare 'SelfManaged',
    as InstanceOf['Google::Cloud::Networkservices::V1::AgentGateway::AgentGateway::SelfManaged'];

coerce 'SelfManaged',
    from HashRef, via { 'Google::Cloud::Networkservices::V1::AgentGateway::AgentGateway::SelfManaged'->new($_) };

declare 'RepeatedSelfManaged',
    as ArrayRef[SelfManaged()];

coerce 'RepeatedSelfManaged',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkservices::V1::AgentGateway::AgentGateway::SelfManaged'->new($_) } @$_ ] };

declare 'MapStringSelfManaged',
    as HashRef[SelfManaged()];

declare 'NetworkConfig',
    as InstanceOf['Google::Cloud::Networkservices::V1::AgentGateway::AgentGateway::NetworkConfig'];

coerce 'NetworkConfig',
    from HashRef, via { 'Google::Cloud::Networkservices::V1::AgentGateway::AgentGateway::NetworkConfig'->new($_) };

declare 'RepeatedNetworkConfig',
    as ArrayRef[NetworkConfig()];

coerce 'RepeatedNetworkConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkservices::V1::AgentGateway::AgentGateway::NetworkConfig'->new($_) } @$_ ] };

declare 'MapStringNetworkConfig',
    as HashRef[NetworkConfig()];

declare 'Egress',
    as InstanceOf['Google::Cloud::Networkservices::V1::AgentGateway::AgentGateway::NetworkConfig::Egress'];

coerce 'Egress',
    from HashRef, via { 'Google::Cloud::Networkservices::V1::AgentGateway::AgentGateway::NetworkConfig::Egress'->new($_) };

declare 'RepeatedEgress',
    as ArrayRef[Egress()];

coerce 'RepeatedEgress',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkservices::V1::AgentGateway::AgentGateway::NetworkConfig::Egress'->new($_) } @$_ ] };

declare 'MapStringEgress',
    as HashRef[Egress()];

declare 'TrustConfig',
    as InstanceOf['Google::Cloud::Networkservices::V1::AgentGateway::AgentGateway::NetworkConfig::Egress::TrustConfig'];

coerce 'TrustConfig',
    from HashRef, via { 'Google::Cloud::Networkservices::V1::AgentGateway::AgentGateway::NetworkConfig::Egress::TrustConfig'->new($_) };

declare 'RepeatedTrustConfig',
    as ArrayRef[TrustConfig()];

coerce 'RepeatedTrustConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkservices::V1::AgentGateway::AgentGateway::NetworkConfig::Egress::TrustConfig'->new($_) } @$_ ] };

declare 'MapStringTrustConfig',
    as HashRef[TrustConfig()];

declare 'DnsPeeringConfig',
    as InstanceOf['Google::Cloud::Networkservices::V1::AgentGateway::AgentGateway::NetworkConfig::DnsPeeringConfig'];

coerce 'DnsPeeringConfig',
    from HashRef, via { 'Google::Cloud::Networkservices::V1::AgentGateway::AgentGateway::NetworkConfig::DnsPeeringConfig'->new($_) };

declare 'RepeatedDnsPeeringConfig',
    as ArrayRef[DnsPeeringConfig()];

coerce 'RepeatedDnsPeeringConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkservices::V1::AgentGateway::AgentGateway::NetworkConfig::DnsPeeringConfig'->new($_) } @$_ ] };

declare 'MapStringDnsPeeringConfig',
    as HashRef[DnsPeeringConfig()];

declare 'AgentGatewayOutputCard',
    as InstanceOf['Google::Cloud::Networkservices::V1::AgentGateway::AgentGateway::AgentGatewayOutputCard'];

coerce 'AgentGatewayOutputCard',
    from HashRef, via { 'Google::Cloud::Networkservices::V1::AgentGateway::AgentGateway::AgentGatewayOutputCard'->new($_) };

declare 'RepeatedAgentGatewayOutputCard',
    as ArrayRef[AgentGatewayOutputCard()];

coerce 'RepeatedAgentGatewayOutputCard',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkservices::V1::AgentGateway::AgentGateway::AgentGatewayOutputCard'->new($_) } @$_ ] };

declare 'MapStringAgentGatewayOutputCard',
    as HashRef[AgentGatewayOutputCard()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Networkservices::V1::AgentGateway::AgentGateway::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Networkservices::V1::AgentGateway::AgentGateway::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkservices::V1::AgentGateway::AgentGateway::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'ListAgentGatewaysRequest',
    as InstanceOf['Google::Cloud::Networkservices::V1::AgentGateway::ListAgentGatewaysRequest'];

coerce 'ListAgentGatewaysRequest',
    from HashRef, via { 'Google::Cloud::Networkservices::V1::AgentGateway::ListAgentGatewaysRequest'->new($_) };

declare 'RepeatedListAgentGatewaysRequest',
    as ArrayRef[ListAgentGatewaysRequest()];

coerce 'RepeatedListAgentGatewaysRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkservices::V1::AgentGateway::ListAgentGatewaysRequest'->new($_) } @$_ ] };

declare 'MapStringListAgentGatewaysRequest',
    as HashRef[ListAgentGatewaysRequest()];

declare 'ListAgentGatewaysResponse',
    as InstanceOf['Google::Cloud::Networkservices::V1::AgentGateway::ListAgentGatewaysResponse'];

coerce 'ListAgentGatewaysResponse',
    from HashRef, via { 'Google::Cloud::Networkservices::V1::AgentGateway::ListAgentGatewaysResponse'->new($_) };

declare 'RepeatedListAgentGatewaysResponse',
    as ArrayRef[ListAgentGatewaysResponse()];

coerce 'RepeatedListAgentGatewaysResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkservices::V1::AgentGateway::ListAgentGatewaysResponse'->new($_) } @$_ ] };

declare 'MapStringListAgentGatewaysResponse',
    as HashRef[ListAgentGatewaysResponse()];

declare 'GetAgentGatewayRequest',
    as InstanceOf['Google::Cloud::Networkservices::V1::AgentGateway::GetAgentGatewayRequest'];

coerce 'GetAgentGatewayRequest',
    from HashRef, via { 'Google::Cloud::Networkservices::V1::AgentGateway::GetAgentGatewayRequest'->new($_) };

declare 'RepeatedGetAgentGatewayRequest',
    as ArrayRef[GetAgentGatewayRequest()];

coerce 'RepeatedGetAgentGatewayRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkservices::V1::AgentGateway::GetAgentGatewayRequest'->new($_) } @$_ ] };

declare 'MapStringGetAgentGatewayRequest',
    as HashRef[GetAgentGatewayRequest()];

declare 'CreateAgentGatewayRequest',
    as InstanceOf['Google::Cloud::Networkservices::V1::AgentGateway::CreateAgentGatewayRequest'];

coerce 'CreateAgentGatewayRequest',
    from HashRef, via { 'Google::Cloud::Networkservices::V1::AgentGateway::CreateAgentGatewayRequest'->new($_) };

declare 'RepeatedCreateAgentGatewayRequest',
    as ArrayRef[CreateAgentGatewayRequest()];

coerce 'RepeatedCreateAgentGatewayRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkservices::V1::AgentGateway::CreateAgentGatewayRequest'->new($_) } @$_ ] };

declare 'MapStringCreateAgentGatewayRequest',
    as HashRef[CreateAgentGatewayRequest()];

declare 'UpdateAgentGatewayRequest',
    as InstanceOf['Google::Cloud::Networkservices::V1::AgentGateway::UpdateAgentGatewayRequest'];

coerce 'UpdateAgentGatewayRequest',
    from HashRef, via { 'Google::Cloud::Networkservices::V1::AgentGateway::UpdateAgentGatewayRequest'->new($_) };

declare 'RepeatedUpdateAgentGatewayRequest',
    as ArrayRef[UpdateAgentGatewayRequest()];

coerce 'RepeatedUpdateAgentGatewayRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkservices::V1::AgentGateway::UpdateAgentGatewayRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateAgentGatewayRequest',
    as HashRef[UpdateAgentGatewayRequest()];

declare 'DeleteAgentGatewayRequest',
    as InstanceOf['Google::Cloud::Networkservices::V1::AgentGateway::DeleteAgentGatewayRequest'];

coerce 'DeleteAgentGatewayRequest',
    from HashRef, via { 'Google::Cloud::Networkservices::V1::AgentGateway::DeleteAgentGatewayRequest'->new($_) };

declare 'RepeatedDeleteAgentGatewayRequest',
    as ArrayRef[DeleteAgentGatewayRequest()];

coerce 'RepeatedDeleteAgentGatewayRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkservices::V1::AgentGateway::DeleteAgentGatewayRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteAgentGatewayRequest',
    as HashRef[DeleteAgentGatewayRequest()];

1;

__END__

=head1 NAME

Google::Cloud::Networkservices::V1::AgentGateway::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
