package Google::Firestore::Admin::V1beta2::Index::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Index',
    as InstanceOf['Google::Firestore::Admin::V1beta2::Index::Index'];

coerce 'Index',
    from HashRef, via { 'Google::Firestore::Admin::V1beta2::Index::Index'->new($_) };

declare 'RepeatedIndex',
    as ArrayRef[Index()];

coerce 'RepeatedIndex',
    from ArrayRef[HashRef], via { [ map { 'Google::Firestore::Admin::V1beta2::Index::Index'->new($_) } @$_ ] };

declare 'MapStringIndex',
    as HashRef[Index()];

declare 'QueryScope',
    as (Int | Str);

declare 'State',
    as (Int | Str);

declare 'IndexField',
    as InstanceOf['Google::Firestore::Admin::V1beta2::Index::Index::IndexField'];

coerce 'IndexField',
    from HashRef, via { 'Google::Firestore::Admin::V1beta2::Index::Index::IndexField'->new($_) };

declare 'RepeatedIndexField',
    as ArrayRef[IndexField()];

coerce 'RepeatedIndexField',
    from ArrayRef[HashRef], via { [ map { 'Google::Firestore::Admin::V1beta2::Index::Index::IndexField'->new($_) } @$_ ] };

declare 'MapStringIndexField',
    as HashRef[IndexField()];

declare 'Order',
    as (Int | Str);

declare 'ArrayConfig',
    as (Int | Str);

1;

__END__

=head1 NAME

Google::Firestore::Admin::V1beta2::Index::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
