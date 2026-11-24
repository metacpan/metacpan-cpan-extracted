package Google::Firestore::Admin::V1::UserCreds::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'UserCreds',
    as InstanceOf['Google::Firestore::Admin::V1::UserCreds::UserCreds'];

coerce 'UserCreds',
    from HashRef, via { 'Google::Firestore::Admin::V1::UserCreds::UserCreds'->new($_) };

declare 'RepeatedUserCreds',
    as ArrayRef[UserCreds()];

coerce 'RepeatedUserCreds',
    from ArrayRef[HashRef], via { [ map { 'Google::Firestore::Admin::V1::UserCreds::UserCreds'->new($_) } @$_ ] };

declare 'MapStringUserCreds',
    as HashRef[UserCreds()];

declare 'State',
    as (Int | Str);

declare 'ResourceIdentity',
    as InstanceOf['Google::Firestore::Admin::V1::UserCreds::UserCreds::ResourceIdentity'];

coerce 'ResourceIdentity',
    from HashRef, via { 'Google::Firestore::Admin::V1::UserCreds::UserCreds::ResourceIdentity'->new($_) };

declare 'RepeatedResourceIdentity',
    as ArrayRef[ResourceIdentity()];

coerce 'RepeatedResourceIdentity',
    from ArrayRef[HashRef], via { [ map { 'Google::Firestore::Admin::V1::UserCreds::UserCreds::ResourceIdentity'->new($_) } @$_ ] };

declare 'MapStringResourceIdentity',
    as HashRef[ResourceIdentity()];

1;

__END__

=head1 NAME

Google::Firestore::Admin::V1::UserCreds::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
