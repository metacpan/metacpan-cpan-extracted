package Google::Cloud::Networkconnectivity::V1::PolicyBasedRouting::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'PolicyBasedRoute',
    as InstanceOf['Google::Cloud::Networkconnectivity::V1::PolicyBasedRouting::PolicyBasedRoute'];

coerce 'PolicyBasedRoute',
    from HashRef, via { 'Google::Cloud::Networkconnectivity::V1::PolicyBasedRouting::PolicyBasedRoute'->new($_) };

declare 'RepeatedPolicyBasedRoute',
    as ArrayRef[PolicyBasedRoute()];

coerce 'RepeatedPolicyBasedRoute',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkconnectivity::V1::PolicyBasedRouting::PolicyBasedRoute'->new($_) } @$_ ] };

declare 'MapStringPolicyBasedRoute',
    as HashRef[PolicyBasedRoute()];

declare 'OtherRoutes',
    as (Int | Str);

declare 'VirtualMachine',
    as InstanceOf['Google::Cloud::Networkconnectivity::V1::PolicyBasedRouting::PolicyBasedRoute::VirtualMachine'];

coerce 'VirtualMachine',
    from HashRef, via { 'Google::Cloud::Networkconnectivity::V1::PolicyBasedRouting::PolicyBasedRoute::VirtualMachine'->new($_) };

declare 'RepeatedVirtualMachine',
    as ArrayRef[VirtualMachine()];

coerce 'RepeatedVirtualMachine',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkconnectivity::V1::PolicyBasedRouting::PolicyBasedRoute::VirtualMachine'->new($_) } @$_ ] };

declare 'MapStringVirtualMachine',
    as HashRef[VirtualMachine()];

declare 'InterconnectAttachment',
    as InstanceOf['Google::Cloud::Networkconnectivity::V1::PolicyBasedRouting::PolicyBasedRoute::InterconnectAttachment'];

coerce 'InterconnectAttachment',
    from HashRef, via { 'Google::Cloud::Networkconnectivity::V1::PolicyBasedRouting::PolicyBasedRoute::InterconnectAttachment'->new($_) };

declare 'RepeatedInterconnectAttachment',
    as ArrayRef[InterconnectAttachment()];

coerce 'RepeatedInterconnectAttachment',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkconnectivity::V1::PolicyBasedRouting::PolicyBasedRoute::InterconnectAttachment'->new($_) } @$_ ] };

declare 'MapStringInterconnectAttachment',
    as HashRef[InterconnectAttachment()];

declare 'Filter',
    as InstanceOf['Google::Cloud::Networkconnectivity::V1::PolicyBasedRouting::PolicyBasedRoute::Filter'];

coerce 'Filter',
    from HashRef, via { 'Google::Cloud::Networkconnectivity::V1::PolicyBasedRouting::PolicyBasedRoute::Filter'->new($_) };

declare 'RepeatedFilter',
    as ArrayRef[Filter()];

coerce 'RepeatedFilter',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkconnectivity::V1::PolicyBasedRouting::PolicyBasedRoute::Filter'->new($_) } @$_ ] };

declare 'MapStringFilter',
    as HashRef[Filter()];

declare 'ProtocolVersion',
    as (Int | Str);

declare 'Warnings',
    as InstanceOf['Google::Cloud::Networkconnectivity::V1::PolicyBasedRouting::PolicyBasedRoute::Warnings'];

coerce 'Warnings',
    from HashRef, via { 'Google::Cloud::Networkconnectivity::V1::PolicyBasedRouting::PolicyBasedRoute::Warnings'->new($_) };

declare 'RepeatedWarnings',
    as ArrayRef[Warnings()];

coerce 'RepeatedWarnings',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkconnectivity::V1::PolicyBasedRouting::PolicyBasedRoute::Warnings'->new($_) } @$_ ] };

declare 'MapStringWarnings',
    as HashRef[Warnings()];

declare 'Code',
    as (Int | Str);

declare 'DataEntry',
    as InstanceOf['Google::Cloud::Networkconnectivity::V1::PolicyBasedRouting::PolicyBasedRoute::Warnings::DataEntry'];

coerce 'DataEntry',
    from HashRef, via { 'Google::Cloud::Networkconnectivity::V1::PolicyBasedRouting::PolicyBasedRoute::Warnings::DataEntry'->new($_) };

declare 'RepeatedDataEntry',
    as ArrayRef[DataEntry()];

coerce 'RepeatedDataEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkconnectivity::V1::PolicyBasedRouting::PolicyBasedRoute::Warnings::DataEntry'->new($_) } @$_ ] };

