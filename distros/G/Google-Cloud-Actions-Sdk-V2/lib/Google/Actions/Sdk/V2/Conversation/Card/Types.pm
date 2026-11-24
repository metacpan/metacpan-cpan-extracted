package Google::Actions::Sdk::V2::Conversation::Card::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Card',
    as InstanceOf['Google::Actions::Sdk::V2::Conversation::Card::Card'];

coerce 'Card',
    from HashRef, via { 'Google::Actions::Sdk::V2::Conversation::Card::Card'->new($_) };

declare 'RepeatedCard',
    as ArrayRef[Card()];

coerce 'RepeatedCard',
    from ArrayRef[HashRef], via { [ map { 'Google::Actions::Sdk::V2::Conversation::Card::Card'->new($_) } @$_ ] };

declare 'MapStringCard',
    as HashRef[Card()];

1;

__END__

=head1 NAME

Google::Actions::Sdk::V2::Conversation::Card::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
