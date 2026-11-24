package Google::Actions::Sdk::V2::Conversation::List::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'List',
    as InstanceOf['Google::Actions::Sdk::V2::Conversation::List::List'];

coerce 'List',
    from HashRef, via { 'Google::Actions::Sdk::V2::Conversation::List::List'->new($_) };

declare 'RepeatedList',
    as ArrayRef[List()];

coerce 'RepeatedList',
    from ArrayRef[HashRef], via { [ map { 'Google::Actions::Sdk::V2::Conversation::List::List'->new($_) } @$_ ] };

declare 'MapStringList',
    as HashRef[List()];

declare 'ListItem',
    as InstanceOf['Google::Actions::Sdk::V2::Conversation::List::List::ListItem'];

coerce 'ListItem',
    from HashRef, via { 'Google::Actions::Sdk::V2::Conversation::List::List::ListItem'->new($_) };

declare 'RepeatedListItem',
    as ArrayRef[ListItem()];

coerce 'RepeatedListItem',
    from ArrayRef[HashRef], via { [ map { 'Google::Actions::Sdk::V2::Conversation::List::List::ListItem'->new($_) } @$_ ] };

declare 'MapStringListItem',
    as HashRef[ListItem()];

1;

__END__

=head1 NAME

Google::Actions::Sdk::V2::Conversation::List::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
