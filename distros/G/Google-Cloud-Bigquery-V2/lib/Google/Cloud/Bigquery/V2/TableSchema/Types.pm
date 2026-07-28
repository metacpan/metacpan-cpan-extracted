package Google::Cloud::Bigquery::V2::TableSchema::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'TableSchema',
    as InstanceOf['Google::Cloud::Bigquery::V2::TableSchema::TableSchema'];

coerce 'TableSchema',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::TableSchema::TableSchema'->new($_) };

declare 'RepeatedTableSchema',
    as ArrayRef[TableSchema()];

coerce 'RepeatedTableSchema',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::TableSchema::TableSchema'->new($_) } @$_ ] };

declare 'MapStringTableSchema',
    as HashRef[TableSchema()];

declare 'ForeignTypeInfo',
    as InstanceOf['Google::Cloud::Bigquery::V2::TableSchema::ForeignTypeInfo'];

coerce 'ForeignTypeInfo',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::TableSchema::ForeignTypeInfo'->new($_) };

declare 'RepeatedForeignTypeInfo',
    as ArrayRef[ForeignTypeInfo()];

coerce 'RepeatedForeignTypeInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::TableSchema::ForeignTypeInfo'->new($_) } @$_ ] };

declare 'MapStringForeignTypeInfo',
    as HashRef[ForeignTypeInfo()];

declare 'TypeSystem',
    as (Int | Str);

declare 'DataPolicyOption',
    as InstanceOf['Google::Cloud::Bigquery::V2::TableSchema::DataPolicyOption'];

coerce 'DataPolicyOption',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::TableSchema::DataPolicyOption'->new($_) };

declare 'RepeatedDataPolicyOption',
    as ArrayRef[DataPolicyOption()];

coerce 'RepeatedDataPolicyOption',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::TableSchema::DataPolicyOption'->new($_) } @$_ ] };

declare 'MapStringDataPolicyOption',
    as HashRef[DataPolicyOption()];

declare 'DataPolicyList',
    as InstanceOf['Google::Cloud::Bigquery::V2::TableSchema::DataPolicyList'];

coerce 'DataPolicyList',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::TableSchema::DataPolicyList'->new($_) };

declare 'RepeatedDataPolicyList',
    as ArrayRef[DataPolicyList()];

coerce 'RepeatedDataPolicyList',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::TableSchema::DataPolicyList'->new($_) } @$_ ] };

declare 'MapStringDataPolicyList',
    as HashRef[DataPolicyList()];

declare 'TableFieldSchema',
    as InstanceOf['Google::Cloud::Bigquery::V2::TableSchema::TableFieldSchema'];

coerce 'TableFieldSchema',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::TableSchema::TableFieldSchema'->new($_) };

declare 'RepeatedTableFieldSchema',
    as ArrayRef[TableFieldSchema()];

coerce 'RepeatedTableFieldSchema',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::TableSchema::TableFieldSchema'->new($_) } @$_ ] };

declare 'MapStringTableFieldSchema',
    as HashRef[TableFieldSchema()];

declare 'RoundingMode',
    as (Int | Str);

declare 'PolicyTagList',
    as InstanceOf['Google::Cloud::Bigquery::V2::TableSchema::TableFieldSchema::PolicyTagList'];

coerce 'PolicyTagList',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::TableSchema::TableFieldSchema::PolicyTagList'->new($_) };

declare 'RepeatedPolicyTagList',
    as ArrayRef[PolicyTagList()];

coerce 'RepeatedPolicyTagList',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::TableSchema::TableFieldSchema::PolicyTagList'->new($_) } @$_ ] };

declare 'MapStringPolicyTagList',
    as HashRef[PolicyTagList()];

declare 'DataGovernanceTagsInfo',
    as InstanceOf['Google::Cloud::Bigquery::V2::TableSchema::TableFieldSchema::DataGovernanceTagsInfo'];

coerce 'DataGovernanceTagsInfo',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::TableSchema::TableFieldSchema::DataGovernanceTagsInfo'->new($_) };

declare 'RepeatedDataGovernanceTagsInfo',
    as ArrayRef[DataGovernanceTagsInfo()];

coerce 'RepeatedDataGovernanceTagsInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::TableSchema::TableFieldSchema::DataGovernanceTagsInfo'->new($_) } @$_ ] };

declare 'MapStringDataGovernanceTagsInfo',
    as HashRef[DataGovernanceTagsInfo()];

declare 'DataGovernanceTagsEntry',
    as InstanceOf['Google::Cloud::Bigquery::V2::TableSchema::TableFieldSchema::DataGovernanceTagsInfo::DataGovernanceTagsEntry'];

coerce 'DataGovernanceTagsEntry',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::TableSchema::TableFieldSchema::DataGovernanceTagsInfo::DataGovernanceTagsEntry'->new($_) };

declare 'RepeatedDataGovernanceTagsEntry',
    as ArrayRef[DataGovernanceTagsEntry()];

coerce 'RepeatedDataGovernanceTagsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::TableSchema::TableFieldSchema::DataGovernanceTagsInfo::DataGovernanceTagsEntry'->new($_) } @$_ ] };

declare 'MapStringDataGovernanceTagsEntry',
    as HashRef[DataGovernanceTagsEntry()];

declare 'FieldElementType',
    as InstanceOf['Google::Cloud::Bigquery::V2::TableSchema::TableFieldSchema::FieldElementType'];

coerce 'FieldElementType',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::TableSchema::TableFieldSchema::FieldElementType'->new($_) };

declare 'RepeatedFieldElementType',
    as ArrayRef[FieldElementType()];

coerce 'RepeatedFieldElementType',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::TableSchema::TableFieldSchema::FieldElementType'->new($_) } @$_ ] };

declare 'MapStringFieldElementType',
    as HashRef[FieldElementType()];

declare 'GeneratedExpressionInfo',
    as InstanceOf['Google::Cloud::Bigquery::V2::TableSchema::TableFieldSchema::GeneratedExpressionInfo'];

coerce 'GeneratedExpressionInfo',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::TableSchema::TableFieldSchema::GeneratedExpressionInfo'->new($_) };

declare 'RepeatedGeneratedExpressionInfo',
    as ArrayRef[GeneratedExpressionInfo()];

coerce 'RepeatedGeneratedExpressionInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::TableSchema::TableFieldSchema::GeneratedExpressionInfo'->new($_) } @$_ ] };

declare 'MapStringGeneratedExpressionInfo',
    as HashRef[GeneratedExpressionInfo()];

declare 'GeneratedColumn',
    as InstanceOf['Google::Cloud::Bigquery::V2::TableSchema::TableFieldSchema::GeneratedColumn'];

coerce 'GeneratedColumn',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::TableSchema::TableFieldSchema::GeneratedColumn'->new($_) };

declare 'RepeatedGeneratedColumn',
    as ArrayRef[GeneratedColumn()];

coerce 'RepeatedGeneratedColumn',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::TableSchema::TableFieldSchema::GeneratedColumn'->new($_) } @$_ ] };

declare 'MapStringGeneratedColumn',
    as HashRef[GeneratedColumn()];

declare 'GeneratedMode',
    as (Int | Str);

1;

__END__

=head1 NAME

Google::Cloud::Bigquery::V2::TableSchema::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
