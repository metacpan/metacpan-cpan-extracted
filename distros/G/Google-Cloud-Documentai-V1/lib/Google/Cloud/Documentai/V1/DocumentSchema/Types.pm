package Google::Cloud::Documentai::V1::DocumentSchema::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'DocumentSchema',
    as InstanceOf['Google::Cloud::Documentai::V1::DocumentSchema::DocumentSchema'];

coerce 'DocumentSchema',
    from HashRef, via { 'Google::Cloud::Documentai::V1::DocumentSchema::DocumentSchema'->new($_) };

declare 'RepeatedDocumentSchema',
    as ArrayRef[DocumentSchema()];

coerce 'RepeatedDocumentSchema',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Documentai::V1::DocumentSchema::DocumentSchema'->new($_) } @$_ ] };

declare 'MapStringDocumentSchema',
    as HashRef[DocumentSchema()];

declare 'EntityType',
    as InstanceOf['Google::Cloud::Documentai::V1::DocumentSchema::DocumentSchema::EntityType'];

coerce 'EntityType',
    from HashRef, via { 'Google::Cloud::Documentai::V1::DocumentSchema::DocumentSchema::EntityType'->new($_) };

declare 'RepeatedEntityType',
    as ArrayRef[EntityType()];

coerce 'RepeatedEntityType',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Documentai::V1::DocumentSchema::DocumentSchema::EntityType'->new($_) } @$_ ] };

declare 'MapStringEntityType',
    as HashRef[EntityType()];

declare 'EnumValues',
    as InstanceOf['Google::Cloud::Documentai::V1::DocumentSchema::DocumentSchema::EntityType::EnumValues'];

coerce 'EnumValues',
    from HashRef, via { 'Google::Cloud::Documentai::V1::DocumentSchema::DocumentSchema::EntityType::EnumValues'->new($_) };

declare 'RepeatedEnumValues',
    as ArrayRef[EnumValues()];

coerce 'RepeatedEnumValues',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Documentai::V1::DocumentSchema::DocumentSchema::EntityType::EnumValues'->new($_) } @$_ ] };

declare 'MapStringEnumValues',
    as HashRef[EnumValues()];

declare 'Property',
    as InstanceOf['Google::Cloud::Documentai::V1::DocumentSchema::DocumentSchema::EntityType::Property'];

coerce 'Property',
    from HashRef, via { 'Google::Cloud::Documentai::V1::DocumentSchema::DocumentSchema::EntityType::Property'->new($_) };

declare 'RepeatedProperty',
    as ArrayRef[Property()];

coerce 'RepeatedProperty',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Documentai::V1::DocumentSchema::DocumentSchema::EntityType::Property'->new($_) } @$_ ] };

declare 'MapStringProperty',
    as HashRef[Property()];

declare 'OccurrenceType',
    as (Int | Str);

declare 'Method',
    as (Int | Str);

declare 'Metadata',
    as InstanceOf['Google::Cloud::Documentai::V1::DocumentSchema::DocumentSchema::Metadata'];

coerce 'Metadata',
    from HashRef, via { 'Google::Cloud::Documentai::V1::DocumentSchema::DocumentSchema::Metadata'->new($_) };

declare 'RepeatedMetadata',
    as ArrayRef[Metadata()];

coerce 'RepeatedMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Documentai::V1::DocumentSchema::DocumentSchema::Metadata'->new($_) } @$_ ] };

declare 'MapStringMetadata',
    as HashRef[Metadata()];

1;

__END__

=head1 NAME

Google::Cloud::Documentai::V1::DocumentSchema::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
