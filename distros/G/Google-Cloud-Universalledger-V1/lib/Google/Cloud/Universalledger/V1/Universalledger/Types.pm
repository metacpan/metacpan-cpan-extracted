package Google::Cloud::Universalledger::V1::Universalledger::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Endpoint',
    as InstanceOf['Google::Cloud::Universalledger::V1::Universalledger::Endpoint'];

coerce 'Endpoint',
    from HashRef, via { 'Google::Cloud::Universalledger::V1::Universalledger::Endpoint'->new($_) };

declare 'RepeatedEndpoint',
    as ArrayRef[Endpoint()];

coerce 'RepeatedEndpoint',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Universalledger::V1::Universalledger::Endpoint'->new($_) } @$_ ] };

declare 'MapStringEndpoint',
    as HashRef[Endpoint()];

declare 'ListEndpointsRequest',
    as InstanceOf['Google::Cloud::Universalledger::V1::Universalledger::ListEndpointsRequest'];

coerce 'ListEndpointsRequest',
    from HashRef, via { 'Google::Cloud::Universalledger::V1::Universalledger::ListEndpointsRequest'->new($_) };

declare 'RepeatedListEndpointsRequest',
    as ArrayRef[ListEndpointsRequest()];

coerce 'RepeatedListEndpointsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Universalledger::V1::Universalledger::ListEndpointsRequest'->new($_) } @$_ ] };

declare 'MapStringListEndpointsRequest',
    as HashRef[ListEndpointsRequest()];

declare 'ListEndpointsResponse',
    as InstanceOf['Google::Cloud::Universalledger::V1::Universalledger::ListEndpointsResponse'];

coerce 'ListEndpointsResponse',
    from HashRef, via { 'Google::Cloud::Universalledger::V1::Universalledger::ListEndpointsResponse'->new($_) };

declare 'RepeatedListEndpointsResponse',
    as ArrayRef[ListEndpointsResponse()];

coerce 'RepeatedListEndpointsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Universalledger::V1::Universalledger::ListEndpointsResponse'->new($_) } @$_ ] };

declare 'MapStringListEndpointsResponse',
    as HashRef[ListEndpointsResponse()];

declare 'GetEndpointRequest',
    as InstanceOf['Google::Cloud::Universalledger::V1::Universalledger::GetEndpointRequest'];

coerce 'GetEndpointRequest',
    from HashRef, via { 'Google::Cloud::Universalledger::V1::Universalledger::GetEndpointRequest'->new($_) };

declare 'RepeatedGetEndpointRequest',
    as ArrayRef[GetEndpointRequest()];

coerce 'RepeatedGetEndpointRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Universalledger::V1::Universalledger::GetEndpointRequest'->new($_) } @$_ ] };

declare 'MapStringGetEndpointRequest',
    as HashRef[GetEndpointRequest()];

declare 'QueryAccountRequest',
    as InstanceOf['Google::Cloud::Universalledger::V1::Universalledger::QueryAccountRequest'];

coerce 'QueryAccountRequest',
    from HashRef, via { 'Google::Cloud::Universalledger::V1::Universalledger::QueryAccountRequest'->new($_) };

declare 'RepeatedQueryAccountRequest',
    as ArrayRef[QueryAccountRequest()];

coerce 'RepeatedQueryAccountRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Universalledger::V1::Universalledger::QueryAccountRequest'->new($_) } @$_ ] };

declare 'MapStringQueryAccountRequest',
    as HashRef[QueryAccountRequest()];

declare 'QueryAccountResponse',
    as InstanceOf['Google::Cloud::Universalledger::V1::Universalledger::QueryAccountResponse'];

coerce 'QueryAccountResponse',
    from HashRef, via { 'Google::Cloud::Universalledger::V1::Universalledger::QueryAccountResponse'->new($_) };

declare 'RepeatedQueryAccountResponse',
    as ArrayRef[QueryAccountResponse()];

coerce 'RepeatedQueryAccountResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Universalledger::V1::Universalledger::QueryAccountResponse'->new($_) } @$_ ] };

declare 'MapStringQueryAccountResponse',
    as HashRef[QueryAccountResponse()];

declare 'SubmitTransactionRequest',
    as InstanceOf['Google::Cloud::Universalledger::V1::Universalledger::SubmitTransactionRequest'];

coerce 'SubmitTransactionRequest',
    from HashRef, via { 'Google::Cloud::Universalledger::V1::Universalledger::SubmitTransactionRequest'->new($_) };

declare 'RepeatedSubmitTransactionRequest',
    as ArrayRef[SubmitTransactionRequest()];

coerce 'RepeatedSubmitTransactionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Universalledger::V1::Universalledger::SubmitTransactionRequest'->new($_) } @$_ ] };

declare 'MapStringSubmitTransactionRequest',
    as HashRef[SubmitTransactionRequest()];

declare 'SubmitTransactionResponse',
    as InstanceOf['Google::Cloud::Universalledger::V1::Universalledger::SubmitTransactionResponse'];

