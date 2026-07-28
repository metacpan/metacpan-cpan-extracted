package Google::Cloud::Dataplex::V1::Metadata::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'StorageSystem',
    as (Int | Str);

declare 'CreateEntityRequest',
    as InstanceOf['Google::Cloud::Dataplex::V1::Metadata::CreateEntityRequest'];

coerce 'CreateEntityRequest',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Metadata::CreateEntityRequest'->new($_) };

declare 'RepeatedCreateEntityRequest',
    as ArrayRef[CreateEntityRequest()];

coerce 'RepeatedCreateEntityRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Metadata::CreateEntityRequest'->new($_) } @$_ ] };

declare 'MapStringCreateEntityRequest',
    as HashRef[CreateEntityRequest()];

declare 'UpdateEntityRequest',
    as InstanceOf['Google::Cloud::Dataplex::V1::Metadata::UpdateEntityRequest'];

coerce 'UpdateEntityRequest',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Metadata::UpdateEntityRequest'->new($_) };

declare 'RepeatedUpdateEntityRequest',
    as ArrayRef[UpdateEntityRequest()];

coerce 'RepeatedUpdateEntityRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Metadata::UpdateEntityRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateEntityRequest',
    as HashRef[UpdateEntityRequest()];

declare 'DeleteEntityRequest',
    as InstanceOf['Google::Cloud::Dataplex::V1::Metadata::DeleteEntityRequest'];

coerce 'DeleteEntityRequest',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Metadata::DeleteEntityRequest'->new($_) };

declare 'RepeatedDeleteEntityRequest',
    as ArrayRef[DeleteEntityRequest()];

coerce 'RepeatedDeleteEntityRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Metadata::DeleteEntityRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteEntityRequest',
    as HashRef[DeleteEntityRequest()];

declare 'ListEntitiesRequest',
    as InstanceOf['Google::Cloud::Dataplex::V1::Metadata::ListEntitiesRequest'];

coerce 'ListEntitiesRequest',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Metadata::ListEntitiesRequest'->new($_) };

declare 'RepeatedListEntitiesRequest',
    as ArrayRef[ListEntitiesRequest()];

coerce 'RepeatedListEntitiesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Metadata::ListEntitiesRequest'->new($_) } @$_ ] };

declare 'MapStringListEntitiesRequest',
    as HashRef[ListEntitiesRequest()];

declare 'EntityView',
    as (Int | Str);

declare 'ListEntitiesResponse',
    as InstanceOf['Google::Cloud::Dataplex::V1::Metadata::ListEntitiesResponse'];

coerce 'ListEntitiesResponse',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Metadata::ListEntitiesResponse'->new($_) };

declare 'RepeatedListEntitiesResponse',
    as ArrayRef[ListEntitiesResponse()];

coerce 'RepeatedListEntitiesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Metadata::ListEntitiesResponse'->new($_) } @$_ ] };

declare 'MapStringListEntitiesResponse',
    as HashRef[ListEntitiesResponse()];

declare 'GetEntityRequest',
    as InstanceOf['Google::Cloud::Dataplex::V1::Metadata::GetEntityRequest'];

coerce 'GetEntityRequest',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Metadata::GetEntityRequest'->new($_) };

declare 'RepeatedGetEntityRequest',
    as ArrayRef[GetEntityRequest()];

coerce 'RepeatedGetEntityRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Metadata::GetEntityRequest'->new($_) } @$_ ] };

declare 'MapStringGetEntityRequest',
    as HashRef[GetEntityRequest()];

declare 'EntityView',
    as (Int | Str);

declare 'ListPartitionsRequest',
    as InstanceOf['Google::Cloud::Dataplex::V1::Metadata::ListPartitionsRequest'];

coerce 'ListPartitionsRequest',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Metadata::ListPartitionsRequest'->new($_) };

declare 'RepeatedListPartitionsRequest',
    as ArrayRef[ListPartitionsRequest()];

coerce 'RepeatedListPartitionsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Metadata::ListPartitionsRequest'->new($_) } @$_ ] };

declare 'MapStringListPartitionsRequest',
    as HashRef[ListPartitionsRequest()];

declare 'CreatePartitionRequest',
    as InstanceOf['Google::Cloud::Dataplex::V1::Metadata::CreatePartitionRequest'];

