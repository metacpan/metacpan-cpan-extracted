package Google::Firestore::V1beta1::Query::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'StructuredQuery',
    as InstanceOf['Google::Firestore::V1beta1::Query::StructuredQuery'];

coerce 'StructuredQuery',
    from HashRef, via { 'Google::Firestore::V1beta1::Query::StructuredQuery'->new($_) };

declare 'RepeatedStructuredQuery',
    as ArrayRef[StructuredQuery()];

coerce 'RepeatedStructuredQuery',
    from ArrayRef[HashRef], via { [ map { 'Google::Firestore::V1beta1::Query::StructuredQuery'->new($_) } @$_ ] };

declare 'MapStringStructuredQuery',
    as HashRef[StructuredQuery()];

declare 'Direction',
    as (Int | Str);

declare 'CollectionSelector',
    as InstanceOf['Google::Firestore::V1beta1::Query::StructuredQuery::CollectionSelector'];

coerce 'CollectionSelector',
    from HashRef, via { 'Google::Firestore::V1beta1::Query::StructuredQuery::CollectionSelector'->new($_) };

declare 'RepeatedCollectionSelector',
    as ArrayRef[CollectionSelector()];

coerce 'RepeatedCollectionSelector',
    from ArrayRef[HashRef], via { [ map { 'Google::Firestore::V1beta1::Query::StructuredQuery::CollectionSelector'->new($_) } @$_ ] };

declare 'MapStringCollectionSelector',
    as HashRef[CollectionSelector()];

declare 'Filter',
    as InstanceOf['Google::Firestore::V1beta1::Query::StructuredQuery::Filter'];

coerce 'Filter',
    from HashRef, via { 'Google::Firestore::V1beta1::Query::StructuredQuery::Filter'->new($_) };

declare 'RepeatedFilter',
    as ArrayRef[Filter()];

coerce 'RepeatedFilter',
    from ArrayRef[HashRef], via { [ map { 'Google::Firestore::V1beta1::Query::StructuredQuery::Filter'->new($_) } @$_ ] };

declare 'MapStringFilter',
    as HashRef[Filter()];

declare 'CompositeFilter',
    as InstanceOf['Google::Firestore::V1beta1::Query::StructuredQuery::CompositeFilter'];

coerce 'CompositeFilter',
    from HashRef, via { 'Google::Firestore::V1beta1::Query::StructuredQuery::CompositeFilter'->new($_) };

declare 'RepeatedCompositeFilter',
    as ArrayRef[CompositeFilter()];

coerce 'RepeatedCompositeFilter',
    from ArrayRef[HashRef], via { [ map { 'Google::Firestore::V1beta1::Query::StructuredQuery::CompositeFilter'->new($_) } @$_ ] };

declare 'MapStringCompositeFilter',
    as HashRef[CompositeFilter()];

declare 'Operator',
    as (Int | Str);

declare 'FieldFilter',
    as InstanceOf['Google::Firestore::V1beta1::Query::StructuredQuery::FieldFilter'];

coerce 'FieldFilter',
    from HashRef, via { 'Google::Firestore::V1beta1::Query::StructuredQuery::FieldFilter'->new($_) };

declare 'RepeatedFieldFilter',
    as ArrayRef[FieldFilter()];

coerce 'RepeatedFieldFilter',
    from ArrayRef[HashRef], via { [ map { 'Google::Firestore::V1beta1::Query::StructuredQuery::FieldFilter'->new($_) } @$_ ] };

declare 'MapStringFieldFilter',
    as HashRef[FieldFilter()];

declare 'Operator',
    as (Int | Str);

declare 'UnaryFilter',
    as InstanceOf['Google::Firestore::V1beta1::Query::StructuredQuery::UnaryFilter'];

coerce 'UnaryFilter',
    from HashRef, via { 'Google::Firestore::V1beta1::Query::StructuredQuery::UnaryFilter'->new($_) };

declare 'RepeatedUnaryFilter',
    as ArrayRef[UnaryFilter()];

coerce 'RepeatedUnaryFilter',
    from ArrayRef[HashRef], via { [ map { 'Google::Firestore::V1beta1::Query::StructuredQuery::UnaryFilter'->new($_) } @$_ ] };

declare 'MapStringUnaryFilter',
    as HashRef[UnaryFilter()];

declare 'Operator',
    as (Int | Str);

declare 'FieldReference',
    as InstanceOf['Google::Firestore::V1beta1::Query::StructuredQuery::FieldReference'];

coerce 'FieldReference',
    from HashRef, via { 'Google::Firestore::V1beta1::Query::StructuredQuery::FieldReference'->new($_) };

declare 'RepeatedFieldReference',
    as ArrayRef[FieldReference()];

coerce 'RepeatedFieldReference',
    from ArrayRef[HashRef], via { [ map { 'Google::Firestore::V1beta1::Query::StructuredQuery::FieldReference'->new($_) } @$_ ] };

declare 'MapStringFieldReference',
    as HashRef[FieldReference()];

declare 'Order',
    as InstanceOf['Google::Firestore::V1beta1::Query::StructuredQuery::Order'];

coerce 'Order',
    from HashRef, via { 'Google::Firestore::V1beta1::Query::StructuredQuery::Order'->new($_) };

declare 'RepeatedOrder',
    as ArrayRef[Order()];

coerce 'RepeatedOrder',
    from ArrayRef[HashRef], via { [ map { 'Google::Firestore::V1beta1::Query::StructuredQuery::Order'->new($_) } @$_ ] };

declare 'MapStringOrder',
    as HashRef[Order()];

declare 'Projection',
    as InstanceOf['Google::Firestore::V1beta1::Query::StructuredQuery::Projection'];

coerce 'Projection',
    from HashRef, via { 'Google::Firestore::V1beta1::Query::StructuredQuery::Projection'->new($_) };

declare 'RepeatedProjection',
    as ArrayRef[Projection()];

coerce 'RepeatedProjection',
    from ArrayRef[HashRef], via { [ map { 'Google::Firestore::V1beta1::Query::StructuredQuery::Projection'->new($_) } @$_ ] };

declare 'MapStringProjection',
    as HashRef[Projection()];

declare 'Cursor',
    as InstanceOf['Google::Firestore::V1beta1::Query::Cursor'];

coerce 'Cursor',
    from HashRef, via { 'Google::Firestore::V1beta1::Query::Cursor'->new($_) };

declare 'RepeatedCursor',
    as ArrayRef[Cursor()];

coerce 'RepeatedCursor',
    from ArrayRef[HashRef], via { [ map { 'Google::Firestore::V1beta1::Query::Cursor'->new($_) } @$_ ] };

declare 'MapStringCursor',
    as HashRef[Cursor()];

1;

__END__

=head1 NAME

Google::Firestore::V1beta1::Query::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
