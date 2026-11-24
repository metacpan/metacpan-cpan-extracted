package Google::Datastore::V1beta3::Entity::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'PartitionId',
    as InstanceOf['Google::Datastore::V1beta3::Entity::PartitionId'];

coerce 'PartitionId',
    from HashRef, via { 'Google::Datastore::V1beta3::Entity::PartitionId'->new($_) };

declare 'RepeatedPartitionId',
    as ArrayRef[PartitionId()];

coerce 'RepeatedPartitionId',
    from ArrayRef[HashRef], via { [ map { 'Google::Datastore::V1beta3::Entity::PartitionId'->new($_) } @$_ ] };

declare 'MapStringPartitionId',
    as HashRef[PartitionId()];

declare 'Key',
    as InstanceOf['Google::Datastore::V1beta3::Entity::Key'];

coerce 'Key',
    from HashRef, via { 'Google::Datastore::V1beta3::Entity::Key'->new($_) };

declare 'RepeatedKey',
    as ArrayRef[Key()];

coerce 'RepeatedKey',
    from ArrayRef[HashRef], via { [ map { 'Google::Datastore::V1beta3::Entity::Key'->new($_) } @$_ ] };

declare 'MapStringKey',
    as HashRef[Key()];

declare 'PathElement',
    as InstanceOf['Google::Datastore::V1beta3::Entity::Key::PathElement'];

coerce 'PathElement',
    from HashRef, via { 'Google::Datastore::V1beta3::Entity::Key::PathElement'->new($_) };

declare 'RepeatedPathElement',
    as ArrayRef[PathElement()];

coerce 'RepeatedPathElement',
    from ArrayRef[HashRef], via { [ map { 'Google::Datastore::V1beta3::Entity::Key::PathElement'->new($_) } @$_ ] };

declare 'MapStringPathElement',
    as HashRef[PathElement()];

declare 'ArrayValue',
    as InstanceOf['Google::Datastore::V1beta3::Entity::ArrayValue'];

coerce 'ArrayValue',
    from HashRef, via { 'Google::Datastore::V1beta3::Entity::ArrayValue'->new($_) };

declare 'RepeatedArrayValue',
    as ArrayRef[ArrayValue()];

coerce 'RepeatedArrayValue',
    from ArrayRef[HashRef], via { [ map { 'Google::Datastore::V1beta3::Entity::ArrayValue'->new($_) } @$_ ] };

declare 'MapStringArrayValue',
    as HashRef[ArrayValue()];

declare 'Value',
    as InstanceOf['Google::Datastore::V1beta3::Entity::Value'];

coerce 'Value',
    from HashRef, via { 'Google::Datastore::V1beta3::Entity::Value'->new($_) };

declare 'RepeatedValue',
    as ArrayRef[Value()];

coerce 'RepeatedValue',
    from ArrayRef[HashRef], via { [ map { 'Google::Datastore::V1beta3::Entity::Value'->new($_) } @$_ ] };

declare 'MapStringValue',
    as HashRef[Value()];

declare 'Entity',
    as InstanceOf['Google::Datastore::V1beta3::Entity::Entity'];

coerce 'Entity',
    from HashRef, via { 'Google::Datastore::V1beta3::Entity::Entity'->new($_) };

declare 'RepeatedEntity',
    as ArrayRef[Entity()];

coerce 'RepeatedEntity',
    from ArrayRef[HashRef], via { [ map { 'Google::Datastore::V1beta3::Entity::Entity'->new($_) } @$_ ] };

declare 'MapStringEntity',
    as HashRef[Entity()];

declare 'PropertiesEntry',
    as InstanceOf['Google::Datastore::V1beta3::Entity::Entity::PropertiesEntry'];

coerce 'PropertiesEntry',
    from HashRef, via { 'Google::Datastore::V1beta3::Entity::Entity::PropertiesEntry'->new($_) };

declare 'RepeatedPropertiesEntry',
    as ArrayRef[PropertiesEntry()];

coerce 'RepeatedPropertiesEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Datastore::V1beta3::Entity::Entity::PropertiesEntry'->new($_) } @$_ ] };

declare 'MapStringPropertiesEntry',
    as HashRef[PropertiesEntry()];

1;

__END__

=head1 NAME

Google::Datastore::V1beta3::Entity::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
