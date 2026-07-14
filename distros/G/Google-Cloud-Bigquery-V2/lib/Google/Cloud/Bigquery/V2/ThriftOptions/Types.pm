package Google::Cloud::Bigquery::V2::ThriftOptions::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'ThriftOptions',
    as InstanceOf['Google::Cloud::Bigquery::V2::ThriftOptions::ThriftOptions'];

coerce 'ThriftOptions',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::ThriftOptions::ThriftOptions'->new($_) };

declare 'RepeatedThriftOptions',
    as ArrayRef[ThriftOptions()];

coerce 'RepeatedThriftOptions',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::ThriftOptions::ThriftOptions'->new($_) } @$_ ] };

declare 'MapStringThriftOptions',
    as HashRef[ThriftOptions()];

declare 'DeserializationOption',
    as (Int | Str);

declare 'FramingOption',
    as (Int | Str);

1;
