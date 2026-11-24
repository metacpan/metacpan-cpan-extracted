package Google::Cloud::Contentwarehouse::V1::DocumentSchemaService::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'CreateDocumentSchemaRequest',
    as InstanceOf['Google::Cloud::Contentwarehouse::V1::DocumentSchemaService::CreateDocumentSchemaRequest'];

coerce 'CreateDocumentSchemaRequest',
    from HashRef, via { 'Google::Cloud::Contentwarehouse::V1::DocumentSchemaService::CreateDocumentSchemaRequest'->new($_) };

declare 'RepeatedCreateDocumentSchemaRequest',
    as ArrayRef[CreateDocumentSchemaRequest()];

coerce 'RepeatedCreateDocumentSchemaRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contentwarehouse::V1::DocumentSchemaService::CreateDocumentSchemaRequest'->new($_) } @$_ ] };

declare 'MapStringCreateDocumentSchemaRequest',
    as HashRef[CreateDocumentSchemaRequest()];

declare 'GetDocumentSchemaRequest',
    as InstanceOf['Google::Cloud::Contentwarehouse::V1::DocumentSchemaService::GetDocumentSchemaRequest'];

coerce 'GetDocumentSchemaRequest',
    from HashRef, via { 'Google::Cloud::Contentwarehouse::V1::DocumentSchemaService::GetDocumentSchemaRequest'->new($_) };

declare 'RepeatedGetDocumentSchemaRequest',
    as ArrayRef[GetDocumentSchemaRequest()];

coerce 'RepeatedGetDocumentSchemaRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contentwarehouse::V1::DocumentSchemaService::GetDocumentSchemaRequest'->new($_) } @$_ ] };

declare 'MapStringGetDocumentSchemaRequest',
    as HashRef[GetDocumentSchemaRequest()];

declare 'UpdateDocumentSchemaRequest',
    as InstanceOf['Google::Cloud::Contentwarehouse::V1::DocumentSchemaService::UpdateDocumentSchemaRequest'];

coerce 'UpdateDocumentSchemaRequest',
    from HashRef, via { 'Google::Cloud::Contentwarehouse::V1::DocumentSchemaService::UpdateDocumentSchemaRequest'->new($_) };

declare 'RepeatedUpdateDocumentSchemaRequest',
    as ArrayRef[UpdateDocumentSchemaRequest()];

coerce 'RepeatedUpdateDocumentSchemaRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contentwarehouse::V1::DocumentSchemaService::UpdateDocumentSchemaRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateDocumentSchemaRequest',
    as HashRef[UpdateDocumentSchemaRequest()];

declare 'DeleteDocumentSchemaRequest',
    as InstanceOf['Google::Cloud::Contentwarehouse::V1::DocumentSchemaService::DeleteDocumentSchemaRequest'];

coerce 'DeleteDocumentSchemaRequest',
    from HashRef, via { 'Google::Cloud::Contentwarehouse::V1::DocumentSchemaService::DeleteDocumentSchemaRequest'->new($_) };

declare 'RepeatedDeleteDocumentSchemaRequest',
    as ArrayRef[DeleteDocumentSchemaRequest()];

coerce 'RepeatedDeleteDocumentSchemaRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contentwarehouse::V1::DocumentSchemaService::DeleteDocumentSchemaRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteDocumentSchemaRequest',
    as HashRef[DeleteDocumentSchemaRequest()];

declare 'ListDocumentSchemasRequest',
    as InstanceOf['Google::Cloud::Contentwarehouse::V1::DocumentSchemaService::ListDocumentSchemasRequest'];

coerce 'ListDocumentSchemasRequest',
    from HashRef, via { 'Google::Cloud::Contentwarehouse::V1::DocumentSchemaService::ListDocumentSchemasRequest'->new($_) };

declare 'RepeatedListDocumentSchemasRequest',
    as ArrayRef[ListDocumentSchemasRequest()];

coerce 'RepeatedListDocumentSchemasRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contentwarehouse::V1::DocumentSchemaService::ListDocumentSchemasRequest'->new($_) } @$_ ] };

declare 'MapStringListDocumentSchemasRequest',
    as HashRef[ListDocumentSchemasRequest()];

declare 'ListDocumentSchemasResponse',
    as InstanceOf['Google::Cloud::Contentwarehouse::V1::DocumentSchemaService::ListDocumentSchemasResponse'];

coerce 'ListDocumentSchemasResponse',
    from HashRef, via { 'Google::Cloud::Contentwarehouse::V1::DocumentSchemaService::ListDocumentSchemasResponse'->new($_) };

declare 'RepeatedListDocumentSchemasResponse',
    as ArrayRef[ListDocumentSchemasResponse()];

coerce 'RepeatedListDocumentSchemasResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contentwarehouse::V1::DocumentSchemaService::ListDocumentSchemasResponse'->new($_) } @$_ ] };

declare 'MapStringListDocumentSchemasResponse',
    as HashRef[ListDocumentSchemasResponse()];

1;

__END__

=head1 NAME

Google::Cloud::Contentwarehouse::V1::DocumentSchemaService::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