coerce 'SubmitTransactionResponse',
    from HashRef, via { 'Google::Cloud::Universalledger::V1::Universalledger::SubmitTransactionResponse'->new($_) };

declare 'RepeatedSubmitTransactionResponse',
    as ArrayRef[SubmitTransactionResponse()];

coerce 'RepeatedSubmitTransactionResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Universalledger::V1::Universalledger::SubmitTransactionResponse'->new($_) } @$_ ] };

declare 'MapStringSubmitTransactionResponse',
    as HashRef[SubmitTransactionResponse()];

declare 'SubmitOperationalTransactionRequest',
    as InstanceOf['Google::Cloud::Universalledger::V1::Universalledger::SubmitOperationalTransactionRequest'];

coerce 'SubmitOperationalTransactionRequest',
    from HashRef, via { 'Google::Cloud::Universalledger::V1::Universalledger::SubmitOperationalTransactionRequest'->new($_) };

declare 'RepeatedSubmitOperationalTransactionRequest',
    as ArrayRef[SubmitOperationalTransactionRequest()];

coerce 'RepeatedSubmitOperationalTransactionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Universalledger::V1::Universalledger::SubmitOperationalTransactionRequest'->new($_) } @$_ ] };

declare 'MapStringSubmitOperationalTransactionRequest',
    as HashRef[SubmitOperationalTransactionRequest()];

declare 'SubmitOperationalTransactionResponse',
    as InstanceOf['Google::Cloud::Universalledger::V1::Universalledger::SubmitOperationalTransactionResponse'];

coerce 'SubmitOperationalTransactionResponse',
    from HashRef, via { 'Google::Cloud::Universalledger::V1::Universalledger::SubmitOperationalTransactionResponse'->new($_) };

declare 'RepeatedSubmitOperationalTransactionResponse',
    as ArrayRef[SubmitOperationalTransactionResponse()];

coerce 'RepeatedSubmitOperationalTransactionResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Universalledger::V1::Universalledger::SubmitOperationalTransactionResponse'->new($_) } @$_ ] };

declare 'MapStringSubmitOperationalTransactionResponse',
    as HashRef[SubmitOperationalTransactionResponse()];

declare 'QueryTransactionStateRequest',
    as InstanceOf['Google::Cloud::Universalledger::V1::Universalledger::QueryTransactionStateRequest'];

coerce 'QueryTransactionStateRequest',
    from HashRef, via { 'Google::Cloud::Universalledger::V1::Universalledger::QueryTransactionStateRequest'->new($_) };

declare 'RepeatedQueryTransactionStateRequest',
    as ArrayRef[QueryTransactionStateRequest()];

coerce 'RepeatedQueryTransactionStateRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Universalledger::V1::Universalledger::QueryTransactionStateRequest'->new($_) } @$_ ] };

declare 'MapStringQueryTransactionStateRequest',
    as HashRef[QueryTransactionStateRequest()];

declare 'QueryTransactionStateResponse',
    as InstanceOf['Google::Cloud::Universalledger::V1::Universalledger::QueryTransactionStateResponse'];

coerce 'QueryTransactionStateResponse',
    from HashRef, via { 'Google::Cloud::Universalledger::V1::Universalledger::QueryTransactionStateResponse'->new($_) };

declare 'RepeatedQueryTransactionStateResponse',
    as ArrayRef[QueryTransactionStateResponse()];

coerce 'RepeatedQueryTransactionStateResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Universalledger::V1::Universalledger::QueryTransactionStateResponse'->new($_) } @$_ ] };

declare 'MapStringQueryTransactionStateResponse',
    as HashRef[QueryTransactionStateResponse()];

declare 'QueryDataRequest',
    as InstanceOf['Google::Cloud::Universalledger::V1::Universalledger::QueryDataRequest'];

coerce 'QueryDataRequest',
    from HashRef, via { 'Google::Cloud::Universalledger::V1::Universalledger::QueryDataRequest'->new($_) };

declare 'RepeatedQueryDataRequest',
    as ArrayRef[QueryDataRequest()];

coerce 'RepeatedQueryDataRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Universalledger::V1::Universalledger::QueryDataRequest'->new($_) } @$_ ] };

declare 'MapStringQueryDataRequest',
    as HashRef[QueryDataRequest()];

declare 'QueryDataResponse',
    as InstanceOf['Google::Cloud::Universalledger::V1::Universalledger::QueryDataResponse'];

coerce 'QueryDataResponse',
    from HashRef, via { 'Google::Cloud::Universalledger::V1::Universalledger::QueryDataResponse'->new($_) };

declare 'RepeatedQueryDataResponse',
    as ArrayRef[QueryDataResponse()];

coerce 'RepeatedQueryDataResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Universalledger::V1::Universalledger::QueryDataResponse'->new($_) } @$_ ] };

declare 'MapStringQueryDataResponse',
    as HashRef[QueryDataResponse()];

1;

__END__

=head1 NAME

Google::Cloud::Universalledger::V1::Universalledger::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
