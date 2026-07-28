package Google::Pubsub::V1::Schema::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'SchemaView',
    as (Int | Str);

declare 'Encoding',
    as (Int | Str);

declare 'Schema',
    as InstanceOf['Google::Pubsub::V1::Schema::Schema'];

coerce 'Schema',
    from HashRef, via { 'Google::Pubsub::V1::Schema::Schema'->new($_) };

declare 'RepeatedSchema',
    as ArrayRef[Schema()];

coerce 'RepeatedSchema',
    from ArrayRef[HashRef], via { [ map { 'Google::Pubsub::V1::Schema::Schema'->new($_) } @$_ ] };

declare 'MapStringSchema',
    as HashRef[Schema()];

declare 'Type',
    as (Int | Str);

declare 'CreateSchemaRequest',
    as InstanceOf['Google::Pubsub::V1::Schema::CreateSchemaRequest'];

coerce 'CreateSchemaRequest',
    from HashRef, via { 'Google::Pubsub::V1::Schema::CreateSchemaRequest'->new($_) };

declare 'RepeatedCreateSchemaRequest',
    as ArrayRef[CreateSchemaRequest()];

coerce 'RepeatedCreateSchemaRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Pubsub::V1::Schema::CreateSchemaRequest'->new($_) } @$_ ] };

declare 'MapStringCreateSchemaRequest',
    as HashRef[CreateSchemaRequest()];

declare 'GetSchemaRequest',
    as InstanceOf['Google::Pubsub::V1::Schema::GetSchemaRequest'];

coerce 'GetSchemaRequest',
    from HashRef, via { 'Google::Pubsub::V1::Schema::GetSchemaRequest'->new($_) };

declare 'RepeatedGetSchemaRequest',
    as ArrayRef[GetSchemaRequest()];

coerce 'RepeatedGetSchemaRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Pubsub::V1::Schema::GetSchemaRequest'->new($_) } @$_ ] };

declare 'MapStringGetSchemaRequest',
    as HashRef[GetSchemaRequest()];

declare 'ListSchemasRequest',
    as InstanceOf['Google::Pubsub::V1::Schema::ListSchemasRequest'];

coerce 'ListSchemasRequest',
    from HashRef, via { 'Google::Pubsub::V1::Schema::ListSchemasRequest'->new($_) };

declare 'RepeatedListSchemasRequest',
    as ArrayRef[ListSchemasRequest()];

coerce 'RepeatedListSchemasRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Pubsub::V1::Schema::ListSchemasRequest'->new($_) } @$_ ] };

declare 'MapStringListSchemasRequest',
    as HashRef[ListSchemasRequest()];

declare 'ListSchemasResponse',
    as InstanceOf['Google::Pubsub::V1::Schema::ListSchemasResponse'];

coerce 'ListSchemasResponse',
    from HashRef, via { 'Google::Pubsub::V1::Schema::ListSchemasResponse'->new($_) };

declare 'RepeatedListSchemasResponse',
    as ArrayRef[ListSchemasResponse()];

coerce 'RepeatedListSchemasResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Pubsub::V1::Schema::ListSchemasResponse'->new($_) } @$_ ] };

declare 'MapStringListSchemasResponse',
    as HashRef[ListSchemasResponse()];

declare 'ListSchemaRevisionsRequest',
    as InstanceOf['Google::Pubsub::V1::Schema::ListSchemaRevisionsRequest'];

coerce 'ListSchemaRevisionsRequest',
    from HashRef, via { 'Google::Pubsub::V1::Schema::ListSchemaRevisionsRequest'->new($_) };

declare 'RepeatedListSchemaRevisionsRequest',
    as ArrayRef[ListSchemaRevisionsRequest()];

coerce 'RepeatedListSchemaRevisionsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Pubsub::V1::Schema::ListSchemaRevisionsRequest'->new($_) } @$_ ] };

declare 'MapStringListSchemaRevisionsRequest',
    as HashRef[ListSchemaRevisionsRequest()];

declare 'ListSchemaRevisionsResponse',
    as InstanceOf['Google::Pubsub::V1::Schema::ListSchemaRevisionsResponse'];

coerce 'ListSchemaRevisionsResponse',
    from HashRef, via { 'Google::Pubsub::V1::Schema::ListSchemaRevisionsResponse'->new($_) };

declare 'RepeatedListSchemaRevisionsResponse',
    as ArrayRef[ListSchemaRevisionsResponse()];

coerce 'RepeatedListSchemaRevisionsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Pubsub::V1::Schema::ListSchemaRevisionsResponse'->new($_) } @$_ ] };

declare 'MapStringListSchemaRevisionsResponse',
    as HashRef[ListSchemaRevisionsResponse()];

declare 'CommitSchemaRequest',
    as InstanceOf['Google::Pubsub::V1::Schema::CommitSchemaRequest'];

coerce 'CommitSchemaRequest',
    from HashRef, via { 'Google::Pubsub::V1::Schema::CommitSchemaRequest'->new($_) };

