package Google::Iam::Admin::V1::WorkforcePoolPlatformLogs::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'WorkforcePoolAttributeSyncEventLog',
    as InstanceOf['Google::Iam::Admin::V1::WorkforcePoolPlatformLogs::WorkforcePoolAttributeSyncEventLog'];

coerce 'WorkforcePoolAttributeSyncEventLog',
    from HashRef, via { 'Google::Iam::Admin::V1::WorkforcePoolPlatformLogs::WorkforcePoolAttributeSyncEventLog'->new($_) };

declare 'RepeatedWorkforcePoolAttributeSyncEventLog',
    as ArrayRef[WorkforcePoolAttributeSyncEventLog()];

coerce 'RepeatedWorkforcePoolAttributeSyncEventLog',
    from ArrayRef[HashRef], via { [ map { 'Google::Iam::Admin::V1::WorkforcePoolPlatformLogs::WorkforcePoolAttributeSyncEventLog'->new($_) } @$_ ] };

declare 'MapStringWorkforcePoolAttributeSyncEventLog',
    as HashRef[WorkforcePoolAttributeSyncEventLog()];

1;

__END__

=head1 NAME

Google::Iam::Admin::V1::WorkforcePoolPlatformLogs::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
