package Google::Cloud::Functions::V1::Operations::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'OperationType',
    as (Int | Str);

declare 'OperationMetadataV1',
    as InstanceOf['Google::Cloud::Functions::V1::Operations::OperationMetadataV1'];

coerce 'OperationMetadataV1',
    from HashRef, via { 'Google::Cloud::Functions::V1::Operations::OperationMetadataV1'->new($_) };

declare 'RepeatedOperationMetadataV1',
    as ArrayRef[OperationMetadataV1()];

coerce 'RepeatedOperationMetadataV1',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Functions::V1::Operations::OperationMetadataV1'->new($_) } @$_ ] };

declare 'MapStringOperationMetadataV1',
    as HashRef[OperationMetadataV1()];

1;

__END__

=head1 NAME

Google::Cloud::Functions::V1::Operations::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
