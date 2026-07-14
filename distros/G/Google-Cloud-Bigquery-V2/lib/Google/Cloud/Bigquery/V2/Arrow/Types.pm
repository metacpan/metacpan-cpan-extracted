package Google::Cloud::Bigquery::V2::Arrow::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'ArrowSchema',
    as InstanceOf['Google::Cloud::Bigquery::V2::Arrow::ArrowSchema'];

coerce 'ArrowSchema',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::Arrow::ArrowSchema'->new($_) };

declare 'RepeatedArrowSchema',
    as ArrayRef[ArrowSchema()];

coerce 'RepeatedArrowSchema',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::Arrow::ArrowSchema'->new($_) } @$_ ] };

declare 'MapStringArrowSchema',
    as HashRef[ArrowSchema()];

declare 'ArrowRecordBatch',
    as InstanceOf['Google::Cloud::Bigquery::V2::Arrow::ArrowRecordBatch'];

coerce 'ArrowRecordBatch',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::Arrow::ArrowRecordBatch'->new($_) };

declare 'RepeatedArrowRecordBatch',
    as ArrayRef[ArrowRecordBatch()];

coerce 'RepeatedArrowRecordBatch',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::Arrow::ArrowRecordBatch'->new($_) } @$_ ] };

declare 'MapStringArrowRecordBatch',
    as HashRef[ArrowRecordBatch()];

declare 'ArrowSerializationOptions',
    as InstanceOf['Google::Cloud::Bigquery::V2::Arrow::ArrowSerializationOptions'];

coerce 'ArrowSerializationOptions',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::Arrow::ArrowSerializationOptions'->new($_) };

declare 'RepeatedArrowSerializationOptions',
    as ArrayRef[ArrowSerializationOptions()];

coerce 'RepeatedArrowSerializationOptions',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::Arrow::ArrowSerializationOptions'->new($_) } @$_ ] };

declare 'MapStringArrowSerializationOptions',
    as HashRef[ArrowSerializationOptions()];

declare 'CompressionCodec',
    as (Int | Str);

declare 'PicosTimestampPrecision',
    as (Int | Str);

1;
