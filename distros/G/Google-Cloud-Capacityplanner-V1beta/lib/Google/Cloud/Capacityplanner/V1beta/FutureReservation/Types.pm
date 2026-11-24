package Google::Cloud::Capacityplanner::V1beta::FutureReservation::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'FutureReservation',
    as InstanceOf['Google::Cloud::Capacityplanner::V1beta::FutureReservation::FutureReservation'];

coerce 'FutureReservation',
    from HashRef, via { 'Google::Cloud::Capacityplanner::V1beta::FutureReservation::FutureReservation'->new($_) };

declare 'RepeatedFutureReservation',
    as ArrayRef[FutureReservation()];

coerce 'RepeatedFutureReservation',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Capacityplanner::V1beta::FutureReservation::FutureReservation'->new($_) } @$_ ] };

declare 'MapStringFutureReservation',
    as HashRef[FutureReservation()];

declare 'SpecificSKUProperties',
    as InstanceOf['Google::Cloud::Capacityplanner::V1beta::FutureReservation::FutureReservation::SpecificSKUProperties'];

coerce 'SpecificSKUProperties',
    from HashRef, via { 'Google::Cloud::Capacityplanner::V1beta::FutureReservation::FutureReservation::SpecificSKUProperties'->new($_) };

declare 'RepeatedSpecificSKUProperties',
    as ArrayRef[SpecificSKUProperties()];

coerce 'RepeatedSpecificSKUProperties',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Capacityplanner::V1beta::FutureReservation::FutureReservation::SpecificSKUProperties'->new($_) } @$_ ] };

declare 'MapStringSpecificSKUProperties',
    as HashRef[SpecificSKUProperties()];

declare 'TimeWindow',
    as InstanceOf['Google::Cloud::Capacityplanner::V1beta::FutureReservation::FutureReservation::TimeWindow'];

coerce 'TimeWindow',
    from HashRef, via { 'Google::Cloud::Capacityplanner::V1beta::FutureReservation::FutureReservation::TimeWindow'->new($_) };

declare 'RepeatedTimeWindow',
    as ArrayRef[TimeWindow()];

coerce 'RepeatedTimeWindow',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Capacityplanner::V1beta::FutureReservation::FutureReservation::TimeWindow'->new($_) } @$_ ] };

declare 'MapStringTimeWindow',
    as HashRef[TimeWindow()];

declare 'Status',
    as InstanceOf['Google::Cloud::Capacityplanner::V1beta::FutureReservation::FutureReservation::Status'];

coerce 'Status',
    from HashRef, via { 'Google::Cloud::Capacityplanner::V1beta::FutureReservation::FutureReservation::Status'->new($_) };

declare 'RepeatedStatus',
    as ArrayRef[Status()];

coerce 'RepeatedStatus',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Capacityplanner::V1beta::FutureReservation::FutureReservation::Status'->new($_) } @$_ ] };

declare 'MapStringStatus',
    as HashRef[Status()];

declare 'ProcurementStatus',
    as (Int | Str);

1;

__END__

=head1 NAME

Google::Cloud::Capacityplanner::V1beta::FutureReservation::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
