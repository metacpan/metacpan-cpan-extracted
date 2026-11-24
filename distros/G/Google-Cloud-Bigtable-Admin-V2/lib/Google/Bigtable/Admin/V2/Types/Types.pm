package Google::Bigtable::Admin::V2::Types::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Type',
    as InstanceOf['Google::Bigtable::Admin::V2::Types::Type'];

coerce 'Type',
    from HashRef, via { 'Google::Bigtable::Admin::V2::Types::Type'->new($_) };

declare 'RepeatedType',
    as ArrayRef[Type()];

coerce 'RepeatedType',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::Admin::V2::Types::Type'->new($_) } @$_ ] };

declare 'MapStringType',
    as HashRef[Type()];

declare 'Bytes',
    as InstanceOf['Google::Bigtable::Admin::V2::Types::Type::Bytes'];

coerce 'Bytes',
    from HashRef, via { 'Google::Bigtable::Admin::V2::Types::Type::Bytes'->new($_) };

declare 'RepeatedBytes',
    as ArrayRef[Bytes()];

coerce 'RepeatedBytes',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::Admin::V2::Types::Type::Bytes'->new($_) } @$_ ] };

declare 'MapStringBytes',
    as HashRef[Bytes()];

declare 'Encoding',
    as InstanceOf['Google::Bigtable::Admin::V2::Types::Type::Bytes::Encoding'];

coerce 'Encoding',
    from HashRef, via { 'Google::Bigtable::Admin::V2::Types::Type::Bytes::Encoding'->new($_) };

declare 'RepeatedEncoding',
    as ArrayRef[Encoding()];

coerce 'RepeatedEncoding',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::Admin::V2::Types::Type::Bytes::Encoding'->new($_) } @$_ ] };

declare 'MapStringEncoding',
    as HashRef[Encoding()];

declare 'Raw',
    as InstanceOf['Google::Bigtable::Admin::V2::Types::Type::Bytes::Encoding::Raw'];

coerce 'Raw',
    from HashRef, via { 'Google::Bigtable::Admin::V2::Types::Type::Bytes::Encoding::Raw'->new($_) };

declare 'RepeatedRaw',
    as ArrayRef[Raw()];

coerce 'RepeatedRaw',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::Admin::V2::Types::Type::Bytes::Encoding::Raw'->new($_) } @$_ ] };

declare 'MapStringRaw',
    as HashRef[Raw()];

declare 'String',
    as InstanceOf['Google::Bigtable::Admin::V2::Types::Type::String'];

coerce 'String',
    from HashRef, via { 'Google::Bigtable::Admin::V2::Types::Type::String'->new($_) };

declare 'RepeatedString',
    as ArrayRef[String()];

coerce 'RepeatedString',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::Admin::V2::Types::Type::String'->new($_) } @$_ ] };

declare 'MapStringString',
    as HashRef[String()];

declare 'Encoding',
    as InstanceOf['Google::Bigtable::Admin::V2::Types::Type::String::Encoding'];

coerce 'Encoding',
    from HashRef, via { 'Google::Bigtable::Admin::V2::Types::Type::String::Encoding'->new($_) };

declare 'RepeatedEncoding',
    as ArrayRef[Encoding()];

coerce 'RepeatedEncoding',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::Admin::V2::Types::Type::String::Encoding'->new($_) } @$_ ] };

declare 'MapStringEncoding',
    as HashRef[Encoding()];

declare 'Utf8Raw',
    as InstanceOf['Google::Bigtable::Admin::V2::Types::Type::String::Encoding::Utf8Raw'];

coerce 'Utf8Raw',
    from HashRef, via { 'Google::Bigtable::Admin::V2::Types::Type::String::Encoding::Utf8Raw'->new($_) };

declare 'RepeatedUtf8Raw',
    as ArrayRef[Utf8Raw()];

coerce 'RepeatedUtf8Raw',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::Admin::V2::Types::Type::String::Encoding::Utf8Raw'->new($_) } @$_ ] };

declare 'MapStringUtf8Raw',
    as HashRef[Utf8Raw()];

declare 'Utf8Bytes',
    as InstanceOf['Google::Bigtable::Admin::V2::Types::Type::String::Encoding::Utf8Bytes'];

coerce 'Utf8Bytes',
    from HashRef, via { 'Google::Bigtable::Admin::V2::Types::Type::String::Encoding::Utf8Bytes'->new($_) };

declare 'RepeatedUtf8Bytes',
    as ArrayRef[Utf8Bytes()];

coerce 'RepeatedUtf8Bytes',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::Admin::V2::Types::Type::String::Encoding::Utf8Bytes'->new($_) } @$_ ] };

declare 'MapStringUtf8Bytes',
    as HashRef[Utf8Bytes()];

declare 'Int64',
    as InstanceOf['Google::Bigtable::Admin::V2::Types::Type::Int64'];

