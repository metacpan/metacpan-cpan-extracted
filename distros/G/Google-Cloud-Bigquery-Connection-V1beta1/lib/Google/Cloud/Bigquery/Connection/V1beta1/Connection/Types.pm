package Google::Cloud::Bigquery::Connection::V1beta1::Connection::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'CreateConnectionRequest',
    as InstanceOf['Google::Cloud::Bigquery::Connection::V1beta1::Connection::CreateConnectionRequest'];

coerce 'CreateConnectionRequest',
    from HashRef, via { 'Google::Cloud::Bigquery::Connection::V1beta1::Connection::CreateConnectionRequest'->new($_) };

declare 'RepeatedCreateConnectionRequest',
    as ArrayRef[CreateConnectionRequest()];

coerce 'RepeatedCreateConnectionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Connection::V1beta1::Connection::CreateConnectionRequest'->new($_) } @$_ ] };

declare 'MapStringCreateConnectionRequest',
    as HashRef[CreateConnectionRequest()];

declare 'GetConnectionRequest',
    as InstanceOf['Google::Cloud::Bigquery::Connection::V1beta1::Connection::GetConnectionRequest'];

coerce 'GetConnectionRequest',
    from HashRef, via { 'Google::Cloud::Bigquery::Connection::V1beta1::Connection::GetConnectionRequest'->new($_) };

declare 'RepeatedGetConnectionRequest',
    as ArrayRef[GetConnectionRequest()];

coerce 'RepeatedGetConnectionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Connection::V1beta1::Connection::GetConnectionRequest'->new($_) } @$_ ] };

declare 'MapStringGetConnectionRequest',
    as HashRef[GetConnectionRequest()];

declare 'ListConnectionsRequest',
    as InstanceOf['Google::Cloud::Bigquery::Connection::V1beta1::Connection::ListConnectionsRequest'];

coerce 'ListConnectionsRequest',
    from HashRef, via { 'Google::Cloud::Bigquery::Connection::V1beta1::Connection::ListConnectionsRequest'->new($_) };

declare 'RepeatedListConnectionsRequest',
    as ArrayRef[ListConnectionsRequest()];

coerce 'RepeatedListConnectionsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Connection::V1beta1::Connection::ListConnectionsRequest'->new($_) } @$_ ] };

declare 'MapStringListConnectionsRequest',
    as HashRef[ListConnectionsRequest()];

declare 'ListConnectionsResponse',
    as InstanceOf['Google::Cloud::Bigquery::Connection::V1beta1::Connection::ListConnectionsResponse'];

coerce 'ListConnectionsResponse',
    from HashRef, via { 'Google::Cloud::Bigquery::Connection::V1beta1::Connection::ListConnectionsResponse'->new($_) };

declare 'RepeatedListConnectionsResponse',
    as ArrayRef[ListConnectionsResponse()];

coerce 'RepeatedListConnectionsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Connection::V1beta1::Connection::ListConnectionsResponse'->new($_) } @$_ ] };

declare 'MapStringListConnectionsResponse',
    as HashRef[ListConnectionsResponse()];

declare 'UpdateConnectionRequest',
    as InstanceOf['Google::Cloud::Bigquery::Connection::V1beta1::Connection::UpdateConnectionRequest'];

coerce 'UpdateConnectionRequest',
    from HashRef, via { 'Google::Cloud::Bigquery::Connection::V1beta1::Connection::UpdateConnectionRequest'->new($_) };

declare 'RepeatedUpdateConnectionRequest',
    as ArrayRef[UpdateConnectionRequest()];

coerce 'RepeatedUpdateConnectionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Connection::V1beta1::Connection::UpdateConnectionRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateConnectionRequest',
    as HashRef[UpdateConnectionRequest()];

declare 'UpdateConnectionCredentialRequest',
    as InstanceOf['Google::Cloud::Bigquery::Connection::V1beta1::Connection::UpdateConnectionCredentialRequest'];

