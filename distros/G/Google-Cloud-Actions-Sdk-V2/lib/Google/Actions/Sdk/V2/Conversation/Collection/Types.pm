package Google::Actions::Sdk::V2::Conversation::Collection::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Collection',
    as InstanceOf['Google::Actions::Sdk::V2::Conversation::Collection::Collection'];

coerce 'Collection',
    from HashRef, via { 'Google::Actions::Sdk::V2::Conversation::Collection::Collection'->new($_) };

declare 'RepeatedCollection',
    as ArrayRef[Collection()];

coerce 'RepeatedCollection',
    from ArrayRef[HashRef], via { [ map { 'Google::Actions::Sdk::V2::Conversation::Collection::Collection'->new($_) } @$_ ] };

declare 'MapStringCollection',
    as HashRef[Collection()];

declare 'CollectionItem',
    as InstanceOf['Google::Actions::Sdk::V2::Conversation::Collection::Collection::CollectionItem'];

coerce 'CollectionItem',
    from HashRef, via { 'Google::Actions::Sdk::V2::Conversation::Collection::Collection::CollectionItem'->new($_) };

declare 'RepeatedCollectionItem',
    as ArrayRef[CollectionItem()];

coerce 'RepeatedCollectionItem',
    from ArrayRef[HashRef], via { [ map { 'Google::Actions::Sdk::V2::Conversation::Collection::Collection::CollectionItem'->new($_) } @$_ ] };

declare 'MapStringCollectionItem',
    as HashRef[CollectionItem()];

1;

__END__

=head1 NAME

Google::Actions::Sdk::V2::Conversation::Collection::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
