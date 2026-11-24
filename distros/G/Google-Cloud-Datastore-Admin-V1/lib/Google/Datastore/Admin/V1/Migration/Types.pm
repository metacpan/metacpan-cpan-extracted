package Google::Datastore::Admin::V1::Migration::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'MigrationState',
    as (Int | Str);

declare 'MigrationStep',
    as (Int | Str);

declare 'MigrationStateEvent',
    as InstanceOf['Google::Datastore::Admin::V1::Migration::MigrationStateEvent'];

coerce 'MigrationStateEvent',
    from HashRef, via { 'Google::Datastore::Admin::V1::Migration::MigrationStateEvent'->new($_) };

declare 'RepeatedMigrationStateEvent',
    as ArrayRef[MigrationStateEvent()];

coerce 'RepeatedMigrationStateEvent',
    from ArrayRef[HashRef], via { [ map { 'Google::Datastore::Admin::V1::Migration::MigrationStateEvent'->new($_) } @$_ ] };

declare 'MapStringMigrationStateEvent',
    as HashRef[MigrationStateEvent()];

declare 'MigrationProgressEvent',
    as InstanceOf['Google::Datastore::Admin::V1::Migration::MigrationProgressEvent'];

coerce 'MigrationProgressEvent',
    from HashRef, via { 'Google::Datastore::Admin::V1::Migration::MigrationProgressEvent'->new($_) };

declare 'RepeatedMigrationProgressEvent',
    as ArrayRef[MigrationProgressEvent()];

coerce 'RepeatedMigrationProgressEvent',
    from ArrayRef[HashRef], via { [ map { 'Google::Datastore::Admin::V1::Migration::MigrationProgressEvent'->new($_) } @$_ ] };

declare 'MapStringMigrationProgressEvent',
    as HashRef[MigrationProgressEvent()];

declare 'ConcurrencyMode',
    as (Int | Str);

declare 'PrepareStepDetails',
    as InstanceOf['Google::Datastore::Admin::V1::Migration::MigrationProgressEvent::PrepareStepDetails'];

coerce 'PrepareStepDetails',
    from HashRef, via { 'Google::Datastore::Admin::V1::Migration::MigrationProgressEvent::PrepareStepDetails'->new($_) };

declare 'RepeatedPrepareStepDetails',
    as ArrayRef[PrepareStepDetails()];

coerce 'RepeatedPrepareStepDetails',
    from ArrayRef[HashRef], via { [ map { 'Google::Datastore::Admin::V1::Migration::MigrationProgressEvent::PrepareStepDetails'->new($_) } @$_ ] };

declare 'MapStringPrepareStepDetails',
    as HashRef[PrepareStepDetails()];

declare 'RedirectWritesStepDetails',
    as InstanceOf['Google::Datastore::Admin::V1::Migration::MigrationProgressEvent::RedirectWritesStepDetails'];

coerce 'RedirectWritesStepDetails',
    from HashRef, via { 'Google::Datastore::Admin::V1::Migration::MigrationProgressEvent::RedirectWritesStepDetails'->new($_) };

declare 'RepeatedRedirectWritesStepDetails',
    as ArrayRef[RedirectWritesStepDetails()];

coerce 'RepeatedRedirectWritesStepDetails',
    from ArrayRef[HashRef], via { [ map { 'Google::Datastore::Admin::V1::Migration::MigrationProgressEvent::RedirectWritesStepDetails'->new($_) } @$_ ] };

declare 'MapStringRedirectWritesStepDetails',
    as HashRef[RedirectWritesStepDetails()];

1;

__END__

=head1 NAME

Google::Datastore::Admin::V1::Migration::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
