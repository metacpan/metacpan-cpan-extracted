package Google::Datastore::Admin::V1beta1::DatastoreAdmin::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'OperationType',
    as (Int | Str);

declare 'CommonMetadata',
    as InstanceOf['Google::Datastore::Admin::V1beta1::DatastoreAdmin::CommonMetadata'];

coerce 'CommonMetadata',
    from HashRef, via { 'Google::Datastore::Admin::V1beta1::DatastoreAdmin::CommonMetadata'->new($_) };

declare 'RepeatedCommonMetadata',
    as ArrayRef[CommonMetadata()];

coerce 'RepeatedCommonMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Datastore::Admin::V1beta1::DatastoreAdmin::CommonMetadata'->new($_) } @$_ ] };

declare 'MapStringCommonMetadata',
    as HashRef[CommonMetadata()];

declare 'State',
    as (Int | Str);

declare 'LabelsEntry',
    as InstanceOf['Google::Datastore::Admin::V1beta1::DatastoreAdmin::CommonMetadata::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Datastore::Admin::V1beta1::DatastoreAdmin::CommonMetadata::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Datastore::Admin::V1beta1::DatastoreAdmin::CommonMetadata::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'Progress',
    as InstanceOf['Google::Datastore::Admin::V1beta1::DatastoreAdmin::Progress'];

coerce 'Progress',
    from HashRef, via { 'Google::Datastore::Admin::V1beta1::DatastoreAdmin::Progress'->new($_) };

declare 'RepeatedProgress',
    as ArrayRef[Progress()];

coerce 'RepeatedProgress',
    from ArrayRef[HashRef], via { [ map { 'Google::Datastore::Admin::V1beta1::DatastoreAdmin::Progress'->new($_) } @$_ ] };

declare 'MapStringProgress',
    as HashRef[Progress()];

declare 'ExportEntitiesRequest',
    as InstanceOf['Google::Datastore::Admin::V1beta1::DatastoreAdmin::ExportEntitiesRequest'];

coerce 'ExportEntitiesRequest',
    from HashRef, via { 'Google::Datastore::Admin::V1beta1::DatastoreAdmin::ExportEntitiesRequest'->new($_) };

declare 'RepeatedExportEntitiesRequest',
    as ArrayRef[ExportEntitiesRequest()];

coerce 'RepeatedExportEntitiesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Datastore::Admin::V1beta1::DatastoreAdmin::ExportEntitiesRequest'->new($_) } @$_ ] };

declare 'MapStringExportEntitiesRequest',
    as HashRef[ExportEntitiesRequest()];

declare 'LabelsEntry',
    as InstanceOf['Google::Datastore::Admin::V1beta1::DatastoreAdmin::ExportEntitiesRequest::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Datastore::Admin::V1beta1::DatastoreAdmin::ExportEntitiesRequest::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Datastore::Admin::V1beta1::DatastoreAdmin::ExportEntitiesRequest::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'ImportEntitiesRequest',
    as InstanceOf['Google::Datastore::Admin::V1beta1::DatastoreAdmin::ImportEntitiesRequest'];

coerce 'ImportEntitiesRequest',
    from HashRef, via { 'Google::Datastore::Admin::V1beta1::DatastoreAdmin::ImportEntitiesRequest'->new($_) };

declare 'RepeatedImportEntitiesRequest',
    as ArrayRef[ImportEntitiesRequest()];

coerce 'RepeatedImportEntitiesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Datastore::Admin::V1beta1::DatastoreAdmin::ImportEntitiesRequest'->new($_) } @$_ ] };

declare 'MapStringImportEntitiesRequest',
    as HashRef[ImportEntitiesRequest()];

declare 'LabelsEntry',
    as InstanceOf['Google::Datastore::Admin::V1beta1::DatastoreAdmin::ImportEntitiesRequest::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Datastore::Admin::V1beta1::DatastoreAdmin::ImportEntitiesRequest::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Datastore::Admin::V1beta1::DatastoreAdmin::ImportEntitiesRequest::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'ExportEntitiesResponse',
    as InstanceOf['Google::Datastore::Admin::V1beta1::DatastoreAdmin::ExportEntitiesResponse'];

coerce 'ExportEntitiesResponse',
    from HashRef, via { 'Google::Datastore::Admin::V1beta1::DatastoreAdmin::ExportEntitiesResponse'->new($_) };

declare 'RepeatedExportEntitiesResponse',
    as ArrayRef[ExportEntitiesResponse()];

coerce 'RepeatedExportEntitiesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Datastore::Admin::V1beta1::DatastoreAdmin::ExportEntitiesResponse'->new($_) } @$_ ] };

declare 'MapStringExportEntitiesResponse',
    as HashRef[ExportEntitiesResponse()];

declare 'ExportEntitiesMetadata',
    as InstanceOf['Google::Datastore::Admin::V1beta1::DatastoreAdmin::ExportEntitiesMetadata'];

coerce 'ExportEntitiesMetadata',
    from HashRef, via { 'Google::Datastore::Admin::V1beta1::DatastoreAdmin::ExportEntitiesMetadata'->new($_) };

declare 'RepeatedExportEntitiesMetadata',
    as ArrayRef[ExportEntitiesMetadata()];

coerce 'RepeatedExportEntitiesMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Datastore::Admin::V1beta1::DatastoreAdmin::ExportEntitiesMetadata'->new($_) } @$_ ] };

declare 'MapStringExportEntitiesMetadata',
    as HashRef[ExportEntitiesMetadata()];

declare 'ImportEntitiesMetadata',
    as InstanceOf['Google::Datastore::Admin::V1beta1::DatastoreAdmin::ImportEntitiesMetadata'];

coerce 'ImportEntitiesMetadata',
    from HashRef, via { 'Google::Datastore::Admin::V1beta1::DatastoreAdmin::ImportEntitiesMetadata'->new($_) };

declare 'RepeatedImportEntitiesMetadata',
    as ArrayRef[ImportEntitiesMetadata()];

coerce 'RepeatedImportEntitiesMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Datastore::Admin::V1beta1::DatastoreAdmin::ImportEntitiesMetadata'->new($_) } @$_ ] };

declare 'MapStringImportEntitiesMetadata',
    as HashRef[ImportEntitiesMetadata()];

declare 'EntityFilter',
    as InstanceOf['Google::Datastore::Admin::V1beta1::DatastoreAdmin::EntityFilter'];

coerce 'EntityFilter',
    from HashRef, via { 'Google::Datastore::Admin::V1beta1::DatastoreAdmin::EntityFilter'->new($_) };

declare 'RepeatedEntityFilter',
    as ArrayRef[EntityFilter()];

coerce 'RepeatedEntityFilter',
    from ArrayRef[HashRef], via { [ map { 'Google::Datastore::Admin::V1beta1::DatastoreAdmin::EntityFilter'->new($_) } @$_ ] };

declare 'MapStringEntityFilter',
    as HashRef[EntityFilter()];

1;

__END__

=head1 NAME

Google::Datastore::Admin::V1beta1::DatastoreAdmin::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
