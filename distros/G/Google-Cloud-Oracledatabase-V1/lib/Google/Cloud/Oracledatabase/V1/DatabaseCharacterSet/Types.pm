package Google::Cloud::Oracledatabase::V1::DatabaseCharacterSet::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'DatabaseCharacterSet',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::DatabaseCharacterSet::DatabaseCharacterSet'];

coerce 'DatabaseCharacterSet',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::DatabaseCharacterSet::DatabaseCharacterSet'->new($_) };

declare 'RepeatedDatabaseCharacterSet',
    as ArrayRef[DatabaseCharacterSet()];

coerce 'RepeatedDatabaseCharacterSet',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::DatabaseCharacterSet::DatabaseCharacterSet'->new($_) } @$_ ] };

declare 'MapStringDatabaseCharacterSet',
    as HashRef[DatabaseCharacterSet()];

declare 'CharacterSetType',
    as (Int | Str);

declare 'ListDatabaseCharacterSetsRequest',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::DatabaseCharacterSet::ListDatabaseCharacterSetsRequest'];

coerce 'ListDatabaseCharacterSetsRequest',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::DatabaseCharacterSet::ListDatabaseCharacterSetsRequest'->new($_) };

declare 'RepeatedListDatabaseCharacterSetsRequest',
    as ArrayRef[ListDatabaseCharacterSetsRequest()];

coerce 'RepeatedListDatabaseCharacterSetsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::DatabaseCharacterSet::ListDatabaseCharacterSetsRequest'->new($_) } @$_ ] };

declare 'MapStringListDatabaseCharacterSetsRequest',
    as HashRef[ListDatabaseCharacterSetsRequest()];

declare 'ListDatabaseCharacterSetsResponse',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::DatabaseCharacterSet::ListDatabaseCharacterSetsResponse'];

coerce 'ListDatabaseCharacterSetsResponse',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::DatabaseCharacterSet::ListDatabaseCharacterSetsResponse'->new($_) };

declare 'RepeatedListDatabaseCharacterSetsResponse',
    as ArrayRef[ListDatabaseCharacterSetsResponse()];

coerce 'RepeatedListDatabaseCharacterSetsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::DatabaseCharacterSet::ListDatabaseCharacterSetsResponse'->new($_) } @$_ ] };

declare 'MapStringListDatabaseCharacterSetsResponse',
    as HashRef[ListDatabaseCharacterSetsResponse()];

1;

__END__

=head1 NAME

Google::Cloud::Oracledatabase::V1::DatabaseCharacterSet::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
