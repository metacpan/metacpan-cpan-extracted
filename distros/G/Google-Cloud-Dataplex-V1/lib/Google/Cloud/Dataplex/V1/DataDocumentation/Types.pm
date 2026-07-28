package Google::Cloud::Dataplex::V1::DataDocumentation::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'DataDocumentationSpec',
    as InstanceOf['Google::Cloud::Dataplex::V1::DataDocumentation::DataDocumentationSpec'];

coerce 'DataDocumentationSpec',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::DataDocumentation::DataDocumentationSpec'->new($_) };

declare 'RepeatedDataDocumentationSpec',
    as ArrayRef[DataDocumentationSpec()];

coerce 'RepeatedDataDocumentationSpec',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::DataDocumentation::DataDocumentationSpec'->new($_) } @$_ ] };

declare 'MapStringDataDocumentationSpec',
    as HashRef[DataDocumentationSpec()];

declare 'GenerationScope',
    as (Int | Str);

declare 'DataDocumentationResult',
    as InstanceOf['Google::Cloud::Dataplex::V1::DataDocumentation::DataDocumentationResult'];

coerce 'DataDocumentationResult',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::DataDocumentation::DataDocumentationResult'->new($_) };

declare 'RepeatedDataDocumentationResult',
    as ArrayRef[DataDocumentationResult()];

coerce 'RepeatedDataDocumentationResult',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::DataDocumentation::DataDocumentationResult'->new($_) } @$_ ] };

declare 'MapStringDataDocumentationResult',
    as HashRef[DataDocumentationResult()];

declare 'DatasetResult',
    as InstanceOf['Google::Cloud::Dataplex::V1::DataDocumentation::DataDocumentationResult::DatasetResult'];

coerce 'DatasetResult',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::DataDocumentation::DataDocumentationResult::DatasetResult'->new($_) };

declare 'RepeatedDatasetResult',
    as ArrayRef[DatasetResult()];

coerce 'RepeatedDatasetResult',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::DataDocumentation::DataDocumentationResult::DatasetResult'->new($_) } @$_ ] };

declare 'MapStringDatasetResult',
    as HashRef[DatasetResult()];

declare 'TableResult',
    as InstanceOf['Google::Cloud::Dataplex::V1::DataDocumentation::DataDocumentationResult::TableResult'];

coerce 'TableResult',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::DataDocumentation::DataDocumentationResult::TableResult'->new($_) };

declare 'RepeatedTableResult',
    as ArrayRef[TableResult()];

coerce 'RepeatedTableResult',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::DataDocumentation::DataDocumentationResult::TableResult'->new($_) } @$_ ] };

declare 'MapStringTableResult',
    as HashRef[TableResult()];

declare 'SchemaRelationship',
    as InstanceOf['Google::Cloud::Dataplex::V1::DataDocumentation::DataDocumentationResult::SchemaRelationship'];

coerce 'SchemaRelationship',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::DataDocumentation::DataDocumentationResult::SchemaRelationship'->new($_) };

declare 'RepeatedSchemaRelationship',
    as ArrayRef[SchemaRelationship()];

coerce 'RepeatedSchemaRelationship',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::DataDocumentation::DataDocumentationResult::SchemaRelationship'->new($_) } @$_ ] };

declare 'MapStringSchemaRelationship',
    as HashRef[SchemaRelationship()];

declare 'Source',
    as (Int | Str);

declare 'Type',
    as (Int | Str);

declare 'SchemaPaths',
    as InstanceOf['Google::Cloud::Dataplex::V1::DataDocumentation::DataDocumentationResult::SchemaRelationship::SchemaPaths'];

coerce 'SchemaPaths',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::DataDocumentation::DataDocumentationResult::SchemaRelationship::SchemaPaths'->new($_) };

declare 'RepeatedSchemaPaths',
    as ArrayRef[SchemaPaths()];

coerce 'RepeatedSchemaPaths',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::DataDocumentation::DataDocumentationResult::SchemaRelationship::SchemaPaths'->new($_) } @$_ ] };

declare 'MapStringSchemaPaths',
    as HashRef[SchemaPaths()];

declare 'Query',
    as InstanceOf['Google::Cloud::Dataplex::V1::DataDocumentation::DataDocumentationResult::Query'];

coerce 'Query',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::DataDocumentation::DataDocumentationResult::Query'->new($_) };

declare 'RepeatedQuery',
    as ArrayRef[Query()];

coerce 'RepeatedQuery',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::DataDocumentation::DataDocumentationResult::Query'->new($_) } @$_ ] };

declare 'MapStringQuery',
    as HashRef[Query()];

declare 'Schema',
    as InstanceOf['Google::Cloud::Dataplex::V1::DataDocumentation::DataDocumentationResult::Schema'];

coerce 'Schema',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::DataDocumentation::DataDocumentationResult::Schema'->new($_) };

declare 'RepeatedSchema',
    as ArrayRef[Schema()];

coerce 'RepeatedSchema',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::DataDocumentation::DataDocumentationResult::Schema'->new($_) } @$_ ] };

declare 'MapStringSchema',
    as HashRef[Schema()];

declare 'Field',
    as InstanceOf['Google::Cloud::Dataplex::V1::DataDocumentation::DataDocumentationResult::Field'];

coerce 'Field',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::DataDocumentation::DataDocumentationResult::Field'->new($_) };

declare 'RepeatedField',
    as ArrayRef[Field()];

coerce 'RepeatedField',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::DataDocumentation::DataDocumentationResult::Field'->new($_) } @$_ ] };

declare 'MapStringField',
    as HashRef[Field()];

1;

__END__

=head1 NAME

Google::Cloud::Dataplex::V1::DataDocumentation::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
