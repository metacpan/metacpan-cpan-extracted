package Google::Cloud::Ids::V1::Ids::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Endpoint',
    as InstanceOf['Google::Cloud::Ids::V1::Ids::Endpoint'];

coerce 'Endpoint',
    from HashRef, via { 'Google::Cloud::Ids::V1::Ids::Endpoint'->new($_) };

declare 'RepeatedEndpoint',
    as ArrayRef[Endpoint()];

coerce 'RepeatedEndpoint',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ids::V1::Ids::Endpoint'->new($_) } @$_ ] };

declare 'MapStringEndpoint',
    as HashRef[Endpoint()];

declare 'Severity',
    as (Int | Str);

declare 'State',
    as (Int | Str);

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Ids::V1::Ids::Endpoint::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Ids::V1::Ids::Endpoint::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ids::V1::Ids::Endpoint::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'ListEndpointsRequest',
    as InstanceOf['Google::Cloud::Ids::V1::Ids::ListEndpointsRequest'];

coerce 'ListEndpointsRequest',
    from HashRef, via { 'Google::Cloud::Ids::V1::Ids::ListEndpointsRequest'->new($_) };

declare 'RepeatedListEndpointsRequest',
    as ArrayRef[ListEndpointsRequest()];

coerce 'RepeatedListEndpointsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ids::V1::Ids::ListEndpointsRequest'->new($_) } @$_ ] };

declare 'MapStringListEndpointsRequest',
    as HashRef[ListEndpointsRequest()];

declare 'ListEndpointsResponse',
    as InstanceOf['Google::Cloud::Ids::V1::Ids::ListEndpointsResponse'];

coerce 'ListEndpointsResponse',
    from HashRef, via { 'Google::Cloud::Ids::V1::Ids::ListEndpointsResponse'->new($_) };

declare 'RepeatedListEndpointsResponse',
    as ArrayRef[ListEndpointsResponse()];

coerce 'RepeatedListEndpointsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ids::V1::Ids::ListEndpointsResponse'->new($_) } @$_ ] };

declare 'MapStringListEndpointsResponse',
    as HashRef[ListEndpointsResponse()];

declare 'GetEndpointRequest',
    as InstanceOf['Google::Cloud::Ids::V1::Ids::GetEndpointRequest'];

coerce 'GetEndpointRequest',
    from HashRef, via { 'Google::Cloud::Ids::V1::Ids::GetEndpointRequest'->new($_) };

declare 'RepeatedGetEndpointRequest',
    as ArrayRef[GetEndpointRequest()];

coerce 'RepeatedGetEndpointRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ids::V1::Ids::GetEndpointRequest'->new($_) } @$_ ] };

declare 'MapStringGetEndpointRequest',
    as HashRef[GetEndpointRequest()];

declare 'CreateEndpointRequest',
    as InstanceOf['Google::Cloud::Ids::V1::Ids::CreateEndpointRequest'];

coerce 'CreateEndpointRequest',
    from HashRef, via { 'Google::Cloud::Ids::V1::Ids::CreateEndpointRequest'->new($_) };

declare 'RepeatedCreateEndpointRequest',
    as ArrayRef[CreateEndpointRequest()];

coerce 'RepeatedCreateEndpointRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ids::V1::Ids::CreateEndpointRequest'->new($_) } @$_ ] };

declare 'MapStringCreateEndpointRequest',
    as HashRef[CreateEndpointRequest()];

declare 'DeleteEndpointRequest',
    as InstanceOf['Google::Cloud::Ids::V1::Ids::DeleteEndpointRequest'];

coerce 'DeleteEndpointRequest',
    from HashRef, via { 'Google::Cloud::Ids::V1::Ids::DeleteEndpointRequest'->new($_) };

declare 'RepeatedDeleteEndpointRequest',
    as ArrayRef[DeleteEndpointRequest()];

coerce 'RepeatedDeleteEndpointRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ids::V1::Ids::DeleteEndpointRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteEndpointRequest',
    as HashRef[DeleteEndpointRequest()];

declare 'OperationMetadata',
    as InstanceOf['Google::Cloud::Ids::V1::Ids::OperationMetadata'];

coerce 'OperationMetadata',
    from HashRef, via { 'Google::Cloud::Ids::V1::Ids::OperationMetadata'->new($_) };

declare 'RepeatedOperationMetadata',
    as ArrayRef[OperationMetadata()];

coerce 'RepeatedOperationMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ids::V1::Ids::OperationMetadata'->new($_) } @$_ ] };

declare 'MapStringOperationMetadata',
    as HashRef[OperationMetadata()];

1;

__END__

=head1 NAME

Google::Cloud::Ids::V1::Ids::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
