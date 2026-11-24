package Google::Cloud::Documentai::V1beta3::Dataset::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Dataset',
    as InstanceOf['Google::Cloud::Documentai::V1beta3::Dataset::Dataset'];

coerce 'Dataset',
    from HashRef, via { 'Google::Cloud::Documentai::V1beta3::Dataset::Dataset'->new($_) };

declare 'RepeatedDataset',
    as ArrayRef[Dataset()];

coerce 'RepeatedDataset',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Documentai::V1beta3::Dataset::Dataset'->new($_) } @$_ ] };

declare 'MapStringDataset',
    as HashRef[Dataset()];

declare 'State',
    as (Int | Str);

declare 'GCSManagedConfig',
    as InstanceOf['Google::Cloud::Documentai::V1beta3::Dataset::Dataset::GCSManagedConfig'];

coerce 'GCSManagedConfig',
    from HashRef, via { 'Google::Cloud::Documentai::V1beta3::Dataset::Dataset::GCSManagedConfig'->new($_) };

declare 'RepeatedGCSManagedConfig',
    as ArrayRef[GCSManagedConfig()];

coerce 'RepeatedGCSManagedConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Documentai::V1beta3::Dataset::Dataset::GCSManagedConfig'->new($_) } @$_ ] };

declare 'MapStringGCSManagedConfig',
    as HashRef[GCSManagedConfig()];

declare 'DocumentWarehouseConfig',
    as InstanceOf['Google::Cloud::Documentai::V1beta3::Dataset::Dataset::DocumentWarehouseConfig'];

coerce 'DocumentWarehouseConfig',
    from HashRef, via { 'Google::Cloud::Documentai::V1beta3::Dataset::Dataset::DocumentWarehouseConfig'->new($_) };

declare 'RepeatedDocumentWarehouseConfig',
    as ArrayRef[DocumentWarehouseConfig()];

coerce 'RepeatedDocumentWarehouseConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Documentai::V1beta3::Dataset::Dataset::DocumentWarehouseConfig'->new($_) } @$_ ] };

declare 'MapStringDocumentWarehouseConfig',
    as HashRef[DocumentWarehouseConfig()];

declare 'UnmanagedDatasetConfig',
    as InstanceOf['Google::Cloud::Documentai::V1beta3::Dataset::Dataset::UnmanagedDatasetConfig'];

coerce 'UnmanagedDatasetConfig',
    from HashRef, via { 'Google::Cloud::Documentai::V1beta3::Dataset::Dataset::UnmanagedDatasetConfig'->new($_) };

declare 'RepeatedUnmanagedDatasetConfig',
    as ArrayRef[UnmanagedDatasetConfig()];

coerce 'RepeatedUnmanagedDatasetConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Documentai::V1beta3::Dataset::Dataset::UnmanagedDatasetConfig'->new($_) } @$_ ] };

declare 'MapStringUnmanagedDatasetConfig',
    as HashRef[UnmanagedDatasetConfig()];

declare 'DocumentId',
    as InstanceOf['Google::Cloud::Documentai::V1beta3::Dataset::DocumentId'];

coerce 'DocumentId',
    from HashRef, via { 'Google::Cloud::Documentai::V1beta3::Dataset::DocumentId'->new($_) };

declare 'RepeatedDocumentId',
    as ArrayRef[DocumentId()];

coerce 'RepeatedDocumentId',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Documentai::V1beta3::Dataset::DocumentId'->new($_) } @$_ ] };

declare 'MapStringDocumentId',
    as HashRef[DocumentId()];

declare 'GCSManagedDocumentId',
    as InstanceOf['Google::Cloud::Documentai::V1beta3::Dataset::DocumentId::GCSManagedDocumentId'];

coerce 'GCSManagedDocumentId',
    from HashRef, via { 'Google::Cloud::Documentai::V1beta3::Dataset::DocumentId::GCSManagedDocumentId'->new($_) };

declare 'RepeatedGCSManagedDocumentId',
    as ArrayRef[GCSManagedDocumentId()];

coerce 'RepeatedGCSManagedDocumentId',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Documentai::V1beta3::Dataset::DocumentId::GCSManagedDocumentId'->new($_) } @$_ ] };

declare 'MapStringGCSManagedDocumentId',
    as HashRef[GCSManagedDocumentId()];

declare 'UnmanagedDocumentId',
    as InstanceOf['Google::Cloud::Documentai::V1beta3::Dataset::DocumentId::UnmanagedDocumentId'];

coerce 'UnmanagedDocumentId',
    from HashRef, via { 'Google::Cloud::Documentai::V1beta3::Dataset::DocumentId::UnmanagedDocumentId'->new($_) };

declare 'RepeatedUnmanagedDocumentId',
    as ArrayRef[UnmanagedDocumentId()];

coerce 'RepeatedUnmanagedDocumentId',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Documentai::V1beta3::Dataset::DocumentId::UnmanagedDocumentId'->new($_) } @$_ ] };

declare 'MapStringUnmanagedDocumentId',
    as HashRef[UnmanagedDocumentId()];

declare 'DatasetSchema',
    as InstanceOf['Google::Cloud::Documentai::V1beta3::Dataset::DatasetSchema'];

coerce 'DatasetSchema',
    from HashRef, via { 'Google::Cloud::Documentai::V1beta3::Dataset::DatasetSchema'->new($_) };

declare 'RepeatedDatasetSchema',
    as ArrayRef[DatasetSchema()];

coerce 'RepeatedDatasetSchema',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Documentai::V1beta3::Dataset::DatasetSchema'->new($_) } @$_ ] };

declare 'MapStringDatasetSchema',
    as HashRef[DatasetSchema()];

declare 'BatchDatasetDocuments',
    as InstanceOf['Google::Cloud::Documentai::V1beta3::Dataset::BatchDatasetDocuments'];

coerce 'BatchDatasetDocuments',
    from HashRef, via { 'Google::Cloud::Documentai::V1beta3::Dataset::BatchDatasetDocuments'->new($_) };

declare 'RepeatedBatchDatasetDocuments',
    as ArrayRef[BatchDatasetDocuments()];

coerce 'RepeatedBatchDatasetDocuments',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Documentai::V1beta3::Dataset::BatchDatasetDocuments'->new($_) } @$_ ] };

declare 'MapStringBatchDatasetDocuments',
    as HashRef[BatchDatasetDocuments()];

declare 'IndividualDocumentIds',
    as InstanceOf['Google::Cloud::Documentai::V1beta3::Dataset::BatchDatasetDocuments::IndividualDocumentIds'];

coerce 'IndividualDocumentIds',
    from HashRef, via { 'Google::Cloud::Documentai::V1beta3::Dataset::BatchDatasetDocuments::IndividualDocumentIds'->new($_) };

declare 'RepeatedIndividualDocumentIds',
    as ArrayRef[IndividualDocumentIds()];

coerce 'RepeatedIndividualDocumentIds',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Documentai::V1beta3::Dataset::BatchDatasetDocuments::IndividualDocumentIds'->new($_) } @$_ ] };

declare 'MapStringIndividualDocumentIds',
    as HashRef[IndividualDocumentIds()];

1;

__END__

=head1 NAME

Google::Cloud::Documentai::V1beta3::Dataset::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
