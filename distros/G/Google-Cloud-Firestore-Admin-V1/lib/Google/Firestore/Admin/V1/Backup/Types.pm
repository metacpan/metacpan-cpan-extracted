package Google::Firestore::Admin::V1::Backup::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Backup',
    as InstanceOf['Google::Firestore::Admin::V1::Backup::Backup'];

coerce 'Backup',
    from HashRef, via { 'Google::Firestore::Admin::V1::Backup::Backup'->new($_) };

declare 'RepeatedBackup',
    as ArrayRef[Backup()];

coerce 'RepeatedBackup',
    from ArrayRef[HashRef], via { [ map { 'Google::Firestore::Admin::V1::Backup::Backup'->new($_) } @$_ ] };

declare 'MapStringBackup',
    as HashRef[Backup()];

declare 'State',
    as (Int | Str);

declare 'Stats',
    as InstanceOf['Google::Firestore::Admin::V1::Backup::Backup::Stats'];

coerce 'Stats',
    from HashRef, via { 'Google::Firestore::Admin::V1::Backup::Backup::Stats'->new($_) };

declare 'RepeatedStats',
    as ArrayRef[Stats()];

coerce 'RepeatedStats',
    from ArrayRef[HashRef], via { [ map { 'Google::Firestore::Admin::V1::Backup::Backup::Stats'->new($_) } @$_ ] };

declare 'MapStringStats',
    as HashRef[Stats()];

1;

__END__

=head1 NAME

Google::Firestore::Admin::V1::Backup::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
