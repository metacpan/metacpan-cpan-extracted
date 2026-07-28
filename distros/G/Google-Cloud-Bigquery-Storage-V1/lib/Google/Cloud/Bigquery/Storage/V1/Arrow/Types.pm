package Google::Cloud::Bigquery::Storage::V1::Arrow::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'ArrowSchema',
    as InstanceOf['Google::Cloud::Bigquery::Storage::V1::Arrow::ArrowSchema'];

coerce 'ArrowSchema',
    from HashRef, via { 'Google::Cloud::Bigquery::Storage::V1::Arrow::ArrowSchema'->new($_) };

declare 'RepeatedArrowSchema',
    as ArrayRef[ArrowSchema()];

coerce 'RepeatedArrowSchema',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Storage::V1::Arrow::ArrowSchema'->new($_) } @$_ ] };

declare 'MapStringArrowSchema',
    as HashRef[ArrowSchema()];

declare 'ArrowRecordBatch',
    as InstanceOf['Google::Cloud::Bigquery::Storage::V1::Arrow::ArrowRecordBatch'];

coerce 'ArrowRecordBatch',
    from HashRef, via { 'Google::Cloud::Bigquery::Storage::V1::Arrow::ArrowRecordBatch'->new($_) };

declare 'RepeatedArrowRecordBatch',
    as ArrayRef[ArrowRecordBatch()];

coerce 'RepeatedArrowRecordBatch',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Storage::V1::Arrow::ArrowRecordBatch'->new($_) } @$_ ] };

declare 'MapStringArrowRecordBatch',
    as HashRef[ArrowRecordBatch()];

declare 'ArrowSerializationOptions',
    as InstanceOf['Google::Cloud::Bigquery::Storage::V1::Arrow::ArrowSerializationOptions'];

coerce 'ArrowSerializationOptions',
    from HashRef, via { 'Google::Cloud::Bigquery::Storage::V1::Arrow::ArrowSerializationOptions'->new($_) };

declare 'RepeatedArrowSerializationOptions',
    as ArrayRef[ArrowSerializationOptions()];

coerce 'RepeatedArrowSerializationOptions',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Storage::V1::Arrow::ArrowSerializationOptions'->new($_) } @$_ ] };

declare 'MapStringArrowSerializationOptions',
    as HashRef[ArrowSerializationOptions()];

declare 'CompressionCodec',
    as (Int | Str);

declare 'PicosTimestampPrecision',
    as (Int | Str);

1;

__END__

=head1 NAME

Google::Cloud::Bigquery::Storage::V1::Arrow::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
