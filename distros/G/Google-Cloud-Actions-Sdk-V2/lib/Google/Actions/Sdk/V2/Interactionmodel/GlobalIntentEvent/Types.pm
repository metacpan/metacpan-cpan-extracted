package Google::Actions::Sdk::V2::Interactionmodel::GlobalIntentEvent::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'GlobalIntentEvent',
    as InstanceOf['Google::Actions::Sdk::V2::Interactionmodel::GlobalIntentEvent::GlobalIntentEvent'];

coerce 'GlobalIntentEvent',
    from HashRef, via { 'Google::Actions::Sdk::V2::Interactionmodel::GlobalIntentEvent::GlobalIntentEvent'->new($_) };

declare 'RepeatedGlobalIntentEvent',
    as ArrayRef[GlobalIntentEvent()];

coerce 'RepeatedGlobalIntentEvent',
    from ArrayRef[HashRef], via { [ map { 'Google::Actions::Sdk::V2::Interactionmodel::GlobalIntentEvent::GlobalIntentEvent'->new($_) } @$_ ] };

declare 'MapStringGlobalIntentEvent',
    as HashRef[GlobalIntentEvent()];

1;

__END__

=head1 NAME

Google::Actions::Sdk::V2::Interactionmodel::GlobalIntentEvent::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
