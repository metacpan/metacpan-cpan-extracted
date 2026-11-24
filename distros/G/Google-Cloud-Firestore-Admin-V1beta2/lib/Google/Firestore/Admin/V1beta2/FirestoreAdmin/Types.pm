package Google::Firestore::Admin::V1beta2::FirestoreAdmin::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'CreateIndexRequest',
    as InstanceOf['Google::Firestore::Admin::V1beta2::FirestoreAdmin::CreateIndexRequest'];

coerce 'CreateIndexRequest',
    from HashRef, via { 'Google::Firestore::Admin::V1beta2::FirestoreAdmin::CreateIndexRequest'->new($_) };

declare 'RepeatedCreateIndexRequest',
    as ArrayRef[CreateIndexRequest()];

coerce 'RepeatedCreateIndexRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Firestore::Admin::V1beta2::FirestoreAdmin::CreateIndexRequest'->new($_) } @$_ ] };

declare 'MapStringCreateIndexRequest',
    as HashRef[CreateIndexRequest()];

declare 'ListIndexesRequest',
    as InstanceOf['Google::Firestore::Admin::V1beta2::FirestoreAdmin::ListIndexesRequest'];

coerce 'ListIndexesRequest',
    from HashRef, via { 'Google::Firestore::Admin::V1beta2::FirestoreAdmin::ListIndexesRequest'->new($_) };

declare 'RepeatedListIndexesRequest',
    as ArrayRef[ListIndexesRequest()];

coerce 'RepeatedListIndexesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Firestore::Admin::V1beta2::FirestoreAdmin::ListIndexesRequest'->new($_) } @$_ ] };

declare 'MapStringListIndexesRequest',
    as HashRef[ListIndexesRequest()];

declare 'ListIndexesResponse',
    as InstanceOf['Google::Firestore::Admin::V1beta2::FirestoreAdmin::ListIndexesResponse'];

coerce 'ListIndexesResponse',
    from HashRef, via { 'Google::Firestore::Admin::V1beta2::FirestoreAdmin::ListIndexesResponse'->new($_) };

declare 'RepeatedListIndexesResponse',
    as ArrayRef[ListIndexesResponse()];

coerce 'RepeatedListIndexesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Firestore::Admin::V1beta2::FirestoreAdmin::ListIndexesResponse'->new($_) } @$_ ] };

declare 'MapStringListIndexesResponse',
    as HashRef[ListIndexesResponse()];

declare 'GetIndexRequest',
    as InstanceOf['Google::Firestore::Admin::V1beta2::FirestoreAdmin::GetIndexRequest'];

coerce 'GetIndexRequest',
    from HashRef, via { 'Google::Firestore::Admin::V1beta2::FirestoreAdmin::GetIndexRequest'->new($_) };

declare 'RepeatedGetIndexRequest',
    as ArrayRef[GetIndexRequest()];

coerce 'RepeatedGetIndexRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Firestore::Admin::V1beta2::FirestoreAdmin::GetIndexRequest'->new($_) } @$_ ] };

declare 'MapStringGetIndexRequest',
    as HashRef[GetIndexRequest()];

declare 'DeleteIndexRequest',
    as InstanceOf['Google::Firestore::Admin::V1beta2::FirestoreAdmin::DeleteIndexRequest'];

coerce 'DeleteIndexRequest',
    from HashRef, via { 'Google::Firestore::Admin::V1beta2::FirestoreAdmin::DeleteIndexRequest'->new($_) };

declare 'RepeatedDeleteIndexRequest',
    as ArrayRef[DeleteIndexRequest()];

coerce 'RepeatedDeleteIndexRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Firestore::Admin::V1beta2::FirestoreAdmin::DeleteIndexRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteIndexRequest',
    as HashRef[DeleteIndexRequest()];

declare 'UpdateFieldRequest',
    as InstanceOf['Google::Firestore::Admin::V1beta2::FirestoreAdmin::UpdateFieldRequest'];

coerce 'UpdateFieldRequest',
    from HashRef, via { 'Google::Firestore::Admin::V1beta2::FirestoreAdmin::UpdateFieldRequest'->new($_) };

