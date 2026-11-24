package Google::Actions::Sdk::V2::Interactionmodel::Type::SynonymType::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'SynonymType',
    as InstanceOf['Google::Actions::Sdk::V2::Interactionmodel::Type::SynonymType::SynonymType'];

coerce 'SynonymType',
    from HashRef, via { 'Google::Actions::Sdk::V2::Interactionmodel::Type::SynonymType::SynonymType'->new($_) };

declare 'RepeatedSynonymType',
    as ArrayRef[SynonymType()];

coerce 'RepeatedSynonymType',
    from ArrayRef[HashRef], via { [ map { 'Google::Actions::Sdk::V2::Interactionmodel::Type::SynonymType::SynonymType'->new($_) } @$_ ] };

declare 'MapStringSynonymType',
    as HashRef[SynonymType()];

declare 'MatchType',
    as (Int | Str);

declare 'Entity',
    as InstanceOf['Google::Actions::Sdk::V2::Interactionmodel::Type::SynonymType::SynonymType::Entity'];

coerce 'Entity',
    from HashRef, via { 'Google::Actions::Sdk::V2::Interactionmodel::Type::SynonymType::SynonymType::Entity'->new($_) };

declare 'RepeatedEntity',
    as ArrayRef[Entity()];

coerce 'RepeatedEntity',
    from ArrayRef[HashRef], via { [ map { 'Google::Actions::Sdk::V2::Interactionmodel::Type::SynonymType::SynonymType::Entity'->new($_) } @$_ ] };

declare 'MapStringEntity',
    as HashRef[Entity()];

declare 'EntitiesEntry',
    as InstanceOf['Google::Actions::Sdk::V2::Interactionmodel::Type::SynonymType::SynonymType::EntitiesEntry'];

coerce 'EntitiesEntry',
    from HashRef, via { 'Google::Actions::Sdk::V2::Interactionmodel::Type::SynonymType::SynonymType::EntitiesEntry'->new($_) };

declare 'RepeatedEntitiesEntry',
    as ArrayRef[EntitiesEntry()];

coerce 'RepeatedEntitiesEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Actions::Sdk::V2::Interactionmodel::Type::SynonymType::SynonymType::EntitiesEntry'->new($_) } @$_ ] };

declare 'MapStringEntitiesEntry',
    as HashRef[EntitiesEntry()];

1;

__END__

=head1 NAME

Google::Actions::Sdk::V2::Interactionmodel::Type::SynonymType::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