coerce 'UpdateConnectionCredentialRequest',
    from HashRef, via { 'Google::Cloud::Bigquery::Connection::V1beta1::Connection::UpdateConnectionCredentialRequest'->new($_) };

declare 'RepeatedUpdateConnectionCredentialRequest',
    as ArrayRef[UpdateConnectionCredentialRequest()];

coerce 'RepeatedUpdateConnectionCredentialRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Connection::V1beta1::Connection::UpdateConnectionCredentialRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateConnectionCredentialRequest',
    as HashRef[UpdateConnectionCredentialRequest()];

declare 'DeleteConnectionRequest',
    as InstanceOf['Google::Cloud::Bigquery::Connection::V1beta1::Connection::DeleteConnectionRequest'];

coerce 'DeleteConnectionRequest',
    from HashRef, via { 'Google::Cloud::Bigquery::Connection::V1beta1::Connection::DeleteConnectionRequest'->new($_) };

declare 'RepeatedDeleteConnectionRequest',
    as ArrayRef[DeleteConnectionRequest()];

coerce 'RepeatedDeleteConnectionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Connection::V1beta1::Connection::DeleteConnectionRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteConnectionRequest',
    as HashRef[DeleteConnectionRequest()];

declare 'Connection',
    as InstanceOf['Google::Cloud::Bigquery::Connection::V1beta1::Connection::Connection'];

coerce 'Connection',
    from HashRef, via { 'Google::Cloud::Bigquery::Connection::V1beta1::Connection::Connection'->new($_) };

declare 'RepeatedConnection',
    as ArrayRef[Connection()];

coerce 'RepeatedConnection',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Connection::V1beta1::Connection::Connection'->new($_) } @$_ ] };

declare 'MapStringConnection',
    as HashRef[Connection()];

declare 'ConnectionCredential',
    as InstanceOf['Google::Cloud::Bigquery::Connection::V1beta1::Connection::ConnectionCredential'];

coerce 'ConnectionCredential',
    from HashRef, via { 'Google::Cloud::Bigquery::Connection::V1beta1::Connection::ConnectionCredential'->new($_) };

declare 'RepeatedConnectionCredential',
    as ArrayRef[ConnectionCredential()];

coerce 'RepeatedConnectionCredential',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Connection::V1beta1::Connection::ConnectionCredential'->new($_) } @$_ ] };

declare 'MapStringConnectionCredential',
    as HashRef[ConnectionCredential()];

declare 'CloudSqlProperties',
    as InstanceOf['Google::Cloud::Bigquery::Connection::V1beta1::Connection::CloudSqlProperties'];

coerce 'CloudSqlProperties',
    from HashRef, via { 'Google::Cloud::Bigquery::Connection::V1beta1::Connection::CloudSqlProperties'->new($_) };

declare 'RepeatedCloudSqlProperties',
    as ArrayRef[CloudSqlProperties()];

coerce 'RepeatedCloudSqlProperties',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Connection::V1beta1::Connection::CloudSqlProperties'->new($_) } @$_ ] };

declare 'MapStringCloudSqlProperties',
    as HashRef[CloudSqlProperties()];

declare 'DatabaseType',
    as (Int | Str);

declare 'CloudSqlCredential',
    as InstanceOf['Google::Cloud::Bigquery::Connection::V1beta1::Connection::CloudSqlCredential'];

coerce 'CloudSqlCredential',
    from HashRef, via { 'Google::Cloud::Bigquery::Connection::V1beta1::Connection::CloudSqlCredential'->new($_) };

declare 'RepeatedCloudSqlCredential',
    as ArrayRef[CloudSqlCredential()];

coerce 'RepeatedCloudSqlCredential',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Connection::V1beta1::Connection::CloudSqlCredential'->new($_) } @$_ ] };

declare 'MapStringCloudSqlCredential',
    as HashRef[CloudSqlCredential()];

1;

__END__

=head1 NAME

Google::Cloud::Bigquery::Connection::V1beta1::Connection::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
