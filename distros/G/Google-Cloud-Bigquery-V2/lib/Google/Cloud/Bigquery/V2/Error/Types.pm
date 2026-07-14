package Google::Cloud::Bigquery::V2::Error::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'ErrorProto',
    as InstanceOf['Google::Cloud::Bigquery::V2::Error::ErrorProto'];

coerce 'ErrorProto',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::Error::ErrorProto'->new($_) };

declare 'RepeatedErrorProto',
    as ArrayRef[ErrorProto()];

coerce 'RepeatedErrorProto',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::Error::ErrorProto'->new($_) } @$_ ] };

declare 'MapStringErrorProto',
    as HashRef[ErrorProto()];

1;
