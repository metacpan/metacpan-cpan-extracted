package Google::Cloud::Run::V2::TrafficTarget::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'TrafficTargetAllocationType',
    as (Int | Str);

declare 'TrafficTarget',
    as InstanceOf['Google::Cloud::Run::V2::TrafficTarget::TrafficTarget'];

coerce 'TrafficTarget',
    from HashRef, via { 'Google::Cloud::Run::V2::TrafficTarget::TrafficTarget'->new($_) };

declare 'RepeatedTrafficTarget',
    as ArrayRef[TrafficTarget()];

coerce 'RepeatedTrafficTarget',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Run::V2::TrafficTarget::TrafficTarget'->new($_) } @$_ ] };

declare 'MapStringTrafficTarget',
    as HashRef[TrafficTarget()];

declare 'TrafficTargetStatus',
    as InstanceOf['Google::Cloud::Run::V2::TrafficTarget::TrafficTargetStatus'];

coerce 'TrafficTargetStatus',
    from HashRef, via { 'Google::Cloud::Run::V2::TrafficTarget::TrafficTargetStatus'->new($_) };

declare 'RepeatedTrafficTargetStatus',
    as ArrayRef[TrafficTargetStatus()];

coerce 'RepeatedTrafficTargetStatus',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Run::V2::TrafficTarget::TrafficTargetStatus'->new($_) } @$_ ] };

declare 'MapStringTrafficTargetStatus',
    as HashRef[TrafficTargetStatus()];

1;

__END__

=head1 NAME

Google::Cloud::Run::V2::TrafficTarget::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
