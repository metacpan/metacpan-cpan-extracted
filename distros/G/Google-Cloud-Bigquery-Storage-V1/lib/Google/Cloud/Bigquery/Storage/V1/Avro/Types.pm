package Google::Cloud::Bigquery::Storage::V1::Avro::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'AvroSchema',
    as InstanceOf['Google::Cloud::Bigquery::Storage::V1::Avro::AvroSchema'];

coerce 'AvroSchema',
    from HashRef, via { 'Google::Cloud::Bigquery::Storage::V1::Avro::AvroSchema'->new($_) };

declare 'RepeatedAvroSchema',
    as ArrayRef[AvroSchema()];

coerce 'RepeatedAvroSchema',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Storage::V1::Avro::AvroSchema'->new($_) } @$_ ] };

declare 'MapStringAvroSchema',
    as HashRef[AvroSchema()];

declare 'AvroRows',
    as InstanceOf['Google::Cloud::Bigquery::Storage::V1::Avro::AvroRows'];

coerce 'AvroRows',
    from HashRef, via { 'Google::Cloud::Bigquery::Storage::V1::Avro::AvroRows'->new($_) };

declare 'RepeatedAvroRows',
    as ArrayRef[AvroRows()];

coerce 'RepeatedAvroRows',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Storage::V1::Avro::AvroRows'->new($_) } @$_ ] };

declare 'MapStringAvroRows',
    as HashRef[AvroRows()];

declare 'AvroSerializationOptions',
    as InstanceOf['Google::Cloud::Bigquery::Storage::V1::Avro::AvroSerializationOptions'];

coerce 'AvroSerializationOptions',
    from HashRef, via { 'Google::Cloud::Bigquery::Storage::V1::Avro::AvroSerializationOptions'->new($_) };

declare 'RepeatedAvroSerializationOptions',
    as ArrayRef[AvroSerializationOptions()];

coerce 'RepeatedAvroSerializationOptions',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Storage::V1::Avro::AvroSerializationOptions'->new($_) } @$_ ] };

declare 'MapStringAvroSerializationOptions',
    as HashRef[AvroSerializationOptions()];

declare 'PicosTimestampPrecision',
    as (Int | Str);

1;

__END__

=head1 NAME

Google::Cloud::Bigquery::Storage::V1::Avro::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
