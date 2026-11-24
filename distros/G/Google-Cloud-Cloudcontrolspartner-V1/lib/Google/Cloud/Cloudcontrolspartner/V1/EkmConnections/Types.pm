package Google::Cloud::Cloudcontrolspartner::V1::EkmConnections::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'EkmConnections',
    as InstanceOf['Google::Cloud::Cloudcontrolspartner::V1::EkmConnections::EkmConnections'];

coerce 'EkmConnections',
    from HashRef, via { 'Google::Cloud::Cloudcontrolspartner::V1::EkmConnections::EkmConnections'->new($_) };

declare 'RepeatedEkmConnections',
    as ArrayRef[EkmConnections()];

coerce 'RepeatedEkmConnections',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Cloudcontrolspartner::V1::EkmConnections::EkmConnections'->new($_) } @$_ ] };

declare 'MapStringEkmConnections',
    as HashRef[EkmConnections()];

declare 'GetEkmConnectionsRequest',
    as InstanceOf['Google::Cloud::Cloudcontrolspartner::V1::EkmConnections::GetEkmConnectionsRequest'];

coerce 'GetEkmConnectionsRequest',
    from HashRef, via { 'Google::Cloud::Cloudcontrolspartner::V1::EkmConnections::GetEkmConnectionsRequest'->new($_) };

declare 'RepeatedGetEkmConnectionsRequest',
    as ArrayRef[GetEkmConnectionsRequest()];

coerce 'RepeatedGetEkmConnectionsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Cloudcontrolspartner::V1::EkmConnections::GetEkmConnectionsRequest'->new($_) } @$_ ] };

declare 'MapStringGetEkmConnectionsRequest',
    as HashRef[GetEkmConnectionsRequest()];

declare 'EkmConnection',
    as InstanceOf['Google::Cloud::Cloudcontrolspartner::V1::EkmConnections::EkmConnection'];

coerce 'EkmConnection',
    from HashRef, via { 'Google::Cloud::Cloudcontrolspartner::V1::EkmConnections::EkmConnection'->new($_) };

declare 'RepeatedEkmConnection',
    as ArrayRef[EkmConnection()];

coerce 'RepeatedEkmConnection',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Cloudcontrolspartner::V1::EkmConnections::EkmConnection'->new($_) } @$_ ] };

declare 'MapStringEkmConnection',
    as HashRef[EkmConnection()];

declare 'ConnectionState',
    as (Int | Str);

declare 'ConnectionError',
    as InstanceOf['Google::Cloud::Cloudcontrolspartner::V1::EkmConnections::EkmConnection::ConnectionError'];

coerce 'ConnectionError',
    from HashRef, via { 'Google::Cloud::Cloudcontrolspartner::V1::EkmConnections::EkmConnection::ConnectionError'->new($_) };

declare 'RepeatedConnectionError',
    as ArrayRef[ConnectionError()];

coerce 'RepeatedConnectionError',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Cloudcontrolspartner::V1::EkmConnections::EkmConnection::ConnectionError'->new($_) } @$_ ] };

declare 'MapStringConnectionError',
    as HashRef[ConnectionError()];

1;

__END__

=head1 NAME

Google::Cloud::Cloudcontrolspartner::V1::EkmConnections::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
