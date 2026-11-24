package Google::Cloud::Contentwarehouse::V1::Document::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'RawDocumentFileType',
    as (Int | Str);

declare 'ContentCategory',
    as (Int | Str);

declare 'Document',
    as InstanceOf['Google::Cloud::Contentwarehouse::V1::Document::Document'];

coerce 'Document',
    from HashRef, via { 'Google::Cloud::Contentwarehouse::V1::Document::Document'->new($_) };

declare 'RepeatedDocument',
    as ArrayRef[Document()];

coerce 'RepeatedDocument',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contentwarehouse::V1::Document::Document'->new($_) } @$_ ] };

declare 'MapStringDocument',
    as HashRef[Document()];

declare 'DocumentReference',
    as InstanceOf['Google::Cloud::Contentwarehouse::V1::Document::DocumentReference'];

coerce 'DocumentReference',
    from HashRef, via { 'Google::Cloud::Contentwarehouse::V1::Document::DocumentReference'->new($_) };

declare 'RepeatedDocumentReference',
    as ArrayRef[DocumentReference()];

coerce 'RepeatedDocumentReference',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contentwarehouse::V1::Document::DocumentReference'->new($_) } @$_ ] };

declare 'MapStringDocumentReference',
    as HashRef[DocumentReference()];

declare 'Property',
    as InstanceOf['Google::Cloud::Contentwarehouse::V1::Document::Property'];

coerce 'Property',
    from HashRef, via { 'Google::Cloud::Contentwarehouse::V1::Document::Property'->new($_) };

declare 'RepeatedProperty',
    as ArrayRef[Property()];

coerce 'RepeatedProperty',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contentwarehouse::V1::Document::Property'->new($_) } @$_ ] };

declare 'MapStringProperty',
    as HashRef[Property()];

declare 'IntegerArray',
    as InstanceOf['Google::Cloud::Contentwarehouse::V1::Document::IntegerArray'];

coerce 'IntegerArray',
    from HashRef, via { 'Google::Cloud::Contentwarehouse::V1::Document::IntegerArray'->new($_) };

declare 'RepeatedIntegerArray',
    as ArrayRef[IntegerArray()];

coerce 'RepeatedIntegerArray',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contentwarehouse::V1::Document::IntegerArray'->new($_) } @$_ ] };

declare 'MapStringIntegerArray',
    as HashRef[IntegerArray()];

declare 'FloatArray',
    as InstanceOf['Google::Cloud::Contentwarehouse::V1::Document::FloatArray'];

coerce 'FloatArray',
    from HashRef, via { 'Google::Cloud::Contentwarehouse::V1::Document::FloatArray'->new($_) };

declare 'RepeatedFloatArray',
    as ArrayRef[FloatArray()];

coerce 'RepeatedFloatArray',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contentwarehouse::V1::Document::FloatArray'->new($_) } @$_ ] };

declare 'MapStringFloatArray',
    as HashRef[FloatArray()];

declare 'TextArray',
    as InstanceOf['Google::Cloud::Contentwarehouse::V1::Document::TextArray'];

coerce 'TextArray',
    from HashRef, via { 'Google::Cloud::Contentwarehouse::V1::Document::TextArray'->new($_) };

declare 'RepeatedTextArray',
    as ArrayRef[TextArray()];

coerce 'RepeatedTextArray',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contentwarehouse::V1::Document::TextArray'->new($_) } @$_ ] };

declare 'MapStringTextArray',
    as HashRef[TextArray()];

declare 'EnumArray',
    as InstanceOf['Google::Cloud::Contentwarehouse::V1::Document::EnumArray'];

coerce 'EnumArray',
    from HashRef, via { 'Google::Cloud::Contentwarehouse::V1::Document::EnumArray'->new($_) };

declare 'RepeatedEnumArray',
    as ArrayRef[EnumArray()];

coerce 'RepeatedEnumArray',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contentwarehouse::V1::Document::EnumArray'->new($_) } @$_ ] };

declare 'MapStringEnumArray',
    as HashRef[EnumArray()];

declare 'DateTimeArray',
    as InstanceOf['Google::Cloud::Contentwarehouse::V1::Document::DateTimeArray'];

coerce 'DateTimeArray',
    from HashRef, via { 'Google::Cloud::Contentwarehouse::V1::Document::DateTimeArray'->new($_) };

declare 'RepeatedDateTimeArray',
    as ArrayRef[DateTimeArray()];