coerce 'Int64',
    from HashRef, via { 'Google::Bigtable::Admin::V2::Types::Type::Int64'->new($_) };

declare 'RepeatedInt64',
    as ArrayRef[Int64()];

coerce 'RepeatedInt64',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::Admin::V2::Types::Type::Int64'->new($_) } @$_ ] };

declare 'MapStringInt64',
    as HashRef[Int64()];

declare 'Encoding',
    as InstanceOf['Google::Bigtable::Admin::V2::Types::Type::Int64::Encoding'];

coerce 'Encoding',
    from HashRef, via { 'Google::Bigtable::Admin::V2::Types::Type::Int64::Encoding'->new($_) };

declare 'RepeatedEncoding',
    as ArrayRef[Encoding()];

coerce 'RepeatedEncoding',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::Admin::V2::Types::Type::Int64::Encoding'->new($_) } @$_ ] };

declare 'MapStringEncoding',
    as HashRef[Encoding()];

declare 'BigEndianBytes',
    as InstanceOf['Google::Bigtable::Admin::V2::Types::Type::Int64::Encoding::BigEndianBytes'];

coerce 'BigEndianBytes',
    from HashRef, via { 'Google::Bigtable::Admin::V2::Types::Type::Int64::Encoding::BigEndianBytes'->new($_) };

declare 'RepeatedBigEndianBytes',
    as ArrayRef[BigEndianBytes()];

coerce 'RepeatedBigEndianBytes',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::Admin::V2::Types::Type::Int64::Encoding::BigEndianBytes'->new($_) } @$_ ] };

declare 'MapStringBigEndianBytes',
    as HashRef[BigEndianBytes()];

declare 'OrderedCodeBytes',
    as InstanceOf['Google::Bigtable::Admin::V2::Types::Type::Int64::Encoding::OrderedCodeBytes'];

coerce 'OrderedCodeBytes',
    from HashRef, via { 'Google::Bigtable::Admin::V2::Types::Type::Int64::Encoding::OrderedCodeBytes'->new($_) };

declare 'RepeatedOrderedCodeBytes',
    as ArrayRef[OrderedCodeBytes()];

coerce 'RepeatedOrderedCodeBytes',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::Admin::V2::Types::Type::Int64::Encoding::OrderedCodeBytes'->new($_) } @$_ ] };

declare 'MapStringOrderedCodeBytes',
    as HashRef[OrderedCodeBytes()];

declare 'Bool',
    as InstanceOf['Google::Bigtable::Admin::V2::Types::Type::Bool'];

coerce 'Bool',
    from HashRef, via { 'Google::Bigtable::Admin::V2::Types::Type::Bool'->new($_) };

declare 'RepeatedBool',
    as ArrayRef[Bool()];

coerce 'RepeatedBool',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::Admin::V2::Types::Type::Bool'->new($_) } @$_ ] };

declare 'MapStringBool',
    as HashRef[Bool()];

declare 'Float32',
    as InstanceOf['Google::Bigtable::Admin::V2::Types::Type::Float32'];

coerce 'Float32',
    from HashRef, via { 'Google::Bigtable::Admin::V2::Types::Type::Float32'->new($_) };

declare 'RepeatedFloat32',
    as ArrayRef[Float32()];

coerce 'RepeatedFloat32',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::Admin::V2::Types::Type::Float32'->new($_) } @$_ ] };

declare 'MapStringFloat32',
    as HashRef[Float32()];

declare 'Float64',
    as InstanceOf['Google::Bigtable::Admin::V2::Types::Type::Float64'];

coerce 'Float64',
    from HashRef, via { 'Google::Bigtable::Admin::V2::Types::Type::Float64'->new($_) };

declare 'RepeatedFloat64',
    as ArrayRef[Float64()];

coerce 'RepeatedFloat64',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::Admin::V2::Types::Type::Float64'->new($_) } @$_ ] };

declare 'MapStringFloat64',
    as HashRef[Float64()];

declare 'Timestamp',
    as InstanceOf['Google::Bigtable::Admin::V2::Types::Type::Timestamp'];

coerce 'Timestamp',
    from HashRef, via { 'Google::Bigtable::Admin::V2::Types::Type::Timestamp'->new($_) };

declare 'RepeatedTimestamp',
    as ArrayRef[Timestamp()];

coerce 'RepeatedTimestamp',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::Admin::V2::Types::Type::Timestamp'->new($_) } @$_ ] };

declare 'MapStringTimestamp',
    as HashRef[Timestamp()];

declare 'Encoding',
    as InstanceOf['Google::Bigtable::Admin::V2::Types::Type::Timestamp::Encoding'];

coerce 'Encoding',
    from HashRef, via { 'Google::Bigtable::Admin::V2::Types::Type::Timestamp::Encoding'->new($_) };

