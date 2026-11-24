package Google::Cloud::Chronicle::V1::Event::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Event',
    as InstanceOf['Google::Cloud::Chronicle::V1::Event::Event'];

coerce 'Event',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::Event::Event'->new($_) };

declare 'RepeatedEvent',
    as ArrayRef[Event()];

coerce 'RepeatedEvent',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::Event::Event'->new($_) } @$_ ] };

declare 'MapStringEvent',
    as HashRef[Event()];

1;

__END__

=head1 NAME

Google::Cloud::Chronicle::V1::Event::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