declare 'MapStringDataEntry',
    as HashRef[DataEntry()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Networkconnectivity::V1::PolicyBasedRouting::PolicyBasedRoute::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Networkconnectivity::V1::PolicyBasedRouting::PolicyBasedRoute::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkconnectivity::V1::PolicyBasedRouting::PolicyBasedRoute::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'ListPolicyBasedRoutesRequest',
    as InstanceOf['Google::Cloud::Networkconnectivity::V1::PolicyBasedRouting::ListPolicyBasedRoutesRequest'];

coerce 'ListPolicyBasedRoutesRequest',
    from HashRef, via { 'Google::Cloud::Networkconnectivity::V1::PolicyBasedRouting::ListPolicyBasedRoutesRequest'->new($_) };

declare 'RepeatedListPolicyBasedRoutesRequest',
    as ArrayRef[ListPolicyBasedRoutesRequest()];

coerce 'RepeatedListPolicyBasedRoutesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkconnectivity::V1::PolicyBasedRouting::ListPolicyBasedRoutesRequest'->new($_) } @$_ ] };

declare 'MapStringListPolicyBasedRoutesRequest',
    as HashRef[ListPolicyBasedRoutesRequest()];

declare 'ListPolicyBasedRoutesResponse',
    as InstanceOf['Google::Cloud::Networkconnectivity::V1::PolicyBasedRouting::ListPolicyBasedRoutesResponse'];

coerce 'ListPolicyBasedRoutesResponse',
    from HashRef, via { 'Google::Cloud::Networkconnectivity::V1::PolicyBasedRouting::ListPolicyBasedRoutesResponse'->new($_) };

declare 'RepeatedListPolicyBasedRoutesResponse',
    as ArrayRef[ListPolicyBasedRoutesResponse()];

coerce 'RepeatedListPolicyBasedRoutesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkconnectivity::V1::PolicyBasedRouting::ListPolicyBasedRoutesResponse'->new($_) } @$_ ] };

declare 'MapStringListPolicyBasedRoutesResponse',
    as HashRef[ListPolicyBasedRoutesResponse()];

declare 'GetPolicyBasedRouteRequest',
    as InstanceOf['Google::Cloud::Networkconnectivity::V1::PolicyBasedRouting::GetPolicyBasedRouteRequest'];

coerce 'GetPolicyBasedRouteRequest',
    from HashRef, via { 'Google::Cloud::Networkconnectivity::V1::PolicyBasedRouting::GetPolicyBasedRouteRequest'->new($_) };

declare 'RepeatedGetPolicyBasedRouteRequest',
    as ArrayRef[GetPolicyBasedRouteRequest()];

coerce 'RepeatedGetPolicyBasedRouteRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkconnectivity::V1::PolicyBasedRouting::GetPolicyBasedRouteRequest'->new($_) } @$_ ] };

declare 'MapStringGetPolicyBasedRouteRequest',
    as HashRef[GetPolicyBasedRouteRequest()];

declare 'CreatePolicyBasedRouteRequest',
    as InstanceOf['Google::Cloud::Networkconnectivity::V1::PolicyBasedRouting::CreatePolicyBasedRouteRequest'];

coerce 'CreatePolicyBasedRouteRequest',
    from HashRef, via { 'Google::Cloud::Networkconnectivity::V1::PolicyBasedRouting::CreatePolicyBasedRouteRequest'->new($_) };

declare 'RepeatedCreatePolicyBasedRouteRequest',
    as ArrayRef[CreatePolicyBasedRouteRequest()];

coerce 'RepeatedCreatePolicyBasedRouteRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkconnectivity::V1::PolicyBasedRouting::CreatePolicyBasedRouteRequest'->new($_) } @$_ ] };

declare 'MapStringCreatePolicyBasedRouteRequest',
    as HashRef[CreatePolicyBasedRouteRequest()];

declare 'DeletePolicyBasedRouteRequest',
    as InstanceOf['Google::Cloud::Networkconnectivity::V1::PolicyBasedRouting::DeletePolicyBasedRouteRequest'];

coerce 'DeletePolicyBasedRouteRequest',
    from HashRef, via { 'Google::Cloud::Networkconnectivity::V1::PolicyBasedRouting::DeletePolicyBasedRouteRequest'->new($_) };

declare 'RepeatedDeletePolicyBasedRouteRequest',
    as ArrayRef[DeletePolicyBasedRouteRequest()];

coerce 'RepeatedDeletePolicyBasedRouteRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkconnectivity::V1::PolicyBasedRouting::DeletePolicyBasedRouteRequest'->new($_) } @$_ ] };

declare 'MapStringDeletePolicyBasedRouteRequest',
    as HashRef[DeletePolicyBasedRouteRequest()];

1;

__END__

=head1 NAME

Google::Cloud::Networkconnectivity::V1::PolicyBasedRouting::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
