package Google::Cloud::Bigquery::Storage::V1::Table::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'TableSchema',
    as InstanceOf['Google::Cloud::Bigquery::Storage::V1::Table::TableSchema'];

coerce 'TableSchema',
    from HashRef, via { 'Google::Cloud::Bigquery::Storage::V1::Table::TableSchema'->new($_) };

declare 'RepeatedTableSchema',
    as ArrayRef[TableSchema()];

coerce 'RepeatedTableSchema',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Storage::V1::Table::TableSchema'->new($_) } @$_ ] };

declare 'MapStringTableSchema',
    as HashRef[TableSchema()];

declare 'TableFieldSchema',
    as InstanceOf['Google::Cloud::Bigquery::Storage::V1::Table::TableFieldSchema'];

coerce 'TableFieldSchema',
    from HashRef, via { 'Google::Cloud::Bigquery::Storage::V1::Table::TableFieldSchema'->new($_) };

declare 'RepeatedTableFieldSchema',
    as ArrayRef[TableFieldSchema()];

coerce 'RepeatedTableFieldSchema',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Storage::V1::Table::TableFieldSchema'->new($_) } @$_ ] };

declare 'MapStringTableFieldSchema',
    as HashRef[TableFieldSchema()];

declare 'Type',
    as (Int | Str);

declare 'Mode',
    as (Int | Str);

declare 'FieldElementType',
    as InstanceOf['Google::Cloud::Bigquery::Storage::V1::Table::TableFieldSchema::FieldElementType'];

coerce 'FieldElementType',
    from HashRef, via { 'Google::Cloud::Bigquery::Storage::V1::Table::TableFieldSchema::FieldElementType'->new($_) };

declare 'RepeatedFieldElementType',
    as ArrayRef[FieldElementType()];

coerce 'RepeatedFieldElementType',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Storage::V1::Table::TableFieldSchema::FieldElementType'->new($_) } @$_ ] };

declare 'MapStringFieldElementType',
    as HashRef[FieldElementType()];

1;

__END__

=head1 NAME

Google::Cloud::Bigquery::Storage::V1::Table::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
