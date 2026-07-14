package Google::Cloud::Bigquery::V2::ValueConversionModes::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'ValueConversionModes',
    as InstanceOf['Google::Cloud::Bigquery::V2::ValueConversionModes::ValueConversionModes'];

coerce 'ValueConversionModes',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::ValueConversionModes::ValueConversionModes'->new($_) };

declare 'RepeatedValueConversionModes',
    as ArrayRef[ValueConversionModes()];

coerce 'RepeatedValueConversionModes',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::ValueConversionModes::ValueConversionModes'->new($_) } @$_ ] };

declare 'MapStringValueConversionModes',
    as HashRef[ValueConversionModes()];

declare 'TemporalTypesValue',
    as (Int | Str);

declare 'NumericTypeValue',
    as (Int | Str);

1;
