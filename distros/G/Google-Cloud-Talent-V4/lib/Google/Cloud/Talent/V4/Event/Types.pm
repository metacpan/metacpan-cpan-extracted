package Google::Cloud::Talent::V4::Event::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'ClientEvent',
    as InstanceOf['Google::Cloud::Talent::V4::Event::ClientEvent'];

coerce 'ClientEvent',
    from HashRef, via { 'Google::Cloud::Talent::V4::Event::ClientEvent'->new($_) };

declare 'RepeatedClientEvent',
    as ArrayRef[ClientEvent()];

coerce 'RepeatedClientEvent',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Talent::V4::Event::ClientEvent'->new($_) } @$_ ] };

declare 'MapStringClientEvent',
    as HashRef[ClientEvent()];

declare 'JobEvent',
    as InstanceOf['Google::Cloud::Talent::V4::Event::JobEvent'];

coerce 'JobEvent',
    from HashRef, via { 'Google::Cloud::Talent::V4::Event::JobEvent'->new($_) };

declare 'RepeatedJobEvent',
    as ArrayRef[JobEvent()];

coerce 'RepeatedJobEvent',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Talent::V4::Event::JobEvent'->new($_) } @$_ ] };

declare 'MapStringJobEvent',
    as HashRef[JobEvent()];

declare 'JobEventType',
    as (Int | Str);

1;

__END__

=head1 NAME

Google::Cloud::Talent::V4::Event::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
