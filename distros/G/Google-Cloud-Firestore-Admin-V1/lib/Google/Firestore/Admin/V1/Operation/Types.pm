package Google::Firestore::Admin::V1::Operation::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'OperationState',
    as (Int | Str);

declare 'IndexOperationMetadata',
    as InstanceOf['Google::Firestore::Admin::V1::Operation::IndexOperationMetadata'];

coerce 'IndexOperationMetadata',
    from HashRef, via { 'Google::Firestore::Admin::V1::Operation::IndexOperationMetadata'->new($_) };

declare 'RepeatedIndexOperationMetadata',
    as ArrayRef[IndexOperationMetadata()];

coerce 'RepeatedIndexOperationMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Firestore::Admin::V1::Operation::IndexOperationMetadata'->new($_) } @$_ ] };

declare 'MapStringIndexOperationMetadata',
    as HashRef[IndexOperationMetadata()];

declare 'FieldOperationMetadata',
    as InstanceOf['Google::Firestore::Admin::V1::Operation::FieldOperationMetadata'];

coerce 'FieldOperationMetadata',
    from HashRef, via { 'Google::Firestore::Admin::V1::Operation::FieldOperationMetadata'->new($_) };

declare 'RepeatedFieldOperationMetadata',
    as ArrayRef[FieldOperationMetadata()];

coerce 'RepeatedFieldOperationMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Firestore::Admin::V1::Operation::FieldOperationMetadata'->new($_) } @$_ ] };

declare 'MapStringFieldOperationMetadata',
    as HashRef[FieldOperationMetadata()];

declare 'IndexConfigDelta',
    as InstanceOf['Google::Firestore::Admin::V1::Operation::FieldOperationMetadata::IndexConfigDelta'];

coerce 'IndexConfigDelta',
    from HashRef, via { 'Google::Firestore::Admin::V1::Operation::FieldOperationMetadata::IndexConfigDelta'->new($_) };

declare 'RepeatedIndexConfigDelta',
    as ArrayRef[IndexConfigDelta()];

coerce 'RepeatedIndexConfigDelta',
    from ArrayRef[HashRef], via { [ map { 'Google::Firestore::Admin::V1::Operation::FieldOperationMetadata::IndexConfigDelta'->new($_) } @$_ ] };

declare 'MapStringIndexConfigDelta',
    as HashRef[IndexConfigDelta()];

declare 'ChangeType',
    as (Int | Str);

declare 'TtlConfigDelta',
    as InstanceOf['Google::Firestore::Admin::V1::Operation::FieldOperationMetadata::TtlConfigDelta'];

coerce 'TtlConfigDelta',
    from HashRef, via { 'Google::Firestore::Admin::V1::Operation::FieldOperationMetadata::TtlConfigDelta'->new($_) };

declare 'RepeatedTtlConfigDelta',
    as ArrayRef[TtlConfigDelta()];

coerce 'RepeatedTtlConfigDelta',
    from ArrayRef[HashRef], via { [ map { 'Google::Firestore::Admin::V1::Operation::FieldOperationMetadata::TtlConfigDelta'->new($_) } @$_ ] };

declare 'MapStringTtlConfigDelta',
    as HashRef[TtlConfigDelta()];

declare 'ChangeType',
    as (Int | Str);

declare 'ExportDocumentsMetadata',
    as InstanceOf['Google::Firestore::Admin::V1::Operation::ExportDocumentsMetadata'];

coerce 'ExportDocumentsMetadata',
    from HashRef, via { 'Google::Firestore::Admin::V1::Operation::ExportDocumentsMetadata'->new($_) };

declare 'RepeatedExportDocumentsMetadata',
    as ArrayRef[ExportDocumentsMetadata()];

coerce 'RepeatedExportDocumentsMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Firestore::Admin::V1::Operation::ExportDocumentsMetadata'->new($_) } @$_ ] };

declare 'MapStringExportDocumentsMetadata',
    as HashRef[ExportDocumentsMetadata()];

declare 'ImportDocumentsMetadata',
    as InstanceOf['Google::Firestore::Admin::V1::Operation::ImportDocumentsMetadata'];

