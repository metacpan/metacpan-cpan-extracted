package Google::Cloud::Bigquery::Storage::V1beta::Partition::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'FieldSchema',
    as InstanceOf['Google::Cloud::Bigquery::Storage::V1beta::Partition::FieldSchema'];

coerce 'FieldSchema',
    from HashRef, via { 'Google::Cloud::Bigquery::Storage::V1beta::Partition::FieldSchema'->new($_) };

declare 'RepeatedFieldSchema',
    as ArrayRef[FieldSchema()];

coerce 'RepeatedFieldSchema',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Storage::V1beta::Partition::FieldSchema'->new($_) } @$_ ] };

declare 'MapStringFieldSchema',
    as HashRef[FieldSchema()];

declare 'StorageDescriptor',
    as InstanceOf['Google::Cloud::Bigquery::Storage::V1beta::Partition::StorageDescriptor'];

coerce 'StorageDescriptor',
    from HashRef, via { 'Google::Cloud::Bigquery::Storage::V1beta::Partition::StorageDescriptor'->new($_) };

declare 'RepeatedStorageDescriptor',
    as ArrayRef[StorageDescriptor()];

coerce 'RepeatedStorageDescriptor',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Storage::V1beta::Partition::StorageDescriptor'->new($_) } @$_ ] };

declare 'MapStringStorageDescriptor',
    as HashRef[StorageDescriptor()];

declare 'SerDeInfo',
    as InstanceOf['Google::Cloud::Bigquery::Storage::V1beta::Partition::SerDeInfo'];

coerce 'SerDeInfo',
    from HashRef, via { 'Google::Cloud::Bigquery::Storage::V1beta::Partition::SerDeInfo'->new($_) };

declare 'RepeatedSerDeInfo',
    as ArrayRef[SerDeInfo()];

coerce 'RepeatedSerDeInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Storage::V1beta::Partition::SerDeInfo'->new($_) } @$_ ] };

declare 'MapStringSerDeInfo',
    as HashRef[SerDeInfo()];

declare 'ParametersEntry',
    as InstanceOf['Google::Cloud::Bigquery::Storage::V1beta::Partition::SerDeInfo::ParametersEntry'];

coerce 'ParametersEntry',
    from HashRef, via { 'Google::Cloud::Bigquery::Storage::V1beta::Partition::SerDeInfo::ParametersEntry'->new($_) };

declare 'RepeatedParametersEntry',
    as ArrayRef[ParametersEntry()];

coerce 'RepeatedParametersEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Storage::V1beta::Partition::SerDeInfo::ParametersEntry'->new($_) } @$_ ] };

declare 'MapStringParametersEntry',
    as HashRef[ParametersEntry()];

declare 'MetastorePartition',
    as InstanceOf['Google::Cloud::Bigquery::Storage::V1beta::Partition::MetastorePartition'];

coerce 'MetastorePartition',
    from HashRef, via { 'Google::Cloud::Bigquery::Storage::V1beta::Partition::MetastorePartition'->new($_) };

declare 'RepeatedMetastorePartition',
    as ArrayRef[MetastorePartition()];

coerce 'RepeatedMetastorePartition',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Storage::V1beta::Partition::MetastorePartition'->new($_) } @$_ ] };

declare 'MapStringMetastorePartition',
    as HashRef[MetastorePartition()];

declare 'ParametersEntry',
    as InstanceOf['Google::Cloud::Bigquery::Storage::V1beta::Partition::MetastorePartition::ParametersEntry'];

coerce 'ParametersEntry',
    from HashRef, via { 'Google::Cloud::Bigquery::Storage::V1beta::Partition::MetastorePartition::ParametersEntry'->new($_) };

declare 'RepeatedParametersEntry',
    as ArrayRef[ParametersEntry()];

coerce 'RepeatedParametersEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Storage::V1beta::Partition::MetastorePartition::ParametersEntry'->new($_) } @$_ ] };

declare 'MapStringParametersEntry',
    as HashRef[ParametersEntry()];

declare 'MetastorePartitionList',
    as InstanceOf['Google::Cloud::Bigquery::Storage::V1beta::Partition::MetastorePartitionList'];

coerce 'MetastorePartitionList',
    from HashRef, via { 'Google::Cloud::Bigquery::Storage::V1beta::Partition::MetastorePartitionList'->new($_) };

declare 'RepeatedMetastorePartitionList',
    as ArrayRef[MetastorePartitionList()];

coerce 'RepeatedMetastorePartitionList',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Storage::V1beta::Partition::MetastorePartitionList'->new($_) } @$_ ] };

declare 'MapStringMetastorePartitionList',
    as HashRef[MetastorePartitionList()];

declare 'ReadStream',
    as InstanceOf['Google::Cloud::Bigquery::Storage::V1beta::Partition::ReadStream'];

coerce 'ReadStream',
    from HashRef, via { 'Google::Cloud::Bigquery::Storage::V1beta::Partition::ReadStream'->new($_) };

declare 'RepeatedReadStream',
    as ArrayRef[ReadStream()];

coerce 'RepeatedReadStream',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Storage::V1beta::Partition::ReadStream'->new($_) } @$_ ] };

declare 'MapStringReadStream',
    as HashRef[ReadStream()];

declare 'StreamList',
    as InstanceOf['Google::Cloud::Bigquery::Storage::V1beta::Partition::StreamList'];

coerce 'StreamList',
    from HashRef, via { 'Google::Cloud::Bigquery::Storage::V1beta::Partition::StreamList'->new($_) };

declare 'RepeatedStreamList',
    as ArrayRef[StreamList()];

coerce 'RepeatedStreamList',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Storage::V1beta::Partition::StreamList'->new($_) } @$_ ] };

declare 'MapStringStreamList',
    as HashRef[StreamList()];

declare 'MetastorePartitionValues',
    as InstanceOf['Google::Cloud::Bigquery::Storage::V1beta::Partition::MetastorePartitionValues'];

coerce 'MetastorePartitionValues',
    from HashRef, via { 'Google::Cloud::Bigquery::Storage::V1beta::Partition::MetastorePartitionValues'->new($_) };

declare 'RepeatedMetastorePartitionValues',
    as ArrayRef[MetastorePartitionValues()];

coerce 'RepeatedMetastorePartitionValues',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Storage::V1beta::Partition::MetastorePartitionValues'->new($_) } @$_ ] };

declare 'MapStringMetastorePartitionValues',
    as HashRef[MetastorePartitionValues()];

1;

__END__

=head1 NAME

Google::Cloud::Bigquery::Storage::V1beta::Partition::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
