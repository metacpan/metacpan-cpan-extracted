package Google::Cloud::Contentwarehouse::V1::DocumentSchema::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'DocumentSchema',
    as InstanceOf['Google::Cloud::Contentwarehouse::V1::DocumentSchema::DocumentSchema'];

coerce 'DocumentSchema',
    from HashRef, via { 'Google::Cloud::Contentwarehouse::V1::DocumentSchema::DocumentSchema'->new($_) };

declare 'RepeatedDocumentSchema',
    as ArrayRef[DocumentSchema()];

coerce 'RepeatedDocumentSchema',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contentwarehouse::V1::DocumentSchema::DocumentSchema'->new($_) } @$_ ] };

declare 'MapStringDocumentSchema',
    as HashRef[DocumentSchema()];

declare 'PropertyDefinition',
    as InstanceOf['Google::Cloud::Contentwarehouse::V1::DocumentSchema::PropertyDefinition'];

coerce 'PropertyDefinition',
    from HashRef, via { 'Google::Cloud::Contentwarehouse::V1::DocumentSchema::PropertyDefinition'->new($_) };

declare 'RepeatedPropertyDefinition',
    as ArrayRef[PropertyDefinition()];

coerce 'RepeatedPropertyDefinition',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contentwarehouse::V1::DocumentSchema::PropertyDefinition'->new($_) } @$_ ] };

declare 'MapStringPropertyDefinition',
    as HashRef[PropertyDefinition()];

declare 'RetrievalImportance',
    as (Int | Str);

declare 'SchemaSource',
    as InstanceOf['Google::Cloud::Contentwarehouse::V1::DocumentSchema::PropertyDefinition::SchemaSource'];

coerce 'SchemaSource',
    from HashRef, via { 'Google::Cloud::Contentwarehouse::V1::DocumentSchema::PropertyDefinition::SchemaSource'->new($_) };

declare 'RepeatedSchemaSource',
    as ArrayRef[SchemaSource()];

coerce 'RepeatedSchemaSource',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contentwarehouse::V1::DocumentSchema::PropertyDefinition::SchemaSource'->new($_) } @$_ ] };

declare 'MapStringSchemaSource',
    as HashRef[SchemaSource()];

declare 'IntegerTypeOptions',
    as InstanceOf['Google::Cloud::Contentwarehouse::V1::DocumentSchema::IntegerTypeOptions'];

coerce 'IntegerTypeOptions',
    from HashRef, via { 'Google::Cloud::Contentwarehouse::V1::DocumentSchema::IntegerTypeOptions'->new($_) };

declare 'RepeatedIntegerTypeOptions',
    as ArrayRef[IntegerTypeOptions()];

coerce 'RepeatedIntegerTypeOptions',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contentwarehouse::V1::DocumentSchema::IntegerTypeOptions'->new($_) } @$_ ] };

declare 'MapStringIntegerTypeOptions',
    as HashRef[IntegerTypeOptions()];

declare 'FloatTypeOptions',
    as InstanceOf['Google::Cloud::Contentwarehouse::V1::DocumentSchema::FloatTypeOptions'];

coerce 'FloatTypeOptions',
    from HashRef, via { 'Google::Cloud::Contentwarehouse::V1::DocumentSchema::FloatTypeOptions'->new($_) };

declare 'RepeatedFloatTypeOptions',
    as ArrayRef[FloatTypeOptions()];

coerce 'RepeatedFloatTypeOptions',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contentwarehouse::V1::DocumentSchema::FloatTypeOptions'->new($_) } @$_ ] };

declare 'MapStringFloatTypeOptions',
    as HashRef[FloatTypeOptions()];

declare 'TextTypeOptions',
    as InstanceOf['Google::Cloud::Contentwarehouse::V1::DocumentSchema::TextTypeOptions'];

coerce 'TextTypeOptions',
    from HashRef, via { 'Google::Cloud::Contentwarehouse::V1::DocumentSchema::TextTypeOptions'->new($_) };

