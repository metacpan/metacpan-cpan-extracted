package Google::Cloud::Datacatalog::V1::Schema::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Schema',
    as InstanceOf['Google::Cloud::Datacatalog::V1::Schema::Schema'];

coerce 'Schema',
    from HashRef, via { 'Google::Cloud::Datacatalog::V1::Schema::Schema'->new($_) };

declare 'RepeatedSchema',
    as ArrayRef[Schema()];

coerce 'RepeatedSchema',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datacatalog::V1::Schema::Schema'->new($_) } @$_ ] };

declare 'MapStringSchema',
    as HashRef[Schema()];

declare 'ColumnSchema',
    as InstanceOf['Google::Cloud::Datacatalog::V1::Schema::ColumnSchema'];

coerce 'ColumnSchema',
    from HashRef, via { 'Google::Cloud::Datacatalog::V1::Schema::ColumnSchema'->new($_) };

declare 'RepeatedColumnSchema',
    as ArrayRef[ColumnSchema()];

coerce 'RepeatedColumnSchema',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datacatalog::V1::Schema::ColumnSchema'->new($_) } @$_ ] };

declare 'MapStringColumnSchema',
    as HashRef[ColumnSchema()];

declare 'IndexingType',
    as (Int | Str);

declare 'LookerColumnSpec',
    as InstanceOf['Google::Cloud::Datacatalog::V1::Schema::ColumnSchema::LookerColumnSpec'];

coerce 'LookerColumnSpec',
    from HashRef, via { 'Google::Cloud::Datacatalog::V1::Schema::ColumnSchema::LookerColumnSpec'->new($_) };

declare 'RepeatedLookerColumnSpec',
    as ArrayRef[LookerColumnSpec()];

coerce 'RepeatedLookerColumnSpec',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datacatalog::V1::Schema::ColumnSchema::LookerColumnSpec'->new($_) } @$_ ] };

declare 'MapStringLookerColumnSpec',
    as HashRef[LookerColumnSpec()];

declare 'LookerColumnType',
    as (Int | Str);

declare 'FieldElementType',
    as InstanceOf['Google::Cloud::Datacatalog::V1::Schema::ColumnSchema::FieldElementType'];

coerce 'FieldElementType',
    from HashRef, via { 'Google::Cloud::Datacatalog::V1::Schema::ColumnSchema::FieldElementType'->new($_) };

declare 'RepeatedFieldElementType',
    as ArrayRef[FieldElementType()];

coerce 'RepeatedFieldElementType',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datacatalog::V1::Schema::ColumnSchema::FieldElementType'->new($_) } @$_ ] };

declare 'MapStringFieldElementType',
    as HashRef[FieldElementType()];

1;

__END__

=head1 NAME

Google::Cloud::Datacatalog::V1::Schema::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
