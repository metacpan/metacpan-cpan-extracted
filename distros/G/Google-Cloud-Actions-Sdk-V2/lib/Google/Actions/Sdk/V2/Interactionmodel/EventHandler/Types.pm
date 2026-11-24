package Google::Actions::Sdk::V2::Interactionmodel::EventHandler::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'EventHandler',
    as InstanceOf['Google::Actions::Sdk::V2::Interactionmodel::EventHandler::EventHandler'];

coerce 'EventHandler',
    from HashRef, via { 'Google::Actions::Sdk::V2::Interactionmodel::EventHandler::EventHandler'->new($_) };

declare 'RepeatedEventHandler',
    as ArrayRef[EventHandler()];

coerce 'RepeatedEventHandler',
    from ArrayRef[HashRef], via { [ map { 'Google::Actions::Sdk::V2::Interactionmodel::EventHandler::EventHandler'->new($_) } @$_ ] };

declare 'MapStringEventHandler',
    as HashRef[EventHandler()];

1;

__END__

=head1 NAME

Google::Actions::Sdk::V2::Interactionmodel::EventHandler::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