declare 'RepeatedUpdateFieldRequest',
    as ArrayRef[UpdateFieldRequest()];

coerce 'RepeatedUpdateFieldRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Firestore::Admin::V1beta2::FirestoreAdmin::UpdateFieldRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateFieldRequest',
    as HashRef[UpdateFieldRequest()];

declare 'GetFieldRequest',
    as InstanceOf['Google::Firestore::Admin::V1beta2::FirestoreAdmin::GetFieldRequest'];

coerce 'GetFieldRequest',
    from HashRef, via { 'Google::Firestore::Admin::V1beta2::FirestoreAdmin::GetFieldRequest'->new($_) };

declare 'RepeatedGetFieldRequest',
    as ArrayRef[GetFieldRequest()];

coerce 'RepeatedGetFieldRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Firestore::Admin::V1beta2::FirestoreAdmin::GetFieldRequest'->new($_) } @$_ ] };

declare 'MapStringGetFieldRequest',
    as HashRef[GetFieldRequest()];

declare 'ListFieldsRequest',
    as InstanceOf['Google::Firestore::Admin::V1beta2::FirestoreAdmin::ListFieldsRequest'];

coerce 'ListFieldsRequest',
    from HashRef, via { 'Google::Firestore::Admin::V1beta2::FirestoreAdmin::ListFieldsRequest'->new($_) };

declare 'RepeatedListFieldsRequest',
    as ArrayRef[ListFieldsRequest()];

coerce 'RepeatedListFieldsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Firestore::Admin::V1beta2::FirestoreAdmin::ListFieldsRequest'->new($_) } @$_ ] };

declare 'MapStringListFieldsRequest',
    as HashRef[ListFieldsRequest()];

declare 'ListFieldsResponse',
    as InstanceOf['Google::Firestore::Admin::V1beta2::FirestoreAdmin::ListFieldsResponse'];

coerce 'ListFieldsResponse',
    from HashRef, via { 'Google::Firestore::Admin::V1beta2::FirestoreAdmin::ListFieldsResponse'->new($_) };

declare 'RepeatedListFieldsResponse',
    as ArrayRef[ListFieldsResponse()];

coerce 'RepeatedListFieldsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Firestore::Admin::V1beta2::FirestoreAdmin::ListFieldsResponse'->new($_) } @$_ ] };

declare 'MapStringListFieldsResponse',
    as HashRef[ListFieldsResponse()];

declare 'ExportDocumentsRequest',
    as InstanceOf['Google::Firestore::Admin::V1beta2::FirestoreAdmin::ExportDocumentsRequest'];

coerce 'ExportDocumentsRequest',
    from HashRef, via { 'Google::Firestore::Admin::V1beta2::FirestoreAdmin::ExportDocumentsRequest'->new($_) };

declare 'RepeatedExportDocumentsRequest',
    as ArrayRef[ExportDocumentsRequest()];

coerce 'RepeatedExportDocumentsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Firestore::Admin::V1beta2::FirestoreAdmin::ExportDocumentsRequest'->new($_) } @$_ ] };

declare 'MapStringExportDocumentsRequest',
    as HashRef[ExportDocumentsRequest()];

declare 'ImportDocumentsRequest',
    as InstanceOf['Google::Firestore::Admin::V1beta2::FirestoreAdmin::ImportDocumentsRequest'];

coerce 'ImportDocumentsRequest',
    from HashRef, via { 'Google::Firestore::Admin::V1beta2::FirestoreAdmin::ImportDocumentsRequest'->new($_) };

declare 'RepeatedImportDocumentsRequest',
    as ArrayRef[ImportDocumentsRequest()];

coerce 'RepeatedImportDocumentsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Firestore::Admin::V1beta2::FirestoreAdmin::ImportDocumentsRequest'->new($_) } @$_ ] };

declare 'MapStringImportDocumentsRequest',
    as HashRef[ImportDocumentsRequest()];

1;

__END__

=head1 NAME

Google::Firestore::Admin::V1beta2::FirestoreAdmin::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
