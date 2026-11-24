package Google::Datastore::Admin::V1::Index::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Index',
    as InstanceOf['Google::Datastore::Admin::V1::Index::Index'];

coerce 'Index',
    from HashRef, via { 'Google::Datastore::Admin::V1::Index::Index'->new($_) };

declare 'RepeatedIndex',
    as ArrayRef[Index()];

coerce 'RepeatedIndex',
    from ArrayRef[HashRef], via { [ map { 'Google::Datastore::Admin::V1::Index::Index'->new($_) } @$_ ] };

declare 'MapStringIndex',
    as HashRef[Index()];

declare 'AncestorMode',
    as (Int | Str);

declare 'Direction',
    as (Int | Str);

declare 'State',
    as (Int | Str);

declare 'IndexedProperty',
    as InstanceOf['Google::Datastore::Admin::V1::Index::Index::IndexedProperty'];

coerce 'IndexedProperty',
    from HashRef, via { 'Google::Datastore::Admin::V1::Index::Index::IndexedProperty'->new($_) };

declare 'RepeatedIndexedProperty',
    as ArrayRef[IndexedProperty()];

coerce 'RepeatedIndexedProperty',
    from ArrayRef[HashRef], via { [ map { 'Google::Datastore::Admin::V1::Index::Index::IndexedProperty'->new($_) } @$_ ] };

declare 'MapStringIndexedProperty',
    as HashRef[IndexedProperty()];

1;

__END__

=head1 NAME

Google::Datastore::Admin::V1::Index::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
