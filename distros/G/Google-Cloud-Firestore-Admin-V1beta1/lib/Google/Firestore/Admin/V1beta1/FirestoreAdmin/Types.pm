package Google::Firestore::Admin::V1beta1::FirestoreAdmin::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'OperationState',
    as (Int | Str);

declare 'IndexOperationMetadata',
    as InstanceOf['Google::Firestore::Admin::V1beta1::FirestoreAdmin::IndexOperationMetadata'];

coerce 'IndexOperationMetadata',
    from HashRef, via { 'Google::Firestore::Admin::V1beta1::FirestoreAdmin::IndexOperationMetadata'->new($_) };

declare 'RepeatedIndexOperationMetadata',
    as ArrayRef[IndexOperationMetadata()];

coerce 'RepeatedIndexOperationMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Firestore::Admin::V1beta1::FirestoreAdmin::IndexOperationMetadata'->new($_) } @$_ ] };

declare 'MapStringIndexOperationMetadata',
    as HashRef[IndexOperationMetadata()];

declare 'OperationType',
    as (Int | Str);

declare 'Progress',
    as InstanceOf['Google::Firestore::Admin::V1beta1::FirestoreAdmin::Progress'];

coerce 'Progress',
    from HashRef, via { 'Google::Firestore::Admin::V1beta1::FirestoreAdmin::Progress'->new($_) };

declare 'RepeatedProgress',
    as ArrayRef[Progress()];

coerce 'RepeatedProgress',
    from ArrayRef[HashRef], via { [ map { 'Google::Firestore::Admin::V1beta1::FirestoreAdmin::Progress'->new($_) } @$_ ] };

declare 'MapStringProgress',
    as HashRef[Progress()];

declare 'CreateIndexRequest',
    as InstanceOf['Google::Firestore::Admin::V1beta1::FirestoreAdmin::CreateIndexRequest'];

coerce 'CreateIndexRequest',
    from HashRef, via { 'Google::Firestore::Admin::V1beta1::FirestoreAdmin::CreateIndexRequest'->new($_) };

declare 'RepeatedCreateIndexRequest',
    as ArrayRef[CreateIndexRequest()];

coerce 'RepeatedCreateIndexRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Firestore::Admin::V1beta1::FirestoreAdmin::CreateIndexRequest'->new($_) } @$_ ] };

declare 'MapStringCreateIndexRequest',
    as HashRef[CreateIndexRequest()];

declare 'GetIndexRequest',
    as InstanceOf['Google::Firestore::Admin::V1beta1::FirestoreAdmin::GetIndexRequest'];

coerce 'GetIndexRequest',
    from HashRef, via { 'Google::Firestore::Admin::V1beta1::FirestoreAdmin::GetIndexRequest'->new($_) };

declare 'RepeatedGetIndexRequest',
    as ArrayRef[GetIndexRequest()];

coerce 'RepeatedGetIndexRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Firestore::Admin::V1beta1::FirestoreAdmin::GetIndexRequest'->new($_) } @$_ ] };

declare 'MapStringGetIndexRequest',
    as HashRef[GetIndexRequest()];

declare 'ListIndexesRequest',
    as InstanceOf['Google::Firestore::Admin::V1beta1::FirestoreAdmin::ListIndexesRequest'];

coerce 'ListIndexesRequest',
    from HashRef, via { 'Google::Firestore::Admin::V1beta1::FirestoreAdmin::ListIndexesRequest'->new($_) };

declare 'RepeatedListIndexesRequest',
    as ArrayRef[ListIndexesRequest()];

coerce 'RepeatedListIndexesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Firestore::Admin::V1beta1::FirestoreAdmin::ListIndexesRequest'->new($_) } @$_ ] };

declare 'MapStringListIndexesRequest',
    as HashRef[ListIndexesRequest()];

declare 'DeleteIndexRequest',
    as InstanceOf['Google::Firestore::Admin::V1beta1::FirestoreAdmin::DeleteIndexRequest'];

coerce 'DeleteIndexRequest',
    from HashRef, via { 'Google::Firestore::Admin::V1beta1::FirestoreAdmin::DeleteIndexRequest'->new($_) };

declare 'RepeatedDeleteIndexRequest',
    as ArrayRef[DeleteIndexRequest()];

coerce 'RepeatedDeleteIndexRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Firestore::Admin::V1beta1::FirestoreAdmin::DeleteIndexRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteIndexRequest',
    as HashRef[DeleteIndexRequest()];

