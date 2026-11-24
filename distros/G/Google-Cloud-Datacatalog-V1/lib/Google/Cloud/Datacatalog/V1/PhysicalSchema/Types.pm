package Google::Cloud::Datacatalog::V1::PhysicalSchema::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'PhysicalSchema',
    as InstanceOf['Google::Cloud::Datacatalog::V1::PhysicalSchema::PhysicalSchema'];

coerce 'PhysicalSchema',
    from HashRef, via { 'Google::Cloud::Datacatalog::V1::PhysicalSchema::PhysicalSchema'->new($_) };

declare 'RepeatedPhysicalSchema',
    as ArrayRef[PhysicalSchema()];

coerce 'RepeatedPhysicalSchema',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datacatalog::V1::PhysicalSchema::PhysicalSchema'->new($_) } @$_ ] };

declare 'MapStringPhysicalSchema',
    as HashRef[PhysicalSchema()];

declare 'AvroSchema',
    as InstanceOf['Google::Cloud::Datacatalog::V1::PhysicalSchema::PhysicalSchema::AvroSchema'];

coerce 'AvroSchema',
    from HashRef, via { 'Google::Cloud::Datacatalog::V1::PhysicalSchema::PhysicalSchema::AvroSchema'->new($_) };

declare 'RepeatedAvroSchema',
    as ArrayRef[AvroSchema()];

coerce 'RepeatedAvroSchema',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datacatalog::V1::PhysicalSchema::PhysicalSchema::AvroSchema'->new($_) } @$_ ] };

declare 'MapStringAvroSchema',
    as HashRef[AvroSchema()];

declare 'ThriftSchema',
    as InstanceOf['Google::Cloud::Datacatalog::V1::PhysicalSchema::PhysicalSchema::ThriftSchema'];

coerce 'ThriftSchema',
    from HashRef, via { 'Google::Cloud::Datacatalog::V1::PhysicalSchema::PhysicalSchema::ThriftSchema'->new($_) };

declare 'RepeatedThriftSchema',
    as ArrayRef[ThriftSchema()];

coerce 'RepeatedThriftSchema',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datacatalog::V1::PhysicalSchema::PhysicalSchema::ThriftSchema'->new($_) } @$_ ] };

declare 'MapStringThriftSchema',
    as HashRef[ThriftSchema()];

declare 'ProtobufSchema',
    as InstanceOf['Google::Cloud::Datacatalog::V1::PhysicalSchema::PhysicalSchema::ProtobufSchema'];

coerce 'ProtobufSchema',
    from HashRef, via { 'Google::Cloud::Datacatalog::V1::PhysicalSchema::PhysicalSchema::ProtobufSchema'->new($_) };

declare 'RepeatedProtobufSchema',
    as ArrayRef[ProtobufSchema()];

coerce 'RepeatedProtobufSchema',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datacatalog::V1::PhysicalSchema::PhysicalSchema::ProtobufSchema'->new($_) } @$_ ] };

declare 'MapStringProtobufSchema',
    as HashRef[ProtobufSchema()];

declare 'ParquetSchema',
    as InstanceOf['Google::Cloud::Datacatalog::V1::PhysicalSchema::PhysicalSchema::ParquetSchema'];

coerce 'ParquetSchema',
    from HashRef, via { 'Google::Cloud::Datacatalog::V1::PhysicalSchema::PhysicalSchema::ParquetSchema'->new($_) };

declare 'RepeatedParquetSchema',
    as ArrayRef[ParquetSchema()];

coerce 'RepeatedParquetSchema',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datacatalog::V1::PhysicalSchema::PhysicalSchema::ParquetSchema'->new($_) } @$_ ] };

declare 'MapStringParquetSchema',
    as HashRef[ParquetSchema()];

declare 'OrcSchema',
    as InstanceOf['Google::Cloud::Datacatalog::V1::PhysicalSchema::PhysicalSchema::OrcSchema'];

coerce 'OrcSchema',
    from HashRef, via { 'Google::Cloud::Datacatalog::V1::PhysicalSchema::PhysicalSchema::OrcSchema'->new($_) };

declare 'RepeatedOrcSchema',
    as ArrayRef[OrcSchema()];

coerce 'RepeatedOrcSchema',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datacatalog::V1::PhysicalSchema::PhysicalSchema::OrcSchema'->new($_) } @$_ ] };

declare 'MapStringOrcSchema',
    as HashRef[OrcSchema()];

declare 'CsvSchema',
    as InstanceOf['Google::Cloud::Datacatalog::V1::PhysicalSchema::PhysicalSchema::CsvSchema'];

coerce 'CsvSchema',
    from HashRef, via { 'Google::Cloud::Datacatalog::V1::PhysicalSchema::PhysicalSchema::CsvSchema'->new($_) };

declare 'RepeatedCsvSchema',
    as ArrayRef[CsvSchema()];

coerce 'RepeatedCsvSchema',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datacatalog::V1::PhysicalSchema::PhysicalSchema::CsvSchema'->new($_) } @$_ ] };

declare 'MapStringCsvSchema',
    as HashRef[CsvSchema()];

1;

__END__

=head1 NAME

Google::Cloud::Datacatalog::V1::PhysicalSchema::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
