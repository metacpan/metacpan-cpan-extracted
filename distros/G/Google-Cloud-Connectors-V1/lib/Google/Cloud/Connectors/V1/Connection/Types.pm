package Google::Cloud::Connectors::V1::Connection::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'DataType',
    as (Int | Str);

declare 'ConnectionView',
    as (Int | Str);

declare 'Connection',
    as InstanceOf['Google::Cloud::Connectors::V1::Connection::Connection'];

coerce 'Connection',
    from HashRef, via { 'Google::Cloud::Connectors::V1::Connection::Connection'->new($_) };

declare 'RepeatedConnection',
    as ArrayRef[Connection()];

coerce 'RepeatedConnection',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Connectors::V1::Connection::Connection'->new($_) } @$_ ] };

declare 'MapStringConnection',
    as HashRef[Connection()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Connectors::V1::Connection::Connection::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Connectors::V1::Connection::Connection::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Connectors::V1::Connection::Connection::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'NodeConfig',
    as InstanceOf['Google::Cloud::Connectors::V1::Connection::NodeConfig'];

coerce 'NodeConfig',
    from HashRef, via { 'Google::Cloud::Connectors::V1::Connection::NodeConfig'->new($_) };

declare 'RepeatedNodeConfig',
    as ArrayRef[NodeConfig()];

coerce 'RepeatedNodeConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Connectors::V1::Connection::NodeConfig'->new($_) } @$_ ] };

declare 'MapStringNodeConfig',
    as HashRef[NodeConfig()];

declare 'ConnectionSchemaMetadata',
    as InstanceOf['Google::Cloud::Connectors::V1::Connection::ConnectionSchemaMetadata'];

coerce 'ConnectionSchemaMetadata',
    from HashRef, via { 'Google::Cloud::Connectors::V1::Connection::ConnectionSchemaMetadata'->new($_) };

declare 'RepeatedConnectionSchemaMetadata',
    as ArrayRef[ConnectionSchemaMetadata()];

coerce 'RepeatedConnectionSchemaMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Connectors::V1::Connection::ConnectionSchemaMetadata'->new($_) } @$_ ] };

declare 'MapStringConnectionSchemaMetadata',
    as HashRef[ConnectionSchemaMetadata()];

declare 'State',
    as (Int | Str);

declare 'RuntimeEntitySchema',
    as InstanceOf['Google::Cloud::Connectors::V1::Connection::RuntimeEntitySchema'];

coerce 'RuntimeEntitySchema',
    from HashRef, via { 'Google::Cloud::Connectors::V1::Connection::RuntimeEntitySchema'->new($_) };

declare 'RepeatedRuntimeEntitySchema',
    as ArrayRef[RuntimeEntitySchema()];

coerce 'RepeatedRuntimeEntitySchema',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Connectors::V1::Connection::RuntimeEntitySchema'->new($_) } @$_ ] };

declare 'MapStringRuntimeEntitySchema',
    as HashRef[RuntimeEntitySchema()];

declare 'Field',
    as InstanceOf['Google::Cloud::Connectors::V1::Connection::RuntimeEntitySchema::Field'];

coerce 'Field',
    from HashRef, via { 'Google::Cloud::Connectors::V1::Connection::RuntimeEntitySchema::Field'->new($_) };

declare 'RepeatedField',
    as ArrayRef[Field()];

coerce 'RepeatedField',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Connectors::V1::Connection::RuntimeEntitySchema::Field'->new($_) } @$_ ] };

declare 'MapStringField',
    as HashRef[Field()];

declare 'RuntimeActionSchema',
    as InstanceOf['Google::Cloud::Connectors::V1::Connection::RuntimeActionSchema'];

coerce 'RuntimeActionSchema',
    from HashRef, via { 'Google::Cloud::Connectors::V1::Connection::RuntimeActionSchema'->new($_) };

declare 'RepeatedRuntimeActionSchema',
    as ArrayRef[RuntimeActionSchema()];

