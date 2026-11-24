package Google::Firestore::Admin::V1::Field::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Field',
    as InstanceOf['Google::Firestore::Admin::V1::Field::Field'];

coerce 'Field',
    from HashRef, via { 'Google::Firestore::Admin::V1::Field::Field'->new($_) };

declare 'RepeatedField',
    as ArrayRef[Field()];

coerce 'RepeatedField',
    from ArrayRef[HashRef], via { [ map { 'Google::Firestore::Admin::V1::Field::Field'->new($_) } @$_ ] };

declare 'MapStringField',
    as HashRef[Field()];

declare 'IndexConfig',
    as InstanceOf['Google::Firestore::Admin::V1::Field::Field::IndexConfig'];

coerce 'IndexConfig',
    from HashRef, via { 'Google::Firestore::Admin::V1::Field::Field::IndexConfig'->new($_) };

declare 'RepeatedIndexConfig',
    as ArrayRef[IndexConfig()];

coerce 'RepeatedIndexConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Firestore::Admin::V1::Field::Field::IndexConfig'->new($_) } @$_ ] };

declare 'MapStringIndexConfig',
    as HashRef[IndexConfig()];

declare 'TtlConfig',
    as InstanceOf['Google::Firestore::Admin::V1::Field::Field::TtlConfig'];

coerce 'TtlConfig',
    from HashRef, via { 'Google::Firestore::Admin::V1::Field::Field::TtlConfig'->new($_) };

declare 'RepeatedTtlConfig',
    as ArrayRef[TtlConfig()];

coerce 'RepeatedTtlConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Firestore::Admin::V1::Field::Field::TtlConfig'->new($_) } @$_ ] };

declare 'MapStringTtlConfig',
    as HashRef[TtlConfig()];

declare 'State',
    as (Int | Str);

1;

__END__

=head1 NAME

Google::Firestore::Admin::V1::Field::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