coerce 'CreatePartitionRequest',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Metadata::CreatePartitionRequest'->new($_) };

declare 'RepeatedCreatePartitionRequest',
    as ArrayRef[CreatePartitionRequest()];

coerce 'RepeatedCreatePartitionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Metadata::CreatePartitionRequest'->new($_) } @$_ ] };

declare 'MapStringCreatePartitionRequest',
    as HashRef[CreatePartitionRequest()];

declare 'DeletePartitionRequest',
    as InstanceOf['Google::Cloud::Dataplex::V1::Metadata::DeletePartitionRequest'];

coerce 'DeletePartitionRequest',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Metadata::DeletePartitionRequest'->new($_) };

declare 'RepeatedDeletePartitionRequest',
    as ArrayRef[DeletePartitionRequest()];

coerce 'RepeatedDeletePartitionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Metadata::DeletePartitionRequest'->new($_) } @$_ ] };

declare 'MapStringDeletePartitionRequest',
    as HashRef[DeletePartitionRequest()];

declare 'ListPartitionsResponse',
    as InstanceOf['Google::Cloud::Dataplex::V1::Metadata::ListPartitionsResponse'];

coerce 'ListPartitionsResponse',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Metadata::ListPartitionsResponse'->new($_) };

declare 'RepeatedListPartitionsResponse',
    as ArrayRef[ListPartitionsResponse()];

coerce 'RepeatedListPartitionsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Metadata::ListPartitionsResponse'->new($_) } @$_ ] };

declare 'MapStringListPartitionsResponse',
    as HashRef[ListPartitionsResponse()];

declare 'GetPartitionRequest',
    as InstanceOf['Google::Cloud::Dataplex::V1::Metadata::GetPartitionRequest'];

coerce 'GetPartitionRequest',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Metadata::GetPartitionRequest'->new($_) };

declare 'RepeatedGetPartitionRequest',
    as ArrayRef[GetPartitionRequest()];

coerce 'RepeatedGetPartitionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Metadata::GetPartitionRequest'->new($_) } @$_ ] };

declare 'MapStringGetPartitionRequest',
    as HashRef[GetPartitionRequest()];

declare 'Entity',
    as InstanceOf['Google::Cloud::Dataplex::V1::Metadata::Entity'];

coerce 'Entity',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Metadata::Entity'->new($_) };

declare 'RepeatedEntity',
    as ArrayRef[Entity()];

coerce 'RepeatedEntity',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Metadata::Entity'->new($_) } @$_ ] };

declare 'MapStringEntity',
    as HashRef[Entity()];

declare 'Type',
    as (Int | Str);

declare 'CompatibilityStatus',
    as InstanceOf['Google::Cloud::Dataplex::V1::Metadata::Entity::CompatibilityStatus'];

coerce 'CompatibilityStatus',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Metadata::Entity::CompatibilityStatus'->new($_) };

declare 'RepeatedCompatibilityStatus',
    as ArrayRef[CompatibilityStatus()];

coerce 'RepeatedCompatibilityStatus',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Metadata::Entity::CompatibilityStatus'->new($_) } @$_ ] };

declare 'MapStringCompatibilityStatus',
    as HashRef[CompatibilityStatus()];

declare 'Compatibility',
    as InstanceOf['Google::Cloud::Dataplex::V1::Metadata::Entity::CompatibilityStatus::Compatibility'];

coerce 'Compatibility',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Metadata::Entity::CompatibilityStatus::Compatibility'->new($_) };

declare 'RepeatedCompatibility',
    as ArrayRef[Compatibility()];

coerce 'RepeatedCompatibility',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Metadata::Entity::CompatibilityStatus::Compatibility'->new($_) } @$_ ] };

declare 'MapStringCompatibility',
    as HashRef[Compatibility()];

declare 'Partition',
    as InstanceOf['Google::Cloud::Dataplex::V1::Metadata::Partition'];

coerce 'Partition',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Metadata::Partition'->new($_) };

declare 'RepeatedPartition',
    as ArrayRef[Partition()];

coerce 'RepeatedPartition',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Metadata::Partition'->new($_) } @$_ ] };

declare 'MapStringPartition',
    as HashRef[Partition()];

declare 'Schema',
    as InstanceOf['Google::Cloud::Dataplex::V1::Metadata::Schema'];

coerce 'Schema',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Metadata::Schema'->new($_) };

