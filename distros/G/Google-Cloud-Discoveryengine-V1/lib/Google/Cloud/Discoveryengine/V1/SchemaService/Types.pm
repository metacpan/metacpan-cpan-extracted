package Google::Cloud::Discoveryengine::V1::SchemaService::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'GetSchemaRequest',
    as InstanceOf['Google::Cloud::Discoveryengine::V1::SchemaService::GetSchemaRequest'];

coerce 'GetSchemaRequest',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1::SchemaService::GetSchemaRequest'->new($_) };

declare 'RepeatedGetSchemaRequest',
    as ArrayRef[GetSchemaRequest()];

coerce 'RepeatedGetSchemaRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1::SchemaService::GetSchemaRequest'->new($_) } @$_ ] };

declare 'MapStringGetSchemaRequest',
    as HashRef[GetSchemaRequest()];

declare 'ListSchemasRequest',
    as InstanceOf['Google::Cloud::Discoveryengine::V1::SchemaService::ListSchemasRequest'];

coerce 'ListSchemasRequest',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1::SchemaService::ListSchemasRequest'->new($_) };

declare 'RepeatedListSchemasRequest',
    as ArrayRef[ListSchemasRequest()];

coerce 'RepeatedListSchemasRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1::SchemaService::ListSchemasRequest'->new($_) } @$_ ] };

declare 'MapStringListSchemasRequest',
    as HashRef[ListSchemasRequest()];

declare 'ListSchemasResponse',
    as InstanceOf['Google::Cloud::Discoveryengine::V1::SchemaService::ListSchemasResponse'];

coerce 'ListSchemasResponse',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1::SchemaService::ListSchemasResponse'->new($_) };

declare 'RepeatedListSchemasResponse',
    as ArrayRef[ListSchemasResponse()];

coerce 'RepeatedListSchemasResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1::SchemaService::ListSchemasResponse'->new($_) } @$_ ] };

declare 'MapStringListSchemasResponse',
    as HashRef[ListSchemasResponse()];

declare 'CreateSchemaRequest',
    as InstanceOf['Google::Cloud::Discoveryengine::V1::SchemaService::CreateSchemaRequest'];

coerce 'CreateSchemaRequest',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1::SchemaService::CreateSchemaRequest'->new($_) };

declare 'RepeatedCreateSchemaRequest',
    as ArrayRef[CreateSchemaRequest()];

coerce 'RepeatedCreateSchemaRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1::SchemaService::CreateSchemaRequest'->new($_) } @$_ ] };

declare 'MapStringCreateSchemaRequest',
    as HashRef[CreateSchemaRequest()];

declare 'UpdateSchemaRequest',
    as InstanceOf['Google::Cloud::Discoveryengine::V1::SchemaService::UpdateSchemaRequest'];

coerce 'UpdateSchemaRequest',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1::SchemaService::UpdateSchemaRequest'->new($_) };

declare 'RepeatedUpdateSchemaRequest',
    as ArrayRef[UpdateSchemaRequest()];

coerce 'RepeatedUpdateSchemaRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1::SchemaService::UpdateSchemaRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateSchemaRequest',
    as HashRef[UpdateSchemaRequest()];

declare 'DeleteSchemaRequest',
    as InstanceOf['Google::Cloud::Discoveryengine::V1::SchemaService::DeleteSchemaRequest'];

coerce 'DeleteSchemaRequest',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1::SchemaService::DeleteSchemaRequest'->new($_) };

declare 'RepeatedDeleteSchemaRequest',
    as ArrayRef[DeleteSchemaRequest()];

coerce 'RepeatedDeleteSchemaRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1::SchemaService::DeleteSchemaRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteSchemaRequest',
    as HashRef[DeleteSchemaRequest()];

declare 'CreateSchemaMetadata',
    as InstanceOf['Google::Cloud::Discoveryengine::V1::SchemaService::CreateSchemaMetadata'];

coerce 'CreateSchemaMetadata',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1::SchemaService::CreateSchemaMetadata'->new($_) };

declare 'RepeatedCreateSchemaMetadata',
    as ArrayRef[CreateSchemaMetadata()];

coerce 'RepeatedCreateSchemaMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1::SchemaService::CreateSchemaMetadata'->new($_) } @$_ ] };

declare 'MapStringCreateSchemaMetadata',
    as HashRef[CreateSchemaMetadata()];

declare 'UpdateSchemaMetadata',
    as InstanceOf['Google::Cloud::Discoveryengine::V1::SchemaService::UpdateSchemaMetadata'];

coerce 'UpdateSchemaMetadata',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1::SchemaService::UpdateSchemaMetadata'->new($_) };

declare 'RepeatedUpdateSchemaMetadata',
    as ArrayRef[UpdateSchemaMetadata()];

coerce 'RepeatedUpdateSchemaMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1::SchemaService::UpdateSchemaMetadata'->new($_) } @$_ ] };

declare 'MapStringUpdateSchemaMetadata',
    as HashRef[UpdateSchemaMetadata()];

declare 'DeleteSchemaMetadata',
    as InstanceOf['Google::Cloud::Discoveryengine::V1::SchemaService::DeleteSchemaMetadata'];

coerce 'DeleteSchemaMetadata',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1::SchemaService::DeleteSchemaMetadata'->new($_) };

declare 'RepeatedDeleteSchemaMetadata',
    as ArrayRef[DeleteSchemaMetadata()];

coerce 'RepeatedDeleteSchemaMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1::SchemaService::DeleteSchemaMetadata'->new($_) } @$_ ] };

declare 'MapStringDeleteSchemaMetadata',
    as HashRef[DeleteSchemaMetadata()];

1;

__END__

=head1 NAME

Google::Cloud::Discoveryengine::V1::SchemaService::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