coerce 'RepeatedDateTimeArray',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contentwarehouse::V1::Document::DateTimeArray'->new($_) } @$_ ] };

declare 'MapStringDateTimeArray',
    as HashRef[DateTimeArray()];

declare 'TimestampArray',
    as InstanceOf['Google::Cloud::Contentwarehouse::V1::Document::TimestampArray'];

coerce 'TimestampArray',
    from HashRef, via { 'Google::Cloud::Contentwarehouse::V1::Document::TimestampArray'->new($_) };

declare 'RepeatedTimestampArray',
    as ArrayRef[TimestampArray()];

coerce 'RepeatedTimestampArray',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contentwarehouse::V1::Document::TimestampArray'->new($_) } @$_ ] };

declare 'MapStringTimestampArray',
    as HashRef[TimestampArray()];

declare 'TimestampValue',
    as InstanceOf['Google::Cloud::Contentwarehouse::V1::Document::TimestampValue'];

coerce 'TimestampValue',
    from HashRef, via { 'Google::Cloud::Contentwarehouse::V1::Document::TimestampValue'->new($_) };

declare 'RepeatedTimestampValue',
    as ArrayRef[TimestampValue()];

coerce 'RepeatedTimestampValue',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contentwarehouse::V1::Document::TimestampValue'->new($_) } @$_ ] };

declare 'MapStringTimestampValue',
    as HashRef[TimestampValue()];

declare 'PropertyArray',
    as InstanceOf['Google::Cloud::Contentwarehouse::V1::Document::PropertyArray'];

coerce 'PropertyArray',
    from HashRef, via { 'Google::Cloud::Contentwarehouse::V1::Document::PropertyArray'->new($_) };

declare 'RepeatedPropertyArray',
    as ArrayRef[PropertyArray()];

coerce 'RepeatedPropertyArray',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contentwarehouse::V1::Document::PropertyArray'->new($_) } @$_ ] };

declare 'MapStringPropertyArray',
    as HashRef[PropertyArray()];

declare 'MapProperty',
    as InstanceOf['Google::Cloud::Contentwarehouse::V1::Document::MapProperty'];

coerce 'MapProperty',
    from HashRef, via { 'Google::Cloud::Contentwarehouse::V1::Document::MapProperty'->new($_) };

declare 'RepeatedMapProperty',
    as ArrayRef[MapProperty()];

coerce 'RepeatedMapProperty',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contentwarehouse::V1::Document::MapProperty'->new($_) } @$_ ] };

declare 'MapStringMapProperty',
    as HashRef[MapProperty()];

declare 'FieldsEntry',
    as InstanceOf['Google::Cloud::Contentwarehouse::V1::Document::MapProperty::FieldsEntry'];

coerce 'FieldsEntry',
    from HashRef, via { 'Google::Cloud::Contentwarehouse::V1::Document::MapProperty::FieldsEntry'->new($_) };

declare 'RepeatedFieldsEntry',
    as ArrayRef[FieldsEntry()];

coerce 'RepeatedFieldsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contentwarehouse::V1::Document::MapProperty::FieldsEntry'->new($_) } @$_ ] };

declare 'MapStringFieldsEntry',
    as HashRef[FieldsEntry()];

declare 'Value',
    as InstanceOf['Google::Cloud::Contentwarehouse::V1::Document::Value'];

coerce 'Value',
    from HashRef, via { 'Google::Cloud::Contentwarehouse::V1::Document::Value'->new($_) };

declare 'RepeatedValue',
    as ArrayRef[Value()];

coerce 'RepeatedValue',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contentwarehouse::V1::Document::Value'->new($_) } @$_ ] };

declare 'MapStringValue',
    as HashRef[Value()];

declare 'EnumValue',
    as InstanceOf['Google::Cloud::Contentwarehouse::V1::Document::EnumValue'];

coerce 'EnumValue',
    from HashRef, via { 'Google::Cloud::Contentwarehouse::V1::Document::EnumValue'->new($_) };

declare 'RepeatedEnumValue',
    as ArrayRef[EnumValue()];

coerce 'RepeatedEnumValue',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contentwarehouse::V1::Document::EnumValue'->new($_) } @$_ ] };

declare 'MapStringEnumValue',
    as HashRef[EnumValue()];

1;

__END__

=head1 NAME

Google::Cloud::Contentwarehouse::V1::Document::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
