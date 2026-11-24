package Google::Cloud::Deploy::V1::ReleaseRenderPayload::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'ReleaseRenderEvent',
    as InstanceOf['Google::Cloud::Deploy::V1::ReleaseRenderPayload::ReleaseRenderEvent'];

coerce 'ReleaseRenderEvent',
    from HashRef, via { 'Google::Cloud::Deploy::V1::ReleaseRenderPayload::ReleaseRenderEvent'->new($_) };

declare 'RepeatedReleaseRenderEvent',
    as ArrayRef[ReleaseRenderEvent()];

coerce 'RepeatedReleaseRenderEvent',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Deploy::V1::ReleaseRenderPayload::ReleaseRenderEvent'->new($_) } @$_ ] };

declare 'MapStringReleaseRenderEvent',
    as HashRef[ReleaseRenderEvent()];

1;

__END__

=head1 NAME

Google::Cloud::Deploy::V1::ReleaseRenderPayload::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