coerce 'RepeatedRuntimeActionSchema',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Connectors::V1::Connection::RuntimeActionSchema'->new($_) } @$_ ] };

declare 'MapStringRuntimeActionSchema',
    as HashRef[RuntimeActionSchema()];

declare 'InputParameter',
    as InstanceOf['Google::Cloud::Connectors::V1::Connection::RuntimeActionSchema::InputParameter'];

coerce 'InputParameter',
    from HashRef, via { 'Google::Cloud::Connectors::V1::Connection::RuntimeActionSchema::InputParameter'->new($_) };

declare 'RepeatedInputParameter',
    as ArrayRef[InputParameter()];

coerce 'RepeatedInputParameter',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Connectors::V1::Connection::RuntimeActionSchema::InputParameter'->new($_) } @$_ ] };

declare 'MapStringInputParameter',
    as HashRef[InputParameter()];

declare 'ResultMetadata',
    as InstanceOf['Google::Cloud::Connectors::V1::Connection::RuntimeActionSchema::ResultMetadata'];

coerce 'ResultMetadata',
    from HashRef, via { 'Google::Cloud::Connectors::V1::Connection::RuntimeActionSchema::ResultMetadata'->new($_) };

declare 'RepeatedResultMetadata',
    as ArrayRef[ResultMetadata()];

coerce 'RepeatedResultMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Connectors::V1::Connection::RuntimeActionSchema::ResultMetadata'->new($_) } @$_ ] };

declare 'MapStringResultMetadata',
    as HashRef[ResultMetadata()];

declare 'LockConfig',
    as InstanceOf['Google::Cloud::Connectors::V1::Connection::LockConfig'];

coerce 'LockConfig',
    from HashRef, via { 'Google::Cloud::Connectors::V1::Connection::LockConfig'->new($_) };

declare 'RepeatedLockConfig',
    as ArrayRef[LockConfig()];

coerce 'RepeatedLockConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Connectors::V1::Connection::LockConfig'->new($_) } @$_ ] };

declare 'MapStringLockConfig',
    as HashRef[LockConfig()];

declare 'ListConnectionsRequest',
    as InstanceOf['Google::Cloud::Connectors::V1::Connection::ListConnectionsRequest'];

coerce 'ListConnectionsRequest',
    from HashRef, via { 'Google::Cloud::Connectors::V1::Connection::ListConnectionsRequest'->new($_) };

declare 'RepeatedListConnectionsRequest',
    as ArrayRef[ListConnectionsRequest()];

coerce 'RepeatedListConnectionsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Connectors::V1::Connection::ListConnectionsRequest'->new($_) } @$_ ] };

declare 'MapStringListConnectionsRequest',
    as HashRef[ListConnectionsRequest()];

declare 'ListConnectionsResponse',
    as InstanceOf['Google::Cloud::Connectors::V1::Connection::ListConnectionsResponse'];

coerce 'ListConnectionsResponse',
    from HashRef, via { 'Google::Cloud::Connectors::V1::Connection::ListConnectionsResponse'->new($_) };

declare 'RepeatedListConnectionsResponse',
    as ArrayRef[ListConnectionsResponse()];

coerce 'RepeatedListConnectionsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Connectors::V1::Connection::ListConnectionsResponse'->new($_) } @$_ ] };

declare 'MapStringListConnectionsResponse',
    as HashRef[ListConnectionsResponse()];

declare 'GetConnectionRequest',
    as InstanceOf['Google::Cloud::Connectors::V1::Connection::GetConnectionRequest'];

coerce 'GetConnectionRequest',
    from HashRef, via { 'Google::Cloud::Connectors::V1::Connection::GetConnectionRequest'->new($_) };

declare 'RepeatedGetConnectionRequest',
    as ArrayRef[GetConnectionRequest()];

coerce 'RepeatedGetConnectionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Connectors::V1::Connection::GetConnectionRequest'->new($_) } @$_ ] };

