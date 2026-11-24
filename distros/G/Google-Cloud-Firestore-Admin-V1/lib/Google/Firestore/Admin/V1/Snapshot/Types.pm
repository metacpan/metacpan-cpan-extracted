package Google::Firestore::Admin::V1::Snapshot::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'PitrSnapshot',
    as InstanceOf['Google::Firestore::Admin::V1::Snapshot::PitrSnapshot'];

coerce 'PitrSnapshot',
    from HashRef, via { 'Google::Firestore::Admin::V1::Snapshot::PitrSnapshot'->new($_) };

declare 'RepeatedPitrSnapshot',
    as ArrayRef[PitrSnapshot()];

coerce 'RepeatedPitrSnapshot',
    from ArrayRef[HashRef], via { [ map { 'Google::Firestore::Admin::V1::Snapshot::PitrSnapshot'->new($_) } @$_ ] };

declare 'MapStringPitrSnapshot',
    as HashRef[PitrSnapshot()];

1;

__END__

=head1 NAME

Google::Firestore::Admin::V1::Snapshot::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
