package Google::Datastore::Admin::V1::DatastoreAdmin::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'OperationType',
    as (Int | Str);

declare 'CommonMetadata',
    as InstanceOf['Google::Datastore::Admin::V1::DatastoreAdmin::CommonMetadata'];

coerce 'CommonMetadata',
    from HashRef, via { 'Google::Datastore::Admin::V1::DatastoreAdmin::CommonMetadata'->new($_) };

declare 'RepeatedCommonMetadata',
    as ArrayRef[CommonMetadata()];

coerce 'RepeatedCommonMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Datastore::Admin::V1::DatastoreAdmin::CommonMetadata'->new($_) } @$_ ] };

declare 'MapStringCommonMetadata',
    as HashRef[CommonMetadata()];

declare 'State',
    as (Int | Str);

declare 'LabelsEntry',
    as InstanceOf['Google::Datastore::Admin::V1::DatastoreAdmin::CommonMetadata::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Datastore::Admin::V1::DatastoreAdmin::CommonMetadata::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Datastore::Admin::V1::DatastoreAdmin::CommonMetadata::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'Progress',
    as InstanceOf['Google::Datastore::Admin::V1::DatastoreAdmin::Progress'];

coerce 'Progress',
    from HashRef, via { 'Google::Datastore::Admin::V1::DatastoreAdmin::Progress'->new($_) };

declare 'RepeatedProgress',
    as ArrayRef[Progress()];

coerce 'RepeatedProgress',
    from ArrayRef[HashRef], via { [ map { 'Google::Datastore::Admin::V1::DatastoreAdmin::Progress'->new($_) } @$_ ] };

declare 'MapStringProgress',
    as HashRef[Progress()];

declare 'ExportEntitiesRequest',
    as InstanceOf['Google::Datastore::Admin::V1::DatastoreAdmin::ExportEntitiesRequest'];

coerce 'ExportEntitiesRequest',
    from HashRef, via { 'Google::Datastore::Admin::V1::DatastoreAdmin::ExportEntitiesRequest'->new($_) };

declare 'RepeatedExportEntitiesRequest',
    as ArrayRef[ExportEntitiesRequest()];

coerce 'RepeatedExportEntitiesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Datastore::Admin::V1::DatastoreAdmin::ExportEntitiesRequest'->new($_) } @$_ ] };

declare 'MapStringExportEntitiesRequest',
    as HashRef[ExportEntitiesRequest()];

declare 'LabelsEntry',
    as InstanceOf['Google::Datastore::Admin::V1::DatastoreAdmin::ExportEntitiesRequest::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Datastore::Admin::V1::DatastoreAdmin::ExportEntitiesRequest::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Datastore::Admin::V1::DatastoreAdmin::ExportEntitiesRequest::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'ImportEntitiesRequest',
    as InstanceOf['Google::Datastore::Admin::V1::DatastoreAdmin::ImportEntitiesRequest'];

coerce 'ImportEntitiesRequest',
    from HashRef, via { 'Google::Datastore::Admin::V1::DatastoreAdmin::ImportEntitiesRequest'->new($_) };

declare 'RepeatedImportEntitiesRequest',
    as ArrayRef[ImportEntitiesRequest()];

coerce 'RepeatedImportEntitiesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Datastore::Admin::V1::DatastoreAdmin::ImportEntitiesRequest'->new($_) } @$_ ] };

declare 'MapStringImportEntitiesRequest',
    as HashRef[ImportEntitiesRequest()];

