package Google::Bigtable::Admin::V2::Common::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'StorageType',
    as (Int | Str);

declare 'OperationProgress',
    as InstanceOf['Google::Bigtable::Admin::V2::Common::OperationProgress'];

coerce 'OperationProgress',
    from HashRef, via { 'Google::Bigtable::Admin::V2::Common::OperationProgress'->new($_) };

declare 'RepeatedOperationProgress',
    as ArrayRef[OperationProgress()];

coerce 'RepeatedOperationProgress',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::Admin::V2::Common::OperationProgress'->new($_) } @$_ ] };

declare 'MapStringOperationProgress',
    as HashRef[OperationProgress()];

1;

__END__

=head1 NAME

Google::Bigtable::Admin::V2::Common::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