declare 'RepeatedEncoding',
    as ArrayRef[Encoding()];

coerce 'RepeatedEncoding',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::Admin::V2::Types::Type::Timestamp::Encoding'->new($_) } @$_ ] };

declare 'MapStringEncoding',
    as HashRef[Encoding()];

declare 'Date',
    as InstanceOf['Google::Bigtable::Admin::V2::Types::Type::Date'];

coerce 'Date',
    from HashRef, via { 'Google::Bigtable::Admin::V2::Types::Type::Date'->new($_) };

declare 'RepeatedDate',
    as ArrayRef[Date()];

coerce 'RepeatedDate',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::Admin::V2::Types::Type::Date'->new($_) } @$_ ] };

declare 'MapStringDate',
    as HashRef[Date()];

declare 'Struct',
    as InstanceOf['Google::Bigtable::Admin::V2::Types::Type::Struct'];

coerce 'Struct',
    from HashRef, via { 'Google::Bigtable::Admin::V2::Types::Type::Struct'->new($_) };

declare 'RepeatedStruct',
    as ArrayRef[Struct()];

coerce 'RepeatedStruct',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::Admin::V2::Types::Type::Struct'->new($_) } @$_ ] };

declare 'MapStringStruct',
    as HashRef[Struct()];

declare 'Field',
    as InstanceOf['Google::Bigtable::Admin::V2::Types::Type::Struct::Field'];

coerce 'Field',
    from HashRef, via { 'Google::Bigtable::Admin::V2::Types::Type::Struct::Field'->new($_) };

declare 'RepeatedField',
    as ArrayRef[Field()];

coerce 'RepeatedField',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::Admin::V2::Types::Type::Struct::Field'->new($_) } @$_ ] };

declare 'MapStringField',
    as HashRef[Field()];

declare 'Encoding',
    as InstanceOf['Google::Bigtable::Admin::V2::Types::Type::Struct::Encoding'];

coerce 'Encoding',
    from HashRef, via { 'Google::Bigtable::Admin::V2::Types::Type::Struct::Encoding'->new($_) };

declare 'RepeatedEncoding',
    as ArrayRef[Encoding()];

coerce 'RepeatedEncoding',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::Admin::V2::Types::Type::Struct::Encoding'->new($_) } @$_ ] };

declare 'MapStringEncoding',
    as HashRef[Encoding()];

declare 'Singleton',
    as InstanceOf['Google::Bigtable::Admin::V2::Types::Type::Struct::Encoding::Singleton'];

coerce 'Singleton',
    from HashRef, via { 'Google::Bigtable::Admin::V2::Types::Type::Struct::Encoding::Singleton'->new($_) };

declare 'RepeatedSingleton',
    as ArrayRef[Singleton()];

coerce 'RepeatedSingleton',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::Admin::V2::Types::Type::Struct::Encoding::Singleton'->new($_) } @$_ ] };

declare 'MapStringSingleton',
    as HashRef[Singleton()];

declare 'DelimitedBytes',
    as InstanceOf['Google::Bigtable::Admin::V2::Types::Type::Struct::Encoding::DelimitedBytes'];

coerce 'DelimitedBytes',
    from HashRef, via { 'Google::Bigtable::Admin::V2::Types::Type::Struct::Encoding::DelimitedBytes'->new($_) };

declare 'RepeatedDelimitedBytes',
    as ArrayRef[DelimitedBytes()];

coerce 'RepeatedDelimitedBytes',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::Admin::V2::Types::Type::Struct::Encoding::DelimitedBytes'->new($_) } @$_ ] };

declare 'MapStringDelimitedBytes',
    as HashRef[DelimitedBytes()];

declare 'OrderedCodeBytes',
    as InstanceOf['Google::Bigtable::Admin::V2::Types::Type::Struct::Encoding::OrderedCodeBytes'];

coerce 'OrderedCodeBytes',
    from HashRef, via { 'Google::Bigtable::Admin::V2::Types::Type::Struct::Encoding::OrderedCodeBytes'->new($_) };

declare 'RepeatedOrderedCodeBytes',
    as ArrayRef[OrderedCodeBytes()];

coerce 'RepeatedOrderedCodeBytes',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::Admin::V2::Types::Type::Struct::Encoding::OrderedCodeBytes'->new($_) } @$_ ] };

declare 'MapStringOrderedCodeBytes',
    as HashRef[OrderedCodeBytes()];

declare 'Proto',
    as InstanceOf['Google::Bigtable::Admin::V2::Types::Type::Proto'];

coerce 'Proto',
    from HashRef, via { 'Google::Bigtable::Admin::V2::Types::Type::Proto'->new($_) };

declare 'RepeatedProto',
    as ArrayRef[Proto()];

