package Google::Actions::Sdk::V2::Interactionmodel::Type::RegularExpressionType::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'RegularExpressionType',
    as InstanceOf['Google::Actions::Sdk::V2::Interactionmodel::Type::RegularExpressionType::RegularExpressionType'];

coerce 'RegularExpressionType',
    from HashRef, via { 'Google::Actions::Sdk::V2::Interactionmodel::Type::RegularExpressionType::RegularExpressionType'->new($_) };

declare 'RepeatedRegularExpressionType',
    as ArrayRef[RegularExpressionType()];

coerce 'RepeatedRegularExpressionType',
    from ArrayRef[HashRef], via { [ map { 'Google::Actions::Sdk::V2::Interactionmodel::Type::RegularExpressionType::RegularExpressionType'->new($_) } @$_ ] };

declare 'MapStringRegularExpressionType',
    as HashRef[RegularExpressionType()];

declare 'Entity',
    as InstanceOf['Google::Actions::Sdk::V2::Interactionmodel::Type::RegularExpressionType::RegularExpressionType::Entity'];

coerce 'Entity',
    from HashRef, via { 'Google::Actions::Sdk::V2::Interactionmodel::Type::RegularExpressionType::RegularExpressionType::Entity'->new($_) };

declare 'RepeatedEntity',
    as ArrayRef[Entity()];

coerce 'RepeatedEntity',
    from ArrayRef[HashRef], via { [ map { 'Google::Actions::Sdk::V2::Interactionmodel::Type::RegularExpressionType::RegularExpressionType::Entity'->new($_) } @$_ ] };

declare 'MapStringEntity',
    as HashRef[Entity()];

declare 'EntitiesEntry',
    as InstanceOf['Google::Actions::Sdk::V2::Interactionmodel::Type::RegularExpressionType::RegularExpressionType::EntitiesEntry'];

coerce 'EntitiesEntry',
    from HashRef, via { 'Google::Actions::Sdk::V2::Interactionmodel::Type::RegularExpressionType::RegularExpressionType::EntitiesEntry'->new($_) };

declare 'RepeatedEntitiesEntry',
    as ArrayRef[EntitiesEntry()];

coerce 'RepeatedEntitiesEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Actions::Sdk::V2::Interactionmodel::Type::RegularExpressionType::RegularExpressionType::EntitiesEntry'->new($_) } @$_ ] };

declare 'MapStringEntitiesEntry',
    as HashRef[EntitiesEntry()];

1;

__END__

=head1 NAME

Google::Actions::Sdk::V2::Interactionmodel::Type::RegularExpressionType::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