declare 'RepeatedTextTypeOptions',
    as ArrayRef[TextTypeOptions()];

coerce 'RepeatedTextTypeOptions',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contentwarehouse::V1::DocumentSchema::TextTypeOptions'->new($_) } @$_ ] };

declare 'MapStringTextTypeOptions',
    as HashRef[TextTypeOptions()];

declare 'DateTimeTypeOptions',
    as InstanceOf['Google::Cloud::Contentwarehouse::V1::DocumentSchema::DateTimeTypeOptions'];

coerce 'DateTimeTypeOptions',
    from HashRef, via { 'Google::Cloud::Contentwarehouse::V1::DocumentSchema::DateTimeTypeOptions'->new($_) };

declare 'RepeatedDateTimeTypeOptions',
    as ArrayRef[DateTimeTypeOptions()];

coerce 'RepeatedDateTimeTypeOptions',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contentwarehouse::V1::DocumentSchema::DateTimeTypeOptions'->new($_) } @$_ ] };

declare 'MapStringDateTimeTypeOptions',
    as HashRef[DateTimeTypeOptions()];

declare 'MapTypeOptions',
    as InstanceOf['Google::Cloud::Contentwarehouse::V1::DocumentSchema::MapTypeOptions'];

coerce 'MapTypeOptions',
    from HashRef, via { 'Google::Cloud::Contentwarehouse::V1::DocumentSchema::MapTypeOptions'->new($_) };

declare 'RepeatedMapTypeOptions',
    as ArrayRef[MapTypeOptions()];

coerce 'RepeatedMapTypeOptions',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contentwarehouse::V1::DocumentSchema::MapTypeOptions'->new($_) } @$_ ] };

declare 'MapStringMapTypeOptions',
    as HashRef[MapTypeOptions()];

declare 'TimestampTypeOptions',
    as InstanceOf['Google::Cloud::Contentwarehouse::V1::DocumentSchema::TimestampTypeOptions'];

coerce 'TimestampTypeOptions',
    from HashRef, via { 'Google::Cloud::Contentwarehouse::V1::DocumentSchema::TimestampTypeOptions'->new($_) };

declare 'RepeatedTimestampTypeOptions',
    as ArrayRef[TimestampTypeOptions()];

coerce 'RepeatedTimestampTypeOptions',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contentwarehouse::V1::DocumentSchema::TimestampTypeOptions'->new($_) } @$_ ] };

declare 'MapStringTimestampTypeOptions',
    as HashRef[TimestampTypeOptions()];

declare 'PropertyTypeOptions',
    as InstanceOf['Google::Cloud::Contentwarehouse::V1::DocumentSchema::PropertyTypeOptions'];

coerce 'PropertyTypeOptions',
    from HashRef, via { 'Google::Cloud::Contentwarehouse::V1::DocumentSchema::PropertyTypeOptions'->new($_) };

declare 'RepeatedPropertyTypeOptions',
    as ArrayRef[PropertyTypeOptions()];

coerce 'RepeatedPropertyTypeOptions',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contentwarehouse::V1::DocumentSchema::PropertyTypeOptions'->new($_) } @$_ ] };

declare 'MapStringPropertyTypeOptions',
    as HashRef[PropertyTypeOptions()];

declare 'EnumTypeOptions',
    as InstanceOf['Google::Cloud::Contentwarehouse::V1::DocumentSchema::EnumTypeOptions'];

coerce 'EnumTypeOptions',
    from HashRef, via { 'Google::Cloud::Contentwarehouse::V1::DocumentSchema::EnumTypeOptions'->new($_) };

declare 'RepeatedEnumTypeOptions',
    as ArrayRef[EnumTypeOptions()];

coerce 'RepeatedEnumTypeOptions',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contentwarehouse::V1::DocumentSchema::EnumTypeOptions'->new($_) } @$_ ] };

declare 'MapStringEnumTypeOptions',
    as HashRef[EnumTypeOptions()];

1;

__END__

=head1 NAME

Google::Cloud::Contentwarehouse::V1::DocumentSchema::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
