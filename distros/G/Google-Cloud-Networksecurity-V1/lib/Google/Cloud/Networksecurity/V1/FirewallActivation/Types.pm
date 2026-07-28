package Google::Cloud::Networksecurity::V1::FirewallActivation::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'FirewallEndpoint',
    as InstanceOf['Google::Cloud::Networksecurity::V1::FirewallActivation::FirewallEndpoint'];

coerce 'FirewallEndpoint',
    from HashRef, via { 'Google::Cloud::Networksecurity::V1::FirewallActivation::FirewallEndpoint'->new($_) };

declare 'RepeatedFirewallEndpoint',
    as ArrayRef[FirewallEndpoint()];

coerce 'RepeatedFirewallEndpoint',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networksecurity::V1::FirewallActivation::FirewallEndpoint'->new($_) } @$_ ] };

declare 'MapStringFirewallEndpoint',
    as HashRef[FirewallEndpoint()];

declare 'State',
    as (Int | Str);

declare 'AssociationReference',
    as InstanceOf['Google::Cloud::Networksecurity::V1::FirewallActivation::FirewallEndpoint::AssociationReference'];

coerce 'AssociationReference',
    from HashRef, via { 'Google::Cloud::Networksecurity::V1::FirewallActivation::FirewallEndpoint::AssociationReference'->new($_) };

declare 'RepeatedAssociationReference',
    as ArrayRef[AssociationReference()];

coerce 'RepeatedAssociationReference',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networksecurity::V1::FirewallActivation::FirewallEndpoint::AssociationReference'->new($_) } @$_ ] };

declare 'MapStringAssociationReference',
    as HashRef[AssociationReference()];

declare 'EndpointSettings',
    as InstanceOf['Google::Cloud::Networksecurity::V1::FirewallActivation::FirewallEndpoint::EndpointSettings'];

coerce 'EndpointSettings',
    from HashRef, via { 'Google::Cloud::Networksecurity::V1::FirewallActivation::FirewallEndpoint::EndpointSettings'->new($_) };

declare 'RepeatedEndpointSettings',
    as ArrayRef[EndpointSettings()];

coerce 'RepeatedEndpointSettings',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networksecurity::V1::FirewallActivation::FirewallEndpoint::EndpointSettings'->new($_) } @$_ ] };

declare 'MapStringEndpointSettings',
    as HashRef[EndpointSettings()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Networksecurity::V1::FirewallActivation::FirewallEndpoint::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Networksecurity::V1::FirewallActivation::FirewallEndpoint::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networksecurity::V1::FirewallActivation::FirewallEndpoint::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'ListFirewallEndpointsRequest',
    as InstanceOf['Google::Cloud::Networksecurity::V1::FirewallActivation::ListFirewallEndpointsRequest'];

coerce 'ListFirewallEndpointsRequest',
    from HashRef, via { 'Google::Cloud::Networksecurity::V1::FirewallActivation::ListFirewallEndpointsRequest'->new($_) };

declare 'RepeatedListFirewallEndpointsRequest',
    as ArrayRef[ListFirewallEndpointsRequest()];

coerce 'RepeatedListFirewallEndpointsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networksecurity::V1::FirewallActivation::ListFirewallEndpointsRequest'->new($_) } @$_ ] };

declare 'MapStringListFirewallEndpointsRequest',
    as HashRef[ListFirewallEndpointsRequest()];

declare 'ListFirewallEndpointsResponse',
    as InstanceOf['Google::Cloud::Networksecurity::V1::FirewallActivation::ListFirewallEndpointsResponse'];

coerce 'ListFirewallEndpointsResponse',
    from HashRef, via { 'Google::Cloud::Networksecurity::V1::FirewallActivation::ListFirewallEndpointsResponse'->new($_) };

declare 'RepeatedListFirewallEndpointsResponse',
    as ArrayRef[ListFirewallEndpointsResponse()];

coerce 'RepeatedListFirewallEndpointsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networksecurity::V1::FirewallActivation::ListFirewallEndpointsResponse'->new($_) } @$_ ] };

declare 'MapStringListFirewallEndpointsResponse',
    as HashRef[ListFirewallEndpointsResponse()];

declare 'GetFirewallEndpointRequest',
    as InstanceOf['Google::Cloud::Networksecurity::V1::FirewallActivation::GetFirewallEndpointRequest'];

coerce 'GetFirewallEndpointRequest',
    from HashRef, via { 'Google::Cloud::Networksecurity::V1::FirewallActivation::GetFirewallEndpointRequest'->new($_) };

