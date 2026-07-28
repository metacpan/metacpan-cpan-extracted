package Google::Cloud::Networksecurity::V1::Common::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'OperationMetadata',
    as InstanceOf['Google::Cloud::Networksecurity::V1::Common::OperationMetadata'];

coerce 'OperationMetadata',
    from HashRef, via { 'Google::Cloud::Networksecurity::V1::Common::OperationMetadata'->new($_) };

declare 'RepeatedOperationMetadata',
    as ArrayRef[OperationMetadata()];

coerce 'RepeatedOperationMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networksecurity::V1::Common::OperationMetadata'->new($_) } @$_ ] };

declare 'MapStringOperationMetadata',
    as HashRef[OperationMetadata()];

1;

__END__

=head1 NAME

Google::Cloud::Networksecurity::V1::Common::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
