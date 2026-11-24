package Google::Cloud::Beyondcorp::Clientgateways::V1::ClientGatewaysService::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'ClientGateway',
    as InstanceOf['Google::Cloud::Beyondcorp::Clientgateways::V1::ClientGatewaysService::ClientGateway'];

coerce 'ClientGateway',
    from HashRef, via { 'Google::Cloud::Beyondcorp::Clientgateways::V1::ClientGatewaysService::ClientGateway'->new($_) };

declare 'RepeatedClientGateway',
    as ArrayRef[ClientGateway()];

coerce 'RepeatedClientGateway',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Beyondcorp::Clientgateways::V1::ClientGatewaysService::ClientGateway'->new($_) } @$_ ] };

declare 'MapStringClientGateway',
    as HashRef[ClientGateway()];

declare 'State',
    as (Int | Str);

declare 'ListClientGatewaysRequest',
    as InstanceOf['Google::Cloud::Beyondcorp::Clientgateways::V1::ClientGatewaysService::ListClientGatewaysRequest'];

coerce 'ListClientGatewaysRequest',
    from HashRef, via { 'Google::Cloud::Beyondcorp::Clientgateways::V1::ClientGatewaysService::ListClientGatewaysRequest'->new($_) };

declare 'RepeatedListClientGatewaysRequest',
    as ArrayRef[ListClientGatewaysRequest()];

coerce 'RepeatedListClientGatewaysRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Beyondcorp::Clientgateways::V1::ClientGatewaysService::ListClientGatewaysRequest'->new($_) } @$_ ] };

declare 'MapStringListClientGatewaysRequest',
    as HashRef[ListClientGatewaysRequest()];

declare 'ListClientGatewaysResponse',
    as InstanceOf['Google::Cloud::Beyondcorp::Clientgateways::V1::ClientGatewaysService::ListClientGatewaysResponse'];

coerce 'ListClientGatewaysResponse',
    from HashRef, via { 'Google::Cloud::Beyondcorp::Clientgateways::V1::ClientGatewaysService::ListClientGatewaysResponse'->new($_) };

declare 'RepeatedListClientGatewaysResponse',
    as ArrayRef[ListClientGatewaysResponse()];

coerce 'RepeatedListClientGatewaysResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Beyondcorp::Clientgateways::V1::ClientGatewaysService::ListClientGatewaysResponse'->new($_) } @$_ ] };

declare 'MapStringListClientGatewaysResponse',
    as HashRef[ListClientGatewaysResponse()];

declare 'GetClientGatewayRequest',
    as InstanceOf['Google::Cloud::Beyondcorp::Clientgateways::V1::ClientGatewaysService::GetClientGatewayRequest'];

coerce 'GetClientGatewayRequest',
    from HashRef, via { 'Google::Cloud::Beyondcorp::Clientgateways::V1::ClientGatewaysService::GetClientGatewayRequest'->new($_) };

declare 'RepeatedGetClientGatewayRequest',
    as ArrayRef[GetClientGatewayRequest()];

coerce 'RepeatedGetClientGatewayRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Beyondcorp::Clientgateways::V1::ClientGatewaysService::GetClientGatewayRequest'->new($_) } @$_ ] };

declare 'MapStringGetClientGatewayRequest',
    as HashRef[GetClientGatewayRequest()];

declare 'CreateClientGatewayRequest',
    as InstanceOf['Google::Cloud::Beyondcorp::Clientgateways::V1::ClientGatewaysService::CreateClientGatewayRequest'];

coerce 'CreateClientGatewayRequest',
    from HashRef, via { 'Google::Cloud::Beyondcorp::Clientgateways::V1::ClientGatewaysService::CreateClientGatewayRequest'->new($_) };

declare 'RepeatedCreateClientGatewayRequest',
    as ArrayRef[CreateClientGatewayRequest()];

coerce 'RepeatedCreateClientGatewayRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Beyondcorp::Clientgateways::V1::ClientGatewaysService::CreateClientGatewayRequest'->new($_) } @$_ ] };

declare 'MapStringCreateClientGatewayRequest',
    as HashRef[CreateClientGatewayRequest()];

declare 'DeleteClientGatewayRequest',
    as InstanceOf['Google::Cloud::Beyondcorp::Clientgateways::V1::ClientGatewaysService::DeleteClientGatewayRequest'];

coerce 'DeleteClientGatewayRequest',
    from HashRef, via { 'Google::Cloud::Beyondcorp::Clientgateways::V1::ClientGatewaysService::DeleteClientGatewayRequest'->new($_) };

declare 'RepeatedDeleteClientGatewayRequest',
    as ArrayRef[DeleteClientGatewayRequest()];

coerce 'RepeatedDeleteClientGatewayRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Beyondcorp::Clientgateways::V1::ClientGatewaysService::DeleteClientGatewayRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteClientGatewayRequest',
    as HashRef[DeleteClientGatewayRequest()];

declare 'ClientGatewayOperationMetadata',
    as InstanceOf['Google::Cloud::Beyondcorp::Clientgateways::V1::ClientGatewaysService::ClientGatewayOperationMetadata'];

coerce 'ClientGatewayOperationMetadata',
    from HashRef, via { 'Google::Cloud::Beyondcorp::Clientgateways::V1::ClientGatewaysService::ClientGatewayOperationMetadata'->new($_) };

declare 'RepeatedClientGatewayOperationMetadata',
    as ArrayRef[ClientGatewayOperationMetadata()];

coerce 'RepeatedClientGatewayOperationMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Beyondcorp::Clientgateways::V1::ClientGatewaysService::ClientGatewayOperationMetadata'->new($_) } @$_ ] };

declare 'MapStringClientGatewayOperationMetadata',
    as HashRef[ClientGatewayOperationMetadata()];

1;

__END__

=head1 NAME

Google::Cloud::Beyondcorp::Clientgateways::V1::ClientGatewaysService::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