declare 'RepeatedGetFirewallEndpointRequest',
    as ArrayRef[GetFirewallEndpointRequest()];

coerce 'RepeatedGetFirewallEndpointRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networksecurity::V1::FirewallActivation::GetFirewallEndpointRequest'->new($_) } @$_ ] };

declare 'MapStringGetFirewallEndpointRequest',
    as HashRef[GetFirewallEndpointRequest()];

declare 'CreateFirewallEndpointRequest',
    as InstanceOf['Google::Cloud::Networksecurity::V1::FirewallActivation::CreateFirewallEndpointRequest'];

coerce 'CreateFirewallEndpointRequest',
    from HashRef, via { 'Google::Cloud::Networksecurity::V1::FirewallActivation::CreateFirewallEndpointRequest'->new($_) };

declare 'RepeatedCreateFirewallEndpointRequest',
    as ArrayRef[CreateFirewallEndpointRequest()];

coerce 'RepeatedCreateFirewallEndpointRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networksecurity::V1::FirewallActivation::CreateFirewallEndpointRequest'->new($_) } @$_ ] };

declare 'MapStringCreateFirewallEndpointRequest',
    as HashRef[CreateFirewallEndpointRequest()];

declare 'UpdateFirewallEndpointRequest',
    as InstanceOf['Google::Cloud::Networksecurity::V1::FirewallActivation::UpdateFirewallEndpointRequest'];

coerce 'UpdateFirewallEndpointRequest',
    from HashRef, via { 'Google::Cloud::Networksecurity::V1::FirewallActivation::UpdateFirewallEndpointRequest'->new($_) };

declare 'RepeatedUpdateFirewallEndpointRequest',
    as ArrayRef[UpdateFirewallEndpointRequest()];

coerce 'RepeatedUpdateFirewallEndpointRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networksecurity::V1::FirewallActivation::UpdateFirewallEndpointRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateFirewallEndpointRequest',
    as HashRef[UpdateFirewallEndpointRequest()];

declare 'DeleteFirewallEndpointRequest',
    as InstanceOf['Google::Cloud::Networksecurity::V1::FirewallActivation::DeleteFirewallEndpointRequest'];

coerce 'DeleteFirewallEndpointRequest',
    from HashRef, via { 'Google::Cloud::Networksecurity::V1::FirewallActivation::DeleteFirewallEndpointRequest'->new($_) };

declare 'RepeatedDeleteFirewallEndpointRequest',
    as ArrayRef[DeleteFirewallEndpointRequest()];

coerce 'RepeatedDeleteFirewallEndpointRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networksecurity::V1::FirewallActivation::DeleteFirewallEndpointRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteFirewallEndpointRequest',
    as HashRef[DeleteFirewallEndpointRequest()];

declare 'FirewallEndpointAssociation',
    as InstanceOf['Google::Cloud::Networksecurity::V1::FirewallActivation::FirewallEndpointAssociation'];

coerce 'FirewallEndpointAssociation',
    from HashRef, via { 'Google::Cloud::Networksecurity::V1::FirewallActivation::FirewallEndpointAssociation'->new($_) };

declare 'RepeatedFirewallEndpointAssociation',
    as ArrayRef[FirewallEndpointAssociation()];

coerce 'RepeatedFirewallEndpointAssociation',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networksecurity::V1::FirewallActivation::FirewallEndpointAssociation'->new($_) } @$_ ] };

declare 'MapStringFirewallEndpointAssociation',
    as HashRef[FirewallEndpointAssociation()];

declare 'State',
    as (Int | Str);

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Networksecurity::V1::FirewallActivation::FirewallEndpointAssociation::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Networksecurity::V1::FirewallActivation::FirewallEndpointAssociation::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networksecurity::V1::FirewallActivation::FirewallEndpointAssociation::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'ListFirewallEndpointAssociationsRequest',
    as InstanceOf['Google::Cloud::Networksecurity::V1::FirewallActivation::ListFirewallEndpointAssociationsRequest'];

coerce 'ListFirewallEndpointAssociationsRequest',
    from HashRef, via { 'Google::Cloud::Networksecurity::V1::FirewallActivation::ListFirewallEndpointAssociationsRequest'->new($_) };

declare 'RepeatedListFirewallEndpointAssociationsRequest',
    as ArrayRef[ListFirewallEndpointAssociationsRequest()];

coerce 'RepeatedListFirewallEndpointAssociationsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networksecurity::V1::FirewallActivation::ListFirewallEndpointAssociationsRequest'->new($_) } @$_ ] };

declare 'MapStringListFirewallEndpointAssociationsRequest',
    as HashRef[ListFirewallEndpointAssociationsRequest()];

