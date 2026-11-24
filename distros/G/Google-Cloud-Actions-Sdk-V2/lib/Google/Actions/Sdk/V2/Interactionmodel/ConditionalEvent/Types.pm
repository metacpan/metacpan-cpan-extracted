package Google::Actions::Sdk::V2::Interactionmodel::ConditionalEvent::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'ConditionalEvent',
    as InstanceOf['Google::Actions::Sdk::V2::Interactionmodel::ConditionalEvent::ConditionalEvent'];

coerce 'ConditionalEvent',
    from HashRef, via { 'Google::Actions::Sdk::V2::Interactionmodel::ConditionalEvent::ConditionalEvent'->new($_) };

declare 'RepeatedConditionalEvent',
    as ArrayRef[ConditionalEvent()];

coerce 'RepeatedConditionalEvent',
    from ArrayRef[HashRef], via { [ map { 'Google::Actions::Sdk::V2::Interactionmodel::ConditionalEvent::ConditionalEvent'->new($_) } @$_ ] };

declare 'MapStringConditionalEvent',
    as HashRef[ConditionalEvent()];

1;

__END__

=head1 NAME

Google::Actions::Sdk::V2::Interactionmodel::ConditionalEvent::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
