package Google::Actions::Sdk::V2::Interactionmodel::EntitySet::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'EntitySet',
    as InstanceOf['Google::Actions::Sdk::V2::Interactionmodel::EntitySet::EntitySet'];

coerce 'EntitySet',
    from HashRef, via { 'Google::Actions::Sdk::V2::Interactionmodel::EntitySet::EntitySet'->new($_) };

declare 'RepeatedEntitySet',
    as ArrayRef[EntitySet()];

coerce 'RepeatedEntitySet',
    from ArrayRef[HashRef], via { [ map { 'Google::Actions::Sdk::V2::Interactionmodel::EntitySet::EntitySet'->new($_) } @$_ ] };

declare 'MapStringEntitySet',
    as HashRef[EntitySet()];

declare 'Entity',
    as InstanceOf['Google::Actions::Sdk::V2::Interactionmodel::EntitySet::EntitySet::Entity'];

coerce 'Entity',
    from HashRef, via { 'Google::Actions::Sdk::V2::Interactionmodel::EntitySet::EntitySet::Entity'->new($_) };

declare 'RepeatedEntity',
    as ArrayRef[Entity()];

coerce 'RepeatedEntity',
    from ArrayRef[HashRef], via { [ map { 'Google::Actions::Sdk::V2::Interactionmodel::EntitySet::EntitySet::Entity'->new($_) } @$_ ] };

declare 'MapStringEntity',
    as HashRef[Entity()];

1;

__END__

=head1 NAME

Google::Actions::Sdk::V2::Interactionmodel::EntitySet::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