declare 'RepeatedSchema',
    as ArrayRef[Schema()];

coerce 'RepeatedSchema',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Metadata::Schema'->new($_) } @$_ ] };

declare 'MapStringSchema',
    as HashRef[Schema()];

declare 'Type',
    as (Int | Str);

declare 'Mode',
    as (Int | Str);

declare 'PartitionStyle',
    as (Int | Str);

declare 'SchemaField',
    as InstanceOf['Google::Cloud::Dataplex::V1::Metadata::Schema::SchemaField'];

coerce 'SchemaField',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Metadata::Schema::SchemaField'->new($_) };

declare 'RepeatedSchemaField',
    as ArrayRef[SchemaField()];

coerce 'RepeatedSchemaField',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Metadata::Schema::SchemaField'->new($_) } @$_ ] };

declare 'MapStringSchemaField',
    as HashRef[SchemaField()];

declare 'PartitionField',
    as InstanceOf['Google::Cloud::Dataplex::V1::Metadata::Schema::PartitionField'];

coerce 'PartitionField',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Metadata::Schema::PartitionField'->new($_) };

declare 'RepeatedPartitionField',
    as ArrayRef[PartitionField()];

coerce 'RepeatedPartitionField',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Metadata::Schema::PartitionField'->new($_) } @$_ ] };

declare 'MapStringPartitionField',
    as HashRef[PartitionField()];

declare 'StorageFormat',
    as InstanceOf['Google::Cloud::Dataplex::V1::Metadata::StorageFormat'];

coerce 'StorageFormat',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Metadata::StorageFormat'->new($_) };

declare 'RepeatedStorageFormat',
    as ArrayRef[StorageFormat()];

coerce 'RepeatedStorageFormat',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Metadata::StorageFormat'->new($_) } @$_ ] };

declare 'MapStringStorageFormat',
    as HashRef[StorageFormat()];

declare 'Format',
    as (Int | Str);

declare 'CompressionFormat',
    as (Int | Str);

declare 'CsvOptions',
    as InstanceOf['Google::Cloud::Dataplex::V1::Metadata::StorageFormat::CsvOptions'];

coerce 'CsvOptions',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Metadata::StorageFormat::CsvOptions'->new($_) };

declare 'RepeatedCsvOptions',
    as ArrayRef[CsvOptions()];

coerce 'RepeatedCsvOptions',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Metadata::StorageFormat::CsvOptions'->new($_) } @$_ ] };

declare 'MapStringCsvOptions',
    as HashRef[CsvOptions()];

declare 'JsonOptions',
    as InstanceOf['Google::Cloud::Dataplex::V1::Metadata::StorageFormat::JsonOptions'];

coerce 'JsonOptions',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Metadata::StorageFormat::JsonOptions'->new($_) };

declare 'RepeatedJsonOptions',
    as ArrayRef[JsonOptions()];

coerce 'RepeatedJsonOptions',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Metadata::StorageFormat::JsonOptions'->new($_) } @$_ ] };

declare 'MapStringJsonOptions',
    as HashRef[JsonOptions()];

declare 'IcebergOptions',
    as InstanceOf['Google::Cloud::Dataplex::V1::Metadata::StorageFormat::IcebergOptions'];

coerce 'IcebergOptions',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Metadata::StorageFormat::IcebergOptions'->new($_) };

declare 'RepeatedIcebergOptions',
    as ArrayRef[IcebergOptions()];

coerce 'RepeatedIcebergOptions',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Metadata::StorageFormat::IcebergOptions'->new($_) } @$_ ] };

declare 'MapStringIcebergOptions',
    as HashRef[IcebergOptions()];

declare 'StorageAccess',
    as InstanceOf['Google::Cloud::Dataplex::V1::Metadata::StorageAccess'];

coerce 'StorageAccess',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Metadata::StorageAccess'->new($_) };

declare 'RepeatedStorageAccess',
    as ArrayRef[StorageAccess()];

coerce 'RepeatedStorageAccess',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Metadata::StorageAccess'->new($_) } @$_ ] };

declare 'MapStringStorageAccess',
    as HashRef[StorageAccess()];

declare 'AccessMode',
    as (Int | Str);

1;

__END__

=head1 NAME

Google::Cloud::Dataplex::V1::Metadata::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