declare 'ListIndexesResponse',
    as InstanceOf['Google::Firestore::Admin::V1beta1::FirestoreAdmin::ListIndexesResponse'];

coerce 'ListIndexesResponse',
    from HashRef, via { 'Google::Firestore::Admin::V1beta1::FirestoreAdmin::ListIndexesResponse'->new($_) };

declare 'RepeatedListIndexesResponse',
    as ArrayRef[ListIndexesResponse()];

coerce 'RepeatedListIndexesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Firestore::Admin::V1beta1::FirestoreAdmin::ListIndexesResponse'->new($_) } @$_ ] };

declare 'MapStringListIndexesResponse',
    as HashRef[ListIndexesResponse()];

declare 'ExportDocumentsRequest',
    as InstanceOf['Google::Firestore::Admin::V1beta1::FirestoreAdmin::ExportDocumentsRequest'];

coerce 'ExportDocumentsRequest',
    from HashRef, via { 'Google::Firestore::Admin::V1beta1::FirestoreAdmin::ExportDocumentsRequest'->new($_) };

declare 'RepeatedExportDocumentsRequest',
    as ArrayRef[ExportDocumentsRequest()];

coerce 'RepeatedExportDocumentsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Firestore::Admin::V1beta1::FirestoreAdmin::ExportDocumentsRequest'->new($_) } @$_ ] };

declare 'MapStringExportDocumentsRequest',
    as HashRef[ExportDocumentsRequest()];

declare 'ImportDocumentsRequest',
    as InstanceOf['Google::Firestore::Admin::V1beta1::FirestoreAdmin::ImportDocumentsRequest'];

coerce 'ImportDocumentsRequest',
    from HashRef, via { 'Google::Firestore::Admin::V1beta1::FirestoreAdmin::ImportDocumentsRequest'->new($_) };

declare 'RepeatedImportDocumentsRequest',
    as ArrayRef[ImportDocumentsRequest()];

coerce 'RepeatedImportDocumentsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Firestore::Admin::V1beta1::FirestoreAdmin::ImportDocumentsRequest'->new($_) } @$_ ] };

declare 'MapStringImportDocumentsRequest',
    as HashRef[ImportDocumentsRequest()];

declare 'ExportDocumentsResponse',
    as InstanceOf['Google::Firestore::Admin::V1beta1::FirestoreAdmin::ExportDocumentsResponse'];

coerce 'ExportDocumentsResponse',
    from HashRef, via { 'Google::Firestore::Admin::V1beta1::FirestoreAdmin::ExportDocumentsResponse'->new($_) };

declare 'RepeatedExportDocumentsResponse',
    as ArrayRef[ExportDocumentsResponse()];

coerce 'RepeatedExportDocumentsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Firestore::Admin::V1beta1::FirestoreAdmin::ExportDocumentsResponse'->new($_) } @$_ ] };

declare 'MapStringExportDocumentsResponse',
    as HashRef[ExportDocumentsResponse()];

declare 'ExportDocumentsMetadata',
    as InstanceOf['Google::Firestore::Admin::V1beta1::FirestoreAdmin::ExportDocumentsMetadata'];

coerce 'ExportDocumentsMetadata',
    from HashRef, via { 'Google::Firestore::Admin::V1beta1::FirestoreAdmin::ExportDocumentsMetadata'->new($_) };

declare 'RepeatedExportDocumentsMetadata',
    as ArrayRef[ExportDocumentsMetadata()];

coerce 'RepeatedExportDocumentsMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Firestore::Admin::V1beta1::FirestoreAdmin::ExportDocumentsMetadata'->new($_) } @$_ ] };

declare 'MapStringExportDocumentsMetadata',
    as HashRef[ExportDocumentsMetadata()];

declare 'ImportDocumentsMetadata',
    as InstanceOf['Google::Firestore::Admin::V1beta1::FirestoreAdmin::ImportDocumentsMetadata'];

coerce 'ImportDocumentsMetadata',
    from HashRef, via { 'Google::Firestore::Admin::V1beta1::FirestoreAdmin::ImportDocumentsMetadata'->new($_) };

declare 'RepeatedImportDocumentsMetadata',
    as ArrayRef[ImportDocumentsMetadata()];

coerce 'RepeatedImportDocumentsMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Firestore::Admin::V1beta1::FirestoreAdmin::ImportDocumentsMetadata'->new($_) } @$_ ] };

declare 'MapStringImportDocumentsMetadata',
    as HashRef[ImportDocumentsMetadata()];

1;

__END__

=head1 NAME

Google::Firestore::Admin::V1beta1::FirestoreAdmin::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
