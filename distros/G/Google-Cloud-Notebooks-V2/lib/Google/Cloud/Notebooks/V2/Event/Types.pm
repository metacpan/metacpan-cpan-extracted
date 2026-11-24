package Google::Cloud::Notebooks::V2::Event::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Event',
    as InstanceOf['Google::Cloud::Notebooks::V2::Event::Event'];

coerce 'Event',
    from HashRef, via { 'Google::Cloud::Notebooks::V2::Event::Event'->new($_) };

declare 'RepeatedEvent',
    as ArrayRef[Event()];

coerce 'RepeatedEvent',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Notebooks::V2::Event::Event'->new($_) } @$_ ] };

declare 'MapStringEvent',
    as HashRef[Event()];

declare 'EventType',
    as (Int | Str);

declare 'DetailsEntry',
    as InstanceOf['Google::Cloud::Notebooks::V2::Event::Event::DetailsEntry'];

coerce 'DetailsEntry',
    from HashRef, via { 'Google::Cloud::Notebooks::V2::Event::Event::DetailsEntry'->new($_) };

declare 'RepeatedDetailsEntry',
    as ArrayRef[DetailsEntry()];

coerce 'RepeatedDetailsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Notebooks::V2::Event::Event::DetailsEntry'->new($_) } @$_ ] };

declare 'MapStringDetailsEntry',
    as HashRef[DetailsEntry()];

1;

__END__

=head1 NAME

Google::Cloud::Notebooks::V2::Event::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
