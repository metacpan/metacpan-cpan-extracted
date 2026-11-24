package Google::Actions::Sdk::V2::Interactionmodel::IntentEvent::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'IntentEvent',
    as InstanceOf['Google::Actions::Sdk::V2::Interactionmodel::IntentEvent::IntentEvent'];

coerce 'IntentEvent',
    from HashRef, via { 'Google::Actions::Sdk::V2::Interactionmodel::IntentEvent::IntentEvent'->new($_) };

declare 'RepeatedIntentEvent',
    as ArrayRef[IntentEvent()];

coerce 'RepeatedIntentEvent',
    from ArrayRef[HashRef], via { [ map { 'Google::Actions::Sdk::V2::Interactionmodel::IntentEvent::IntentEvent'->new($_) } @$_ ] };

declare 'MapStringIntentEvent',
    as HashRef[IntentEvent()];

1;

__END__

=head1 NAME

Google::Actions::Sdk::V2::Interactionmodel::IntentEvent::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