coerce 'RepeatedProto',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::Admin::V2::Types::Type::Proto'->new($_) } @$_ ] };

declare 'MapStringProto',
    as HashRef[Proto()];

declare 'Enum',
    as InstanceOf['Google::Bigtable::Admin::V2::Types::Type::Enum'];

coerce 'Enum',
    from HashRef, via { 'Google::Bigtable::Admin::V2::Types::Type::Enum'->new($_) };

declare 'RepeatedEnum',
    as ArrayRef[Enum()];

coerce 'RepeatedEnum',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::Admin::V2::Types::Type::Enum'->new($_) } @$_ ] };

declare 'MapStringEnum',
    as HashRef[Enum()];

declare 'Array',
    as InstanceOf['Google::Bigtable::Admin::V2::Types::Type::Array'];

coerce 'Array',
    from HashRef, via { 'Google::Bigtable::Admin::V2::Types::Type::Array'->new($_) };

declare 'RepeatedArray',
    as ArrayRef[Array()];

coerce 'RepeatedArray',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::Admin::V2::Types::Type::Array'->new($_) } @$_ ] };

declare 'MapStringArray',
    as HashRef[Array()];

declare 'Map',
    as InstanceOf['Google::Bigtable::Admin::V2::Types::Type::Map'];

coerce 'Map',
    from HashRef, via { 'Google::Bigtable::Admin::V2::Types::Type::Map'->new($_) };

declare 'RepeatedMap',
    as ArrayRef[Map()];

coerce 'RepeatedMap',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::Admin::V2::Types::Type::Map'->new($_) } @$_ ] };

declare 'MapStringMap',
    as HashRef[Map()];

declare 'Aggregate',
    as InstanceOf['Google::Bigtable::Admin::V2::Types::Type::Aggregate'];

coerce 'Aggregate',
    from HashRef, via { 'Google::Bigtable::Admin::V2::Types::Type::Aggregate'->new($_) };

declare 'RepeatedAggregate',
    as ArrayRef[Aggregate()];

coerce 'RepeatedAggregate',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::Admin::V2::Types::Type::Aggregate'->new($_) } @$_ ] };

declare 'MapStringAggregate',
    as HashRef[Aggregate()];

declare 'Sum',
    as InstanceOf['Google::Bigtable::Admin::V2::Types::Type::Aggregate::Sum'];

coerce 'Sum',
    from HashRef, via { 'Google::Bigtable::Admin::V2::Types::Type::Aggregate::Sum'->new($_) };

declare 'RepeatedSum',
    as ArrayRef[Sum()];

coerce 'RepeatedSum',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::Admin::V2::Types::Type::Aggregate::Sum'->new($_) } @$_ ] };

declare 'MapStringSum',
    as HashRef[Sum()];

declare 'Max',
    as InstanceOf['Google::Bigtable::Admin::V2::Types::Type::Aggregate::Max'];

coerce 'Max',
    from HashRef, via { 'Google::Bigtable::Admin::V2::Types::Type::Aggregate::Max'->new($_) };

declare 'RepeatedMax',
    as ArrayRef[Max()];

coerce 'RepeatedMax',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::Admin::V2::Types::Type::Aggregate::Max'->new($_) } @$_ ] };

declare 'MapStringMax',
    as HashRef[Max()];

declare 'Min',
    as InstanceOf['Google::Bigtable::Admin::V2::Types::Type::Aggregate::Min'];

coerce 'Min',
    from HashRef, via { 'Google::Bigtable::Admin::V2::Types::Type::Aggregate::Min'->new($_) };

declare 'RepeatedMin',
    as ArrayRef[Min()];

coerce 'RepeatedMin',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::Admin::V2::Types::Type::Aggregate::Min'->new($_) } @$_ ] };

declare 'MapStringMin',
    as HashRef[Min()];

declare 'HyperLogLogPlusPlusUniqueCount',
    as InstanceOf['Google::Bigtable::Admin::V2::Types::Type::Aggregate::HyperLogLogPlusPlusUniqueCount'];

coerce 'HyperLogLogPlusPlusUniqueCount',
    from HashRef, via { 'Google::Bigtable::Admin::V2::Types::Type::Aggregate::HyperLogLogPlusPlusUniqueCount'->new($_) };

declare 'RepeatedHyperLogLogPlusPlusUniqueCount',
    as ArrayRef[HyperLogLogPlusPlusUniqueCount()];

coerce 'RepeatedHyperLogLogPlusPlusUniqueCount',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::Admin::V2::Types::Type::Aggregate::HyperLogLogPlusPlusUniqueCount'->new($_) } @$_ ] };

declare 'MapStringHyperLogLogPlusPlusUniqueCount',
    as HashRef[HyperLogLogPlusPlusUniqueCount()];

1;

__END__

=head1 NAME

Google::Bigtable::Admin::V2::Types::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
