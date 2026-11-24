package Google::Cloud::Apigeeconnect::V1::Connection::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'ListConnectionsRequest',
    as InstanceOf['Google::Cloud::Apigeeconnect::V1::Connection::ListConnectionsRequest'];

coerce 'ListConnectionsRequest',
    from HashRef, via { 'Google::Cloud::Apigeeconnect::V1::Connection::ListConnectionsRequest'->new($_) };

declare 'RepeatedListConnectionsRequest',
    as ArrayRef[ListConnectionsRequest()];

coerce 'RepeatedListConnectionsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apigeeconnect::V1::Connection::ListConnectionsRequest'->new($_) } @$_ ] };

declare 'MapStringListConnectionsRequest',
    as HashRef[ListConnectionsRequest()];

declare 'ListConnectionsResponse',
    as InstanceOf['Google::Cloud::Apigeeconnect::V1::Connection::ListConnectionsResponse'];

coerce 'ListConnectionsResponse',
    from HashRef, via { 'Google::Cloud::Apigeeconnect::V1::Connection::ListConnectionsResponse'->new($_) };

declare 'RepeatedListConnectionsResponse',
    as ArrayRef[ListConnectionsResponse()];

coerce 'RepeatedListConnectionsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apigeeconnect::V1::Connection::ListConnectionsResponse'->new($_) } @$_ ] };

declare 'MapStringListConnectionsResponse',
    as HashRef[ListConnectionsResponse()];

declare 'Connection',
    as InstanceOf['Google::Cloud::Apigeeconnect::V1::Connection::Connection'];

coerce 'Connection',
    from HashRef, via { 'Google::Cloud::Apigeeconnect::V1::Connection::Connection'->new($_) };

declare 'RepeatedConnection',
    as ArrayRef[Connection()];

coerce 'RepeatedConnection',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apigeeconnect::V1::Connection::Connection'->new($_) } @$_ ] };

declare 'MapStringConnection',
    as HashRef[Connection()];

declare 'Cluster',
    as InstanceOf['Google::Cloud::Apigeeconnect::V1::Connection::Cluster'];

coerce 'Cluster',
    from HashRef, via { 'Google::Cloud::Apigeeconnect::V1::Connection::Cluster'->new($_) };

declare 'RepeatedCluster',
    as ArrayRef[Cluster()];

coerce 'RepeatedCluster',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apigeeconnect::V1::Connection::Cluster'->new($_) } @$_ ] };

declare 'MapStringCluster',
    as HashRef[Cluster()];

1;

__END__

=head1 NAME

Google::Cloud::Apigeeconnect::V1::Connection::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
