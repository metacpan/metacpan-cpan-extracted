package Google::Spanner::Admin::Instance::V1::Common::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'FulfillmentPeriod',
    as (Int | Str);

declare 'OperationProgress',
    as InstanceOf['Google::Spanner::Admin::Instance::V1::Common::OperationProgress'];

coerce 'OperationProgress',
    from HashRef, via { 'Google::Spanner::Admin::Instance::V1::Common::OperationProgress'->new($_) };

declare 'RepeatedOperationProgress',
    as ArrayRef[OperationProgress()];

coerce 'RepeatedOperationProgress',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Admin::Instance::V1::Common::OperationProgress'->new($_) } @$_ ] };

declare 'MapStringOperationProgress',
    as HashRef[OperationProgress()];

declare 'ReplicaSelection',
    as InstanceOf['Google::Spanner::Admin::Instance::V1::Common::ReplicaSelection'];

coerce 'ReplicaSelection',
    from HashRef, via { 'Google::Spanner::Admin::Instance::V1::Common::ReplicaSelection'->new($_) };

declare 'RepeatedReplicaSelection',
    as ArrayRef[ReplicaSelection()];

coerce 'RepeatedReplicaSelection',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Admin::Instance::V1::Common::ReplicaSelection'->new($_) } @$_ ] };

declare 'MapStringReplicaSelection',
    as HashRef[ReplicaSelection()];

1;

__END__

=head1 NAME

Google::Spanner::Admin::Instance::V1::Common::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