declare 'MapStringGetConnectionRequest',
    as HashRef[GetConnectionRequest()];

declare 'CreateConnectionRequest',
    as InstanceOf['Google::Cloud::Connectors::V1::Connection::CreateConnectionRequest'];

coerce 'CreateConnectionRequest',
    from HashRef, via { 'Google::Cloud::Connectors::V1::Connection::CreateConnectionRequest'->new($_) };

declare 'RepeatedCreateConnectionRequest',
    as ArrayRef[CreateConnectionRequest()];

coerce 'RepeatedCreateConnectionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Connectors::V1::Connection::CreateConnectionRequest'->new($_) } @$_ ] };

declare 'MapStringCreateConnectionRequest',
    as HashRef[CreateConnectionRequest()];

declare 'UpdateConnectionRequest',
    as InstanceOf['Google::Cloud::Connectors::V1::Connection::UpdateConnectionRequest'];

coerce 'UpdateConnectionRequest',
    from HashRef, via { 'Google::Cloud::Connectors::V1::Connection::UpdateConnectionRequest'->new($_) };

declare 'RepeatedUpdateConnectionRequest',
    as ArrayRef[UpdateConnectionRequest()];

coerce 'RepeatedUpdateConnectionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Connectors::V1::Connection::UpdateConnectionRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateConnectionRequest',
    as HashRef[UpdateConnectionRequest()];

declare 'DeleteConnectionRequest',
    as InstanceOf['Google::Cloud::Connectors::V1::Connection::DeleteConnectionRequest'];

coerce 'DeleteConnectionRequest',
    from HashRef, via { 'Google::Cloud::Connectors::V1::Connection::DeleteConnectionRequest'->new($_) };

declare 'RepeatedDeleteConnectionRequest',
    as ArrayRef[DeleteConnectionRequest()];

coerce 'RepeatedDeleteConnectionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Connectors::V1::Connection::DeleteConnectionRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteConnectionRequest',
    as HashRef[DeleteConnectionRequest()];

declare 'GetConnectionSchemaMetadataRequest',
    as InstanceOf['Google::Cloud::Connectors::V1::Connection::GetConnectionSchemaMetadataRequest'];

coerce 'GetConnectionSchemaMetadataRequest',
    from HashRef, via { 'Google::Cloud::Connectors::V1::Connection::GetConnectionSchemaMetadataRequest'->new($_) };

declare 'RepeatedGetConnectionSchemaMetadataRequest',
    as ArrayRef[GetConnectionSchemaMetadataRequest()];

coerce 'RepeatedGetConnectionSchemaMetadataRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Connectors::V1::Connection::GetConnectionSchemaMetadataRequest'->new($_) } @$_ ] };

declare 'MapStringGetConnectionSchemaMetadataRequest',
    as HashRef[GetConnectionSchemaMetadataRequest()];

declare 'RefreshConnectionSchemaMetadataRequest',
    as InstanceOf['Google::Cloud::Connectors::V1::Connection::RefreshConnectionSchemaMetadataRequest'];

coerce 'RefreshConnectionSchemaMetadataRequest',
    from HashRef, via { 'Google::Cloud::Connectors::V1::Connection::RefreshConnectionSchemaMetadataRequest'->new($_) };

declare 'RepeatedRefreshConnectionSchemaMetadataRequest',
    as ArrayRef[RefreshConnectionSchemaMetadataRequest()];

coerce 'RepeatedRefreshConnectionSchemaMetadataRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Connectors::V1::Connection::RefreshConnectionSchemaMetadataRequest'->new($_) } @$_ ] };

declare 'MapStringRefreshConnectionSchemaMetadataRequest',
    as HashRef[RefreshConnectionSchemaMetadataRequest()];

declare 'ListRuntimeEntitySchemasRequest',
    as InstanceOf['Google::Cloud::Connectors::V1::Connection::ListRuntimeEntitySchemasRequest'];

