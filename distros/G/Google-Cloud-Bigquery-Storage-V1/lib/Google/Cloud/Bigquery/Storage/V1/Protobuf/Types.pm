package Google::Cloud::Bigquery::Storage::V1::Protobuf::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'ProtoSchema',
    as InstanceOf['Google::Cloud::Bigquery::Storage::V1::Protobuf::ProtoSchema'];

coerce 'ProtoSchema',
    from HashRef, via { 'Google::Cloud::Bigquery::Storage::V1::Protobuf::ProtoSchema'->new($_) };

declare 'RepeatedProtoSchema',
    as ArrayRef[ProtoSchema()];

coerce 'RepeatedProtoSchema',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Storage::V1::Protobuf::ProtoSchema'->new($_) } @$_ ] };

declare 'MapStringProtoSchema',
    as HashRef[ProtoSchema()];

declare 'ProtoRows',
    as InstanceOf['Google::Cloud::Bigquery::Storage::V1::Protobuf::ProtoRows'];

coerce 'ProtoRows',
    from HashRef, via { 'Google::Cloud::Bigquery::Storage::V1::Protobuf::ProtoRows'->new($_) };

declare 'RepeatedProtoRows',
    as ArrayRef[ProtoRows()];

coerce 'RepeatedProtoRows',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Storage::V1::Protobuf::ProtoRows'->new($_) } @$_ ] };

declare 'MapStringProtoRows',
    as HashRef[ProtoRows()];

1;

__END__

=head1 NAME

Google::Cloud::Bigquery::Storage::V1::Protobuf::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
