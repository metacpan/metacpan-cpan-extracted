package Google::Cloud::Automl::V1beta1::DataTypes::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'TypeCode',
    as (Int | Str);

declare 'DataType',
    as InstanceOf['Google::Cloud::Automl::V1beta1::DataTypes::DataType'];

coerce 'DataType',
    from HashRef, via { 'Google::Cloud::Automl::V1beta1::DataTypes::DataType'->new($_) };

declare 'RepeatedDataType',
    as ArrayRef[DataType()];

coerce 'RepeatedDataType',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Automl::V1beta1::DataTypes::DataType'->new($_) } @$_ ] };

declare 'MapStringDataType',
    as HashRef[DataType()];

declare 'StructType',
    as InstanceOf['Google::Cloud::Automl::V1beta1::DataTypes::StructType'];

coerce 'StructType',
    from HashRef, via { 'Google::Cloud::Automl::V1beta1::DataTypes::StructType'->new($_) };

declare 'RepeatedStructType',
    as ArrayRef[StructType()];

coerce 'RepeatedStructType',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Automl::V1beta1::DataTypes::StructType'->new($_) } @$_ ] };

declare 'MapStringStructType',
    as HashRef[StructType()];

declare 'FieldsEntry',
    as InstanceOf['Google::Cloud::Automl::V1beta1::DataTypes::StructType::FieldsEntry'];

coerce 'FieldsEntry',
    from HashRef, via { 'Google::Cloud::Automl::V1beta1::DataTypes::StructType::FieldsEntry'->new($_) };

declare 'RepeatedFieldsEntry',
    as ArrayRef[FieldsEntry()];

coerce 'RepeatedFieldsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Automl::V1beta1::DataTypes::StructType::FieldsEntry'->new($_) } @$_ ] };

declare 'MapStringFieldsEntry',
    as HashRef[FieldsEntry()];

1;

__END__

=head1 NAME

Google::Cloud::Automl::V1beta1::DataTypes::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