coerce 'ListRuntimeEntitySchemasRequest',
    from HashRef, via { 'Google::Cloud::Connectors::V1::Connection::ListRuntimeEntitySchemasRequest'->new($_) };

declare 'RepeatedListRuntimeEntitySchemasRequest',
    as ArrayRef[ListRuntimeEntitySchemasRequest()];

coerce 'RepeatedListRuntimeEntitySchemasRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Connectors::V1::Connection::ListRuntimeEntitySchemasRequest'->new($_) } @$_ ] };

declare 'MapStringListRuntimeEntitySchemasRequest',
    as HashRef[ListRuntimeEntitySchemasRequest()];

declare 'ListRuntimeEntitySchemasResponse',
    as InstanceOf['Google::Cloud::Connectors::V1::Connection::ListRuntimeEntitySchemasResponse'];

coerce 'ListRuntimeEntitySchemasResponse',
    from HashRef, via { 'Google::Cloud::Connectors::V1::Connection::ListRuntimeEntitySchemasResponse'->new($_) };

declare 'RepeatedListRuntimeEntitySchemasResponse',
    as ArrayRef[ListRuntimeEntitySchemasResponse()];

coerce 'RepeatedListRuntimeEntitySchemasResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Connectors::V1::Connection::ListRuntimeEntitySchemasResponse'->new($_) } @$_ ] };

declare 'MapStringListRuntimeEntitySchemasResponse',
    as HashRef[ListRuntimeEntitySchemasResponse()];

declare 'ListRuntimeActionSchemasRequest',
    as InstanceOf['Google::Cloud::Connectors::V1::Connection::ListRuntimeActionSchemasRequest'];

coerce 'ListRuntimeActionSchemasRequest',
    from HashRef, via { 'Google::Cloud::Connectors::V1::Connection::ListRuntimeActionSchemasRequest'->new($_) };

declare 'RepeatedListRuntimeActionSchemasRequest',
    as ArrayRef[ListRuntimeActionSchemasRequest()];

coerce 'RepeatedListRuntimeActionSchemasRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Connectors::V1::Connection::ListRuntimeActionSchemasRequest'->new($_) } @$_ ] };

declare 'MapStringListRuntimeActionSchemasRequest',
    as HashRef[ListRuntimeActionSchemasRequest()];

declare 'ListRuntimeActionSchemasResponse',
    as InstanceOf['Google::Cloud::Connectors::V1::Connection::ListRuntimeActionSchemasResponse'];

coerce 'ListRuntimeActionSchemasResponse',
    from HashRef, via { 'Google::Cloud::Connectors::V1::Connection::ListRuntimeActionSchemasResponse'->new($_) };

declare 'RepeatedListRuntimeActionSchemasResponse',
    as ArrayRef[ListRuntimeActionSchemasResponse()];

coerce 'RepeatedListRuntimeActionSchemasResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Connectors::V1::Connection::ListRuntimeActionSchemasResponse'->new($_) } @$_ ] };

declare 'MapStringListRuntimeActionSchemasResponse',
    as HashRef[ListRuntimeActionSchemasResponse()];

declare 'ConnectionStatus',
    as InstanceOf['Google::Cloud::Connectors::V1::Connection::ConnectionStatus'];

coerce 'ConnectionStatus',
    from HashRef, via { 'Google::Cloud::Connectors::V1::Connection::ConnectionStatus'->new($_) };

declare 'RepeatedConnectionStatus',
    as ArrayRef[ConnectionStatus()];

coerce 'RepeatedConnectionStatus',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Connectors::V1::Connection::ConnectionStatus'->new($_) } @$_ ] };

declare 'MapStringConnectionStatus',
    as HashRef[ConnectionStatus()];

declare 'State',
    as (Int | Str);

1;

__END__

=head1 NAME

Google::Cloud::Connectors::V1::Connection::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