coerce 'ImportDocumentsMetadata',
    from HashRef, via { 'Google::Firestore::Admin::V1::Operation::ImportDocumentsMetadata'->new($_) };

declare 'RepeatedImportDocumentsMetadata',
    as ArrayRef[ImportDocumentsMetadata()];

coerce 'RepeatedImportDocumentsMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Firestore::Admin::V1::Operation::ImportDocumentsMetadata'->new($_) } @$_ ] };

declare 'MapStringImportDocumentsMetadata',
    as HashRef[ImportDocumentsMetadata()];

declare 'BulkDeleteDocumentsMetadata',
    as InstanceOf['Google::Firestore::Admin::V1::Operation::BulkDeleteDocumentsMetadata'];

coerce 'BulkDeleteDocumentsMetadata',
    from HashRef, via { 'Google::Firestore::Admin::V1::Operation::BulkDeleteDocumentsMetadata'->new($_) };

declare 'RepeatedBulkDeleteDocumentsMetadata',
    as ArrayRef[BulkDeleteDocumentsMetadata()];

coerce 'RepeatedBulkDeleteDocumentsMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Firestore::Admin::V1::Operation::BulkDeleteDocumentsMetadata'->new($_) } @$_ ] };

declare 'MapStringBulkDeleteDocumentsMetadata',
    as HashRef[BulkDeleteDocumentsMetadata()];

declare 'ExportDocumentsResponse',
    as InstanceOf['Google::Firestore::Admin::V1::Operation::ExportDocumentsResponse'];

coerce 'ExportDocumentsResponse',
    from HashRef, via { 'Google::Firestore::Admin::V1::Operation::ExportDocumentsResponse'->new($_) };

declare 'RepeatedExportDocumentsResponse',
    as ArrayRef[ExportDocumentsResponse()];

coerce 'RepeatedExportDocumentsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Firestore::Admin::V1::Operation::ExportDocumentsResponse'->new($_) } @$_ ] };

declare 'MapStringExportDocumentsResponse',
    as HashRef[ExportDocumentsResponse()];

declare 'RestoreDatabaseMetadata',
    as InstanceOf['Google::Firestore::Admin::V1::Operation::RestoreDatabaseMetadata'];

coerce 'RestoreDatabaseMetadata',
    from HashRef, via { 'Google::Firestore::Admin::V1::Operation::RestoreDatabaseMetadata'->new($_) };

declare 'RepeatedRestoreDatabaseMetadata',
    as ArrayRef[RestoreDatabaseMetadata()];

coerce 'RepeatedRestoreDatabaseMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Firestore::Admin::V1::Operation::RestoreDatabaseMetadata'->new($_) } @$_ ] };

declare 'MapStringRestoreDatabaseMetadata',
    as HashRef[RestoreDatabaseMetadata()];

declare 'CloneDatabaseMetadata',
    as InstanceOf['Google::Firestore::Admin::V1::Operation::CloneDatabaseMetadata'];

coerce 'CloneDatabaseMetadata',
    from HashRef, via { 'Google::Firestore::Admin::V1::Operation::CloneDatabaseMetadata'->new($_) };

declare 'RepeatedCloneDatabaseMetadata',
    as ArrayRef[CloneDatabaseMetadata()];

coerce 'RepeatedCloneDatabaseMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Firestore::Admin::V1::Operation::CloneDatabaseMetadata'->new($_) } @$_ ] };

declare 'MapStringCloneDatabaseMetadata',
    as HashRef[CloneDatabaseMetadata()];

declare 'Progress',
    as InstanceOf['Google::Firestore::Admin::V1::Operation::Progress'];

coerce 'Progress',
    from HashRef, via { 'Google::Firestore::Admin::V1::Operation::Progress'->new($_) };

declare 'RepeatedProgress',
    as ArrayRef[Progress()];

coerce 'RepeatedProgress',
    from ArrayRef[HashRef], via { [ map { 'Google::Firestore::Admin::V1::Operation::Progress'->new($_) } @$_ ] };

declare 'MapStringProgress',
    as HashRef[Progress()];

1;

__END__

=head1 NAME

Google::Firestore::Admin::V1::Operation::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
