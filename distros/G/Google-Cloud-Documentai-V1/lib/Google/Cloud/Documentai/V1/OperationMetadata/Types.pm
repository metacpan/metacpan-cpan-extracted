package Google::Cloud::Documentai::V1::OperationMetadata::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'CommonOperationMetadata',
    as InstanceOf['Google::Cloud::Documentai::V1::OperationMetadata::CommonOperationMetadata'];

coerce 'CommonOperationMetadata',
    from HashRef, via { 'Google::Cloud::Documentai::V1::OperationMetadata::CommonOperationMetadata'->new($_) };

declare 'RepeatedCommonOperationMetadata',
    as ArrayRef[CommonOperationMetadata()];

coerce 'RepeatedCommonOperationMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Documentai::V1::OperationMetadata::CommonOperationMetadata'->new($_) } @$_ ] };

declare 'MapStringCommonOperationMetadata',
    as HashRef[CommonOperationMetadata()];

declare 'State',
    as (Int | Str);

1;

__END__

=head1 NAME

Google::Cloud::Documentai::V1::OperationMetadata::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