declare 'ListFirewallEndpointAssociationsResponse',
    as InstanceOf['Google::Cloud::Networksecurity::V1::FirewallActivation::ListFirewallEndpointAssociationsResponse'];

coerce 'ListFirewallEndpointAssociationsResponse',
    from HashRef, via { 'Google::Cloud::Networksecurity::V1::FirewallActivation::ListFirewallEndpointAssociationsResponse'->new($_) };

declare 'RepeatedListFirewallEndpointAssociationsResponse',
    as ArrayRef[ListFirewallEndpointAssociationsResponse()];

coerce 'RepeatedListFirewallEndpointAssociationsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networksecurity::V1::FirewallActivation::ListFirewallEndpointAssociationsResponse'->new($_) } @$_ ] };

declare 'MapStringListFirewallEndpointAssociationsResponse',
    as HashRef[ListFirewallEndpointAssociationsResponse()];

declare 'GetFirewallEndpointAssociationRequest',
    as InstanceOf['Google::Cloud::Networksecurity::V1::FirewallActivation::GetFirewallEndpointAssociationRequest'];

coerce 'GetFirewallEndpointAssociationRequest',
    from HashRef, via { 'Google::Cloud::Networksecurity::V1::FirewallActivation::GetFirewallEndpointAssociationRequest'->new($_) };

declare 'RepeatedGetFirewallEndpointAssociationRequest',
    as ArrayRef[GetFirewallEndpointAssociationRequest()];

coerce 'RepeatedGetFirewallEndpointAssociationRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networksecurity::V1::FirewallActivation::GetFirewallEndpointAssociationRequest'->new($_) } @$_ ] };

declare 'MapStringGetFirewallEndpointAssociationRequest',
    as HashRef[GetFirewallEndpointAssociationRequest()];

declare 'CreateFirewallEndpointAssociationRequest',
    as InstanceOf['Google::Cloud::Networksecurity::V1::FirewallActivation::CreateFirewallEndpointAssociationRequest'];

coerce 'CreateFirewallEndpointAssociationRequest',
    from HashRef, via { 'Google::Cloud::Networksecurity::V1::FirewallActivation::CreateFirewallEndpointAssociationRequest'->new($_) };

declare 'RepeatedCreateFirewallEndpointAssociationRequest',
    as ArrayRef[CreateFirewallEndpointAssociationRequest()];

coerce 'RepeatedCreateFirewallEndpointAssociationRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networksecurity::V1::FirewallActivation::CreateFirewallEndpointAssociationRequest'->new($_) } @$_ ] };

declare 'MapStringCreateFirewallEndpointAssociationRequest',
    as HashRef[CreateFirewallEndpointAssociationRequest()];

declare 'DeleteFirewallEndpointAssociationRequest',
    as InstanceOf['Google::Cloud::Networksecurity::V1::FirewallActivation::DeleteFirewallEndpointAssociationRequest'];

coerce 'DeleteFirewallEndpointAssociationRequest',
    from HashRef, via { 'Google::Cloud::Networksecurity::V1::FirewallActivation::DeleteFirewallEndpointAssociationRequest'->new($_) };

declare 'RepeatedDeleteFirewallEndpointAssociationRequest',
    as ArrayRef[DeleteFirewallEndpointAssociationRequest()];

coerce 'RepeatedDeleteFirewallEndpointAssociationRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networksecurity::V1::FirewallActivation::DeleteFirewallEndpointAssociationRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteFirewallEndpointAssociationRequest',
    as HashRef[DeleteFirewallEndpointAssociationRequest()];

declare 'UpdateFirewallEndpointAssociationRequest',
    as InstanceOf['Google::Cloud::Networksecurity::V1::FirewallActivation::UpdateFirewallEndpointAssociationRequest'];

coerce 'UpdateFirewallEndpointAssociationRequest',
    from HashRef, via { 'Google::Cloud::Networksecurity::V1::FirewallActivation::UpdateFirewallEndpointAssociationRequest'->new($_) };

declare 'RepeatedUpdateFirewallEndpointAssociationRequest',
    as ArrayRef[UpdateFirewallEndpointAssociationRequest()];

coerce 'RepeatedUpdateFirewallEndpointAssociationRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networksecurity::V1::FirewallActivation::UpdateFirewallEndpointAssociationRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateFirewallEndpointAssociationRequest',
    as HashRef[UpdateFirewallEndpointAssociationRequest()];

1;

__END__

=head1 NAME

Google::Cloud::Networksecurity::V1::FirewallActivation::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
