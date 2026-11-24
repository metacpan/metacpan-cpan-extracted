package Google::Cloud::Oslogin::Common::Common::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'OperatingSystemType',
    as (Int | Str);

declare 'PosixAccount',
    as InstanceOf['Google::Cloud::Oslogin::Common::Common::PosixAccount'];

coerce 'PosixAccount',
    from HashRef, via { 'Google::Cloud::Oslogin::Common::Common::PosixAccount'->new($_) };

declare 'RepeatedPosixAccount',
    as ArrayRef[PosixAccount()];

coerce 'RepeatedPosixAccount',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oslogin::Common::Common::PosixAccount'->new($_) } @$_ ] };

declare 'MapStringPosixAccount',
    as HashRef[PosixAccount()];

declare 'SshPublicKey',
    as InstanceOf['Google::Cloud::Oslogin::Common::Common::SshPublicKey'];

coerce 'SshPublicKey',
    from HashRef, via { 'Google::Cloud::Oslogin::Common::Common::SshPublicKey'->new($_) };

declare 'RepeatedSshPublicKey',
    as ArrayRef[SshPublicKey()];

coerce 'RepeatedSshPublicKey',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oslogin::Common::Common::SshPublicKey'->new($_) } @$_ ] };

declare 'MapStringSshPublicKey',
    as HashRef[SshPublicKey()];

1;

__END__

=head1 NAME

Google::Cloud::Oslogin::Common::Common::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
