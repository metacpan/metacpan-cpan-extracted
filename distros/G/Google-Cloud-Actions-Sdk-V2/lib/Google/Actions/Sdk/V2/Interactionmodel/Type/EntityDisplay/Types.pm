package Google::Actions::Sdk::V2::Interactionmodel::Type::EntityDisplay::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'EntityDisplay',
    as InstanceOf['Google::Actions::Sdk::V2::Interactionmodel::Type::EntityDisplay::EntityDisplay'];

coerce 'EntityDisplay',
    from HashRef, via { 'Google::Actions::Sdk::V2::Interactionmodel::Type::EntityDisplay::EntityDisplay'->new($_) };

declare 'RepeatedEntityDisplay',
    as ArrayRef[EntityDisplay()];

coerce 'RepeatedEntityDisplay',
    from ArrayRef[HashRef], via { [ map { 'Google::Actions::Sdk::V2::Interactionmodel::Type::EntityDisplay::EntityDisplay'->new($_) } @$_ ] };

declare 'MapStringEntityDisplay',
    as HashRef[EntityDisplay()];

1;

__END__

=head1 NAME

Google::Actions::Sdk::V2::Interactionmodel::Type::EntityDisplay::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
