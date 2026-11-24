package Google::Firestore::V1beta1::UndeliverableFirstGenEvent::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'UndeliverableFirstGenEvent',
    as InstanceOf['Google::Firestore::V1beta1::UndeliverableFirstGenEvent::UndeliverableFirstGenEvent'];

coerce 'UndeliverableFirstGenEvent',
    from HashRef, via { 'Google::Firestore::V1beta1::UndeliverableFirstGenEvent::UndeliverableFirstGenEvent'->new($_) };

declare 'RepeatedUndeliverableFirstGenEvent',
    as ArrayRef[UndeliverableFirstGenEvent()];

coerce 'RepeatedUndeliverableFirstGenEvent',
    from ArrayRef[HashRef], via { [ map { 'Google::Firestore::V1beta1::UndeliverableFirstGenEvent::UndeliverableFirstGenEvent'->new($_) } @$_ ] };

declare 'MapStringUndeliverableFirstGenEvent',
    as HashRef[UndeliverableFirstGenEvent()];

declare 'Reason',
    as (Int | Str);

declare 'DocumentChangeType',
    as (Int | Str);

1;

__END__

=head1 NAME

Google::Firestore::V1beta1::UndeliverableFirstGenEvent::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