declare 'RepeatedCommitSchemaRequest',
    as ArrayRef[CommitSchemaRequest()];

coerce 'RepeatedCommitSchemaRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Pubsub::V1::Schema::CommitSchemaRequest'->new($_) } @$_ ] };

declare 'MapStringCommitSchemaRequest',
    as HashRef[CommitSchemaRequest()];

declare 'RollbackSchemaRequest',
    as InstanceOf['Google::Pubsub::V1::Schema::RollbackSchemaRequest'];

coerce 'RollbackSchemaRequest',
    from HashRef, via { 'Google::Pubsub::V1::Schema::RollbackSchemaRequest'->new($_) };

declare 'RepeatedRollbackSchemaRequest',
    as ArrayRef[RollbackSchemaRequest()];

coerce 'RepeatedRollbackSchemaRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Pubsub::V1::Schema::RollbackSchemaRequest'->new($_) } @$_ ] };

declare 'MapStringRollbackSchemaRequest',
    as HashRef[RollbackSchemaRequest()];

declare 'DeleteSchemaRevisionRequest',
    as InstanceOf['Google::Pubsub::V1::Schema::DeleteSchemaRevisionRequest'];

coerce 'DeleteSchemaRevisionRequest',
    from HashRef, via { 'Google::Pubsub::V1::Schema::DeleteSchemaRevisionRequest'->new($_) };

declare 'RepeatedDeleteSchemaRevisionRequest',
    as ArrayRef[DeleteSchemaRevisionRequest()];

coerce 'RepeatedDeleteSchemaRevisionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Pubsub::V1::Schema::DeleteSchemaRevisionRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteSchemaRevisionRequest',
    as HashRef[DeleteSchemaRevisionRequest()];

declare 'DeleteSchemaRequest',
    as InstanceOf['Google::Pubsub::V1::Schema::DeleteSchemaRequest'];

coerce 'DeleteSchemaRequest',
    from HashRef, via { 'Google::Pubsub::V1::Schema::DeleteSchemaRequest'->new($_) };

declare 'RepeatedDeleteSchemaRequest',
    as ArrayRef[DeleteSchemaRequest()];

coerce 'RepeatedDeleteSchemaRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Pubsub::V1::Schema::DeleteSchemaRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteSchemaRequest',
    as HashRef[DeleteSchemaRequest()];

declare 'ValidateSchemaRequest',
    as InstanceOf['Google::Pubsub::V1::Schema::ValidateSchemaRequest'];

coerce 'ValidateSchemaRequest',
    from HashRef, via { 'Google::Pubsub::V1::Schema::ValidateSchemaRequest'->new($_) };

declare 'RepeatedValidateSchemaRequest',
    as ArrayRef[ValidateSchemaRequest()];

coerce 'RepeatedValidateSchemaRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Pubsub::V1::Schema::ValidateSchemaRequest'->new($_) } @$_ ] };

declare 'MapStringValidateSchemaRequest',
    as HashRef[ValidateSchemaRequest()];

declare 'ValidateSchemaResponse',
    as InstanceOf['Google::Pubsub::V1::Schema::ValidateSchemaResponse'];

coerce 'ValidateSchemaResponse',
    from HashRef, via { 'Google::Pubsub::V1::Schema::ValidateSchemaResponse'->new($_) };

declare 'RepeatedValidateSchemaResponse',
    as ArrayRef[ValidateSchemaResponse()];

coerce 'RepeatedValidateSchemaResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Pubsub::V1::Schema::ValidateSchemaResponse'->new($_) } @$_ ] };

declare 'MapStringValidateSchemaResponse',
    as HashRef[ValidateSchemaResponse()];

declare 'ValidateMessageRequest',
    as InstanceOf['Google::Pubsub::V1::Schema::ValidateMessageRequest'];

coerce 'ValidateMessageRequest',
    from HashRef, via { 'Google::Pubsub::V1::Schema::ValidateMessageRequest'->new($_) };

declare 'RepeatedValidateMessageRequest',
    as ArrayRef[ValidateMessageRequest()];

coerce 'RepeatedValidateMessageRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Pubsub::V1::Schema::ValidateMessageRequest'->new($_) } @$_ ] };

declare 'MapStringValidateMessageRequest',
    as HashRef[ValidateMessageRequest()];

declare 'ValidateMessageResponse',
    as InstanceOf['Google::Pubsub::V1::Schema::ValidateMessageResponse'];

coerce 'ValidateMessageResponse',
    from HashRef, via { 'Google::Pubsub::V1::Schema::ValidateMessageResponse'->new($_) };

declare 'RepeatedValidateMessageResponse',
    as ArrayRef[ValidateMessageResponse()];

coerce 'RepeatedValidateMessageResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Pubsub::V1::Schema::ValidateMessageResponse'->new($_) } @$_ ] };

declare 'MapStringValidateMessageResponse',
    as HashRef[ValidateMessageResponse()];

1;

__END__

=head1 NAME

Google::Pubsub::V1::Schema::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