declare 'LabelsEntry',
    as InstanceOf['Google::Datastore::Admin::V1::DatastoreAdmin::ImportEntitiesRequest::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Datastore::Admin::V1::DatastoreAdmin::ImportEntitiesRequest::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Datastore::Admin::V1::DatastoreAdmin::ImportEntitiesRequest::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'ExportEntitiesResponse',
    as InstanceOf['Google::Datastore::Admin::V1::DatastoreAdmin::ExportEntitiesResponse'];

coerce 'ExportEntitiesResponse',
    from HashRef, via { 'Google::Datastore::Admin::V1::DatastoreAdmin::ExportEntitiesResponse'->new($_) };

declare 'RepeatedExportEntitiesResponse',
    as ArrayRef[ExportEntitiesResponse()];

coerce 'RepeatedExportEntitiesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Datastore::Admin::V1::DatastoreAdmin::ExportEntitiesResponse'->new($_) } @$_ ] };

declare 'MapStringExportEntitiesResponse',
    as HashRef[ExportEntitiesResponse()];

declare 'ExportEntitiesMetadata',
    as InstanceOf['Google::Datastore::Admin::V1::DatastoreAdmin::ExportEntitiesMetadata'];

coerce 'ExportEntitiesMetadata',
    from HashRef, via { 'Google::Datastore::Admin::V1::DatastoreAdmin::ExportEntitiesMetadata'->new($_) };

declare 'RepeatedExportEntitiesMetadata',
    as ArrayRef[ExportEntitiesMetadata()];

coerce 'RepeatedExportEntitiesMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Datastore::Admin::V1::DatastoreAdmin::ExportEntitiesMetadata'->new($_) } @$_ ] };

declare 'MapStringExportEntitiesMetadata',
    as HashRef[ExportEntitiesMetadata()];

declare 'ImportEntitiesMetadata',
    as InstanceOf['Google::Datastore::Admin::V1::DatastoreAdmin::ImportEntitiesMetadata'];

coerce 'ImportEntitiesMetadata',
    from HashRef, via { 'Google::Datastore::Admin::V1::DatastoreAdmin::ImportEntitiesMetadata'->new($_) };

declare 'RepeatedImportEntitiesMetadata',
    as ArrayRef[ImportEntitiesMetadata()];

coerce 'RepeatedImportEntitiesMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Datastore::Admin::V1::DatastoreAdmin::ImportEntitiesMetadata'->new($_) } @$_ ] };

declare 'MapStringImportEntitiesMetadata',
    as HashRef[ImportEntitiesMetadata()];

declare 'EntityFilter',
    as InstanceOf['Google::Datastore::Admin::V1::DatastoreAdmin::EntityFilter'];

coerce 'EntityFilter',
    from HashRef, via { 'Google::Datastore::Admin::V1::DatastoreAdmin::EntityFilter'->new($_) };

declare 'RepeatedEntityFilter',
    as ArrayRef[EntityFilter()];

coerce 'RepeatedEntityFilter',
    from ArrayRef[HashRef], via { [ map { 'Google::Datastore::Admin::V1::DatastoreAdmin::EntityFilter'->new($_) } @$_ ] };

declare 'MapStringEntityFilter',
    as HashRef[EntityFilter()];

declare 'CreateIndexRequest',
    as InstanceOf['Google::Datastore::Admin::V1::DatastoreAdmin::CreateIndexRequest'];

coerce 'CreateIndexRequest',
    from HashRef, via { 'Google::Datastore::Admin::V1::DatastoreAdmin::CreateIndexRequest'->new($_) };

declare 'RepeatedCreateIndexRequest',
    as ArrayRef[CreateIndexRequest()];

coerce 'RepeatedCreateIndexRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Datastore::Admin::V1::DatastoreAdmin::CreateIndexRequest'->new($_) } @$_ ] };

declare 'MapStringCreateIndexRequest',
    as HashRef[CreateIndexRequest()];

declare 'DeleteIndexRequest',
    as InstanceOf['Google::Datastore::Admin::V1::DatastoreAdmin::DeleteIndexRequest'];

coerce 'DeleteIndexRequest',
    from HashRef, via { 'Google::Datastore::Admin::V1::DatastoreAdmin::DeleteIndexRequest'->new($_) };

declare 'RepeatedDeleteIndexRequest',
    as ArrayRef[DeleteIndexRequest()];

coerce 'RepeatedDeleteIndexRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Datastore::Admin::V1::DatastoreAdmin::DeleteIndexRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteIndexRequest',
    as HashRef[DeleteIndexRequest()];

declare 'GetIndexRequest',
    as InstanceOf['Google::Datastore::Admin::V1::DatastoreAdmin::GetIndexRequest'];

coerce 'GetIndexRequest',
    from HashRef, via { 'Google::Datastore::Admin::V1::DatastoreAdmin::GetIndexRequest'->new($_) };

declare 'RepeatedGetIndexRequest',
    as ArrayRef[GetIndexRequest()];

coerce 'RepeatedGetIndexRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Datastore::Admin::V1::DatastoreAdmin::GetIndexRequest'->new($_) } @$_ ] };

declare 'MapStringGetIndexRequest',
    as HashRef[GetIndexRequest()];

declare 'ListIndexesRequest',
    as InstanceOf['Google::Datastore::Admin::V1::DatastoreAdmin::ListIndexesRequest'];

coerce 'ListIndexesRequest',
    from HashRef, via { 'Google::Datastore::Admin::V1::DatastoreAdmin::ListIndexesRequest'->new($_) };

declare 'RepeatedListIndexesRequest',
    as ArrayRef[ListIndexesRequest()];

coerce 'RepeatedListIndexesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Datastore::Admin::V1::DatastoreAdmin::ListIndexesRequest'->new($_) } @$_ ] };

declare 'MapStringListIndexesRequest',
    as HashRef[ListIndexesRequest()];

declare 'ListIndexesResponse',
    as InstanceOf['Google::Datastore::Admin::V1::DatastoreAdmin::ListIndexesResponse'];

coerce 'ListIndexesResponse',
    from HashRef, via { 'Google::Datastore::Admin::V1::DatastoreAdmin::ListIndexesResponse'->new($_) };

declare 'RepeatedListIndexesResponse',
    as ArrayRef[ListIndexesResponse()];

coerce 'RepeatedListIndexesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Datastore::Admin::V1::DatastoreAdmin::ListIndexesResponse'->new($_) } @$_ ] };

declare 'MapStringListIndexesResponse',
    as HashRef[ListIndexesResponse()];

declare 'IndexOperationMetadata',
    as InstanceOf['Google::Datastore::Admin::V1::DatastoreAdmin::IndexOperationMetadata'];

coerce 'IndexOperationMetadata',
    from HashRef, via { 'Google::Datastore::Admin::V1::DatastoreAdmin::IndexOperationMetadata'->new($_) };

declare 'RepeatedIndexOperationMetadata',
    as ArrayRef[IndexOperationMetadata()];

coerce 'RepeatedIndexOperationMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Datastore::Admin::V1::DatastoreAdmin::IndexOperationMetadata'->new($_) } @$_ ] };

declare 'MapStringIndexOperationMetadata',
    as HashRef[IndexOperationMetadata()];

declare 'DatastoreFirestoreMigrationMetadata',
    as InstanceOf['Google::Datastore::Admin::V1::DatastoreAdmin::DatastoreFirestoreMigrationMetadata'];

coerce 'DatastoreFirestoreMigrationMetadata',
    from HashRef, via { 'Google::Datastore::Admin::V1::DatastoreAdmin::DatastoreFirestoreMigrationMetadata'->new($_) };

declare 'RepeatedDatastoreFirestoreMigrationMetadata',
    as ArrayRef[DatastoreFirestoreMigrationMetadata()];

coerce 'RepeatedDatastoreFirestoreMigrationMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Datastore::Admin::V1::DatastoreAdmin::DatastoreFirestoreMigrationMetadata'->new($_) } @$_ ] };

declare 'MapStringDatastoreFirestoreMigrationMetadata',
    as HashRef[DatastoreFirestoreMigrationMetadata()];

1;

__END__

=head1 NAME

Google::Datastore::Admin::V1::DatastoreAdmin::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
